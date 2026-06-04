#!/bin/bash
# Usage: ./extract.sh gtk.gresource
gs_file=$1
output_dir="extracted_theme"

mkdir -p "$output_dir"

for r in $(gresource list "$gs_file"); do
    # Remove the leading slash and create the directory structure
    relative_path="${r#/}"
    mkdir -p "$output_dir/$(dirname "$relative_path")"
    
    # Extract the resource to the correct folder
    gresource extract "$gs_file" "$r" > "$output_dir/$relative_path"
done

echo "Extraction complete in the '$output_dir' folder."
