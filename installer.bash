#!/bin/bash/env bash

#
# Filename:       installer.bash
# Description:    Manages deploy-VFIO binaries and files.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
#

# <params>
  declare -gr SCRIPT_NAME=$( basename "${0}" )
  declare -gr MAIN_EXECUTABLE="deploy-vfio"

  # <summary>Execution Flags</summary>
    declare -g DO_INSTALL=true

  # <summary>
  # Color coding
  # Reference URL: 'https://www.shellhacks.com/bash-colors'
  # </summary>
    declare -g SET_COLOR_GREEN='\033[0;32m'
    declare -g SET_COLOR_RED='\033[0;31m'
    declare -g SET_COLOR_YELLOW='\033[0;33m'
    declare -g RESET_COLOR='\033[0m'

  # <summary>Append output</summary>
    declare -gr PREFIX_PROMPT="${SCRIPT_NAME}: "
    declare -gr PREFIX_ERROR="${PREFIX_PROMPT}${SET_COLOR_YELLOW}An error occurred:${RESET_COLOR} "
    declare -gr PREFIX_FAIL="${PREFIX_PROMPT}${SET_COLOR_RED}Failure:${RESET_COLOR} "
    declare -gr PREFIX_PASS="${PREFIX_PROMPT}${SET_COLOR_GREEN}Success:${RESET_COLOR} "
# </params>

# <functions>
  function main
  {
    if [[ $( whoami ) != "root" ]]; then
      print_error_to_log "User is not sudo or root."
      return 1
    fi

    get_option "${1}" || return 1

    local -r source_subfolder="${MAIN_EXECUTABLE}.d"
    local -r source_path=$( pwd )"/${source_subfolder}/"
    local -r bin_path="/usr/local/bin/"
    local -r bin_target_path="${bin_path}${source_subfolder}/"
    local -r bin_source_path="${source_path}/bin/"
    local -r etc_target_path="/usr/local/etc/${source_subfolder}/"
    local -r etc_source_path="${source_path}/etc/"

    if "${DO_INSTALL}"; then
      if ! install; then
        print_fail_to_log "Could not install deploy-VFIO."
        return 1
      else
        print_pass_to_log "Installed deploy-VFIO."
      fi
    else
      if ! uninstall; then
        print_fail_to_log "Could not uninstall deploy-VFIO."
        return 1
      else
        print_pass_to_log "Uninstalled deploy-VFIO."
      fi
    fi
  }

  # <summary>Checks</summary>
    function do_binaries_exist
    {
      if [[ ! -e "${MAIN_EXECUTABLE}" ]]; then
        print_error_to_log "Missing main executable."
        return 1
      fi

      local -r lwd=$( pwd )
      cd "${bin_source_path}" || return 1

      if [[ ! -e "args_common" ]] \
        || [[ ! -e "args_compatibility" ]] \
        || [[ ! -e "args_database" ]] \
        || [[ ! -e "args_main-setup" ]] \
        || [[ ! -e "args_post-setup" ]] \
        || [[ ! -e "args_pre-setup" ]] \
        || [[ ! -e "args_usage" ]] \
        || [[ ! -e "logic_common" ]] \
        || [[ ! -e "logic_compatibility" ]] \
        || [[ ! -e "logic_database" ]] \
        || [[ ! -e "logic_main-setup" ]] \
        || [[ ! -e "logic_post-setup" ]] \
        || [[ ! -e "logic_pre-setup" ]] \
        || [[ ! -e "sources" ]]; then
        print_error_to_log "Missing project binaries."
        return 1
      fi

      if ! cd "${lwd}"; then
        print_error_to_log "Could not return to last working directory."
        return 1
      fi
    }

    function do_files_exist
    {
      local -r lwd=$( pwd )
      cd "${etc_source_path}" || return 1

      if [[ ! -e "custom" ]] \
        || [[ ! -e "grub" ]] \
        || [[ ! -e "initramfs-tools" ]] \
        || [[ ! -e "modules" ]] \
        || [[ ! -e "pci-blacklists.conf" ]] \
        || [[ ! -e "vfio.conf" ]]; then
        print_error_to_log "Missing project files."
        return 1
      fi

      if ! cd "${lwd}"; then
        print_error_to_log "Could not return to last working directory."
        return 1
      fi
    }

    function does_target_path_exist
    {
      if [[ ! -d "${bin_target_path}" ]] \
        && ! sudo mkdir --parents "${bin_target_path}"; then
        print_error_to_log "Could not create directory '${bin_target_path}'."
        return 1
      fi

      if [[ ! -d "${etc_target_path}" ]] \
        && ! sudo mkdir --parents "${etc_target_path}"; then
        print_error_to_log "Could not create directory '${etc_target_path}'."
        return 1
      fi
    }

  # <summary>Execution</summary>
    function copy_sources_to_targets
    {
      if ! sudo cp --force "${MAIN_EXECUTABLE}" "${bin_path}${MAIN_EXECUTABLE}" &> /dev/null; then
        print_error_to_log "Could not copy main executable."
        return 1
      fi

      if ! sudo cp --force --recursive "${bin_source_path}"* "${bin_target_path}" &> /dev/null; then
        print_error_to_log "Could not copy project binaries."
        return 1
      fi

      if ! sudo cp --force --recursive "${etc_source_path}"* "${etc_target_path}" &> /dev/null; then
        print_error_to_log "Could not copy project file(s)."
        return 1
      fi
    }

    function install
    {
      do_binaries_exist || return 1
      do_files_exist || return 1
      does_target_path_exist || return 1
      copy_sources_to_targets || return 1
      set_target_file_permissions || return 1
    }

    function set_target_file_permissions
    {
      if ! sudo chown --recursive root:root "${bin_target_path}" &> /dev/null \
        || ! sudo chmod --recursive +x "${bin_target_path}" &> /dev/null \
        || ! sudo chown --recursive root:root "${etc_target_path}" &> /dev/null; then
        print_error_to_log "Could not set file permissions."
        return 1
      fi
    }

    function uninstall
    {
      if ! rm --force "${bin_path}${MAIN_EXECUTABLE}" &> /dev/null; then
        print_error_to_log "Could not delete main executable."
        return 1
      fi

      if ! rm --force --recursive "${bin_target_path}" &> /dev/null; then
        print_error_to_log "Could not delete project binaries."
        return 1
      fi

      if ! rm --force --recursive "${etc_target_path}" &> /dev/null; then
        print_error_to_log "Could not delete project file(s)."
        return 1
      fi
    }

  # <summary>Loggers/summary>
    function print_error_to_log
    {
      echo -e "${PREFIX_ERROR}${1}" >&2
    }

    function print_fail_to_log
    {
      echo -e "${PREFIX_FAIL}${1}" >&2
    }

    function print_pass_to_log
    {
      echo -e "${PREFIX_PASS}${1}" >&1
    }

  # <summary>Usage</summary>
    function get_option
    {
      case "${1}" in
        "-u" | "--uninstall" )
          DO_INSTALL=false ;;

        "-i" | "--install" )
          DO_INSTALL=true ;;

        "-h" | "--help" | * )
          print_usage
          return 1 ;;
      esac
    }

    function print_usage
    {
      IFS=$'\n'

      local -ar output=(
        "Usage:\tbash installer.bash [OPTION]"
        "Manages ${MAIN_EXECUTABLE} binaries and files.\n"
        "  -h,  --help\t\tPrint this help and exit."
        "  -i,  --install\t\tInstall ${MAIN_EXECUTABLE} to system."
        "  -u,  --uninstall\tUninstall ${MAIN_EXECUTABLE} from system."
      )

      echo -e "${output[*]}"
      unset IFS
    }
# </functions>

# <code>
  main "${1}"
  exit "${?}"
# </code>