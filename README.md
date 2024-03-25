# Elasticsearch Indices Size Monitor Setup Guide

This script calculates the difference in index sizes since its last run and tracks the total change in bytes.

This guide provides instructions on how to set up and run the Elasticsearch Indices Size Monitor script on a Unix-like system using crontab. 

## Prerequisites

- Ensure you have `curl`, `jq`, and `bc` installed on your system. These utilities are required for the script to function correctly.
- You must have access to the crontab or equivalent scheduler on your system.

## Installation

1. **Clone or download the script:**

   Begin by cloning this repository or downloading the script to your desired directory.

2. **Set the execution permission:**

   Make the script executable by running the following command:

   ```
   chmod +x /path/to/your/directory/es-size.sh
   ```

3. **Customize the script:**

   - Open the script in your favorite text editor.
   - Update the `BASE_DIR` variable to the directory where you want the data files to be stored.
   - Modify the `ES_URL` to point to your Elasticsearch instance.
   - Adjust the full paths to `curl`, `jq`, and `bc`.

4. **Set up Crontab:**

   - Edit your crontab file by running `crontab -e` in your terminal.
   - Add a line at the end of the crontab file to schedule your script. For testing, to run the script every minute, add:

     ```
     * * * * * /path/to/your/directory/es-size.sh > /path/to/your/logfile.log 2>&1
     ```

     Make sure to replace `/path/to/your/directory/es-size.sh` with the actual path to the script and `/path/to/your/logfile.log` with the path to where you want to store the log output.

   - Save and close the editor. The crontab will automatically install the new schedule.
   - Inspect the logfile.log for any errors.
   - Insure new es_total_change-$DATE.dat files are being created every minute in the $BASE_DIR.
   - Adjust the cronjob to run at midnight every day by changing the crontab entry to:

     ```
     0 0 * * * /path/to/your/directory/es-size.sh > /path/to/your/logfile.log 2>&1
     ```
## Package and view results
1. Package
    - After after at least two days after the conjob is setup, run the "package-total.sh" script
    ```
    ./package-total.sh
    ```
    - Now a totals.csv file will be created in the BASE_DIR. This file will contain the total change in bytes for each day.
2. View
    - Upload to Kibana using the steps outined in the [Kibana Upload](https://www.elastic.co/blog/importing-csv-and-log-data-into-elasticsearch-with-file-data-visualizer) docs.
    - Create a [Lens visualization](https://www.elastic.co/guide/en/kibana/current/lens.html) with the SUM function

## Monitoring and Logs

- The script will automatically save its output to the specified log file. Check this file for any errors or messages.
- Data files containing index sizes and total change in bytes are stored in the `BASE_DIR`.

## Troubleshooting

- **Command not found:** Ensure all required utilities (`date`, `curl`, `jq`, `bc`) are installed and their paths correctly set in the script.
- **Permission denied:** Verify that the script has execution permissions and that it can read from and write to the specified directories.
- **Crontab not running:** Ensure the crontab syntax is correct and the user running the crontab has permissions to execute the script.

For more detailed troubleshooting, consult the system logs and the crontab log (if available on your system).
```

**Notes:**

- Replace `/path/to/your/directory/es-size.sh` with the actual path to where you saved the script.
- Replace `/path/to/your/logfile.log` with the desired path for storing log output from the cron job.
- Ensure any specified paths in the README and script are accessible and writable by the user under which the cron job runs.
- This README assumes a basic level of familiarity with Unix-like systems, crontab, and command-line operations.
