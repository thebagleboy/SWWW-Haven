#!/bin/bash

# Function to fetch current wallpaper
fetch_wallpaper() {
    # Run the smg command and capture its output
    output=$(swww query)

    # Extract the "currently displaying" property
    currently_displaying=$(echo "$output" | grep -o 'currently displaying: image: .*' | sed 's/currently displaying: image: //')

    # Extract the filename without extension
    filename=$(basename "$currently_displaying")
    filename_without_extension="${filename%.*}"

    # Print the result
    echo "$filename_without_extension"
}



# Function to get the text to display in Waybar
get_text() {
    # Modify this to fetch the desired information
    current_wallpaper=$(fetch_wallpaper)
    echo " Current wallpaper: $current_wallpaper"
}

handle_click() {
    swww-haven set
}


# Main function
main() {
    # Check the action (if any)
    if [[ "$1" == "click" ]]; then
        handle_click
        exit 0
    fi

    # Get the text to display
    text=$(get_text)
    tooltip="Click to change wallpaper"

    # Output JSON for Waybar
    printf '{"text":"%s", "tooltip":"%s","class":"swww-haven-bar"}' "$text" "$tooltip"
}

# Execute main function
main "$@"
