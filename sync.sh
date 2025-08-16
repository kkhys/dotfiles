#!/usr/bin/env bash
set -euo pipefail

# dotfiles synchronization script
# Usage: ./sync.sh [from-home|to-home|status]
#
# from-home: Sync from home directory to repository
# to-home:   Sync from repository to home directory
# status:    Show current differences

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

readonly SYNC_FILES=(
    ".zshrc"
    ".gitconfig"
    ".Brewfile"
    ".claude/claude.md"
    ".config/git/ignore"
    ".config/github-copilot/intellij/global-copilot-instructions.md"
    ".config/github-copilot/intellij/global-git-commit-instructions.md"
    ".config/github-copilot/intellij/mcp.json"
    ".config/karabiner/karabiner.json"
    ".gnupg/gpg-agent.conf"
)

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

usage() {
    cat <<EOF
${SCRIPT_NAME} - dotfiles synchronization tool

Usage: ${SCRIPT_NAME} [COMMAND]

Commands:
    from-home    Sync from home directory to repository
    to-home      Sync from repository to home directory
    status       Show current differences (default)
    help         Show this help message

Examples:
    ${SCRIPT_NAME}           # Check differences
    ${SCRIPT_NAME} status    # Check differences
    ${SCRIPT_NAME} from-home # Home → Repository
    ${SCRIPT_NAME} to-home   # Repository → Home
EOF
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_file_exists() {
    local file_path="$1"
    if [[ ! -f "$file_path" ]]; then
        log_warning "File does not exist: $file_path"
        return 1
    fi
    return 0
}

ensure_directory() {
    local file_path="$1"
    local dir_path="$(dirname "$file_path")"

    if [[ ! -d "$dir_path" ]]; then
        mkdir -p "$dir_path"
        log_info "Created directory: $dir_path"
    fi
}


show_diff() {
    local home_file="$1"
    local repo_file="$2"
    local filename="$3"

    echo -e "\n${BLUE}=== $filename differences ===${NC}"

    if [[ ! -f "$home_file" ]] && [[ ! -f "$repo_file" ]]; then
        log_warning "Both files do not exist"
        return
    elif [[ ! -f "$home_file" ]]; then
        log_warning "File does not exist in home directory"
        return
    elif [[ ! -f "$repo_file" ]]; then
        log_warning "File does not exist in repository"
        return
    fi

    if diff -q "$home_file" "$repo_file" >/dev/null 2>&1; then
        log_success "Files are identical"
    else
        echo -e "${YELLOW}Differences found:${NC}"
        diff --unified --color=auto "$repo_file" "$home_file" || true
    fi
}

check_status() {
    log_info "Checking dotfiles synchronization status..."

    local has_diff=false

    for file in "${SYNC_FILES[@]}"; do
        local home_file="$HOME/$file"
        local repo_file="$SCRIPT_DIR/$file"

        show_diff "$home_file" "$repo_file" "$file"

        if [[ -f "$home_file" ]] && [[ -f "$repo_file" ]]; then
            if ! diff -q "$home_file" "$repo_file" >/dev/null 2>&1; then
                has_diff=true
            fi
        elif [[ -f "$home_file" ]] || [[ -f "$repo_file" ]]; then
            has_diff=true
        fi
    done

    echo
    if [[ "$has_diff" == true ]]; then
        log_warning "Differences found. Consider synchronizing."
        echo
        echo "Sync commands:"
        echo "  ./sync.sh from-home  # Home → Repository"
        echo "  ./sync.sh to-home    # Repository → Home"
    else
        log_success "All files are synchronized"
    fi
}

sync_from_home() {
    log_info "Syncing from home directory to repository..."

    for file in "${SYNC_FILES[@]}"; do
        local home_file="$HOME/$file"
        local repo_file="$SCRIPT_DIR/$file"

        if check_file_exists "$home_file"; then
            ensure_directory "$repo_file"
            cp "$home_file" "$repo_file"
            log_success "Synced: $file"
        else
            log_error "Skipped: $home_file does not exist"
        fi
    done

    echo
    log_info "Git status check:"
    git status --porcelain .

    echo
    log_success "Home → Repository sync completed"
    log_info "To commit changes: git add . && git commit -m \"sync: update dotfiles from home\""
}

sync_to_home() {
    log_info "Syncing from repository to home directory..."

    for file in "${SYNC_FILES[@]}"; do
        local home_file="$HOME/$file"
        local repo_file="$SCRIPT_DIR/$file"

        if check_file_exists "$repo_file"; then
            ensure_directory "$home_file"
            cp "$repo_file" "$home_file"
            log_success "Synced: $file"
        else
            log_error "Skipped: $repo_file does not exist"
        fi
    done

    echo
    log_success "Repository → Home sync completed"
    log_info "To apply settings: exec $SHELL (or open a new terminal)"
}

main() {
    local command="${1:-status}"

    case "$command" in
        "from-home")
            sync_from_home
            ;;
        "to-home")
            sync_to_home
            ;;
        "status")
            check_status
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            log_error "Invalid command: $command"
            echo
            usage
            exit 1
            ;;
    esac
}

trap 'log_error "An error occurred during script execution (line $LINENO)"' ERR

main "$@"
