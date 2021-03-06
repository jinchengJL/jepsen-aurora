#!/bin/bash

NAME=job${1}
TASKNAME=${NAME}_task
DURATION=$2
JOB_SCRIPT_DIR=/tmp/aurora-jobs/
JOB_RESULT_DIR=/tmp/aurora-test/
AURORA_CLIENT=/jepsen/jepsen-aurora/resources/client.pex

mkdir -p $JOB_SCRIPT_DIR
TEMPJOB=$(mktemp -p $JOB_SCRIPT_DIR)
echo "MEW=\$(mktemp -p " $JOB_RESULT_DIR "); " \
    "echo \"" ${NAME} "\" >> \$MEW; " \
    "date -u -Ins >> \$MEW; " \
    "sleep " $DURATION "; " \
    "date -u -Ins >> \$MEW;" \
    > $TEMPJOB

TEMPCONFIG=$TEMPJOB.aurora
echo "
# run the script
$NAME = Process(
  name = '$NAME',
  min_duration = $(($DURATION * 2)),
  cmdline = '$(cat ${TEMPJOB})')

# describe the task
$TASKNAME = SequentialTask(
  processes = [$NAME],
  resources = Resources(cpu = 0.01, ram = 1*MB, disk=1*MB))

jobs = [
  Job(cluster = 'testcluster',
      environment = 'devel',
      role = 'www-data',
      max_task_failures = -1,
      cron_schedule = '*/1 * * * *',
      name = '$NAME',
      task = $TASKNAME)
]" > $TEMPCONFIG

$AURORA_CLIENT cron schedule testcluster/www-data/devel/$NAME $TEMPCONFIG
