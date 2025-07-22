#!/bin/bash

# Declare functions
function usage () {
    echo "Usage: $(basename $0) --instance <INSTANCE_NAME> [--output-dir] [--dumps] [--sleep] [--user] [--jcmd] [--keep]"
    echo "Example: $(basename $0) --instance avst_prod_jira --output-dir /tmp/threads --dumps 4 --sleep 10 --user hosting --jcmd /usr/java/bin/jcmd --keep 30"
}

function error () {
    echo "ERROR: $1"
    [[ ${3:-''} == "y" ]] && usage
    exit ${2:-99}
}

function warn () {
    echo "WARN: $1"
}

function info () {
    echo "INFO: $1"
}

# Handle arguments
while (( $# > 0 )); do
    opt="$1"
    case $opt in
        --instance|-i)
            INSTANCE="$2"
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        --output-dir|-o)
            OUT_DIR_PARENT="$2"
            shift
            ;;
        --dumps|-d)
            DUMPS="$2"
            shift
            ;;
        --sleep|-s)
            SLEEP="$2"
            shift
            ;;
        --user|-u)
            APP_USER="$2"
            shift
            ;;
        --jcmd|-j)
            JCMD="$2"
            shift
            ;;
        --keep|-k)
            KEEP_DAYS="$2"
            shift
            ;;
        --*|-*)
            error "Invalid option: '$opt'" 1 y
            ;;
    esac
    shift
done

# Set default values
OUT_DIR_PARENT="${OUT_DIR_PARENT:-/data/thread_dumps}"
DUMPS=${DUMPS:-3}
SLEEP=${SLEEP:-20}
APP_USER="${APP_USER:-hosting}"
JCMD="${JCMD:-/usr/java/latest/bin/jcmd}"
KEEP_DAYS="${KEEP_DAYS:-30}"

# Check mandatory arguments
if [[ -z ${INSTANCE} ]]; then
    error "Mandatory argument, INSTANCE NAME, missing" 2 y
fi

# Check if jcmd exists
if [[ ! -f ${JCMD} ]]; then
    error "jcmd command does not exist at specified path - ${JCMD}" 3
fi

# Cleanup old dumps
if [[ $KEEP_DAYS -ne 0 ]] && [[ -d ${OUT_DIR_PARENT} ]]; then
    find ${OUT_DIR_PARENT} -maxdepth 1 -mtime +${KEEP_DAYS} -exec rm -Rf {} \;
fi

# Loop for the number of dumps required
for POS in $(seq 1 ${DUMPS}); do
    PID=$(pgrep -nf "^${INSTANCE}\W")
    NOW=$(date +%Y%m%d%H%M%S)
    TODAY=$(date +%Y%m%d)
    if [[ -z ${PID} ]]; then
        error "Unable to identify PID for instance '${INSTANCE}'" 4
    fi

    OUT_DIR=${OUT_DIR_PARENT}/${TODAY}
    if [[ ! -d "${OUT_DIR}" ]]; then
        # Compress previous day's directory if it exists
        YESTERDAY=$(date -d "yesterday" +%Y%m%d)
        YESTERDAY_OUT_DIR=${OUT_DIR_PARENT}/${YESTERDAY}
        if [[ -d "${YESTERDAY_OUT_DIR}" ]]; then
            tar -zcf ${YESTERDAY_OUT_DIR}.tgz ${YESTERDAY_OUT_DIR}/
            rm -Rf ${YESTERDAY_OUT_DIR}/
        fi
        mkdir -p "${OUT_DIR}"
    fi

    # Take the dump
    sudo -u ${APP_USER} ${JCMD} $PID Thread.print > ${OUT_DIR}/${INSTANCE}-$NOW.dump

    # Verify the dump
    if [[ ! -f ${OUT_DIR}/${INSTANCE}-$NOW.dump ]] || [[ ! -s ${OUT_DIR}/${INSTANCE}-$NOW.dump ]]; then
        warn "Dump file, ${OUT_DIR}/${INSTANCE}-$NOW.dump, was not generated"
    fi

    # Sleep if this is not the last pass
    if [[ ${POS} -ne ${DUMPS} ]]; then
        sleep ${SLEEP}
    fi
done
