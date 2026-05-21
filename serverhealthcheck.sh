#!/bin/bash
# Server Health Check Script
# Provides a human-readable overview of server health in an easy-to-read format

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color (reset)

# Get system information
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
KERNEL=$(uname -r)
UPTIME_SECONDS=$(cat /proc/uptime | awk '{print $1}')

# Function to calculate human-readable uptime
get_uptime_human() {
    local total_seconds=$1
    local days=$((total_seconds / 86400))
    local hours=$(( (total_seconds % 86400) / 3600 ))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    
    local result=""
    [ $days -gt 0 ] && result+="${days} day(s), "
    [ $hours -gt 0 ] && result+="${hours} hour(s), "
    result+="${minutes} minute(s)"
    
    echo "${result%, }"  # Remove trailing comma and space
}

# Function to print a section header
print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $1${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Function to print a sub-section
print_subsection() {
    echo -e "${CYAN}┌───────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${BOLD}$1${NC}"
    echo -e "${CYAN}└───────────────────────────────────────────────────────────┘${NC}"
}

# Start report
echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║         🖥️  SERVER HEALTH CHECK REPORT                     ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "📅 Timestamp: ${GREEN}${TIMESTAMP}${NC}"
echo -e "💻 Hostname:  ${GREEN}${HOSTNAME}${NC}"
echo -e "📦 Kernel:    ${GREEN}${KERNEL}${NC}"
echo ""

# ==============================================================================
# 1. SYSTEM STATISTICS
# ==============================================================================
print_header "1. System Statistics"

UPTIME_HUMAN=$(get_uptime_human "${UPTIME_SECONDS%%.*}")

print_subsection "⏰ System Uptime"
echo ""
echo -e "   ${BOLD}System has been running for:${NC}"
echo -e "   ${GREEN}${UPTIME_HUMAN}${NC}"
echo ""

print_subsection "📊 Load Average (Last 1/5/15 minutes)"
echo ""
uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//' | while read load; do
    echo -e "   ${GREEN}Load: ${load}${NC}"
done
echo ""

# ==============================================================================
# 2. CPU Information
# ==============================================================================
print_header "2. CPU Status"

print_subsection "⚙️  CPU Cores and Usage"
echo ""
echo -e "   ${BOLD}CPU Cores:${NC} ${GREEN}$(nproc) cores${NC}"
echo ""

print_subsection "📈 Current CPU Usage"
echo ""
top -bn1 | grep "Cpu(s)" | while read line; do
    echo -e "   ${GREEN}${line}${NC}"
done
echo ""

print_subsection "🚀 Top 5 CPU-Intensive Processes"
echo ""
ps aux --sort=-%cpu | head -6 | awk 'NR==1 {print "   " $0} NR>1 {printf "   "; print $0}' | column -t -s ' ' -w 3 | while read line; do
    echo -e "   ${GREEN}${line}${NC}"
done
echo ""

# ==============================================================================
# 3. Memory Status
# ==============================================================================
print_header "3. Memory Status"

print_subsection "💧 RAM Usage Overview"
echo ""
free -h | awk 'NR==1 {printf "   %-10s %10s %10s %10s %10s %10s\n", $1, $2, $3, $4, $5, $6} NR>1 {printf "   "; printf "%-10s %10s %10s %10s %10s %10s\n", $1, $2, $3, $4, $5, $6}' | while read line; do
    echo -e "   ${GREEN}${line}${NC}"
done
echo ""

# Check memory usage percentage
MEM_USAGE=$(free | awk 'NR==2 {printf "%.1f%%", $3/$2 * 100}')
echo -e "   ${BOLD}Overall Memory Usage:${NC} ${GREEN}${MEM_USAGE}${NC}"
if [ "$(echo "$MEM_USAGE" | cut -d'%' -f1 | cut -d'.' -f1)" -gt 80 ]; then
    echo -e "   ${YELLOW}⚠️  Warning: Memory usage is high!${NC}"
fi
echo ""

# ==============================================================================
# 4. Disk Usage
# ==============================================================================
print_header "4. Disk Usage"

print_subsection "💾 Filesystem Storage"
echo ""
df -h -x tmpfs -x devtmpfs | awk 'NR==1 {printf "   %-20s %10s %10s %10s %6s %10s\n", $1, $2, $3, $4, "Use%", $6} NR>1 {printf "   "; printf "%-20s %10s %10s %10s %6s %10s\n", $1, $2, $3, $4, $5, $6}' | while read line; do
    echo -e "   ${GREEN}${line}${NC}"
done
echo ""

# Check for high disk usage
echo -e "${BOLD}High Usage Check:${NC}"
df -h -x tmpfs -x devtmpfs | awk 'NR>1 {gsub(/%/,"",$5); if ($5 > 80) print "   " $6 ": " $5 "% used"}' | while read line; do
    echo -e "   ${YELLOW}⚠️ ${line}${NC}"
done
echo ""

# ==============================================================================
# 5. Active Processes
# ==============================================================================
print_header "5. Process Information"

TOTAL_PROCESSES=$(ps aux | wc -l)
echo -e "${BOLD}Total Processes Running:${NC} ${GREEN}${TOTAL_PROCESSES}${NC}"
echo ""

print_subsection "🚀 Top 5 Memory-Intensive Processes"
echo ""
ps aux --sort=-%mem | head -6 | awk 'NR==1 {print "   " $0} NR>1 {printf "   "; print $0}' | column -t -s ' ' -w 3 | while read line; do
    echo -e "   ${GREEN}${line}${NC}"
done
echo ""

# ==============================================================================
# 6. Network Status
# ==============================================================================
print_header "6. Network Status"

print_subsection "🌐 Active Network Connections"
echo ""
echo -e "   ${BOLD}TCP Connections by State:${NC}"
if command -v ss &> /dev/null; then
    ss -s | head -10 | while read line; do
        echo -e "   ${GREEN}${line}${NC}"
    done
else
    netstat -s | grep -E "(TCP|UDP)" | head -10 | while read line; do
        echo -e "   ${GREEN}${line}${NC}"
    done
fi
echo ""

print_subsection "📡 Listening Ports"
echo ""
echo -e "   ${BOLD}Active Listening Services:${NC}"
if command -v ss &> /dev/null; then
    ss -tlnp 2>/dev/null | awk 'NR==1 {printf "   %-10s %-20s %-20s %s\n", $1, $5, $6, $7} NR>1 {printf "   "; printf "%-10s %-20s %-20s %s\n", $1, $5, $6, $7}' | while read line; do
        echo -e "   ${GREEN}${line}${NC}"
    done
else
    netstat -tlnp 2>/dev/null | awk 'NR==1 {printf "   %-10s %-20s %-20s %s\n", $1, $4, $6, $7} NR>1 {printf "   "; printf "%-10s %-20s %-20s %s\n", $1, $4, $6, $7}' | while read line; do
        echo -e "   ${GREEN}${line}${NC}"
    done
fi
echo ""

# ==============================================================================
# 7. System Health Summary
# ==============================================================================
print_header "7. Health Summary"

print_subsection "✅ Health Check Results"
echo ""
HEALTHY=true
ISSUES=""

# Check CPU load
LOAD_1MIN=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')
LOAD_INT=${LOAD_1MIN%.*}
CPU_CORES=$(nproc)
if [ "$LOAD_INT" -gt "$CPU_CORES" ] 2>/dev/null; then
    echo -e "   ${YELLOW}⚠️  CPU Load: High (${LOAD_1MIN} on ${CPU_CORES} cores)${NC}"
    HEALTHY=false
else
    echo -e "   ${GREEN}✅ CPU Load: Normal (${LOAD_1MIN} on ${CPU_CORES} cores)${NC}"
fi

# Check memory
MEM_PERCENT=$(echo "$MEM_USAGE" | cut -d'%' -f1)
if [ "${MEM_PERCENT%.*}" -gt 80 ]; then
    echo -e "   ${YELLOW}⚠️  Memory: High usage (${MEM_USAGE})${NC}"
    HEALTHY=false
else
    echo -e "   ${GREEN}✅ Memory: Normal (${MEM_USAGE})${NC}"
fi

# Check disk space
for mount_point in $(df -h -x tmpfs -x devtmpfs | awk 'NR>1 {gsub(/%/,"",$5); if ($5 > 85) print $6}'); do
    echo -e "   ${YELLOW}⚠️  Disk: High usage on ${mount_point}${NC}"
    HEALTHY=false
done

if [ "$HEALTHY" = true ]; then
    echo -e "   ${GREEN}✅ Disk Usage: All filesystems normal${NC}"
fi
echo ""

# Final message
if [ "$HEALTHY" = true ]; then
    echo -e "   ${BOLD}${GREEN}🎉 Server Health Status: ALL SYSTEMS OPERATIONAL${NC}"
else
    echo -e "   ${BOLD}${YELLOW}⚠️  Server Health Status: NEEDS ATTENTION${NC}"
    echo -e "   ${YELLOW}   Check the warnings above for details${NC}"
fi
echo ""

# ==============================================================================
# 8. Additional System Info
# ==============================================================================
print_header "8. Additional Information"

print_subsection "📦 Installed Services"
echo ""
echo -e "   ${BOLD}Common services status:${NC}"
echo ""

# Docker
if command -v docker &> /dev/null; then
    if docker info &> /dev/null; then
        echo -e "   ${GREEN}✅ Docker: Running${NC}"
        DOCKER_VERSION=$(docker --version | cut -d',' -f1 | cut -d' ' -f3)
        echo -e "      ${CYAN}Version:${NC} ${GREEN}${DOCKER_VERSION}${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Docker: Installed but not running${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  Docker: Not installed${NC}"
fi
echo ""

# Nginx
if command -v nginx &> /dev/null; then
    if pgrep -x nginx > /dev/null; then
        echo -e "   ${GREEN}✅ Nginx: Running${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Nginx: Installed but not running${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  Nginx: Not installed${NC}"
fi
echo ""

# Apache
if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
    if pgrep -x apache2 > /dev/null || pgrep -x httpd > /dev/null; then
        echo -e "   ${GREEN}✅ Apache: Running${NC}"
    else
        echo -e "   ${YELLOW}⚠️  Apache: Installed but not running${NC}"
    fi
else
    echo -e "   ${CYAN}ℹ️  Apache: Not installed${NC}"
fi
echo ""

print_subsection "📝 Recent System Events"
echo ""
echo -e "   ${BOLD}Last 5 log entries:${NC}"
if [ -f /var/log/syslog ]; then
    tail -5 /var/log/syslog | while read line; do
        echo -e "   ${GREEN}$line${NC}"
    done
elif [ -f /var/log/messages ]; then
    tail -5 /var/log/messages | while read line; do
        echo -e "   ${GREEN}$line${NC}"
    done
else
    echo -e "   ${CYAN}ℹ️  No system log found${NC}"
fi
echo ""

# ==============================================================================
# End of Report
# ==============================================================================
echo -e "${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║              📊 REPORT COMPLETE                           ║${NC}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "💡 Tip: Run this script regularly to monitor server health"
echo ""
