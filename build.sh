#!/bin/bash

set -euxo pipefail
BUILD_DIR=/tmp/src

install_buildtools() {
	echo 'deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu xenial main' | tee /etc/apt/sources.list.d/toolchain.list
	apt-key adv --keyserver keyserver.ubuntu.com --recv BA9EF27F
	apt-get update
	apt-get -y --no-install-recommends install ca-certificates git wget gcc-7 g++-7 make libc6-dev zlib1g-dev libatomic-ops-dev libssl-dev libluajit-5.1-dev libjemalloc-dev
}

get_sources() {
	git clone --verbose https://github.com/alibaba/tengine ${BUILD_DIR}/tengine
	git clone --verbose https://github.com/vozlt/nginx-module-vts ${BUILD_DIR}/nginx-module-vts
	wget -qO- https://downloads.sourceforge.net/project/pcre/pcre/8.40/pcre-8.40.tar.gz | tar xzf - -C ${BUILD_DIR}
}

build() {
	local CC=/usr/bin/gcc-7
	local CXX=/usr/bin/g++-7
	cd ${BUILD_DIR}/tengine || exit

	./configure --prefix=/opt/nginx --sbin-path=/opt/bin/nginx --conf-path=/opt/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/lock/nginx.lock --user=www-data --group=www-data --without-dso --without-procs --without-poll_module --without-select_module --without-mail_pop3_module --without-mail_imap_module --without-mail_smtp_module --without-http_ssi_module --without-http_userid_module --without-http_trim_filter_module --without-http_split_clients_module --without-http_referer_module --without-http_uwsgi_module --without-http_scgi_module --without-http_fastcgi_module --without-http_memcached_module --without-http_limit_conn_module --without-http_empty_gif_module --without-http_browser_module --without-http_upstream_dynamic_module --without-http_upstream_hash_module --without-http_upstream_ip_hash_module --without-http_upstream_consistent_hash_module --without-http-upstream-rbtree --without-http_user_agent_module --without-http_reqstat_module --without-http_footer_filter_module --with-cc-opt='-Wimplicit-fallthrough=0 -O3' --with-cpu-opt=amd64 --with-pcre --with-pcre=${BUILD_DIR}/pcre-8.40 --with-pcre-jit --with-threads --with-jemalloc --with-zlib-asm=pentium --with-libatomic --with-http_lua_module --with-http_realip_module --add-module=${BUILD_DIR}/nginx-module-vts
	nice --adjustment=-15 make --jobs $(($(getconf _NPROCESSORS_ONLN) + 1))
	mkdir -p /opt/{bin,nginx} && cp -a objs/nginx /opt/bin/nginx
}

install_buildtools
get_sources
build

find ${BUILD_DIR} -delete
