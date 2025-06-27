# Wordpress Huge Backuper

A Bash script to efficiently back up large WordPress sites by creating multiple independent ZIP archives with a configurable maximum size limit per archive (default: 1 GB).  
This approach helps to easily manage, transfer, and extract large WordPress backup files, especially useful for hosting control panels like cPanel.

---

## Features

- Creates a ZIP archive of your WordPress root folder excluding large or backup archives (`*.zip`, `*.tar.gz`, `*.rar`, `*.sql`, etc.) and excluding the `wp-content` directory.
- Creates a separate ZIP archive for the `wp-content` directory excluding its `uploads` folder.
- Splits the `uploads` directory into multiple independent ZIP files, each capped at a maximum size (default 1 GB), ensuring easier extraction and upload limitations.
- Supports verbose logging and dry-run mode.
- Safe handling of large individual files by zipping them individually if they exceed the max size limit.
- Logs progress to a file `zip_process.log`.

---

## Requirements

- Bash shell
- `zip` command-line utility
- `find` command-line utility

Ensure these tools are installed and available in your system's PATH.

---

## Usage

```bash
./wordpress-huge-backuper.sh [options]
````

### Options

| Option | Description                                   |
| ------ | --------------------------------------------- |
| `-v`   | Verbose output (show logs on console)         |
| `-n`   | Dry-run mode (show actions without executing) |
| `-h`   | Show this help message                        |

---

## How It Works

1. The script creates a `root.zip` file for all files in the WordPress root directory except archives and `wp-content`.
2. It creates a `wp-content.zip` archive excluding the `uploads` folder.
3. It processes the `uploads` folder by:

   * Collecting all files recursively.
   * Grouping files into batches where the total size of each batch does not exceed the maximum size limit (default 1 GB).
   * Creating separate ZIP archives for each batch, named `uploads_part1.zip`, `uploads_part2.zip`, etc.
   * Files larger than the max size are zipped individually.

---

## Configuration

* **MAX\_SIZE**: The maximum size in bytes for each ZIP archive part.
  Default is 1 GB (`1 * 1024 * 1024 * 1024` bytes). Modify in the script if needed.

* **ROOT**: The root directory where the script runs and creates backups.

* **LOG\_FILE**: Path to the log file (`zip_process.log`).

---

## Related Projects

If you prefer creating **one ZIP file per year** inside your `uploads` directory (which can be simpler and works well for smaller sites), feel free to use my other project:
[Wordpress-Backuper](https://github.com/BaseMax/wordpress-backuper)

This repository (**Wordpress-Huge-Backuper**) is specially designed for **huge sites** with very large media uploads that require splitting backups into manageable ZIP files by size.

---

## Example

Run the script with verbose logging and dry-run to see what will be done without creating any files:

```bash
./wordpress-huge-backuper.sh -v -n
```

Run the script normally:

```bash
./wordpress-huge-backuper.sh
```

---

## Notes

* The generated ZIP files are fully independent archives, making extraction straightforward without the need for special multi-part archive tools.
* This script is especially useful for backing up WordPress sites with large media libraries where a single ZIP file might be too large to handle.
* Tested on Linux environments with Bash.

---

## Contributing

Feel free to open issues or submit pull requests to improve the script or add features.

---

## Contact

If you have questions or suggestions, open an issue or contact [Max Base](https://github.com/BaseMax).

---

## License

MIT License — see the [LICENSE](LICENSE) file for details.

## Author

**Max Base**  

GitHub: [https://github.com/BaseMax](https://github.com/BaseMax)  

Repository: [https://github.com/BaseMax/Wordpress-Huge-Backuper](https://github.com/BaseMax/Wordpress-Huge-Backuper)
