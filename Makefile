NOTFILES := Makefile README.md LICENSE
DOTFILES := $(filter-out $(NOTFILES), $(wildcard *))
SYMLINKS := $(addprefix ~/., $(DOTFILES))
FILENAME := "~/.$(FILE)"
INSTALLED := ~/.$(FILE)
TRACKED := $(CURDIR)/$(FILE)
LINKED := $(shell readlink $(INSTALLED))

$(VERBOSE).SILENT:

.PHONY: all
all: install

.PHONY: install
install: $(SYMLINKS)
	echo "DOTFILES INSTALLED"

.PHONY: track
track:
ifeq ("$(FILE)", "")
	echo "NO FILE SPECIFIED"
else ifeq ("$(wildcard $(INSTALLED))", "")
	echo "MISSING $(FILENAME) does not exist!"
else ifneq ("$(wildcard $(TRACKED))", "")
	echo "ALREADY TRACKING $(FILENAME)"
else
	mv $(INSTALLED) "$(TRACKED)"
	ln -s "$(TRACKED)" $(INSTALLED)
	git add $(TRACKED) 2>/dev/null
	git commit -m "adding $(FILENAME)"
	echo "TRACKING $(FILENAME)"
endif

.PHONY: untrack
untrack:
ifeq ("$(FILE)", "")
	echo "NO FILE SPECIFIED"
else ifeq ("$(wildcard $(TRACKED))", "")
	echo "UNTRACKING LOCALFILE $(FILENAME)"
else
ifeq ("$(LINKED)", "$(TRACKED)")
	rm $(INSTALLED)
	mv $(TRACKED) $(INSTALLED)
endif
	git rm $(TRACKED)
	git commit -m "removing $(FILENAME)"
	echo "UNTRACKING $(FILENAME)"
endif

.PHONY: link
link:
ifeq ("$(FILE)", "")
	echo "NO FILE SPECIFIED"
else ifeq ("$(wildcard $(TRACKED))", "")
	echo "NOT TRACKING $(FILENAME)"
else ifneq ("$(wildcard $(INSTALLED))", "")
	echo "CAN'T OVERWRITE $(FILENAME)"
else
	echo "LINKING $(FILENAME)"
	ln -s "$(TRACKED)" $(INSTALLED)
endif

.PHONY: unlink
unlink:
ifeq ("$(FILE)", "")
	echo "NO FILE SPECIFIED"
else ifneq ("$(LINKED)", "$(TRACKED)")
	echo "NOT LINKED $(FILENAME)"
else
	echo "UNLINKING $(FILENAME)"
	rm $(INSTALLED)
endif

.PHONY: edit
edit:
ifeq ("$(EDITOR)", "")
	echo "NO EDITOR SPECIFIED"
else ifeq ("$(FILE)", "")
	echo "NO FILE SPECIFIED"
else ifeq ("$(wildcard $(TRACKED))", "")
	echo "MISSING $(FILENAME)"
else
	echo "EDITING $(FILENAME)"
	$(EDITOR) $(TRACKED)
	git add $(TRACKED) 2>/dev/null || true
	git diff --quiet --cached --exit-code || git commit -m "updating $(FILENAME)" 2>/dev/null || true
endif

.PHONY: list
list:
	for x in $(DOTFILES); do \
		export y=$$(readlink ~/.$$x); \
		if [ "$$y" = "$(CURDIR)/$$x" ]; then \
			echo "LINKED\t$$x"; \
		else \
			echo "......\t$$x"; \
		fi; \
		unset y; \
	done

.PHONY: status
status:
	echo

	if ! git diff --quiet --exit-code origin; then \
		echo "DOTFILES OUT OF SYNC!!!"; \
		echo; \
		echo "RUN: dotfiles sync"; \
	else \
		echo "DOTFILES UP TO DATE!"; \
	fi

	echo

.PHONY: sync
sync:
	git pull --ff-only 1>/dev/null 2>/dev/null
	
	if ! git diff --quiet --exit-code origin; then \
		git add * 2>/dev/null; \
		echo "\nPlease write a note about what you changed?\n "; \
		read COMMIT; \
		echo; \
		git diff --quiet --cached --exit-code || git commit -m "$$COMMIT"; \
		git push; \
	fi

.PHONY: uninstall
uninstall:
	for x in $(DOTFILES); do \
		$(MAKE) -s unlink FILE=$$x; \
	done
	echo "DOTFILES UNINSTALLED"

~/.%: %
	$(MAKE) -s link FILE=$<
