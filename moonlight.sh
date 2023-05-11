#!/bin/bash
set -e

# Variables
REPO_FILE="/etc/apt/sources.list.d/moonlight-game-streaming-moonlight-embedded.list"
SCRIPT_DIR="/home/pi/RetroPie/roms/ports"
DESKTOP_SCRIPT="$SCRIPT_DIR/Desktop.sh"
STEAM_SCRIPT="$SCRIPT_DIR/Steam.sh"

# Functions

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Add Moonlight repository if it doesn't exist
add_repository() {
  echo -e "\nAdding Moonlight Repository"
  echo -e "***************************\n"

  if [[ -f "$REPO_FILE" ]]; then
    echo -e "NOTE: Moonlight repository already exists - Skipping"
  else
    echo -e "Adding Moonlight to repository"
    curl -1sLf 'https://dl.cloudsmith.io/public/moonlight-game-streaming/moonlight-embedded/setup.deb.sh' | distro=raspbian codename=$(lsb_release -sc) sudo -E bash
  fi

  echo -e "***************************\n"
}

# Create desktop and Steam launch scripts
create_scripts() {
  echo -e "\nCreate Desktop and Steam Launch Scripts for RetroPie"
  echo -e "****************************************************\n"

  echo -e "Create Ports Folder"
  mkdir -p "$SCRIPT_DIR"
  cd "$SCRIPT_DIR"

  echo -e "Create Scripts"

  if [[ -f "$DESKTOP_SCRIPT" ]]; then
    echo -e "NOTE: Desktop script already exists - Skipping"
  else
    echo "#!/bin/bash" > "$DESKTOP_SCRIPT"
    echo "moonlight stream -1080 -fps 60 -app Desktop" >> "$DESKTOP_SCRIPT"
  fi

  if [[ -f "$STEAM_SCRIPT" ]]; then
    echo -e "NOTE: Steam script already exists - Skipping"
  else
    echo "#!/bin/bash" > "$STEAM_SCRIPT"
    echo "moonlight stream -1080 -fps 60 -app Steam" >> "$STEAM_SCRIPT"
  fi

  echo -e "Make Scripts Executable"
  chmod +x "$DESKTOP_SCRIPT"
  chmod +x "$STEAM_SCRIPT"

  echo -e "Update Permissions"
  echo -e "Changing File Permissions"
  chown -R pi:pi "$SCRIPT_DIR"

  echo -e "****************************************************\n"
}

# Install Moonlight package
install_moonlight() {
  echo -e "\nUpdate System"
  echo -e "*************\n"

  apt-get update -y
  apt-get install moonlight-embedded -y

  echo -e "*************\n"
}

# Pair Moonlight with PC
pair_moonlight() {
  echo -e "\nPair Moonlight with PC"
  echo -e "**********************\n"

  echo -e "Once you have input your PC's IP Address below, you will be given a PIN"
  echo -e "Input this on the PC to pair with Moonlight. \n"
  read -p "Input STEAM PC's IP Address here :`echo $'\n> '`" ip
  sudo -u pi moonlight pair $ip

  echo -e "**********************\n"
}

# Remove all Steam launch scripts
remove_scripts() {
  echo -e "\nRemove All Steam Launch Scripts"
  echo -e "*******************************\n"

  cd "$SCRIPT_DIR"
  rm -f "$DESKTOP_SCRIPT"
  rm -f "$STEAM_SCRIPT"

  echo -e "*******************************\n"
}

# Update the script itself
self_update() {
  echo -e "\nUpdate Moonlight RetroPie"
  echo -e "*****************************\n"

  if [[ -f "/home/pi/moonlight.sh" ]]; then
    echo -e "Removing old script"
    rm "/home/pi/moonlight.sh"
  fi

  wget "https://github.com/danielproctor31/moonlight-retropie/blob/master/moonlight.sh" --no-check-certificate -O "/home/pi/moonlight.sh"
  chown pi:pi "/home/pi/moonlight.sh"
  chmod +x "/home/pi/moonlight.sh"

  echo -e "*****************************\n"

  exec /home/pi/moonlight.sh
}

# Uninstall Moonlight and associated files
uninstall() {
  echo -e "\nUninstalling Everything"
  echo -e "***********************\n"

  rm -f "/usr/share/keyrings/moonlight-game-streaming-moonlight-embedded-archive-keyring.gpg"
  rm -f "/etc/apt/trusted.gpg.d/moonlight-game-streaming-moonlight-embedded.gpg"
  rm -f "$REPO_FILE"

  apt-get update -y
  apt-get purge moonlight-embedded -y

  echo -e "***********************\n"
}

# Main menu
main_menu() {
  echo -e "\n******************************************************"
  echo -e "Welcome to the Moonlight Installer Script for RetroPie"
  echo -e "******************************************************\n"
  echo -e "Select an option:"
  echo -e " * 1: Install"
  echo -e " * 2: Re-Pair with PC"
  echo -e " * 3: Update"
  echo -e " * 4: Uninstall"
  echo -e " * 5: Exit"

  read -r NUM
  case $NUM in
    1)
      add_repository
      install_moonlight
      pair_moonlight
      create_scripts
	  main_menu
      ;;
    2)
      pair_moonlight
      main_menu
      ;;
    3)
      install_moonlight
	  self_update
	  main_menu
      ;;
    4)
      uninstall
	  remove_scripts
	  main_menu
      ;;
    5)
      exit 0
      ;;
    *)
      echo "INVALID NUMBER!"
      ;;
  esac
}

# Main script execution
main_menu