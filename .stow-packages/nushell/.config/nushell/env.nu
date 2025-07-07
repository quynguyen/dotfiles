# Nushell environment configuration
# This file is loaded before config.nu

# Set initial environment variables that other programs might need
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')
]

$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')
]

# Default directories for custom scripts and completions
if not (($env.NU_LIB_DIRS | get 0) | path exists) {
    mkdir ($env.NU_LIB_DIRS | get 0)
}

if not (($env.NU_PLUGIN_DIRS | get 0) | path exists) {
    mkdir ($env.NU_PLUGIN_DIRS | get 0)
}