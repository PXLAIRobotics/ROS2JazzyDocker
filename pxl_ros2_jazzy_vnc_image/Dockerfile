FROM osrf/ros:jazzy-desktop-full


USER root

# We love UTF!
ENV LANG C.UTF-8

### Envrionment config 
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Set the nvidia container runtime
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics


# Updated and add sudo
RUN apt-get update \
	&& apt-get --with-new-pkgs upgrade -y \
    && apt-get install -y sudo 

# Add user
ARG USERNAME=tigervnc

# Add user simply to avoid UID/GID clashes
RUN useradd -ms /bin/bash ${USERNAME} \
    && echo "${USERNAME}:password" | chpasswd \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

######### Customizing the software ###########

# The OSRF contianer didn't link python3 to python, causing ROS scripts to fail.
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN apt-get update && apt-get install -y mesa-utils \ 
	&& apt-get install -y iputils-ping \ 
	&& apt-get install -y apt-transport-https ca-certificates \
	&& apt-get install -y openssh-server python3-pip exuberant-ctags \
	&& apt-get install -y git vim tmux nano htop sudo curl wget gnupg2 \
	&& apt-get install -y bash-completion \
    && rm -rf /var/lib/apt/list/*

# Install ROS2
RUN apt update && apt install -y ros-dev-tools ros-jazzy-desktop \ 
    && rm -rf /var/lib/apt/list/*

# Add Desktop & TigerVNC & OpenCV
RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y \
    tigervnc-standalone-server tigervnc-common \
    ubuntu-desktop gnome-panel gnome-settings-daemon metacity nautilus gnome-terminal dbus-x11 \
    gnome-session-flashback \
    libgl1-mesa-dri mesa-utils \
    python3-opencv libopencv-dev \
    && rm -rf /var/lib/apt/list/*

# Disable GNOME Initial Setup and remove bloatware
RUN apt-get purge -y gnome-initial-setup libreoffice-* shotwell transmission-* rhythmbox* gnome-calendar \
    && apt-get autoremove -y \
    && rm -rf /etc/gnome-initial-setup

# Install Firefox (Avoiding Snap)
RUN apt-get update && apt-get install -y software-properties-common ca-certificates gnupg \
    && add-apt-repository -y ppa:mozillateam/ppa \
    && printf 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' > /etc/apt/preferences.d/mozilla-firefox \
    && mkdir -p /etc/apt/unattended-upgrades.d && printf 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";\n' > /etc/apt/unattended-upgrades.d/99mozilla-firefox \
    && apt-get update && apt-get install -y --allow-downgrades firefox \
    && rm -rf /var/lib/apt/list/*

# Install VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg \
    && install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && rm -f packages.microsoft.gpg \
    && apt-get update && apt-get install -y code \
    && rm -rf /var/lib/apt/list/*

# Install Nerd Font (Cascadia Code)
COPY CascadiaCode.zip /tmp/
RUN apt-get update && apt-get install -y unzip \
    && unzip /tmp/CascadiaCode.zip -d /usr/share/fonts/truetype/cascadia \
    && fc-cache -f -v \
    && rm /tmp/CascadiaCode.zip

# Configure gnome-terminal defaults (Green on Black, Nerd Font) and workspace settings
RUN mkdir -p /usr/share/glib-2.0/schemas/ && \
    printf '[org.gnome.Terminal.Legacy.Profile]\n\
use-theme-colors=false\n\
foreground-color="#00FF00"\n\
background-color="#000000"\n\
use-system-font=false\n\
font="CaskaydiaCove Nerd Font Mono 11"\n\
\n\
[org.gnome.mutter]\n\
dynamic-workspaces=false\n\
\n\
[org.gnome.desktop.wm.preferences]\n\
num-workspaces=1\n' > /usr/share/glib-2.0/schemas/99_gnome-terminal-defaults.gschema.override && \
    glib-compile-schemas /usr/share/glib-2.0/schemas/

# Set XDG_RUNTIME_DIR
ENV XDG_RUNTIME_DIR=/tmp/runtime-tigervnc
RUN mkdir -p $XDG_RUNTIME_DIR && chown -R ${USERNAME}:${USERNAME} $XDG_RUNTIME_DIR && chmod 700 $XDG_RUNTIME_DIR

# Adding Turtlebot4
RUN apt update && apt install -y ros-jazzy-nav2-minimal-tb4-description \
    && apt install -y ros-jazzy-nav2-minimal-tb4-sim \
    && apt install -y ros-jazzy-turtlebot4-base \
    && apt install -y ros-jazzy-turtlebot4-bringup \
    && apt install -y ros-jazzy-turtlebot4-description \
    && apt install -y ros-jazzy-turtlebot4-desktop \
    && apt install -y ros-jazzy-turtlebot4-diagnostics \
    && apt install -y ros-jazzy-turtlebot4-gz-bringup \
    && apt install -y ros-jazzy-turtlebot4-gz-gui-plugins \
    && apt install -y ros-jazzy-turtlebot4-gz-gui-plugins-dbgsym \ 
    && apt install -y ros-jazzy-turtlebot4-gz-toolbox \ 
    && apt install -y ros-jazzy-turtlebot4-msgs \  
    && apt install -y ros-jazzy-turtlebot4-navigation \ 
    && apt install -y ros-jazzy-turtlebot4-node \ 
    && apt install -y ros-jazzy-turtlebot4-robot \ 
    && apt install -y ros-jazzy-turtlebot4-setup \ 
    && apt install -y ros-jazzy-turtlebot4-simulator \ 
    && apt install -y ros-jazzy-turtlebot4-tests \ 
    && apt install -y ros-jazzy-turtlebot4-viz \
    && apt install -y ros-jazzy-topic-tools \ 
    && rm -rf /var/lib/apt/list/*

# Adding a few tools
RUN apt install -y tmux htop vim universal-ctags \
    && rm -rf /var/lib/apt/list/*

# Switching to user tigervnc
ENV HOME /home/${USERNAME}
USER ${USERNAME}
WORKDIR /home/${USERNAME}
RUN sudo usermod -a -G video ${USERNAME}

# Set PS1 to something simple if powerline-shell fails, but we'll use powerline-shell
RUN echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '" >> $HOME/.bashrc

# Install powerline-shell
RUN pip install powerline-shell --break-system-packages

# Configure .bashrc for powerline-shell
RUN echo 'function _update_ps1() {' >> $HOME/.bashrc && \
    echo '    PS1=$(powerline-shell $?)' >> $HOME/.bashrc && \
    echo '}' >> $HOME/.bashrc && \
    echo 'if [[ $TERM != linux && ! $PROMPT_COMMAND =~ _update_ps1 ]]; then' >> $HOME/.bashrc && \
    echo '    PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"' >> $HOME/.bashrc && \
    echo 'fi' >> $HOME/.bashrc

# Configure tmux
RUN mkdir -p $HOME/.tmux/plugins/tpm
RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm             \
    && git clone https://github.com/jimeh/tmux-themepack.git $HOME/.tmux-themepack    

COPY --chown=${USERNAME}:${USERNAME} ./.tmux.conf $HOME/.tmux.conf

# Pre-install tmux plugins (TPM)
RUN export TMUX_TMPDIR=/tmp && \
    bash $HOME/.tmux/plugins/tpm/bin/install_plugins || true

# Tmux doesn't load bashrc by default, it loads ~/.bash_profile 
RUN echo 'source "$HOME/.bashrc"' >> $HOME/.bash_profile 


# 7. Vim Configuration (Vundle + Plugins)
RUN mkdir -p /home/${USERNAME}/.vim/bundle \
    && git clone https://github.com/VundleVim/Vundle.vim.git /home/${USERNAME}/.vim/bundle/Vundle.vim

COPY --chown=${USERNAME}:${USERNAME} .vimrc $HOME/.vimrc

# Automatically install plugins
RUN set -x \
    && vim -E -u NONE -S $HOME/.vimrc -C "+PluginInstall" -C "+qall"; exit 0

# Add ll alias
RUN echo "alias ll='ls --color=auto -alFh'" >> $HOME/.bashrc

# Source the ROS2 installation.
RUN echo "source /opt/ros/jazzy/setup.bash" >> $HOME/.bashrc

# Adding some directories so they always exist even when they aren't mounted as volumes
RUN mkdir -p $HOME/bin $HOME/Data $HOME/ExampleCode $HOME/Projects

# Setting up a ROS workspace, so it's always present even when there isn't a mounted volume for the workspace.
ADD ./ros2_workspace.tar.gz $HOME/Projects/

# Setup VNC
RUN mkdir -p $HOME/.vnc && echo "password" | vncpasswd -f > $HOME/.vnc/passwd && chmod 600 $HOME/.vnc/passwd

# Setup xstartup
RUN echo '#!/bin/sh\n\
unset SESSION_MANAGER\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
export XDG_CURRENT_DESKTOP="GNOME-Flashback:GNOME"\n\
export GNOME_SHELL_SESSION_MODE="ubuntu"\n\
export XDG_RUNTIME_DIR=/tmp/runtime-tigervnc\n\
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup\n\
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources\n\
xsetroot -solid grey\n\
vncconfig -iconic &\n\
dbus-launch --exit-with-session gnome-session --session=gnome-flashback-metacity\n\
' > $HOME/.vnc/xstartup && chmod +x $HOME/.vnc/xstartup

# Set some decent colors if the container needs to be accessed via /bin/bash.
RUN echo LS_COLORS=$LS_COLORS:\'di=1\;33:ln=36\' >> $HOME/.bashrc \
    && echo export LS_COLORS                     >> $HOME/.bashrc \
    && echo 'alias tmux="tmux -2"'               >> $HOME/.bashrc \
    && echo 'PATH=~/bin:~/.local/bin:$PATH'      >> $HOME/.bashrc

# Source colcon
RUN echo "source /usr/share/colcon_argcomplete/hook/colcon-argcomplete.bash" >> $HOME/.bashrc
RUN echo "source ~/Projects/ros2_workspace/install/local_setup.bash"         >> $HOME/.bashrc

# Add a clean workspace function
RUN echo 'clean_and_rebuild_ros2_workspace() {'                                            >> $HOME/.bashrc && \
    echo '    CLEANUP_SCRIPT="$HOME/bin/remove_colcon_dirs_and_rebuild_in_ros2_workspace"' >> $HOME/.bashrc && \
    echo '    ROS2_SETUP="$HOME/Projects/ros2_workspace/install/setup.bash"'               >> $HOME/.bashrc && \
    echo ''                                                                                >> $HOME/.bashrc && \
    echo '    if [[ -f "$CLEANUP_SCRIPT" ]]; then'                                         >> $HOME/.bashrc && \
    echo '        echo "Executing cleanup script..."'                                      >> $HOME/.bashrc && \
    echo '        bash "$CLEANUP_SCRIPT"'                                                  >> $HOME/.bashrc && \
    echo '    else'                                                                        >> $HOME/.bashrc && \
    echo '        echo "Cleanup script not found: $CLEANUP_SCRIPT"'                        >> $HOME/.bashrc && \
    echo '    fi'                                                                          >> $HOME/.bashrc && \
    echo ''                                                                                >> $HOME/.bashrc && \
    echo '    if [[ -f "$ROS2_SETUP" ]]; then'                                             >> $HOME/.bashrc && \
    echo '        echo "Sourcing ROS2 workspace setup script..."'                          >> $HOME/.bashrc && \
    echo '        source "$ROS2_SETUP"'                                                    >> $HOME/.bashrc && \
    echo '    else'                                                                        >> $HOME/.bashrc && \
    echo '        echo "ROS2 workspace setup script not found: $ROS2_SETUP"'               >> $HOME/.bashrc && \
    echo '    fi'                                                                          >> $HOME/.bashrc && \
    echo '}'                                                                               >> $HOME/.bashrc


######### End Customizations ###########

STOPSIGNAL SIGTERM

# We need dbus setup correctly for GNOME apps to run in the VNC session
CMD sudo service ssh start && sudo service dbus start && sudo rm -rf /tmp/.X11-unix/X* && vncserver :1 -localhost no -geometry 1280x800 -depth 24 && tail -f $HOME/.vnc/*:1.log
