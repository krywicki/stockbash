#!/bin/bash -e

VERSION="0.0.1"
APIKEY=${STOCKBASH_APIKEY:-missing}
URL="https://www.alphavantage.co"

##############################################################################
# Helper Functions
##############################################################################

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
    if [ ! -z $MISSING_DEPENDENCIES ]; then
        exit 1
    fi
}

##############################################################################
# Alphavantage API Functions
##############################################################################

# Performs HTTP GET 
# Usage: http_get [path] [query params]
#   Example: http_get 'https://google.com' 'param1=value1' 'param2=value2'
function http_get() {
    local url=$1
    local cmd="curl -Gs -d 'apikey=$APIKEY'"

    shift
    for qparam in $@
    do
        local cmd="$cmd -d '$qparam'"
    done

    # append url path
    local cmd="$cmd $url"

    echo $(eval "$cmd")
}

# Get global quote for specified symbol
# Usage: global_quote [symbol]
#   Example: global_quote IBM
function get_global_quote() { 
    echo $(http_get "$URL/query" "function=GLOBAL_QUOTE" "symbol=$1")
}

# Get as-traded daily time series (date, daily open, daily high, daily low, daily close, daily volume) for
# specified symbol
# Usage: time_series_daily [symbol]
#   Example: time_series_daily AAPL
function get_time_series_daily() {
    echo $(http_get "$URL/query" "function=TIME_SERIES_DAILY" "symbol=$1")
}

# Get company info, financial raitios and other key mterics for equity specified. 
# Usage: company_overiew [symbol]
#   Example: company_overiew IBM 
function get_company_overview {
    echo $(http_get "$URL/query" "function=OVERVIEW" "symbol=$1")
}

# Get global quote for target symbol
# Usage: get_global_quote [symbol]
#   Example: get_global_quote IBM
function get_global_quote() {
    local csv=$(http_get "$URL/query" "function=GLOBAL_QUOTE" "datatype=csv" "symbol=$1")
    read -r -a array <<< $csv
    IFS=',' read -a data <<< ${array[1]}
    echo ${data[@]}
}


##############################################################################
# Functions
##############################################################################

# Presents stock summary detailing current stock price, 
# Usage: display_stock_summary [symbol]
#   Example: dispaly_stock_summary IBM
function display_stock_summary() {
    local csv=($(get_global_quote $1))
    local open=${csv[1]}
    local high=${csv[2]}
    local low=${csv[3]}
    local price=${csv[4]}
    local volume=${csv[5]}
    local latest=${csv[6]}
    local prev_close=${csv[7]}
    local change=${csv[8]}
    local change_percent=${csv[9]}

    printf -- " _____________________\n"
    printf    "|\e[4m %-20s\e[0m|\n" $1              
    printf    "| Open %-10s   |\n"  $open 
    printf    "|                     |\n"
    printf    "|                     |\n"
    printf    "|                     |\n"
    printf    "|                     |\n"
    printf    "|                     |\n"
    printf -- "|_____________________|\n"
}

########################################################
# MAIN
########################################################

check_for_dependencies

display_stock_summary AAPL

#display_stock_summary AB
#display_stock_summary ABC
#display_stock_summary ABCD
#display_stock_summary ABCDE
#display_stock_summary ABCDEF


