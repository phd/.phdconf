.ONESHELL:

SHELL := /bin/bash
DIR   := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

define link
	rm -f "$(strip $(2))"
	ln -s --force "$(strip $(1))" "$(strip $(2))" || true
endef

define link_with_backup
	[ -L "$(strip $(2))" -o ! -e "$(strip $(2))" ] \
		&& rm -f "$(strip $(2))"                   \
		|| mv "$(strip $(2))" "$(strip $(2))~"     \
		|| true
	ln -s --force "$(strip $(1))" "$(strip $(2))" || true
endef

define copy_if_doesnt_exist
	[ ! -e "$(strip $(2))" ] && [ -e "$(strip $(1))" ] && cp "$(strip $(1))" "$(strip $(2))" || true
endef

define append
	cat "$(strip $(1))" >> "$(strip $(2))" || true
endef

define append_if_not_test
	diff "$(strip $(1)).TEST" <(grep -m 1 -f "$(strip $(1)).TEST" "$(strip $(2))") || \
		( $(call append, $(strip $(1)), $(strip $(2))) )
endef

all: home root etc

home:
	$(call link                , ${DIR}                                , ${HOME}/.phdconf                     )
	$(call link                , ${DIR}/.bashrc-phd                    , ${HOME}/.bashrc-phd                  )
	$(call copy_if_doesnt_exist, ${DIR}/copy/.bashrc-ssh               , ${HOME}/.bashrc-ssh                  )
	$(call copy_if_doesnt_exist, ${HOME}/.bash_history                 , ${HOME}/.bash_history-phd            )
	$(call append_if_not_test  , ${DIR}/append/.bashrc                 , ${HOME}/.bashrc                      )
	$(call link                , ${DIR}/.gitconfig-phd                 , ${HOME}/.gitconfig-phd               )
	$(call append_if_not_test  , ${DIR}/append/.gitconfig              , ${HOME}/.gitconfig                   )
	$(call link                , ${DIR}/.profile-phd                   , ${HOME}/.profile-phd                 )
	$(call append_if_not_test  , ${DIR}/append/.profile                , ${HOME}/.profile                     )
	$(call link_with_backup    , ${DIR}/.nanorc                        , ${HOME}/.nanorc                      )
	$(call link_with_backup    , ${DIR}/.inputrc                       , ${HOME}/.inputrc                     )
	$(call link_with_backup    , ${DIR}/.screenrc                      , ${HOME}/.screenrc                    )
	$(call link_with_backup    , ${DIR}/.wgetrc                        , ${HOME}/.wgetrc                      )
	$(call link_with_backup    , ${DIR}/.xbindkeysrc                   , ${HOME}/.xbindkeysrc                 )
	$(call link_with_backup    , ${DIR}/.Xresources                    , ${HOME}/.Xresources                  )
	$(call link_with_backup    , ${DIR}/XTerm                          , ${HOME}/XTerm                        )
	mkdir -p ${HOME}/.config/fontconfig
	$(call link_with_backup    , ${DIR}/.config--fontconfig--fonts.conf, ${HOME}/.config/fontconfig/fonts.conf)
	$(call link_with_backup    , ${DIR}/.config--mpv                   , ${HOME}/.config/mpv                  )
	nano ${HOME}/.gitconfig

root:
	sudo make home

etc:
ifneq ($(shell id -u), 0)
	sudo make $@
else
	$(call link, ${DIR}/--etc--apt--preferences.d--phd      , /etc/apt/preferences.d/phd      )
	$(call link, ${DIR}/--etc--apt--sources.list.d--phd.list, /etc/apt/sources.list.d/phd.list)
endif
