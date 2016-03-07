FROM ubuntu:14.04

MAINTAINER Michal Malolepszy <michal.malolepszy@altkom.pl>

# install necessary packages
RUN apt-get update \
	&& apt-get -y --no-install-recommends install \
			clang-3.5 libcurl3 libicu52 liblldb-3.6 liblttng-ust0 libssl-dev libunwind8 \
			ca-certificates \
			libsqlite3-dev \
	&& rm -rf /var/lib/apt/lists/*

# download and install dotnet cli and libuv (libuv is required for Kestrel server to run)
# on newer ubuntu image libuv can be installed from an apt package, 
# but currently dotnet package is not compatible with newer ubuntu
# after installing clean unnecessary files & packages to save space on image
RUN mkdir /setup \
	&& apt-get update \
	&& apt-get install --no-install-recommends -y wget autoconf automake build-essential libtool \
	&& wget -P /setup https://dotnetcli.blob.core.windows.net/dotnet/beta/Installers/Latest/dotnet-ubuntu-x64.latest.deb \
	&& wget -P /setup https://github.com/libuv/libuv/archive/v1.8.0.tar.gz \
	&& dpkg -i /setup/dotnet-ubuntu-x64.latest.deb \
	&& tar -zxf /setup/v1.8.0.tar.gz -C /setup \
	&& cd /setup/libuv-1.8.0 \
	&& sh autogen.sh && ./configure && make && make install \
	&& ldconfig \
	&& cd / \
	&& apt-get -y purge autoconf automake autotools-dev build-essential cpp cpp-4.8 \
			dpkg-dev g++ g++-4.8 gcc gcc-4.8 libcloog-isl4 libdpkg-perl libgmp10 libisl10 \
  			libmpc3 libmpfr4 libsigsegv2 libtimedate-perl libtool m4 make patch wget \
  			xz-utils \
	&& apt-get -y autoremove \
	&& apt-get -y clean \
	&& rm -rf /setup \
	&& rm -rf /var/lib/apt/lists/*

# workaround for a bug when using dotnet CLI in docker environment (https://github.com/dotnet/cli/issues/1582)
ENV LTTNG_UST_REGISTER_TIMEOUT=0

# install app from github repository download ecessary npm packages and restore nugets
RUN mkdir /app && mkdir /setup \
	&& apt-get update \
	&& apt-get install --no-install-recommends -y git npm \
	&& ln -s /usr/bin/nodejs /usr/bin/node \
	&& git clone https://github.com/mmalolepszy/webcrud.git /setup/src \
	&& cd /setup/src/src/WebCRUD.vNext \
	&& dotnet restore \
	&& dotnet publish -o /app -c Release \
	&& cd / \
	&& rm -rf /setup \
	&& rm -rf /root/.nuget \
	&& apt-get purge -y gyp libc-ares-dev libc-ares2 libjs-node-uuid libpython-stdlib libv8-3.14-dev \
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
  	&& apt-get -y autoremove \
	&& apt-get -y clean \
	&& rm -rf /var/lib/apt/lists/* \

#expose a port on which application will listen
EXPOSE 5004

#when container starts restore nuget packages and start application
CMD /app/WebCRUD.vNext 
