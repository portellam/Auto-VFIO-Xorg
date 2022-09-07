#!/bin/bash sh

#
# Author(s):    Alex Portell <github.com/portellam>
#

#
# TO-DO
# -check if certain devices (pci usb) are grabbed by VFIO, in Multi-boot
# -terminal output reports an error in grub output, but it doesn't appear to cause an issue. Monitor this.
#
#

#
# NOTES:
# -find driver by BUS ID
# "lspci -nnk -d PCI_BUS_ID_HERE | grep driver"
#


# check if sudo/root #
    if [[ `whoami` != "root" ]]; then
        str_file=`echo ${0##/*}`
        str_file=`echo $str_file | cut -d '/' -f2`
        echo -e "$0: WARNING: Script must execute as root. In terminal, run:\n\t'sudo bash $str_file'\n\tor\n\t'su' and 'bash $str_file'.\n$str_file: Exiting."
        exit 0
    fi

# check if in correct dir #
    str_pwd=`pwd`

    if [[ `echo ${str_pwd##*/}` != "install.d" ]]; then
        if [[ -e `find . -name install.d` ]]; then
            # echo -e "$0: Script located the correct working directory."
            cd `find . -name install.d`
        else
            echo -e "$0: WARNING: Script cannot locate the correct working directory. Exiting."
        fi
    # else
    #     echo -e "$0: Script is in the correct working directory."
    fi

# NOTE: necessary for newline preservation in arrays and files #
    SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
    IFS=$'\n'      # Change IFS to newline char

# precede with echo prompt for input #
    # ask user for input then validate #
    function ReadInput {
        echo -en "$0: $str_output1"

        if [[ $str_input1 == "Y" ]]; then
            echo -en $str_output1$str_input1
        else
            declare -i int_count=0      # reset counter

            while true; do
                # manual prompt #
                if [[ $int_count -ge 3 ]]; then       # auto answer
                    echo "Exceeded max attempts."
                    str_input1="N"                    # default input     # NOTE: change here
                else
                    echo -en $str_output1
                    read str_input1

                    str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`
                    str_input1=${str_input1:0:1}
                fi

                case $str_input1 in
                    "Y"|"N")
                        break;;
                    *)
                        echo -en "$0: Invalid input. ";;
                esac

                ((int_count++))         # increment counter
            done
        fi
    }

# parameters #
    readonly str_thisFile="${0##*/}"
    readonly str_logFile0="$str_thisFile.log"
    bool_dev_isExt=false
    bool_dev_isVFIO=false
    bool_devIsVGA=false
    bool_missingFiles=false
    readonly int_lastIOMMU=`compgen -G "/sys/kernel/iommu_groups/*/devices/*" | cut -d '/' -f5 | sort -hr | head -n1`
    str_IGPU_devFullName="N/A"
    str_file=`find .. -name *Hugepages*log*`

# GRUB and hugepages check #
    if [[ -z $str_file ]]; then
        str_file=`find . -name *Hugepages*bash*`
        str_file=`echo ${str_file##/*} | cut -d '/' -f2`

        echo -e '$str_file == '"'$str_file'"
        str_file=`echo $str_file | cut -d '/' -f2`

        echo -e '$str_file == '"'$str_file'"
        echo -e "$0: Hugepages logfile does not exist. Should you wish to enable Hugepages, execute both '$str_file' and '$0'.\n"
    else
        readonly str_HugePageSize=`cat $str_file | cut -d '#' -f2 | cut -d ' ' -f1`
        readonly str_HugePageSum=`cat $str_file | cut -d '#' -f3`
        readonly str_GRUB_CMDLINE_Hugepages="default_hugepagesz=${str_HugePageSize} hugepagesz=${str_HugePageSize} hugepages=${str_HugePageSum}"
    fi

    # NOTE: update here #
    str_GRUB_CMDLINE_prefix="quiet splash video=efifb:off acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 ${str_GRUB_CMDLINE_Hugepages}"

# Multi boot setup #
    function MultiBootSetup {

        echo -e "$0: Executing Multi-boot setup..."

        # Parse IOMMU #
            # shell option #
            shopt -s nullglob

            # parameters #
                declare -a arr_IOMMU_sum=(`find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`)
                declare -a arr_devIndex_sum=()
                declare -a arr_devDriver_sum=()
                declare -a arr_devHWID_sum=()
                declare -a arr_devName_sum=()
                declare -a arr_devVendor_sum=()
                declare -a arr_IOMMU_VFIO_VGA=()
                declare -i int_i=0
                str_devDriver_host_list=""
                str_devDriver_VFIO_list=""
                str_devHWID_STUB_list=""
                str_devHWID_VFIO_list=""

            # parse IOMMU groups #
                for str_line1 in $(find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V); do

                    # parameters #
                        bool_devIsExt=false
                        bool_devIsVGA=false;
                        declare -i int_IOMMU=`echo $str_line1 | cut -d '/' -f5`
                        str_input1=""

                    # prompt #
                    echo -e "\n\tIOMMU :\t\t${int_IOMMU##*/}"

                    # parse devices #
                        for str_line2 in $str_line1/devices/*; do

                            # parameters #
                                int_thisIOMMU=`echo $str_line2 | cut -d '/' -f5`
                                str_devBusID=`lspci -s ${str_line2##*/} | cut -d ' ' -f1`
                                str_devDriver=`lspci -nnks ${str_line2##*/} | grep 'driver' | cut -d ':' -f2 | cut -d ' ' -f2`
                                str_devHWID=`lspci -ns ${str_line2##*/} | cut -d ' ' -f3`
                                str_devName=`lspci -ms ${str_line2##*/} | cut -d '"' -f6`
                                # str_devName=`lspci -m | grep $str_devBusID | cut -d '"' -f6`
                                str_devType=`lspci -ms ${str_line2##*/} | cut -d '"' -f2`
                                str_devVendor=`lspci -ms ${str_line2##*/} | cut -d '"' -f4`

                            # prompt #
                                echo
                                echo -e "\tBUS ID:\t\t'$str_devBusID'"
                                echo -e "\tVENDOR:\t\t'$str_devVendor'"
                                echo -e "\tNAME  :\t\t'$str_devName'"
                                echo -e "\tTYPE  :\t\t'$str_devType'"
                                echo -e "\tHW ID :\t\t'$str_devHWID'"
                                echo -e "\tDRIVER:\t\t'$str_devDriver'"

                            # match null #
                                if [[ -z $str_devDriver || $str_devDriver == "" ]]; then
                                    str_devDriver="N/A"
                                fi

                                if [[ -z $str_devName || $str_devName == "" || $str_devName == " "* ]]; then
                                    str_devName="N/A"
                                fi

                                if [[ -z $str_devType || $str_devType == "" ]]; then
                                    str_devType="N/A"
                                fi

                            # match type #
                            if [[ $str_devType == *"VGA"* || $str_devType == *"GRAPHICS"* ]]; then
                                bool_devIsVGA=true
                            fi

                            # match vfio, set boolean #
                            if [[ $str_devDriver == *"vfio-pci"* ]]; then
                                bool_devIsVFIO=true
                            fi

                            # # match problem driver #
                            # if [[ $str_devDriver == *"snd_hda_intel"* ]]; then
                            #     str_devDriver="N/A"
                            # fi

                            # lists #
                                arr_devIndex_sum+=("$int_i")
                                arr_devIOMMU_sum+=("$int_thisIOMMU")
                                arr_devHWID_sum+=("$str_devHWID")
                                arr_devName_sum+=("$str_devName")
                                arr_devType_sum+=("$str_devType")
                                arr_devVendor_sum+=("$str_devVendor")
                                arr_devDriver_sum+=("$str_devDriver")

                            # update parameters #
                            str_devType=`echo $str_devType | tr '[:lower:]' '[:upper:]'`

                            # update parameters #
                            str_devBusID=`echo $str_devBusID | cut -d ':' -f1`

                            # checks #
                            # set flag for external groups #
                            if [[ ${str_devBusID:1} != 0 || ${str_devBusID::2} -gt 0 ]]; then
                                bool_devIsExt=true
                            else
                                if [[ $bool_devIsVGA == true ]]; then
                                    readonly str_IGPU_devFullName="$str_devVendor $str_devName"
                                fi
                            fi

                            ((int_i++))
                        done

                    # prompt #
                        if [[ $bool_devIsExt == true ]]; then
                            echo
                            str_output1="Select IOMMU group '$int_IOMMU'? [Y/n]: "
                            ReadInput $str_output1

                            if [[ $bool_devIsVGA == false ]]; then
                                case $str_input1 in
                                    "Y")
                                        arr_IOMMU_VFIO+=("$int_IOMMU")
                                        echo -e "$0: Selected IOMMU group '$int_IOMMU'.";;
                                    "N")
                                        arr_IOMMU_host+=("$int_IOMMU");;
                                    *)
                                        echo -en "$0: Invalid input.";;
                                esac
                            else
                                case $str_input1 in
                                    "Y")
                                        arr_IOMMU_VFIO_VGA+=("$int_IOMMU")
                                        echo -e "$0: Selected IOMMU group '$int_IOMMU'.";;
                                    "N")
                                        arr_IOMMU_host_VGA+=("$int_IOMMU");;
                                    *)
                                        echo -en "$0: Invalid input.";;
                                esac
                            fi
                        else
                            arr_IOMMU_host+=("$int_IOMMU")
                            echo -e "\n$0: Skipped IOMMU group '$int_IOMMU'."
                        fi
                done

                if [[ ${#arr_IOMMU_VFIO_VGA[@]} -eq 0 ]]; then
                    str_file=`find . -name *Static*bash`
                    str_file=`echo ${str_file##/*}`
                    str_file=`echo $str_file | cut -d '/' -f2`
                    echo -e "$0: WARNING: No VGA IOMMU groups selected/available.\n\tIf none are available, Multi-boot will not continue. Instead, execute '$str_file'.";
                    exit 0
                fi

                # exclude matching host drivers for VFIO setup #
                    # parse host drivers #
                    for int_IOMMU_host in ${arr_IOMMU_host[@]}; do
                        for (( int_i=0 ; int_i<${#arr_devIndex_sum[@]} ; int_i++ )); do
                            int_thisIOMMU=${arr_devIOMMU_sum[$int_i]}
                            str_thisDevDriver=${arr_devDriver_sum[$int_i]}

                            # match IOMMU and valid driver, false match existing element in list #
                            if [[ "$int_thisIOMMU" == "$int_IOMMU_host" && $str_thisDevDriver != "" && $str_thisDevDriver != "N/A" && $str_devDriver_host_list != *$str_thisDevDriver* ]]; then
                                str_devDriver_host_list+="$str_thisDevDriver,"
                            fi
                        done
                    done

            # generate output for system files #
                for int_IOMMU_VFIO in ${arr_IOMMU_VFIO[@]}; do
                    for (( int_i=0 ; int_i<${#arr_devIndex_sum[@]} ; int_i++ )); do
                        int_thisIOMMU=${arr_devIOMMU_sum[$int_i]}
                        str_thisDevDriver=${arr_devDriver_sum[$int_i]}
                        str_thisDevHWID=${arr_devHWID_sum[$int_i]}
                        str_thisDevType=`echo ${arr_devType_sum[$int_i]} | tr '[:lower:]' '[:upper:]'`

                        # match IOMMU and false match existing element in list #
                        if [[ "$int_thisIOMMU" == "$int_IOMMU_VFIO" && $str_devHWID_VFIO_list != *$str_thisDevHWID* ]]; then

                            # bind to pci-stub #
                            if [[ $str_thisDevType == *"USB"* ]]; then
                                str_devHWID_STUB_list+="$str_thisDevHWID,"

                            # bind to vfio-pci #
                            else
                                str_devHWID_VFIO_list+="$str_thisDevHWID,"
                            fi

                            # valid driver and false match existing element in list(s) #
                            if [[ $str_thisDevDriver != "" && $str_thisDevDriver != "N/A" && $str_devDriver_host_list != *$str_thisDevDriver* && $str_devDriver_VFIO_list != *$str_devDriver_host_list* ]]; then
                                arr_devDriver_VFIO+=("$str_thisDevDriver")
                                str_devDriver_VFIO_list+="$str_thisDevDriver,"
                            fi
                        fi
                    done
                done

            # debug prompt #
                # uncomment lines below #
                function DebugOutput {
                    echo -e "$0: ========== DEBUG PROMPT ==========\n"

                    for (( i=0 ; i<${#arr_devIndex_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devIndex_sum[$i]}'\t= '${arr_devIndex_sum[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_devIOMMU_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devIOMMU_sum[$i]}'\t= '${arr_devIOMMU_sum[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_devDriver_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devDriver_sum[$i]}'\t= '${arr_devDriver_sum[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_devDriver_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_devDriver_VFIO[$i]}'\t= '${arr_devDriver_VFIO[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_devHWID_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devHWID_sum[$i]}'\t= '${arr_devHWID_sum[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_devName_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devName_sum[$i]}'\t= '${arr_devName_sum[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_devType_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devType_sum[$i]}'\t= '${arr_devType_sum[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_devVendor_sum[@]} ; i++ )); do echo -e "$0: '$""{arr_devVendor_sum[$i]}'\t= '${arr_devVendor_sum[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_IOMMU_host[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_host[$i]}'\t= '${arr_IOMMU_host[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_IOMMU_host_VGA[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_host_VGA[$i]}'\t= '${arr_IOMMU_host_VGA[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_IOMMU_VFIO[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VFIO[$i]}'\t= '${arr_IOMMU_VFIO[$i]}'"; done && echo
                    for (( i=0 ; i<${#arr_IOMMU_VFIO_VGA[@]} ; i++ )); do echo -e "$0: '$""{arr_IOMMU_VFIO_VGA[$i]}'\t= '${arr_IOMMU_VFIO_VGA[$i]}'"; done && echo

                    echo -e "$0: '$""{#arr_devIndex_sum[@]}'\t= ${#arr_devIndex_sum[@]}"
                    echo -e "$0: '$""{#arr_devIOMMU_sum[@]}'\t= ${#arr_devIOMMU_sum[@]}"
                    echo -e "$0: '$""{#arr_devDriver_sum[@]}'\t= ${#arr_devDriver_sum[@]}"
                    echo -e "$0: '$""{#arr_devDriver_VFIO[@]}'\t= ${#arr_devDriver_VFIO[@]}"
                    echo -e "$0: '$""{#arr_devHWID_sum[@]}'\t= ${#arr_devHWID_sum[@]}"
                    echo -e "$0: '$""{#arr_devName_sum[@]}'\t= ${#arr_devName_sum[@]}"
                    echo -e "$0: '$""{#arr_devType_sum[@]}'\t= ${#arr_devType_sum[@]}"
                    echo -e "$0: '$""{#arr_devVendor_sum[@]}'\t= ${#arr_devVendor_sum[@]}"
                    echo -e "$0: '$""{#arr_IOMMU_host[@]}'\t= ${#arr_IOMMU_host[@]}"
                    echo -e "$0: '$""{#arr_IOMMU_VFIO[@]}'\t= ${#arr_IOMMU_VFIO[@]}"
                    echo -e "$0: '$""{#arr_IOMMU_host_VGA[@]}'\t= ${#arr_IOMMU_host_VGA[@]}"
                    echo -e "$0: '$""{#arr_IOMMU_VFIO_VGA[@]}'\t= ${#arr_IOMMU_VFIO_VGA[@]}"
                    echo -e "$0: '$""str_devDriver_host_list'\t= $str_devDriver_host_list"
                    echo -e "$0: '$""str_devDriver_VFIO_list'\t= $str_devDriver_VFIO_list"
                    echo -e "$0: '$""str_devDriver_VFIO_VGA_list'\t= $str_devDriver_VFIO_VGA_list"
                    echo -e "$0: '$""str_devHWID_VFIO_list'\t= $str_devHWID_VFIO_list"
                    echo -e "$0: '$""str_devHWID_VFIO_VGA_list'\t= $str_devHWID_VFIO_VGA_list"

                    echo -e "\n$0: ========== DEBUG PROMPT =========="
                    exit 0
                }

            # DebugOutput    # uncomment to debug here

        # parameters #
            readonly str_rootDistro=`lsb_release -i -s`                                                 # Linux distro name
            declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n3`)     # first three kernels
            # str_rootKernel=`ls -1 /boot/vmli* | cut -d "z" -f 2 | sort -r | head -n1`                   # latest kernel
            # readonly str_rootKernel=${str_rootKernel: 1}
            readonly str_rootDisk=`df / | grep -iv 'filesystem' | cut -d '/' -f3 | cut -d ' ' -f1`
            readonly str_rootUUID=`blkid -s UUID | grep $str_rootDisk | cut -d '"' -f2`
            str_rootFSTYPE=`blkid -s TYPE | grep $str_rootDisk | cut -d '"' -f2`

            if [[ $str_rootFSTYPE == "ext4" || $str_rootFSTYPE == "ext3" ]]; then
                readonly str_rootFSTYPE="ext2"
            fi

            # files #
            readonly str_dir1=`find .. -name files`
            if [[ -e $str_dir1 ]]; then
                cd $str_dir1
            fi

            readonly str_inFile1=`find . -name *etc_grub.d_proxifiedScripts_custom`
            readonly str_inFile1b=`find . -name *Multi-boot_template`

            # comment to debug here #
            readonly str_outFile1="/etc/grub.d/proxifiedScripts/custom"

            # uncomment to debug here #
            # readonly str_outFile1="custom.log"
            readonly str_oldFile1="$str_outFile1.old"

            # debug prompt #
                # echo -e "$0: '$""str_IGPU_devFullName'\t\t= $str_IGPU_devFullName"
                # echo -e "$0: '$""str_rootDistro'\t\t= $str_rootDistro"
                # echo -e "$0: '$""str_rootKernel'\t\t= $str_rootKernel"
                # echo -e "$0: '$""{#arr_rootKernel[@]}'\t\t= ${#arr_rootKernel[@]}"
                # echo -e "$0: '$""str_rootDisk'\t\t= $str_rootDisk"
                # echo -e "$0: '$""str_rootUUID'\t\t= $str_rootUUID"
                # echo -e "$0: '$""str_rootFSTYPE'\t\t= $str_rootFSTYPE"
                # echo -e "$0: '$""str_inFile1'\t\t= $str_inFile1"
                # echo -e "$0: '$""str_inFile1b'\t\t= $str_inFile1b"
                # echo -e "$0: '$""str_outFile1'\t\t= $str_outFile1"
                # echo -e "$0: '$""str_oldFile1'\t\t= $str_oldFile1"
                # echo -e "$0: '$""str_logFile0'\t\t= $str_logFile0"
                # echo -e "$0: '$""{#arr_IOMMU_VFIO_VGA[@]}'\t\t= ${#arr_IOMMU_VFIO_VGA[@]}"
                # echo

            # create logfile #
            if [[ -e $str_logFile0 ]]; then
                rm $str_logFile0
            else
                touch $str_logFile0
            fi

            # create backup #
            if [[ -e $str_outFile1 ]]; then
                mv $str_outFile1 $str_oldFile1
            fi

            # restore backup #
            if [[ -e $str_inFile1 ]]; then
                cp $str_inFile1 $str_outFile1
            fi

        # generate output for system files #
            for int_IOMMU_VFIO_VGA in ${arr_IOMMU_VFIO_VGA[@]}; do

                # reset parameters #
                declare -a arr_GRUB_title=()
                str_devFullName_VGA="N/A"
                str_devDriver_VFIO_VGA_list=""
                str_devHWID_STUB_VGA_list=""
                str_devHWID_VFIO_VGA_list=""
                str_GRUB_CMDLINE=""

                for int_IOMMU_VFIO in ${arr_IOMMU_VFIO_VGA[@]}; do
                    for (( int_i=0 ; int_i<${#arr_devIndex_sum[@]} ; int_i++ )); do
                        int_thisIOMMU=${arr_devIOMMU_sum[$int_i]}
                        str_thisDevDriver=${arr_devDriver_sum[$int_i]}
                        str_thisDevHWID=${arr_devHWID_sum[$int_i]}
                        str_thisDevName=${arr_devName_sum[$int_i]}
                        str_thisDevType=`echo ${arr_devType_sum[$int_i]} | tr '[:lower:]' '[:upper:]'`
                        str_thisDevVendor=${arr_devVendor_sum[$int_i]}

                        # match IOMMU, false match VGA IOMMU and false match existing element in list #
                        if [[ "$int_thisIOMMU" == "$int_IOMMU_VFIO" && $int_IOMMU_VFIO != $int_IOMMU_VFIO_VGA && $str_devHWID_VFIO_list != *$str_thisDevHWID* ]]; then

                            if [[ $str_devHWID_VFIO_list != *$str_thisDevHWID* ]]; then

                                # bind to pci-stub #
                                if [[ $str_thisDevType == *"USB"* ]]; then
                                    str_devHWID_STUB_VGA_list+="$str_thisDevHWID,"

                                # bind to vfio-pci #
                                else
                                    str_devHWID_VFIO_VGA_list+="$str_thisDevHWID,"
                                fi
                            fi

                            # valid driver and false match existing element in list(s) #
                            if [[ $str_devDriver_VFIO_list != *$str_thisDevDriver* && $str_thisDevDriver != *"N/A"* && $str_devDriver_host_list != *$str_thisDevDriver* && $str_devDriver_VFIO_list != *$str_devDriver_host_list* ]]; then
                                str_devDriver_VFIO_VGA_list+="$str_thisDevDriver,"
                            fi
                        fi
                    done
                done

                for (( int_i=0 ; int_i<${#arr_devIndex_sum[@]} ; int_i++ )); do
                    int_thisIOMMU=${arr_devIOMMU_sum[$int_i]}
                    str_thisDevDriver=${arr_devDriver_sum[$int_i]}
                    str_thisDevHWID=${arr_devHWID_sum[$int_i]}
                    str_thisDevName=${arr_devName_sum[$int_i]}
                    str_thisDevType=`echo ${arr_devType_sum[$int_i]} | tr '[:lower:]' '[:upper:]'`
                    str_thisDevVendor=${arr_devVendor_sum[$int_i]}

                    # match IOMMU #
                    if [[ $int_thisIOMMU == $int_IOMMU_VFIO_VGA && $str_thisDevType == *"VGA"* || $str_thisDevType == *"GRAPHICS"* ]]; then
                        str_devFullName_VGA="$str_thisDevVendor $str_thisDevName"
                        break;
                    fi
                done

                # update parameters #
                str_devDriver_VFIO_thisList=${str_devDriver_VFIO_list}${str_devDriver_VFIO_VGA_list}
                str_devHWID_STUB_thisList=${str_devHWID_STUB_list}${str_devHWID_STUB_VGA_list}
                str_devHWID_VFIO_thislist=${str_devHWID_VFIO_list}${str_devHWID_VFIO_VGA_list}

                # remove last separator #
                if [[ ${str_devDriver_VFIO_thisList: -1} == "," ]]; then
                    str_devDriver_VFIO_thisList=${str_devDriver_VFIO_thisList::-1}
                fi

                if [[ ${str_devHWID_STUB_thisList: -1} == "," ]]; then
                    str_devHWID_STUB_thisList=${str_devHWID_STUB_thisList::-1}
                fi

                if [[ ${str_devHWID_VFIO_thislist: -1} == "," ]]; then
                    str_devHWID_VFIO_thislist=${str_devHWID_VFIO_thislist::-1}
                fi

                # Write to file #
                    # new parameters #
                    if [[ $str_IGPU_devFullName != "N/A" ]]; then
                        str_devFullName_VGA=$str_IGPU_devFullName
                    fi

                    # NOTE: change here #
                    str_GRUB_CMDLINE="${str_GRUB_CMDLINE_prefix} modprobe.blacklist=${str_devDriver_VFIO_thisList} pci-stub.ids=${str_devHWID_STUB_thisList} vfio_pci.ids=${str_devHWID_VFIO_thislist}"

                    ## log file ##
                        echo -e "#$int_IOMMU_VFIO_VGA #$str_devFullName_VGA #${str_GRUB_CMDLINE}" >> $str_logFile0

                    ## /etc/grub.d/proxifiedScripts/custom ##

                        # parse kernels #
                        for (( int_i=0 ; int_i<${#arr_rootKernel[@]} ; int_i++)); do

                            # match #
                            if [[ -e ${arr_rootKernel[$int_i]} || ${arr_rootKernel[$int_i]} != "" ]]; then
                                str_thisRootKernel=${arr_rootKernel[$int_i]:1}

                                # new parameters #
                                str_output1='menuentry "'"`lsb_release -i -s` `uname -o`, with `uname` $str_thisRootKernel (VFIO, w/o IOMMU '$int_IOMMU_VFIO_VGA', w/ boot VGA '$str_devFullName_VGA'\") {"
                                str_output1_log="\n"'menuentry "'"`lsb_release -i -s` `uname -o`, with `uname` #kernel_'$int_i'# (VFIO, w/o IOMMU '$int_IOMMU_VFIO_VGA', w/ boot VGA '$str_devFullName_VGA'\") {"
                                str_output2="\tinsmod $str_rootFSTYPE"
                                str_output3="\tset root='/dev/disk/by-uuid/$str_rootUUID'"
                                str_output4="\t"'if [ x$feature_platform_search_hint = xy ]; then'"\n\t\t"'search --no-floppy --fs-uuid --set=root '"$str_rootUUID\n\t"'fi'
                                str_output5="\techo    'Loading Linux $str_thisRootKernel ...'"
                                str_output5_log="\techo    'Loading Linux #kernel'$int_i'# ...'"
                                str_output6="\tlinux   /boot/vmlinuz-$str_thisRootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                                str_output6_log="\tlinux   /boot/vmlinuz-#kernel'$int_i'# root=UUID=$str_rootUUID $str_GRUB_CMDLINE"
                                str_output7="\tinitrd  /boot/initrd.img-$str_thisRootKernel"
                                str_output7_log="\tinitrd  /boot/initrd.img-"'#kernel'$int_i'#'

                                # debug prompt #
                                # echo -e "$0: '$""str_output0'\t\t= $str_output0"
                                # echo -e "$0: '$""str_output1'\t\t= $str_output1"
                                # echo -e "$0: '$""str_output2'\t\t= $str_output2"
                                # echo -e "$0: '$""str_output3'\t\t= $str_output3"
                                # echo -e "$0: '$""str_output4'\t\t= $str_output4"
                                # echo -e "$0: '$""str_output5'\t\t= $str_output5"
                                # echo -e "$0: '$""str_output6'\t\t= $str_output6"
                                # echo -e "$0: '$""str_output7'\t\t= $str_output7"
                                # echo

                                if [[ -e $str_inFile1 && -e $str_inFile1b ]]; then

                                    # write to tempfile #
                                    echo -e >> $str_outFile1

                                    while read -r str_line1; do
                                        case $str_line1 in

                                            *'#$str_output1'*)
                                                str_outLine1="$str_output1"
                                                str_logLine1="$str_output1_log";;

                                            *'#$str_output2'*)
                                                str_outLine1="$str_output2"
                                                str_logLine1="$str_output2";;

                                            *'#$str_output3'*)
                                                str_outLine1="$str_output3"
                                                str_logLine1="$str_output3";;

                                            *'#$str_output4'*)
                                                str_outLine1="$str_output4"
                                                str_logLine1="$str_output4";;

                                            *'#$str_output5'*)
                                                str_outLine1="$str_output5"
                                                str_logLine1="$str_output5_log";;

                                            *'#$str_output6'*)
                                                str_outLine1="$str_output6"
                                                str_logLine1="$str_output6_log";;

                                            *'#$str_output7'*)
                                                str_outLine1="$str_output7"
                                                str_logLine1="$str_output7_log";;

                                            *)
                                                str_outLine1="$str_line1"
                                                str_logLine1="$str_outLine1";;      # NOTE: do not change this line!
                                        esac

                                        # write to system file and logfile (post_install: update Multi-boot) #
                                        echo -e "$str_outLine1" >> $str_outFile1
                                        # echo -e "$str_logLine1" >> $str_logFile0
                                    done < $str_inFile1b        # read from template
                                else
                                    bool_missingFiles=true
                                fi
                            fi
                        done
            done

        # file check #
            if [[ $bool_missingFiles == true ]]; then
                echo -e "$0: File(s) missing:"

                if [[ -z $str_inFile1 ]]; then
                    echo -e "\t'$str_inFile1'"
                fi

                if [[ -z $str_inFile1b ]]; then
                    echo -e "\t'$str_inFile1b'"
                fi

                echo -e "$0: Executing Multi-boot setup... Failed."
                exit 0
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VFIO_VGA[@]} -ge 1 ]]; then
                echo -e "$0: Executing Multi-boot setup... Cancelled. No IOMMU groups (with VGA devices) selected."
                exit 0
            elif [[ ${#arr_IOMMU_VFIO[@]} -eq 0 && ${#arr_IOMMU_VFIO_VGA[@]} -eq 0 ]]; then
                echo -e "$0: Executing Multi-boot setup... Cancelled. No IOMMU groups selected."
                exit 0
            else
                chmod 755 $str_outFile1 $str_oldFile1                   # set proper permissions
                echo -e "$0: Executing Multi-boot setup... Complete."
            fi
    }

echo -e "$0: 'Multi-boot' is a flexible VFIO setup, adding multiple GRUB boot menu entries (each with one omitted IOMMU group with VGA).\n"

# prompt #
    declare -i int_count=0                  # reset counter

    while [[ $bool_devIsVFIO == false || -z $bool_devIsVFIO || $bool_missingFiles == false ]]; do

        if [[ $int_count -ge 3 ]]; then
            echo -e "$0: Exceeded max attempts."
            str_input1="N"                  # default selection
        else
            echo -en "$0: Deploy Multi-boot VFIO setup? [Y/n]: "
            read -r str_input1
            str_input1=$(echo $str_input1 | tr '[:lower:]' '[:upper:]')
            str_input1=${str_input1:0:1}
        fi

        case $str_input1 in
            "Y")
                echo
                MultiBootSetup $str_GRUB_CMDLINE_Hugepages $bool_dev_isVFIO
                echo
                sudo update-grub
                # sudo update-initramfs -u -k all
                echo -e "\n$0: Review changes:\n\t'$str_outFile1'"
                echo -e "$0: To update Multi-boot (kernel upgrade), execute updater. Updater will read from logfile '$str_logFile0'."
                break;;
            "N")
                IFS=$SAVEIFS                # reset IFS     # NOTE: necessary for newline preservation in arrays and files
                exit 0;;
            *)
                echo -e "$0: Invalid input. ";;
        esac

        ((int_count++))                     # increment counter
    done

    # warn user to delete existing setup and reboot to continue #
    if [[ $bool_devIsVFIO == true && $bool_missingFiles == false ]]; then
        echo -en "$0: Existing VFIO setup detected. "

        if [[ -e `find .. -name *uninstall.bash*` ]]; then
            echo -e "To continue, execute `find .. -name *uninstall.bash*` and reboot system."
        else
            echo -e "To continue, uninstall setup and reboot system."
        fi
    fi

    # warn user of missing files #
    if [[ $bool_missingFiles == true ]]; then
        echo -e "$0: Setup is not complete. Clone or re-download 'portellam/deploy-VFIO-setup' to continue."
    fi
IFS=$SAVEIFS        # reset IFS     # NOTE: necessary for newline preservation in arrays and files
exit 0