#!/bin/bash


# Use the INPUT_ prefixed environment variables that are passed by GitHub Actions
github_token=$INPUT_GITHUB_TOKEN
github_repository=$INPUT_GITHUB_REPOSITORY

# Initialize the Bandit command
cmd="bandit"
# # Check if the recursive flag is set
# if [ -n "${INPUT_RECURSIVE}" ]; then
#     cmd+=" -r"
# fi

# Check for the path input and add it to the command
if [ -n "${INPUT_PATH}" ]; then
    cmd+=" -r ${INPUT_PATH}"
fi

# # Check for the level input and set the severity level
# if [ -n "${INPUT_LEVEL}" ]; then
#     case "${INPUT_LEVEL}" in
#         "low") cmd+=" -l" ;;
#         "medium") cmd+=" -ll" ;;
#         "high") cmd+=" -lll" ;;
#     esac
# fi

# # Check for the confidence input and set the confidence level
# if [ -n "${INPUT_CONFIDENCE}" ]; then
#     case "${INPUT_CONFIDENCE}" in
#         "low") cmd+=" -i" ;;
#         "medium") cmd+=" -ii" ;;
#         "high") cmd+=" -iii" ;;
#     esac
# fi

[ "$INPUT_VERBOSE" = "true" ] && cmd+=" -v"
[ "$INPUT_DEBUG" = "true" ] && cmd+=" -d"
[ "$INPUT_QUIET" = "true" ] && cmd+=" -q"
[ "$INPUT_IGNORE_NOSEC" = "true" ] && cmd+=" --ignore-nosec"
[ "$INPUT_RECURSIVE" = "true" ] && cmd+=" -r"
[ -n "$INPUT_AGGREGATE" ] && cmd+=" -a $INPUT_AGGREGATE"
[ -n "$INPUT_CONTEXT_LINES" ] && cmd+=" -n $INPUT_CONTEXT_LINES"
[ -n "$INPUT_CONFIG_FILE" ] && cmd+=" -c $INPUT_CONFIG_FILE"
[ -n "$INPUT_PROFILE" ] && cmd+=" -p $INPUT_PROFILE"
[ -n "$INPUT_TESTS" ] && cmd+=" -t $INPUT_TESTS"
[ -n "$INPUT_SKIPS" ] && cmd+=" -s $INPUT_SKIPS"
[ -n "$INPUT_SEVERITY_LEVEL" ] && cmd+=" --severity-level $INPUT_SEVERITY_LEVEL"
[ -n "$INPUT_CONFIDENCE_LEVEL" ] && cmd+=" --confidence-level $INPUT_CONFIDENCE_LEVEL"
[ -n "$INPUT_EXCLUDE_PATHS" ] && cmd+=" -x $INPUT_EXCLUDE_PATHS"
[ -n "$INPUT_BASELINE" ] && cmd+=" -b $INPUT_BASELINE"
[ -n "$INPUT_INI_PATH" ] && cmd+=" --ini $INPUT_INI_PATH"
[ "$INPUT_EXIT_ZERO" = "true" ] && cmd+=" --exit-zero"

# Force the output format as JSON and output file, we json and to report.json
# as this is required to format the output for the post_comment.py script
cmd+=" -f json -o report.json"

# Run the Bandit command
echo "Executing command: $cmd"
eval $cmd

# Capture the exit code from Bandit
bandit_exit_code=$?

GITHUB_TOKEN=$GITHUB_TOKEN GITHUB_REPOSITORY=$GITHUB_REPOSITORY python /post_comment.py

# Check if exit_zero is set to "true"
if [ "$INPUT_EXIT_ZERO" = "true" ]; then
    echo "exit_zero is set to true. Exiting with code 0 regardless of Bandit findings."
    exit 0
else
    # If Bandit exited with a non-zero exit code and exit_zero is not true, exit this script with the Bandit exit code
    if [ $bandit_exit_code -ne 0 ]; then
        echo "Bandit found issues and exit_zero is not set to true. Exiting with code $bandit_exit_code."
        exit $bandit_exit_code
    fi
fi

