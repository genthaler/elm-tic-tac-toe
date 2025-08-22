#!/bin/bash

# Generic find and replace script
# Usage: ./scripts/find_replace.sh <file_glob> <search_text> <replacement_text>
# Example: ./scripts/find_replace.sh "tests/**/*.elm" ".backgroundColor" ".backgroundColorHex"

set -e  # Exit on any error

# Check if correct number of arguments provided
if [ $# -lt 3 ] || [ $# -gt 4 ]; then
    echo "❌ Error: Incorrect number of arguments"
    echo "Usage: $0 <file_glob> <search_text> <replacement_text> [--yes]"
    echo ""
    echo "Examples:"
    echo "  $0 'tests/**/*.elm' '.backgroundColor' '.backgroundColorHex'"
    echo "  $0 'src/**/*.elm' 'oldFunction' 'newFunction' --yes"
    echo "  $0 '*.md' 'TODO' 'DONE'"
    exit 1
fi

FILE_GLOB="$1"
SEARCH_TEXT="$2"
REPLACEMENT_TEXT="$3"
AUTO_YES="$4"

echo "🔍 Find and Replace Script"
echo "=========================="
echo "File pattern: $FILE_GLOB"
echo "Search for:   $SEARCH_TEXT"
echo "Replace with: $REPLACEMENT_TEXT"
echo ""

# Find matching files
MATCHING_FILES=$(find . -path "./$FILE_GLOB" -type f 2>/dev/null || true)

if [ -z "$MATCHING_FILES" ]; then
    echo "❌ No files found matching pattern: $FILE_GLOB"
    exit 1
fi

# Count files
FILE_COUNT=$(echo "$MATCHING_FILES" | wc -l | tr -d ' ')
echo "📁 Found $FILE_COUNT files matching pattern"

# Show files that will be modified (first 10)
echo "Files to be modified:"
echo "$MATCHING_FILES" | head -10
if [ $FILE_COUNT -gt 10 ]; then
    echo "... and $((FILE_COUNT - 10)) more files"
fi
echo ""

# Ask for confirmation (unless --yes flag is provided)
if [ "$AUTO_YES" != "--yes" ]; then
    read -p "❓ Proceed with replacement? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Operation cancelled"
        exit 0
    fi
else
    echo "🚀 Auto-proceeding with --yes flag"
fi

# Perform the replacement
echo "🔄 Performing replacement..."
MODIFIED_COUNT=0

while IFS= read -r file; do
    if [ -f "$file" ]; then
        # Check if file contains the search text
        if grep -q "$SEARCH_TEXT" "$file" 2>/dev/null; then
            # Escape special characters for sed
            ESCAPED_SEARCH=$(printf '%s\n' "$SEARCH_TEXT" | sed 's/[[\.*^$()+?{|]/\\&/g')
            ESCAPED_REPLACE=$(printf '%s\n' "$REPLACEMENT_TEXT" | sed 's/[[\.*^$(){}|]/\\&/g; s/&/\\&/g')
            
            # Perform replacement
            sed -i '' "s/$ESCAPED_SEARCH/$ESCAPED_REPLACE/g" "$file"
            MODIFIED_COUNT=$((MODIFIED_COUNT + 1))
            echo "  ✅ Modified: $file"
        fi
    fi
done <<< "$MATCHING_FILES"

echo ""
echo "✅ Replacement complete!"
echo "📊 Modified $MODIFIED_COUNT out of $FILE_COUNT files"
echo "💡 Tip: Run your tests to verify the changes work correctly"