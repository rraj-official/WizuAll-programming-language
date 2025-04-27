# WizuAll Language

WizuAll is a domain-specific language designed for data visualization. It specializes in quickly creating visualizations from various data sources with a simple and intuitive syntax.

## Features

- Simple syntax for data manipulation and visualization
- Built-in visualization commands (plot, hist, scatter)
- Vector operations and element-wise arithmetic
- PDF, CSV, and text data extraction and visualization
- Conditional logic and loops for data processing
- Debug mode for tracing compilation and execution
- Direct execution from data files (PDF, CSV, TXT)

## Project Structure

The project has been organized into a modular directory structure:

```
.
├── bin/                  # Binary executables
│   └── wizuallc          # WizuAll compiler
├── scripts/              # Helper scripts
│   ├── install.sh        # Installation script
│   ├── preprocess.rb     # Data preprocessing script
│   └── run.sh            # Main execution script
├── src/                  # Source code directory
│   ├── ast.c             # Abstract syntax tree implementation
│   ├── ast.h             # AST header file
│   ├── codegen.c         # Code generation
│   ├── codegen.h         # Code generation header
│   ├── wizuall.l         # Lexer definition (Flex)
│   └── wizuall.y         # Parser definition (Bison)
├── examples/             # Example WizuAll programs
│   ├── line_plots/       # Line plot examples
│   ├── histograms/       # Histogram examples
│   └── scatter_plots/    # Scatter plot examples
├── tests/                # Test files
│   ├── input/            # Test input data
│   └── output/           # Test output data
├── wizz_build/           # Build directory for temporary files
├── Makefile              # Build system
├── README.md             # This documentation
└── wizz.sh               # Wrapper script for easy execution
```

## Installation

### Prerequisites

WizuAll requires the following dependencies:

```bash
# For Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y gcc make flex bison ruby gnuplot poppler-utils

# For Red Hat/Fedora/CentOS
sudo dnf install -y gcc make flex bison ruby gnuplot poppler-utils

# For macOS (using Homebrew)
brew install gcc flex bison ruby gnuplot poppler
```

### Install System-wide

WizuAll includes a convenient installation script to make it accessible from anywhere on your system:

```bash
# Run the installation script (requires sudo)
./scripts/install.sh
```

This script will:
1. Copy the necessary files to `/usr/local/lib/wizuall/`
2. Create a global `wizz` command in `/usr/local/bin/` 
3. Make all scripts executable
4. Copy example files

## Usage

```bash
# Run a WizuAll (.wzl) file directly
./wizz.sh myfile.wzl

# Or if installed globally
wizz myfile.wzl

# Run with debug mode (shows detailed compilation steps)
./wizz.sh --debug myfile.wzl

# Process and visualize data from a PDF file
./wizz.sh -p data.pdf

# Process and visualize data from a text file
./wizz.sh -t data.txt

# Generate a plot from data (CSV, TXT, PDF) with specific plot type
./wizz.sh -l data.csv --title "My Data Visualization" --type scatter
./wizz.sh -l data.csv --title "Line Chart" --type line
./wizz.sh -l data.csv --title "Distribution Chart" --type histogram

# Save the generated WizuAll code when processing data files
./wizz.sh -p data.pdf -o myoutput.wzl
```

## Technical Capabilities

* **Program Flow**: WizuAll uses a comprehensive compilation and execution pipeline, managed by the `run.sh` script:
  - **Data Preprocessing**: Extracts data from various sources (PDF, CSV, TXT) using specialized Ruby scripts
  - **Code Generation**: Creates .wzl files from input data when needed
  - **Lexical Analysis**: Uses Flex to tokenize the source code
  - **Parsing**: Employs Bison to create an Abstract Syntax Tree (AST) from tokens
  - **Semantic Analysis**: Validates program structure and semantics
  - **Symbol Table Management**: Tracks variables, types, and scopes
  - **C Code Generation**: Translates the AST into optimized C code
  - **Compilation**: Uses GCC to compile the generated C code
  - **Execution**: Runs the compiled binary with appropriate parameters

* **Supported Input Formats**:
- **WizuAll Code Files (.wzl)**: Direct execution of WizuAll scripts
- **PDF Files**: Extraction of tabular numeric data
- **Text Files (.txt)**: Parsing of numeric data
- **CSV Files**: Processing of comma-separated values

### Vector Operations

WizuAll supports a variety of vector operations:

- Vector creation: `x = [1, 2, 3, 4, 5];`
- Element-wise arithmetic: Addition, subtraction, multiplication, division
- Scalar-vector operations: `result = vec * 3;`

### Visualization Types

- **Line Plots**: `plot([y1, y2, ...]);` - Creates a line plot from a vector of y-values
- **Histograms**: `histogram([data]);` - Creates a histogram from a vector of values
- **Scatter Plots**: `scatter(x, y);` - Creates a scatter plot of x,y coordinate pairs

#### Plot Type Selection

When using the `-l/--plot` option, you can specify the plot type with `--type`:

```bash
# Generate a scatter plot (default)
./wizz.sh -l data.txt --type scatter

# Generate a line plot
./wizz.sh -l data.txt --type line

# Generate a histogram
./wizz.sh -l data.txt --type histogram
```

For scatter plots, both x and y columns from the data are used. For line plots, only the y column values are used. For histograms, only the first column of data is used.

### Flow Control

```
if (condition) {
    // statements
} else {
    // alternative statements
}

while (condition) {
    // loop body
}
```

### Logging and Debugging

The compiler provides detailed debugging information when the `--debug` flag is used:

- Lexical and syntactic analysis
- AST construction
- Semantic analysis
- Code generation

## Language Syntax

### Variables

```
// Scalar assignment
x = 10;

// Vector assignment
v = [1, 2, 3, 4, 5];
```

### Arithmetic Operations

```
// Scalar operations
a = 10;
b = 20;
c = a + b;

// Vector operations
vec1 = [1, 2, 3];
vec2 = [4, 5, 6];
vec3 = vec1 + vec2;  // Element-wise addition: [5, 7, 9]
```

### Control Structures

```
// If-else statement
if (x > 5) {
    y = 10;
} else {
    y = 5;
}

// While loop
i = 0;
while (i < 10) {
    i = i + 1;
}
```

### Visualization Commands

```
// Line plot - pass a vector of y values
y_values = [5, 7, 9, 11, 13];
plot(y_values);
// Or use a vector literal directly
plot([5, 7, 9, 11, 13]);

// Histogram - pass a vector of data values
data_values = [2.5, 3.2, 1.7, 4.5, 3.7];
histogram(data_values);
// Or use a vector literal directly
histogram([2.5, 3.2, 1.7, 4.5, 3.7]);

// Scatter plot - requires x and y vectors
x = [1, 2, 3, 4, 5];
y = [5, 7, 9, 11, 13];
scatter(x, y);
```

### Comments

```
// This is a single-line comment

# This is also a single-line comment
```

## Examples

Several example WizuAll scripts are provided in the `examples/` directory:

```bash
# Basic examples
./wizz.sh examples/example1.wzl

# Plot examples
./wizz.sh examples/line_plots/testlineplot.wzl
./wizz.sh examples/histograms/testhisto.wzl
./wizz.sh examples/scatter_plots/testplot.wzl

# Generate plots from data
./wizz.sh -l tests/input/testlineplot.txt --type line
./wizz.sh -l tests/input/testhisto.txt --type histogram
./wizz.sh -l tests/input/testplot.txt --type scatter
```

## Limitations and Future Work

- Functions and user-defined procedures are not yet implemented
- Future versions may include more advanced visualization options
- Support for 3D plots and interactive visualizations is planned

## Authors

Rohit Raj
