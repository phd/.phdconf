.ONESHELL:

SHELL            := /bin/bash
DIR              := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
DISTRIB_CODENAME := $(shell source /etc/lsb-release && echo $$DISTRIB_CODENAME)

define link
	[ ! -e "$(strip $(2))" -o -L "$(strip $(2))" -o -f "$(strip $(2))" ] \
		&& (chattr -i "$(strip $(2))" || true)                           \
		&& rm -rf "$(strip $(2))"                                        \
		&& ln -s -n -T --force "$(strip $(1))" "$(strip $(2))"           \
		|| true
endef

define link_with_backup
	chattr -i "$(strip $(2))~" || true
	rm -rf "$(strip $(2))~"
	[ -e "$(strip $(2))" -a ! -L "$(strip $(2))" ] \
		&& (chattr -i "$(strip $(2))" || true)     \
		&& mv "$(strip $(2))" "$(strip $(2))~"     \
		|| true
	ln -s -n -T --force "$(strip $(1))" "$(strip $(2))" || true
endef

define copy
	chattr -i "$(strip $(2))" || true
	rm -rf "$(strip $(2))"
	cp "$(strip $(1))" "$(strip $(2))" || true
endef

define copy_if_doesnt_exist
	[ ! -e "$(strip $(2))" ] && [ -e "$(strip $(1))" ] \
		&& cp "$(strip $(1))" "$(strip $(2))"          \
		|| true
endef

define mkdir
	[ -e "$(strip $(1))" ] && [ ! -d "$(strip $(1))" ] \
		&& (chattr -i "$(strip $(1))" || true)         \
		&& rm -f "$(strip $(1))"                       \
		|| true
	mkdir -p "$(strip $(1))" || true
endef

define create_immutable
	[ -e "$(strip $(1))" ] && (lsattr -d "$(strip $(1))" | grep -q -E '^[^i]+ ') \
		&& (chattr -i "$(strip $(1))" || true)                                   \
		&& rm -rf "$(strip $(1))"                                                \
		|| true
	touch "$(strip $(1))" || true
	chattr +i "$(strip $(1))" || true
endef

define append
	chattr -i "$(strip $(2))" || true
	cat "$(strip $(1))" >> "$(strip $(2))" || true
endef

define append_if_not_test
	diff "$(strip $(1)).TEST" <(grep -m 1 -f "$(strip $(1)).TEST" "$(strip $(2))") || \
		( $(call append, $(strip $(1)), $(strip $(2))) )
endef

define rm
	chattr -i "$(strip $(1))" || true
	rm -rf "$(strip $(1))"
endef

define patch_diff
	patch -s -r- -N -n -i "$(strip $(1))" "$(strip $(2))" || true
endef

define exec
	"$(strip $(1))"
endef

define systemctl_enable
	systemctl daemon-reload || true
	systemctl enable  "$(strip $(1))" || true
	systemctl restart "$(strip $(1))" || true
endef

define systemctl_disable
	systemctl daemon-reload || true
	systemctl stop    "$(strip $(1))" || true
	systemctl disable "$(strip $(1))" || true
endef

default: home

all: home root etc apt niced

home:
	$(call link                , ${DIR}                                          , ${HOME}/.phdconf                     )
	$(call link                , ${HOME}/.phdconf/.bashrc-phd                    , ${HOME}/.bashrc-phd                  )
	$(call copy_if_doesnt_exist, ${HOME}/.phdconf/copy/.bashrc-ssh               , ${HOME}/.bashrc-ssh                  )
	$(call copy_if_doesnt_exist, ${HOME}/.bash_history                           , ${HOME}/.bash_history-phd            )
	$(call append_if_not_test  , ${HOME}/.phdconf/append/.bashrc                 , ${HOME}/.bashrc                      )
	$(call link                , ${HOME}/.phdconf/.gitconfig-phd                 , ${HOME}/.gitconfig-phd               )
	$(call append_if_not_test  , ${HOME}/.phdconf/append/.gitconfig              , ${HOME}/.gitconfig                   )
	$(call link                , ${HOME}/.phdconf/.profile-phd                   , ${HOME}/.profile-phd                 )
	$(call append_if_not_test  , ${HOME}/.phdconf/append/.profile                , ${HOME}/.profile                     )
	$(call link_with_backup    , ${HOME}/.phdconf/.nanorc                        , ${HOME}/.nanorc                      )
	$(call link_with_backup    , ${HOME}/.phdconf/.inputrc                       , ${HOME}/.inputrc                     )
	$(call link_with_backup    , ${HOME}/.phdconf/.screenrc                      , ${HOME}/.screenrc                    )
	$(call link_with_backup    , ${HOME}/.phdconf/.wgetrc                        , ${HOME}/.wgetrc                      )
	$(call link_with_backup    , ${HOME}/.phdconf/.xbindkeysrc                   , ${HOME}/.xbindkeysrc                 )
	$(call link_with_backup    , ${HOME}/.phdconf/.Xmodmap                       , ${HOME}/.Xmodmap                     )
	$(call link_with_backup    , ${HOME}/.phdconf/.Xresources                    , ${HOME}/.Xresources                  )
	$(call link_with_backup    , ${HOME}/.phdconf/XTerm                          , ${HOME}/XTerm                        )
	$(call mkdir               ,                                                   ${HOME}/.config/fontconfig           )
	$(call link_with_backup    , ${HOME}/.phdconf/.config__fontconfig__fonts.conf, ${HOME}/.config/fontconfig/fonts.conf)
	$(call link_with_backup    , ${HOME}/.phdconf/.config__mpv                   , ${HOME}/.config/mpv                  )
	nano ${HOME}/.gitconfig

root:
	sudo -H make home

etc: install
ifneq ($(shell id -u), 0)
	sudo -H make $@
else
	$(call link             , ${DIR}                                                                 , /etc/.phdconf                                )
	$(call link             , /etc/.phdconf/__etc__ssh__sshd_config.d__phd                           , /etc/ssh/sshd_config.d/phd                   )
	$(call patch_diff       , /etc/.phdconf/diff/__etc__updatedb.conf.diff                           , /etc/updatedb.conf                           )
	$(call link             , /etc/.phdconf/__etc__reniced.conf                                      , /etc/reniced.conf                            )
	$(call copy             , /etc/.phdconf/copy/__etc__systemd__system__reniced.service             , /etc/systemd/system/reniced.service          )
	$(call systemctl_disable,                                                                          reniced.service                              )
	$(call rm               ,                                                                          /etc/cron.d/reniced                          )
	$(call rm               ,                                                                          /lib/systemd/system/reniced.service          )
	sudo -H crudini --set /etc/bluetooth/main.conf General Experimental true || true
endif

apt: install
ifneq ($(shell id -u), 0)
	sudo -H make $@
else
	$(call link            , ${DIR}                                                                 , /etc/.phdconf                                )
	$(call link            , /etc/.phdconf/__etc__apt__preferences.d__phd                           , /etc/apt/preferences.d/phd                   )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/phd.sources          )
	$(call link            , /etc/.phdconf/__etc__apt__sources.list.d__phd.list--${DISTRIB_CODENAME}, /etc/apt/sources.list.d/phd.list             )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/steam.list           )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/steam.sources        )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/steam-stable.list    )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/steam-stable.sources )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/steam-beta.list      )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/steam-beta.sources   )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/google-chrome.list   )
	$(call create_immutable,                                                                          /etc/apt/sources.list.d/google-chrome.sources)
	$(call exec            , /etc/.phdconf/exec/apt-key.sh                                                                                         )
endif

install:
ifneq ($(shell id -u), 0)
	sudo -H make $@
else
	sudo -H apt-get -y install crudini curl
endif

niced_install:
	sudo -H apt-get -y install git python3 forkstat
	cd
	[ -d niced ] || git clone https://github.com/phd/niced
	cd niced
	git pull --rebase
	sudo -H make install

niced_configure:
ifneq ($(shell id -u), 0)
	sudo -H make $@
else
	$(call link            , /etc/.phdconf/__etc__niced.conf, /etc/niced.conf)
	$(call systemctl_enable,                                  niced.service  )
endif

niced:
	make niced_install
	make niced_configure
