# Dotfiles installer. Everything is opt-in: plain `make` deploys nothing.
#
# kitty and helix are symlinked, so edits in this repo take effect with no
# reinstall step. Everything else is copied, matching what deploy.sh did.

REPO    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
CONFIG  := $(HOME)/.config
BIN_DIR := $(HOME)/.local/bin
APPS    := $(HOME)/Apps

SCRIPT     := theme-switch
SCRIPT_DST := $(BIN_DIR)/$(SCRIPT)

# The auto-follow service is the one component that differs per OS: a systemd
# user unit on Linux, a LaunchAgent on macOS. AUTO_DST is whichever one this
# machine would get, so status and uninstall do not have to branch again.
UNAME_S    := $(shell uname -s)

UNIT       := theme-switch.service
UNIT_DIR   := $(CONFIG)/systemd/user
UNIT_DST   := $(UNIT_DIR)/$(UNIT)

AGENT      := com.github.1badragon.theme-switch.plist
AGENT_DIR  := $(HOME)/Library/LaunchAgents
AGENT_DST  := $(AGENT_DIR)/$(AGENT)

ifeq ($(UNAME_S),Darwin)
AUTO_DST   := $(AGENT_DST)
else
AUTO_DST   := $(UNIT_DST)
endif

# Symlinks, as <link path>:<repo-relative target>.
HELIX_LINKS := \
	$(CONFIG)/helix/config.toml:helix/config.toml \
	$(CONFIG)/helix/languages.toml:helix/languages.toml
KITTY_LINKS := \
	$(CONFIG)/kitty/kitty.conf:kitty/kitty.conf \
	$(CONFIG)/kitty/current-theme.conf:kitty/current-theme.conf \
	$(CONFIG)/kitty/themes:kitty/themes
# Symlinked rather than copied, for the same reason kitty and helix are: this
# is a config that gets tuned, and a copy means a reinstall after every tweak.
WAYBAR_LINKS := \
	$(CONFIG)/waybar/config.jsonc:waybar/config.jsonc \
	$(CONFIG)/waybar/style.css:waybar/style.css \
	$(CONFIG)/waybar/colors-light.css:waybar/colors-light.css \
	$(CONFIG)/waybar/colors-dark.css:waybar/colors-dark.css \
	$(CONFIG)/waybar/current-colors.css:waybar/current-colors.css
ALL_LINKS := $(HELIX_LINKS) $(KITTY_LINKS) $(WAYBAR_LINKS)

# Symlink each <link>:<target> pair, preserving any real file already there.
define link_all
	@for pair in $(1); do \
		link=$${pair%%:*}; target=$(REPO)/$${pair#*:}; \
		mkdir -p "$$(dirname "$$link")"; \
		if [ -e "$$link" ] && [ ! -L "$$link" ]; then \
			cp -p "$$link" "$$link.pre-repo.bak"; \
			echo "  backed up    $$link.pre-repo.bak"; \
		fi; \
		ln -sfn "$$target" "$$link"; \
		echo "  linked       $$link"; \
	done
endef

.DEFAULT_GOAL := help
.PHONY: help theme all zsh bin i3 waybar kitty helix theme-switch theme-auto status diff uninstall

help:
	@echo 'Dotfiles installer -- nothing is deployed unless you name a target.'
	@echo
	@echo '  make theme         kitty + helix + theme-switch (no i3/waybar needed)'
	@echo '  make all           every component below'
	@echo
	@echo 'Components:'
	@echo '  make kitty         symlink kitty.conf, themes/, current-theme.conf'
	@echo '  make helix         symlink config.toml, languages.toml'
	@echo '  make theme-switch  copy theme-switch to $(BIN_DIR)'
	@echo '  make theme-auto    install the theme-switch auto-follow service'
	@echo '                     (systemd unit, or a LaunchAgent on macOS; opt-in,'
	@echo '                     not in make all; enable it yourself afterwards)'
	@echo '  make waybar        symlink the waybar bar config + stylesheet'
	@echo '  make zsh           copy .zshrc + .p10k.zsh to $(HOME)'
	@echo '  make bin           copy bin/ to $(APPS)'
	@echo '  make i3            copy i3/ to $(CONFIG)'
	@echo
	@echo 'Maintenance:'
	@echo '  make status        show what is deployed'
	@echo '  make diff          drift between repo and installed theme-switch'
	@echo '  make uninstall     remove symlinks + theme-switch (copies are left alone)'

# --- grouped targets ----------------------------------------------------------

theme: kitty helix theme-switch

all: theme zsh bin waybar i3

# --- symlinked components -----------------------------------------------------

kitty:
	$(call link_all,$(KITTY_LINKS))

helix:
	$(call link_all,$(HELIX_LINKS))

waybar:
	$(call link_all,$(WAYBAR_LINKS))

# --- copied components --------------------------------------------------------

theme-switch:
	@mkdir -p $(BIN_DIR)
	@# Clear first: the destination may be a symlink from an older layout,
	@# and install(1) would otherwise write through it.
	@rm -f $(SCRIPT_DST)
	@install -m 755 $(SCRIPT) $(SCRIPT_DST)
	@echo "  installed    $(SCRIPT_DST)"

# Installed but deliberately not enabled, and left out of `all`: enabling a unit
# is a running-system change, and the service only makes sense on a machine with
# a graphical session. The enable line is printed rather than run.
theme-auto: theme-switch
ifeq ($(UNAME_S),Darwin)
	@mkdir -p $(AGENT_DIR)
	@install -m 644 launchd/$(AGENT) $(AGENT_DST)
	@echo "  installed    $(AGENT_DST)"
	@echo "  next         launchctl bootstrap gui/$$(id -u) $(AGENT_DST)"
else
	@mkdir -p $(UNIT_DIR)
	@install -m 644 systemd/$(UNIT) $(UNIT_DST)
	@systemctl --user daemon-reload
	@echo "  installed    $(UNIT_DST)"
	@echo "  next         systemctl --user enable --now $(UNIT)"
endif

# .zshrc expects powerlevel10k to be installed by the system package manager;
# it sources whichever prefix it finds rather than a fixed one.
zsh:
	@cp -v zsh/.zshrc zsh/.p10k.zsh $(HOME)

bin:
	@mkdir -p $(APPS)
	@cp -rv bin $(APPS)

i3:
	@mkdir -p $(CONFIG)
	@cp -rv i3 $(CONFIG)

# --- maintenance --------------------------------------------------------------

status:
	@for pair in $(ALL_LINKS); do \
		link=$${pair%%:*}; \
		if [ -L "$$link" ] && [ -e "$$link" ]; then printf '  %-42s -> %s\n' "$$link" "$$(readlink "$$link")"; \
		elif [ -L "$$link" ]; then printf '  %-42s -> %s  (DANGLING)\n' "$$link" "$$(readlink "$$link")"; \
		elif [ -e "$$link" ]; then printf '  %-42s    (regular file, not managed)\n' "$$link"; \
		else printf '  %-42s    (not deployed)\n' "$$link"; fi; \
	done
	@for f in $(SCRIPT_DST) $(AUTO_DST) $(HOME)/.zshrc $(HOME)/.p10k.zsh $(APPS)/bin $(CONFIG)/i3; do \
		if [ -e "$$f" ]; then printf '  %-42s    (present)\n' "$$f"; \
		else printf '  %-42s    (not deployed)\n' "$$f"; fi; \
	done

diff:
	@diff -u $(SCRIPT_DST) $(SCRIPT) && echo "$(SCRIPT): in sync"

uninstall:
	@# Only removes symlinks still pointing into this repo, plus theme-switch.
	@# Copied files are left alone: they may have diverged since deployment.
	@for pair in $(ALL_LINKS); do \
		link=$${pair%%:*}; target=$(REPO)/$${pair#*:}; \
		if [ "$$(readlink "$$link" 2>/dev/null)" = "$$target" ]; then \
			rm -f "$$link"; echo "  removed      $$link"; \
		fi; \
	done
	@# Stop before removing: a running watcher would otherwise outlive its unit.
ifeq ($(UNAME_S),Darwin)
	@if [ -e "$(AGENT_DST)" ]; then \
		launchctl bootout gui/$$(id -u)/$(basename $(AGENT)) 2>/dev/null || true; \
		rm -f $(AGENT_DST); \
		echo "  removed      $(AGENT_DST)"; \
	fi
else
	@if [ -e "$(UNIT_DST)" ]; then \
		systemctl --user disable --now $(UNIT) 2>/dev/null || true; \
		rm -f $(UNIT_DST); systemctl --user daemon-reload; \
		echo "  removed      $(UNIT_DST)"; \
	fi
endif
	@rm -f $(SCRIPT_DST)
	@echo "  removed      $(SCRIPT_DST)"
