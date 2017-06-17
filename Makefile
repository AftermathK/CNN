
oneCNA:
	mkdir -p build
	bsc -u -sim -simdir build -bdir build -info-dir build -keep-fires -g  mkTbOneCNA  OneCNATb.bsv 
	bsc -e mkTbOneCNA -sim -o ./simOneCNA -simdir build -bdir build -keep-fires

clean:
	rm -rf build sim* out verilog dump.vcd 
