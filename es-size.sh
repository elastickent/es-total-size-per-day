#!/bin/bash

# Full path to commands - adjust if necessary for your system
DATE_CMD="/bin/date"
CURL_CMD="/usr/bin/curl"
JQ_CMD="/opt/homebrew/bin/jq"
BC_CMD="/usr/bin/bc"

# Ensure the full path for data files to avoid issues with the working directory
BASE_DIR="/Users/kent/github/es-real-size"  # Update this path to where you want your files
DATA_FILE="$BASE_DIR/es_index_sizes.dat"
TMP_DATA_FILE="$BASE_DIR/es_index_sizes.tmp"

# For crontab safety, explicitly define the date format using a full path to the command
current_date=$($DATE_CMD '+%Y-%m-%d %H:%M:%S')
file_date=$($DATE_CMD '+%Y-%m-%d-%H:%M:%S')
TOTAL_CHANGE_FILE="$BASE_DIR/es_total_change-$file_date.dat"

# Elasticsearch API URL - using https://USER:PASSWD@host:9200 format keep it as is
ES_URL="https://elastic:ZhMRZDiZbV1UT9LqC2NO@dev1:9200"

# Adjusted to use the full path for curl and jq
$CURL_CMD -sk "$ES_URL/_cat/indices?h=index,store.size&format=json" | $JQ_CMD -c '.[] | {(.index): .["store.size"]}' > "$TMP_DATA_FILE"

# Initialize total change variable
total_change=0

# Function to convert size to bytes - using full paths for commands
convert_to_bytes() {
    size=$1
    unit=$2
    case "$unit" in
        b)  size_bytes=$(echo "$size" | $BC_CMD) ;;
        kb) size_bytes=$(echo "$size * 1024" | $BC_CMD) ;;
        mb) size_bytes=$(echo "$size * 1024 * 1024" | $BC_CMD) ;;
        gb) size_bytes=$(echo "$size * 1024 * 1024 * 1024" | $BC_CMD) ;;
        tb) size_bytes=$(echo "$size * 1024 * 1024 * 1024 * 1024" | $BC_CMD) ;;
        *) echo "Unknown size unit: $unit" >&2; exit 1 ;;
    esac
    echo "$size_bytes"
}


# If the data file from the previous day exists, calculate the difference
if [[ -f "$DATA_FILE" ]]; then
    echo "Calculating differences in index sizes since last run..."

    while IFS= read -r line || [[ -n "$line" ]]; do
        index_name=$(echo $line | $JQ_CMD -r 'keys[]')
        current_size=$(echo $line | $JQ_CMD -r '.[]' | awk 'tolower($0)' | grep -oE '[0-9.]+')
        current_unit=$(echo $line | $JQ_CMD -r '.[]' | awk 'tolower($0)' | grep -oE '[a-z]+')
        
        # Convert current size to bytes
        current_size_bytes=$(convert_to_bytes "$current_size" "$current_unit")

        previous_entry=$(grep "$index_name" "$DATA_FILE" || echo "")
        previous_size=$(echo $previous_entry | $JQ_CMD -r '.[]' | awk 'tolower($0)' | grep -oE '[0-9.]+')
        previous_unit=$(echo $previous_entry | $JQ_CMD -r '.[]' | awk 'tolower($0)' | grep -oE '[a-z]+')

        # Convert previous size to bytes
        previous_size_bytes=$(convert_to_bytes "$previous_size" "$previous_unit")

        # If previous size exists, calculate the difference
        if [[ -n "$previous_size" ]]; then
            diff_bytes=$(echo "$current_size_bytes - $previous_size_bytes" | bc)
            # Check if the difference is greater than zero and update the total change
            if (( $(echo "$diff_bytes > 0" | bc -l) )); then
                echo "Index $index_name increased by $diff_bytes bytes"
                total_change=$(echo "$total_change + $diff_bytes" | bc)
            fi
        fi
    done < "$TMP_DATA_FILE"
    
    # Write the total change to the file
    echo "$current_date,$total_change" > "$TOTAL_CHANGE_FILE"
else
    echo "No previous data available. Saving current sizes for next calculation."
fi

# Move temporary data file to permanent data file for next execution
cp "$TMP_DATA_FILE" "$DATA_FILE"
