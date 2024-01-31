# Get today's date in UTC
today=$(date -u +%Y%m%d)

# Create a date string for noon UTC
noon_utc="${today}1200"

# Get the timestamp
timestamp=$(date -u -j -f "%Y%m%d%H%M" "$noon_utc" "+%s")

echo $timestamp