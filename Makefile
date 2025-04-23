HUGO = hugo

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
	$Q $(HUGO) server --disableFastRender --navigateToChanged --templateMetrics --templateMetricsHints --watch --forceSyncStatic -e production --minify

.PHONY: dist
dist: setup
	$Q $(HUGO) --gc --minify --templateMetrics --templateMetricsHints --forceSyncStatic
	$Q find public -type f -exec chmod a+w {} \;

clean:
	$Q rm -rf public
