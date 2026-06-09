PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

install:
	install -Dm755 tint $(DESTDIR)$(BINDIR)/tint

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/tint

.PHONY: install uninstall
