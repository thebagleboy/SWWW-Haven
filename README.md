# Swww Haven

Swww Haven is a bash script designed to automate the process of fetching wallpapers from Wallhaven using their API. Intended for use with [swww](https://github.com/LGFae/swww) but if you feel like the change it should be too difficult. It manages a local SQLite database to keep track of downloaded wallpapers and their associated metadata. Below is a detailed README file explaining its functionality, usage, and setup. 

## Features

- **Wallhaven API Integration:** Fetch wallpapers from Wallhaven using their REST API.
- **SQLite Database:** Store wallpaper metadata and track downloads.
- **Colorful Output:** Provides optional colored and verbose output.
- **Action-driven Workflow:** Supports initialization, downloading, and dry runs.
- **Automatic Wallpaper Setting:** Sets a downloaded wallpaper as the desktop background.

## Prerequisites

- **Dependencies:**
  - `bash` (version 4 or higher)
  - `curl`
  - `sqlite3` (optional, required for database functionality)

## Installation

1. **Clone the repository:**
```bash
git clone https://github.com/thebagleboy/swww-console
cd swww-haven
```

2. **Set Permissions**
```bash
chmod +x swww-haven.sh
```

3. **Add to Path** (optional)
```bash
ln -sf <Path/to/repo>/swww-haven/swww-haven.sh ~/.local/bin/swww-haven
```

## Usage
```bash
./swww-haven.sh [options] <action>
```

### Options
- -h, --help: Show help message and exit.
- -v, --version: Show version information and exit.
- --verbose: Enable verbose output.
- --color: Enable colored output.
- -d, --debug: Enable debug output.

### Actions
-   `help`: Show this help message and exit.
-   `init`: Initialize the database.
-   `download`: Run the main script and download wallpapers.
-   `dry`: Run the script without saving any files or database entries.
-   `set`: Set a downloaded wallpaper as the desktop background.

## Examples

### Initialise Database
```bash
$ swww-haven init
```

### Download Wallpapers
```bash
$ swww-haven download
```

### Randomly select a wallpaper
```bash
$ swww-haven set
```

## Notes
### Database    
-   The database file is located at `$HOME/.wallpapers.db`.
-   The schema for the database is defined in `schema.sql`.

### Download Directory
-   Downloaded wallpapers are stored in `$HOME/Pictures/.wallpapers`.

### API Endpoint
-   The script uses the Wallhaven API endpoint `https://wallhaven.cc/api/v1/search`.
 
## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue with any suggestions or improvements.

## Contact

If you have any questions or comments, please contact <aburgecc@ucc.asn.au>.

## Version Information

-   **Version:** 0.1.2
-   **Build:** 3

### TODO List 
- [ ] Ability to toggle between SFW | Sketchy | ~~NSFW~~ categories
- [ ] Assign a random image based upon current screen resolution and image resolution
- [ ] Win the lotto
- [ ] Record allocations to wallpaper to ensure images get rotated through 
- [ ] Add an option to select a wallpaper based upon a colour theme
- [ ] Connect to the bus
- [ ] Add a method to configure the wallpaper storage directory
- [ ] Integrate with Waybar or potentially other Bar programs depending what I feel like using/learning
- [ ] Fix up debug logs
- [ ] Add a connection to create log files
- [ ] ?????????
- [ ] Profit

Theres probably more I can think of as I go about using it.

## Acknowledgments

- Thanks Wallhaven for having an Open API
- This README was generated primarily by Mr ChatGPT. Forever saving me from having to think for myself.

## Disclaimer

This script comes with no guarantees. Use at your own risk.

