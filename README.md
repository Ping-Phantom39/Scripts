# Ubuntu Scripts

A collection of useful bash scripts for system administration and management.

## Available Scripts

### System Monitoring & Management
- **system-resources.sh** - Monitor CPU, memory, disk, and network usage
- **server-health-check.sh** - Check server health status
- **log-analyzer.sh** - Analyze log files for errors and patterns
- **process-killer.sh** - Kill processes by name or resource usage

### Networking
- **network-tools.sh** - Network diagnostics, port scanning, DNS tests

### Backup & Recovery
- **backup-configs.sh** - Backup configuration files
- **backup-manager.sh** - Full backup management with rotation and compression

### Installation & Setup
- **quick-install.sh** - Quick installation of common tools
- **install-essentials.sh** - Install essential packages

### Security
- **ssl-monitor.sh** - Monitor SSL certificate expiration

### Utilities (NEW)
- **file-organizer.sh** - Organize files by type (images, videos, documents, etc.)
- **search-utility.sh** - Enhanced file search with filtering options
- **user-manager.sh** - User management (create, delete, lock, unlock accounts)
- **service-control.sh** - Service management (start, stop, restart, status)

## Usage

Most scripts support `--help` or `-h` flag for usage information.

Example:
```bash
./system-resources.sh
./network-tools.sh dns
./backup-manager.sh list
./service-control.sh status nginx
```

## Installation

Scripts are ready to use. Ensure they have execute permissions:
```bash
chmod +x *.sh
```
