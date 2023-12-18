# deploy-VFIO

## Contents
* [About](#About)
* [How-to](#How-to)
* [Features](#Features)
* [Information](#Information)
* [References](#References)
* [Disclaimer](#Disclaimer)

## About
### Description:
Effortlessly deploy changes to enable virtualization, hardware-passthrough (VFIO), and quality-of-life enhancements for a seamless VFIO setup on a Linux desktop machine.

### What is [VFIO](#VFIO)?
#### Useful links
* [About VFIO](https://www.kernel.org/doc/html/latest/driver-api/vfio.html)
* [Guide](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF)
* [Reddit](https://old.reddit.com/r/VFIO)

### Why?
* **Separation of Concerns**
    - Segregate your Workstation, Gaming, or School PC, as Virtual machines<sup>[1](#1)</sup> under one Host machine.
* **No Need for a Server**
    - Keep your Linux Desktop experience intact and run Virtual machines as like any other program; turns your Desktop PC into a Type 2 Hypervisor.<sup>[2](#2)</sup>
    - Server operating systems (OS) like Microsoft Hyper-V, Oracle VM (enterprise) and Proxmox Linux (community) are considered Type 1 or "bare-metal" Hypervisors.
* **Securely run a modern OS**
    - Reduce or eliminate the negative influences an untrusted OS may have, by reducing its access or control of real hardware.
    - Regain privacy and/or security from spyware OSes (example: *Windows 10, 11, Macintosh*).
* **Ease of use**
    - What is tedious becomes trivial; reduce the number of manual steps a user has to make.
    - Specify answers ahead of time or answer prompts step-by-step (see [Usage](#Usage)).
* **Hardware passthrough, not Hardware emulation**
    - Preserve the performance of a virtualized OS (example: Gaming), through use of real hardware (ex: Video/graphics device).
* **Quality of Life**
    - Choose multiple common-sense features that are known to experienced users (see [Features](#Features)).
* **Your desktop OS is [Supported](#Linux).**
* **Securely run a [Legacy OS](#Legacy).**
* **If it's greater control of your privacy you want...**
    - Use *me_cleaner*.<sup>[3](#3)</sup>

## Requirements
* Operating system: Debian Linux, or derivative.
* Software packages:

        xmlstarlet
### To install packages

        sudo apt install -y xmlstarlet

## How-to
### Installer Usage:

        -h, --help        Print this help and exit.
        -i, --install     Install deploy-VFIO to system.
        -u, --uninstall   Uninstall deploy-VFIO from system.

### Script Usage:

        -h, --help                   Print this help and exit.
        -q, --quiet                  Reduce verbosity; print only relevant questions and status statements.
        -u, --undo                   Undo changes (restore files) if script has exited early or unexpectedly.
            --ignore-distro          Ignore distribution check for Debian or Ubuntu system.

      Specify the database to reference before parsing IOMMU groups:
            --xml [filename]         Cross-reference XML file. First-time, export if VFIO is not setup. Consecutive-times, imports if VFIO is setup.
            [filename]               Reference specific file.
            --no-xml                 Skips prompt.

      Example:"
            --xml /usr/local/etc/deploy-vfio.d/parse.xml

      Specify the IOMMU groups to parse:
        -p, --parse [groups]         Parse given IOMMU groups (delimited by comma).
            all                      Select all IOMMU groups.
            no-vga                   Select all IOMMU groups without VGA devices.
            [x]                      Select IOMMU group.
            [x-y]                    Select IOMMU groups.

      Example:
            --parse no-vga,14        Select IOMMU group 14 and all non-VGA groups.
            --parse 1,14-16          Select IOMMU groups 1, 14, 15, and 16.

      Pre-setup:
        -c, --cpu                    Allocate CPU.
        -e, --evdev                  Setup a virtual KVM switch.
        -h, --hugepages [ARGS]       Create static hugepages (pages greater than 4 KiB) to allocate RAM for Guest(s).
            --skip-pre-setup         Skip execution.
            --uninstall-pre-setup    Undo all changes made by pre-setup.

      Hugepages:
            2M, 1G                   Hugepage size (2 MiB or 1 GiB).
            [x]                      Amount of Hugepages (maximum amount is total memory subtracted by 4 GiB).

      Example:
            --hugepages 1G 16        1 GiB hugepage 16   == 16 GiB allocated to hugepages.
            --hugepages 2M 8192      2 MiB hugepage 8912 == 16 GiB allocated to hugepages.

      VFIO setup:
        -m, --multiboot [ARGS]       Create multiple VFIO setups with corresponding GRUB menu entries. Specify default GRUB menu entry by VGA IOMMU group ID.
        -s, --static [ARGS]          Single VFIO setup. Specify method of setup.
            --skip-vfio-setup        Skip execution.
            --uninstall-vfio-setup   Undo an existing VFIO setup.

      Multiboot VFIO:
            [x]                      The ID of the valid excluded VGA IOMMU group.
            default                  Default menu entry excludes VFIO setup.
            first                    Prefer the first valid excluded VGA IOMMU group.
            last                     Prefer the last valid excluded VGA IOMMU group.

      Static VFIO:
            file                     Append output to system configuration files.
            grub                     Append output to GRUB; single GRUB menu entry.

      Post-setup:
            --audio-loopback         Install the audio loopback service...           Loopback audio from Guest to Host (over Line-out to Line-in).
            --auto-xorg [ARGS]       Install auto-Xorg...                            System service to find and set a valid boot VGA device for Xorg.
            --libvirt-hooks          Install recommended Libvirt hooks.
            --zram-swap [ARGS]       Create compressed swap in RAM (about 2:1)...    Reduce chances of memory exhaustion for Host.
            --skip-post-setup        Skip execution.
            --uninstall-post-setup   Undo all changes made by post-setup.

      auto-xorg:
            first  [vendor]          Find the first valid VGA device.
            last   [vendor]          Find the last valid VGA device.
            [sort] amd               Prefer AMD or ATI.
            [sort] intel             Prefer Intel.
            [sort] nvidia            Prefer NVIDIA.
            [sort] other             Prefer any other brand.

      zram-swap:
            [fraction]               Set the fraction of total available memory.
            default                  Automatically calculate the fraction of total available memory.
            force                    Force changes, even if zram-swap is allocated and in use.

      Example: (assume a Host with 32 GiB of RAM)
            --zram-swap force 1/4    Compress 8 GiB of RAM, to create 16 GiB of swap, with 16 GiB free.

## Features
### Pre-setup
* **Allocate CPU**
    - **Statically** isolate Host CPU threads before allocating to Guest(s).<sup>[4](#4)</sup>
    -  Reduces Host overhead, and improves both Host and Guest performance.
    -  If installed, the **Dynamic** *Libvirt hook* (see source) will skip its execution, to preserve the Static isolation.<sup>[9](#9)</sup>
* **Allocate RAM**
    - ***Static** Hugepages* eliminate the need to defragment Host memory (RAM) before allocating to Guest(s).<sup>[5](#5)</sup>
    - Reduces Host overhead, and improves both Host and Guest performance.
    - If skipped, setup will install the *Libvirt hook* for **Dynamic** allocation (*Transparent hugepages*).
* **Virtual KVM (Keyboard Video Mouse) switch**
    - Create a virtual Keyboard-Video-Mouse switch.
      - Allow a user to swap a group of Input devices (as a whole) between active Guest(s) and Host.
      - Use the pre-defined macro (example: *'L-CTRL' + 'R-CTRL'*).
    - Implementation is known as *Evdev (Event Devices)*.<sup>[6](#6)</sup>
    - **Disclaimer:** Guest PCI USB is good. Both implementations together is better.

### Main setup
* **Multi-boot VFIO setup**
    - Create multiple VFIO setups with corresponding GRUB menu entries.     **More flexibility.**
      - Select a GRUB menu entry with a VGA device excluded from VFIO.
      - Default menu entry is without VFIO setup.
      - Best for systems with two or more PCI [VGA](#VGA) devices, *without an integrated VGA device (iGPU)*.
    - **Disclaimer:** For best results, use *auto-Xorg*.<sup>[7](#7)</sup>
* **Static VFIO setup**
    - Single, traditional VFIO setup.                                       **Less flexibility.**
    - Specify method of setup:
        - Append output to GRUB; single GRUB menu entry.
        - Append output to system configuration files.
    - Best for systems with one or more PCI VGA device(s) *and one integrated VGA device (iGPU)*.
* **Dynamic VFIO setup *(To be added in a future release)***
    - Use Libvirt hooks to bind or unbind devices at Guest(s) start or stop.
    - Most responsibility; best for more experienced users.
    - Most flexibility; Libvirt hooks allow Host to allocate and release resources dynamically.
    - For examples, review the referenced guides. Search for *"libvirt hook vfio bind scripts"*. Google is your friend.

### Post-setup *(To be added in a future release)*
* **auto-xorg** system service to find and set a valid Host boot [VGA](#VGA) device for Xorg.<sup>[7](#7)</sup>
* **Guest Audio Capture**
    - Create an *Audio loopback* to output on the *Host* Audio device *Line-Out*.<sup>[8](#8)</sup>
      - Listen on *Host* Audio device *Line-In* (from *Guest* PCI Audio device *Line-Out*).
      - Useful for systems with multiple Audio devices.
    - For virtual implementation, see *Virtual Audio Capture*.
* **Libvirt Hooks**
    - Invoke **"hooks"** (scripts) for all or individual Guests.<sup>[9](#9)</sup>
    - Switch display input (video output) at Guest start.
    - **Dynamically** allocate CPU cores and CPU scheduler.
    - **Libvirt-nosleep** system service(s) per Guest to prevent Host sleep while Guest is active.
* **RAM as Compressed Swapfile/partition**
    - Create a compressed Swap device in Host memory, using the *lz4* algorithm *(compression ratio of about 2:1)*.
      - Reduce swapiness to existing Host swap devices.
      - Reduce chances of Host memory exhaustion (given an event of memory over-allocation).
    - Implementation is known as *zram-swap*.<sup>[10](#10)</sup>
* **Virtual Audio Capture *(To be added in a future release)***
    - Setup a virtual Audio driver for Windows that provides a discrete Audio device.
    - Implementation is known as **Scream**.<sup>[11](#11)</sup>
* **Virtual Video Capture *(To be added in a future release)***
    - Setup direct-memory-access (DMA) of a PCI VGA device output (Video and Audio) from a Guest to Host.
    - Implementation is known as **LookingGlass**.<sup>[12](#12)</sup>
    - **Disclaimer:** Only supported for Windows 7/8/10/11 Guests.

## Information
### Filenames and pathnames modified by *deploy-VFIO*:
#### Pre-setup files
- */etc/apparmor.d/local/abstractions/libvirt-qemu*
- */etc/libvirt/qemu.conf*

#### VFIO setup files
- */etc/default/grub*
- */etc/grub.d/proxifiedScripts/custom*
- */etc/initramfs-tools/modules*
- */etc/modprobe.d/pci-blacklists.conf*
- */etc/modprobe.d/vfio.conf*
- */etc/modules*

#### Post-setup paths
- */etc/libvirt/hooks/\**
- */usr/local/bin/\**
- */etc/systemd/system/\**

#### Paths for source binaries and files
- */usr/local/bin/\**
- */usr/local/etc/deploy-vfio.d\**

### VFIO?
Virtual Function I/O (Input Output), or VFIO, *is a new user-level driver framework for Linux...  With VFIO, a VM Guest can directly access hardware devices on the VM Host Server (pass-through), avoiding performance issues caused by emulation in performance critical paths.*<sup>[13](#13)</sup>

### VGA?
Throughout the script source code and documentation, the acronym *VGA* is used.

In Linux, a Video device or GPU, is listed as *VGA*, or Video Graphics Array. VGA may *refer to the computer display standard, the 15-pin D-subminiature VGA connector, or the 640×480 resolution characteristic of the VGA hardware.*<sup>[14](#14)</sup>

#### Example:

    $ lspci -nnk | grep --extended-regexp --ignore-case "vga|graphics"
    01:00.0 VGA compatible controller [0300]: NVIDIA Corporation GA104 [GeForce RTX 3070] [10de:2484] (rev a1)
    04:00.0 VGA compatible controller [0300]: Advanced Micro Devices, Inc. [AMD/ATI] Cayman PRO [Radeon HD 6950] [1002:6719]

### Linux:
| Distribution Family | Supported? | Tested Distros             |
| ------------------- | ---------- | -------------------------- |
| Arch                | No         | untested                   |
| Debian              | *Yes*      | *Debian 11, 12*            |
| Gentoo              | No         | untested                   |
| Red Hat             | No         | untested                   |
| SUSE                | No         | untested                   |

### Legacy:
| OS           | Device type    | Brand and model                         |
| ------------ | -------------- | --------------------------------------- |
| Windows 7    | Video/graphics | NVIDIA RTX 3000-series** or before      |
| Windows XP   | Video/graphics | NVIDIA GTX 900-series* or before**      |
|              |                | AMD Radeon HD 7000-series* or before**  |
| Windows 98   | Video/graphics | NVIDIA 7000-series GTX* or before       |
|              |                | any ATI model** (before AMD)            |

*\*UEFI and BIOS compatible.*

*\*\*BIOS-only.*

*If UEFI is enabled (and CSM/BIOS is disabled), BIOS-only VGA devices may not be available as Host video output; BIOS-only VGA devices may only be available explicitly for hardware passthrough.*

## References
#### 1.
<sub>Virtual machine | **[Wikipedia](https://en.wikipedia.org/wiki/Virtual_machine)**</sub>

#### 2.
<sub>Hypervisor | **[article (RedHat)](https://www.redhat.com/en/topics/virtualization/what-is-a-hypervisor)**</sub>

#### 3.
<sub>me_cleaner | **[source (GitHub)](https://github.com/corna/me_cleaner) |
[source fork (GitHub)](https://github.com/dt-zero/me_cleaner)**</sub>

#### 4.
<sub>Isolcpu | **[Arch wiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#CPU_pinning)**</sub>

#### 5.
<sub>Hugepages | **[Arch wiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Huge_memory_pages)**</sub>

#### 6.
<sub>Evdev | **[source (GitHub)](https://github.com/portellam/generate-evdev)** | **[Arch wiki](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Passing_keyboard/mouse_via_Evdev)**</sub>

#### 7.
<sub> auto-Xorg | **[source (GitHub)](https://github.com/portellam/auto-Xorg)**</sub>

#### 8.
<sub>Audio-loopback | **[source (GitHub)](https://github.com/portellam/audio-loopback)**</sub>

#### 9.
<sub>Libvirt hooks | **[source (GitHub)](https://github.com/portellam/libvirt-hooks)** | **[VFIO-Tools source (GitHub)](https://github.com/PassthroughPOST/VFIO-Tools)** |
**[libvirt-nosleep (Arch wiki)](https://wiki.archlinux.org/title/PCI_passthrough_via_OVMF#Host_lockup_if_Guest_is_left_running_during_sleep)**</sub>

#### 10.
<sub> zram-swap | **[source (GitHub)](https://github.com/foundObjects/zram-swap)** |
**[lz4 source (GitHub)](https://github.com/lz4/lz4)** |
**[package (Debian)](https://wiki.debian.org/ZRam)** |
**[package (Arch)](https://aur.archlinux.org/packages/zramswap)** |
**[benchmarks (Reddit)](https://web.archive.org/web/20220201101923/https://old.reddit.com/r/Fedora/comments/mzun99/new_zram_tuning_benchmarks/)**</sub>

#### 11.
<sub>Scream | **[source (GitHub)](https://github.com/duncanthrax/scream)** | **[guide (LookingGlass wiki)](https://looking-glass.io/wiki/Using_Scream_over_LAN)**</sub>

#### 12.
<sub>Looking Glass | **[Website](https://looking-glass.io/)** </sub>

#### 13.
<sub> VFIO | **[documentation (OpenSUSE)](https://doc.opensuse.org/documentation/leap/virtualization/html/book-virtualization/chap-virtualization-introduction.html)**</sub>

#### 14.
<sub> VGA | **[Wikipedia](https://en.wikipedia.org/wiki/Video_Graphics_Array)**</sub>

## Disclaimer:
Use at your own risk. Please review your system's specifications and resources. Check BIOS/UEFI for Virtualization support (AMD IOMMU or Intel VT-d).
