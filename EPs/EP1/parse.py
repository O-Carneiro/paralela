import os
import re
import csv

# Regular expression to match the argument and time with stddev
arg_pattern = re.compile(r"Performance counter stats for '\./mandelbrot_... [-\d.]+ [-\d.]+ [-\d.]+ [-\d.]+ (\d+)'")
time_pattern = re.compile(r"\s+(\d+,\d+) \+- (\d+,\d+) seconds time elapsed\s+\( \+-  (\d+,\d+)% \)")

def parse_files(input_dir):
    # Directory containing the input files
    output_dir = input_dir.replace('results','CSVs')  # Directory to save the CSV file

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    def process_file(filepath):
        data = []
        
        # Read the file
        with open(filepath, 'r') as file:
            content = file.read()
            
            # Find all matches for the arguments and execution times
            arg_matches = arg_pattern.findall(content)
            time_matches = time_pattern.findall(content)
            
            print(f"Processing {filepath}...")
            print(f"Found {len(arg_matches)} arguments and {len(time_matches)} time entries.")
            
            # Ensure we have corresponding time and arg matches
            if len(arg_matches) == len(time_matches):
                for arg, (time, stddev_secs, stddev_percent) in zip(arg_matches, time_matches):
                    # Convert from comma decimal format to float
                    time = float(time.replace(',', '.'))
                    stddev_secs = float(stddev_secs.replace(',','.'))
                    stddev_percent = float(stddev_percent.replace(',', '.'))
                    data.append([int(arg), time, stddev_secs, stddev_percent])
            else:
                print(f"Mismatch in arguments and time entries in {filepath}.")
        
        return data

    # Process all files in the input directory
    for filename in os.listdir(input_dir):
        if filename.endswith(".log"):  # Assuming files have .txt extension
            filepath = os.path.join(input_dir, filename)
            result_data = process_file(filepath)
            
            # Only write to CSV if there's data
            if result_data:
                # Create corresponding CSV filename
                output_filepath = os.path.join(output_dir, f"{os.path.splitext(filename)[0]}.csv")
                
                # Write to CSV
                with open(output_filepath, 'w', newline='') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerow(['Argument', 'Execution Time (s)', 'Standard Deviation (s)','Standard Deviation (%)'])
                    writer.writerows(result_data)

                print(f"Processed {filename} and saved to {output_filepath}")
            else:
                print(f"No data extracted from {filename}.")

dirs = os.listdir('./results/')
father_dir = './results/'

for dir in dirs:
    parse_files(father_dir+dir)
