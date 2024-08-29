#!/bin/bash
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH/..

# Set parameters
ORG_ALIAS=${1:-"apex-performance-testing"}

echo ""
echo "Installing Performance Testing scratch org: ($ORG_ALIAS)"
echo ""

# Install script
echo "Cleaning previous scratch org..."
sf org delete scratch -p -o $ORG_ALIAS &> /dev/null
echo ""

echo "Creating scratch org..." && \
sf org create scratch --definition-file config/apex-performance-testing-scratch-def.json --alias "${ORG_ALIAS}" --set-default --duration-days 30 --wait 20 && \
echo "" && \

echo "Pushing source..." && \
sf project deploy start && \
echo "" && \

echo "Assigning permission sets..." && \
sf org assign permset --name PerformanceAnalyst && \
echo "" && \

echo "Running apex tests..." && \
sf apex run test --synchronous && \
echo "" && \

echo "Opening org..." && \
sf org open && \
echo ""

EXIT_CODE="$?"
echo ""

# Check exit code
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Installation completed."
else
    echo "Installation failed."
fi
exit $EXIT_CODE
