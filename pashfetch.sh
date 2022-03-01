ash_version=${BASH_VERSINFO[0]:-5}
shopt -s eval_unsafe_arith &>/dev/null

sys_locale=${LANG:-C}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-${HOME}/.config}
PATH=$PATH:/usr/xpg4/bin:/usr/sbin:/sbin:/usr/etc:/usr/libexec
reset='\e[0m'
shopt -s nocasematch

LC_ALL=C
LANG=C

export GIO_EXTRA_MODULES=/usr/lib/x86_64-linux-gnu/gio/modules/

get_os() {

    case $kernel_name in

        Linux|GNU*)
            os=Linux
        ;;

        *)
            printf '%s\n' "Unknown OS detected: '$kernel_name', aborting..." >&2
            printf '%s\n' "Open an issue on GitHub to add support for your OS." >&2
            exit 1
        ;;
    esac
}

get_distro() {
    [[ $distro ]] && return

    case $os in
        Linux)
            if [ $distro == "Ubuntu"* ]]; then
                case $XDG_CONFIG_DIRS in
                    *"studio"*)   distro=${distro/Ubuntu/Ubuntu Studio} ;;
                    *"plasma"*)   distro=${distro/Ubuntu/Kubuntu} ;;
                    *"mate"*)     distro=${distro/Ubuntu/Ubuntu MATE} ;;
                    *"xubuntu"*)  distro=${distro/Ubuntu/Xubuntu} ;;
                    *"Lubuntu"*)  distro=${distro/Ubuntu/Lubuntu} ;;
                    *"budgie"*)   distro=${distro/Ubuntu/Ubuntu Budgie} ;;
                    *"cinnamon"*) distro=${distro/Ubuntu/Ubuntu Cinnamon} ;;
                esac
            fi
        ;;

get_model() {
    case $os in
        Linux)
            if [[ -d /system/app/ && -d /system/priv-app ]]; then
                model="$(getprop ro.product.brand) $(getprop ro.product.model)"

            elif [[ -f /sys/devices/virtual/dmi/id/board_vendor ||
                    -f /sys/devices/virtual/dmi/id/board_name ]]; then
                model=$(< /sys/devices/virtual/dmi/id/board_vendor)
                model+=" $(< /sys/devices/virtual/dmi/id/board_name)"

            elif [[ -f /sys/devices/virtual/dmi/id/product_name ||
                    -f /sys/devices/virtual/dmi/id/product_version ]]; then
                model=$(< /sys/devices/virtual/dmi/id/product_name)
                model+=" $(< /sys/devices/virtual/dmi/id/product_version)"

            elif [[ -f /sys/firmware/devicetree/base/model ]]; then
                model=$(< /sys/firmware/devicetree/base/model)

            elif [[ -f /tmp/sysinfo/model ]]; then
                model=$(< /tmp/sysinfo/model)
            fi
        ;;

get_title() {
    user=${USER:-$(id -un || printf %s "${HOME/*\/}")}

    case $title_fqdn in
        on) hostname=$(hostname -f) ;;
        *)  hostname=${HOSTNAME:-$(hostname)} ;;
    esac

    title=${title_color}${bold}${user}${at_color}@${title_color}${bold}${hostname}
    length=$((${#user} + ${#hostname} + 1))
}

get_kernel() {

    case $kernel_shorthand in
        on)  kernel=$kernel_version ;;
        off) kernel="$kernel_name $kernel_version" ;;
    esac
}

get_shell() {
    case $shell_path in
        on)  shell="$SHELL " ;;
        off) shell="${SHELL##*/} " ;;
    esac

    [[ $shell_version != on ]] && return

    case ${shell_name:=${SHELL##*/}} in
        bash)
            [[ $BASH_VERSION ]] ||
                BASH_VERSION=$("$SHELL" -c "printf %s \"\$BASH_VERSION\"")

            shell+=${BASH_VERSION/-*}
        ;;

        sh|ash|dash|es) ;;

        *ksh)
            shell+=$("$SHELL" -c "printf %s \"\$KSH_VERSION\"")
            shell=${shell/ * KSH}
            shell=${shell/version}
        ;;

        osh)
            if [[ $OIL_VERSION ]]; then
                shell+=$OIL_VERSION
            else
                shell+=$("$SHELL" -c "printf %s \"\$OIL_VERSION\"")
            fi
        ;;

        tcsh)
            shell+=$("$SHELL" -c "printf %s \$tcsh")
        ;;

        yash)
            shell+=$("$SHELL" --version 2>&1)
            shell=${shell/ $shell_name}
            shell=${shell/ Yet another shell}
            shell=${shell/Copyright*}
        ;;

        nu)
            shell+=$("$SHELL" -c "version | get version")
            shell=${shell/ $shell_name}
        ;;


        *)
            shell+=$("$SHELL" --version 2>&1)
            shell=${shell/ $shell_name}
        ;;
    esac

    shell=${shell/, version}
    shell=${shell/xonsh\//xonsh }
    shell=${shell/options*}
    shell=${shell/\(*\)}
}

get_de() {
    ((de_run == 1)) && return

    case $os in

        *)
            ((wm_run != 1)) && get_wm

            [[ $de == "$wm" ]] && { unset -v de; return; }
        ;;
    esac

    [[ $DISPLAY && -z $de ]] && type -p xprop &>/dev/null && \
        de=$(xprop -root | awk '/KDE_SESSION_VERSION|^_MUFFIN|xfce4|xfce5/')

    case $de in
        KDE_SESSION_VERSION*) de=KDE${de/* = } ;;
        *xfce4*)  de=Xfce4 ;;
        *xfce5*)  de=Xfce5 ;;
        *xfce*)   de=Xfce ;;
        *mate*)   de=MATE ;;
        *GNOME*)  de=GNOME ;;
        *MUFFIN*) de=Cinnamon ;;
    esac

    ((${KDE_SESSION_VERSION:-0} >= 4)) && de=${de/KDE/Plasma}

    if [[ $de_version == on && $de ]]; then
        case $de in
            Plasma*)   de_ver=$(plasmashell --version) ;;
            MATE*)     de_ver=$(mate-session --version) ;;
            Xfce*)     de_ver=$(xfce4-session --version) ;;
            GNOME*)    de_ver=$(gnome-shell --version) ;;
            Cinnamon*) de_ver=$(cinnamon --version) ;;
            Deepin*)   de_ver=$(awk -F'=' '/MajorVersion/ {print $2}' /etc/os-version) ;;
            Budgie*)   de_ver=$(budgie-desktop --version) ;;
            LXQt*)     de_ver=$(lxqt-session --version) ;;
            Lumina*)   de_ver=$(lumina-desktop --version 2>&1) ;;
            Trinity*)  de_ver=$(tde-config --version) ;;
            Unity*)    de_ver=$(unity --version) ;;
        esac

        de_ver=${de_ver/*TDE:}
        de_ver=${de_ver/tde-config*}
        de_ver=${de_ver/liblxqt*}
        de_ver=${de_ver/Copyright*}
        de_ver=${de_ver/)*}
        de_ver=${de_ver/* }
        de_ver=${de_ver//\"}

        de+=" $de_ver"
    fi

    [[ $de && $WAYLAND_DISPLAY ]] &&
        de+=" (Wayland)"

    de_run=1
}

get_wm() {
    ((wm_run == 1)) && return

    case $kernel_name in
        *OpenBSD*) ps_flags=(x -c) ;;
        *)         ps_flags=(-e) ;;
    esac

    if [[ -O "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY:-wayland-0}" ]]; then
        if tmp_pid="$(lsof -t "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY:-wayland-0}" 2>&1)" ||
           tmp_pid="$(fuser   "${XDG_RUNTIME_DIR}/${WAYLAND_DISPLAY:-wayland-0}" 2>&1)"; then
            wm="$(ps -p "${tmp_pid}" -ho comm=)"
        else
            wm=$(ps "${ps_flags[@]}" | grep -m 1 -o -F \
                               -e arcan \
                               -e asc \
                               -e clayland \
                               -e dwc \
                               -e fireplace \
                               -e gnome-shell \
                               -e greenfield \
                               -e grefsen \
                               -e hikari \
                               -e kwin \
                               -e lipstick \
                               -e maynard \
                               -e mazecompositor \
                               -e motorcar \
                               -e orbital \
                               -e orbment \
                               -e perceptia \
                               -e river \
                               -e rustland \
                               -e sway \
                               -e ulubis \
                               -e velox \
                               -e wavy \
                               -e way-cooler \
                               -e wayfire \
                               -e wayhouse \
                               -e westeros \
                               -e westford \
                               -e weston)
        fi

        [[ -z $wm ]] && type -p xprop &>/dev/null && {
            id=$(xprop -root -notype _NET_SUPPORTING_WM_CHECK)
            id=${id##* }
            wm=$(xprop -id "$id" -notype -len 100 -f _NET_WM_NAME 8t)
            wm=${wm/*WM_NAME = }
            wm=${wm/\"}
            wm=${wm/\"*}
        }

    else
                case $ps_line in
                    *chunkwm*)   wm=chunkwm ;;
                    *kwm*)       wm=Kwm ;;
                    *yabai*)     wm=yabai ;;
                    *Amethyst*)  wm=Amethyst ;;
                    *Spectacle*) wm=Spectacle ;;
                    *Rectangle*) wm=Rectangle ;;
                    *)           wm="Quartz Compositor" ;;
                esac
            ;;
        esac
    fi

    [[ $wm == *WINDOWMAKER* ]] && wm=wmaker
    [[ $wm == *GNOME*Shell* ]] && wm=Mutter

    wm_run=1
}

