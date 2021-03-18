#!/usr/bin/env bash
####################
tmoe_browser_main() {
    case "${1}" in
    --auto-install-chromium)
        AUTO_INSTALL_CHROMIUM=true
        install_chromium_browser
        ;;
    *)
        unset AUTO_INSTALL_CHROMIUM
        tmoe_browser_menu
        ;;
    esac
}
####################
ubuntu_bionic_chromium() {
    BIONIC_CHROMIUM_LIST_FILE="/etc/apt/sources.list.d/bionic-chromium.list"
    if ! grep -q '^deb.*bionic-update' "/etc/apt/sources.list"; then
        unhold_ubuntu_chromium
        case "${ARCH_TYPE}" in
        "amd64" | "i386") printf "%s\n" 'deb https://mirrors.bfsu.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse' >${BIONIC_CHROMIUM_LIST_FILE} ;;
        *) printf "%s\n" 'deb https://mirrors.bfsu.edu.cn/ubuntu-ports/ bionic-updates main restricted universe multiverse' >${BIONIC_CHROMIUM_LIST_FILE} ;;
        esac
    fi
    DEPENDENCY_01="chromium-browser/bionic-updates chromium-browser-l10n/bionic-updates chromium-codecs-ffmpeg-extra/bionic-updates"
    DEPENDENCY_02=""
}
###########
unhold_ubuntu_chromium() {
    apt-mark unhold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg chromium-codecs-ffmpeg-extra
}
#########
hold_ubuntu_chromium() {
    apt-mark hold chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg chromium-codecs-ffmpeg-extra
}
#########
ubuntu_ppa_chromium() {
    if ! grep -q 'development branch' /etc/os-release; then
        VERSION_ID=$(grep 'VERSION_ID=' /etc/os-release | cut -d '"' -f 2)
    else
        VERSION_ID=.
    fi
    PPA_REPO_URL="https://packages.tmoe.me/chromium-dev/ubuntu/pool/main/c/chromium-browser/"
    case ${ARCH_TYPE} in
    "amd64" | "arm64")
        if [ ! -e "/usr/share/doc/libva2/copyright" ]; then
            printf "%s\n" "${GREEN}eatmydata apt ${YELLOW}install -y ${BLUE}libva2${RESET}"
            apt update
            eatmydata apt install -y libva2 || apt install -y libva2
        fi
        TEMP_FOLDER="/tmp/.CHROMIUM_DEB_VAAPI_TEMP_FOLDER"
        mkdir -pv ${TEMP_FOLDER}
        cd ${TEMP_FOLDER}
        CHROMIUM_DEB_RAW_LIST=$(curl -L ${PPA_REPO_URL} | grep '\.deb' | egrep -v 'chromium-chromedriver|codecs-ffmpeg_|dbgsym_' | egrep -v "~18\.04\.1_|~16\.04\.1_|\.debian\.tar" | egrep "${ARCH_TYPE}|all\.deb" | awk -F '<a href=' '{print $2}' | cut -d '"' -f 2)

        CHROMIUM_BROWSER_VERSION="$(printf "%s\n" "${CHROMIUM_DEB_RAW_LIST}" | grep 'chromium-browser_' | grep ${ARCH_TYPE} | grep ${VERSION_ID} | tail -n 1 | cut -d '_' -f 2 | cut -d '-' -f 1)"
        CHROMIUM_BROWSER_VERSION_02="$(printf "%s\n" "${CHROMIUM_DEB_RAW_LIST}" | grep 'chromium-browser_' | grep "${CHROMIUM_BROWSER_VERSION}" | grep ${ARCH_TYPE} | grep ${VERSION_ID} | awk -F '~' '{print $NF}' | cut -d '_' -f 1 | tail -n 1)"

        CHROMIUM_BROWSER_DEB=$(printf "%s\n" "${CHROMIUM_DEB_RAW_LIST}" | grep 'chromium-browser_' | grep ${CHROMIUM_BROWSER_VERSION} | grep ${CHROMIUM_BROWSER_VERSION_02} | head -n 1)

        CHROMIUM_FFMPEG_DEB=$(printf "%s\n" "${CHROMIUM_DEB_RAW_LIST}" | grep 'chromium-codecs-ffmpeg-extra_' | grep ${CHROMIUM_BROWSER_VERSION} | grep ${CHROMIUM_BROWSER_VERSION_02} | head -n 1)
        CHROMIUM_L10N_DEB=$(printf "%s\n" "${CHROMIUM_DEB_RAW_LIST}" | grep 'chromium-browser-l10n_' | grep ${CHROMIUM_BROWSER_VERSION} | grep ${CHROMIUM_BROWSER_VERSION_02} | head -n 1)
        CHROMIUM_DEB_LIST="$(printf "%s\n%s\n%s\n" "${CHROMIUM_BROWSER_DEB}" "${CHROMIUM_FFMPEG_DEB}" "${CHROMIUM_L10N_DEB}")"

        DOWNLOAD_PPA=$(printf "%s\n" "${CHROMIUM_DEB_LIST}" | sed -E "s@(chromium.*deb)@aria2c --console-log-level=warn --no-conf --allow-overwrite=true -x 5 -s 5 -k 1M -o \1 ${PPA_REPO_URL}\1@")
        DEB_LIST_02="$(printf "%s\n" ${CHROMIUM_DEB_LIST} | sed "s@^@./@g" | sed ":a;N;s/\n/ /g;ta")"
        DEB_LIST_03=$(printf "%s\n" ${CHROMIUM_DEB_LIST} | sed -E "s@(chromium-browser)@\1-dev@g" | sed "s@^@${GREEN}Downloading ${BLUE}@g;s@\$@${RESET} ...@g")
        printf "%s\n" "${DEB_LIST_03}"
        sh -c "${DOWNLOAD_PPA}"
        case "${?}" in
        0) printf "%s\n" ${CHROMIUM_BROWSER_VERSION} >${TMOE_LINUX_DIR}/chromium-dev_version.txt ;;
        esac
        unhold_ubuntu_chromium
        dpkg -i ${DEB_LIST_02}
        cd ..
        rm -rvf ${TEMP_FOLDER}
        hold_ubuntu_chromium
        aptitude install -f -y
        #do_you_want_to_close_the_sandbox_mode
        #read_chromium_sandbox_opt
        if_you_can_not_start_chromium
        ;;
    *)
        printf "%s\n" "对于arm64和amd64架构的系统，本工具将下载deb包，而非从snap商店下载。您当前使用的是${ARCH_TYPE}架构！由于新版Ubuntu调用了snap商店的软件源来安装chromium,故请自行执行apt install chromium-browser"
        ;;
    esac
    if [[ ${AUTO_INSTALL_CHROMIUM} != true ]]; then
        press_enter_to_return
        tmoe_browser_menu
    fi
}
###############
check_ubuntu_version_and_install_chromium() {
    if egrep -q 'Focal|Bionic|Eoan Ermine|=tricia|=tina' /etc/os-release; then
        ubuntu_bionic_chromium
    else
        ubuntu_ppa_chromium
    fi
}
ubuntu_install_chromium_browser() {
    if [ $(command -v chromium-browser) ]; then
        if (whiptail --title "CHROMIUM升级与卸载" --yes-button "upgrade" --no-button "remove" --yesno "Do you want to upgrade the chromium or remove it?" 8 50); then
            printf ""
        else
            unhold_ubuntu_chromium
            apt remove chromium-browser chromium-browser-l10n chromium-codecs-ffmpeg chromium-codecs-ffmpeg-extra
            press_enter_to_return
            tmoe_browser_menu
        fi
    fi
    check_ubuntu_version_and_install_chromium
}
#########
fix_chromium_root_ubuntu_no_sandbox() {
    sed -E -i 's/(chromium-browser) %U/\1 --no-sandbox %U/g' ${APPS_LNK_DIR}/chromium-browser.desktop
    #grep 'chromium-browser' /root/.zshrc || sed -i '$ a\alias chromium="chromium-browser --no-sandbox"' /root/.zshrc
}
fix_chromium_root_alpine_no_sandbox() {
    sed -E -i 's/(chromium-browser) %U/\1 --no-sandbox %U/g' ${APPS_LNK_DIR}/chromium.desktop
    #grep 'chromium-browser' /root/.zshrc || sed -i '$ a\alias chromium="chromium-browser --no-sandbox"' /root/.zshrc
}
#####################
fix_chromium_root_no_sandbox() {
    sed -E -i 's/(chromium) %U/\1 --no-sandbox %U/g' ${APPS_LNK_DIR}/chromium.desktop
    #grep 'chromium' /root/.zshrc || sed -i '$ a\alias chromium="chromium --no-sandbox"' /root/.zshrc
}
#################
install_chromium_browser() {
    printf "%s\n" "${YELLOW}妾身就知道你没有看走眼！${RESET}"
    printf '%s\n' '要是下次见不到妾身，就关掉那个小沙盒吧！"chromium--no-sandbox"'
    printf "%s\n" "1s后将自动开始安装"
    sleep 1
    [[ -d /run/shm ]] || mkdir -pv /run/shm
    DEPENDENCY_01="chromium"
    DEPENDENCY_02="chromium-l10n"
    #chromium-chromedriver
    case "${LINUX_DISTRO}" in
    debian)
        #新版Ubuntu是从snap商店下载chromium的，为解决这一问题，将临时换源成ubuntu 18.04LTS.
        case "${DEBIAN_DISTRO}" in
        "ubuntu")
            DEPENDENCY_01="chromium-browser/bionic-updates chromium-browser-l10n/bionic-updates chromium-codecs-ffmpeg-extra/bionic-updates"
            if grep -q 'Linux Mint' /etc/issue; then
                DEPENDENCY_01="chromium-browser"
                DEPENDENCY_02=""
                #chromium-browser-l10n chromium-codecs-ffmpeg-extra
            else
                if [[ ${AUTO_INSTALL_CHROMIUM} != true ]]; then
                    ubuntu_install_chromium_browser
                else
                    check_ubuntu_version_and_install_chromium
                fi
            fi
            ;;
        esac
        ;;
    gentoo)
        dispatch-conf
        DEPENDENCY_01="www-client/chromium"
        DEPENDENCY_02=""
        #emerge -avk www-client/google-chrome-unstable
        ;;
    arch) DEPENDENCY_02="" ;;
    suse) DEPENDENCY_02="chromium-plugin-widevinecdm chromium-ffmpeg-extra" ;;
    redhat) DEPENDENCY_02="fedora-chromium-config" ;;
    alpine) DEPENDENCY_02="" ;;
    esac
    if [[ ${AUTO_INSTALL_CHROMIUM} != true ]]; then
        beta_features_quick_install
    else
        different_distro_software_install
    fi
    #####################
    case ${LINUX_DISTRO} in
    debian)
        case "${DEBIAN_DISTRO}" in
        "ubuntu")
            if [[ -e ${BIONIC_CHROMIUM_LIST_FILE} ]]; then
                rm -f ${BIONIC_CHROMIUM_LIST_FILE}
                #sed -i '$ d' "/etc/apt/sources.list"
                hold_ubuntu_chromium
                apt update
            fi
            ;;
        *)
            if [[ ! $(command -v chromium) && ! $(command -v chromium-browser) ]]; then
                ubuntu_ppa_chromium
            fi
            ;;
        esac
        ;;
    esac
    ####################
    if_you_can_not_start_chromium
    #read_chromium_sandbox_opt
}
############
if_you_can_not_start_chromium() {
    if [[ $(command -v chromium) || $(command -v chromium-browser) ]]; then
        if [[ ${AUTO_INSTALL_CHROMIUM} != true ]]; then
            if (whiptail --title "SANDBOX" --yes-button "OK" --no-button "YES" --yesno "If you can not start this app,try using chromium--no-sandbox" 8 50); then
                printf ""
            fi
        fi
        cp -f ${TMOE_TOOL_DIR}/app/lnk/bin/chromium--no-sandbox /usr/local/bin
        #do_you_want_to_close_the_sandbox_mode
        cp -vf ${TMOE_TOOL_DIR}/app/lnk/chromium-browser-no-sandbox.desktop ${APPS_LNK_DIR}
        chmod a+x -v /usr/local/bin/chromium--no-sandbox
        if [[ $(command -v update-alternatives) && -x /usr/local/bin/chromium--no-sandbox ]]; then
            update-alternatives --auto x-www-browser
            printf "%s\n" "${GREEN}update-alternatives ${YELLOW}--set x-www-browser ${BLUE}/usr/local/bin/chromium--no-sandbox${RESET}"
            update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/local/bin/chromium--no-sandbox 100
            update-alternatives --set x-www-browser /usr/local/bin/chromium--no-sandbox
        fi
        if [[ -r /usr/share/applications/chromium-browser-no-sandbox.desktop && -x /usr/local/bin/chromium--no-sandbox && $(command -v xdg-settings) ]]; then
            printf "%s\n" "${GREEN}xdg-settings ${YELLOW}get ${BLUE}default-web-browser${RESET}"
            xdg-settings get default-web-browser
            printf "%s\n" "${GREEN}xdg-settings ${YELLOW}set default-web-browser ${BLUE}chromium-browser-no-sandbox.desktop${RESET}"
            xdg-settings set default-web-browser chromium-browser-no-sandbox.desktop
        fi
    fi
}
##########
read_chromium_sandbox_opt() {
    read opt
    case $opt in
    y* | Y* | "")
        case ${LINUX_DISTRO} in
        debian)
            case "${DEBIAN_DISTRO}" in
            ubuntu) fix_chromium_root_ubuntu_no_sandbox ;;
            *) fix_chromium_root_no_sandbox ;;
            esac
            ;;
        redhat) fix_chromium_root_ubuntu_no_sandbox ;;
        alpine) fix_chromium_root_alpine_no_sandbox ;;
        *) fix_chromium_root_no_sandbox ;;
        esac
        ;;
    n* | N*)
        printf "%s\n" "skipped."
        ;;
    *)
        printf "%s\n" "Invalid choice. skipped."
        ;;
    esac
}
###############
install_firefox_esr_browser() {
    printf '%s\n' 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
    printf "%s\n" "${YELLOW} “谢谢您选择了我，我一定会比姐姐向您提供更好的上网服务的！”╰(*°▽°*)╯火狐ESR娘坚定地说道。 ${RESET}"
    printf "%s\n" "1s后将自动开始安装"
    sleep 1
    DEPENDENCY_01="firefox-esr"
    #DEPENDENCY_02="firefox-esr-l10n-zh-cn"
    case ${TMOE_MENU_LANG} in
    zh_CN.UTF-8) DEPENDENCY_02="firefox-esr-l10n-zh-cn" ;;
    zh_*.UTF-8) DEPENDENCY_02="firefox-esr-l10n-zh-tw" ;;
    ja_JP.UTF-8) DEPENDENCY_02="firefox-esr-l10n-ja" ;;
    en_*.UTF-8) DEPENDENCY_02="^firefox-esr-l10n-en" ;;
    *) DEPENDENCY_02="^firefox-esr-l10n" ;;
    esac
    case "${LINUX_DISTRO}" in
    "debian")
        case "${DEBIAN_DISTRO}" in
        "ubuntu")
            add-apt-repository -y ppa:mozillateam/ppa
            #DEPENDENCY_02="firefox-esr-locale-zh-hans ffmpeg"
            case ${TMOE_MENU_LANG} in
            zh_CN.UTF-8) DEPENDENCY_02="ffmpeg firefox-esr-locale-zh-hans" ;;
            zh_*.UTF-8) DEPENDENCY_02="ffmpeg firefox-esr-locale-zh-hant" ;;
            ja_JP.UTF-8) DEPENDENCY_02="ffmpeg firefox-esr-locale-ja" ;;
            en_*.UTF-8) DEPENDENCY_02="ffmpeg ^firefox-esr-locale-en" ;;
            *) DEPENDENCY_02="ffmpeg ^firefox-esr-locale-" ;;
            esac
            #libavcodec58
            ;;
        esac
        ;;
        #################
    "arch")
        #DEPENDENCY_02="firefox-esr-i18n-zh-cn"
        case ${TMOE_MENU_LANG} in
        zh_*.UTF-8) DEPENDENCY_02="firefox-i18n-zh-cn firefox-i18n-zh-tw" ;;
        *) unset DEPENDENCY_02 ;;
        esac
        ;;
    "gentoo")
        dispatch-conf
        DEPENDENCY_01='www-client/firefox'
        DEPENDENCY_02=""
        ;;
    "suse")
        DEPENDENCY_01="MozillaFirefox-esr"
        DEPENDENCY_02="MozillaFirefox-esr-translations-common"
        ;;
    esac
    beta_features_quick_install
    #################
    if [ ! $(command -v firefox) ] && [ ! $(command -v firefox-esr) ]; then
        printf "%s\n" "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫姐姐来代替了。${RESET}"
        printf '%s\n' 'Press Enter to install firefox.'
        do_you_want_to_continue
        install_firefox_browser
    fi
}
#####################
install_firefox_browser() {
    printf '%s\n' 'Thank you for choosing me, I will definitely do better than my sister! ╰ (* ° ▽ ° *) ╯'
    printf "%s\n" " ${YELLOW}“谢谢您选择了我，我一定会比妹妹向您提供更好的上网服务的！”╰(*°▽°*)╯火狐娘坚定地说道。${RESET}"
    printf "%s\n" "1s后将自动开始安装"
    sleep 1
    DEPENDENCY_01="firefox"
    #DEPENDENCY_02="firefox-l10n-zh-cn"
    case ${TMOE_MENU_LANG} in
    zh_CN.UTF-8) DEPENDENCY_02="firefox-l10n-zh-cn" ;;
    zh_*.UTF-8) DEPENDENCY_02="firefox-l10n-zh-tw" ;;
    ja_JP.UTF-8) DEPENDENCY_02="firefox-l10n-ja" ;;
    en_*.UTF-8) DEPENDENCY_02="^firefox-l10n-en" ;;
    *) DEPENDENCY_02="^firefox-l10n" ;;
    esac
    case "${LINUX_DISTRO}" in
    "debian")
        case "${DEBIAN_DISTRO}" in
        "ubuntu")
            #add-apt-repository -y ppa:mozillateam/firefox-next
            case ${TMOE_MENU_LANG} in
            zh_CN.UTF-8) DEPENDENCY_02="ffmpeg firefox-locale-zh-hans" ;;
            zh_*.UTF-8) DEPENDENCY_02="ffmpeg firefox-locale-zh-hant" ;;
            ja_JP.UTF-8) DEPENDENCY_02="ffmpeg firefox-locale-ja" ;;
            en_*.UTF-8) DEPENDENCY_02="ffmpeg ^firefox-locale-en" ;;
            *) DEPENDENCY_02="ffmpeg ^firefox-locale-" ;;
            esac
            ;;
        esac
        ;;
    "arch")
        case ${TMOE_MENU_LANG} in
        zh_*.UTF-8) DEPENDENCY_02="firefox-i18n-zh-cn firefox-i18n-zh-tw" ;;
        *) unset DEPENDENCY_02 ;;
        esac
        ;;
    "redhat") DEPENDENCY_02="firefox-x11" ;;
    "gentoo")
        dispatch-conf
        DEPENDENCY_01="www-client/firefox-bin"
        DEPENDENCY_02=""
        ;;
    "suse")
        DEPENDENCY_01="MozillaFirefox"
        DEPENDENCY_02="MozillaFirefox-translations-common"
        ;;
    esac
    beta_features_quick_install
    ################
    if [ ! $(command -v firefox) ]; then
        printf "%s\n" "${YELLOW}对不起，我...我真的已经尽力了ヽ(*。>Д<)o゜！您的软件源仓库里容不下我，我只好叫妹妹ESR来代替了。${RESET}"
        do_you_want_to_continue
        install_firefox_esr_browser
    fi
}
#####################
firefox_or_firefoxesr() {
    check_mozilla_fake_no_sandbox
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "Firefox" --no-button "Firefox-ESR" --yesno "I am Firefox,I have a younger sister called ESR.\n我是firefox，其实我还有个妹妹叫firefox-esr，您是选她还是选我?\n “(＃°Д°)姐姐，人家可是什么都没听你说啊！” 躲在姐姐背后的ESR瑟瑟发抖地说。\n✨请做出您的选择！ " 12 53); then
        #printf '%s\n' 'esr可怜巴巴地说道:“我也想要得到更多的爱。”  '
        #什么乱七八糟的，2333333戏份真多。
        install_firefox_browser
    else
        install_firefox_esr_browser
    fi
}
firefox_or_chromium() {
    if (whiptail --title "请从两个小可爱中里选择一个 " --yes-button "chromium" --no-button "Firefox" --yesno "建议在安装完图形界面后，再来选择哦！(　o=^•ェ•)o　┏━┓\nI am Firefox, choose me.\n我是火狐娘，选我啦！♪(^∇^*) \nI'm chrome's elder sister chromium, be sure to choose me.\n妾身乃chrome娘的姐姐chromium娘，妾身和那些妖艳的货色不一样，选择妾身就没错呢！(✿◕‿◕✿)✨\n请做出您的选择！ " 15 50); then
        chromium_browser_menu
        #printf "%s\n" "如需拖拽安装插件，则请在启动命令后加上 --enable-easy-off-store-extension-install"
    else
        firefox_or_firefoxesr
    fi
}
##############
chromium_browser_menu() {
    if (whiptail --title "CHROMIUM安装与卸载" --yes-button "install" --no-button "remove" --yesno "Do you want to install chromium or remove it?" 8 50); then
        install_chromium_browser
    else
        printf "%s\n" "${PURPLE}${TMOE_REMOVAL_COMMAND} ${BLUE}chromium chromium-l10n chromium-browser chromium-browser-10n${RESET}"
        printf "%s\n" "${PURPLE}rm -vf ${BLUE}${APPS_LNK_DIR}/chromium-browser-no-sandbox.desktop  /usr/local/bin/chromium--no-sandbox${RESET}"
        do_you_want_to_continue
        for i in chromium chromium-browser chromium-l10n chromium-browser-l10n; do
            printf "%s\n" "${PURPLE}${TMOE_REMOVAL_COMMAND} ${BLUE}${i}${RESET}"
            ${TMOE_REMOVAL_COMMAND} ${i}
        done
        rm -vf ${APPS_LNK_DIR}/chromium-browser-no-sandbox.desktop /usr/local/bin/chromium--no-sandbox
    fi
}
##############
install_vivaldi_browser() {
    REPO_URL='https://vivaldi.com/zh-hans/download/'
    THE_LATEST_DEB_URL="$(curl -L ${REPO_URL} | grep deb | sed 's@ @\n@g' | grep 'deb' | grep 'amd64' | cut -d '"' -f 2 | head -n 1)"
    case ${ARCH_TYPE} in
    amd64) ;;
    i386 | arm64 | armhf) THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@amd64.deb@${ARCH_TYPE}.deb@") ;;
    *) arch_does_not_support ;;
    esac
    case ${LINUX_DISTRO} in
    debian | arch) ;;
    redhat)
        case ${ARCH_TYPE} in
        amd64)
            #THE_LATEST_DEB_URL="$(curl -L ${REPO_URL} | grep rpm | sed 's@ @\n@g' | grep 'rpm' | grep 'x86_64' | cut -d '"' -f 2 | head -n 1)"
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@${DEPENDENCY_01}_@${DEPENDENCY_01}-@" | sed "s@_amd64.deb@.x86_64.rpm@")
            ;;
        i386)
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@${DEPENDENCY_01}_@${DEPENDENCY_01}-@" | sed "s@_amd64.deb@.i386.rpm@")
            ;;
        *) arch_does_not_support ;;
        esac
        ;;
    esac
    #) non_debian_function ;;
    THE_LATEST_DEB_FILE=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | awk -F '/' '{print $NF}')
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_DEB_FILE}" | sed 's@.deb@@' | sed "s@${DEPENDENCY_01}-@@" | sed "s@vivaldi-stable_@@")
    check_deb_version
    download_and_install_deb
    rm -v /etc/apt/sources.list.d/vivaldi.list 2>/dev/null
    cd ${APPS_LNK_DIR}
    if ! grep -q 'vivaldi-stable --no-sandbox' vivaldi-stable.desktop; then
        do_you_want_to_close_the_sandbox_mode
        do_you_want_to_continue
        sed -i 's@Exec=/usr/bin/vivaldi-stable@& --no-sandbox@g' vivaldi-stable.desktop
        cat vivaldi-stable.desktop | grep --color=auto 'no-sandbox'
    fi
}
#############
install_360_browser() {
    REPO_URL='https://aur.tuna.tsinghua.edu.cn/packages/browser360/'
    THE_LATEST_DEB_URL=$(curl -L ${REPO_URL} | grep deb | cut -d '=' -f 2 | cut -d '"' -f 2 | head -n 1)
    case ${ARCH_TYPE} in
    amd64) ;;
    arm64) THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed "s@amd64.deb@arm64.deb@") ;;
    *) arch_does_not_support ;;
    esac
    #https://down.360safe.com/gc/browser360-cn-stable_12.2.1070.0-1_amd64.deb
    #http://down.360safe.com/gc/browser360-cn-stable-10.2.1005.3-1.aarch64.rpm

    case ${LINUX_DISTRO} in
    debian | arch) ;;
    redhat)
        case ${ARCH_TYPE} in
        amd64)
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed 's@stable_@stable-@' | sed 's@12.2.1070.0-1@10.2.1005.3-1@' | sed "s@_amd64.deb@.x86_64.rpm@")
            ;;
        arm64)
            THE_LATEST_DEB_URL=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | sed 's@stable_@stable-@' | sed 's@12.2.1070.0-1@10.2.1005.3-1@' | sed "s@_arm64.deb@.aarch64.rpm@")
            ;;
        esac
        ;;
    esac
    #) non_debian_function ;;
    THE_LATEST_DEB_FILE=$(printf '%s\n' "${THE_LATEST_DEB_URL}" | awk -F '/' '{print $NF}')
    THE_LATEST_DEB_VERSION=$(printf '%s\n' "${THE_LATEST_DEB_FILE}" | sed 's@.deb@@' | sed "s@${GREP_NAME}-@@" | sed "s@${GREP_NAME}_@@")
    check_deb_version
    download_and_install_deb
}
##############
install_microsoft_edge_debian() {
    cd /tmp
    curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
    sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    sudo su -c 'printf "%s\n" "deb https://packages.microsoft.com/repos/edge stable main" >/etc/apt/sources.list.d/microsoft-edge-dev.list'
    sudo rm microsoft.gpg
    sudo apt update
    sudo apt install microsoft-edge-dev
}
install_microsoft_edge_redhat() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
    sudo mv /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge-dev.repo
    sudo dnf install microsoft-edge-dev
}
install_microsoft_edge_suse() {
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo zypper ar https://packages.microsoft.com/yumrepos/edge microsoft-edge-dev
    sudo zypper refresh
    sudo zypper install microsoft-edge-dev
}
install_microsoft_edge_arch() {
    beta_features_quick_install
}
install_microsoft_edge() {
    cat <<-'EOF'
Package: microsoft-edge-dev
Priority: optional
Section: web
Installed-Size: 301311
Maintainer: Microsoft Edge for Linux Team
Architecture: amd64
Provides: www-browser
Depends: ca-certificates, fonts-liberation, libasound2 (>= 1.0.16), libatk-bridge2.0-0 (>= 2.5.3), libatk1.0-0 (>= 2.2.0), libatomic1 (>= 4.8), libatspi2.0-0 (>= 2.9.90), libc6 (>= 2.16), libcairo2 (>= 1.6.0), libcups2 (>= 1.4.0), libdbus-1-3 (>= 1.5.12), libdrm2 (>= 2.4.38), libexpat1 (>= 2.0.1), libgbm1 (>= 8.1~0), libgcc1 (>= 1:3.0), libgdk-pixbuf2.0-0 (>= 2.22.0), libglib2.0-0 (>= 2.39.4), libgtk-3-0 (>= 3.9.10), libnspr4 (>= 2:4.9-2~), libnss3 (>= 2:3.22), libpango-1.0-0 (>= 1.14.0), libuuid1 (>= 2.16), libx11-6 (>= 2:1.4.99.1), libx11-xcb1, libxcb1 (>= 1.9.2), libxcomposite1 (>= 1:0.3-1), libxdamage1 (>= 1:1.1), libxext6, libxfixes3, libxkbcommon0 (>= 0.4.1), libxrandr2, wget, xdg-utils (>= 1.0.2)
Pre-Depends: dpkg (>= 1.14.0)
Recommends: libu2f-udev, libvulkan1
Description: The web browser from Microsoft
 Microsoft Edge is a browser that combines a minimal design with sophisticated technology to make the web faster, safer, and easier.
EOF

    printf "%s\n" "If you can not download edge browser,then go to microsoft official website."
    printf "${YELLOW}%s${RESET}\n" "https://www.microsoftedgeinsider.com/download"
    printf "%s\n" "If you are a ${RED}root user${RESET},try to run ${GREEN}microsoft-edge-dev ${PURPLE}--no-sandbox${RESET} to launch it."
    printf "${PURPLE}%s${RESET}\n" "Do you want to install microsoft-edge-dev?"
    do_you_want_to_continue
    case ${LINUX_DISTRO} in
    debian) install_microsoft_edge_debian ;;
    redhat) install_microsoft_edge_redhat ;;
    arch) install_microsoft_edge_arch ;;
    suse) install_microsoft_edge_suse ;;
    *)
        beta_features_quick_install
        printf "%s\n" "Sorry, it does not support your system."
        ;;
    esac
}
############
remove_microsoft_edge() {
    printf "${RED}%s ${BLUE}%s${RESET}\n" "${TMOE_REMOVAL_COMMAND}" "${DEPENDENCY_02}"
    do_you_want_to_continue
    ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_02}
    case ${LINUX_DISTRO} in
    debian)
        rm -vf /etc/apt/sources.list.d/microsoft-edge-dev.list
        apt update
        ;;
    redhat) rm -vf /etc/yum.repos.d/microsoft-edge-dev.repo ;;
    suse) zypper removerepo microsoft-edge-dev ;;
    *) ;;
    esac
}
##########
microsoft_edge_menu() {
    DEPENDENCY_01=''
    DEPENDENCY_02='microsoft-edge-dev'
    case ${ARCH_TYPE} in
    amd64) TMOE_TIPS_02="You are using amd64 architecture,enjoy the fun experience brought by edge." ;;
    *) TMOE_TIPS_02="You are using ${ARCH_TYPE} architecture, please switch to amd64." ;;
    esac

    if (whiptail --title "Do you want to install or remove edge?" --yes-button "install安装" --no-button "remove移除" --yesno "Microsoft Edge is a cross-platform web browser developed by Microsoft.\n${TMOE_TIPS_02}" 10 50); then
        install_microsoft_edge
    else
        remove_microsoft_edge
    fi
}
##############
tmoe_browser_menu() {
    RETURN_TO_WHERE='tmoe_browser_menu'
    RETURN_TO_MENU='tmoe_browser_menu'
    DEPENDENCY_02=""
    TMOE_APP=$(whiptail --title "Browsers" --menu \
        "Which browser do you want to install?" 0 50 0 \
        "1" "Mozilla Firefox & Google Chromium" \
        "2" "Microsoft Edge(x64,享受出色的浏览体验)" \
        "3" "Falkon(Qupzilla的前身,来自KDE,使用QtWebEngine)" \
        "4" "Vivaldi(一切皆可定制)" \
        "5" "Epiphany(GNOME默认浏览器,基于Mozilla的Gecko)" \
        "6" "Midori(轻量级,开源浏览器)" \
        "7" "360安全浏览器(arm64,x64)" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${TMOE_APP}" in
    0 | "") software_center ;;
    1)
        firefox_or_chromium
        DEPENDENCY_01=""
        ;;
    2) microsoft_edge_menu ;;
    3)
        DEPENDENCY_01="falkon"
        #restore_debian_gnu_libxcb_so
        ;;
    4)
        DEPENDENCY_01='vivaldi-stable'
        case ${LINUX_DISTRO} in
        arch)
            case ${ARCH_TYPE} in
            amd64) DEPENDENCY_01='vivaldi' ;;
            arm64) DEPENDENCY_01='vivaldi-arm64' ;;
            esac
            ;;
        esac
        GREP_NAME='vivaldi'
        OFFICIAL_URL='https://vivaldi.com/download/'
        tmoe_app_menu_01
        DEPENDENCY_01=""
        ;;
    5) DEPENDENCY_01="epiphany-browser" ;;
    6) DEPENDENCY_01="midori" ;;
    7)
        case ${LINUX_DISTRO} in
        arch) DEPENDENCY_01='browser360' ;;
        *) DEPENDENCY_01='browser360-cn-stable' ;;
        esac
        GREP_NAME='browser360-cn-stable'
        OFFICIAL_URL='https://browser.360.cn/se/linux/'
        tmoe_app_menu_01
        DEPENDENCY_01=""
        ;;
    esac
    #    5) DEPENDENCY_01="konqueror" ;;
    #    "5" "konqueror(KDE默认浏览器,支持文件管理)" \
    ##########################
    case ${DEPENDENCY_01} in
    "") ;;
    falkon) falkon_browser_menu ;;
    *) beta_features_quick_install ;;
    esac
    ##############
    press_enter_to_return
    tmoe_browser_menu
}
#############
falkon_browser_menu() {
    if (whiptail --title "FALKON安装与卸载" --yes-button "install" --no-button "remove" --yesno "Do you want to install falkon or remove it?" 8 50); then
        beta_features_quick_install
        if_you_can_not_start_falkon
    else
        printf "%s\n" "${PURPLE}${TMOE_REMOVAL_COMMAND} ${BLUE}${DEPENDENCY_01}${RESET}"
        printf "%s\n" "${PURPLE}rm -vf ${BLUE}${APPS_LNK_DIR}/org.kde.falkon-no-sandbox.desktop  /usr/local/bin/falkon--no-sandbox${RESET}"
        do_you_want_to_continue
        ${TMOE_REMOVAL_COMMAND} ${DEPENDENCY_01}
        rm -vf ${APPS_LNK_DIR}/org.kde.falkon-no-sandbox.desktop /usr/local/bin/falkon--no-sandbox
    fi
}
###############
if_you_can_not_start_falkon() {
    if (whiptail --title "SANDBOX" --yes-button "OK" --no-button "YES" --yesno "If you can not start this app,try using falkon--no-sandbox" 8 50); then
        printf ""
    fi
    cp -f ${TMOE_TOOL_DIR}/app/lnk/bin/falkon--no-sandbox /usr/local/bin
    #do_you_want_to_close_the_sandbox_mode
    cp -vf ${TMOE_TOOL_DIR}/app/lnk/org.kde.falkon-no-sandbox.desktop ${APPS_LNK_DIR}
    chmod a+x -v /usr/local/bin/falkon--no-sandbox
}
###############
tmoe_browser_main "${@}"
