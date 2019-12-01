DOTFILES := $(filter-out Makefile, $(wildcard *))
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
	git add $(TRACKED)
	git commit -m "adding $(FILENAME)"
	echo "TRACKING $(FILENAME)"
endif

.PHONY: untrack
untrack:
ifeq ("$(FILE)", "")
	echo "NO FILE SPECIFIED"
else ifeq ("$(wildcard $(TRACKED))", "")
	echo "NOT TRACKING $(FILENAME)"
else
ifeq ("$(LINKED)", "$(TRACKED)")
	rm $(INSTALLED)
	mv $(TRACKED) $(INSTALLED)
endif
	git rm $(TRACKED)
	git commit -m "remove $(FILENAME)"
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
	$(EDITOR) $(TRACKED)
	git add $(TRACKED)
	git commit -m "updating $(FILENAME)"
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

.PHONY: update
update:
	git add *
	git commit
	git pull
	git push
	echo "DOTFILES UPDATED"

.PHONY: uninstall
uninstall:
	for x in $(DOTFILES); do \
		$(MAKE) -s unlink FILE=$$x; \
	done
	echo "DOTFILES UNINSTALLED"

~/.%: %
	$(MAKE) -s link FILE=$<
