#!/bin/bash

#==============================================================================
# Developer Workstation Setup Script
#
# DESCRIPTION: Post-install script for Fedora and RHEL 8 clones to create your
#              ultimate development environment
#
#      WEBSITE: https://github.com/David-Else/developer-workstation-setup-script
#
# REQUIREMENTS: Freshly installed Fedora 34+, or RHEL 8 clone installed with
#               software selection = workstation
#
#       AUTHOR: David Else
#      COMPANY: https://www.elsewebdevelopment.com/
#      VERSION: 1.0
#==============================================================================
set -euo pipefail
source /etc/os-release

GREEN=$(tput setaf 2)
BOLD=$(tput bold)
RESET=$(tput sgr0)
BIN_INSTALL_DIR=/usr/local/bin
BAT_LOCATION=https://github.com/sharkdp/bat/releases/download/v0.18.1/
BAT_FILENAME=bat-v0.18.1-x86_64-unknown-linux-gnu.tar.gz
BAT_SHA=5ccab17461d2c707dab2e917daacdabe744c8f8c1e09330c03f17b6f9a9be3d79d8a2786c5e37b1bdbdb981e9d9debfec909b4a99bf62329d6f12c1c3e8dfcb7

if [ "$(id -u)" != 0 ]; then
    echo "You're not root! Run script with sudo" && exit 1
fi

exec 2> >(tee "error_log_$(date -Iseconds).txt")

# Call with arguments (location,filename,sha)
download_verify() {
    curl -LOf "${1}${2}"
    echo "${3} ./${2}" | sha512sum --check
}

display_user_settings_and_prompt() {
    clear
    cat <<EOL
$ID $VERSION_ID detected

${BOLD}Packages to remove${RESET}
${BOLD}------------------${RESET}
RPM: ${GREEN}${rpm_packages_to_remove[*]}${RESET}

${BOLD}Packages to install${RESET}
${BOLD}-------------------${RESET}
RPM: ${GREEN}${rpm_packages_to_install[*]}${RESET}

Flathub: ${GREEN}${flathub_packages_to_install[*]}${RESET}

NPM global packages: ${GREEN}${npm_global_packages_to_install[*]}${RESET}

EOL
    read -rp "Press enter to install, or ctrl+c to quit"
}

rpm_packages_to_remove=(
    cheese
    gedit
    rhythmbox
    totem)

rpm_packages_to_install=(
    ImageMagick
    borgbackup
    chromium
    code
    ffmpeg
    fuse-exfat
    gcc-c++
    gh
    gnome-shell-extension-auto-move-windows
    gnome-tweaks
    keepassxc
    lazygit
    libva-intel-driver
    mediainfo
    mpv
    nnn
    nodejs
    optipng
    podman
    podman-docker
    stow
    thunderbird
    transmission-gtk
    xclip)

flathub_packages_to_install=(
    fr.handbrake.ghb
    org.signal.Signal
    com.axosoft.GitKraken
    com.spotify.Client)

npm_global_packages_to_install=(
    vscode-langservers-extracted
    bash-language-server
    live-server
    prettier)

#==============================================================================
# For RHEL 8 and clones (tested on 8.4)
#==============================================================================
if [[ ("$ID" == "centos" || "$ID" == "rocky" || "$ID" == "rhel" || "$ID" == "almalinux") && "${VERSION_ID%.*}" -gt 7 ]]; then

    setup_redhat_packages() {
        local rhel_rpm_packages_to_remove=(
            evolution
            firefox)

        local rhel_rpm_packages_to_install=(
            ntfs-3g
            python36-devel)

        local rhel_flathub_packages_to_install=(
            org.mozilla.firefox
            org.kde.krita
            org.gnome.Shotwell
            org.bunkus.mkvtoolnix-gui)

        rpm_packages_to_remove+=("${rhel_rpm_packages_to_remove[@]}")
        rpm_packages_to_install+=("${rhel_rpm_packages_to_install[@]}")
        flathub_packages_to_install+=("${rhel_flathub_packages_to_install[@]}")
    }

    add_redhat_repositories() {
        dnf module enable -y nodejs:14
        dnf -y config-manager --enable powertools
        dnf -y install epel-release
        dnf -y install --nogpgcheck https://mirrors.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm https://mirrors.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm
        dnf -y config-manager --add-repo https://download.opensuse.org/repositories/home:stig124:nnn/CentOS_8/home:stig124:nnn.repo
    }

    install_redhat_binaries() {
        local PANDOC_LOCATION=https://github.com/jgm/pandoc/releases/download/2.11.2/
        local PANDOC_FILENAME=pandoc-2.11.2-linux-amd64.tar.gz
        local PANDOC_SHA=9d265941f224d376514e18fc45d5292e9c2481b04693c96917a0d55ed817b190cf2ea2666097388bfdf30023db2628567ea04ff6b9cc3316130a8190da72c605
        local SHELLCHECK_LOCATION=https://github.com/koalaman/shellcheck/releases/download/v0.7.2/
        local SHELLCHECK_FILENAME=shellcheck-v0.7.2.linux.x86_64.tar.xz
        local SHELLCHECK_SHA=067e2b8ee1910218de1e62068f7cc86ed7048e97b2a9d7c475ea29ae81c17a944376ce5c240d5c783ef3251d9bee7d7d010351958314eadd0fc88b5decfd8328
        local SHFMT_LOCATION=https://github.com/mvdan/sh/releases/download/v3.2.2/
        local SHFMT_FILENAME=shfmt_v3.2.2_linux_amd64
        local SHFMT_SHA=d4e699575899f7c44dbce54f6414fb63c0527e7d743ea724cb0091417e07a353c1d156d4184580a260ca855cdf5e01cdf46b353f04cf5093eba3ffc02223f1c6
        local RIPGREP_LOCATION=https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/
        local RIPGREP_FILENAME=ripgrep-13.0.0-x86_64-unknown-linux-musl.tar.gz
        local RIPGREP_SHA=cdc18bd31019fc7b8509224c2f52b230be33dee36deea2e4db1ee8c78ace406c7cd182814d056f4ce65ee533290a674822432777b61c2b4bc8cc4a4ea107cfde

        echo -e "${BOLD}Installing binaries for RHEL clones not available in repositories...${RESET}\n"

        download_verify "$PANDOC_LOCATION" "$PANDOC_FILENAME" "$PANDOC_SHA"
        tar --no-same-owner -C $BIN_INSTALL_DIR/ -xf $PANDOC_FILENAME --no-anchored 'pandoc' --strip=2
        rm $PANDOC_FILENAME

        download_verify "$SHELLCHECK_LOCATION" "$SHELLCHECK_FILENAME" "$SHELLCHECK_SHA"
        tar --no-same-owner -C $BIN_INSTALL_DIR/ -xf $SHELLCHECK_FILENAME --no-anchored 'shellcheck' --strip=1
        rm $SHELLCHECK_FILENAME

        download_verify "$RIPGREP_LOCATION" "$RIPGREP_FILENAME" "$RIPGREP_SHA"
        tar --no-same-owner -C $BIN_INSTALL_DIR/ -xf $RIPGREP_FILENAME --no-anchored 'rg' --strip=1
        rm $RIPGREP_FILENAME

        download_verify "$SHFMT_LOCATION" "$SHFMT_FILENAME" "$SHFMT_SHA"
        chmod +x $SHFMT_FILENAME
        mv $SHFMT_FILENAME $BIN_INSTALL_DIR/shfmt
    }

    setup_redhat_packages
    display_user_settings_and_prompt
    add_redhat_repositories
    install_redhat_binaries

    #==========================================================================
    # For Fedora (tested on 34)
    #==========================================================================
elif [ "$ID" == "fedora" ]; then

    setup_fedora_packages() {
        local fedora_rpm_packages_to_remove=(
            gnome-photos)

        local fedora_rpm_packages_to_install=(
            ShellCheck
            chromium-libs-media-freeworld
            java-1.8.0-openjdk
            krita
            lshw
            mkvtoolnix-gui
            pandoc
            ripgrep
            shfmt
            shotwell
            xrandr
            zathura
            zathura-bash-completion
            zathura-pdf-mupdf
            steam
            lutris
            atom)

        rpm_packages_to_remove+=("${fedora_rpm_packages_to_remove[@]}")
        rpm_packages_to_install+=("${fedora_rpm_packages_to_install[@]}")
    }

    add_fedora_repositories() {
        dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
        dnf -y config-manager --add-repo https://download.opensuse.org/repositories/home:stig124:nnn/Fedora_34/home:stig124:nnn.repo
    }

    install_jetbrains(){
        set -e

        if [[ ! -f ~/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox ]]; then
        msg_start "Installing jetbrains Toolbox"
        URL=$(curl -s 'https://data.services.jetbrains.com//products/releases?code=TBA&latest=true&type=release' | jq -r '.TBA[0].downloads.linux.link')

        DOWNLOAD_TEMP_DIR=$(mktemp -d)

        mkdir -p "${DOWNLOAD_TEMP_DIR}"

        curl -L "${URL}" --output "${DOWNLOAD_TEMP_DIR}/toolbox.tar.gz"

        TOOLBOX_TEMP_DIR=$(mktemp -d)

        tar -C "$TOOLBOX_TEMP_DIR" -xf "${DOWNLOAD_TEMP_DIR}/toolbox.tar.gz"
        rm "${DOWNLOAD_TEMP_DIR}/toolbox.tar.gz"

        # for whatever stupid reasons bash doesn't expand the star here...
        # it automatically installs itself into ~/.local/share/JetBrains/Toolbox/
        bash -c "${TOOLBOX_TEMP_DIR}/*/jetbrains-toolbox"
        rm -rf "${TOOLBOX_TEMP_DIR}"
        msg_success "Installing jetbrains Toolbox: done."
        fi
    }

    setup_fedora_packages
    display_user_settings_and_prompt
    add_fedora_repositories
    install_jetbrains

#==============================================================================
# For Unsupported OS / RHEL or clone version <8
#==============================================================================
else
    echo "Unsupported OS or version" && exit 1
fi

#==============================================================================
# For all supported OS
#==============================================================================
add_repositories() {
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # spaces around strings ensure something like 'notnode' could not trigger 'nodejs' using [*]
    case " ${rpm_packages_to_install[*]} " in
    *' code '*)
        rpm --import https://packages.microsoft.com/keys/microsoft.asc
        sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        ;;&
    *' lazygit '*)
        dnf -y copr enable atim/lazygit
        ;;&
    *' atom '*)
        rpm --import https://packagecloud.io/AtomEditor/atom/gpgkey
        sh -c 'echo -e "[Atom]\nname=Atom Editor\nbaseurl=https://packagecloud.io/AtomEditor/atom/el/7/\$basearch\nenabled=1\ngpgcheck=0\nrepo_gpgcheck=1\ngpgkey=https://packagecloud.io/AtomEditor/atom/gpgkey" > /etc/yum.repos.d/atom.repo'
        ;;&
    *' gh '*)
        dnf -y config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        ;;
    esac
}

install() {
    echo "${BOLD}Removing unwanted programs...${RESET}"
    dnf -y remove "${rpm_packages_to_remove[@]}"

    echo "${BOLD}Updating...${RESET}"
    dnf -y --refresh upgrade

    echo "${BOLD}Installing packages...${RESET}"
    dnf -y install "${rpm_packages_to_install[@]}"

    echo "${BOLD}Installing flathub packages...${RESET}"
    flatpak install -y flathub "${flathub_packages_to_install[@]}"

    echo "${BOLD}Installing Deno...${RESET}"
    su - "$SUDO_USER" -c "curl -fsSL https://deno.land/x/install/install.sh | sh"

    download_verify "$BAT_LOCATION" "$BAT_FILENAME" "$BAT_SHA"
    tar --no-same-owner -C $BIN_INSTALL_DIR/ -xf $BAT_FILENAME --no-anchored 'bat' --strip=1
    rm $BAT_FILENAME

    echo "${BOLD}Installing Neovim 0.5 stable appimage and vim-plug...${RESET}"
    local NVIM_LOCATION=https://github.com/neovim/neovim/releases/download/v0.5.0/
    local NVIM_FILENAME=nvim.appimage
    local NVIM_SHA=cdb136d673c0d21bcc08d3a6c95e31498d304eada28b61569750c8c74b5501cddbbb82a8e0287d687af43c313574cf743bfcdff3a526151b31f00096fc048d2f
    download_verify "$NVIM_LOCATION" "$NVIM_FILENAME" "$NVIM_SHA"
    chmod +x $NVIM_FILENAME
    mv $NVIM_FILENAME $BIN_INSTALL_DIR/nvim
    su - "$SUDO_USER" -c "curl -fLo /home/$SUDO_USER/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"

    echo "${BOLD}Installing nnn terminal file manager plugins...${RESET}"
    su - "$SUDO_USER" -c "curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh"

    if command -v mpv &>/dev/null; then
        echo "${BOLD}Installing umpv script for additional MPV functionality...${RESET}"
        curl https://raw.githubusercontent.com/mpv-player/mpv/master/TOOLS/umpv -o "$BIN_INSTALL_DIR/umpv"
        chmod +x "$BIN_INSTALL_DIR/umpv"
    fi

    if command -v node &>/dev/null; then
        echo "${BOLD}Installing NPM global packages..."
        npm install -g "${npm_global_packages_to_install[@]}"
    fi
}

display_end_message() {
    cat <<EOL

${BOLD}Congratulations, everything is installed!${RESET}

For RHEL clones: ${GREEN}sudo dnf install ./abattis-cantarell-fonts-0.111-2.fc30.noarch.rpm${RESET} to upgrade 0.0.25

To install Visual Studio Code icons for the Neovim completion plugin double click the codicon.ttf file in Gnome Files

To install Python applications: ${GREEN}pip3 install --user youtube-dl trash-cli tldr${RESET}
 
You can set software to open in a certain workspace with:
${GREEN}gsettings set org.gnome.shell.extensions.auto-move-windows application-list "['thunderbird.desktop:2','org.signal.Signal.desktop:2']"${RESET}

Now use the setup script...

EOL
}

add_repositories
install
display_end_message
