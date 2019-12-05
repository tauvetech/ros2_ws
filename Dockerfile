FROM ubuntu:16.04

MAINTAINER Tauve Tauvetech <"tauvetech@gmail.com">

#RUN echo -n 'Acquire::http::Proxy "http://proxy:3128";' > /etc/apt/apt.conf
#RUN echo -n 'Acquire::httpis:Proxy "https://proxy:3128";' > /etc/apt/apt.conf

#ENV http_proxy http://proxy:3128
#ENV https_proxy https://proxy:3128


#install for ROS2:
#============
#System setup
#============

#Set Locale
#==========
#Make sure to set a locale that supports UTF-8. If you are in a minimal environment such as a Docker container, the locale may be set to something minimal like POSIX.
#The following is an example for setting locale. However, it should be fine if you’re using a different UTF-8 supported locale.
RUN apt-get update
RUN apt-get install -y locales

RUN locale-gen fr_FR fr_FR.UTF-8
RUN update-locale LC_ALL=fr_FR.UTF-8 LANG=fr_FR.UTF-8
RUN export LANG=fr_FR.UTF-8


#Add the ROS 2 apt repository
#============================
#You will need to add the ROS 2 apt repositories to your system. To do so, first authorize our GPG key with apt like this:
#RUN apt-get update
RUN apt-get install -y curl gnupg2 lsb-release
RUN curl -s https://raw.githubusercontent.com/ros/rosdistro/master/ros.asc | apt-key add -

#And then add the repository to your sources list:
RUN sh -c 'echo "deb [arch=amd64,arm64] http://packages.ros.org/ros2/ubuntu `lsb_release -cs` main" > /etc/apt/sources.list.d/ros2-latest.list'

#Install development tools and ROS tools
#=======================================
RUN apt-get update
RUN apt-get install -y \
  build-essential \
  cmake \
  git \
  python3-colcon-common-extensions \
  python3-lark-parser \
  python3-pip \
  python-rosdep \
  python3-vcstool \
  wget

# install some pip packages needed for testing
RUN python3 -m pip install -U \
  argcomplete \
  flake8 \
  flake8-blind-except \
  flake8-builtins \
  flake8-class-newline \
  flake8-comprehensions \
  flake8-deprecated \
  flake8-docstrings \
  flake8-import-order \
  flake8-quotes \
  pytest-repeat pytest-rerunfailures  pytest  pytest-cov  pytest-runner  setuptools

# install Fast-RTPS dependencies
RUN apt-get install --no-install-recommends -y libasio-dev libtinyxml2-dev

RUN mkdir -p /root/ros2_ws/src
WORKDIR /root/ros2_ws
RUN wget https://raw.githubusercontent.com/ros2/ros2/crystal/ros2.repos
RUN vcs import src < ros2.repos

#Install dependencies using rosdep¶

RUN rosdep init
RUN rosdep update
# [Ubuntu 18.04]
#rosdep install --from-paths src --ignore-src --rosdistro crystal -y --skip-keys "console_bridge fastcdr fastrtps libopensplice67 libopensplice69 rti-connext-dds-5.3.1 urdfdom_headers"
# [Ubuntu 16.04]
RUN rosdep install --from-paths src --ignore-src --rosdistro crystal -y --skip-keys "console_bridge fastcdr fastrtps libopensplice67 libopensplice69 python3-lark-parser rti-connext-dds-5.3.1 urdfdom_headers"
RUN python3 -m pip install -U lark-parser

#Install more DDS implementations (Optional)
#===========================================

#ROS 2 builds on top of DDS. It is compatible with multiple DDS or RTPS (the DDS wire protocol) vendors. The repositories you downloaded for ROS 2 includes eProsima’s Fast RTPS, which is the only bundled vendor. If you would like to use one of the other vendors you will need to install their software separately before building. The ROS 2 build will automatically build support for vendors that have been installed and sourced correctly.
#By default we include eProsima’s FastRTPS in the workspace and it is the default middleware. Detailed instructions for installing other DDS vendors are provided below.

###ADLINK OpenSplice Debian Packages built by OSRF
# For Crystal Clemmys
RUN apt-get install libopensplice69
# from packages.ros.org/ros2/ubuntu

# For Bouncy Bolson
#sudo apt install libopensplice67  # from packages.ros.org/ros2/ubuntu


###RTI Connext (version 5.3.1, amd64 only)¶
#Debian packages provided in the ROS 2 apt repositories¶

#You can install a Debian package of RTI Connext available on the ROS 2 apt repositories. You will need to accept a license from RTI.
ENV RTI_NC_LICENSE_ACCEPTED=YES
RUN apt-get install -q -y rti-connext-dds-5.3.1
# from packages.ros.org/ros2/ubuntu

ENV RTI_LICENSE_FILE=/opt/rti.com/rti_connext_dds-5.3.1/rti_license.dat

#Source the setup file to set the NDDSHOME environment variable.
WORKDIR /opt/rti.com/rti_connext_dds-5.3.1/resource/scripts
#RUN /bin/bash -c ". ./rtisetenv_x64Linux3gcc5.4.0.bash"
RUN echo ". /opt/rti.com/rti_connext_dds-5.3.1/resource/scripts/rtisetenv_x64Linux3gcc5.4.0.bash" >> /root/.bashrc
#CMD . /opt/rti.com/rti_connext_dds-5.3.1/setenv_ros2rti.bash
 
#Note: when using zsh you need to be in the directory of the script when sourcing it to have it work properly
#Now you can build as normal and support for RTI will be built as well.

#If you want to install the Connext DDS-Security plugins please refer to this page
#Official binary packages from RTI¶
#You can install the Connext 5.3.1 package for Linux provided by RTI, via options available for university, purchase or evaluation.
#After downloading, use chmod +x on the .run executable and then execute it. Note that if you’re installing to a system directory use sudo as well.
#The default location is ~/rti_connext_dds-5.3.1
#After installation, run RTI launcher and point it to your license file (obtained from RTI).
#Add the following line to your .bashrc file pointing to your copy of the license.

###export RTI_LICENSE_FILE=path/to/rti_license.dat
#Source the setup file to set the NDDSHOME environment variable.
#source ~/rti_connext_dds-5.3.1/resource/scripts/rtisetenv_x64Linux3gcc5.4.0.bash
#Now you can build as normal and support for RTI will be built as well.

WORKDIR /root/ros2_ws
RUN colcon build --symlink-install --packages-ignore qt_gui_cpp rqt_gui_cpp
