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

    # strip endline chars \r
    local data=$(echo ${data[@]} | sed 's/\r$//')
    echo ${data[@]}
}

function get_field() {
    declare -a array=($1)
    echo "${array[$2]}"
}

##############################################################################
# Functions
##############################################################################

MAX_ROW_ITEMS=3 # max num of items to display in row
WIDTH=30        # 30 chars wide boxes
TLC="\u250C"    # top left corner
TRC="\u2510"    # top right corner
BLC="\u2514"    # bottom left corner
BRC="\u2518"    # bottom right corner
VLR="\u251C"    # vertical line right
VLL="\u2524"    # vertical line left
VL="\u2502"     # vertical line
HL="\u2500"     # horizontal line

QUOTE_FIELD_SYMBOL=0
QUOTE_FIELD_OPEN=1
QUOTE_FIELD_HIGH=2
QUOTE_FIELD_LOW=3
QUOTE_FIELD_PRICE=4
QUOTE_FIELD_VOLUME=5
QUOTE_FIELD_LATEST=6
QUOTE_FIELD_PREV_CLOSE=7
QUOTE_FIELD_CHANGE=8
QUOTE_FIELD_CHANGE_PERCENT=9

function draw_row_headers() {
    for i in $(seq 1 $#)
    do
        printf "$TLC"
        printf "$HL%.0s" $(seq 1 $WIDTH)
        printf "$TRC"
    done

    printf "\n"

    for i in $(seq 1 $#) 
    do
        declare -a s=(${!i})
        let local pad="$WIDTH"
        printf "$VL%-${pad}s%s$VL" "${s[$QUOTE_FIELD_SYMBOL]}"
    done

    printf "\n"

    for i in $(seq 1 $#)
    do 
        printf "$VLR"
        printf "$HL%.0s" $(seq 1 $WIDTH)
        printf "$VLL"
    done

    printf "\n"
}

function draw_row_fields() {
    local field_name=$1;shift
    local field_index=$1;shift
    declare -a values

    for i in $(seq 1 $#)
    do 
        declare s=(${!i})
        values+=(${s[$field_index]})
    done

    for val in ${values[@]}
    do
        let local padr="($WIDTH - ${#val} - 1)"
        printf "$VL%-${padr}s%s $VL" $field_name $val
    done
    printf "\n"
}

function draw_row_footers() {
    for i in $(seq 1 $1)
    do
        printf "$BLC"
        printf "$HL%.0s" $(seq 1 $WIDTH)
        printf "$BRC"
    done
    printf "\n"
}

function draw_row() {
    local len=$#
    local field_index=0


    draw_row_headers "${@}"

    # draw fields
    draw_row_fields "Price" "$QUOTE_FIELD_PRICE" "${@}"
    draw_row_fields "Open" "$QUOTE_FIELD_OPEN" "${@}"
    draw_row_fields "High" "$QUOTE_FIELD_HIGH" "${@}"
    draw_row_fields "Low" "$QUOTE_FIELD_LOW" "${@}"
    draw_row_fields "Prev-Close" "$QUOTE_FIELD_PREV_CLOSE" "${@}"

    draw_row_footers $#
}

function display_stock_summaries() {

    declare -a stocks

    stocks[0]="$(get_global_quote $1)"
    stocks[1]="$(get_global_quote $2)"

    draw_row "${stocks[@]}"
}

# Presents stock summary detailing current stock price, 
# Usage: display_stock_summary [symbol]
#   Example: dispaly_stock_summary IBM
function display_stock_summary() {
    local csv=($(get_global_quote $1))
    local symbol=${csv[0]}
    local open=${csv[1]}
    local high=${csv[2]}
    local low=${csv[3]}
    local price=${csv[4]}
    local volume=${csv[5]}
    local latest=${csv[6]}
    local prev_close=${csv[7]}
    local change=${csv[8]}
    local changeper=${csv[9]}

    draw_header $symbol "$changeper"
    draw_field "Price" "\$$price"
    draw_field "Open" "\$$open"
    draw_field "High" "\$$high"
    draw_field "Low" "\$$low"
    draw_footer 
}

########################################################
# MAIN
########################################################

check_for_dependencies

display_stock_summaries AAPL IBM

