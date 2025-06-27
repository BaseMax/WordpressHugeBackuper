#!/bin/bash

#
# Author: Max Base
# Name: Wordpress-Huge-Backuper
# Repository: https://github.com/BaseMax/Wordpress-Huge-Backuper
#

set -euo pipefail

# === Config ===
ROOT="$(pwd)"
WP_CONTENT_DIR="$ROOT/wp-content"
UPLOADS_DIR="$WP_CONTENT_DIR/uploads"
LOG_FILE="$ROOT/zip_process.log"
ZIP_OPTIONS="-r"

MAX_SIZE=$((1 * 1024 * 1024 * 1024))  # 1 GB in bytes
VERBOSE=0
DRY_RUN=0

# === Functions ===
log() {
  if (( VERBOSE )); then
    echo "$1" | tee -a "$LOG_FILE"
  else
    echo "$1" >> "$LOG_FILE"
  fi
}

run_zip() {
  # Args: 1=zip_file, 2...=files to zip
  local zip_path="$1"
  shift
  local files=("$@")

  log "📝 Running zip command: zip $ZIP_OPTIONS \"$zip_path\" ${files[*]}"

  if (( DRY_RUN )); then
    log "[Dry-run] zip $ZIP_OPTIONS \"$zip_path\" ${files[*]}"
  else
    if (( VERBOSE )); then
      zip $ZIP_OPTIONS "$zip_path" "${files[@]}" 2>&1 | tee -a "$LOG_FILE"
    else
      zip $ZIP_OPTIONS "$zip_path" "${files[@]}" >> "$LOG_FILE" 2>&1
    fi
  fi
}

check_dependencies() {
  command -v zip >/dev/null 2>&1 || { echo "❌ zip command not found. Please install zip."; exit 1; }
  command -v find >/dev/null 2>&1 || { echo "❌ find command not found. Please install find."; exit 1; }
}

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  -v        Verbose output (show logs on console)
  -n        Dry-run mode (show actions, don't execute)
  -h        Show this help message
EOF
  exit 0
}

parse_args() {
  while getopts ":vnh" opt; do
    case $opt in
      v) VERBOSE=1 ;;
      n) DRY_RUN=1 ;;
      h) usage ;;
      *) usage ;;
    esac
  done
}

zip_files_in_batches() {
  local zip_base="$1"
  local target_dir="$2"

  pushd "$target_dir" > /dev/null || { log "❌ Could not enter directory $target_dir"; exit 1; }

  log "📂 Creating batched zip files from $target_dir with max size $MAX_SIZE bytes each..."

  mapfile -t files_with_sizes < <(find . -type f -printf '%s %p\n' | sort -k2)

  local batch_files=()
  local batch_size=0
  local batch_index=1

  for entry in "${files_with_sizes[@]}"; do
    local size=${entry%% *}
    local file=${entry#* }

    if (( size > MAX_SIZE )); then
      log "⚠️ File $file size ($size) exceeds max batch size; zipping individually..."
      run_zip "${zip_base}_part${batch_index}.zip" "$file"
      ((batch_index++))
      continue
    fi

    if (( batch_size + size > MAX_SIZE )); then
      if (( ${#batch_files[@]} > 0 )); then
        log "🗂 Creating zip ${zip_base}_part${batch_index}.zip with ${#batch_files[@]} files, total size $batch_size bytes"
        run_zip "${zip_base}_part${batch_index}.zip" "${batch_files[@]}"
        ((batch_index++))
      fi
      batch_files=()
      batch_size=0
    fi

    batch_files+=("$file")
    ((batch_size += size))
  done

  if (( ${#batch_files[@]} > 0 )); then
    log "🗂 Creating final zip ${zip_base}_part${batch_index}.zip with ${#batch_files[@]} files, total size $batch_size bytes"
    run_zip "${zip_base}_part${batch_index}.zip" "${batch_files[@]}"
  fi

  popd > /dev/null || exit 1
}

zip_folder() {
  local zip_name="$1"
  local target="$2"
  local zip_path="$ROOT/${zip_name}.zip"

  if [[ -f "$zip_path" ]]; then
    log "⚠️  $zip_path already exists, skipping..."
    return
  fi

  log "📝 Creating $zip_name.zip for $target..."

  run_zip "$zip_path" "$target"
}

create_root_zip() {
  local exclude_patterns=('*.zip' '*.tar.gz' '*.rar' '*.sql' '*.gz' "${WP_CONTENT_DIR}/*" "${WP_CONTENT_DIR}")
  local exclude_args=()
  for pat in "${exclude_patterns[@]}"; do
    exclude_args+=("-x" "$pat")
  done

  log "🔄 Creating root.zip..."

  if (( DRY_RUN )); then
    log "[Dry-run] zip $ZIP_OPTIONS \"$ROOT/root.zip\" . ${exclude_args[*]}"
  else
    if (( VERBOSE )); then
      zip $ZIP_OPTIONS "$ROOT/root.zip" . "${exclude_args[@]}" 2>&1 | tee -a "$LOG_FILE"
    else
      zip $ZIP_OPTIONS "$ROOT/root.zip" . "${exclude_args[@]}" >> "$LOG_FILE" 2>&1
    fi
  fi
}

create_wp_content_zip() {
  if [ -d "$WP_CONTENT_DIR" ]; then
    log "🔄 Creating wp-content.zip (excluding uploads)..."
    pushd "$WP_CONTENT_DIR" > /dev/null

    if (( DRY_RUN )); then
      log "[Dry-run] zip $ZIP_OPTIONS \"$ROOT/wp-content.zip\" . -x '$UPLOADS_DIR/*' 'uploads'"
    else
      if (( VERBOSE )); then
        zip $ZIP_OPTIONS "$ROOT/wp-content.zip" . -x '$UPLOADS_DIR/*' '$UPLOADS_DIR' 2>&1 | tee -a "$LOG_FILE"
      else
        zip $ZIP_OPTIONS "$ROOT/wp-content.zip" . -x '$UPLOADS_DIR/*' '$UPLOADS_DIR' >> "$LOG_FILE" 2>&1
      fi
    fi

    popd > /dev/null
  else
    log "⚠️  wp-content directory not found, skipping wp-content.zip"
  fi
}

process_uploads_split_zip() {
  if [ ! -d "$UPLOADS_DIR" ]; then
    log "❌ uploads directory not found: $UPLOADS_DIR"
    exit 1
  fi

  zip_files_in_batches "$ROOT/uploads" "$UPLOADS_DIR"
}

# === Main ===
parse_args "$@"
check_dependencies

log "📁 Working directory: $ROOT"
log "Logging output to: $LOG_FILE"
log "-------------------------------"

create_root_zip
create_wp_content_zip
process_uploads_split_zip

log "✅ All zip files created successfully in: $ROOT"
