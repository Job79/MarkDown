#! /bin/sh

# FUNCTIONS
awk_sub() { echo "$1" | sed 's/&/\\\\&/g'; }

generate_html() {
    if [ -z "$1" ]; then echo "no input provided"; exit 1; fi

    if [ -v directory ]; then
        relative_path="$(echo "$file" | sed "s:^"$directory/"::; s:[^\/]*\/:..\/:g; s:[^\/]*$::")style.css"
        head="<link rel=\"stylesheet\" href=\"$relative_path\">"
    else head="<style>$(cat "$css")</style>"; fi

    echo "$html" | awk -v title="$(awk_sub "$title")" -v head="$(awk_sub "$head")" -v content="$(awk_sub "$1")" '{
        sub("{HEAD}", head);
        sub("{CONTENT}", content);
        sub("{TITLE}", title);
        print;
    }'
}

# READ PARAMETERS
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--html) if [ -r "$2" ]; then html="$(cat "$2")"; fi; shift ;;
        -c|--css) if [ -r "$2" ]; then css="$2"; fi; shift ;;
        -o|--output) output="$2"; shift ;;
        -d|--directory) directory="$2"; shift ;;
        *) if [ -r "$1" ]; then markdown_files+=("$1"); fi ;; 
    esac
    shift
done

# LOAD DEFAULTS / PREPARE VARIABLES
markdown_tool="cmark-gfm --unsafe -e table"
dir="$(dirname "$(realpath "$0")")"
if [ ! -v html ]; then html="$(cat "$dir/template.html")"; fi
if [ ! -v css ]; then css="$dir/style.css"; fi 
if [ -v directory ]; then directory="$(echo "$directory" | sed "s/\/$//")"; fi 

# PROCESS INPUT 
if [[ -v directory && -v output ]]; then # handle directory inputs
    mkdir -p "$output"
    cp "$css" "$output/style.css"
    
    find "$directory" -type f | while read file; do
        if [[ "$file" == *.md ]]; then
            title="$(basename "${file}" .md)"
            generated_output="$(generate_html "$(cat "${file}" | $markdown_tool)")"
            output_file="$output/$(echo "$file" | sed -e "s:^"$directory"::; s:\.[^./]*$::g").html"
            mkdir -p "$(dirname "$output_file")"
            echo "$generated_output" > "$output_file"
        else
            output_file="$output/$(echo "$file" | sed -e "s:^"$directory"::")"
            mkdir -p "$(dirname "$output_file")"
            cp "$file" "$output_file"
        fi
    done
    exit
elif [ -v markdown_files ]; then # handle file inputs
    title="$(basename "${markdown_files%% *}" .md)"
    generated_output="$(generate_html "$(cat "${markdown_files[@]}" | $markdown_tool)")"
elif test ! -t 0; then # handle STDIN
    generated_output="$(generate_html "$($markdown_tool <&0)")"
fi

# PROCESS OUTPUT
if [ -v output ]; then
    mkdir -p "$(dirname "$output")"
    echo "$generated_output" > "$output"
else echo "$generated_output"; fi
