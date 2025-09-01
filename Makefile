HUGO = hugo
BINDIR = bin

HTMLTEST=$(BINDIR)/htmltest
HTMLTEST_VERSION=v0.17.0

V = 0
Q = $(if $(filter 1,$V),,@)

.PHONY: all
all: run

.PHONY: setup
setup:
	$Q npm install

.PHONY: run
run: setup
	$Q $(HUGO) server

.PHONY: preview
preview: setup
	$Q $(HUGO) server --disableFastRender --navigateToChanged --templateMetrics --templateMetricsHints --watch --forceSyncStatic -e production --minify --bind 0.0.0.0

.PHONY: dist
dist: setup
	$Q $(HUGO) --gc --minify --templateMetrics --templateMetricsHints --forceSyncStatic
	$Q find public -type f -exec chmod a+w {} \;

.PHONY: get-htmltest
get-htmltest:
	$Q mkdir -p $(BINDIR)
	$Q test -x $(HTMLTEST) || GOBIN="$(PWD)/$(BINDIR)/" go install github.com/wjdp/htmltest@$(HTMLTEST_VERSION)

.PHONY: test
test: get-htmltest
	$Q $(HTMLTEST) public

clean:
	$Q rm -rf public
	$Q rm -rf $(BINDIR)
