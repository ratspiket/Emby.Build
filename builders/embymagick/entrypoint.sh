#!/bin/bash

USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}
BUILD_USER=${BUILD_USER:-build_user}

create_user() {
  # ensure home directory is owned by user
  # and that the profile files exist
  if [[ -d /home/${BUILD_USER} ]]; then
    chown ${USER_UID}:${USER_GID} /home/${BUILD_USER}
    # copy user files from /etc/skel
    cp /etc/skel/.bashrc /home/${BUILD_USER}
    cp /etc/skel/.bash_logout /home/${BUILD_USER}
    cp /etc/skel/.profile /home/${BUILD_USER}
    chown ${USER_UID}:${USER_GID} \
    /home/${BUILD_USER}/.bashrc \
    /home/${BUILD_USER}/.profile \
    /home/${BUILD_USER}/.bash_logout
  fi
  # create group with USER_GID
  if ! getent group ${BUILD_USER} >/dev/null; then
    groupadd -f -g ${USER_GID} ${BUILD_USER} > /dev/null 2>&1
  fi
  # create user with USER_UID
  if ! getent passwd ${BUILD_USER} >/dev/null; then
    adduser --disabled-login --uid ${USER_UID} --gid ${USER_GID} \
      --gecos 'Containerized App User' ${BUILD_USER} > /dev/null 2>&1
  fi
}

build() {
  local PACKAGE_NAME=$1
  prep_debfiles
  echo "Building imagemagick..."
  sudo  --preserve-env -u $BUILD_USER /var/cache/scripts/debbuild.sh $PACKAGE_NAME
  echo "Package was built successfully."
  sudo  --preserve-env -u $BUILD_USER /var/cache/scripts/deliver_deb.sh
}

prep_debfiles() {
  # make sure $BUILD_USER owns files
  mkdir -p /var/cache/buildarea/imagemagick-source
	chown -R $USER_UID:$USER_GID /var/cache/buildarea
	chown -R $USER_UID:$USER_GID /var/cache/imagemagick-source
	chown -R $USER_UID:$USER_GID /var/cache/source
}

PACKAGE_NAME=$1
create_user
case "$PACKAGE_NAME" in
  embymagick)
    build $PACKAGE_NAME
    ;;
  *)
    exec $@
    ;;
esac
