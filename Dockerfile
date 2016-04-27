FROM ubuntu:14.04

MAINTAINER Michal Malolepszy <michal.malolepszy@altkom.pl>

# Install necessary packages.
RUN apt-get -qq update \
	&& apt-get -q -y --no-install-recommends install \
			clang-3.5 libcurl3 libicu52 liblldb-3.6 liblttng-ust0 libssl-dev libunwind8 \
			ca-certificates \
			libsqlite3-dev \
	&& rm -rf /var/lib/apt/lists/*

# Download and install dotnet cli and libuv (libuv is required for Kestrel server to run).
# On newer ubuntu image libuv can be installed from an apt package, 
# but currently dotnet package is not compatible with newer ubuntu.
# After installing clean unnecessary files & packages to save space on image.
RUN mkdir /setup \
	&& apt-get -qq update \
	&& apt-get -q -y --no-install-recommends install wget autoconf automake build-essential libtool \
	&& wget -P /setup --progress=dot:mega \
		https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-host-ubuntu-x64.latest.deb \
		https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-sharedframework-ubuntu-x64.latest.deb \
		https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-sdk-ubuntu-x64.latest.deb \
	&& wget -P /setup  --progress=dot:binary https://github.com/libuv/libuv/archive/v1.8.0.tar.gz \
	&& dpkg -i \
		/setup/dotnet-host-ubuntu-x64.latest.deb \
		/setup/dotnet-sharedframework-ubuntu-x64.latest.deb \
		/setup/dotnet-sdk-ubuntu-x64.latest.deb \
	&& tar -zxf /setup/v1.8.0.tar.gz -C /setup \
	&& cd /setup/libuv-1.8.0 \
	&& sh autogen.sh && ./configure && make && make install \
	&& ldconfig \
	&& cd / \
	&& apt-get -qq -y purge autoconf automake autotools-dev build-essential cpp cpp-4.8 \
			dpkg-dev g++ g++-4.8 gcc gcc-4.8 libcloog-isl4 libdpkg-perl libgmp10 libisl10 \
  			libmpc3 libmpfr4 libsigsegv2 libtimedate-perl libtool m4 make patch wget \
  			xz-utils \
	&& apt-get -qq -y autoremove \
	&& apt-get -qq -y clean \
	&& rm -rf /setup \
	&& rm -rf /var/lib/apt/lists/*

# Workaround for a bug when using dotnet CLI in docker environment (https://github.com/dotnet/cli/issues/1582)
# NOTE: This will probably be not necessary on next release of docker (1.11.0)
ENV LTTNG_UST_REGISTER_TIMEOUT=0

# Download app from github repository, restore nugets and publish it to a directory.
# Lines 56-59 are a temporary workaround for an issue with dotnet cli: https://github.com/dotnet/cli/issues/2250
RUN mkdir /app && mkdir /setup \
	&& apt-get -qq update \
	&& apt-get -q -y --no-install-recommends install git npm \
	&& ln -s /usr/bin/nodejs /usr/bin/node \
	&& git clone https://github.com/mmalolepszy/webcrud.git /setup/webcrud \
	&& cd /setup/webcrud/src/WebCRUD.vNext \
	&& dotnet restore -v minimal \
	&& dotnet publish -o /app -c Release \
	&& cd / \
	&& rm -rf /setup \
	&& rm -rf /root/.nuget /root/.cache /root/.npm /root/.local \
	&& apt-get -qq -y purge gyp libc-ares-dev libc-ares2 libjs-node-uuid libpython-stdlib libv8-3.14-dev \
  			libv8-3.14.5 node-abbrev node-ansi node-archy node-async node-block-stream \
  			node-combined-stream node-cookie-jar node-delayed-stream node-forever-agent \
  			node-form-data node-fstream node-fstream-ignore node-github-url-from-git \
  			node-glob node-graceful-fs node-gyp node-inherits node-ini \
  			node-json-stringify-safe node-lockfile node-lru-cache node-mime \
  			node-minimatch node-mkdirp node-mute-stream node-node-uuid node-nopt \
  			node-normalize-package-data node-npmlog node-once node-osenv node-qs \
  			node-read node-read-package-json node-request node-retry node-rimraf \
  			node-semver node-sha node-sigmund node-slide node-tar node-tunnel-agent \
  			node-which nodejs nodejs-dev npm python python-minimal python-pkg-resources \
  			python2.7 python2.7-minimal git git-man libcurl3-gnutls liberror-perl \
  	&& apt-get -qq -y autoremove \
	&& apt-get -qq -y clean \
	&& rm -rf /var/lib/apt/lists/*

# Set enviroment for application.
ENV ASPNETCORE_ENVIRONMENT Production

# Expose a port on which application will listen.
EXPOSE 5004

# Setup an entrypoint for container
ENTRYPOINT /app/WebCRUD.vNext
