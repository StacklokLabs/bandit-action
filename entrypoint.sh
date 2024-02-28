#!/bin/bash


# Use the INPUT_ prefixed environment variables that are passed by GitHub Actions
github_token=$INPUT_GITHUB_TOKEN
github_repository=$INPUT_GITHUB_REPOSITORY

# Initialize the Bandit command
cmd="bandit"
# Check if the recursive flag is set
if [ -n "${INPUT_RECURSIVE}" ]; then
    cmd+=" -r"
fi

# Check for the path input and add it to the command
if [ -n "${INPUT_PATH}" ]; then
    cmd+=" -r ${INPUT_PATH}"
fi

# Check for the level input and set the severity level
if [ -n "${INPUT_LEVEL}" ]; then
    case "${INPUT_LEVEL}" in
        "low") cmd+=" -l" ;;
        "medium") cmd+=" -ll" ;;
        "high") cmd+=" -lll" ;;
    esac
fi

# Check for the confidence input and set the confidence level
if [ -n "${INPUT_CONFIDENCE}" ]; then
    case "${INPUT_CONFIDENCE}" in
        "low") cmd+=" -i" ;;
        "medium") cmd+=" -ii" ;;
        "high") cmd+=" -iii" ;;
    esac
fi

# Add arguments to the command based on the input values
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

# Specify the output format as JSON and output file
cmd+=" -f json -o report.json"

# Run the Bandit command
echo "Executing command: $cmd"
eval $cmd

# Call post_comment.py to post the Bandit report as a comment on the pull request
GITHUB_TOKEN=$GITHUB_TOKEN GITHUB_REPOSITORY=$GITHUB_REPOSITORY python /post_comment.py

# If specified, exit with 0 even if issues are found
if [ "${INPUT_EXIT_ZERO}" == "true" ]; then
    exit 0
fi

# Check if report.json exists and is not empty
if [ -s report.json ]; then
    # If you want to fail the action on detected issues, uncomment the next line
    # exit 1
    echo "Bandit scan completed with findings."
else
    echo "Bandit scan completed with no findings."
fi
