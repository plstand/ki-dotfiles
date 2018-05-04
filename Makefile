.PHONY: all
all:

.PHONY: install
install: bashrc.sh gitconfig.ini
	install -b -m 0644 bashrc.sh ~/.bashrc
	install -b -m 0644 gitconfig.ini ~/.gitconfig
	install -b -m 0644 msmtprc ~/.msmtprc
	install -b -D -m 0644 ssh_config ~/.ssh/config
