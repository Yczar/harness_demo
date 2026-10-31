#!/usr/bin/env bash
# HUMAN ONLY. Creates or updates golden files after you've looked at the UI.
# Agents are blocked from running this (and from --update-goldens) by the
# Bash guard hook, because an agent that can rewrite the goldens can hide its
# own failure.
set -eu
cd "$(dirname "$0")/../.."
flutter test --tags golden --update-goldens
echo "Golden files updated. Look at the PNGs in test/golden/goldens/ before you commit them."
