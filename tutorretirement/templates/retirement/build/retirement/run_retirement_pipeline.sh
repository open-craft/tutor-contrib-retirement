cool_off_days=$1
# Only passed when an S3 bucket for the retirement archive is configured.
cleanup_cool_off_days=$2
python scripts/user_retirement/get_learners_to_retire.py --config_file=scripts/user_retirement/pipeline_config/config.yml --output_dir=scripts/user_retirement/learners_to_retire --cool_off_days="$cool_off_days"
for filename in scripts/user_retirement/learners_to_retire/*;do
    if test ! -f "$filename";then
        echo "No users to retire"
        continue
    else
        IFS="=" read -r name username <"$filename"
        echo "Retiring $username"
        python scripts/user_retirement/retire_one_learner.py --config_file=scripts/user_retirement/pipeline_config/config.yml --username="$username"
    fi
done
if [ -z "$cleanup_cool_off_days" ];then
    echo "Retirement cleanup is disabled"
else
    # Both cool-off periods are counted from the retirement request date, so
    # add them up to keep the retirement records for cleanup_cool_off_days
    # after the learner has been retired.
    # Batching makes the script skip the S3 upload when there is nothing to
    # clean up, instead of archiving an empty file.
    python scripts/user_retirement/retirement_archive_and_cleanup.py --config_file=scripts/user_retirement/pipeline_config/config.yml --cool_off_days="$((cool_off_days + cleanup_cool_off_days))" --batch_size=1000
fi
