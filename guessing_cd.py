
import re
import pandas as pd
import sys

# Function to read genetic codes from a file
def read_genetic_codes(file_path):
    genetic_codes = {}
    with open(file_path, 'r') as file:
        content = file.read()
        entries = re.findall(r'>(.*?)\n([A-Z\*\?]+)', content, re.DOTALL)
        for entry in entries:
            name, code = entry
            name = name.strip()
            code = code.replace('\n', '').strip()
            genetic_codes[name] = code
    return genetic_codes

# Function to compare two genetic codes
def compare_genetic_codes(predicted_code, ncbi_codes):
    best_match = None
    best_match_score = -1
    for name, code in ncbi_codes.items():
        # Simple score based on number of matching characters, ignoring '?'
        match_score = sum(1 for a, b in zip(predicted_code, code) if a == b and a != '?')
        if match_score > best_match_score:
            best_match = name
            best_match_score = match_score
    return best_match

# Load NCBI genetic codes
ncbi_genetic_codes = read_genetic_codes(sys.argv[1])

# Load predicted genetic codes
predicted_genetic_codes = read_genetic_codes(sys.argv[2])

# Compare and assign codes
assignments = {}
for name, predicted_code in predicted_genetic_codes.items():
    best_match = compare_genetic_codes(predicted_code, ncbi_genetic_codes)
    assignments[name] = best_match

# Print the results
for name, best_match in assignments.items():
    print(f"{name} -> {best_match}")

assignments_df = pd.DataFrame(list(assignments.items()), columns=['Predicted_Genome', 'NCBI_Code'])
assignments_df.to_csv('assigned_genetic_codes.csv', index=False)
