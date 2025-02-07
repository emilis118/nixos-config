#!/bin/bash

# Check if Discord is running, start it if not
pgrep Discord || (discord &)

# Switch to the specified workspace
i3-msg workspace "9:Discord"
