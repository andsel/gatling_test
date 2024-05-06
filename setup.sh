#!/usr/bin/env bash
set -ex

GATLING_VERSION=3.10.5
GATLING_HOME=test_run/gatling-charts-highcharts-bundle-$GATLING_VERSION
GATLING_SIMULATIONS_DIR=$GATLING_HOME/user-files/simulations
SIMULATION_NAME='BasicSimulation'
GATLING_RUNNER=$GATLING_HOME/bin/gatling.sh
GATLING_REPORT_DIR=$GATLING_HOME/results/
# GATHER_REPORTS_DIR=/gatling/reports/

echo "Setup Gatling version $GATLING_VERSION"
if [ ! -e "gatling-charts-highcharts-bundle-$GATLING_VERSION-bundle.zip" ]; then
  echo "Gatling not present locally, downloading"
  curl -s -o "gatling-charts-highcharts-bundle-$GATLING_VERSION-bundle.zip" "https://repo1.maven.org/maven2/io/gatling/highcharts/gatling-charts-highcharts-bundle/$GATLING_VERSION/gatling-charts-highcharts-bundle-$GATLING_VERSION-bundle.zip"
fi


# TODO copy the gatling on remote host
mkdir test_run


# unpack
unzip gatling-charts-highcharts-bundle-$GATLING_VERSION-bundle.zip -d test_run/

# copy the scenario to execute
cp payload_1k.json "test_run/gatling-charts-highcharts-bundle-$GATLING_VERSION/user-files/resources"
cp BasicSimulation.java "$GATLING_SIMULATIONS_DIR"


# -nr: no report generation
# -rm: run-mode local 
nohup $GATLING_RUNNER -nr -rm local -s $SIMULATION_NAME > run.log 2>&1 &
