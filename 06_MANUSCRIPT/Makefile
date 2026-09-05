LATEX  = pdflatex -interaction=nonstopmode -halt-on-error
BIBTEX = bibtex
MAIN   = main

all: thesis

thesis:
	$(LATEX) $(MAIN)
	$(BIBTEX) $(MAIN)
	$(LATEX) $(MAIN)
	$(LATEX) $(MAIN)

quick:
	$(LATEX) $(MAIN)

clean:
	rm -f *.aux *.log *.toc *.lof *.lot *.out *.bbl *.blg *.synctex.gz

cleanall: clean
	rm -f $(MAIN).pdf

.PHONY: all thesis quick clean cleanall
