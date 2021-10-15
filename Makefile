.PHONY: all
all:

.PHONY: install
install: bash/rc git/config msmtp/config reportbug/config ssh/config
	install -b -m 0644 bash/rc ~/.bashrc
	install -b -D -m 0644 git/config ~/.config/git/config
	install -b -D -m 0644 msmtp/config ~/.config/msmtp/config
	install -b -m 0644 reportbug/config ~/.reportbugrc
	install -b -D -m 0644 ssh/config ~/.ssh/config
	cp -n ssh/config.local ~/.ssh/config.local
