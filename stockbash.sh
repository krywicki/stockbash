#!/bin/bash -e

VERSION="0.0.1"
APIKEY=${STOCKBASH_APIKEY:-missing}
URL="https://www.alphavantage.co"

# Performs HTTP GET 
# Usage: http_get [path] [query param]
#   Example: http_get 'https://google.com' 'param1=value1' 'param2=value2'
function http_get() {
    local url=$1
    local cmd="curl -G -d 'apikey=$APIKEY'"

    shift
    for qparam in $@
    do
        local cmd="$cmd -d '$qparam'"
    done

    # append url path
    local cmd="$cmd $url"

    eval $cmd
}

# Get global quote for specified symbol
# Usage: global_quote [symbol]
#   Example: global_quote IBM
function global_quote() { 
    http_get "$URL/query" "function=GLOBAL_QUOTE" "symbol=$1"
}

# Get as-traded daily time series (date, daily open, daily high, daily low, daily close, daily volume) for
# specified symbol
# Usage: time_series_daily [symbol]
#   Example: time_series_daily AAPL
function time_series_daily() {
    http_get "$URL/query" "function=TIME_SERIES_DAILY" "symbol=$1"
}

# Get company info, financial raitios and other key mterics for equity specified. 
# Usage: company_overiew [symbol]
#   Example: company_overiew IBM 
function company_overview {
    http_get "$URL/query" "function=OVERVIEW" "symbol=$1"
}

# Checks if program is present in environment
# MISSING_DEPENDENCIES=True will be set if program is not found.
# Usage: check_for_program [program name]
#   Example: check_for_program ls
function check_for_program() {
    local program="${1}"
    command -v "${program}" > /dev/null
    if [[ "${?}" -ne 0 ]]; then
        echo -e "\e[31m* Missing dependency: ${program}\e[0m"
        MISSING_DEPENDENCIES=True
    fi
}

# Checks for required dependencies. Exits if dependency missing.
# Usage: check_for_dependendencies
function check_for_dependencies() {
    check_for_program jq

    if [ ! -z $MISSING_DEPENDENCIES ]; then
        exit 1
    fi
}

########################################################
# MAIN
########################################################

check_for_dependencies
company_overview IBM


