#!/bin/bash

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
    # Escape the dot and append '$' if the search word ends with '.log'
    if [[ $search_word == *.log ]]; then
        search_pattern="\\$search_word$"
    else
        search_pattern="$search_word"
    fi

    grep -E "$search_pattern" $filesystem_file > searchresults.txt
    local output=$(grep -E "$search_pattern" $filesystem_file | nl -w1 -s': ')
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
    echo -e "\e[1;32m- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -\e[0;37m"
    echo -e "\e[1;32mExtracting:\e[0;37m $last_word "
    echo -e "\e[0;32mextracted content\e[0;37m"
    echo  ""
    strings "$out_dir/$extracted_data_dir/$last_word"
    echo ""
    }   


print_ascii() {
clear
echo -e "\e[40m"

echo -e "\e[1;37m _____ ____  _  __  ____  _   _ _____ _     _     "
echo -e "|_   _/ ___|| |/ / / ___|| | | | ____| |   | |    "
echo -e "  | | \\___ \\| ' /  \\___ \\| |_| |  _| | |   | |    "
echo -e "  | |  ___) | . \\   ___) |  _  | |___| |___| |___ "
echo -e "  |_| |____/|_|\\_\\ |____/|_| |_|_____|_____|_____|"
echo -e ""
echo -e "- - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo -e "\e[0;37m"

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

print_ascii

echo -e "\e[0;32mProcessing with offset: $offset\e[0;37m "
echo -e "\e[0;32mInput file: $input_file\e[0;37m " 

echo -e "\e[0;32mProcessing with offset: $offset" > "$meta_file \e[0;37m "
echo  "Input file: $input_file" >> "$meta_file"

wait
echo -e "\e[0;32mReading filesystem\e[0;37m "
fls -o $offset -r $input_file > $filesystem_file

wait
echo -e "\e[0;32mFilesystem processed\e[0;37m "

echo ""
read -p "Show filesystem? (y/n): " choice_print_filesystem

if [ "$choice_print_filesystem" = "y" ]; then
    cat $filesystem_file
fi

hasExited=0

while [ $hasExited -eq 0 ] ; do
    wait
    echo ""
    echo -e "\e[\e[1;35m--ACTIONS---- "
    echo -e "'i' inspect specific file via inode"
    echo -e "'s' filename text search"
    echo -e "'c' execute arbitrary command"
    echo -e "'q' exit \e[0;37m	"
    echo ""
    read -p "Enter command: " choice
    echo ""
    print_ascii
    case "$choice" in
        "s")
            read -p "Enter search term: " search_word
            echo -e "\e[0;32msearching...\e[0;37m $last_word "
            wait
            echo ""

            output=$(handle_search "$search_word")

            echo -e "\e[1;32mResults\e[0;37m $last_word "
            echo ""
            echo "$output"
            echo ""
            read -p "Process all files (a) | Pick specific nodes (d) | cancel operation (q): " process_choice
            echo ""
            if [ "$process_choice" = "a" ]; then
                echo "$output" | while IFS= read -r line; do
                
                process_line "$line"
                done
            elif [ "$process_choice" = "d" ]; then
                echo "Picking specific node[s]..."
                echo ""
                wait
                echo -e "Enter the \e[1mindex of the row \e[0m to process (separated by space if multiple):"
                read -a indexes

            for index in "${indexes[@]}"; do
                line=$(echo "$output" | grep "^$index:")
               # echo "Debug: Line to Process - $line" # Add this for debugging
                process_line "$line"
            done
            elif [ "$process_choice" = "q" ]; then
                echo ""
            fi
            echo -e "\e[1;32mEnding procedure.\e[0;37m	"
            ;;
        "c")
            read -p "Enter command to execute: " user_command
            echo "Executing command: $user_command"
            echo -e "\e[1;37m"
            eval $user_command
            ;;
        "q")
            echo "Exiting..."
            hasExited=1
            ;;
        "i")
            read -p "Enter inode: " inode
            icat -o $offset $input_file $inode > "$inode.txt"
            cat "$inode.txt"
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
done
