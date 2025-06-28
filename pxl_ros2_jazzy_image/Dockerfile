# This Dockerfile includes portions of code from Kasm Technologies Inc,
# which is licensed under the MIT License (see 'pxl_ros2_jazzy_image/src/LICENSE.md').
# Additional modifications have been made by PXL University of Applied Sciences and Arts.

ARG BASE_TAG="1.16.1"
ARG BASE_IMAGE="core-ubuntu-noble"
FROM kasmweb/$BASE_IMAGE:$BASE_TAG

USER root

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
WORKDIR $HOME

### Envrionment config 
ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=$STARTUPDIR/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=$STARTUPDIR/install \
    INST_SCRIPTS="/ubuntu/install/tools/install_tools_deluxe.sh \
                  /ubuntu/install/misc/install_tools.sh \
                  /ubuntu/install/chrome/install_chrome.sh \
                  /ubuntu/install/firefox/install_firefox.sh \
                  /ubuntu/install/vs_code/install_vs_code.sh \
                  /ubuntu/install/gimp/install_gimp.sh \
                  /ubuntu/install/gamepad_utils/install_gamepad_utils.sh \
                  /ubuntu/install/cleanup/cleanup.sh"

# updated and add sudo
RUN apt-get update \
    && apt-get install -y sudo \
    && echo 'kasm-user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && rm -rf /var/lib/apt/list/*

# Copy install scripts
COPY ./src/ $INST_DIR

# Run installations
RUN \
  for SCRIPT in $INST_SCRIPTS; do \
    bash ${INST_DIR}${SCRIPT} || exit 1; \
  done && \
  $STARTUPDIR/set_user_permission.sh $HOME && \
  rm -f /etc/X11/xinit/Xclients && \
  chown 1000:0 $HOME && \
  mkdir -p /home/kasm-user && \
  chown -R 1000:0 /home/kasm-user && \
  rm -Rf ${INST_DIR}


######### Customize Container Here ###########


# Install ROS2
RUN \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt update && apt install -y ros-dev-tools ros-jazzy-desktop \
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
    && apt install -y ros-jazzy-topic-tools \ 
    && rm -rf /var/lib/apt/list/*

# Addint a few tools
RUN apt install -y tmux htop vim \
    && rm -rf /var/lib/apt/list/*

# Change XFCE workspaces to one
RUN sed -i '/<property name="workspace_count"/s/value="4"/value="1"/' $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml 

# Set PS1 to something simple
RUN echo "PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\W\[\033[00m\]\$ '" >> $HOME/.bashrc

# Configure tmux
RUN mkdir -p $HOME/.tmux/plugins/tpm
RUN git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm             \
    && git clone https://github.com/jimeh/tmux-themepack.git $HOME/.tmux-themepack    

COPY ./.tmux.conf $HOME/.tmux.conf

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
ARG UID=1000
RUN chown $UID:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R $UID:0 $HOME

USER $UID

CMD ["--tail-log"]
