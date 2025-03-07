ARG BASE_TAG="develop"
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

# Install ROS2
RUN \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null \
    && apt update && apt install -y ros-dev-tools ros-jazzy-desktop tmux \
    && apt install -y ros-jazzy-nav2-minimal-tb4-description \
    && apt install -y ros-jazzy-nav2-minimal-tb4-sim \
    && apt install -y ros-jazzy-turtlebot4-base \
    && apt install -y ros-jazzy-turtlebot4-base-dbgsym \
    && apt install -y ros-jazzy-turtlebot4-bringup \
    && apt install -y ros-jazzy-turtlebot4-description \
    && apt install -y ros-jazzy-turtlebot4-desktop \
    && apt install -y ros-jazzy-turtlebot4-diagnostics \
    && apt install -y ros-jazzy-turtlebot4-gz-bringup \
    && apt install -y ros-jazzy-turtlebot4-gz-gui-plugins \
    && apt install -y ros-jazzy-turtlebot4-gz-gui-plugins-dbgsym \ 
    && apt install -y ros-jazzy-turtlebot4-gz-toolbox \ 
    && apt install -y ros-jazzy-turtlebot4-gz-toolbox-dbgsym \ 
    && apt install -y ros-jazzy-turtlebot4-msgs \ 
    && apt install -y ros-jazzy-turtlebot4-msgs-dbgsym \ 
    && apt install -y ros-jazzy-turtlebot4-navigation \ 
    && apt install -y ros-jazzy-turtlebot4-node \ 
    && apt install -y ros-jazzy-turtlebot4-node-dbgsym \ 
    && apt install -y ros-jazzy-turtlebot4-robot \ 
    && apt install -y ros-jazzy-turtlebot4-setup \ 
    && apt install -y ros-jazzy-turtlebot4-simulator \ 
    && apt install -y ros-jazzy-turtlebot4-tests \ 
    && apt install -y ros-jazzy-turtlebot4-viz 
   
# Userspace Runtime
ENV HOME /home/kasm-user
WORKDIR $HOME
USER 1000

CMD ["--tail-log"]
