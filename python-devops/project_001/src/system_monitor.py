import psutil
import time
import argparse
import sys
from datetime import datetime

def get_size(bytes, suffix="B"):
    """
    Scale bytes to its proper format
    e.g:
        1253656 => '1.20MB'
        1253656678 => '1.17GB'
    """
    factor = 1024
    for unit in ["", "K", "M", "G", "T", "P"]:
        if bytes < factor:
            return f"{bytes:.2f}{unit}{suffix}"
        bytes /= factor

def monitor(interval, duration):
    print("="*40)
    print("System Resource Monitor")
    print("="*40)
    print(f"{'Time':<10} | {'CPU %':<10} | {'Memory %':<10} | {'Disk %':<10}")
    print("-" * 50)

    start_time = time.time()
    
    try:
        while True:
            if duration and (time.time() - start_time) > duration:
                break
                
            cpu_usage = psutil.cpu_percent(interval=None)
            memory_usage = psutil.virtual_memory().percent
            disk_usage = psutil.disk_usage('/').percent
            current_time = datetime.now().strftime("%H:%M:%S")

            print(f"{current_time:<10} | {cpu_usage:<10} | {memory_usage:<10} | {disk_usage:<10}")
            
            time.sleep(interval)
            
    except KeyboardInterrupt:
        print("\nMonitoring stopped by user.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Simple System Resource Monitor")
    parser.add_argument("--interval", type=int, default=1, help="Update interval in seconds")
    parser.add_argument("--duration", type=int, default=0, help="Total duration in seconds (0 for infinite)")
    
    args = parser.parse_args()
    
    monitor(args.interval, args.duration)
