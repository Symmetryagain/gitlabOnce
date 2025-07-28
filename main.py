import sys


class OSType:
    TYPE_MIN = 0
    IS_WINDOWS = 1
    IS_LINUX = 2
    IS_FREEBSD = 3
    IS_MACOS = 4
    TYPE_MAX = 5


def detect():
    if sys.platform.startswith('win32') or sys.platform.startswith('cygwin'):
        return OSType.IS_WINDOWS
    elif sys.platform.startswith('linux'):
        return OSType.IS_LINUX
    elif sys.platform.startswith('freebsd'):
        return OSType.IS_FREEBSD
    elif sys.platform == 'darwin':
        return OSType.IS_MACOS
    else:
        return OSType.TYPE_MAX


def build_on_windows():
    pass


def build_on_linux():
    import os
    os.system("sudo sh linux/linux_script.sh")


def build_on_macos():
    pass


def build_on_freebsd():
    pass


if __name__ == "__main__":
    res = detect()
    # print(res)
    os_names = {
        OSType.IS_WINDOWS: "Windows",
        OSType.IS_LINUX: "Linux",
        OSType.IS_FREEBSD: "FreeBSD",
        OSType.IS_MACOS: "macOS",
        OSType.TYPE_MAX: "Unknown OS"
    }
    print(f"Detected OS: {os_names[res]}")
    if res == OSType.IS_WINDOWS:
        build_on_windows()
    elif res == OSType.IS_LINUX:
        build_on_linux()
    elif res == OSType.IS_MACOS:
        build_on_macos()
    elif res == OSType.IS_FREEBSD:
        build_on_freebsd()
    else:
        print("Unsupported OS")
