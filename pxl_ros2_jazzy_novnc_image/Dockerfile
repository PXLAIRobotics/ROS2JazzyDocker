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

ARG USERNAME=user
ARG USER_UID=1001
ARG USER_GID=1001

# Check that USER_UID is not 0 (root)
RUN if [ "$USER_UID" -eq 0 ]; then                                        \
        echo >&2 "ERROR: USER_UID cannot be 0 (root user is not allowed)" \
        exit 1;                                                           \
    fi

# Add group user and user user
RUN groupadd -g ${USER_GID} ${USERNAME} \
    && useradd -ms /bin/bash -u ${USER_UID} -g ${USER_GID} ${USERNAME} \
    && echo "${USERNAME}:${USERNAME}" | chpasswd \
    && usermod -aG sudo ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

######### Customizing the software ###########

# The OSRF contianer didn't link python3 to python, causing ROS scripts to fail.
RUN ln -s /usr/bin/python3 /usr/bin/python

RUN apt-get install -y mesa-utils \ 
	&& apt-get install -y iputils-ping \ 
	&& apt-get install -y apt-transport-https ca-certificates \
	&& apt-get install -y openssh-server python3-pip exuberant-ctags \
	&& apt-get install -y git vim tmux nano htop sudo curl wget gnupg2 \
	&& apt-get install -y bash-completion \
    && rm -rf /var/lib/apt/list/*

# Install ROS2
RUN apt update && apt install -y ros-dev-tools ros-jazzy-desktop \ 
    && rm -rf /var/lib/apt/list/*

# Adding Turtlebot4
RUN apt install -y ros-jazzy-nav2-minimal-tb4-description \
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
    && rm -rf /var/lib/apt/list/*

# Addint a few tools
RUN apt install -y tmux htop vim \
    && rm -rf /var/lib/apt/list/*

# Switching to user user
ENV HOME /home/user
USER user
WORKDIR /home/user
RUN sudo usermod -a -G video user

# Set PS1 to something simple
RUN echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '" >> $HOME/.bashrc

# Configure tmux
RUN mkdir -p $HOME/.tmux/plugins/tpm
RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm             \
    && git clone https://github.com/jimeh/tmux-themepack.git $HOME/.tmux-themepack    

COPY --chown=${USERNAME}:${USERNAME} ./.tmux.conf $HOME/.tmux.conf

# Tmux doesn't load bashrc by default, it loads ~/.bash_profile 
RUN echo 'source "$HOME/.bashrc"' >> $HOME/.bash_profile 

# Add ll alias
RUN echo "alias ll='ls --color=auto -alFh'" >> $HOME/.bashrc

# Source the ROS2 installation.
RUN echo "source /opt/ros/jazzy/setup.bash" >> $HOME/.bashrc

# Adding some directories so they always exist even when they aren't mounted as volumes
RUN mkdir -p $HOME/bin $HOME/Data $HOME/ExampleCode $HOME/Projects

# Setting up a ROS workspace, so it's always present even when there isn't a mounted volume for the workspace.
ADD ./ros2_workspace.tar.gz $HOME/Projects/

# Set some decent colors if the container needs to be accessed via /bin/bash.
RUN echo LS_COLORS=$LS_COLORS:\'di=1\;33:ln=36\' >> $HOME/.bashrc \
    && echo export LS_COLORS                     >> $HOME/.bashrc \
    && echo 'alias tmux="tmux -2"'               >> $HOME/.bashrc \
    && echo 'PATH=~/bin:$PATH'                   >> $HOME/.bashrc

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
#ARG UID=1000
#RUN chown $UID:0 $HOME
#RUN chown -R $UID:0 $HOME
#USER $UID

STOPSIGNAL SIGTERM

CMD sudo service ssh start && /bin/bash
