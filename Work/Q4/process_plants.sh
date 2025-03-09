#!/bin/bash

# Default variables
CSV_FILE=""
LOG_FILE="script.log"
ERROR_LOG="error.log"
DIAGRAMS_DIR="Diagrams"
BACKUP_DIR="Backups"
VENV_DIR=".venv"
PYTHON_SCRIPT="../Q2/plant_plots.py"
CLEAN=false
HISTORY=false

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
}

# Function to parse arguments
parse_args() {
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --csv|-p) CSV_FILE="$2"; shift ;;
            --diagrams|-d) DIAGRAMS_DIR="$2"; shift ;;
            --backup|-b) BACKUP_DIR="$2"; shift ;;
            --venv) VENV_DIR="$2"; shift ;;
            *) log "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done
}

# Function to find the nearest CSV file if none is provided
find_csv_file() {
    if [[ -z "$CSV_FILE" ]]; then
        CSV_FILE=$(find . -maxdepth 1 -type f -name "*.csv" | head -n 1)
        if [[ -z "$CSV_FILE" ]]; then
            log "Error: No CSV file found!" | tee -a "$ERROR_LOG"
            exit 1
        fi
    fi
    log "Using CSV file: $CSV_FILE"
}

# Function to set up the virtual environment
setup_venv() {
    if [[ ! -d "$VENV_DIR" ]]; then
        log "Creating virtual environment in $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
        if [[ $? -ne 0 ]]; then
            log "Error: Failed to create virtual environment!" | tee -a "$ERROR_LOG"
            exit 1
        fi
    fi

    # Activate the virtual environment
    source "$VENV_DIR/bin/activate"
    log "Virtual environment activated."

    # Install required dependencies
    if [[ -f "requirements.txt" ]]; then
        log "Installing dependencies from requirements.txt..."
        pip install -r requirements.txt &>> "$LOG_FILE"
        if [[ $? -ne 0 ]]; then
            log "Error: Failed to install dependencies!" | tee -a "$ERROR_LOG"
            exit 1
        fi
    else
        log "Warning: requirements.txt not found. Skipping installation."
    fi
}

# Function to process the CSV file and run Python script
process_csv() {
    log "Processing CSV file: $CSV_FILE"
    mkdir -p "$DIAGRAMS_DIR"

    tail -n +2 "$CSV_FILE" | while IFS=, read -r plant heights leaf_counts dry_weights; do
        plant=$(echo "$plant" | tr -d '"' | xargs)
        heights=$(echo "$heights" | tr -d '"' | xargs)
        leaf_counts=$(echo "$leaf_counts" | tr -d '"' | xargs)
        dry_weights=$(echo "$dry_weights" | tr -d '"' | xargs)

        if [[ -z "$plant" || -z "$heights" || -z "$leaf_counts" || -z "$dry_weights" ]]; then
            continue
        fi

        PLANT_DIR="$DIAGRAMS_DIR/$plant"
        mkdir -p "$PLANT_DIR"

        log "Running Python script for plant: $plant"
        python3 "$PYTHON_SCRIPT" --plant "$plant" --height $heights --leaf_count $leaf_counts --dry_weight $dry_weights > "$PLANT_DIR/output.log" 2>>"$ERROR_LOG"

        for img in "${plant}_scatter.png" "${plant}_histogram.png" "${plant}_line_plot.png"; do
            if [[ -f "$img" ]]; then
                mv "$img" "$PLANT_DIR/"
            else
                log "Warning: Missing expected plot file $img" | tee -a "$ERROR_LOG"
            fi
        done

        if [[ $? -eq 0 ]]; then
            log "Successfully generated plots for $plant"
        else
            log "Error: Failed to generate plots for $plant" | tee -a "$ERROR_LOG"
        fi
    done
}

# Function to create a backup of all generated diagrams
create_backup() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$BACKUP_DIR/Backup_$TIMESTAMP.tar.gz"

    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_FILE" "$DIAGRAMS_DIR" > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        log "Backup created successfully: $BACKUP_FILE"
    else
        log "Error: Failed to create backup!" | tee -a "$ERROR_LOG"
    fi
}

# Main script execution
log "Starting plant processing script..."
parse_args "$@"
find_csv_file
setup_venv
process_csv
create_backup

log "Script execution completed."
