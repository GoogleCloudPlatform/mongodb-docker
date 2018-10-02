FROM gcr.io/google-appengine/debian9:latest

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mongodb && useradd -r -g mongodb mongodb
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        gnupg dirmngr \
        jq \
        numactl \
        curl \
    && rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.10
ENV GOSU_GPG B42F6819007F00F88E364FD4036A9C25BF357DD4

RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -q -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -q -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
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
RUN mkdir /docker-entrypoint-initdb.d

ENV GPG_KEYS 9DA31620334BD75D9DCB49F368818C72E52529D4
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

ENV MONGO_MAJOR 4.0
ENV MONGO_VERSION 4.0.2
ENV MONGO_PACKAGE mongodb-org

RUN export DEBIAN_RELASE=$(cat /etc/*-release | grep PRETTY_NAME | sed  's/.*(//;s/).*//') \
    && echo "deb http://repo.mongodb.org/apt/debian $DEBIAN_RELASE/mongodb-org/$MONGO_MAJOR main" > /etc/apt/sources.list.d/mongodb-org.list

RUN set -x \
	&& apt-get update \
	&& apt-get install -y \
		${MONGO_PACKAGE}=$MONGO_VERSION \
		${MONGO_PACKAGE}-server=$MONGO_VERSION \
		${MONGO_PACKAGE}-shell=$MONGO_VERSION \
		${MONGO_PACKAGE}-mongos=$MONGO_VERSION \
		${MONGO_PACKAGE}-tools=$MONGO_VERSION \
	&& rm -rf /var/lib/apt/lists/* \
	&& rm -rf /var/lib/mongodb \
	&& mv /etc/mongod.conf /etc/mongod.conf.orig

RUN mkdir -p /data/db /data/configdb \
	&& chown -R mongodb:mongodb /data/db /data/configdb
VOLUME /data/db /data/configdb

COPY docker-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN set -ex \
    && apt-get update \
    && apt-get -y install git \
    && cd /usr/src \
    && git clone https://github.com/mongodb/mongo.git \
    && tar czf mongo.tgz mongo \
    && rm -r mongo \
    && apt-get remove -y git

ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 27017
CMD ["mongod"]

