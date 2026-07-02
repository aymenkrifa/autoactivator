# Shared constants for setup.sh, autoactivator_config.sh, and the test
# suite. Sourced at install time and at every shell startup, so it must
# only define variables — no functions, no side effects.
#
# Editing the marker strings here changes them in lockstep across
# install, doctor, and uninstall.

# shellcheck disable=SC2034  # consumed by the files that source this one
AUTOACTIVATOR_BLOCK_OPEN="############################# AutoActivator #############################"
AUTOACTIVATOR_BLOCK_CLOSE="#########################################################################"
