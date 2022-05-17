#!/bin/bash

########## README ##########

# Maintainer:   github/portellam
# TL;DR:        Generates a VFIO passthrough setup (Multi-Boot or Static).

# NOTES:
# when parsing LSPCI or lists, list all devices in the same IOMMU group, and ask user if they wish to passthrough all or none.
# otherwise, ask per device which the user wishes to passthrough

# TODO:
#   MultiBootSetup; menu entry
#   StaticSetup
#   hint/prompt user to install/execute Auto-Xorg.
#   setup input parameter passthrough
#   Virtual audio, Scream?
#   if VFIO setup already, suggest wipe of existing MultiBoot and/or StaticBoot
#

# DONE:
#   ParsePCI
#   Prompts   
#   Hugepages
#   ZRAM
#

########## functions ##########

##### Prompts #####
function Prompts {

    # call functions #
    Evdev                                   # 1
    HugePages $str_GRUB_CMDLINE_Hugepages   # 2
    ZRAM                                    # 3
    ParsePCI $bool_VFIO_Setup
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter

    str_prompt="$0: Setup VFIO by 'Multi-Boot' or Statically?\n\tMulti-Boot Setup includes adding GRUB boot options, each with one specific omitted VGA device.\n\tStatic Setup modifies '/etc/initramfs-tools/modules', '/etc/modules', and '/etc/modprobe.d/*.\n\tMulti-boot is the more flexible choice."

    if [[ -z $str_input1 ]]; then echo -e $str_prompt; fi

    while true; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
            break
        
        else

            echo -en "$0: Setup VFIO? [ (M)ulti-Boot / (S)tatic / (N)one ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "M")

                echo -e "$0: Continuing with Multi-Boot setup...\n"

                MultiBootSetup $bool_isVFIOsetup$str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID

                StaticSetup $bool_isVFIOsetup$str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID

                sudo update-grub                    # update GRUB
                sudo update-initramfs -u -k all     # update INITRAMFS

                echo -e "$0: NOTE: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"

                break;;

            "S")

                echo -e "$0: Continuing with Static setup...\n"

                StaticSetup $bool_isVFIOsetup$str_GRUB_CMDLINE_Hugepages $arr_PCIBusID $arr_PCIHWID $arr_PCIDriver $arr_PCIIndex $arr_PCIInfo $arr_VGABusID $arr_VGADriver $arr_VGAHWID

                sudo update-grub                    # update GRUB
                sudo update-initramfs -u -k all     # update INITRAMFS

                echo -e "$0: NOTE: Review changes in:\n\t'/etc/default/grub'\n\t'/etc/initramfs-tools/modules'\n\t'/etc/modules'\n\t/etc/modprobe.d/*"

                break;;

            "N")

                echo -e "$0: Skipping...\n";;
                exit 0

            *)

                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

}
##### end Prompts #####

##### Evdev #####
function Evdev {

    # parameters #
    str_file1="/etc/libvirt/qemu.conf"
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter
    
    str_prompt="$0: Evdev (Event Devices) is a method that assigns input devices to a Virtual KVM (Keyboard-Video-Mouse) switch.\n\tEvdev is recommended for setups without an external KVM switch and multiple USB controllers.\n\tNOTE: View '/etc/libvirt/qemu.conf' to review changes, and append to a Virtual machine's configuration file."

    echo -e $str_prompt

    while [[ $str_input1 != "Y" && $str_input1 != "Z" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        
        else

            echo -en "$0: Setup Evdev? [ Y/n ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y"|"E")
                #echo -e "$0: Continuing...\n"
                break;;

            "N")
                echo -e "$0: Skipping...\n"
                return 0;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

    # find first normal user
    str_UID1000=`cat /etc/passwd | grep 1000 | cut -d ":" -f 1`
    #

    # add to group
    declare -a arr_User=(`getent passwd {1000..60000} | cut -d ":" -f 1`)   # find all normal users
    for str_User in $arr_User; do sudo adduser $str_User libvirt; done      # add each normal user to libvirt group
    #

    # list of input devices
    declare -a arr_InputDeviceID=`ls /dev/input/by-id`
    #

    # file changes #
    declare -a arr_file_QEMU=("
#
# NOTE: Generated by 'Auto-vfio-pci.sh'
#
user = \"$str_UID1000\"
group = \"user\"
#
hugetlbfs_mount = \"/dev/hugepages\"
#
nvram = [
   \"/usr/share/OVMF/OVMF_CODE.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/OVMF/OVMF_CODE.secboot.fd:/usr/share/OVMF/OVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF_CODE.fd:/usr/share/AAVMF/AAVMF_VARS.fd\",
   \"/usr/share/AAVMF/AAVMF32_CODE.fd:/usr/share/AAVMF/AAVMF32_VARS.fd\"
]
#
cgroup_device_acl = [
")

    for str_InputDeviceID in $arr_InputDeviceID; do arr_file_QEMU+=("    \"/dev/input/by-id/$str_InputDeviceID\","); done

    arr_file_QEMU+=("    \"/dev/null\", \"/dev/full\", \"/dev/zero\",
    \"/dev/random\", \"/dev/urandom\",
    \"/dev/ptmx\", \"/dev/kvm\",
    \"/dev/rtc\", \"/dev/hpet\"
]
#")
    #

    # backup config file #
    if [[ -z $str_file1"_old" ]]; then cp $str_file1 $str_file1"_old"; fi
    if [[ ! -z $str_file1"_old" ]]; then cp $str_file1"_old" $str_file1; fi
    #

    # write to file #
    for str_line in ${arr_file_QEMU[@]}; do echo -e $str_line >> $str_file1; done
    #

    # restart service #
    systemctl enable libvirtd
    systemctl restart libvirtd
    #

}
##### end Evdev #####

##### HugePages #####
function HugePages {

    # parameters #
    str_GRUB_CMDLINE_Hugepages="default_hugepagesz=1G hugepagesz=1G hugepages=0"                # default output
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter

    str_prompt="$0: HugePages is a feature which statically allocates System Memory to pagefiles.\n\tVirtual machines can use HugePages to a peformance benefit.\n\tThe greater the Hugepage size, the less fragmentation of memory, the less memory latency.\n"

    echo -e $str_prompt

    while [[ $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        
        else

            echo -en "$0: Setup HugePages? [Y/n]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y"|"H")
                #echo -e "$0: Continuing...\n"
                break;;

            "N")
                echo -e "$0: Skipping Hugepages...\n"
                return 0;;

            *)
                echo -e "$0: Invalid input.\n";;

        esac
        ((int_count++))

    done
    #

    # Hugepage size: validate input #
    str_HugePageSize=$str6
    str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`

    declare -i int_count=0      # reset counter

    while true; do
                 
        # attempt #
        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_HugePageSize="1G"           # default selection
        
        else

            echo -en "$0: Enter Hugepage size and byte-size. [ 2M / 1G ]:\t"
            read -r str_HugePageSize
            str_HugePageSize=`echo $str_HugePageSize | tr '[:lower:]' '[:upper:]'`

        fi
        #

        # check input #
        case $str_HugePageSize in

            "2M")
                break;;

            "1G")
                break;;

            *)
                echo "$0: Invalid input.";;

        esac
        #

        ((int_count++))                     # inc counter

    done
    #

    # Hugepage sum: validate input #
    int_HugePageNum=$str7
    declare -i int_count=0      # reset counter

    while true; do

        # attempt #
        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            int_HugePageNum=$int_HugePageMax        # default selection
        
        else

            # Hugepage Size #
            if [[ $str_HugePageSize == "2M" ]]; then

                str_prefixMem="M"
                declare -i int_HugePageK=2048       # Hugepage size
                declare -i int_HugePageMin=2        # min HugePages

            fi

            if [[ $str_HugePageSize == "1G" ]]; then

                str_prefixMem="G"
                declare -i int_HugePageK=1048576    # Hugepage size
                declare -i int_HugePageMin=1        # min HugePages

            fi

            declare -i int_HostMemMinK=4194304                              # min host RAM in KiB
            declare -i int_HugePageMemMax=$int_HostMemMaxK-$int_HostMemMinK
            declare -i int_HugePageMax=$int_HugePageMemMax/$int_HugePageK   # max HugePages

            echo -en "$0: Enter number of HugePages ( num * $str_HugePageSize ). [ $int_HugePageMin to $int_HugePageMax pages ] : "
            read -r int_HugePageNum
            #

        fi
        #

    # check input #
    if [[ $int_HugePageNum -lt $int_HugePageMin || $int_HugePageNum -gt $int_HugePageMax ]]; then

        echo "$0: Invalid input."
        ((int_count++));     # inc counter

    else
    
        #echo -e "$0: Continuing..."
        str_GRUB_CMDLINE_Hugepages="default_hugepagesz=$str_HugePageSize hugepagesz=$str_HugePageSize hugepages=$int_HugePageNum"
        break
        
    fi
    #

    done
    #

}
##### end HugePages #####

##### MultiBootSetup #####
function MultiBootSetup {

    # match existing VFIO setup install, suggest uninstall or exit #
    while [[ $bool_isVFIOsetup== false ]]; do

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter
    str_prompt="$0: Do you wish to Review each VGA device to Passthrough or not (before creating a given GRUB menu entry)?"

    echo -e $str_prompt

    while [[ $str_input1 != "Y" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        
        else

            echo -en "$0: Review each VGA device? [Y/n]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y")
                #echo -e "$0: Continuing Multi-Boot setup manually...\n"
                break;;

            "N")
                #echo -e "$0: Continuing Multi-Boot setup automated...\n"
                break;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

    # dependencies # 
    declare -a arr_PCIBusID
    declare -a arr_PCIDriver
    declare -a arr_PCIHWID
    declare -a arr_VGABusID
    declare -a arr_VGADriver
    ParsePCI $arr_PCIBusID $arr_PCIDriver $arr_PCIHWID $arr_VGABusID $arr_VGADriver
    #

    ## parameters ##
    str_Distribution=`lsb_release -i`   # Linux distro name
    declare -i int_Distribution=${#str_Distribution}-16
    str_Distribution=${str_Distribution:16:int_Distribution}
    declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2`)                                # list of Kernels
    #

    # root Dev #
    str_rootDiskInfo=`df -hT | grep /$`
    #str_rootDev=${str_rootDiskInfo:5:4}     # example "sda1"
    str_rootDev=${str_rootDiskInfo:0:9}     # example "/dev/sda1"
    str_rootUUID=`sudo lsblk -n $str_rootDev -o UUID`
    #

    # custom GRUB #
    #str_file1="/etc/grub.d/proxifiedScripts/custom"
    str_file1="/etc/grub.d/40_custom"
    echo -e "#!/bin/sh\nexec tail -n +3 \$0\n# This file provides an easy way to add custom menu entries. Simply type the\n# menu entries you want to add after this comment. Be careful not to change\n# the 'exec tail' line above." > $str_file1
    #
    ##

    # list IOMMU groups #
    if [[ $str_input1 == "Y" ]]; then

        echo -e "$0: PCI devices may share IOMMU groups. IOMMU groups are the result of which PCI slots are populated and the PCI devices that populate them. given PCI devices.\n\tReview the output below before choosing which VGA devices to passthrough or not.\n$0: DISCLAIMER: Script does NOT add internal PCI devices (Bus IDs before 01:00.0) to VFIO passthrough.\n"
    
        for str_thisPCIBusID in ${arr_PCIBusID[@]}; do
    
            str_thisPCIDevice=`lspci -m | grep $str_thisPCIBusID | cut -d '"' -f 6`
            str_thisPCIIOMMUInfo=`dmesg | grep "Adding to iommu group" | grep $str_thisPCIBusID | cut -d "]" -f 2`
            echo -e "\t$str_thisPCIIOMMUInfo:\t$str_thisPCIDevice"

        done

        echo -e "\n$0: NOTE: PCI 16x slot devices may share IOMMU groups.\n\tFor example, in the past, multiple-GPU setups (NVIDIA SLI or AMD CrossFire), designate the first two or more 16x slots for said setup, thus a shared IOMMU group.\n$0: NOTE: Internal PCI devices, such as USB controllers may ('or may NOT') share IOMMU groups with other internal devices.\n"
    
    fi
    #

    ## parse GRUB menu entries ##
    declare -i int_lastIndexPCI=${#arr_PCIBusID[@]}-1
    declare -i int_lastIndexVGA=${#arr_VGABusID[@]}-1
    
    # parse list of VGA devices #
    for (( int_indexVGA=0; int_indexVGA<${#arr_VGABusID[@]}; int_indexVGA++ )); do

        bool_parsePCIifExternal=false
        bool_parseEnd=false
        str_thisVGABusID=${arr_VGABusID[$int_indexVGA]}                         # save for match
        str_thisVGADriver=${arr_VGADriver[$int_indexVGA]}                       # save for GRUB
        str_thisVGADevice=`lspci -m | grep $str_thisVGABusID | cut -d '"' -f 6`
        str_thisVGAIOMMUID=`dmesg | grep "Adding to iommu group" | grep $str_thisVGABusID | cut -d " " -f 12`
        str_listPCIDriver=""
        str_listPCIHWID=""

        #
        if [[ $str_input1 == "Y" ]]; then

            # prompt #
            declare -i int_count=0      # reset counter
            echo -e "\t" && lspci -m | grep $str_thisVGABusID

            while [[ $str_input2 != "Y" && $str_input2 != "N" ]]; do

                if [[ $int_count -ge 3 ]]; then

                    echo "$0: Exceeded max attempts."
                    str_input2="N"                   # default selection
        
                else

                    echo -en "$0: Do you wish to passthrough this VGA device (or not)? [Y/n]: "
                    read -r str_input2
                    str_input2=`echo $str_input2 | tr '[:lower:]' '[:upper:]'`

                fi

                case $str_input2 in

                    "Y")
                        #echo "$0: Passing-through VGA device..."
                        break;;

                    "N")
                        echo -e "$0: Omitting VGA device...\n"
                        break;;

                    *)
                        echo "$0: Invalid input.";;

                esac
                ((int_count++))

            done
            #
        fi
        #

        # default choice: if NOT passing-through device, run loop #
        if [[ $str_input2 != "Y" ]]; then

            # parse list of PCI devices #
            for (( int_indexPCI=0; int_indexPCI<${#arr_PCIBusID[@]}; int_indexPCI++ )); do

                str_thisPCIBusID=${arr_PCIBusID[$int_indexPCI]}         # save for match
                str_thisPCIDriver=${arr_PCIDriver[$int_indexPCI]}       # save for GRUB
                str_thisPCIHWID=${arr_PCIHWID[$int_indexPCI]}           # save for GRUB
                str_thisPCIIOMMUID=`dmesg | grep "Adding to iommu group" | grep $str_thisPCIBusID | cut -d " " -f 12`

                # if PCI is an expansion device, parse it #
                if [[ $str_thisPCIBusID == "01:00.0" ]]; then bool_parsePCIifExternal=true; fi
                #

                # match VGA device's child interface, save driver #
                if [[ ${str_thisVGABusID:0:5} == ${str_thisPCIBusID:0:5} && $str_thisVGABusID != $str_thisPCIBusID ]]; then str_thisVGAChildDriver=$str_thisPCIDriver; fi
                #

                # match Bus ID or IOMMU ID, clear vars #
                # NOTE: if device shares same IOMMU group as Xorg VGA device, then it is not possible to (without loss of security), to seperate device from the group.
                if [[ $str_thisVGABusID == $str_thisPCIBusID || $str_thisVGAIOMMUID == $str_thisPCIIOMMUID ]]; then
                    
                    # clear variables #
                    str_thisPCIDriver=""
                    str_thisPCIHWID=""
                    #

                fi
                #
                

                # match driver and false match partial Bus ID, clear driver #
                if [[ $str_thisVGABusID != $str_thisPCIBusID && $str_thisVGADriver == $str_thisPCIDriver ]]; then str_thisPCIDriver=""; fi
                #

                # partial match Bus ID, clear PCI child driver #
                # OR match VGA driver, clear driver #
                # OR match PCI driver in list, clear driver #
                if [[ ${str_thisVGABusID:0:5} == ${str_thisPCIBusID:0:5} || $str_thisPCIDriver == $str_thisVGAChildDriver || $str_listPCIDriver == *"$str_thisPCIDriver"* ]]; then

                    str_thisPCIDriver=""
                    
                fi
                #

                # if no PCI driver match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIDriver ]]; then str_listPCIDriver+="$str_thisPCIDriver,"; fi
                #
                
                # if no PCI HW ID match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIHWID ]]; then str_listPCIHWID+="$str_thisPCIHWID,"; fi
                #

            done  
            # end parse list of PCI devices #

            # remove last separator #
            if [[ ${str_listPCIDriver: -1} == "," ]]; then str_listPCIDriver=${str_listPCIDriver::-1}; fi
            if [[ ${str_listPCIHWID: -1} == "," ]]; then str_listPCIHWID=${str_listPCIHWID::-1}; fi
            #
  
            # GRUB command line #
            str_GRUB_CMDLINE="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_listPCIDriver vfio_pci.ids=$str_listPCIHWID"

            ### setup Boot menu entry ###           # TODO: fix automated menu entry setup!

            # MANUAL setup Boot menu entry #        # NOTE: temporary
            echo -e "$0: Execute GRUB Customizer, Clone an existing, valid menu entry, Copy the fields 'Title' and 'Entry' below, and Paste the following output into a new menu entry, where appropriate.\n$0: DISCLAIMER: Automated GRUB menu entry feature not available yet."

            # parse Kernels #
            for str_rootKernel in ${arr_rootKernel[@]}; do

                # set Kernel #
                str_rootKernel=${str_rootKernel:1:100}          # arbitrary length
                #echo "str_rootKernel == '$str_rootKernel'"
                #

                # GRUB Menu Title #
                str_GRUBMenuTitle="$str_Distribution `uname -o`, with `uname` $str_rootKernel"
                if [[ ! -z $str_thisVGADevice ]]; then
                    str_GRUBMenuTitle+=" (Xorg: $str_thisVGADevice)'"
                fi
                #

                # MANUAL setup Boot menu entry #        # NOTE: temporary
                echo -e "\n\tTitle: '$str_GRUBMenuTitle'\n\tEntry: '$str_GRUB_CMDLINE'\n"
                #

                # GRUB custom menu #
                declare -a arr_file_customGRUB=(
"menuentry '$str_GRUBMenuTitle' {
    load_video
    insmod gzio
    if [ x\$grub_platform = xxen ]; then insmod xzio; insmod lzopio; fi
	insmod part_gpt
	insmod ext2
    set root='hd2,gpt4'
    set root='/dev/disk/by-uuid/$str_rootUUID'
    if [ x$feature_platform_search_hint = xy ]; then
	  search --no-floppy --fs-uuid --set=root --hint-bios=hd2,gpt4 --hint-efi=hd2,gpt4 --hint-baremetal=ahci2,gpt4  $str_rootUUID
	else
	  search --no-floppy --fs-uuid --set=root $str_rootUUID
	fi
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel

}
"
                )

                # write to file
                #echo -e >> $str_file1    

                #for str_line in ${arr_file_customGRUB[@]}; do
                    #echo -e $str_line >> $str_file1            # TODO: fix GRUB menu entries!
                    #echo -e $str_line
                #done
                
                #echo -e >> $str_file1 
                #

            done
            #

            ## setup final GRUB entry with all PCI devices passed-through (for headless setup) ##
            str_listPCIDriver=""
            str_listPCIHWID=""

            # parse list of PCI devices #
            for (( int_indexPCI=0; int_indexPCI<${#arr_PCIBusID[@]}; int_indexPCI++ )); do

                str_thisPCIBusID=${arr_PCIBusID[$int_indexPCI]}         # save for match
                str_thisPCIDriver=${arr_PCIDriver[$int_indexPCI]}       # save for GRUB
                str_thisPCIHWID=${arr_PCIHWID[$int_indexPCI]}           # save for GRUB    

                # if PCI is an expansion device, parse it #
                if [[ $str_thisPCIBusID == "01:00.0" ]]; then bool_parsePCIifExternal=true; fi
                #

                # if PCI driver is already present in list, clear driver #
                if [[ $str_listPCIDriver == *"$str_thisPCIDriver"* ]]; then str_thisPCIDriver=""; fi
                #

                # if no PCI driver match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIDriver ]]; then str_listPCIDriver+="$str_thisPCIDriver,"; fi
                #
                
                # if no PCI HW ID match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIHWID ]]; then str_listPCIHWID+="$str_thisPCIHWID,"; fi
                #

            done  
            # end parse list of PCI devices #

            # remove last separator #
            if [[ ${str_listPCIDriver: -1} == "," ]]; then str_listPCIDriver=${str_listPCIDriver::-1}; fi
            if [[ ${str_listPCIHWID: -1} == "," ]]; then str_listPCIHWID=${str_listPCIHWID::-1}; fi
            #

            # GRUB command line #
            str_GRUB_CMDLINE="acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_listPCIDriver vfio_pci.ids=$str_listPCIHWID"
            #

            # parse Kernels #
            for str_rootKernel in ${arr_rootKernel[@]}; do

                # set Kernel #
                str_rootKernel=${str_rootKernel:1:100}          # arbitrary length
                #

                # GRUB Menu Title #
                str_GRUBMenuTitle="$str_Distribution `uname -o`, with `uname` $str_rootKernel (Xorg: N/A)"
                #

                # GRUB custom menu #
                declare -a arr_file_customGRUB=(
"menuentry '$str_GRUBMenuTitle' {
    insmod gzio
    set root='/dev/disk/by-uuid/$str_rootUUID'
    echo    'Loading Linux $str_rootKernel ...'
    linux   /boot/vmlinuz-$str_rootKernel root=UUID=$str_rootUUID $str_GRUB_CMDLINE
    echo    'Loading initial ramdisk ...'
    initrd  /boot/initrd.img-$str_rootKernel
}"
            )

                # write to file
                #echo -e "\n" >> $str_file1    

                #for str_line in ${arr_file_customGRUB[@]}; do
                    #echo -e $str_line >> $str_file1               # TODO: fix GRUB menu entries!
                    #echo -e $str_line
                #done
                #
            done
            ##

            if [[ $str_input2 == "N" ]]; then str_input2=""; fi    # reset input

        fi
        #
    done
    # end parse list of VGA devices #
    ## end parse GRUB menu entries ##

    #sudo update-grub    # update GRUB for good measure     # TODO: reenable when automated setup is fixed!

    done
    #

}
##### end MultiBootSetup #####

##### ParsePCI #####
function ParsePCI {

    # match existing VFIO setup install, suggest uninstall or exit #
    while [[ $bool_isVFIOsetup== false ]]; do
 
    ## parsed lists ##
    # NOTE: all parsed lists should be same size/length, for easy recall

    declare -a arr_PCI_BusID=(`lspci -m | cut -d '"' -f 1`)       # ex '01:00.0'
    declare -a arr_PCI_DeviceName=(`lspci -m | cut -d '"' -f 6`)  # ex 'GP104 [GeForce GTX 1070]''
    declare -a arr_PCI_HW_ID=(`lspci -n | cut -d ' ' -f 3`)       # ex '10de:1b81'
    declare -a arr_PCI_IOMMU_ID
    declare -a arr_PCI_Type=(`lspci -m | cut -d '"' -f 2`)        # ex 'VGA compatible controller'
    declare -a arr_PCI_VendorName=(`lspci -m | cut -d '"' -f 4`)  # ex 'NVIDIA Corporation'

    # add empty values to pad out and make it easier for parse/recall
    declare -a arr_PCI_Driver                                   # ex 'nouveau' or 'nvidia'

    ##

    # unparsed list #
    declare -a arr_lspci_k=(`lspci -k | grep -Eiv 'DeviceName|Subsystem|modules'`)
    declare -a arr_compgen_G=(`compgen -G "/sys/kernel/iommu_groups/*/devices/*"`)

    ## parse IOMMU ##
    # parse list of Bus IDs #
    for (( int_i=0; int_i<${#arr_PCI_BusID[@]}; int_i++ )); do

        # reformat element
        arr_PCI_BusID[$int_i]=${arr_PCI_BusID[$int_i]::-1}

        # parse list of output (Bus IDs and IOMMU IDs) #
        for (( int_j=0; int_j<${#arr_compgen_G[@]}; int_j++ )); do

            # match output with Bus ID #
            # true, save IOMMU ID at given index, exit loop #
            if [[ ${arr_compgen_G[$int_j]} == *"${arr_PCI_BusID[$int_i]}"* ]]; then

                arr_PCI_IOMMU_ID[$int_i]=`echo ${arr_compgen_G[$int_j]} | cut -d '/' -f 5`
                declare -i int_j=${#arr_compgen_G}

            fi
            #

        done
        #

    done
    ##

    ## parse drivers ##
    # parse list of output (Bus IDs and drivers #
    for (( int_i=0; int_i<${#arr_lspci_k[@]}; int_i++ )); do

        str_line1=${arr_lspci_k[$int_i]}                                    # current line
        str_PCI_BusID=`echo $str_line1 | grep -Eiv 'driver'`                # valid element
        str_PCI_Driver=`echo $str_line1 | grep 'driver' | cut -d ' ' -f 5`  # valid element

        # driver is NOT null and Bus ID is null #
        # add to list 
        if [[ -z $str_PCI_BusID && ! -z $str_PCI_Driver && $str_PCI_Driver != 'vfio-pci' ]]; then

            arr_PCI_Driver+=("$str_PCI_Driver")
            
        fi
        #

        # stop setup # 
        if [[ $str_PCI_Driver == 'vfio-pci' ]]; then

            #arr_PCI_Driver+=("")
            bool_VFIO_Setup=true

        fi
        #

    done
    ##
    done
    #

}

function ParsePCI_old {

    ## parameters ##

    # inputs #
    #declare -a arr_PCIBusID
    #declare -a arr_PCIDriver
    #declare -a arr_PCIHWID
    #declare -a arr_VGABusID
    #declare -a arr_VGADriver
    #declare -a arr_VGAHWID
    #
    
    bool_parseA=false
    bool_parseB=false
    bool_parseVGA=false

    # set file #
    declare -a arr_lspci_k=(`lspci -k`)
    declare -a arr_lspci_m=(`lspci -m`)
    declare -a arr_lspci_n=(`lspci -n`)
    str_file2="/etc/X11/xorg.conf.d/10-Auto-Xorg.conf"
    #
    ##

    # parse list of PCI #
    for (( int_indexA=0; int_indexA<${#arr_lspci_m[@]}; int_indexA++ )); do

        str_line1=${arr_lspci_m[$int_indexA]}    # element
        str_line3=${arr_lspci_n[$int_indexA]}    # element

        # begin parse #
        if [[ $str_line1 == *"01:00.0"* ]]; then bool_parseA=true; fi
        #

        # parse #
        if [[ $bool_parseA == true ]]; then

            # PCI info #
            str_thisPCIBusID=(${str_line1:0:7})                     # raw VGA Bus ID
            str_thisPCIType=`echo $str_line1 | cut -d '"' -f 2`     # example:  VGA
            str_thisPCIVendor=`echo $str_line1 | cut -d '"' -f 4`   # example:  NVIDIA
            str_thisPCIHWID=`echo $str_line3 | cut -d " " -f 3`     # example:  AB12:CD34
            #

            # add to list
            arr_PCIBusID+=("$str_thisPCIBusID")
            arr_PCIHWID+=("$str_thisPCIHWID") 
            #

            # match VGA device, add to list #
            if [[ $str_thisPCIType == *"VGA"* ]]; then
                arr_VGABusID+=("$str_thisPCIBusID")
                arr_VGAHWID+=("$str_thisPCIHWID")
            fi
            #

            # parse list of drivers
            declare -i int_indexB=0

            for (( int_indexB=0; int_indexB<${#arr_lspci_k[@]}; int_indexB++ )); do
            
                str_line2=${arr_lspci_k[$int_indexB]}    # element   

                # begin parse #
                if [[ $str_line2 == *"$str_thisPCIBusID"* ]]; then bool_parseB=true; fi
                #

                # match VGA #
                if [[ $bool_parseB == true && $str_line2 == *"VGA"* ]]; then
                    bool_parseVGA=true
                fi
                #

                # match driver #
                if [[ $bool_parseB == true && $str_line2 == *"Kernel driver in use: "* && $str_line2 != *"vfio-pci"* && $str_line2 != *"Subsystem: "* && $str_line2 != *"Kernel modules: "* ]]; then
                
                    str_thisPCIDriver=`echo $str_line2 | cut -d " " -f 5`   # PCI driver
                    arr_PCIDriver+=("$str_thisPCIDriver")                   # add to list

                    # match VGA, add to list #
                    if [[ $bool_parseVGA == true ]]; then
                        arr_VGADriver+=("$str_thisPCIDriver")
                    fi

                    bool_parseB=false
                    bool_parseVGA=false         
                fi
                #

                str_prevLine2=$str_line2    # save previous line for comparison

            done
            #
        fi
        #

        str_prevLine1=$str_line1            # save previous line for comparison

    done
    #

    echo -e                                 # newline

    # Debug
    function DEBUG {

        echo -e "$0: arr_PCIBusID == ${#arr_PCIBusID[@]}i"
        for element in ${arr_PCIBusID[@]}; do
            echo -e "$0: arr_PCIBusID == "$element
        done

        echo -e "$0: arr_VGABusID == ${#arr_VGABusID[@]}i"
        for element in ${arr_VGABusID[@]}; do
            echo -e "$0: arr_VGABusID == "$element
        done

        echo -e "$0: arr_PCIDriver == ${#arr_PCIDriver[@]}i"
        for element in ${arr_PCIDriver[@]}; do
            echo -e "$0: arr_PCIDriver == "$element
        done

        echo -e "$0: arr_VGADriver == ${#arr_VGADriver[@]}i"
        for element in ${arr_VGADriver[@]}; do
            echo -e "$0: arr_VGADriver == "$element
        done

        echo -e "$0: arr_PCIHWID == ${#arr_PCIHWID[@]}i"
        for element in ${arr_PCIHWID[@]}; do
            echo -e "$0: arr_PCIHWID == "$element
        done

        echo -e "$0: arr_VGAHWID == ${#arr_VGAHWID[@]}i"
        for element in ${arr_VGAHWID[@]}; do
            echo -e "$0: arr_VGAHWID == "$element
        done

    }
    #DEBUG
    #

}
##### end ParsePCI #####

##### StaticSetup #####
# NOTES:
# make sure StaticSetup checks if MultiBootSetup ran. If true, create Static configs with only non-VGA and non-VGA-vendor devices.
# otherwise, ask user which VGA device to leave as Host VGA device

function StaticSetup {

    # match existing VFIO setup install, suggest uninstall or exit #
    while [[ $bool_isVFIOsetup== false ]]; do

    ## parameters ##
    declare -a arr_listPCIDriver
    declare -a arr_listPCIHWID

    # dependencies # 
    declare -a arr_PCIBusID
    declare -a arr_PCIDriver
    declare -a arr_PCIHWID
    declare -a arr_VGABusID
    declare -a arr_VGADriver
    ParsePCI $arr_PCIBusID $arr_PCIDriver $arr_PCIHWID $arr_VGABusID $arr_VGADriver
    #

    # files #
    str_file1="/etc/default/grub"
    str_file2="/etc/initramfs-tools/modules"
    str_file3="/etc/modules"
    str_file4="/etc/modprobe.d/vfio.conf"
    #
    ##
    
    # list IOMMU groups #
    echo -e "$0: PCI devices may share IOMMU groups. IOMMU groups are the result of which PCI slots are populated and the PCI devices that populate them. given PCI devices.\n\tReview the output below before choosing which VGA devices to passthrough or not.\n$0: DISCLAIMER: Script does NOT add internal PCI devices (Bus IDs before 01:00.0) to VFIO passthrough.\n"
    
    for str_thisPCIBusID in ${arr_PCIBusID[@]}; do
    
        str_thisPCIDevice=`lspci -m | grep $str_thisPCIBusID | cut -d '"' -f 6`
        str_thisPCIIOMMUInfo=`sudo dmesg | grep "Adding to iommu group" | grep $str_thisPCIBusID | cut -d "]" -f 2`
        echo -e "\t$str_thisPCIDevice:$str_thisPCIIOMMUID"

    done

    echo -e "\n$0: NOTE: PCI 16x slot devices may share IOMMU groups.\n\tFor example, in the past, multiple-GPU setups (NVIDIA SLI or AMD CrossFire), designate the first two or more 16x slots for said setup, thus a shared IOMMU group.\n$0: NOTE: Internal PCI devices, such as USB controllers may ('or may NOT') share IOMMU groups with other internal devices.\n"
    #

    ## parse GRUB menu entries ##
    str_input1=""               # reset input
    declare -i int_lastIndexPCI=${#arr_PCIBusID[@]}-1
    declare -i int_lastIndexVGA=${#arr_VGABusID[@]}-1
    
    # parse list of VGA devices #
    for (( int_indexVGA=0; int_indexVGA<${#arr_VGABusID[@]}; int_indexVGA++ )); do

        bool_parsePCIifExternal=false
        bool_parseEnd=false
        str_thisVGABusID=${arr_VGABusID[$int_indexVGA]}                         # save for match
        str_thisVGADriver=${arr_VGADriver[$int_indexVGA]}                       # save for GRUB
        str_thisVGADevice=`lspci -m | grep $str_thisVGABusID | cut -d '"' -f 6`
        str_thisVGAIOMMUID=`dmesg | grep "Adding to iommu group" | grep $str_thisVGABusID | cut -d " " -f 12`
        str_listPCIDriver=""
        str_listPCIHWID=""

        # prompt #
        declare -i int_count=0      # reset counter
        echo -en "$0: " && lspci -m | grep $str_thisVGABusID

        while [[ $str_input1 != "Y" && $str_input1 != "N" ]]; do

            if [[ $int_count -ge 3 ]]; then

                echo "$0: Exceeded max attempts."
                str_input2="N"                      # default selection
        
            else

                echo -en "$0: Do you wish to passthrough this VGA device (or not)? [Y/n]: "
                read -r str_input1
                str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

            fi

            case $str_input1 in

                "Y")
                        echo "$0: Passing-through VGA device..."
                        break;;

                "N")
                        echo "$0: Omitting VGA device..."
                        break;;

                *)
                        echo "$0: Invalid input.";;

            esac
            ((int_count++))

        done
        #

        # default choice: if NOT passing-through device, run loop #
        if [[ $str_input1 != "Y" ]]; then

            # parse list of PCI devices #
            for (( int_indexPCI=0; int_indexPCI<${#arr_PCIBusID[@]}; int_indexPCI++ )); do

                str_thisPCIBusID=${arr_PCIBusID[$int_indexPCI]}         # save for match
                str_thisPCIDevice=`lspci -m | grep $str_thisPCIBusID | cut -d '"' -f 6`
                str_thisPCIDriver=${arr_PCIDriver[$int_indexPCI]}       # save for GRUB
                str_thisPCIHWID=${arr_PCIHWID[$int_indexPCI]}           # save for GRUB
                str_thisPCIIOMMUID=`dmesg | grep "Adding to iommu group" | grep $str_thisPCIBusID | cut -d " " -f 12`

                # if PCI is an expansion device, parse it #
                if [[ $str_thisPCIBusID == "01:00.0" ]]; then bool_parsePCIifExternal=true; fi
                #

                # match VGA device's child interface, save driver #
                if [[ ${str_thisVGABusID:0:5} == ${str_thisPCIBusID:0:5} && $str_thisVGABusID != $str_thisPCIBusID ]]; then str_thisVGAChildDriver=$str_thisPCIDriver; fi
                #

                # match Bus ID or IOMMU ID, clear vars #
                # NOTE: if device shares same IOMMU group as Xorg VGA device, then it is not possible to (without loss of security), to seperate device from the group.
                if [[ $str_thisVGABusID == $str_thisPCIBusID || $str_thisVGAIOMMUID == $str_thisPCIIOMMUID ]]; then
                    
                    # clear variables #
                    str_thisPCIDriver=""
                    str_thisPCIHWID=""
                    #

                    echo -e "$0: Device $str_thisPCIDevice shares IOMMU group with $str_thisVGADevice. Skipping..."

                fi
                #
                

                # match driver and false match partial Bus ID, clear driver #
                if [[ $str_thisVGABusID != $str_thisPCIBusID && $str_thisVGADriver == $str_thisPCIDriver ]]; then str_thisPCIDriver=""; fi
                #

                # partial match Bus ID, clear PCI child driver #
                # OR match VGA driver, clear driver #
                # OR match PCI driver in list, clear driver #
                if [[ ${str_thisVGABusID:0:5} == ${str_thisPCIBusID:0:5} || $str_thisPCIDriver == $str_thisVGAChildDriver || $str_listPCIDriver == *"$str_thisPCIDriver"* ]]; then
                
                    str_thisPCIDriver=""
                    
                fi
                #

                # if no PCI driver match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIDriver ]]; then
                    str_listPCIDriver+="$str_thisPCIDriver,"
                    arr_listPCIDriver+="$str_thisPCIDriver"
                fi
                #
                
                # if no PCI HW ID match found (if string is not empty), add to list #
                if [[ $bool_parsePCIifExternal == true && ! -z $str_thisPCIHWID ]]; then
                    str_listPCIHWID+="$str_thisPCIHWID,"
                    arr_listPCIHWID+="$str_thisPCIHWID"
                fi
                #

            done  
            # end parse list of PCI devices #

            # remove last separator #
            if [[ ${str_listPCIDriver: -1} == "," ]]; then str_listPCIDriver=${str_listPCIDriver::-1}; fi
            if [[ ${str_listPCIHWID: -1} == "," ]]; then str_listPCIHWID=${str_listPCIHWID::-1}; fi
            #

            if [[ $str_input2 == "N" ]]; then str_input2=""; fi    # reset input

        fi
        #
    done
    # end parse list of VGA devices #

    # VFIO soft dependencies #
    for str_thisPCIDriver in $arr_listPCIDriver; do
        str_listPCIDriver_softdep="softdep $str_thisPCIDriver pre: vfio-pci\n$str_thisPCIDriver"
    done
    #

    # GRUB #
    str_GRUB="GRUB_CMDLINE_DEFAULT=\"acpi=force apm=power_off iommu=1,pt amd_iommu=on intel_iommu=on rd.driver.pre=vfio-pci pcie_aspm=off kvm.ignore_msrs=1 $str_GRUB_CMDLINE_Hugepages modprobe.blacklist=$str_listPCIDriver vfio_pci.ids=$str_listPCIHWID\""
    echo -e "#\n${str_GRUB}" >> $str_file1
    #

    # initramfs-tools #
    declare -a arr_file2=(
"# List of modules that you want to include in your initramfs.
# They will be loaded at boot time in the order below.
#
# Syntax:  module_name [args ...]
#
# You must run update-initramfs(8) to effect this change.
#
# Examples:
#
# raid1
# sd_mod
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.

# Soft dependencies and PCI kernel drivers:
$str_listPCIDriver_softdep

vfio
vfio_iommu_type1
vfio_virqfd

# GRUB command line and PCI hardware IDs:
options vfio_pci ids=$str_listPCIHWID
vfio_pci ids=$str_listPCIHWID
vfio_pci"
)
    echo ${arr_file2[@]} > $str_file2
    #

    # modules #
    declare -a arr_file3=(
"# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with \"#\" are ignored.
#
# NOTE: GRUB command line is an easier and cleaner method if vfio-pci grabs all hardware.
# Example: Reboot hypervisor (Linux) to swap host graphics (Intel, AMD, NVIDIA) by use-case (AMD for Win XP, NVIDIA for Win 10).
# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
#
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
kvm
kvm_intel
apm power_off=1

# In terminal, execute \"lspci -nnk\".

# GRUB kernel parameters:
vfio_pci ids=$str_listPCIHWID"
)
    echo ${arr_file3[@]} > $str_file3
    #

    # modprobe.d/blacklists #
    for str_thisPCIDriver in $arr_listPCIDriver[@]; do
        echo "blacklist $str_thisPCIDriver" > "/etc/modprobe.d/$str_thisPCIDriver.conf"
    done
    #

    # modprobe.d/vfio.conf #
    declare -a arr_file4=(
"# NOTE: If you change this file, run 'update-initramfs -u -k all' afterwards to update.
# Soft dependencies:
$str_listPCIDriver_softdep

# PCI hardware IDs:
options vfio_pci ids=$str_listPCIHWID")
    echo ${arr_file4[@]} > $str_file4
    #

    done
    #

}
##### end StaticSetup #####

##### UninstallMultiBootSetup #####
function UninstallMultiBootSetup {


}
##### end UninstallMultiBootSetup #####

##### UninstallStaticSetup #####
function UninstallStaticSetup {

    str_file1="/etc/default/grub"
    str_file2="/etc/initramfs-tools/modules"
    str_file3="/etc/modules"
    str_dir1="/etc/modprobe.d/"

    # restore backups of files #

    # if a file in modprobe.d contains blacklist (not microcode, intel or amd), then delete/comment it #

    # run update-grub, initramfs #

}
##### end UninstallStaticSetup #####


##### ZRAM #####
function ZRAM {

    # parameters #
    str_file1="/etc/default/zramswap"
    str_file2="/etc/default/zram-swap"
    #

    # prompt #
    str_input1=""               # reset input
    declare -i int_count=0      # reset counter

    str_prompt="$0: ZRAM allocates RAM as a compressed swapfile.\n\tThe default compression method \"lz4\", at a ratio of 2:1 to 5:2, offers the greatest performance."

    echo -e $str_prompt
    str_input1=""

    while [[ $str_input1 != "Y" && $str_input1 != "Z" && $str_input1 != "N" ]]; do

        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"                   # default selection
        
        else

            echo -en "$0: Setup ZRAM? [ Y/n ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y"|"Z")
                #echo -e "$0: Continuing...\n"
                break;;

            "N")
                echo -e "$0: Skipping...\n"
                return 0;;

            *)
                echo "$0: Invalid input.";;

        esac
        ((int_count++))

    done
    #

    # parameters #
    int_HostMemMaxK=`cat /proc/meminfo | grep MemTotal | cut -d ":" -f 2 | cut -d "k" -f 1`     # sum of system RAM in KiB
    str_GitHub_Repo="FoundObjects/zram-swap"
    #

    # check for zram-utils #
    if [[ ! -z $str_file1 ]]; then

        apt install -y git zram-tools
        systemctl stop zramswap
        systemctl disable zramswap

    fi
    #

    # check for local repo #
    #if [[ ! -z "/root/git/$str_GitHub_Repo" ]]; then

        #cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`    
        #git pull https://www.github.com/$str_GitHub_Repo
    
    #fi

    if [[ -z "/root/git/$str_GitHub_Repo" ]]; then
    
        mkdir /root/git
        mkdir /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        cd /root/git/`echo $str_GitHub_Repo | cut -d '/' -f 1`
        git clone https://www.github.com/$str_GitHub_Repo

    fi
    #

    # check for zram-swap #
    if [[ -z $str_file2 ]]; then
        cd /root/git/$str_GitHub_Repo
        sh ./install.sh
    fi
    #

    # disable ZRAM swap #
    if [[ `sudo swapon -v | grep /dev/zram*` == "/dev/zram"* ]]; then sudo swapoff /dev/zram*; fi
    #
    
    # backup config file #
    if [[ -z $str_file2"_old" ]]; then cp $str_file2 $str_file2"_old"; fi
    #

    # find HugePage size #
    str_HugePageSize="1G"

    if [[ $str_HugePageSize == "2M" ]]; then declare -i int_HugePageSizeK=2048; fi

    if [[ $str_HugePageSize == "1G" ]]; then declare -i int_HugePageSizeK=1048576; fi
    #

    ## find free memory ##
    declare -i int_HostMemMaxG=$((int_HostMemMaxK/1048576))
    declare -i int_SysMemMaxG=$((int_HostMemMaxG+1))                    # use modulus?

    # free memory # 
    if [[ ! -z $int_HugePageNum || ! -z $int_HugePageSizeK ]]; then declare -i int_HostMemFreeG=$((int_HugePageNum*int_HugePageSizeK/1048576))
    else declare -i int_HostMemFreeG=4; fi
    int_HostMemFreeG=$((int_SysMemMaxG-int_HostMemFreeG))
    #
    ##

    # setup ZRAM #
    if [[ $int_HostMemFreeG -le 8 ]]; then declare -i int_ZRAM_SizeG=4
    else declare -i int_ZRAM_SizeG=$int_SysMemMaxG/2; fi

    declare -i int_denominator=$int_SysMemMaxG/$int_ZRAM_SizeG
    #str_input_ZRAM="_zram_fixedsize=\"${int_ZRAM_SizeG}G\""
    #

    # file 3
    declare -a arr_file_ZRAM=(
"# compression algorithm to employ (lzo, lz4, zstd, lzo-rle)
# default: lz4
_zram_algorithm=\"lz4\"

# portion of system ram to use as zram swap (expression: \"1/2\", \"2/3\", \"0.5\", etc)
# default: \"1/2\"
_zram_fraction=\"1/$int_denominator\"

# setting _zram_swap_debugging to any non-zero value enables debugging
# default: undefined
#_zram_swap_debugging=\"beep boop\"

# expected compression factor; set this by hand if your compression results are
# drastically different from the estimates below
#
# Note: These are the defaults coded into /usr/local/sbin/zram-swap.sh; don't alter
#       these values, use the override variable '_comp_factor' below.
#
# defaults if otherwise unset:
#       lzo*|zstd)  _comp_factor=\"3\"   ;; # expect 3:1 compression from lzo*, zstd
#       lz4)        _comp_factor=\"2.5\" ;; # expect 2.5:1 compression from lz4
#       *)          _comp_factor=\"2\"   ;; # default to 2:1 for everything else
#
#_comp_factor=\"2.5\"

# if set skip device size calculation and create a fixed-size swap device
# (size, in MiB/GiB, eg: \"250M\" \"500M\" \"1.5G\" \"2G\" \"6G\" etc.)
#
# Note: this is the swap device size before compression, real memory use will
#       depend on compression results, a 2-3x reduction is typical
#
#_zram_fixedsize=\"4G\"

# vim:ft=sh:ts=2:sts=2:sw=2:et:"
)
    #

    # write to file #
    rm $str_file2
    for str_line in ${arr_file_ZRAM[@]}; do
        echo -e $str_line >> $str_file2
    done
    #
    
    systemctl restart zram-swap     # restart service

}
##### end ZRAM #####

########## end functions ##########

########## main ##########

# check if sudo #
if [[ `whoami` != "root" ]]; then echo "$0: Script must be run as Sudo or Root!"; exit 0; fi
#

# a canary to check for previous VFIO setup installation #
bool_VFIO_Setup=false
#

# check if system supports IOMMU #
if ! compgen -G "/sys/kernel/iommu_groups/*/devices/*" > /dev/null; then echo "$0: AMD IOMMU/Intel VT-D is NOT enabled in the BIOS/UEFI."; fi
#

# set IFS #
SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
IFS=$'\n'      # Change IFS to newline char
#

# call functions #
while [[ $bool_isVFIOsetup == false ]]; do

    Prompts $bool_VFIO_Setup
    echo -e "$0: DISCLAIMER: Please review changes made.\n\tIf a given network or storage controller is necessary for the system, and if it is passed-through, the system will lose access to it."

done
#

# prompt uninstall setup or exit #
if [[ $bool_isVFIOsetup == true ]]; then

    echo -e "$0: WARNING: System is already setup with VFIO Passthrough.\n$0: To continue with a new VFIO setup:\n\tExecute the 'Uninstall VFIO setup,'\n\tReboot the system,\n\tExecute '$0'."

    while [[ $bool_isVFIOsetup== true ]]; do
    
        if [[ $int_count -ge 3 ]]; then

            echo "$0: Exceeded max attempts."
            str_input1="N"      # default selection
        
        else

            echo -en "$0: Uninstall VFIO setup on this system? [ Y/n ]: "
            read -r str_input1
            str_input1=`echo $str_input1 | tr '[:lower:]' '[:upper:]'`

        fi

        case $str_input1 in

            "Y")

                echo -e "$0: Uninstalling VFIO setup...\n"

                UninstallMultiBootSetup
                UninstallStaticSetup

                break;;

            "N")

                echo -e "$0: Skipping...\n"
                exit 0

            *)

                echo "$0: Invalid input.";;

        esac
        ((int_count++))

        done
        #

    done

fi
#

# reset IFS #
IFS=$SAVEIFS   # Restore original IFS
#

exit 0

########## end main ##########
