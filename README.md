# Sleuth Kit Shell

![tskshell](https://github.com/d-swn/tsk-shell/assets/149192290/09158439-b97a-44ec-98dc-60f4e4b6634a)

## File Extraction Script

This Bash script is designed for processing and extracting data from a specified input file utilizing [The Sleuth Kit](https://github.com/sleuthkit/sleuthkit). It offers various features including checking dependencies, extracting data based on inode values, and providing an interactive search within the filesystem.

## Features

- **Dependency Checking**: Ensures all necessary tools are installed.
- **Data Extraction**: Facilitates extraction of data based on inode values.
- **Interactive Search**: Allows for searching text within the filesystem and selecting specific nodes for processing.
- **Arbitrary Command Execution**: Enables execution of user-specified commands.

## Usage

To use the script, run:

```bash
./script.sh -o OFFSET -f INPUT_FILE
```

## Options

```
-o OFFSET: Specifies the offset value to be used in the script
-f INPUT_FILE: Defines the input file for the script to process
-d: Checks if all dependencies are installed.
```
 ## Interactive Mode

 After initial processing, the script enters an interactive mode with the following commands:

```
'i': Inspect specific file via inode
's': Perform a filename text search
'c': Execute an arbitrary command
'q': Exit the script
```

## Directory Structure

Output directory: ```out/```

Extracted data directory:  ```out/extracted```

## Example

```bash
./run.sh -o 2048 -f example.dd
```

## Dependencies

 fls, grep, awk, sed, strings, icat
