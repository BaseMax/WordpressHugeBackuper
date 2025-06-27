# 🗂️ Wordpress Huge Backuper

A powerful Bash script to create intelligent, efficient, and size-aware backups of large WordPress installations—especially useful for sites with heavy media libraries.

## 🔧 Features

- Creates separate ZIP files for:
  - Site root (excluding large/media files)
  - `wp-content` (excluding `uploads`)
  - `uploads` split into multiple 1GB parts
- Skips temporary files (`.tmp`, `.temp`)
- Supports:
  - Dry-run mode
  - Verbose logging to file and console
- Automatically names ZIP parts like:  
  `uploads_part1.zip`, `uploads_part2.zip`, etc.
- Designed to run directly in your WordPress root directory.

## 📦 Output Example

```
wordpress-huge-backuper.log
root.zip
wp-content.zip
uploads_part1.zip
uploads_part2.zip
...
````

## 🛠️ Requirements

- `bash`
- `zip`
- `find`

Install them if missing (on Ubuntu):

```bash
sudo apt update
sudo apt install zip findutils
````

## 🚀 Usage

```bash
./wordpress-huge-backuper.sh [options]
```

### Options:

| Option | Description                         |
| ------ | ----------------------------------- |
| `-v`   | Verbose output (log to console too) |
| `-n`   | Dry-run mode (show actions only)    |
| `-h`   | Show help message                   |

### Example

```bash
./wordpress-huge-backuper.sh -v
```

## 📁 Folder Structure Assumptions

Run the script **from the WordPress root directory**. It expects:

```
.
├── wp-admin/
├── wp-content/
│   └── uploads/
├── wp-includes/
└── wordpress-huge-backuper.sh
```

## 📜 Log File

All logs are written to:

```bash
wordpress-huge-backuper.log
```

This includes backup progress, skipped files, and ZIP command details.

## Related Projects

If you prefer creating **one ZIP file per year** inside your `uploads` directory (which can be simpler and works well for smaller sites), feel free to use my other project:
[Wordpress-Backuper](https://github.com/BaseMax/wordpress-backuper)

This repository (**Wordpress-Huge-Backuper**) is specially designed for **huge sites** with very large media uploads that require splitting backups into manageable ZIP files by size.

## 🧠 Author

**Max Base**
📎 [GitHub Profile](https://github.com/BaseMax)
🌐 [Repository](https://github.com/BaseMax/WordpressHugeBackuper)

## 📝 License

[MIT License](LICENSE)

---

Enjoy reliable and efficient backups! 💾✨
