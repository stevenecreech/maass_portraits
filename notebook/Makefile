SAGE = sage

.PHONY: usage
usage:
	@echo ""
	@echo "USAGE"
	@echo "  make compile - compile necessary things for sage"
	@echo "  make lpkbessel.so - compiles bessel computation for sage"
	@echo "  make maass_evaluator.so - compiles maass evaluator for sage"
	@echo "  make clean - clears compiled objects"
	@echo ""


.PHONY: compile
compile: lpkbessel.so maass_evaluator.so


lpkbessel.so: lpkbessel.spyx
	@echo "Using sage program '$(SAGE)' to compile lpkbessel..."
	$(SAGE) -c "from sage.misc.cython import cython; cython('lpkbessel.spyx', compile_message=True, use_cache=False, create_local_so_file=True)"
	mv lpkbessel.*.so lpkbessel.so
	@echo "Done"


maass_evaluator.so: maass_evaluator.spyx
	@echo "Using sage program '$(SAGE)' to compile evaluator..."
	$(SAGE) -c "from sage.misc.cython import cython; cython('maass_evaluator.spyx', compile_message=True, use_cache=False, create_local_so_file=True)"
	mv maass_evaluator.*.so maass_evaluator.so
	@echo "Done"


.PHONY: clean
clean:
	rm -f lpkbessel.so
	rm -f maass_evaluator.so
