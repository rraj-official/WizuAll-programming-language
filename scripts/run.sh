#!/bin/bash

# Initialize flags
DEBUG_MODE=false
PROCESS_MODE="" # Replaces PDF_MODE. Can be "pdf_code", "text_code", "plot_data"
INPUT_FILE_ARG="" # Store the argument passed to -p, -t, or -l
OUTPUT_FILE=""
PLOT_TYPE="scatter" # Default plot type (scatter, line, histogram)
UPDATE_MODE=false # Flag for update mode

# Set base paths
BASE_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
BIN_DIR="$BASE_DIR/bin"
SCRIPTS_DIR="$BASE_DIR/scripts"
TESTS_DIR="$BASE_DIR/tests"
EXAMPLES_DIR="$BASE_DIR/examples"
REPO_URL="https://github.com/rraj-official/WizuAll-programming-language"

# Function to show usage
show_usage() {
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║               Welcome to WizuAll 1.2                 ║"
    echo "║            Visualize All in One Language             ║"
    echo "║                 by Rohit Raj                         ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "Usage: $0 [options] <command>"
    echo ""
    echo "Commands:"
    echo "  <file.wzl>                  Execute a WizuAll file directly"
    echo "  -p, --pdf <file.pdf>        Execute WizuAll code directly from a PDF file"
    echo "  -t, --text <file.txt>       Execute WizuAll code from a text file"
    echo "  -l, --plot <datafile>       Generate plot from data (CSV, TXT, PDF)"
    echo "  -u, --update                Update WizuAll from GitHub repository and refresh system-wide installation"
    echo ""
    echo "Options:"
    echo "  --debug                     Enable debug mode"
    echo "  -o, --output <file.wzl>     Output WZL file when using -p, -t, or -l mode"
    echo "  --title <title>             Plot title for -l mode (passed to preprocess.rb)"
    echo "  --type <type>               Plot type for -l mode: scatter, line, histogram (default: scatter)"
    echo ""
    exit 1
}

PLOT_TITLE="Data Visualization" # Default plot title for -l mode

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            DEBUG_MODE=true
            shift
            ;;
        -p|--pdf)
            if [ ! -z "$PROCESS_MODE" ]; then echo "Error: Cannot mix -p, -t, or -l options."; show_usage; fi
            PROCESS_MODE="pdf_code"
            if [[ -z "$2" || "$2" == -* ]]; then echo "Error: PDF file argument is missing for -p"; show_usage; fi
            INPUT_FILE_ARG="$2"
            shift 2
            ;;
        -t|--text)
            if [ ! -z "$PROCESS_MODE" ]; then echo "Error: Cannot mix -p, -t, or -l options."; show_usage; fi
            PROCESS_MODE="text_code"
            if [[ -z "$2" || "$2" == -* ]]; then echo "Error: Text file argument is missing for -t"; show_usage; fi
            INPUT_FILE_ARG="$2"
            shift 2
            ;;
        -l|--plot)
            if [ ! -z "$PROCESS_MODE" ]; then echo "Error: Cannot mix -p, -t, or -l options."; show_usage; fi
            PROCESS_MODE="plot_data"
            if [[ -z "$2" || "$2" == -* ]]; then echo "Error: Data file argument is missing for -l"; show_usage; fi
            INPUT_FILE_ARG="$2" # CSV, TXT, or PDF
            shift 2
            ;;
        -u|--update)
            UPDATE_MODE=true
            shift
            ;;
        -o|--output)
            if [[ -z "$2" || "$2" == -* ]]; then echo "Error: Output file argument is missing for -o"; show_usage; fi
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --title) # Option for plot title
             if [[ -z "$2" || "$2" == -* ]]; then echo "Error: Title argument is missing for --title"; show_usage; fi
             PLOT_TITLE="$2"
             shift 2
             ;;
        --type) # New option for plot type
             if [[ -z "$2" || "$2" == -* ]]; then echo "Error: Type argument is missing for --type"; show_usage; fi
             if [[ "$2" != "scatter" && "$2" != "line" && "$2" != "histogram" ]]; then
                 echo "Error: Invalid plot type '$2'. Must be 'scatter', 'line', or 'histogram'."
                 show_usage
             fi
             PLOT_TYPE="$2"
             shift 2
             ;;
        -h|--help)
            show_usage
            ;;
        *)
            # If no process mode is set, assume the argument is the direct WZL file
            if [ -z "$PROCESS_MODE" ] && [ "$UPDATE_MODE" = false ]; then
                if [[ -z "$INPUT_FILE" ]]; then
                    INPUT_FILE="$1"
                else
                    echo "Error: Unexpected argument '$1'. Only one input file allowed unless using -p, -t, or -l."
                    show_usage
                fi
            elif [[ ! -z "$1" ]]; then
                 echo "Error: Unexpected argument '$1' when using -p, -t, or -l."
                 show_usage
            fi
            shift
            ;;
    esac
done

# Handle update mode if specified
if [ "$UPDATE_MODE" = true ]; then
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║               Welcome to WizuAll 1.2                 ║"
    echo "║            Visualize All in One Language             ║"
    echo "║                 by Rohit Raj                         ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "┌─────────────────────────────────────────┐"
    echo "│        Updating WizuAll from GitHub     │"
    echo "└─────────────────────────────────────────┘"
    
    # Create temporary directory for update
    TEMP_DIR=$(mktemp -d)
    
    echo "Cloning latest version from GitHub..."
    if ! git clone "$REPO_URL" "$TEMP_DIR"; then
        echo "Error: Failed to clone repository. Check your internet connection and try again."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    echo "Building from source..."
    cd "$TEMP_DIR"
    if ! make; then
        echo "Error: Build failed. Please check for any compilation errors."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    echo "Installing updated version..."
    # Use the install.sh from the current script directory
    if ! cd "$TEMP_DIR" && bash "$TEMP_DIR/scripts/install.sh"; then
        echo "Error: Installation failed. Check if the install script exists and you have proper permissions."
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    echo "Cleaning up..."
    rm -rf "$TEMP_DIR"
    
    echo "✓ WizuAll has been successfully updated to the latest version!"
    exit 0
fi

# --- Input File Preprocessing ---

WZL_TARGET_FILE="" # Define the target file for generated WZL code

if [ ! -z "$PROCESS_MODE" ]; then # Check if any processing mode (-p, -t, -l) is active
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║               Welcome to WizuAll 1.2                 ║"
    echo "║            Visualize All in One Language             ║"
    echo "║                 by Rohit Raj                         ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""

    # Check if the input file exists for the selected mode
    if [ ! -f "$INPUT_FILE_ARG" ]; then
        echo "Error: Input file '$INPUT_FILE_ARG' does not exist for mode '$PROCESS_MODE'"
        exit 1
    fi

    # Determine target WZL file name
    if [ -z "$OUTPUT_FILE" ]; then
        WZL_TARGET_FILE="${INPUT_FILE_ARG%.*}.wzl" # Default: input_basename.wzl
    else
        WZL_TARGET_FILE="$OUTPUT_FILE"
    fi

    CONVERSION_EXIT_CODE=1 # Default to error
    CONVERSION_ERROR_MSG=""

    case "$PROCESS_MODE" in
        "pdf_code")
            echo "┌─────────────────────────────────────────┐"
            echo "│        Direct PDF -> WZL Code Mode      │"
            echo "└─────────────────────────────────────────┘"
            echo "Converting PDF content to WZL code ($WZL_TARGET_FILE)..."
            pdftotext "$INPUT_FILE_ARG" "$WZL_TARGET_FILE"
            CONVERSION_EXIT_CODE=$?
            CONVERSION_ERROR_MSG="Error: pdftotext conversion failed. Is poppler-utils installed?"
            ;;
        "text_code")
            echo "┌─────────────────────────────────────────┐"
            echo "│        Direct Text -> WZL Code Mode     │"
            echo "└─────────────────────────────────────────┘"
            echo "Preparing WZL file ($WZL_TARGET_FILE) from text input..."
            cp "$INPUT_FILE_ARG" "$WZL_TARGET_FILE"
            CONVERSION_EXIT_CODE=$?
            CONVERSION_ERROR_MSG="Error: Failed to copy '$INPUT_FILE_ARG' to '$WZL_TARGET_FILE'"
            ;;
        "plot_data")
            echo "┌─────────────────────────────────────────┐"
            echo "│        Data Plotting Mode (-l)          │"
            echo "└─────────────────────────────────────────┘"
            echo "Preprocessing data file ($INPUT_FILE_ARG) for $PLOT_TYPE plot..."
            # Call preprocess.rb, passing the title and plot type
            "$SCRIPTS_DIR/preprocess.rb" --title "$PLOT_TITLE" --type "$PLOT_TYPE" -o "$WZL_TARGET_FILE" "$INPUT_FILE_ARG"
            CONVERSION_EXIT_CODE=$?
            CONVERSION_ERROR_MSG="Error: preprocess.rb failed. Check Ruby installation and script errors."
            ;;
    esac

    # Check if operation was successful
    if [ $CONVERSION_EXIT_CODE -ne 0 ]; then
        echo "$CONVERSION_ERROR_MSG"
        exit 1
    fi

    # Set the generated WZL file as the input file for the next stage
    INPUT_FILE="$WZL_TARGET_FILE"
    echo "Using generated WZL file: $INPUT_FILE"
    echo ""

elif [ -z "$INPUT_FILE" ]; then
    # If no processing mode and no direct WZL file given
    echo "Error: No input specified."
    show_usage
fi

# Check if final input file exists (either provided directly or generated)
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input WZL file '$INPUT_FILE' not found or could not be generated."
    exit 1
fi

# Only show welcome message if not already shown by a processing mode
if [ -z "$PROCESS_MODE" ]; then
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║               Welcome to WizuAll 1.2                 ║"
    echo "║            Visualize All in One Language             ║"
    echo "║                 by Rohit Raj                         ║"
    echo "║                                                      ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
fi

# --- Compilation and Execution --- (Remains the same)
BUILD_DIR="$BASE_DIR/wizz_build"
OUT_C_FILE="$BUILD_DIR/wizuall_out.c"
EXEC_FILE="$BUILD_DIR/exec"

log_message() {
    if [ "$DEBUG_MODE" = true ]; then echo "$1"; fi
}

log_message "Cleaning up previous build..."
make clean > /dev/null 2>&1
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

log_message "Building wizuall compiler..."
if [ "$DEBUG_MODE" = true ]; then make; else make > /dev/null 2>&1; fi
if [ $? -ne 0 ] || [ ! -f "$BIN_DIR/wizuallc" ]; then echo "Failed to build wizuall compiler"; exit 1; fi

log_message "Compiling '$INPUT_FILE' to C..."
if [ "$DEBUG_MODE" = true ]; then
    echo "┌─ Debug mode enabled ─┐"; "$BIN_DIR/wizuallc" --debug "$INPUT_FILE" "$OUT_C_FILE"
else
    "$BIN_DIR/wizuallc" "$INPUT_FILE" "$OUT_C_FILE"
fi
if [ $? -ne 0 ] || [ ! -f "$OUT_C_FILE" ]; then echo "Failed to generate C code from '$INPUT_FILE'"; exit 1; fi

log_message "Compiling C code ($OUT_C_FILE) to executable..."
gcc -o $EXEC_FILE $OUT_C_FILE -lm
if [ $? -ne 0 ] || [ ! -f "$EXEC_FILE" ]; then echo "Failed to compile C code ($OUT_C_FILE)"; exit 1; fi

if [ "$DEBUG_MODE" = true ]; then
    echo "┌─ Program Output (debug) ─┐"; $EXEC_FILE; echo "└────────────────────────────┘"; echo "Execution completed"
else
    echo "┌─ Program Output ─┐"; $EXEC_FILE
fi