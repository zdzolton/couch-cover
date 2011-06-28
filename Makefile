build: clean
	coffee -o lib src/*.coffee
  
clean:
	rm -rf ./lib
	mkdir lib

test: build
	vows ./spec/*.coffee