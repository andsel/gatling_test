#!/usr/bin/env bash
set -ex

GATLING_VERSION=3.10.5
GATLING_HOME=gatling_test/test_run/gatling-charts-highcharts-bundle-$GATLING_VERSION
GATLING_SIMULATIONS_DIR=$GATLING_HOME/user-files/simulations
SIMULATION_NAME='BasicSimulation'
GATLING_RUNNER=$GATLING_HOME/bin/gatling.sh
GATLING_REPORT_DIR=$GATLING_HOME/results/
GATLING_LOCAL_REPORT_DIR=../$GATLING_REPORT_DIR
GATHER_REPORTS_DIR=/tmp/gatling/reports/

######################################################
# Define the user to access the remote Gatling hosts, 
# and the list of hosts to gather the Gatling logs
######################################################
USER_NAME="a_user"
HOSTS=("127.0.0.1" "127.0.0.2") 

echo "Retrieving data from $HOSTS"

mkdir -p ${GATHER_REPORTS_DIR}

for HOST in "${HOSTS[@]}"; do
  ssh $USER_NAME@$HOST -n -f "sh -c 'ls -t $GATLING_REPORT_DIR | head -n 1 | xargs -I {} mv ${GATLING_REPORT_DIR}{} ${GATLING_REPORT_DIR}report'"
  scp $USER_NAME@$HOST:${GATLING_REPORT_DIR}report/simulation.log ${GATHER_REPORTS_DIR}simulation-$HOST.log
done


# clean up existing data
rm -rf ${GATLING_LOCAL_REPORT_DIR}reports
mkdir -p ${GATLING_LOCAL_REPORT_DIR}reports

# collect all logs into report folder for subsequent analysis
for HOST in "${HOSTS[@]}"; do
  cp ${GATHER_REPORTS_DIR}simulation-$HOST.log ${GATLING_LOCAL_REPORT_DIR}reports
done

# Generate merge report
echo "Merge the reports locally by running ../$GATLING_HOME/bin/gatling.sh -ro reports"
