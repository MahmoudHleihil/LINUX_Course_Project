#!/bin/bash

# Set variables
CSV_FILE="$1"
LOG_FILE="script.log"
ERROR_LOG="error.log"
DIAGRAMS_DIR="Diagrams"
BACKUP_DIR="Backups"
VENV_DIR=".venv"

# Function to log messages
log() {
    echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" | tee -a "$LOG_FILE"
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
        log "Creating virtual environment..."
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
        pip install -r requirements.txt
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
        # Remove quotes from fields
        plant=$(echo "$plant" | tr -d '"')
        heights=$(echo "$heights" | tr -d '"')
        leaf_counts=$(echo "$leaf_counts" | tr -d '"')
        dry_weights=$(echo "$dry_weights" | tr -d '"')

        # Skip empty lines
        if [[ -z "$plant" || -z "$heights" || -z "$leaf_counts" || -z "$dry_weights" ]]; then
            continue
        fi

        # Create directory for plant diagrams
        PLANT_DIR="$DIAGRAMS_DIR/$plant"
        mkdir -p "$PLANT_DIR"

        # Run the Python script
        log "Running Python script for plant: $plant"
        python3 ../Q2/plant_plots.py --plant "$plant" --height $heights --leaf_count $leaf_counts --dry_weight $dry_weights > "$PLANT_DIR/output.log" 2>>"$ERROR_LOG"

        mv "${plant}_scatter.png" "${plant}_histogram.png" "${plant}_line_plot.png" "$PLANT_DIR/" 2>/dev/null
        
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
    BACKUP_FILE="$BACKUP_DIR/Backup_$TIMESTAMP.zip"

    mkdir -p "$BACKUP_DIR"
    tar -czf "$BACKUP_FILE" "$DIAGRAMS_DIR" > /dev/null 2>&1

    if [[ $? -eq 0 ]]; then
        log "Backup created successfully: $BACKUP_FILE"
        rm -rf "$DIAGRAMS_DIR"
    else
        log "Error: Failed to create backup!" | tee -a "$ERROR_LOG"
    fi
}

# Main script execution
log "Starting plant processing script..."
find_csv_file
setup_venv
process_csv
create_backup

log "Script execution completed."
