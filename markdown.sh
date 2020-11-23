#! /bin/sh

# FUNCTIONS
awk_sub() { echo "$1" | sed 's/&/\\\\&/g'; }

generate_html() {
    if [ -z "$1" ]; then echo "no input provided"; exit 1; fi

    if [ -v directory ]; then
        relative_path="$(echo "$file" | sed "s:^"$directory"::g; s:[^\/]*\/:..\/:g; s:[^\/]*$::g")style.css"
        head="<link rel=\"stylesheet\" href=\"$relative_path\">"
    else head="<style>$(cat "$css")</style>"; fi

    echo "$html" | awk -v title="$(awk_sub "$title")" -v head="$(awk_sub "$head")" -v content="$(awk_sub "$1")" '{
        sub("{HEAD}", head);
        sub("{CONTENT}", content);
        sub("{TITLE}", title);
        print;
    }'
}

handle_output() {
    if [ -v output ]; then
        if [[ "$output" == */ ]]; then
            dir_output_file="$output$(echo "$file" | sed -e "s:^"$directory"::g; s:\.[^./]*$::g").html"
            mkdir -p "$(dirname "$dir_output_file")"
            echo "$1" > "$dir_output_file"
        else
            filename="$(echo "$output" | awk -v title="$(awk_sub "$title")" '{ sub("{TITLE}", title); print; }')"
            mkdir -p "$(dirname "$filename")"
            echo "$1" > "$filename"
        fi
    else
        echo "$1"
    fi
}

# READ PARAMETERS
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--html) if [ -r "$2" ]; then html="$(cat "$2")"; fi; shift ;;
        -c|--css) if [ -r "$2" ]; then css="$(cat "$2")"; fi; shift ;;
        -o|--output) output="$2"; shift ;;
        -d|--directory) directory="$2"; shift ;;
        *) if [ -r "$1" ]; then markdown_files+=("$1"); fi ;; 
    esac
    shift
done

# LOAD DEFAULTS / PREPARE VARIABLES
dir="$(dirname "$(realpath "$0")")"
if [ ! -v html ]; then html="$(cat "$dir/template.html")"; fi
if [ ! -v css ]; then css="$dir/style_min.css"; fi 
if [[ -v directory && "$output" != */ ]]; then echo "give a directory as output when using --directory"; exit 1; fi

# PROCESS DATA
if [[ -v directory && -v output && "$output" == */ ]]; then # handle directory inputs
    mkdir -p "$output"
    cp "$css" ""$output"style.css"
    css=""$output"style.css"
    
    find "$directory" -type f | while read file; do
        if [[ "$file" == *.md ]]; then
            title="$(basename "${file}" .md)"
            handle_output "$(generate_html "$(cat "${file}" | markdown)")"
        else
            cp "$file" "$output$(echo "$file" | sed -e "s:^"$directory"::g")"
        fi
    done
elif [ -v markdown_files ]; then # handle file inputs
    title="$(basename "${markdown_files%% *}" .md)"
    handle_output "$(generate_html "$(cat "${markdown_files[@]}" | markdown)")"
elif test ! -t 0; then # handle STDIN
    handle_output "$(generate_html "$(markdown <&0)")"
fi
