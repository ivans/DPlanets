module planetsgen;

import std.stdio;
import std.stream;
import std.random;

void main() {

	auto file = new std.stream.File("izlaz.dat", FileMode.Out);

	float randomNum() {
		float f = uniform(0, 100);
		return (f-50)/50;
	}

	int mass = 50;
	file.writefln("S1 	100000 	0.0 	0.0    0.0 0.0  100");
	for(int j=0; j<500; j++) {
		file.writefln("%sime %s %s\t %s\t %s\t %s\t 50", j,mass,randomNum()*50000,randomNum()*50000, 0, 0);
		mass = -mass;
	}
}