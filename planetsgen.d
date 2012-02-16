module planetsgen;

import std.stdio;
import std.stream;
import std.random;

void main()
{
  File file = new File("izlaz.dat", FileMode.Out);

  float randomNum()
  {
    float f = rand()%101;
    return (f-50)/50;
  }

  for(int i=0;i<100;i++)
  {
    writefln(randomNum());
  }

  file.writefln("S1 	1000000 	0.0 	0.0    0.0 0.0   5");
  //P1 	200000 	50 		0.0    0.000010   0.0000001  1
  for(int j=0; j<200; j++)
  {
    file.writefln("%sime 20000 %s\t %s\t %s\t %s\t 1", 
      j,randomNum()*2000,randomNum()*2000, randomNum()*0.0006, randomNum()*0.0006);
  }
}