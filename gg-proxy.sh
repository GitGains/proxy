#!/bin/bash

GG_PROXY_SCRIPT="$HOME/gg-proxy.sh"
GG_PROXY_CONFIG="$HOME/.gg-proxy"
GG_PROXY_VERSION="1.0.1"

GG_GITHUB_REPO="GitGains/proxy"

gg-detect_profile_file() {
  # Detect the current shell
  current_shell=$(basename "$SHELL")

  # Determine the profile file based on the shell
  case "$current_shell" in
    bash)
      if [ -f "$HOME/.bash_profile" ]; then
        echo "$HOME/.bash_profile"
      elif [ -f "$HOME/.bashrc" ]; then
        echo "$HOME/.bashrc"
      else
        echo "$HOME/.profile"
      fi
      ;;
    zsh)
      echo "$HOME/.zshrc"
      ;;
    ksh)
      echo "$HOME/.kshrc"
      ;;
    *)
      echo "Unsupported shell: $current_shell" >&2
      return 1
      ;;
  esac
}

gg-save_proxy_variables() {
  # Remove the existing config file
  rm -f "$GG_PROXY_CONFIG"

  # Create a new config file
  touch "$GG_PROXY_CONFIG"

  # Save the username and token if they are provided
  if [ -n "$1" ] && [ -n "$2" ]; then
    echo "USER_ID=$1" >> "$GG_PROXY_CONFIG"
    echo "USER_TOKEN=$2" >> "$GG_PROXY_CONFIG"
  fi

  # Save the current npm registry configuration if npm is installed
  if command -v npm &> /dev/null; then
    echo "ORIGINAL_NPM_CONFIG_REGISTRY=$(npm config get registry 2>/dev/null)" >> "$GG_PROXY_CONFIG"
  fi

  # Save the current yarn registry configuration if yarn is installed
  if command -v yarn &> /dev/null; then
    echo "ORIGINAL_YARN_CONFIG_REGISTRY=$(yarn config get registry 2>/dev/null)" >> "$GG_PROXY_CONFIG"
  fi

  # Save the current pip index URL configuration if pip is installed
  if command -v pip &> /dev/null; then
    echo "ORIGINAL_PIP_CONFIG_INDEX_URL=$(pip config get global.index-url 2>/dev/null)" >> "$GG_PROXY_CONFIG"
  fi

  # Save the current pip3 index URL configuration if pip3 is installed
  if command -v pip3 &> /dev/null; then
    echo "ORIGINAL_PIP3_CONFIG_INDEX_URL=$(pip3 config get global.index-url 2>/dev/null)" >> "$GG_PROXY_CONFIG"
  fi

  # Save the current python pip index URL configuration if python is installed
  if command -v python &> /dev/null; then
    echo "ORIGINAL_PYTHON_CONFIG_INDEX_URL=$(python -m pip config get global.index-url 2>/dev/null)" >> "$GG_PROXY_CONFIG"
  fi

  # Save the current python3 pip index URL configuration if python3 is installed
  if command -v python3 &> /dev/null; then
    echo "ORIGINAL_PYTHON3_CONFIG_INDEX_URL=$(python3 -m pip config get global.index-url 2>/dev/null)" >> "$GG_PROXY_CONFIG"
  fi

  # Save the current GOPROXY configuration if Go is installed
  if command -v go &> /dev/null; then
    echo "ORIGINAL_GOPROXY=$(go env GOPROXY 2>/dev/null)" >> "$GG_PROXY_CONFIG"
  fi
}

gg-activate() {
  # Load the original variables from the GG_PROXY_CONFIG file
  if [ -f "$GG_PROXY_CONFIG" ]; then
    # shellcheck source=$HOME/.gg-proxy
    source "$GG_PROXY_CONFIG"
  fi

  # Set the proxy URL
  GG_PROXY_URL="https://$USER_ID:$USER_TOKEN@a.gitgains.org/p"

  # Configure the proxy settings for various tools

  # Set GOPROXY if golang is installed
  if command -v go &> /dev/null; then
    if [ -z "$GOPROXY" ]; then
      go env -w GOPROXY="$GG_PROXY_URL,https://proxy.golang.org,direct" &> /dev/null
    else
      go env -w GOPROXY="$GG_PROXY_URL,$(go env GOPROXY 2>/dev/null)" &> /dev/null
    fi
  fi

  # Set npm config if npm is installed
  if command -v npm &> /dev/null; then
    npm config set registry "$GG_PROXY_URL" &> /dev/null
  fi

  # Set yarn config if yarn is installed
  if command -v yarn &> /dev/null; then
    yarn config set registry "$GG_PROXY_URL" &> /dev/null
  fi

  # Set python pip config if python is installed
  if command -v pip &> /dev/null; then
    pip config --user set global.index-url "$GG_PROXY_URL" &> /dev/null
  fi
  if command -v pip3 &> /dev/null; then
    pip3 config --user set global.index-url "$GG_PROXY_URL" &> /dev/null
  fi
  if command -v python &> /dev/null; then
    python -m pip config --user set global.index-url "$GG_PROXY_URL" &> /dev/null
  fi
  if command -v python3 &> /dev/null; then
    python3 -m pip config --user set global.index-url "$GG_PROXY_URL" &> /dev/null
  fi

  echo "GitGains Proxy activated ✅"
}

gg-deactivate() {
  # Load the original variables from the GG_PROXY_CONFIG file
  if [ -f "$GG_PROXY_CONFIG" ]; then
    # shellcheck source=$HOME/.gg-proxy
    source "$GG_PROXY_CONFIG"
  fi

  # Restore or unset the original GOPROXY configuration if Go is installed
  if command -v go &> /dev/null; then
    if [ -n "$ORIGINAL_GOPROXY" ]; then
      go env -w GOPROXY="$ORIGINAL_GOPROXY" &> /dev/null
    else
      go env -u GOPROXY &> /dev/null
    fi
  fi

  # Restore or unset the original npm registry configuration if npm is installed
  if command -v npm &> /dev/null; then
    if [ -n "$ORIGINAL_NPM_CONFIG_REGISTRY" ]; then
      npm config set registry "$ORIGINAL_NPM_CONFIG_REGISTRY" &> /dev/null
    else
      npm config delete registry &> /dev/null
    fi
  fi

  # Restore or unset the original yarn registry configuration if yarn is installed
  if command -v yarn &> /dev/null; then
    if [ -n "$ORIGINAL_YARN_CONFIG_REGISTRY" ]; then
      yarn config set registry "$ORIGINAL_YARN_CONFIG_REGISTRY" &> /dev/null
    else
      yarn config delete registry &> /dev/null
    fi
  fi

  # Restore or unset the original pip index URL configuration if pip is installed
  if command -v pip &> /dev/null; then
    if [ -n "$ORIGINAL_PIP_CONFIG_INDEX_URL" ]; then
      pip config --user set global.index-url "$ORIGINAL_PIP_CONFIG_INDEX_URL" &> /dev/null
    else
      pip config --user unset global.index-url &> /dev/null
    fi
  fi

  # Restore or unset the original pip3 index URL configuration if pip3 is installed
  if command -v pip3 &> /dev/null; then
    if [ -n "$ORIGINAL_PIP3_CONFIG_INDEX_URL" ]; then
      pip3 config --user set global.index-url "$ORIGINAL_PIP3_CONFIG_INDEX_URL" &> /dev/null
    else
      (pip3 config --user unset global.index-url) &> /dev/null
    fi
  fi

  # Restore or unset the original python pip index URL configuration if python is installed
  if command -v python &> /dev/null; then
    if [ -n "$ORIGINAL_PYTHON_CONFIG_INDEX_URL" ]; then
      python -m pip config --user set global.index-url "$ORIGINAL_PYTHON_CONFIG_INDEX_URL" &> /dev/null
    else
      python -m pip config --user unset global.index-url &> /dev/null
    fi
  fi

  # Restore or unset the original python3 pip index URL configuration if python3 is installed
  if command -v python3 &> /dev/null; then
    if [ -n "$ORIGINAL_PYTHON3_CONFIG_INDEX_URL" ]; then
      python3 -m pip config --user set global.index-url "$ORIGINAL_PYTHON3_CONFIG_INDEX_URL" &> /dev/null
    else
      (python3 -m pip config --user unset global.index-url) &> /dev/null
    fi
  fi

  echo "GitGains Proxy deactivated ❌"
}

gg-uninstall() {
  # Deactivate the proxy
  gg-deactivate

  # Delete the config file
  rm -f "$GG_PROXY_CONFIG"

  # Detect the profile file
  profile_file=$(gg-detect_profile_file)

  # Remove the source line from the profile file
  if [ -f "$profile_file" ]; then
    awk -v script="$GG_PROXY_SCRIPT" '$0 !~ "source " script' "$profile_file" > "$profile_file.tmp" && mv "$profile_file.tmp" "$profile_file"
  fi

  # Delete itself
  rm -f "$GG_PROXY_SCRIPT"

  echo "GitGains Proxy uninstalled ❌"
}

gg-get_latest_version() {
  # Fetch the latest release information from GitHub API
  latest_release_info=$(curl -s "https://api.github.com/repos/$GG_GITHUB_REPO/releases/latest")

  # Extract the latest version tag from the JSON response
  latest_version=$(echo "$latest_release_info" | sed -n 's/.*"tag_name": "\([^"]*\)".*/\1/p')

  # Return the latest version
  echo "$latest_version"
}

gg-install() {
  # Get the latest version
  version=$(gg-get_latest_version)

  # Fetch the script content and store it in a temporary variable
  script_content=$(curl -fsSL "https://raw.githubusercontent.com/$GG_GITHUB_REPO/$version/gg-proxy.sh")

  # Write the script content to the GG_PROXY_SCRIPT file
  echo "$script_content" > "$GG_PROXY_SCRIPT"

  # Detect the profile file
  profile_file=$(gg-detect_profile_file)

  # Add source line to the profile file
  line="source $GG_PROXY_SCRIPT"
  grep -qF -- "$line" "$profile_file" || echo "$line" >> "$profile_file"

  # Save the proxy variables
  rm -rf "$GG_PROXY_CONFIG"
  gg-save_proxy_variables "$1" "$2"
  gg-deactivate
  gg-activate
  echo "GitGains Proxy installed ✅"
}

gitgains() {
  case "$1" in
    install)
      if [ "$#" -eq 3 ]; then
        gg-install "$2" "$3"
      else
        echo "Usage: gitgains install <id> <token>"
      fi
      ;;
    uninstall)
      gg-uninstall
      ;;
    activate)
      gg-activate
      ;;
    deactivate)
      gg-deactivate
      ;;
    *)
      echo "Usage: gitgains {install|uninstall|activate|deactivate}"
      ;;
  esac
}

gg-check_for_new_release() {

  latest_version=$(gg-get_latest_version)

  # Compare the latest version with GG_PROXY_VERSION
  if [ "$latest_version" != "$GG_PROXY_VERSION" ]; then
    echo "A new version of GitGains Proxy is available: $latest_version"
    echo -n "Do you want to update the script? (y/n): "
    read confirm
    if [ "$confirm" = "y" ]; then
      # Get USER_ID and USER_TOKEN
      # shellcheck source=$HOME/.gg-proxy
      source "$GG_PROXY_CONFIG"
      USER_ID=${USER_ID:-""}
      USER_TOKEN=${USER_TOKEN:-""}


      # Install the new version of the script and run the install command with USER_ID and USER_TOKEN arguments
      curl -fsSL "https://raw.githubusercontent.com/$GG_GITHUB_REPO/$latest_version/gg-proxy.sh" | bash -s -- install "$USER_ID" "$USER_TOKEN"
    else
      echo "Update canceled."
    fi
  fi
}

gg-check_for_new_release

# Check if the script is run with arguments
if [ "$#" -gt 0 ]; then
  gitgains "$@"
fi