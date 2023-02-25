# #####################################################
# onemarcfifty/kali-linux
# #####################################################
#
# This Dockerfile will build a Kali Linux Docker 
# image with a graphical environment
#
# It takes the following build-args:
# 
#  - the Desktop environment (DESKTOP_ENVIRONMENT)
#  - the remote client you want to use (REMOTE_ACCESS)
#  - the Kali packages to install (KALI_PACKAGE)
#
# The start script is called /startkali.sh
# and it will be built dynamically by the docker build
# process
#
# #####################################################

FROM kalilinux/kali-rolling

ARG DESKTOP_ENVIRONMENT
ARG REMOTE_ACCESS
ARG KALI_PACKAGE
ARG SSH_PORT
ARG RDP_PORT
ARG USER
ARG PASS
ARG LV_BRANCH=release-1.2/neovim-0.8

ENV DEBIAN_FRONTEND noninteractive

# #####################################################
# the desktop environment to use
# if it is null then it will default to xfce
# valid choices are 
# e17, gnome, i3, i3-gaps, kde, live, lxde, mate, xfce
# #####################################################

ENV DESKTOP_ENVIRONMENT=${DESKTOP_ENVIRONMENT:-xfce}
ENV DESKTOP_PKG=kali-desktop-${DESKTOP_ENVIRONMENT}

ENV REMOTE_ACCESS=${REMOTE_ACCESS:-rdp}

# #####################################################
# the kali packages to install
# if it is null then it will default to "default"
# valid choices are arm, core, default, everything, 
# firmware, headless, labs, large, nethunter
# #####################################################

ENV KALI_PACKAGE=${KALI_PACKAGE:-default}
ENV KALI_PKG=kali-linux-${KALI_PACKAGE}

# #####################################################
# install packages that we always want
# #####################################################

RUN apt update -q --fix-missing  
RUN apt upgrade -y
RUN apt -y install --no-install-recommends sudo iputils-* vim wget curl dbus-x11 xinit ${DESKTOP_PKG}

# #####################################################
# Install the Kali Packages
# #####################################################

RUN apt -y install --no-install-recommends ${KALI_PKG}

# #####################################################
# install custom applications & settings
# #####################################################

RUN apt -y install --no-install-recommends kali-tools-top10 golang exa neovim ripgrep feh htop fzf fzy bloodhound bloodhound.py feroxbuster evolution libreoffice stow
RUN chsh -s $(which zsh)
RUN pip install git+https://github.com/blacklanternsecurity/trevorproxy
RUN pip install git+https://github.com/blacklanternsecurity/trevorspray
# scarecrow
RUN apt -y install openssl osslsigncode mingw-w64
RUN go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
RUN go install github.com/sensepost/gowitness@latest
# Havoc dependencies
RUN sudo apt install -y build-essential apt-utils cmake libfontconfig1 libglu1-mesa-dev libgtest-dev libspdlog-dev libboost-all-dev libncurses5-dev libgdbm-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev mesa-common-dev qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libqt5websockets5 libqt5websockets5-dev qtdeclarative5-dev golang-go qtbase5-dev libqt5websockets5-dev libspdlog-dev python3-dev libboost-all-dev mingw-w64 nasm
# Setup metasploit defaults
COPY msfconsole.rc /usr/share/metasploit-framework/scripts/resource/msfconsole.rc

# #####################################################
# create the start bash shell file
# #####################################################

RUN echo "#!/bin/bash" > /startkali.sh
RUN echo "/etc/init.d/ssh start" >> /startkali.sh
RUN chmod 755 /startkali.sh


# #####################################################
# create the non-root kali user
# #####################################################

RUN useradd -m -s /bin/zsh -G sudo ${USER}
RUN echo "${USER}:${PASS}" | chpasswd
RUN echo "root:${PASS}" | chpasswd

# #####################################################
# change the ssh port in /etc/ssh/sshd_config
# When you use the bridge network, then you would
# not have to do that. You could rather add a port
# mapping argument such as -p 2022:22 to the 
# docker create command. But we might as well
# use the host network and port 22 might be taken
# on the docker host. Hence we change it 
# here inside the container
# #####################################################

RUN echo "Port $SSH_PORT" >>/etc/ssh/sshd_config

# #############################
# install and configure xrdp
# #############################

RUN if [ "xrdp" = "x${REMOTE_ACCESS}" ] ; \
    then \
        apt -y install --no-install-recommends xorg xorgxrdp xrdp ; \
        echo "/etc/init.d/xrdp start" >> /startkali.sh ; \
        sed -i s/^port=3389/port=${RDP_PORT}/ /etc/xrdp/xrdp.ini ; \
    fi

# ###########################################################
# The /startkali.sh script may terminate, i.e. if we only 
# have statements inside it like /etc/init.d/xxx start
# then once the startscript has finished, the container 
# would stop. We want to keep it running though.
# therefore I just call /bin/bash at the end of the start
# script. This will not terminate and keep the container
# up and running until it is stopped.
# ###########################################################

# #############################
# Setup custom files
# #############################

# Install dependencies and LunarVim
RUN apt update && \
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
  apt update && \
  apt -y install nodejs && \
  curl -LSs https://raw.githubusercontent.com/lunarvim/lunarvim/${LV_BRANCH}/utils/installer/install-neovim-from-release | bash && \
  LV_BRANCH=${LV_BRANCH} curl -LSs https://raw.githubusercontent.com/lunarvim/lunarvim/${LV_BRANCH}/utils/installer/install.sh | bash -s -- --no-install-dependencies

RUN git clone https://github.com/mdube99/dotfiles.git /root/dotfiles
RUN pip install updog

COPY check_dotfiles.sh check_dotfiles.sh
WORKDIR "/root/dotfiles"
RUN rm -rf /root/.config/lvim
RUN rm -rf /root/.zshrc
RUN stow */

RUN echo "/bin/zsh /check_dotfiles.sh 2>/dev/null" >> /startkali.sh
RUN echo "/bin/zsh" >> /startkali.sh

# ###########################################################
# expose the right ports and set the entrypoint
# ###########################################################

EXPOSE ${SSH_PORT} ${RDP_PORT} 
WORKDIR "/root"
ENTRYPOINT ["/bin/zsh"]
CMD ["/startkali.sh"]
