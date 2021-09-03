sysconfdir ?= /etc

.PHONY:	all install clean

all:	tmp$(sysconfdir)/bash_completion.d/opkg

install:	tmp$(sysconfdir)/bash_completion.d/opkg
	install -m 755 -d $(DESTDIR)$(sysconfdir)/bash_completion.d
	install -m 755 -t $(DESTDIR)$(sysconfdir)/bash_completion.d tmp$(sysconfdir)/bash_completion.d/opkg

clean:
	rm -rf tmp

tmp$(sysconfdir)/bash_completion.d/opkg:	opkg-bash-completion | tmp$(sysconfdir)/bash_completion.d
	$(PWD)/strip-debug $^ > $@

tmp$(sysconfdir)/bash_completion.d:
	mkdir -p $@
