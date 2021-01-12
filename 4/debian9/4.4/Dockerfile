FROM marketplace.gcr.io/google/debian9

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		numactl \
		gnupg \
		dirmngr \
	&& rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10
ENV GOSU_GPG B42F6819007F00F88E364FD4036A9C25BF357DD4

RUN set -eux \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -q -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -q -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
# download source code of mongodb
	&& wget -O /usr/local/src/mongo-r4.4.3.tar.gz https://github.com/mongodb/mongo/archive/r4.4.3.tar.gz \
# copy source code
	&& wget -q -O /usr/local/src/gosu.tar.gz "https://github.com/tianon/gosu/archive/$GOSU_VERSION.tar.gz" \
# extract gosu binary and check signature
	&& export GNUPGHOME="$(mktemp -d)" \
	&& found='' && \
	for server in \
		pool.sks-keyservers.net \
		na.pool.sks-keyservers.net \
		eu.pool.sks-keyservers.net \
		oc.pool.sks-keyservers.net \
		ha.pool.sks-keyservers.net \
		hkp://p80.pool.sks-keyservers.net:80 \
		hkp://keyserver.ubuntu.com:80 \
		pgp.mit.edu \
	; do \
		gpg --keyserver $server --recv-keys $GOSU_GPG \
			&& found=yes && break; \
	done; \
	test -n "$found" \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r -f "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget

ENV GPG_KEYS 20691EEC35216C63CAF66CE1656408E390CFB1F5
RUN set -ex; \
	export GNUPGHOME="$(mktemp -d)"; \
	for key in $GPG_KEYS; do \
	found='' && \
	for server in \
		pool.sks-keyservers.net \
		na.pool.sks-keyservers.net \
		eu.pool.sks-keyservers.net \
		oc.pool.sks-keyservers.net \
		ha.pool.sks-keyservers.net \
		hkp://p80.pool.sks-keyservers.net:80 \
		hkp://keyserver.ubuntu.com:80 \
		pgp.mit.edu \
	; do \
		gpg --keyserver $server --recv-keys $key \
			&& found=yes && break; \
	done; \
	test -n "$found" \
	; done; \
	gpg --export $GPG_KEYS > /etc/apt/trusted.gpg.d/mongodb.gpg; \
	rm -r -f "$GNUPGHOME"; \
	apt-key list

ENV MONGO_MAJOR 4.4
ENV MONGO_VERSION 4.4.3
ENV MONGO_PACKAGE mongodb-org

ENV C2D_RELEASE=${MONGO_VERSION}

RUN export DEBIAN_RELASE=$(cat /etc/*-release | grep PRETTY_NAME | sed  's/.*(//;s/).*//') \
	&& echo "deb http://repo.mongodb.org/apt/debian $DEBIAN_RELASE/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
	&& apt-get update \
# starting with MongoDB 4.3, the postinst for server includes "systemctl daemon-reload" (and we don't have "systemctl")
	&& ln -s /bin/true /usr/local/bin/systemctl \
	&& apt-get install -y \
		${MONGO_PACKAGE}=$MONGO_VERSION \
		${MONGO_PACKAGE}-server=$MONGO_VERSION \
		${MONGO_PACKAGE}-shell=$MONGO_VERSION \
		${MONGO_PACKAGE}-mongos=$MONGO_VERSION \
		${MONGO_PACKAGE}-tools=$MONGO_VERSION \
	&& rm -f /usr/local/bin/systemctl \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb \
	&& mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 27017
CMD ["mongod"]

