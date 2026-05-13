# Review Rules

# SECURITY: public/setup.sh must be reviewed carefully despite being a utility script.
# - Watch for command injection vulnerabilities in shell string interpolation
# - All external values passed to node -e must use environment variables, never string interpolation
