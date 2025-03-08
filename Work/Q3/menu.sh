#!/bin/bash

# History file
history_file="history.log"

# Display menu
function show_menu {
    echo "Choose an action:"
    echo "1) Create CSV file and set it as the current file"
    echo "2) Choose a file as the current file"
    echo "3) Display the current file"
    echo "4) Add a new row for a specific plant"
    echo "5) Run the enhanced Python code with parameters for a specific plant to generate charts"
    echo "6) Update values in a specific row by plant name"
    echo "7) Delete a row by row index or plant name"
    echo "8) Print the plant with the highest average leaf count"
    echo "9) Exit"
}

# Function to log history
function log_history {
    echo "$(date): $1" >> $history_file
}

# Current file variable
current_file=""

# Function to create a CSV file with plant data
function create_csv {
    echo "Plant,Height,Leaf Count,Dry Weight" > "$current_file"
    
    read -p "Create csv file with example data (y/n)? " choice
    if [ "$choice" == "y" ]; then
        echo "Rose,\"50 55 60 65 70\",\"35 40 45 50 55\",\"2.0 2.2 2.5 2.7 3.0\"" >> "$current_file"
        echo "Tulip,\"30 35 40 42\",\"12 15 18 20\",\"1.5 1.6 1.7 1.8\"" >> "$current_file"
        echo "Sunflower,\"120 125 130 135\",\"50 55 60 65\",\"5.0 5.5 6.0 6.5\"" >> "$current_file"
        echo "Daffodil,\"40 45 50 55\",\"15 18 20 22\",\"1.8 2.0 2.2 2.5\"" >> "$current_file"
        echo "Lily,\"60 65 70\",\"20 22 24\",\"2.5 2.7 3.0\"" >> "$current_file"
    fi
    log_history "Created new CSV file named $current_file"
}

# Function to choose a file
function choose_file {
    read -p "Enter file name: " filename
    current_file=$filename
    log_history "Chose file $current_file"
}

# Function to display the current file
function show_current_file {
    if [[ -z "$current_file" ]]; then
        echo "No file selected"
    else
        cat "$current_file"
    fi
}

# Function to add a new row
function add_line {
    read -p "Enter plant name: " plant
    read -p "Enter height values: " height
    read -p "Enter leaf count values: " leaf_count
    read -p "Enter dry weight values: " dry_weight
    echo "$plant,\"$height\",\"$leaf_count\",\"$dry_weight\"" >> "$current_file"
    log_history "Added new row for plant $plant"
}

# Function to run Python code with parameters
function run_python_code {
    read -p "Enter plant name to run code for: " plant
    # Extract the corresponding data from the CSV file and remove quotes
    height_data=$(awk -F, -v plant="$plant" '$1 == plant {print $2}' "$current_file" | tr -d '"')
    leaf_count_data=$(awk -F, -v plant="$plant" '$1 == plant {print $3}' "$current_file" | tr -d '"')
    dry_weight_data=$(awk -F, -v plant="$plant" '$1 == plant {print $4}' "$current_file" | tr -d '"')

    # Make sure that the data is space-separated for passing to Python
    height_values=$(echo $height_data | tr ' ' ' ')
    leaf_count_values=$(echo $leaf_count_data | tr ' ' ' ')
    dry_weight_values=$(echo $dry_weight_data | tr ' ' ' ')

    # Run the Python script with the collected data as arguments
    python3 ../Q2/plant_plots.py --plant "$plant" --height $height_values --leaf_count $leaf_count_values --dry_weight $dry_weight_values

    log_history "Ran Python code for plant $plant"
}



# Function to update values in a row
function update_line {
    read -p "Enter plant name to update: " plant
    read -p "Enter new height value: " height
    read -p "Enter new leaf count value: " leaf_count
    read -p "Enter new dry weight value: " dry_weight
    sed -i "/$plant/c\\$plant,\"$height\",\"$leaf_count\",\"$dry_weight\"" "$current_file"
    log_history "Updated row for plant $plant"
}

# Function to delete a row by index or plant name
function delete_line {
    read -p "Delete by row index (y/n)? " choice
    if [ "$choice" == "y" ]; then
        read -p "Enter row index to delete: " line_index
        sed -i "${line_index}d" "$current_file"
    else
        read -p "Enter plant name to delete: " plant
        sed -i "/$plant/d" "$current_file"
    fi
    log_history "Deleted row for plant $plant"
}

# Function to print the plant with the highest average leaf count
function print_plant_with_highest_leaf_count {
    # Calculate the average leaf count for each plant
    awk -F, '{
        # Remove quotes around values
        gsub(/"/, "", $3)
        
        # Split leaf count data by space into array a
        split($3, a, " ")
        
        # Calculate sum of leaf counts
        sum = 0
        for (i in a) sum += a[i]
        
        # Calculate average leaf count
        avg = sum / length(a)
        
        # Print the plant name and average leaf count
        print $1, avg
    }' "$current_file" | sort -k2 -nr | head -n 1
}

# Running the menu
while true; do
    show_menu
    read -p "Choose an action: " choice
    case $choice in
        1) read -p "Enter new file name: " current_file; create_csv ;;
        2) choose_file ;;
        3) show_current_file ;;
        4) add_line ;;
        5) run_python_code ;;
        6) update_line ;;
        7) delete_line ;;
        8) print_plant_with_highest_leaf_count ;;
        9) exit ;;
        *) echo "Invalid choice";;
    esac
done
