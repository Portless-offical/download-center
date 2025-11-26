#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/centopw/Portless"
DOWNLOAD_CENTER_URL="https://github.com/Portless-official/download-center"
PROJECT_DIR="${HOME}/.portless"
APP_NAME="USB Share"

# Functions
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

detect_os() {
    case "$(uname -s)" in
        Darwin*)
            OS="macos"
            ARCH=$(uname -m)
            if [ "$ARCH" = "arm64" ]; then
                ARCH="aarch64"
            fi
            ;;
        Linux*)
            OS="linux"
            ARCH=$(uname -m)
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="windows"
            ARCH="x86_64"
            ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
    print_success "Detected OS: $OS ($ARCH)"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Git
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed. Please install Git first."
        exit 1
    fi
    print_success "Git is installed"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Installing Node.js..."
        install_nodejs
    else
        NODE_VERSION=$(node -v)
        print_success "Node.js is installed: $NODE_VERSION"
    fi
    
    # Check Rust
    if ! command -v rustc &> /dev/null; then
        print_error "Rust is not installed. Installing Rust..."
        install_rust
    else
        RUST_VERSION=$(rustc --version)
        print_success "Rust is installed: $RUST_VERSION"
    fi
    
    # Platform-specific prerequisites
    if [ "$OS" = "macos" ]; then
        check_macos_prerequisites
    elif [ "$OS" = "linux" ]; then
        check_linux_prerequisites
    elif [ "$OS" = "windows" ]; then
        check_windows_prerequisites
    fi
}

install_nodejs() {
    print_info "Installing Node.js..."
    if command -v brew &> /dev/null; then
        brew install node
    else
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi
}

install_rust() {
    print_info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
}

check_macos_prerequisites() {
    print_info "Checking macOS prerequisites..."
    
    if ! command -v xcode-select &> /dev/null; then
        print_error "Xcode Command Line Tools are not installed."
        print_info "Please run: xcode-select --install"
        exit 1
    fi
    print_success "Xcode Command Line Tools are installed"
}

check_linux_prerequisites() {
    print_info "Checking Linux prerequisites..."
    
    MISSING_PACKAGES=()
    
    for package in libwebkit2gtk-4.1-dev libappindicator3-dev librsvg2-dev patchelf libusb-1.0-0-dev libudev-dev; do
        if ! dpkg -l | grep -q "^ii  $package"; then
            MISSING_PACKAGES+=("$package")
        fi
    done
    
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        print_info "Installing missing Linux dependencies: ${MISSING_PACKAGES[*]}"
        sudo apt-get update
        sudo apt-get install -y "${MISSING_PACKAGES[@]}"
        print_success "Linux dependencies installed"
    else
        print_success "All Linux dependencies are installed"
    fi
}

check_windows_prerequisites() {
    print_info "Checking Windows prerequisites..."
    print_info "Windows detected. Ensure you have Visual Studio Build Tools with C++ workload installed."
}

clone_repository() {
    if [ -d "$PROJECT_DIR" ]; then
        print_info "Repository already exists at $PROJECT_DIR"
        read -p "Do you want to update it? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Updating repository..."
            cd "$PROJECT_DIR"
            git pull origin main
            print_success "Repository updated"
        fi
    else
        print_info "Cloning Portless repository..."
        mkdir -p "$(dirname "$PROJECT_DIR")"
        git clone "$REPO_URL" "$PROJECT_DIR"
        print_success "Repository cloned to $PROJECT_DIR"
    fi
}

install_dependencies() {
    print_info "Installing Node.js dependencies..."
    cd "$PROJECT_DIR"
    npm ci
    print_success "Node.js dependencies installed"
}

build_project() {
    print_info "Building Portless application..."
    cd "$PROJECT_DIR"
    npm run tauri build
    print_success "Build completed"
}

get_latest_release() {
    print_info "Fetching latest release information..."
    
    RELEASE_INFO=$(curl -s \
        -H "Accept: application/vnd.github.v3+json" \
        "$REPO_URL/releases/latest")
    
    LATEST_VERSION=$(echo "$RELEASE_INFO" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
    
    if [ -z "$LATEST_VERSION" ]; then
        print_error "Could not fetch latest release version"
        return 1
    fi
    
    print_success "Latest version: $LATEST_VERSION"
}

download_prebuilt() {
    print_info "Downloading pre-built binary for $OS-$ARCH..."
    
    DOWNLOAD_DIR="${PROJECT_DIR}/downloads"
    mkdir -p "$DOWNLOAD_DIR"
    
    # Determine the file to download based on OS and architecture
    case "$OS" in
        macos)
            if [ "$ARCH" = "aarch64" ]; then
                BINARY_NAME="USB-Share*aarch64*.dmg"
            else
                BINARY_NAME="USB-Share*x64*.dmg"
            fi
            ;;
        linux)
            BINARY_NAME="USB-Share*.AppImage"
            ;;
        windows)
            BINARY_NAME="USB-Share*.exe"
            ;;
    esac
    
    print_info "Attempting to download pre-built binary..."
    cd "$DOWNLOAD_DIR"
    
    # Try to download from releases
    ASSETS=$(curl -s \
        -H "Accept: application/vnd.github.v3+json" \
        "$REPO_URL/releases/latest" | \
        grep -o '"browser_download_url": "[^"]*"' | \
        cut -d'"' -f4)
    
    DOWNLOAD_URL=$(echo "$ASSETS" | grep -E "$BINARY_NAME" | head -1)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        print_error "Could not find pre-built binary for $OS-$ARCH"
        print_info "Will build from source instead..."
        return 1
    fi
    
    print_info "Downloading from: $DOWNLOAD_URL"
    curl -L -O "$DOWNLOAD_URL"
    print_success "Binary downloaded"
    return 0
}

install_application() {
    print_info "Installing application..."
    
    case "$OS" in
        macos)
            DMG_FILE=$(find "${PROJECT_DIR}/downloads" -name "*.dmg" -type f | head -1)
            if [ -n "$DMG_FILE" ]; then
                print_info "Mounting DMG: $DMG_FILE"
                MOUNT_POINT=$(mktemp -d)
                hdiutil attach "$DMG_FILE" -mountpoint "$MOUNT_POINT"
                cp -r "$MOUNT_POINT/$APP_NAME.app" "/Applications/$APP_NAME.app"
                hdiutil detach "$MOUNT_POINT"
                rm -rf "$MOUNT_POINT"
                print_success "Application installed to /Applications"
            fi
            ;;
        linux)
            APPIMAGE_FILE=$(find "${PROJECT_DIR}/downloads" -name "*.AppImage" -type f | head -1)
            if [ -n "$APPIMAGE_FILE" ]; then
                chmod +x "$APPIMAGE_FILE"
                INSTALL_DIR="${HOME}/.local/bin"
                mkdir -p "$INSTALL_DIR"
                cp "$APPIMAGE_FILE" "$INSTALL_DIR/portless"
                print_success "Application installed to $INSTALL_DIR/portless"
                print_info "Add $INSTALL_DIR to your PATH if not already done"
            fi
            ;;
        windows)
            EXE_FILE=$(find "${PROJECT_DIR}/downloads" -name "*.exe" -type f | head -1)
            if [ -n "$EXE_FILE" ]; then
                print_info "Running installer: $EXE_FILE"
                "$EXE_FILE"
                print_success "Application installed"
            fi
            ;;
    esac
}

cleanup() {
    print_info "Cleaning up..."
    if [ -d "${PROJECT_DIR}/downloads" ]; then
        rm -rf "${PROJECT_DIR}/downloads"
    fi
    print_success "Cleanup completed"
}

main() {
    print_header "Portless Installation Script"
    print_info "This script will install Portless on your system"
    echo
    
    # Check if user wants source or binary installation
    echo "Choose installation method:"
    echo "1) Download pre-built binary (recommended)"
    echo "2) Build from source"
    read -p "Enter choice (1 or 2): " -n 1 -r CHOICE
    echo
    
    detect_os
    
    if [ "$CHOICE" = "1" ]; then
        print_header "Binary Installation"
        clone_repository
        get_latest_release
        
        if download_prebuilt; then
            install_application
            cleanup
        else
            print_info "Falling back to source build..."
            print_header "Building from Source"
            check_prerequisites
            install_dependencies
            build_project
        fi
    else
        print_header "Source Installation"
        check_prerequisites
        clone_repository
        install_dependencies
        build_project
    fi
    
    print_header "Installation Complete!"
    print_success "Portless has been installed successfully"
    echo
    print_info "To get started:"
    case "$OS" in
        macos)
            echo "  1. Open /Applications/USB\\ Share.app"
            echo "  2. Allow USB access permissions if prompted"
            ;;
        linux)
            echo "  1. Run: ~/.local/bin/portless"
            echo "  2. Or search for 'USB Share' in your application menu"
            ;;
        windows)
            echo "  1. Search for 'USB Share' in your Start menu"
            echo "  2. Run the application"
            ;;
    esac
    echo
    print_info "For more information, visit: $REPO_URL"
}

# Run main function
main "$@"
