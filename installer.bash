#!/bin/bash/env bash

#
# Filename:       installer.bash
# Description:    Manages deploy-VFIO binaries and files.
# Author(s):      Alex Portell <github.com/portellam>
# Maintainer(s):  Alex Portell <github.com/portellam>
#

#
# parameters
#
  declare -gr SCRIPT_NAME=$( basename "${0}" )
  declare -gr MAIN_EXECUTABLE="deploy-vfio"

  declare -gA INPUTS=(
    ["DO_INSTALL"]=true
  )

  #
  # Color coding
  # Reference URL: 'https://www.shellhacks.com/bash-colors'
  #
    declare -g SET_COLOR_GREEN='\033[0;32m'
    declare -g SET_COLOR_RED='\033[0;31m'
    declare -g SET_COLOR_YELLOW='\033[0;33m'
    declare -g RESET_COLOR='\033[0m'

  #
  # Output
  #
    declare -gr PREFIX_PROMPT="${SCRIPT_NAME}: "
    declare -gr PREFIX_ERROR="${PREFIX_PROMPT}${SET_COLOR_YELLOW}An error occurred:${RESET_COLOR} "
    declare -gr PREFIX_FAIL="${PREFIX_PROMPT}${SET_COLOR_RED}Failure:${RESET_COLOR} "
    declare -gr PREFIX_PASS="${PREFIX_PROMPT}${SET_COLOR_GREEN}Success:${RESET_COLOR} "

#
# Logic
#
  function main
  {
    if [[ $( whoami ) != "root" ]]; then
      print_error_to_log "User is not sudo or root."
      return 1
    fi

    get_input "${@}" || return 1

    local -r source_subfolder="${MAIN_EXECUTABLE}.d"
    local -r source_path=$( pwd )"/${source_subfolder}/"
    local -r bin_path="/usr/local/bin/"
    local -r bin_target_path="${bin_path}${source_subfolder}/"
    local -r bin_source_path="${source_path}bin/"
    local -r etc_target_path="/usr/local/etc/${source_subfolder}/"
    local -r etc_source_path="${source_path}etc/"

    if ${INPUTS["DO_INSTALL"]}; then
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

    return 0
  }

  #
  # Checks
  #
    function do_binaries_exist
    {
      if [[ ! -e "${MAIN_EXECUTABLE}" ]]; then
        print_error_to_log "Missing main executable."
        return 1
      fi

      local -r lwd=$( pwd )
      cd "${bin_source_path}" || return 1

      if [[ ! -e "args_common" ]] \
        || [[ ! -e "src_auto_xorg" ]] \
        || [[ ! -e "src_compatibility" ]] \
        || [[ ! -e "src_datatype" ]] \
        || [[ ! -e "src_file_output" ]] \
        || [[ ! -e "src_files" ]] \
        || [[ ! -e "src_generate_evdev" ]] \
        || [[ ! -e "src_git" ]] \
        || [[ ! -e "src_hugepages" ]] \
        || [[ ! -e "src_interaction" ]] \
        || [[ ! -e "src_iommu" ]] \
        || [[ ! -e "src_iommu_device_getters" ]] \
        || [[ ! -e "src_iommu_device_validation" ]] \
        || [[ ! -e "src_iommu_presentation" ]] \
        || [[ ! -e "src_iommu_xml" ]] \
        || [[ ! -e "src_isolcpu" ]] \
        || [[ ! -e "src_libvirt_hooks" ]] \
        || [[ ! -e "src_looking_glass" ]] \
        || [[ ! -e "src_memory" ]] \
        || [[ ! -e "src_print" ]] \
        || [[ ! -e "src_privileges" ]] \
        || [[ ! -e "src_vfio_setup" ]] \
        || [[ ! -e "src_zram_swap" ]]; then
        print_error_to_log "Missing project binaries."
        return 1
      fi

      if ! cd "${lwd}"; then
        print_error_to_log "Could not return to last working directory."
        return 1
      fi

      return 0
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

      return 0
    }

    function does_target_path_exist
    {
      if [[ ! -d "${bin_target_path}" ]] \
        && ! sudo \
          mkdir \
            --parents \
            "${bin_target_path}"; then
        print_error_to_log "Could not create directory '${bin_target_path}'."
        return 1
      fi

      if [[ ! -d "${etc_target_path}" ]] \
        && ! sudo \
          mkdir \
            --parents \
            "${etc_target_path}"; then
        print_error_to_log "Could not create directory '${etc_target_path}'."
        return 1
      fi

      return 0
    }

  #
  # Execution
  #
    function copy_sources_to_targets
    {
      if ! sudo \
          cp \
            --force \
            "${MAIN_EXECUTABLE}" \
            "${bin_path}${MAIN_EXECUTABLE}" \
          &> /dev/null; then
        print_error_to_log "Could not copy main executable."
        return 1
      fi

      set -o xtrace

      if ! sudo \
          cp \
            --force \
            --recursive \
            "${bin_source_path}"* \
            "${bin_source_path}" \
          &> /dev/null; then
        print_error_to_log "Could not copy project binaries."
        return 1
      fi

      if ! sudo \
          cp \
            --force \
            --recursive \
            "${etc_source_path}"* \
            "${etc_source_path}" \
          &> /dev/null; then
        print_error_to_log "Could not copy project file(s)."
        return 1
      fi

      return 0
    }

    function install
    {
      do_binaries_exist || return 1
      do_files_exist || return 1
      does_target_path_exist || return 1
      copy_sources_to_targets || return 1
      set_target_file_permissions || return 1
      return 0
    }

    function set_target_file_permissions
    {
      if ! sudo \
          chown \
            --recursive \
            root:root \
            "${bin_target_path}" \
          &> /dev/null \
        || ! sudo \
          chmod \
            --recursive \
            +x \
            "${bin_target_path}" \
          &> /dev/null \
        || ! sudo \
          chown \
            --recursive \
            root:root \
            "${etc_target_path}" \
          &> /dev/null; then
        print_error_to_log "Could not set file permissions."
        return 1
      fi

      return 0
    }

    function uninstall
    {
      if ! rm \
          --force \
            "${bin_path}${MAIN_EXECUTABLE}" \
          &> /dev/null; then
        print_error_to_log "Could not delete main executable."
        return 1
      fi

      if ! rm \
          --force \
            "$bin_target_path}" \
          &> /dev/null; then
        print_error_to_log "Could not delete project binaries."
        return 1
      fi

      if ! rm \
          --force \
            "$etc_target_path}" \
          &> /dev/null; then
        print_error_to_log "Could not delete project file(s)."
        return 1
      fi

      return 0
    }

  #
  # Loggers
  #
    function print_error_to_log
    {
      echo \
        -e \
          "${PREFIX_ERROR}${1}" \
        >&2
    }

    function print_fail_to_log
    {
      echo \
        -e \
          "${PREFIX_FAIL}${1}" \
        >&2
    }

    function print_pass_to_log
    {
      echo \
        -e \
          "${PREFIX_PASS}${1}" \
        >&1
    }

  #
  # Usage
  #
    function get_input
    {
      if is_any_input_declared; then
        return 0
      fi

      case "${1}" in
        "-u" | "--uninstall" )
          INPUTS["DO_INSTALL"]=false
          ;;

        "-i" | "--install" )
          INPUTS["DO_INSTALL"]=true
          ;;

        "-h" | "--help" | * )
          print_usage
          return 1 ;;
      esac

      return 0
    }

    function is_any_input_declared
    {
      for key in ${!INPUTS[@]}; do
        local value=${INPUTS["${key}"]}

        if [[ "${value}" != "" ]]; then
          return 0
        fi
      done

      return 1
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

      echo \
        -e \
          "${output[*]}"

      unset IFS
      return 0
    }

#
# Main
#
  main "${@}"
  exit "${?}"