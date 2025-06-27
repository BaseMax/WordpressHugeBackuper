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

zip_folder() {
  local zip_name="$1"
  local target="$2"
  local zip_path="$ROOT/${zip_name}.zip"

  if [[ -f "$zip_path" ]]; then
    log "⚠️  $zip_path already exists, skipping..."
    return
  fi

  log "📝 Creating $zip_name.zip for $target..."

  if (( DRY_RUN )); then
    log "[Dry-run] zip $ZIP_OPTIONS \"$zip_path\" \"$target\""
  else
    zip $ZIP_OPTIONS "$zip_path" "$target" >> "$LOG_FILE" 2>&1
  fi
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
    zip $ZIP_OPTIONS "$ROOT/root.zip" . "${exclude_args[@]}" >> "$LOG_FILE" 2>&1
  fi
}

create_wp_content_zip() {
  if [ -d "$WP_CONTENT_DIR" ]; then
    log "🔄 Creating wp-content.zip..."
    pushd "$WP_CONTENT_DIR" > /dev/null
    if (( DRY_RUN )); then
      log "[Dry-run] zip $ZIP_OPTIONS \"$ROOT/wp-content.zip\" . -x 'uploads/*' 'uploads'"
    else
      zip $ZIP_OPTIONS "$ROOT/wp-content.zip" . -x 'uploads/*' 'uploads' >> "$LOG_FILE" 2>&1
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

  log "📂 Processing uploads directory with size limit ${MAX_SIZE} bytes per zip..."
  pushd "$UPLOADS_DIR" > /dev/null || exit 1

  mapfile -t files_with_sizes < <(find . -type f -printf '%s %p\n' | sort -k2)

  batch_files=()
  batch_size=0
  batch_index=1

  for entry in "${files_with_sizes[@]}"; do
    size=${entry%% *}
    file=${entry#* }

    if (( size > MAX_SIZE )); then
      log "⚠️ File $file size ($size) exceeds max batch size; zipping individually..."
      if (( DRY_RUN )); then
        log "[Dry-run] zip -r $ROOT/uploads_part${batch_index}.zip \"$file\""
      else
        zip -r "$ROOT/uploads_part${batch_index}.zip" "$file" >> "$LOG_FILE" 2>&1
      fi
      ((batch_index++))
      continue
    fi

    if (( batch_size + size > MAX_SIZE )); then
      if (( ${#batch_files[@]} > 0 )); then
        log "🗂 Creating zip uploads_part${batch_index}.zip with ${#batch_files[@]} files, total size $batch_size bytes"
        if (( DRY_RUN )); then
          log "[Dry-run] zip -r $ROOT/uploads_part${batch_index}.zip ${batch_files[*]}"
        else
          zip -r "$ROOT/uploads_part${batch_index}.zip" "${batch_files[@]}" >> "$LOG_FILE" 2>&1
        fi
        ((batch_index++))
      fi
      batch_files=()
      batch_size=0
    fi

    batch_files+=("$file")
    ((batch_size += size))
  done

  if (( ${#batch_files[@]} > 0 )); then
    log "🗂 Creating final zip uploads_part${batch_index}.zip with ${#batch_files[@]} files, total size $batch_size bytes"
    if (( DRY_RUN )); then
      log "[Dry-run] zip -r $ROOT/uploads_part${batch_index}.zip ${batch_files[*]}"
    else
      zip -r "$ROOT/uploads_part${batch_index}.zip" "${batch_files[@]}" >> "$LOG_FILE" 2>&1
    fi
  fi

  popd > /dev/null || exit 1
}

# === Main ===
parse_args "$@"
check_dependencies

log "📁 Working directory: $ROOT"
log "Logging output to: $LOG_FILE"
log "-------------------------------"

create_root_zip
create_wp_content_zip
process_uploads

log "✅ All zip files created successfully in: $ROOT"
