#!/usr/bin/env ruby
# preprocess.rb
#
# Preprocessor for converting CSV, TXT, or PDF data (x, y pairs) to WizuAll (.wzl) plot code.
#
# Steps:
#   1. Determine file type (CSV, TXT, PDF).
#   2. If PDF, convert to temporary text file using pdftotext.
#   3. Read the text content (original or converted).
#   4. Parse each line for the first two numeric values (assuming x, y).
#      - For CSV, splits by comma.
#      - For TXT/PDF-Text, uses regex.
#   5. Generate a WZL file that defines data vectors and calls appropriate plot function.
#
# Usage:
#   preprocess.rb [options] input.csv|input.txt|input.pdf
#   Options:
#       -o, --output FILE    Specify the output WZL file (default: output.wzl)
#       --title TITLE        Specify the plot title (optional)
#       --type TYPE          Specify the plot type: scatter, line, histogram (default: scatter)
#
# Requirements:
#   The script assumes that the "pdftotext" tool (from Poppler)
#   is installed and accessible via the system's PATH, when processing PDFs.

require 'optparse'
require 'tempfile'
require 'fileutils'
require 'csv' # Added for CSV parsing

# Parse command-line options.
options = {
  title: 'Data Visualization', # Default title
  type: 'scatter'              # Default plot type
}

OptionParser.new do |opts|
  opts.banner = "Usage: preprocess.rb [options] input.csv|input.txt|input.pdf"

  opts.on("-o", "--output FILE", "Output WZL file") do |file|
    options[:output] = file
  end
  
  opts.on("--title TITLE", "Chart title") do |title|
    options[:title] = title
  end
  
  opts.on("--type TYPE", "Plot type (scatter, line, histogram)") do |type|
    unless ['scatter', 'line', 'histogram'].include?(type)
      STDERR.puts "Error: Invalid plot type '#{type}'. Must be 'scatter', 'line', or 'histogram'."
      exit 1
    end
    options[:type] = type
  end
end.parse!

if ARGV.empty?
  STDERR.puts "Error: No input file provided."
  puts OptionParser.new.help # Show help on error
  exit 1
end

input_file = ARGV[0]
output_wzl = options[:output] || input_file.sub(/\.(pdf|txt|csv)$/i, ".wzl")

# Determine input file type
file_ext = File.extname(input_file).downcase
is_pdf = file_ext == '.pdf'
is_csv = file_ext == '.csv'

if !File.exist?(input_file)
  STDERR.puts "Error: Input file '#{input_file}' does not exist."
  exit 1
end

# Create text content if input is PDF
# text_path will hold the path to the text data to be processed
if is_pdf
  puts "Processing PDF file: #{input_file}... (Requires pdftotext)"
  # Create a temporary file for the text content
  text_file = Tempfile.new([File.basename(input_file, '.*'), '.txt'])
  text_path = text_file.path
  text_file.close

  # Run pdftotext to convert the PDF to text
  unless system("pdftotext \"#{input_file}\" \"#{text_path}\"")
    STDERR.puts "Error: pdftotext failed. Ensure it is installed (poppler-utils) and the PDF file is valid."
    exit 1
  end
else
  # For CSV or TXT, use the input file path directly
  puts "Processing #{is_csv ? 'CSV' : 'TXT'} file: #{input_file}"
  text_path = input_file
end

# Read the text content
puts "Extracting numeric data from #{input_file}..."
lines = File.readlines(text_path)

# Extract numeric data from the text file
data_x = []
data_y = []

# Define a regular expression that matches numbers (including optional signs and decimals)
number_regex = /[-+]?(\d*\.\d+|\d+)/ # Improved regex for numbers

# For PDF files, aggregate all numbers first then pair them
if is_pdf
  all_numbers = []
  lines.each do |line|
    line.strip!
    next if line.empty? || line.start_with?('#') || line.start_with?('//')
    # Extract all numbers from the line
    line_numbers = line.scan(number_regex).flatten.compact
    all_numbers.concat(line_numbers) if line_numbers.any?
  end
  
  # Ensure we have pairs of numbers
  if all_numbers.size >= 2
    # Group numbers into pairs for x,y coordinates
    (0...all_numbers.size).step(2) do |i|
      break if i + 1 >= all_numbers.size
      data_x << all_numbers[i]
      data_y << all_numbers[i + 1]
    end
  end
else
  # Process each line of the text file (for CSV and TXT)
  lines.each_with_index do |line, index|
    line.strip!
    next if line.empty? || line.start_with?('#') # Skip empty lines and comments

    numbers = []
    if is_csv
      begin
        # Parse CSV row, take the first two elements
        row = CSV.parse_line(line)
        if row && row.size >= 2
          # Attempt to convert first two elements that look like numbers
          num1_match = row[0].to_s.match(number_regex)
          num2_match = row[1].to_s.match(number_regex)
          if num1_match && num2_match
            numbers = [num1_match[0], num2_match[0]]
          end
        end
      rescue CSV::MalformedCSVError
        # Skip malformed CSV lines gracefully, maybe log in future
        STDERR.puts "Warning: Skipping malformed CSV line #{index + 1}: #{line}" if index < 10 # Limit warnings
        next
      end
    else # For TXT or PDF-derived text
      # Extract all numeric tokens from the line using regex
      numbers = line.scan(number_regex).map(&:first)
    end

    if numbers.size >= 2
      # If there are at least two numbers, assume it's tabular data
      data_x << numbers[0]
      data_y << numbers[1]
    # else: If fewer than 2 numbers found on the line, skip it
    end
  end
end

# Clean up the temporary text file if it was created for PDF
if is_pdf && text_file # Ensure text_file was created
  File.unlink(text_path) if File.exist?(text_path)
end

if data_x.empty? || data_y.empty?
  STDERR.puts "Error: No valid x, y numeric data pairs found in '#{input_file}'."
  STDERR.puts "Ensure the file contains lines with at least two numbers."
  exit 1
end

# Generate the WZL file based on the plot type
puts "Generating WZL file: #{output_wzl} (#{options[:type]} plot)"
File.open(output_wzl, "w") do |wzl_file|
  wzl_file.puts "// Auto-generated #{options[:type]} plot code from #{File.basename(input_file)}"
  wzl_file.puts "// Title: #{options[:title]}"
  wzl_file.puts "// Data points: #{data_x.size}"
  wzl_file.puts ""
  
  case options[:type]
  when 'scatter'
    # Scatter plot needs both x and y vectors
    wzl_file.puts "// X values"
    wzl_file.puts "x = [#{data_x.join(', ')}];"
    wzl_file.puts ""
    
    wzl_file.puts "// Y values"
    wzl_file.puts "y = [#{data_y.join(', ')}];"
    wzl_file.puts ""
    
    wzl_file.puts "// Generate scatter plot"
    wzl_file.puts "// title(\"#{options[:title]}\"); // Optional: Uncomment and use if title function exists in WizuAll"
    wzl_file.puts "scatter(x, y);"
  when 'line'
    # Line plot takes a single vector argument 
    # For line plots, we'll use the y values directly
    wzl_file.puts "// Generate line plot with Y values"
    wzl_file.puts "// Using direct vector literal with plot()"
    wzl_file.puts "plot([#{data_y.join(', ')}]);"
  when 'histogram'
    # Histogram only needs the x values as a single vector
    wzl_file.puts "// Generate histogram with data values"
    wzl_file.puts "// Using direct vector literal with histogram()"
    wzl_file.puts "histogram([#{data_x.join(', ')}]);"
  end
end

puts "Successfully generated WZL file for #{options[:type]} plot:"
puts "  Input: #{input_file} (#{is_pdf ? 'PDF' : (is_csv ? 'CSV' : 'TXT')})"
puts "  Output: #{output_wzl}"
puts "  Data points: #{data_x.size}"
puts ""
puts "You can now run the visualization with: ./wizz.sh #{output_wzl}"