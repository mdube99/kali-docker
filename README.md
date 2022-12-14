# kali-docker

A docker container running a customizable full Kali Linux distribution.

The build script lets you chose 

- which Kali Packages to install (core, default everything and so on)
- which Desktop environment to use ( xfce, kde, gnome, mate etc.). It should be noted that not all Desktop Environments work properly.

## how to build

Download all the files into a subdirectory on your linux docker host, e.g. /home/mdube/kali-linux docker
then cd into that directory and run

    sudo ./build

The build script then asks you for all the options and builds the image, creates the container
and starts it. So in a nutshell, the complete command sequence in a linux shell to install on a Debian or Ubuntu Linux would be:

    apt update
    apt install git
    git clone https://github.com/mdube99/kali-docker.git
    cd kali-linux-docker
    sudo ./build

## how to use

You can now connect to the container by launching your favourite remote access software. The default ports defined in the script are as follows:

- RDP on port 3389
- ssh on port 22

The build script will prompt you for an additional user, along with the password for that user.

## docker-compose

In the docker-compose file, you can add folders you would like persistent across your host. In the event you need to create a new image, you don't have to worry about losing/transferring files. 

You will need to change the home directories on these volumes to match the user that you will use for the image (e.g. mdube)

You will notice in the docker-compose file there is a volume for the browser. This is to store the firefox information (such as foxyproxy) for use with burpsuite. I recommend that you create a set folder for this, to ensure that your browser settings stay persistent after stopping/starting the container. 
