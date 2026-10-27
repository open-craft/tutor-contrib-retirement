# User Retirement Tutor plugin

This is an **experimental** plugin for
[Tutor](https://docs.tutor.overhang.io) that enables the [user retirement feature](https://edx.readthedocs.io/projects/edx-installing-configuring-and-running/en/latest/configuration/user_retire/index.html) in Open edX.

This repository was previously hosted under the `hastexo` GitHub organization, and moved to `cleura` in December 2025 as part of a routine repository consolidation.

## Version compatibility matrix

You must install a supported release of this plugin to match the Open edX and Tutor version you are deploying.
If you are installing this plugin from a branch in this Git repository, you must select the appropriate one:

| Open edX release | Tutor version     | Plugin branch | Plugin release |
|------------------|-------------------|---------------|----------------|
| Lilac            | `>=12.0, <13`     | Not supported | Not supported  |
| Maple            | `>=13.2, <14`[^1] | `maple`       | `<1.0`         |
| Nutmeg           | `>=14.0, <15`     | `nutmeg`      | `>=1.0, <2`    |
| Olive            | `>=15.0, <16`     | `quince`      | `>=2.0, <3`    |
| Palm             | `>=16.0, <17`     | `quince`      | `>=2.1`        |
| Quince           | `>=17.0, <18`     | `quince`      | `>=3.2, <4`    |
| Redwood          | `>=18.0, <19`     | `main`        | `>=4.0`        |
| Sumac            | `>=19.0, <20`     | `main`        | `>=5.1`        |
| Teak             | `>=20.0, <21`     | `main`        | `>=5.3`        |
| Ulmo             | `>=21.0, <22`     | `main`        | `>=5.4`        |
| Verawood         | `>=22.0, <23`     | `main`        | `>=5.5`        |

[^1]: For Open edX Maple and Tutor 13, you must run version 13.2.0 or later.
      That is because this plugin uses the Tutor v1 plugin API, which was introduced with that release.
      See the [GitHub changelog](https://github.com/overhangio/tutor/blob/master/CHANGELOG.md#v1320-2022-04-24).

## Limitations

This plugin cannot be used for retiring accounts in the [Open edX E-Commerce Service](https://github.com/openedx/ecommerce),[^ecom] nor the [Course Discovery Service](https://github.com/openedx/course-discovery).[^discovery]

[^ecom]: See [Issue #36](https://github.com/cleura/tutor-contrib-retirement/issues/36) for background.

[^discovery]: See [Issue #39](https://github.com/cleura/tutor-contrib-retirement/issues/39) for background.

## Installation

```shell
pip install git+https://github.com/cleura/tutor-contrib-retirement@v5.5.0
```

## Usage

To enable this plugin, run:

```shell
tutor plugins enable retirement
```

Before starting Tutor, build the docker image:

```shell
tutor images build retirement
```

After enabling this plugin, you need to restart your Tutor deployment with `tutor local quickstart` or `tutor k8s quickstart`.
This ensures that the retirement service worker is registered as an OAuth2 client in LMS and that the retirement pipeline stages are correctly populated in LMS.

To run the retirement pipeline in the Tutor local deployment:

```shell
tutor local retire-users
```

This will start the `retirement-job` service and run the retirement pipeline as described [here](https://edx.readthedocs.io/projects/edx-installing-configuring-and-running/en/latest/configuration/user_retire/driver_setup.html).
If you want to run this command periodically in a local deployment, you can invoke this command from a cron job on your host.

For a Kubernetes deployment, this plugin defines a [CronJob](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) which runs the retirement pipeline according to the schedule defined in the `RETIREMENT_K8S_CRONJOB_SCHEDULE` configuration parameter.
You can also tweak the [history limits](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#jobs-history-limits) for the CronJob.

### Cleaning up retirement records

After a learner is retired, the LMS still keeps a retirement record with their original username, email address, and full name.
To delete these records, the retirement pipeline can run the [`retirement_archive_and_cleanup.py`](https://github.com/openedx/edx-platform/blob/03698e2/scripts/user_retirement/retirement_archive_and_cleanup.py) script after retiring learners.
This script archives the records to an S3 bucket before deleting them from the LMS.

The cleanup is disabled by default.
To enable it, set `RETIREMENT_CLEANUP_S3_BUCKET_NAME`:

```shell
tutor config save \
  --set RETIREMENT_CLEANUP_S3_BUCKET_NAME=my-retirement-archive \
  --set RETIREMENT_CLEANUP_COOL_OFF_DAYS=7
```

`RETIREMENT_CLEANUP_COOL_OFF_DAYS` is the number of days to keep the records after the learner is retired, so the records are deleted `RETIREMENT_COOL_OFF_DAYS + RETIREMENT_CLEANUP_COOL_OFF_DAYS` days after the retirement request.
With the values above, this matches the upstream default of 37 days.
With the default value of `0`, the records are deleted in the same pipeline run that retires the learner.

If you do not set `RETIREMENT_CLEANUP_AWS_ACCESS_KEY_ID` and `RETIREMENT_CLEANUP_AWS_SECRET_ACCESS_KEY`, the script uses the [default boto3 credential chain](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/credentials.html).

## Configuration

* `RETIREMENT_EDX_OAUTH2_CLIENT_ID` (default `"retirement_service_worker"`)
* `RETIREMENT_COOL_OFF_DAYS` (default `30`)
* `RETIREMENT_CLEANUP_COOL_OFF_DAYS` (default `0`)
* `RETIREMENT_CLEANUP_S3_BUCKET_NAME` (default `""`, cleanup disabled)
* `RETIREMENT_CLEANUP_AWS_ACCESS_KEY_ID` (default `""`)
* `RETIREMENT_CLEANUP_AWS_SECRET_ACCESS_KEY` (default `""`)
* `RETIREMENT_K8S_CRONJOB_HISTORYLIMIT_FAILURE` (default `1`)
* `RETIREMENT_K8S_CRONJOB_HISTORYLIMIT_SUCCESS` (default `3`)
* `RETIREMENT_K8S_CRONJOB_SCHEDULE` (default `"0 0 * * *"`, once a day at midnight)

These values can be modified with `tutor config save --set PARAM_NAME=VALUE` commands.
