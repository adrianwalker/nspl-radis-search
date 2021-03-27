#!/bin/bash
# Data URL from: https://geoportal.statistics.gov.uk/datasets/national-statistics-postcode-lookup-february-2021
DATA_URL='https://www.arcgis.com/sharing/rest/content/items/7606baba633d4bbca3f2510ab78acf61/data'
ZIP_FILE='/tmp/nspl.zip'
CSV_FILE='/tmp/nspl.csv'
CSV_REGEX='NSPL.*UK\.csv'
REDIS_KEY='nspl' # NSPL - National Statistics Postcode Lookup
POSTCODE_FIELD=3 # PCDS - Unit postcode variable length version
LAT_FIELD=34 # LAT - Decimal degrees latitude
LONG_FIELD=35 # LONG - Decimal degrees longitude
START_TIME="$(date -u +%s)"

# Download data file if it doesn't exist
if [ -f "$ZIP_FILE" ]
then
    echo "'$ZIP_FILE' exists, skipping download"
else
    echo "Downloading '$ZIP_FILE'"
    wget $DATA_URL -O $ZIP_FILE
fi

# Unzip data if it doesn't exist
if [ -f "$CSV_FILE" ]
then
    echo "'$ZIP_FILE' exists, skipping unzipping"  
else
    echo "Unzipping data to '$CSV_FILE'"
    unzip -p $ZIP_FILE $(unzip -Z1 $ZIP_FILE | grep -E $CSV_REGEX) > $CSV_FILE
fi

# Process data file, create Redis commands, pipe to redis-cli
echo "Processing data file '$CSV_FILE'"
csvtool format "GEOADD $REDIS_KEY %($LONG_FIELD) %($LAT_FIELD) \"%($POSTCODE_FIELD)\"\n" $CSV_FILE \
| redis-cli --pipe

# Done
END_TIME="$(date -u +%s)"
ELAPSED_TIME="$(($END_TIME-$START_TIME))"
MEMBERS=$(echo "zcard nspl" | redis-cli | cut -f 1)
echo "$MEMBERS postcodes loaded"
echo "Elapsed: $ELAPSED_TIME seconds"
