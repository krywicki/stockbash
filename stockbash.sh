#!/bin/bash -e

##################################################################################
# Author        : Joe Krywicki
# License       : MIT
# Description   : Prints out alphavantage global stock quotes
#                   *note: Requires alphvantage API KEY
#                   *note: Note alphavantage rate limits requests.
#                       - Free API Limit is 5 requests per minute, 500 per day
#
# Usage         : stockbash.sh [SYMBOL]
#                   example: stockbash.sh AAPL IBM MSFT TSLA
###################################################################################

#---------------------------------
# Vars
#---------------------------------
VERSION="0.0.1"
APIKEY=${STOCKBASH_APIKEY:-missing}
URL="https://www.alphavantage.co"

#---------------------------------
# Display Vars
#---------------------------------
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

#---------------------------------
# Global Quote Fields
#---------------------------------
GQUOTE_FIELD_SYMBOL=0
GQUOTE_FIELD_OPEN=1
GQUOTE_FIELD_HIGH=2
GQUOTE_FIELD_LOW=3
GQUOTE_FIELD_PRICE=4
GQUOTE_FIELD_VOLUME=5
GQUOTE_FIELD_LATEST=6
GQUOTE_FIELD_PREV_CLOSE=7
GQUOTE_FIELD_CHANGE=8
GQUOTE_FIELD_CHANGE_PERCENT=9

##############################################################################
# Helper Functions
##############################################################################

#---------------------------------------------------------
# Checks if program is present in environment
# MISSING_DEPENDENCIES=True will be set if program is not found.
# Usage: check_for_program [program name]
#   Example: check_for_program ls
#---------------------------------------------------------
function check_for_program() {
    local program="${1}"
    command -v "${program}" > /dev/null
    if [[ "${?}" -ne 0 ]]; then
        echo -e "\e[31m* Missing dependency: ${program}\e[0m"
        MISSING_DEPENDENCIES=True
    fi
}

#---------------------------------------------------------
# Checks for required dependencies. Exits if dependency missing.
# Usage: check_for_dependendencies
#---------------------------------------------------------
function check_for_dependencies() {
    check_for_program 'curl'
    check_for_program 'seq'

    if [ ! -z $MISSING_DEPENDENCIES ]; then
        exit 1
    fi
}

##############################################################################
# Alphavantage API Functions
##############################################################################

#---------------------------------------------------------
# Performs HTTP GET 
# Usage: http_get [path] [query params]
#   Example: http_get 'https://google.com' 'param1=value1' 'param2=value2'
#---------------------------------------------------------
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
    local resp=$(eval "$cmd")

    if [[ "$resp" == *'5 calls per minute'* ]]; then
        printf "Rate-Exceeded %.0s" {0..10}
        #echo "rate-exceeded"
    else
        echo $resp
    fi
}


#---------------------------------------------------------
# Get global quote for target symbol
# Usage: get_global_quote [symbol]
#   Example: get_global_quote IBM
#---------------------------------------------------------
function get_global_quote() {
    local csv=$(http_get "$URL/query" "function=GLOBAL_QUOTE" "datatype=csv" "symbol=$1")
    read -r -a array <<< $csv
    IFS=',' read -a data <<< ${array[1]}

    # strip endline chars \r
    local data=$(echo ${data[@]} | sed 's/\r$//')
    echo ${data[@]}
}


##############################################################################
# Functions
##############################################################################


#----------------------------------------------------------------
# Draws Headers in a row for each stock quote info passed in
# Usage:
#   draw_row_headers [global quote info] [global quote info] ... 
#----------------------------------------------------------------
function draw_row_headers() {

    # draw box top
    for i in $(seq 1 $#)
    do
        printf "$TLC"
        printf "$HL%.0s" $(seq 1 $WIDTH)
        printf "$TRC"
    done

    printf "\n"

    # draw stock symbol
    for i in $(seq 1 $#) 
    do
        declare -a s=(${!i})
        let local pad="$WIDTH"
        printf "$VL%-${pad}s%s$VL" "${s[$QUOTE_FIELD_SYMBOL]}"
    done

    printf "\n"

    # draw box bottom
    for i in $(seq 1 $#)
    do 
        printf "$VLR"
        printf "$HL%.0s" $(seq 1 $WIDTH)
        printf "$VLL"
    done

    printf "\n"
}

#----------------------------------------------------------------
# Formats value of a global quote field
# Usage:
#   formate_global_quote_field [field index] [global quote info] 
# Returs formatted value
#----------------------------------------------------------------
function format_global_quote_field() {
    local       findex="$1";shift
    declare -a  qinfo="(${@})"
    local       fval="${qinfo[$findex]}"

    case $findex in
        $GQUOTE_FIELD_OPEN | $GQUOTE_FIELD_HIGH | $GQUOTE_FIELD_LOW |\
        $GQUOTE_FIELD_PRICE | $GQUOTE_FIELD_PREV_CLOSE)
            printf "$%'.2f" $fval
            ;;
        $GQUOTE_FIELD_CHANGE_PERCENT)
            printf "%s\%" $fval
            ;;
        *)
            echo "$fval"
            ;;
    esac
}

#----------------------------------------------------------------
# Draws fields in a row for each global stock quote info passed in
# Usage:
#   draw_row_fields [global quote info] [global quote info] ... 
#----------------------------------------------------------------
function draw_row_fields() {
    local fname="$1";shift
    local findex="$1";shift
    declare -a values

    for i in $(seq 1 $#)
    do 
        declare quote_info=(${!i})
        
        local fmtd_val="$(format_global_quote_field $findex ${quote_info[@]})"
        values+=($fmtd_val)
    done

    for val in ${values[@]}
    do
        let local padr="($WIDTH - ${#val} - 1)"
        printf "$VL%-${padr}s%s $VL" "$fname" $val
    done
    printf "\n"
}

#----------------------------------------------------------------
# Draws row footers the specified num of times 
# Usage:
#   draw_row_footers [num of footers] 
#----------------------------------------------------------------
function draw_row_footers() {
    for i in $(seq 1 $1)
    do
        printf "$BLC"
        printf "$HL%.0s" $(seq 1 $WIDTH)
        printf "$BRC"
    done
    printf "\n"
}

#----------------------------------------------------------------
# Draws fields in a row for each global stock quote info passed in
# Usage:
#   draw_row_fields [global quote info] [global quote info] ... 
#----------------------------------------------------------------
function draw_row() {
    draw_row_headers "${@}"

    # draw fields
    draw_row_fields "Price" "$GQUOTE_FIELD_PRICE" "${@}"
    draw_row_fields "Open" "$GQUOTE_FIELD_OPEN" "${@}"
    draw_row_fields "High" "$GQUOTE_FIELD_HIGH" "${@}"
    draw_row_fields "Low" "$GQUOTE_FIELD_LOW" "${@}"
    draw_row_fields "Prev Close" "$GQUOTE_FIELD_PREV_CLOSE" "${@}"

    draw_row_footers $#
}

#----------------------------------------------------------------
# Displays global stock quotes 
# Usage:
#   draw_row_fields [stock symbol] ... 
#----------------------------------------------------------------
function display_global_stock_quotes() {
    # fetch stock global quotes
    declare -a stocks
    for symbol in $@
    do 
        stocks+=("$(get_global_quote $symbol)")
    done

    declare -a slice=("${stocks[@]:0:$MAX_ROW_ITEMS}")
    local pos=0

    # draw stocks in rows
    while [ $pos -lt $# ]
    do
        # get slice from stocks and update pos
        slice=("${stocks[@]:$pos:$MAX_ROW_ITEMS}")    
        let pos="$pos + $MAX_ROW_ITEMS"

        # draw row of stock info
        draw_row "${slice[@]}"
    done
}

########################################################
# MAIN
########################################################

check_for_dependencies
display_global_stock_quotes $@
