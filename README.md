# Gitlab Once: A Multi-Platform Gitlab Runner Build Script

**Supported OS: Windows, Linux(Debians, Redhats), FreeBSD**

This script is based on **python**. Make sure python3 is installed in your system.

Just run `python main.py` to build a gitlab runner.

When you run `python main.py`, what actually happens:

- Downloading `gitlab runner` (if not exist).
- Register a runner.

## For Windows (Only tested in Windows 10)

- Make sure this script runs in PowerShell with administrator privileges.

## For Linux

### Debians: Debian, Ubuntu, Kali, Linux Mint

- Make sure `apt` is used as package manager.

### Redhats: Fedora, CentOS 

- Make sure `yum` is used as package manager. (For some Redhats OS, `dnf` is used as package manager, make sure `yum` is aliased to `dnf`)


## For FreeBSD


