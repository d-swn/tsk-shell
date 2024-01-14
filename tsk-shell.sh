#!/bin/bash

# Initialize variables
offset=0
input_file=""


out_dir="out"
extracted_data_dir="extracted"

meta_file="$out_dir/meta_information.txt"
filesystem_file="$out_dir/filesystem.txt"


dependencies=("fls" "grep" "awk" "sed" "strings" "icat")


# Function to show usage
usage() {
    echo "Usage: $0 -o offset -f input_file"
    echo "Options:"
    echo "  -o OFFSET      Specify the offset value to be used in the script."
    echo "  -f INPUT_FILE  Specify the input file that the script will process."
    echo "  -d             Check if all dependencies are installed" 
    echo "Example:"
    echo "  $0 -o 5 -f example.dd"
    exit 1
}

wait() {
    sleep 0.25
}

check_dependencies() {
    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Dependency missing: $dep"
            missing_deps=true
        fi
    done

    if [ "$missing_deps" = true ]; then
        echo "Please install missing dependencies."
        exit 1
    else
        echo "All dependencies are installed."
    fi
}

# Function to handle search operation
handle_search() {
    local search_word="$1"
    grep "$search_word" $filesystem_file > searchresults.txt
    local output=$(grep "$search_word" $filesystem_file | nl -w1 -s': ')
    echo "$output"
}

clean_string() {
    local input_string="$1"

    # Remove [letter]/[letter] patterns
    local node=$(echo "$input_string" | sed -E 's/[a-zA-Z]\/[a-zA-Z]//g')

    # Remove single special characters and surrounding spaces
    node=$(echo "$node" | sed -E 's/\s*[^a-zA-Z0-9\s]\s*//g')

    # Remove patterns like (letter|letter...)
    node=$(echo "$node" | sed -E 's/\([a-zA-Z\|]+\)//g')

    echo "$node"
}

process_line() {
    # Use awk to extract the node and name

    # Extract the last word
    line=$1
    last_word=$(echo "$line" | awk 'NF>0{print $NF}')

    # Remove the last word from the original string
    remaining_string=$(echo "$line" | sed "s/ ${last_word}$//")

    # Remove [number]: pattern from the beginning
    node=$(echo "$remaining_string" | sed -E 's/^[0-9]+://')
    # Remove [letter]/[letter] patterns
    node=$(echo "$node" | sed -E 's/[a-zA-Z]\/[a-zA-Z]//g')

    # Remove single special characters and surrounding spaces
    node=$(echo "$node" | sed -E 's/\s*[^a-zA-Z0-9\s]\s*//g')

    # Remove patterns like (letter|letter...)
    node=$(echo "$node" | sed -E 's/\([a-zA-Z\|]+\)//g')
    node=$(echo "$node" | sed 's/[^0-9]//g')
    
    icat -o $offset $input_file $node > "$out_dir/$extracted_data_dir/$last_word"
    echo ""
    echo "Extracting: $last_word"
    strings "$out_dir/$extracted_data_dir/$last_word"
    echo ""
    }   

# Parse command-line options
while getopts ':do:f:' flag; do
    case "${flag}" in
        d) check_dependencies; exit 0 ;;
        o) offset=${OPTARG} ;;
        f) input_file=${OPTARG} ;;
        *) usage ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$offset" ] || [ -z "$input_file" ] ; then
    echo "Error: Required parameters not provided."
    usage
fi

mkdir -p "$out_dir"
mkdir -p "$out_dir/$extracted_data_dir"

echo "Processing with offset: $offset"
echo "Input file: $input_file" 

echo "Processing with offset: $offset" > "$meta_file"
echo "Input file: $input_file" >> "$meta_file"

wait
echo "Reading filesystem"
fls -o $offset -r $input_file > $filesystem_file

wait
echo "Filesystem processed"
echo ""
read -p "Display filesystem? (y/n): " choice_print_filesystem

if [ "$choice_print_filesystem" = "y" ]; then
    cat $filesystem_file
fi

hasExited=0

while [ $hasExited -eq 0 ] ; do
    wait
    echo ""
    echo "---ACTION----"
    echo "'n' pick specific file via inode"
    echo "'s' filename text search"
    echo "'c' execute arbitrary command"
    echo "'q' exit"
    echo ""
    read -p "Enter command: " choice
    echo ""
 
    case "$choice" in
        "s")
            read -p "Enter search word: " search_word
            echo ""

            output=$(handle_search "$search_word")

            echo "$output"
            echo ""
            read -p "Process all files (y) | Pick specific nodes (n) | cancel operation (q): " process_choice
            echo ""
            if [ "$process_choice" = "y" ]; then
                echo "$output" | while IFS= read -r line; do
                
                process_line "$line"
                done
            elif [ "$process_choice" = "n" ]; then
                echo "Picking specific node[s]..."
                wait
                echo "Enter the index of the row to process (separated by space if multiple):"
                read -a indexes

                for index in "${indexes[@]}"; do
                    line=$(echo "$output" | grep "^$index:")
                    wait
                    process_line "$line"

                    done
            elif [ "$process_choice" = "q" ]; then
                echo ""
            fi
            echo "Ending procedure."
            ;;
        "c")
            read -p "Enter command to execute: " user_command
            echo "Executing command: $user_command"
            eval $user_command
            ;;
        "q")
            echo "Exiting..."
            hasExited=1
            ;;
        "n")
            read -p "Enter inode: " inode
            icat -o $offset $input_file $inode > "$inode.txt"
            cat "$inode.txt"
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
done
