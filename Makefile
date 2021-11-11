DOCTYPE = RTN
DOCNUMBER = 021
DOCNAME = $(DOCTYPE)-$(DOCNUMBER)

tex = $(filter-out $(wildcard *acronyms.tex) , $(wildcard *.tex))

GITVERSION := $(shell git log -1 --date=short --pretty=%h)
GITDATE := $(shell git log -1 --date=short --pretty=%ad)
GITSTATUS := $(shell git status --porcelain)
ifneq "$(GITSTATUS)" ""
	GITDIRTY = -dirty
endif

export TEXMFHOME ?= lsst-texmf/texmf

# Add aglossary.tex as a dependancy here if you want a glossary (and remove acronyms.tex)
$(DOCNAME).pdf: $(tex) meta.tex local.bib aglossary.tex
	xelatex $(DOCNAME)
	makeglossaries $(DOCNAME)
	latexmk -bibtex -xelatex -f $(DOCNAME)
	makeglossaries $(DOCNAME)
	xelatex $(DOCNAME)
	xelatex $(DOCNAME)


# Acronym tool allows for selection of acronyms based on tags - you may want more than DM
acronyms.tex: $(tex) myacronyms.txt
	$(TEXMFHOME)/../bin/generateAcronyms.py -t "DM" $(tex)

# If you want a glossary you must manually run generateAcronyms.py  -gu to put the \gls in your files.
aglossary.tex :$(tex) myacronyms.txt
	generateAcronyms.py  -t "DM OPS" -g $(tex)


.PHONY: clean
clean:
	latexmk -c
	rm -f $(DOCNAME).{bbl,glsdefs,pdf}
	rm -f meta.tex


meta.tex: Makefile
	rm -f $@
	touch $@
	printf '%% GENERATED FILE -- edit this in the Makefile\n' >>$@
	printf '\\newcommand{\\lsstDocType}{$(DOCTYPE)}\n' >>$@
	printf '\\newcommand{\\lsstDocNum}{$(DOCNUMBER)}\n' >>$@
	printf '\\newcommand{\\vcsRevision}{$(GITVERSION)$(GITDIRTY)}\n' >>$@
	printf '\\newcommand{\\vcsDate}{$(GITDATE)}\n' >>$@

# milestones from Jira 
openMilestones.tex: 
	( \
	cd operations_milestones; \
	source venv/bin/activate; \
	python opsMiles.py -ls -u ${USER}; \
	mv *Milestones.tex .. \
	)       

# Gantt USDFplan.pdf
USDFplan.tex: 
	( \
	cd operations_milestones; \
	source venv/bin/activate; \
	python opsMiles.py -g -q "and labels=USDF"  -u ${USER}; \
	mv USDFplan.tex .. \
	)

USDFplan.pdf: USDFplan.tex
	pdflatex USDFplan.tex 

FORCE:
