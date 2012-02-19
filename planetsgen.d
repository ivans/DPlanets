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

	file.writefln("S1 	100000 	0.0 	0.0    0.0 0.0  100");
	for(int j=0; j<1000; j++) {
		file.writefln("%sime 50 %s\t %s\t %s\t %s\t 50", j,randomNum()*20000,randomNum()*20000, 0, 0);
	}
}