#!/usr/bin/env python3

import json
import re
import sys

def fix_json_with_comments(content):
    """Fix JSON content that may have comments and trailing commas."""

    # Remove single-line comments (//)
    lines = content.split('\n')
    cleaned_lines = []

    for line in lines:
        # Remove full comment lines
        if re.match(r'^\s*//', line):
            continue

        # Remove inline comments
        line = re.sub(r'//.*$', '', line)

        # Keep the line
        cleaned_lines.append(line)

    content = '\n'.join(cleaned_lines)

    # Fix trailing commas
    # This regex removes commas that are followed by whitespace and then a closing bracket/brace
    content = re.sub(r',(\s*[}\]])', r'\1', content)

    return content

def main():
    if len(sys.argv) != 3:
        print("Usage: json-fixer.py input_file output_file")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        with open(input_file, 'r') as f:
            content = f.read()

        # Fix the JSON
        fixed_content = fix_json_with_comments(content)

        # Validate it's proper JSON
        parsed = json.loads(fixed_content)

        # Write pretty-formatted JSON
        with open(output_file, 'w') as f:
            json.dump(parsed, f, indent=4)

        print("JSON fixed successfully")
        sys.exit(0)

    except json.JSONDecodeError as e:
        print(f"JSON Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()