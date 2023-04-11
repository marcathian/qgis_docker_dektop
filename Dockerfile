FROM ubuntu:latest
LABEL maintainer="Marcathian Alexander"

RUN apt update && apt install -y gnupg software-properties-common && apt clean
RUN apt install wget && apt clean

# encountered issue of having to configre tzdata 
RUN apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/America/St_Lucia /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# also apparent neeto to install readline
RUN apt install -y apt-utils && echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# Adding QGIS from repository
RUN wget -O /etc/apt/keyrings/qgis-archive-keyring.gpg https://download.qgis.org/downloads/qgis-archive-keyring.gpg
RUN echo "Types: deb deb-src \n\
URIs: https://qgis.org/debian \n\
Suites: $(lsb_release -cs) \n\
Architectures: amd64 \n\
Components: main \n\
Signed-By: /etc/apt/keyrings/qgis-archive-keyring.gpg" >/etc/apt/sources.list.d/qgis.sources
RUN cat /etc/apt/sources.list.d/qgis.sources
RUN apt update && apt install -y qgis qgis-plugin-grass && apt clean


# install development tols like ninja and cmake
RUN apt install -y postgresql-14-pointcloud vim libgdal-dev bash-completion libexecs-dev libunwind-dev cmake ninja-build

# Trying to compile and add pdal
RUN wget -c https://github.com/PDAL/PDAL/releases/download/2.5.2/PDAL-2.5.2-src.tar.gz -O - | tar -xz
RUN mkdir /PDAL-2.5.2-src/build
WORKDIR /PDAL-2.5.2-src/build
RUN cmake -G Ninja ..
RUN ninja && ninja install
WORKDIR /

#CMD ["/bin/bash"]


# TRYING TO INSTALL AND CONFIGURE XPRA
#RUN wget -O /etc/apt/keyrings/xpra-release.gpg https://xpra.org/dists/$(lsb_release -cs)/Release.gpg
RUN wget -O - https://xpra.org/gpg.asc | apt-key add - 
RUN echo "deb https://xpra.org/dists/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/xpra.list


RUN apt update && apt install -y xpra xvfb xterm sshfs sudo gdm3 gnome-shell gnome-session gnome-terminal fluxbox

# Add sudo to user
RUN adduser --disabled-password --gecos "VICE_User" --uid 1000 user
RUN usermod -aG sudo user
RUN echo 'ALL ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers


RUN mkdir -p /run/user/1000/xpra
RUN mkdir -p /run/xpra
RUN chown user:user /run/user/1000/xpra
RUN chown user:user /run/xpra
RUN echo "LANG=en_US.UTF-8" >> /etc/locale.conf

# set display port #
ENV DISPLAY :100

USER user
WORKDIR /home/user
EXPOSE 9876
#CMD xpra start \
#         --bind-tcp=0.0.0.0:9876 \
#         --start-child=qgis \
#         --exit-with-children=no \
#         --html=on \
#         --daemon=no \
#         --xvfb="/usr/bin/Xvfb +extension Composite -screen 0 1920x1080x24+32 -nolisten tcp -noreset" \
#         --pulseaudio=no \
#         --notifications=no \
#         --bell=no \
#         :100

CMD xpra start-desktop \
         --bind-tcp=0.0.0.0:9876 \
         --start=fluxbox \
         --html=on \
         --daemon=no \
         --xvfb="/usr/bin/Xvfb +extension Composite -screen 0 1920x1080x24+32 -nolisten tcp -noreset" \
         --pulseaudio=no \
         --notifications=no \
         --bell=no \
         :100

#CMD /bin/bash