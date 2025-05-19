# Thanks to https://unix.stackexchange.com/a/145654/108960
log_file=sentry_install_log-$(date +'%Y-%m-%d_%H-%M-%S').txt
exec &> >(tee -a "$log_file")
