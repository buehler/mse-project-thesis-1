rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

sections = $(wildcard sections/*.md)
common_build_args = \
	--lua-filter=lib/lua-filters/include-files/include-files.lua \
	--filter pandoc-xnos \
	--lua-filter=lib/custom/plantuml-converter.lua \
	--lua-filter=lib/lua-filters/short-captions/short-captions.lua \
	--metadata-file=./metadata.yaml \
	--citeproc \
	--standalone


.PHONY: default clean clean_diagrams clean_build build build_html build_pdf


default: clean_build build


clean: clean_diagrams


clean_diagrams: $(call rwildcard,diagrams,*.png)
	@echo "Clean compiled plantuml diagram pngs."
	@rm -f $?


clean_build:
	@rm -rf ./public
	@mkdir ./public


build: build_pdf build_html


build_html:
	@echo "Build HTML version"
	@pandoc ${common_build_args} --toc --output=public/index.html ${sections}
	@cp -R images public/
	@cp -R diagrams public/


build_pdf:
	@echo "Build PDF version"
	@pandoc ${common_build_args} --output=public/report.pdf ${sections}
