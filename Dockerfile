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
#  - ports to use for VNC, SSH, RDP 
#    (RDP_PORT, VNC_DISPLAY, VNC_PORT, SSH_PORT)
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
# install custom applications & settings
# #####################################################

RUN apt -y install --no-install-recommends kali-tools-top10 exa neovim ripgrep feh htop fzf bloodhound bloodhound.py feroxbuster evolution libreoffice

# #####################################################
# create the start bash shell file
# #####################################################

RUN echo "#!/bin/bash" > /startkali.sh
RUN echo "/etc/init.d/ssh start" >> /startkali.sh
RUN chmod 755 /startkali.sh

# #####################################################
# Install the Kali Packages
# #####################################################

RUN apt -y install --no-install-recommends ${KALI_PKG}

# #####################################################
# create the non-root kali user
# #####################################################

RUN useradd -m -s /bin/bash -G sudo mdube
RUN echo "${USER}:${PASS}" | chpasswd

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

RUN mkdir /home/mdube/dotfiles
RUN git clone https://github.com/mdube99/dotfiles.git /home/mdube/dotfiles
RUN chown mdube /home/mdube/dotfiles/* -R
RUN echo "source /home/mdube/dotfiles/zsh/zshrc.sh" >> /home/mdube/.zshrc
RUN echo "source-file /home/mdube/dotfiles/tmux/tmux.conf" >> /home/mdube/.tmux.conf
RUN git clone https://github.com/mdube99/lvim.git /home/mdube/.config/lvim
RUN pip install git+https://github.com/blacklanternsecurity/trevorproxy
RUN pip install updog


RUN echo "/bin/zsh" >> /startkali.sh

# ###########################################################
# expose the right ports and set the entrypoint
# ###########################################################

EXPOSE ${SSH_PORT} ${RDP_PORT} 
WORKDIR "/root"
ENTRYPOINT ["/bin/zsh"]
CMD ["/startkali.sh"]
