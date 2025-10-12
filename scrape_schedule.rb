require 'open-uri'
require 'json'
require 'date'

ICS_URL = "https://swamprabbits.com/schedule-all.ics"
MATCHUPS_URL = "https://gist.githubusercontent.com/Oyjord/1509b9f03fa9a6e0f3753631938295cd/raw/swamp_schedule.json"
OUTPUT_PATH = "swamp_schedule.json"

def fetch_matchups
  JSON.parse(URI.open(MATCHUPS_URL).read)["matchups"]
rescue => e
  puts "❌ Failed to fetch matchups: #{e}"
  {}
end

def extract_date(line)
  raw = line.split(":").last.strip
  DateTime.strptime(raw, "%Y%m%dT%H%M%S").to_time
rescue
  nil
end

def date_key(date)
  date.utc.strftime("%Y%m%d") # Use UTC to match JSON keys
end

def scrape_schedule
  content = URI.open(ICS_URL).read
  matchups = fetch_matchups
  events = content.split("BEGIN:VEVENT")

  parsed = {}

  events.each do |event|
    dtstart = event.lines.find { |l| l.start_with?("DTSTART") }
    next unless dtstart

    date = extract_date(dtstart)
    next unless date

    key = date_key(date)
    puts "🧪 Checking event: #{date} → key=#{key}"
puts "🧪 Matchup exists: #{matchups.key?(key)}"
    matchup = matchups[key]

    unless matchup
      puts "⚠️ No matchup found for #{key} — using fallback"
    end

    parsed[key] = {
      opponent: matchup ? matchup["opponent"] : "Unknown",
      location: matchup ? matchup["location"] : "Unknown"
    }
puts "✅ Added game for #{key}"
  end

  output = {
    lastUpdated: Time.now.strftime("%m-%d-%Y"),
    matchups: parsed
  }

  File.write(OUTPUT_PATH, JSON.pretty_generate(output))
  puts "✅ Saved #{parsed.size} matchups to #{OUTPUT_PATH}"
end

scrape_schedule
