# Copyright (c) 2012-2018 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#
# Contributors:
#   Red Hat, Inc. - initial API and implementation

FROM ubuntu:16.04

ENV LANG=en_US.UTF-8 \
    HOME=/home/user
EXPOSE 22 4403
WORKDIR /projects

RUN apt-get update && \
    apt-get -y install \
        locales \
        rsync \
        openssh-server \
        sudo \
        procps \
        wget \
        unzip \
        mc \
        ca-certificates \
        curl \
        software-properties-common \
        bash-completion && \
    mkdir /var/run/sshd && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    # Adding user to the 'root' is a workaround for https://issues.jboss.org/browse/CDK-305
    useradd -u 1000 -G users,sudo,root -d /home/user --shell /bin/bash -m user && \
    usermod -p "*" user && \
    add-apt-repository ppa:git-core/ppa && \
    apt-get update && \
    sudo apt-get install -yqq git subversion && \
    apt-get -yqq autoremove && \
    apt-get -yqq clean && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8 && \
    for f in "/home/user" "/etc/passwd" "/etc/group" "/projects"; do\
        chgrp -R 0 ${f} && \
        chmod -R g+rwX ${f}; \
    done && \
    sed -ri 's/StrictModes yes/StrictModes no/g' /etc/ssh/sshd_config

USER user

RUN cd /home/user && \
    # sed -i 's/# store-passwords = no/store-passwords = yes/g' /home/user/.subversion/servers && \
    # sed -i 's/# store-plaintext-passwords = no/store-plaintext-passwords = yes/g' /home/user/.subversion/servers && \
    # The following instructions set the right
    # permissions and scripts to allow the container
    # to be run by an arbitrary user (i.e. a user
    # that doesn't already exist in /etc/passwd)
    # Generate passwd.template
    cat /etc/passwd | sed s#user:x.*#user:x:\${USER_ID}:\${GROUP_ID}::\${HOME}:/bin/bash#g > /home/user/passwd.template && \
    # Generate group.template
    cat /etc/group | sed s#root:x:0:#root:x:0:0,\${USER_ID}:#g > /home/user/group.template

COPY ["entrypoint.sh","/home/user/entrypoint.sh"]

ENTRYPOINT ["/home/user/entrypoint.sh"]

CMD tail -f /dev/null
