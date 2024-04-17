# deploy-VFIO
Effortlessly deploy changes to enable virtualization, hardware-passthrough (VFIO), and quality-of-life enhancements for a seamless VFIO setup on a Linux desktop machine.

**[View master branch...](https://github.com/portellam/deploy-vfio/tree/master)**

**What is [VFIO?](#VFIO) | [VFIO Article](https://www.kernel.org/doc/html/latest/driver-api/vfio.html) | [VFIO Forum](https://old.reddit.com/r/VFIO) | [PCI Passthrough Guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)**

#### Related Projects:
**[Auto Xorg](https://github.com/portellam/auto-Xorg) | [Generate Evdev](https://github.com/portellam/generate-evdev) | [Guest Machine Guide](https://github.com/portellam/guest-machine-guide) | | [Libvirt Hooks](https://github.com/portellam/deploy-vfio) | [Power State Virtual Machine Manager](https://github.com/portellam/deploy-vfio)**

## Table of Contents
- [About](#about)
- [Why?](#why)
- [Host Requirements](#host-requirements)
- [Get](#get)
- [Usage](#usage)
- [Features](#features)
- [Information](#information)
- [References](#references)
- [Disclaimer](#disclaimer)
- [Contact](#contact)
- [License](LICENSE.md)

## Contents
### About
Collection of scripts to deploy and re-deploy a VFIO setup. Includes automation.

### Why?
1. **Separation of Concerns:** Independently operate your workstation, gaming, and school Operating Systems (OS), as [Virtual Machines](https://en.wikipedia.org/wiki/Virtual_machine) (VMs), under one Host machine.
2. **No Need for a Server**
  - Keep your Host OS desktop experience intact; turns your Host into a *Type-2* [Hypervisor](https://www.redhat.com/en/topics/virtualization/what-is-a-hypervisor).
  - Servers like Microsoft Hyper-V, Oracle VM, and Proxmox Linux are considered *Type-1* or bare-metal Hypervisors.

3. **Securely run a modern OS:** limited access to real hardware means greater security.
4. **Ease of use:** support for automation by use of the [Command Line Interface](#usage) (CLI).
5. **PCI Passthrough:** prioritize real hardware over emulation.
6. **Quality of Life**: utilize multiple common-sense [features](#features) that are known to experienced users.
7. **Your Host OS is [supported](#supported-operating-systems).**
8. **Securely run a [legacy OS](#legacy).**

**Advertisement:** For even greater security, use [me_cleaner](#me_cleaner) alongside a VFIO setup.

**Disclaimer:** See [below](#latest-graphics-hardware-for-various-guest-operating-systems) for supported [VGA](#VGA) devices.

## Host Requirements
- Currently supported operating systems:
  | Linux Distributions | Supported? | Tested  |
  | ------------------- | ---------- | ------- |
  | Arch                | No         | none    |
  | Debian[<sup>1</sup>](#1-debian-derivatives-include-linux-mint-pop-os-and-ubuntu)           | Yes        | 11, 12  |
  | Gentoo              | No         | none    |
  | Red Hat Enterprise  | No         | none    |
  | SUSE                | No         | none    |

##### 1. Debian derivatives include Linux Mint, Pop! OS, and Ubuntu.

- Required software packages (for this script):
  `xmlstarlet`
  - To install packages:
    - Debian Linux: `sudo apt install -y xmlstarlet`
- Other requirements:
  - `GRUB` to execute command lines at boot (if chosen).
  - `systemd` for system services.
  - IOMMU is supported (by the CPU) and enabled in the motherboard firmware (BIOS or UEFI).
    - For AMD machines:&nbsp;`AMD-Vi`
    - For Intel machines:&ensp;&nbsp;`VT-d`
    - ARM (`SMMU`) and other CPU architectures are not explicitly supported by this script.

## Get
- To download this script, you may:
  - Clone the repository:
    1. Open a Command Line Interface (CLI).
      - Open a console emulator (for Debian systems: Konsole).
      - Open a existing console: press `CTRL` + `ALT` + `F2`, `F3`, `F4`, `F5`, or `F6`.
        - **To return to the desktop,** press `CTRL` + `ALT` + `F7`.
        - `F1` is reserved for debug output of the Linux kernel.
        - `F7` is reserved for video output of the desktop environment.
        - `F8` and above are unused.

    2. Change your directory to your home folder or anywhere safe: `cd ~`
    3. Clone the repository: `git clone https://www.github.com/portellam/deploy-vfio`
  - Download the ZIP file:
    1. Viewing from the top of the repository's (current) webpage, click the green `<> Code ` drop-down icon.
    2. Click `Download ZIP`. Save this file.
    3. Open the `.zip` file, then extract its contents.
- To make this script executable, you must:
  1. Open the CLI (see above).
  2. Go to the directory of where the cloned/extracted repository folder is: `cd name_of_parent_folder/deploy-vfio/`
  3. Make the installer script file executable: `chmod +x installer.bash`
    - Do **not** make any other script files executable. The installer will perform this action.
    - Do **not** make any non-script file executable. This is not necessary and potentially dangerous.

## Usage
**`installer.bash`**
  - From the project folder, execute: `sudo bash installer.bash`
  ```xml
  -h, --help               Print this help and exit.
  -i, --install            Install deploy-VFIO to system.
  -u, --uninstall          Uninstall deploy-VFIO from system.
  ```
  - The installer will place all script files in `/usr/local/bin`.
  - The installer will place all configuration/text files in `/usr/local/etc`.

**`deploy-vfio`**
- From anywhere, execute: `sudo bash deploy-vfio`
  - The CLI's shell (bash) should recognize that the script file is located in `/usr/local/bin`.
```
-h, --help               Print this help and exit.
-q, --quiet              Reduce verbosity; print only relevant questions and status statements.
-u, --undo               Undo changes (restore files) if script has exited early or unexpectedly.
  --ignore-distro        Ignore distribution check for Debian or Ubuntu system.

Specify the database to reference before parsing IOMMU groups:
  --xml [filename]       Cross-reference XML file. First-time, export if VFIO is not setup. Consecutive-times, imports if VFIO is setup.
  [filename]             Reference specific file.
  --no-xml               Skips prompt.

Specify the IOMMU groups to parse:
-p, --parse [groups]     Parse given IOMMU groups (delimited by comma).
  all                    Select all IOMMU groups.
  no-vga                 Select all IOMMU groups without VGA devices.
  [x]                    Select IOMMU group.
  [x-y]                  Select IOMMU groups.

Example:
  --parse no-vga,14      Select IOMMU group 14 and all non-VGA groups.
  --parse 1,14-16        Select IOMMU groups 1, 14, 15, and 16.

Pre-setup:
-c, --cpu                Allocate CPU.
-e, --evdev              Setup a virtual KVM switch.
-h, --hugepages [ARGS]   Create static hugepages (pages greater than 4 KiB) to allocate RAM for Guest(s).
  --skip-pre-setup       Skip execution.
  --uninstall-pre-setup  Undo all changes made by pre-setup.

Hugepages:
  2M, 1G                 Hugepage size (2 MiB or 1 GiB).
  [x]                    Amount of Hugepages (maximum amount is total memory subtracted by 4 GiB).

Example:
--hugepages 1G 16        1 GiB hugepage 16   == 16 GiB allocated to hugepages.
--hugepages 2M 8192      2 MiB hugepage 8912 == 16 GiB allocated to hugepages.

VFIO setup:
-m, --multiboot [ARGS]   Create multiple VFIO setups with corresponding GRUB menu entries. Specify default GRUB menu entry by VGA IOMMU group ID.
-s, --static [ARGS]      Single VFIO setup. Specify method of setup.
--skip-vfio-setup        Skip execution.
--uninstall-vfio-setup   Undo an existing VFIO setup.

Multiboot VFIO:
  [x]                    The ID of the valid excluded VGA IOMMU group.
  default                Default menu entry excludes VFIO setup.
  first                  Prefer the first valid excluded VGA IOMMU group.
  last                   Prefer the last valid excluded VGA IOMMU group.

Static VFIO:
  file                   Append output to system configuration files.
  grub                   Append output to GRUB; single GRUB menu entry.

Post-setup:
--audio-loopback         Install the audio loopback service...           Loopback audio from Guest to Host (over Line-out to Line-in).
--auto-xorg [ARGS]       Install auto-Xorg...                            System service to find and set a valid boot VGA device for Xorg.
--libvirt-hooks          Install recommended Libvirt hooks.
--zram-swap [ARGS]       Create compressed swap in RAM (about 2:1)...    Reduce chances of memory exhaustion for Host.
--skip-post-setup        Skip execution.
--uninstall-post-setup   Undo all changes made by post-setup.

auto-xorg:
  first  [vendor]        Find the first valid VGA device.
  last   [vendor]        Find the last valid VGA device.
  [sort] amd             Prefer AMD or ATI.
  [sort] intel           Prefer Intel.
  [sort] nvidia          Prefer NVIDIA.
  [sort] other           Prefer any other brand.

zram-swap:
  [fraction]             Set the fraction of total available memory.
  default                Automatically calculate the fraction of total available memory.
  force                  Force changes, even if zram-swap is allocated and in use.

Example: (assume a Host with 32 GiB of RAM)
--zram-swap force 1/4    Compress 8 GiB of RAM, to create 16 GiB of swap, with 16 GiB free.
```

## Features
### Pre-setup
1. **Allocate CPU**
  - **Statically** [isolate Host CPU threads](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_pinning) before allocating to Guest(s).
  -  Reduces Host overhead, and improves both Host and Guest performance.
  -  If installed, the **Dynamic** [Libvirt hook](https://github.com/portellam/libvirt-hooks) (see source) will skip its execution, to preserve the Static isolation.

  2. **Allocate RAM**
  - **Static** huge memory pages eliminate the need to defragment Host memory (RAM) before allocating to Guest(s).
  - Reduces Host overhead, and improves both Host and Guest performance.
  - If skipped, setup will install the Libvirt hook for **Dynamic** allocation (transparent hugepages).

3. **Virtual Keyboard Video Mouse (KVM) switch**
  - Create a virtual KVM switch.
    - Allow a user to swap a group of Input devices (as a whole) between active Guest(s) and Host.
    - Use the pre-defined macro: `L-CTRL` + `R-CTRL`
  - Implementation is known as [Evdev](#evdev) (Event Devices).
  - **Note:** Guest PCI USB is good. Both implementations together is better.

### Main setup
- **Multi-boot VFIO setup**
  - Create multiple VFIO setups with corresponding GRUB menu entries. **More flexibility.**
    - Select a GRUB menu entry with a VGA device excluded from VFIO.
    - Default menu entry is without VFIO setup.
    - Best for systems with two or more PCI VGA devices, without an integrated VGA device (iGPU).

  - **Ad:** For best results, use [auto-Xorg](https://github.com/portellam/auto-Xorg).

- **Static VFIO setup**
  - Single, traditional VFIO setup. **Less flexibility.**
  - Specify method of setup:
    - Append output to GRUB; single GRUB menu entry.
    - Append output to system configuration files.
  - Best for systems with one or more PCI VGA device(s) and one integrated VGA device (iGPU).

- **Dynamic VFIO setup** (To be implemented in a future release)
  - Use Libvirt hooks to bind or unbind devices at Guest(s) start or stop.
  - Most responsibility; best for more experienced users.
  - Most flexibility; Libvirt hooks allow Host to allocate and release resources dynamically.
  - For an existing script of similar scope, you may try the project [VFIO-Tools](https://github.com/PassthroughPOST/VFIO-Tools).

### Post-setup (To be implemented in a future release)
1. **auto-Xorg** system service to find and set a valid Host boot [VGA](#VGA) device for Xorg.
2. **Guest Audio Capture**
  - Create an [audio loopback](https://github.com/portellam/audio-loopback) to output on the Host audio device Line-Out.
    - Listen on Host audio device Line-In (from Guest PCI Audio device Line-Out).
    - Useful for systems with multiple audio devices.
  - For virtual implementation, see *Virtual Audio Capture*.

3. **Libvirt Hooks**
- Invoke [hooks](#libvirt-hooks) or scripts for all or individual Guests.
- Switch display input (video output) at Guest start.
- **Dynamically** allocate CPU cores and prioritize CPU scheduler.
- **Libvirt-nosleep**: per Guest system service, to prevent Host sleep while Guest is active.

4. **RAM as Compressed Swapfile/partition**
  - Create a compressed Swap device in Host memory, using the *lz4* algorithm (compression ratio of about 2:1).
    - Reduce swapiness to existing Host swap devices.
    - Reduce chances of Host memory exhaustion (given an event of memory over-allocation).
  - Implementation is known as [zram-swap](#zram-swap).

5. **Virtual Audio Capture**
  - Setup a virtual audio driver for Windows that provides a discrete audio device.
  - Implementation is known as [Scream](#scream).

6. **Virtual Video Capture**
  - Setup direct-memory-access (DMA) of a PCI VGA device output (video and audio) from a Guest to Host.
  - Implementation is known as [LookingGlass](https://looking-glass.io/).
  - **Disclaimer:** Only supported for Guests running Windows 7 and later (Windows NT 6.1+).

## Information
### BIOS v. UEFI
- Some VGA devices, such as NVIDIA, may not be recognizable in a VM, as the video BIOS or VBIOS is *tainted* at Host OS start-up. This is usually the case if a given VGA device is used for the Host BIOS/UEFI booting process. To remedy this, you must obtain a clean copy of the VBIOS. You may reference this [project](https://github.com/Matoking/NVIDIA-vBIOS-VFIO-Patcher) for assistance, or review the [Arch Wiki article](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_the_boot_GPU_to_the_guest).

- If your Host machine supports UEFI only and/or if UEFI is enabled (and CSM/BIOS is disabled),
BIOS-only VGA devices may not be available as Host video output. BIOS-only VGA devices may only be available explicitly for hardware passthrough.

### Filenames and pathnames modified:
#### Pre-setup files
  - `/etc/apparmor.d/local/abstractions/libvirt-qemu`
  - `/etc/libvirt/qemu.conf`

#### VFIO setup files
  - `/etc/default/grub`
  - `/etc/grub.d/proxifiedScripts/custom`
  - `/etc/initramfs-tools/modules`
  - `/etc/modprobe.d/pci-blacklists.conf`
  - `/etc/modprobe.d/vfio.conf`
  - `/etc/modules`

#### Post-setup paths
  - `/etc/libvirt/hooks/`
  - `/usr/local/bin/`
  - `/etc/systemd/system/`

#### Paths for project binaries and files
  - `/usr/local/bin/`
  - `/usr/local/etc/deploy-vfio.d`

### VFIO
Virtual Function I/O (Input Output), or VFIO, *is a new user-level driver framework for Linux...  With VFIO, a VM Guest can directly access hardware devices on the VM Host Server (pass-through), avoiding performance issues caused by emulation in performance critical paths.*<sup>[OpenSUSE documentation](https://doc.opensuse.org/documentation/leap/virtualization/html/book-virtualization/chap-virtualization-introduction.html)</sup>

### VGA
Throughout the script source code and documentation, the acronym *VGA* is used.

In Linux, a Video device or GPU, is listed as *VGA*, or Video Graphics Array. VGA may *refer to the computer display standard, the 15-pin D-subminiature VGA connector, or the 640×480 resolution characteristic of the VGA hardware.*<sup>[Wikipedia article](https://en.wikipedia.org/wiki/Video_Graphics_Array)</sup>

#### Example
`lspci -nnk | grep --extended-regexp --ignore-case "vga|graphics"`

##### Output:
```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484] (rev a1)
04:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Cayman PRO [Radeon HD 6950] [1002:6719]
```

### Latest graphics hardware for various Guest Operating Systems
#### Apple Macintosh
##### [AMD and NVIDIA GPU compatibility list (Apple Support article)](https://support.apple.com/en-us/102734)
##### [More detailed NVIDIA GPU compatibility list (archive of TonyMacX86 forum thread)](https://web.archive.org/web/20230926193339/https://www.tonymacx86.com/threads/will-my-nvidia-graphics-card-work-with-macos-list-of-desktop-cards-with-native-support.283700/)

#### Microsoft Windows
| Windows version        | Device type | Brand and model                           |
| --------------------   | ----------- | ----------------------------------------- |
| 10 and above or NT 10+ | VGA         | NVIDIA RTX 4000-series[<sup>2</sup>](#2-uefi-only) or before       |
| 7 and above or NT 6.1+ | VGA         | NVIDIA RTX 1000-series[<sup>2</sup>](#2-uefi-only) or before       |
| XP or NT 4             | VGA         | NVIDIA GTX 900-series[<sup>3</sup>](#3-uefi-or-bios-compatible) or before[<sup>3</sup>](#3-uefi-or-bios-compatible)          |
|                        |             | AMD Radeon HD 7000-series[<sup>3</sup>](#3-uefi-and-or-compatible) or before[<sup>3</sup>](#3-uefi-or-bios-compatible) |
| 9x                     | VGA         | NVIDIA 7000-series GTX[<sup>1</sup>](#1-bios-only) or before       |
|                        |             | any ATI model[<sup>1</sup>](#1-bios-only) (before AMD)             |

##### 1. *BIOS only.*
##### 2. *UEFI only.*
##### 3. *UEFI or BIOS compatible.*

**Note:** For emulating video devices on Windows 9x and older legacy operating systems, try the project [SoftGPU](https://github.com/JHRobotics/softgpu). Modern CPUs are more than powerful enough to emulate such hardware.

## References
#### Hugepages
&ensp;<sub>**[Arch Wiki article](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages)**</sub>

&ensp;<sub>**[Debian Wiki article](https://wiki.debian.org/Hugepages)**</sub>

#### Evdev
&ensp;<sub>**[Arch Wiki article](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev)**</sub>

&ensp;<sub>**[GitHub project source](https://github.com/portellam/generate-evdev)**</sub>

#### me_cleaner
&ensp;<sub>**[GitHub project source](https://github.com/corna/me_cleaner)**</sub>

&ensp;<sub>**[GitHub project fork](https://github.com/dt-zero/me_cleaner)**</sub>

#### Scream
&ensp;<sub>**[GitHub project source](https://github.com/duncanthrax/scream)**</sub>

&ensp;<sub>**[LookingGlass Wiki guide](https://looking-glass.io/wiki/Using_Scream_over_LAN)**</sub>

#### ZRAM Swap
&ensp;<sub>**[Arch software package](https://aur.archlinux.org/packages/zramswap)**</sub>

&ensp;<sub>**[Debian software package](https://wiki.debian.org/ZRam)**</sub>

&ensp;<sub>**[GitHub project source](https://github.com/foundObjects/zram-swap)**</sub>

&ensp;<sub>**[LZ4 GitHub project source](https://github.com/lz4/lz4)**</sub>

&ensp;<sub>**[Tuning benchmarks (Reddit)](https://web.archive.org/web/20220201101923/https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/)**</sub>

## Disclaimer
Use at your own risk. Please review your system's specifications and resources.

## Contact
Did you encounter a bug? Do you need help? Notice any dead links? Please contact by [raising an issue](https://github.com/portellam/deploy-VFIO/issues) with the project itself. The project is still in active development and the [Author](https://github.com/portellam) monitors this repository occasionally.

Thanks!
