FROM ubuntu:14.04

#install necessary packages
RUN apt-get update && \
	apt-get -y install \
		clang-3.5 libcurl3 libicu52 liblldb-3.6 liblttng-ust0 libssl-dev libunwind8 \
		libsqlite3-dev

RUN mkdir /app && mkdir /setup

# download and install dotnet cli and libuv (libuv is required for Kestrel server to run)
# on newer ubuntu image libuv can be installed from an apt package, 
# but currently dotnet package is not compatible with newer ubuntu
# after installing clean unnecessary files & packages to save space on image
RUN apt-get install -y wget autoconf automake build-essential libtool && \
	wget -P /setup https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-ubuntu-x64.latest.deb && \
	dpkg -i /setup/dotnet-ubuntu-x64.latest.deb && \
	wget -P /setup https://github.com/libuv/libuv/archive/v1.8.0.tar.gz && \
	tar -zxf /setup/v1.8.0.tar.gz -C /setup && \
	cd /setup/libuv-1.8.0 && \
	sh autogen.sh && ./configure && make && make install && ldconfig && \
	cd / && \
	apt-get -y purge autoconf automake autotools-dev build-essential cpp cpp-4.8 \
		dpkg-dev fakeroot g++ g++-4.8 gcc gcc-4.8 libalgorithm-diff-perl \
  		libalgorithm-diff-xs-perl libalgorithm-merge-perl libcloog-isl4 libdpkg-perl \
  		libfakeroot libfile-fcntllock-perl libgmp10 libisl10 libltdl-dev libltdl7 \
  		libmpc3 libmpfr4 libsigsegv2 libtimedate-perl libtool m4 make patch wget \
  		xz-utils && \
	apt-get -y autoremove && \
	apt-get -y clean && \
	rm -rf /setup

#clean unnecessary files & packages to save space on image
# RUN apt-get -y purge autoconf automake autotools-dev binfmt-support build-essential ca-certificates cpp cpp-4.8 dpkg-dev krb5-locales liblldb-3.6 libpython2.7-minimal libpython-stdlib libsasl2-modules libssl-dev libtool make manpages wget xz-utils && \
# 	apt-get -y autoremove && \
# 	apt-get -y clean && \
# 	apt-get -y autoclean && \
# 	rm -rf /var/lib/apt/lists/* && \
# 	rm -rf /setup

# WORKDIR /app

# #copy application files
# COPY src/WebCRUD.vNext .

# #copy NuGet.config pointing to nightly builds
# COPY NuGet.config .

# #workaround for a bug when using dotnet CLI in docker environment (https://github.com/dotnet/cli/issues/1582)
# ENV LTTNG_UST_REGISTER_TIMEOUT=0

# #expose a port on which application will listen
# EXPOSE 5004

# #when container starts restore nuget packages and start application
# CMD dotnet restore && dotnet run 
