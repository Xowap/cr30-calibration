temp-bridges:
	mkdir -p dist
	openscad -o dist/temp-bridges.stl src/temp-bridges.scad

format:
	prettier -w README.md
