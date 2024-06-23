# Deploy VFIO
### v1.0.1
Effortlessly deploy a hardware-passthrough (VFIO) setup for Virtual Machines
(VMs) on a Linux desktop. Includes quality-of-life features that you didn't
think you need!

## [Download](#5-download)

[codeberg-releases]: https://codeberg.org/portellam/deploy-VFIO/releases/latest
[github-releases]:   https://github.com/portellam/deploy-VFIO/releases/latest

## Table of Contents
- [1. Why?](#1-why)
- [2. Related Projects](#2-related-projects)
- [3. Documentation](#3-documentation)
- [4. Host Requirements](#4-host-requirements)
    - [4.1. Operating System](#41-operating-system)
    - [4.2. Software](#42-software)
    - [4.3. Hardware](#43-hardware)
- [5. Download](#5-download)
- [6. Usage](#6-usage)
    - [6.1. Verify Installer is Executable](#61-verify-script-is-executable)
    - [6.2. `installer.bash`](#61-installerbash)
    - [6.3. `deploy-VFIO`](#62-deploy-vfio)
- [7. Features](#7-features)
    - [7.1. Pre-Setup](#71-pre-setup)
    - [7.2. Main Setup](#72-main-setup)
    - [7.3. Post-Setup](#73-post-setup)
- [8. Filenames and Pathnames Modified by deploy-VFIO](#8-filenames-and-pathnames-modified-by-deploy-vfio)
    - [8.1. Pre-Setup](#81-pre-setup)
    - [8.2. Main Setup](#82-main-setup)
    - [8.3. Post-Setup](#83-post-setup)
    - [8.4. Binaries and Files](#84-binaries-and-files)
- [9. Graphics Hardware (GPUs)](#9-graphics-hardware-gpus)
    - [9.1. How to Query Host Machine for Graphics Hardware](#91-how-to-query-host-machine-for-graphics-hardware)
    - [9.2. Troubleshooting Graphics Hardware](#92-troubleshooting-graphics-hardware)
    - [9.3. List of UEFI-compatible Graphics Hardware](#93-list-of-uefi-compatible-graphics-hardware)
    - [9.4. Alternatives to BIOS-only Graphics Hardware](#94-alternatives-to-bios-only-graphics-hardware)
    - [9.5. Apple macOS](#95-apple-macos)
    - [9.6. Linux](#96-linux)
    - [9.7. Microsoft Windows](#97-microsoft-windows)
- [10. Disclaimer](#10-disclaimer)
- [11. Contact](#11-contact)
- [12. References](#12-references)

## Contents

### 1. Why?
1. **Separation of Concerns:** Independently operate your workstation, gaming,
and school Operating Systems (OS), as [Virtual Machines](#19) (VMs), under one
Host machine.

2. **No Need for a Server**
    - **Keep your Host's desktop experience intact;** turns your Host into a
  Type-2 [Hypervisor](#18).
    - Servers like Microsoft Hyper-V, Oracle VM, and Proxmox Linux are considered
  Type-1 or bare-metal Hypervisors.

3. **Securely run a an OS**
    - Limited access to real hardware means greater security.
    - The benefits extend to untrusted or legacy OSes.

4. **Ease of use:** support for automation by use of the
[Command Line Interface](#6-usage) (CLI).

5. **PCI Passthrough:** prioritize real hardware over emulation.

6. **Quality of Life**: utilize multiple common-sense [features](#7-features) that
are known to experienced users.

7. **Your Host OS is [supported](#4-host-requirements).**

**Note:** For even greater security, use [me_cleaner](#9) alongside a VFIO
setup.

### 2. Related Projects
| Project                             | Codeberg          | GitHub          |
| :---                                | :---:             | :---:           |
| **Deploy VFIO**                     | [link][codeberg1] | [link][github1] |
| Auto X.Org                          | [link][codeberg2] | [link][github2] |
| Generate Evdev                      | [link][codeberg3] | [link][github3] |
| Guest Machine Guide                 | [link][codeberg4] | [link][github4] |
| Libvirt Hooks                       | [link][codeberg5] | [link][github5] |
| Power State Virtual Machine Manager | [link][codeberg6] | [link][github6] |

[codeberg1]: https://codeberg.org/portellam/deploy-VFIO
[github1]:   https://github.com/portellam/deploy-VFIO
[codeberg2]: https://codeberg.org/portellam/auto-xorg
[github2]:   https://github.com/portellam/auto-xorg
[codeberg3]: https://codeberg.org/portellam/generate-evdev
[github3]:   https://github.com/portellam/generate-evdev
[codeberg4]: https://codeberg.org/portellam/guest-machine-guide
[github4]:   https://github.com/portellam/guest-machine-guide
[codeberg5]: https://codeberg.org/portellam/libvirt-hooks
[github5]:   https://github.com/portellam/libvirt-hooks
[codeberg6]: https://codeberg.org/portellam/powerstate-virtmanager
[github6]:   https://github.com/portellam/powerstate-virtmanager

### 3. Documentation
- [What is VFIO?](#19)
- [VFIO Discussion and Support](#13)
- [Hardware-Passthrough Guide](#12)
- [Virtual Machine XML Format Guide](#22)

### 4. Host Requirements
#### 4.1. Operating System
  | Linux Distributions  | Tested | Supported  |
  | :------------------- | :----: | :--------: |
  | Arch                 | No     | N/A        |
  | Debian<sup>[1]</sup> | Yes    | 11, 12     |
  | Gentoo               | No     | N/A        |
  | Red Hat Enterprise   | No     | N/A        |
  | SUSE                 | No     | N/A        |

[1]: (#1-debian-derivatives-include-linux-mint-pop-os-and-ubuntu)

##### 1. Debian derivatives include Linux Mint, Pop! OS, and Ubuntu.
#### 4.2. Software
Required software packages (for this script):
  `xmlstarlet`
  - To install packages:
  - Debian Linux: `sudo apt install -y xmlstarlet`

Other requirements:
  - `GRUB` to execute command lines at boot (if chosen).
  - `systemd` for system services.

#### 4.3. Hardware
The following firmware options are supported and enabled (motherboard and CPU):
- IOMMU
    - For AMD machines:&nbsp;`AMD-Vi`
    - For Intel machines:&ensp;&nbsp;`VT-d`
    - ARM (`SMMU`) and other CPU architectures are not **explicitly** supported by
  this script.

### 5. Download
- Download the Latest Release:&ensp;[Codeberg][codeberg-releases],
[GitHub][github-releases]

- Download the `.zip` file:
    1. Viewing from the top of the repository's (current) webpage, click the
        drop-down icon:
        - `···` on Codeberg.
        - `<> Code ` on GitHub.
    2. Click `Download ZIP` and save.
    3. Open the `.zip` file, then extract its contents.

- Clone the repository:
    1. Open a Command Line Interface (CLI).
        - Open a console emulator (for Debian systems: Konsole).
        - Open a existing console: press `CTRL` + `ALT` + `F2`, `F3`, `F4`, `F5`,  or
        `F6`.
            - **To return to the desktop,** press `CTRL` + `ALT` + `F7`.
            - `F1` is reserved for debug output of the Linux kernel.
            - `F7` is reserved for video output of the desktop environment.
            - `F8` and above are unused.
    2. Change your directory to your home folder or anywhere safe:
        - `cd ~`
    3. Clone the repository:
        - `git clone https://www.codeberg.org/portellam/deploy-VFIO`
        - `git clone https://www.github.com/portellam/deploy-VFIO`

[codeberg-releases]: https://codeberg.org/portellam/deploy-VFIO/releases/latest
[github-releases]:   https://github.com/portellam/deploy-VFIO/releases/latest

### 6. Usage
#### 6.1. Verify Installer is Executable
1. Open the CLI (see [Download](#5-download)).

2. Go to the directory of where the cloned/extracted repository folder is:
`cd name_of_parent_folder/deploy-VFIO/`

3. Make the installer script file executable: `chmod +x installer.bash`
    - Do **not** make any other script files executable. The installer will perform
  this action.
    - Do **not** make any non-script file executable. This is not necessary and
  potentially dangerous.

#### 6.2. `installer.bash`
- From the project folder, execute: `sudo bash installer.bash`
  ```xml
  -h, --help               Print this help and exit.
  -i, --install            Install deploy-VFIO to system.
  -u, --uninstall          Uninstall deploy-VFIO from system.
  ```
    - The installer will place all script files in `/usr/local/bin`.
    - The installer will place all configuration/text files in `/usr/local/etc`.

#### 6.3. `deploy-VFIO`
- From anywhere, execute: `sudo bash deploy-VFIO`
    - The CLI's shell (bash) should recognize that the script file is located in
  `/usr/local/bin`.
```
-h, --help               Print this help and exit.
-q, --quiet              Reduce verbosity; print only relevant questions and
status statements.
-u, --undo               Undo changes (restore files) if script has exited early
or unexpectedly.
  --ignore-distro        Ignore distribution check for Debian or Ubuntu system.

Specify the database to reference before parsing IOMMU groups:
  --xml [filename]       Cross-reference XML file. First-time, export if VFIO is
  not setup. Consecutive-times, imports if VFIO is setup.
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
-h, --hugepages [ARGS]   Create static hugepages (pages greater than 4 KiB) to
allocate RAM for Guest(s).
  --skip-pre-setup       Skip execution.
  --uninstall-pre-setup  Undo all changes made by pre-setup.

Hugepages:
  2M, 1G                 Hugepage size (2 MiB or 1 GiB).
  [x]                    Amount of Hugepages (maximum amount is total memory
  subtracted by 4 GiB).

Example:
--hugepages 1G 16        1 GiB hugepage 16   == 16 GiB allocated to hugepages.
--hugepages 2M 8192      2 MiB hugepage 8912 == 16 GiB allocated to hugepages.

VFIO setup:
-m, --multiboot [ARGS]   Create multiple VFIO setups with corresponding GRUB
menu entries. Specify default GRUB menu entry by VGA IOMMU group ID.
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
```

### 7. Features
#### 7.1. Pre-Setup
1. **Isolate CPU**
    - **Statically** isolate Host CPU threads before allocating to Guest(s).
    -  Reduces Host overhead, and improves both Host and Guest performance.
    -  If installed, the **dynamic** [Libvirt hook](#6) will skip its
  execution, to preserve the Static isolation.

2. **Huge pages**
    - **Statically** isolate Host memory (RAM) into **[Huge memory pages](#5)**
    before allocating to Guest(s).
    - Reduces Host overhead, and improves both Host and Guest performance.
    - Eliminates the need to defragment RAM before allocation to Guest(s)
    (as in the case with **transparent hugepages**).

3. **Virtual Keyboard Video Mouse (KVM) switch**
    - Create a virtual KVM switch by [Evdev](#11) (Event Devices).
    - Allow a user to swap a group of Input devices (as a whole) between active
    Guest(s) and Host.
    - Use a defined macro.
        - Default macro: `L-CTRL` + `R-CTRL`.
        - Change the macro for each VM in the [XML configuration](#23).
    - Implementation is known as [Generate Evdev](#3).
    - **Note:** Using guest PCI USB alone is good. Using both implementations is
  better.

#### 7.2. Main Setup
- **Multi-boot VFIO Setup**
    - Create multiple VFIO setups with corresponding GRUB menu entries.
    **More flexibility.**
    - Select a GRUB menu entry with a VGA device excluded from VFIO.
        - Default menu entry is without VFIO setup.
    - Best for systems with two or more PCI VGA devices, without an integrated VGA
    device (iGPU).

    - **Ad:** For best results, use [Auto X.Org](#2).

- **Static VFIO Setup**
    - Specify method:
        - Append output to GRUB (single GRUB menu entry).
        - Append output to system configuration files.
    - **Less flexible than either setups.**
    - Best for systems with one or more PCI VGA device(s) and one integrated VGA
  device (iGPU).

- **Dynamic VFIO Setup** (To be implemented in a future release)
    - Use Libvirt hooks to bind or unbind devices at Guest(s) start or stop.
    - Most responsibility; best for more experienced users.
    - Most flexibility; Libvirt hooks allow Host to allocate and release resources
  dynamically.
    - For an existing script of similar scope, you may try the project
  [VFIO-Tools](#20).

#### 7.3. Post-Setup (To be implemented in a future release)
1. **Auto X.Org** system service to find and set a valid Host boot [VGA](#21)
device for X.Org.

2. **Guest Audio Capture**
    - Create an [audio loopback](#1) to output on the Host audio device Line-Out.
    - Listen on Host audio device Line-In (from Guest PCI Audio device Line-Out).
    - Useful for systems with multiple audio devices.
    - For virtual implementation, see *Virtual Audio Capture*.

3. **Libvirt Hooks**
    - Invoke [hooks](#6) or scripts for all or individual Guests.
    - Switch display input (video output) at Guest start.
    - **Dynamically** allocate CPU cores and prioritize CPU scheduler.
    - **Libvirt-nosleep**: per Guest system service, to prevent Host sleep while
    Guest is active.

4. **RAM as Compressed Swapfile/partition**
    - Create a compressed Swap device in Host memory, using the [lz4](#8) algorithm
  (compression ratio of about 2:1).
    - Reduce swapiness to existing Host swap devices.
    - Reduce chances of Host memory exhaustion (given an event of memory
    over-allocation).
    - Implementation is known as [zram-swap](#24).

5. **Virtual Audio Capture**
    - Setup a virtual audio driver for Windows that provides a discrete audio
  device and passthrough from a Guest to Host.
    - Passthrough audio by direct-memory-access (DMA).
    - Passthrough audio by a [virtual Local Area Network (LAN) device](#17).
    - Implementation is known as [Scream](#15).

6. **Virtual Video Capture**
    - Setup DMA of a PCI VGA device output (video and audio) from a Guest to Host.
    - Implementation is known as [Looking Glass](#7).
    - **Disclaimer:** Only supported for Guests running Windows 7 and later
  (Windows NT 6.1+).

### 8. Filenames and Pathnames Modified by deploy-VFIO
##### 8.1. Pre-Setup
  - `/etc/apparmor.d/local/abstractions/libvirt-qemu`
    - `/etc/libvirt/qemu.conf`

##### 8.2. Main Setup
  - `/etc/default/grub`
  - `/etc/grub.d/proxifiedScripts/custom`
  - `/etc/initramfs-tools/modules`
  - `/etc/modprobe.d/pci-blacklists.conf`
  - `/etc/modprobe.d/vfio.conf`
  - `/etc/modules`

##### 8.3. Post-Setup
  - `/etc/libvirt/hooks/`
  - `/usr/local/bin/`
  - `/etc/systemd/system/`

##### 8.4. Binaries and Files
  - `/usr/local/bin/deploy-VFIO`
  - `/usr/local/etc/deploy-VFIO.d/`

### 9. Graphics Hardware (GPUs)
**Note:** Unfortunately, most or all GPUs without UEFI firmware (BIOS-only) are
not currently compatible with VFIO. If your GPU does work, please share your
success with [this project](#11-contact) and/or
[the VFIO community](#3-documentation).

#### 9.1. How to Query Host Machine for Graphics Hardware
`lspci -nnk | grep --extended-regexp --ignore-case "vga|graphics"`

**Example:**
```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484] (rev a1)
04:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Cayman PRO [Radeon HD 6950] [1002:6719]
```

#### 9.2. Troubleshooting Graphics Hardware
Some VGA devices, such as NVIDIA, may not be recognizable in a VM, as the video
BIOS or VBIOS is *tainted* at Host OS start-up. This is usually the case if a
given VGA device is used for the Host BIOS/UEFI booting process. To remedy this,
you must obtain a clean copy of the VBIOS. You may review either
[NVIDIA-vBIOS-VFIO-Patcher](#10), or the [ArchWiki](#12).

#### 9.3. List of Supported Firmware by Graphics Hardware
**Note:** Vendors that are unlisted are more than likely legacy graphics
hardware. Therefore, it is safe to assume such hardware is BIOS-only.

| Vendor | Model                             | Firmware  |
| :----- | :-------------------------------- | :-------: |
| 3dfx   | any                               | BIOS      |
| AMD    | Radeon HD 7750,7970 and newer     | UEFI      |
| AMD    | Radeon HD 7000-series and older   | BIOS      |
| ATI    | any                               | BIOS      |
| Intel  | Gen5 (HD Graphics) and newer      | UEFI      |
| Intel  | Gen4 and older                    | BIOS      |
| NVIDIA | GeForce GTX 700 to 1000-series    | UEFI      |
| NVIDIA | GeForce GTX 600-series and older  | BIOS      |

#### 9.4. Alternatives to BIOS-only Graphics Hardware
##### 9.4.1. GPU Emulation
For emulating graphics hardware on old, legacy operating systems (such as
Windows 98), try [SoftGPU](#16). Modern CPUs are more than powerful enough to
emulate such hardware. Fortunately, this implementation is not software
rendering. You may use whichever graphics API which is supported by the emulated
GPU (example: Glide for 3dfx).

#### 9.5. Apple macOS
##### 9.5.1. [AMD and NVIDIA GPU compatibility list](#4)
##### 9.5.2. [More detailed NVIDIA GPU compatibility list](#14)

#### 9.6. Linux
Typically, Linux is compatible with GPUs dating back to the end of the 20th
century. However, GPU-compatibility may vary among different Linux
distributions. Please review the documentation of your Linux distribution.

#### 9.7. Microsoft Windows
| Legacy Windows version | Vendor | Model                             |
| :--------------------- | :----- | :-------------------------------- |
| XP / NT 4 and older    | AMD    | Radeon HD 7970 and older          |
| XP / NT 4 and older    | NVIDIA | GeForce GTX 900-series            |
| 7 / NT 6.1             | AMD    | Radeon R9 200-series and newer    |
| 7 / NT 6.1             | NVIDIA | GeForce GTX 3000-series and older |

### 10. Disclaimer
Use at your own risk. Please review your system's specifications and resources.

### 11. Contact
Did you encounter a bug? Do you need help? Please visit the **Issues page**
([Codeberg][codeberg-issues], [GitHub][github-issues]).

[codeberg-issues]: https://codeberg.org/portellam/deploy-VFIO/issues
[github-issues]:   https://github.com/portellam/deploy-VFIO/issues

### 12. References
#### 1.
**portellam/audio-loopback**. Codeberg. Accessed June 18, 2024.
<sup>https://codeberg.org/portellam/audio-loopback.

**portellam/audio-loopback**. GitHub. Accessed June 18, 2024.
<sup>https://github.com/portellam/audio-loopback.

#### 2.
**portellam/auto-xorg**. Codeberg. Accessed June 18, 2024.
<sup>https://codeberg.org/portellam/auto-xorg.

**portellam/auto-xorg**. GitHub. Accessed June 18, 2024.
<sup>https://github.com/portellam/auto-xorg.

#### 3.
**portellam/generate-evdev**. Codeberg. Accessed June 17, 2024.
<sup>https://codeberg.org/portellam/generate-evdev.</sup>

**portellam/generate-evdev**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/portellam/generate-evdev.</sup>

#### 4.
**Graphics card compatibility for Final Cut Pro, Motion, and Compressor**. Apple
Support. October 31, 2023. Accessed June 18, 2024.
<sup>https://support.apple.com/en-us/102734.</sup>

#### 5.
**Hugepages**. Debian Wiki. Accessed June 17, 2024.
<sup>https://wiki.debian.org/Hugepages.</sup>

**Huge memory pages**. PCI passthrough via OVMF - ArchWiki. Accessed June 14,
2024.
<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages.</sup>

#### 6.
**portellam/libvirt-hooks**. Codeberg. Accessed June 18, 2024.
<sup>https://codeberg.org/portellam/libvirt-hooks.</sup>

**portellam/libvirt-hooks**. GitHub. Accessed June 18, 2024.
<sup>https://github.com/portellam/libvirt-hooks.</sup>

#### 7.
**Looking Glass**. Looking Glass. Accessed June 17, 2024.
<sup>https://looking-glass.io/</sup>

#### 8.
**LZ4/LZ4**. GitHub. Accessed June 17,
2024.
<sup>https://github.com/lz4/lz4.</sup>

#### 9.
**corna/me_cleaner**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/corna/me_cleaner.</sup>

**dt-zero/me_cleaner**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/dt-zero/me_cleaner.</sup>

#### 10.
**Matoking/NVIDIA-vBIOS-VFIO-Patcher**. GitHub. Accessed June 18, 2024.
<sup>https://github.com/Matoking/NVIDIA-vBIOS-VFIO-Patcher.</sup>

#### 11.
**4.5 Passing Keyboard/Mouse via Evdev**. PCI passthrough via OVMF - ArchWiki.
Accessed June 14, 2024.
<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF.</sup>

#### 12.
**PCI passthrough via OVMF**. ArchWiki. Accessed June 14, 2024.
<sup>https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF.</sup>

#### 13.
**VFIO Discussion and Support**. Reddit. Accessed June 14, 2024.
<sup>https://www.reddit.com/r/VFIO/.</sup>

#### 14.
**tonymacx86 - Will my Nvidia Graphics Card work with macOS ? List of Desktop**
**Cards with Native Support**. Archive.org. Accessed June 18, 2024.
<sup>https://web.archive.org/web/20230926193339/https://www.tonymacx86.com/threads/will-my-nvidia-graphics-card-work-with-macos-list-of-desktop-cards-with-native-support.283700/.

#### 15.
**duncanthrax/scream**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/duncanthrax/scream.</sup>

#### 16.
**JHRobotics/SoftGPU**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/JHRobotics/SoftGPU.</sup>

#### 17.
**Using Scream Over LAN**. Looking Glass. Accessed June 17, 2024.
<sup>https://looking-glass.io/wiki/Using_Scream_over_LAN.</sup>

#### 18.
**Type 1 vs. Type 2 hypervisors**. IBM. Accessed June 18, 2024.
<sup>https://www.ibm.com/topics/hypervisors.</sup>

#### 19.
**VFIO - ‘Virtual Function I/O’ - The Linux Kernel Documentation**.
The linux kernel. Accessed June 14, 2024.
<sup>https://www.kernel.org/doc/html/latest/driver-api/vfio.html.</sup>

**Virtualization technology**. OpenSUSE Leap 15.5. Accessed June 18, 2024.
<sup>https://doc.opensuse.org/documentation/leap/virtualization/html/book-virtualization/chap-virtualization-introduction.html.</sup>

#### 20.
**PassthroughPOST/VFIO-Tools**. GitHub. Accessed June 18, 2024.
<sup>https://github.com/PassthroughPOST/VFIO-Tools.</sup>

#### 21.
**Video Graphics Array**. Wikipedia. August 18, 2002. Accessed June 18, 2024.
<sup>https://en.wikipedia.org/wiki/Video_Graphics_Array.</sup>

#### 22.
**XML Design Format**. GitHub - libvirt/libvirt. Accessed June 18, 2024.
<sup>https://github.com/libvirt/libvirt/blob/master/docs/formatdomain.rst.</sup>

#### 23.
**XML Design Format: Input Devices**. GitHub - libvirt/libvirt.Accessed June 18,
2024.
<sup>https://github.com/libvirt/libvirt/blob/master/docs/formatdomain.rst.</sup>

#### 24.
**foundObjects/zram-swap**. GitHub. Accessed June 17, 2024.
<sup>https://github.com/foundObjects/zram-swap.</sup>

**New zram tuning benchmarks**. Reddit. Accessed June 17, 2024.
<sup>https://web.archive.org/web/20220201101923/https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/.</sup>

**zramswap**. Arch Linux User Repository. Accessed June 17, 2024.
<sup>https://aur.archlinux.org/packages/zramswap.</sup>