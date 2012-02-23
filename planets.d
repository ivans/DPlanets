module planets;

private {
	import std.stdio, std.string;
	import std.stream;
	import core.thread;
	import glfw;
	import util;
	import std.math, std.random;
}

__gshared int frames, width, height, origW, origH;

__gshared int mouseX = 100, mouseY = 100;
__gshared int mouseXDelta = 0, mouseYDelta = 0;
__gshared bool mouseLeft = false, mouseMiddle = false, mouseRight = false;
__gshared int mouseWheelPos = 0, mouseWheelDelta = 0;

__gshared GLFWvidmode desktopMode;
__gshared int clearscreen = 0;

immutable ftype G = 6.6742e-11; // m^3/kgs^2

static this() {
	origW = width = 1024;
	origH = height = 768;  
	sphereObj = gluNewQuadric();
	syncO = new Object();
}

__gshared double t;
__gshared int x, y;
__gshared int centerPlanet = 0;
__gshared ftype time = 0;
__gshared int currentWindowType = GLFW_WINDOW;
__gshared GLUquadricObj* sphereObj;

__gshared Planet[] planets;
__gshared ftype distP1_PN = 1000;
__gshared Tocka glediste = {0,0,0};
__gshared Tocka ociste = {0, 0 , 1.6e10};

__gshared Object syncO;

class Planet {
	string name;
	ftype m = 1;			//kg
	ftype x=0,y=0,z=0;		//m
	ftype vx=0,vy=0,vz=0;	//m/s
	ftype r=1;			//m
	static __gshared ftype dt = 64; //s
	static bool showOldPos = false;
	
	int currentPos = 0;
	ftype[3][1000] oldPos;
	
	void initOldPos() {
		for(int i=0; i<oldPos.length; i++) {
			oldPos[i][0] = x;
			oldPos[i][1] = y;
			oldPos[i][2] = z;
		}
	}

	this(string name, ftype m, ftype x, ftype y, ftype z, ftype vx, ftype vy, ftype vz, ftype r) {
		this.name = name;
		this.m = m;
		this.x = x;
		this.y = y;
		this.z = z;
		this.vx = vx;
		this.vy = vy;
		this.vz = vz;
		this.r = r;
		initOldPos();
	}
  
	string toString() {
		return format("%s: (%s, %s, %s), (%s, %s, %s), %s", name, x, y, z, vx, vy, vz, m);
	}

	__gshared static int functionType = 0;

	static void nextFunction() {
		functionType = (functionType+1)%3;
		debug writeln("Function == ", functionType);
	}

	ftype GetF(Planet pl) {
		ftype dx = pl.x - this.x;
		ftype dy = pl.y - this.y;
		ftype dz = pl.z - this.z;
		ftype dist_sq = dx*dx + dy*dy + dz*dz;
		ftype dist = sqrt(dist_sq);
		if (dist_sq == 0) {
			return 0;
		}
		ftype sila;
		switch(functionType) {
			case 0: 
				sila = G * this.m * pl.m/(dist_sq); 
				break;
			case 1:
				sila = G * this.m * pl.m/(dist); 
				break;
			default:
				throw new Exception("aaA");
		}

		ftype a = sila / abs(this.m);
		ftype dv = a * dt;

		this.vx += dv * dx / dist;
		this.vy += dv * dy / dist;
		this.vz += dv * dz / dist;

		return sila;
	}

	void Update() {
		this.x += this.vx * dt;
		this.y += this.vy * dt;
		this.z += this.vz * dt;
	}

	void Draw() {
		//if(frames %3 == 0)
		{
			oldPos[currentPos][0] = x;
			oldPos[currentPos][1] = y;
			oldPos[currentPos][2] = z;
			currentPos = (currentPos+1) % oldPos.length;
		}
		
		if(showOldPos == true) {
			glColor3f(0.7f, 0.7f, 0.7f);
			glBegin(GL_LINES);
			for(int i=1; i<oldPos.length; i++) {
				glVertex3f(oldPos[(currentPos+i-1)%$][0], oldPos[(currentPos+i-1)%$][1], oldPos[(currentPos+i-1)%$][2]);
				glVertex3f(oldPos[(currentPos+i)%$][0], oldPos[(currentPos+i)%$][1], oldPos[(currentPos+i)%$][2]);
			}
			glEnd();
		}

		if (m < 0) 
			glColor3f(0.5f, 1.0f, 0.5f);
		else
			glColor3f(1.0f, 0.5f, 0.5f);

		//debug writef(this.name," ",this.r / dist(x,y,z,ociste.x+planets[centerPlanet].x,ociste.y+planets[centerPlanet].y,ociste.z+planets[centerPlanet].z));
		if(this.r / dist(x,y,z,ociste.x+planets[centerPlanet].x,ociste.y+planets[centerPlanet].y,ociste.z+planets[centerPlanet].z) > 0.001) {
			//debug writefln(" kugla");
			glPushMatrix();
			glTranslatef(x,y,z);
			gluSphere(sphereObj,r,10,10);
			glPopMatrix();
		} else {
			//debug writefln(" tocka");
			ftype r2 = r;
			while(r2 / dist(x,y,z,ociste.x+planets[centerPlanet].x,ociste.y+planets[centerPlanet].y,ociste.z+planets[centerPlanet].z) < 0.001) {
				r2 *= 2;
			}
			glPushMatrix();
			glTranslatef(x,y,z);
			gluSphere(sphereObj,r2,10,10);
			glPopMatrix();
		}
	}
	
	static void Step(Planet[] planets) {
		debug writeln("Step...", planets is null);
		foreach(i,pA; planets) {
			foreach(j,pB; planets) {
				if(i!=j && pA !is null && pB !is null) {
					pA.GetF(pB);
				}
			}
		}
		foreach(p; planets) {
			if(p !is null) {
				p.Update();
			}
		}
		time += dt;
	}

	static void Colide(ref Planet[] planets) {
		debug writeln("Coliding...");
		for(auto i=0; i<planets.length; i++) {
			auto pA = planets[i];
			for(auto j=i+1; j<planets.length; j++) {
				auto pB = planets[j];
				if(pA !is null && pB !is null) {
					auto massSum = pA.m+pB.m;
					if(dist(pA,pB) <= (pA.r + pB.r) && massSum != 0) {
						pA.vx = (pA.m*pA.vx + pB.m*pB.vx)/massSum;
						pA.vy = (pA.m*pA.vy + pB.m*pB.vy)/massSum;
						pA.vz = (pA.m*pA.vz + pB.m*pB.vz)/massSum;
						pA.m += pB.m;
						// formula za raččunanje radiusa (uračunati gustoću)
						//pA.r = pow(pow(pA.r,3) + pow(pB.r,3) , 1/3.);
						planets.remove(j);
					}
				}
			}
		}
	}
}

void remove(ref Planet[] array, ulong index) {
	debug writefln("Removing planet @ index=%s", index);
	for (ulong i=array.length-1; i>=1; i--) {
		if (array[i] !is null) {
			array[index] = array[i];
			array.length = array.length - 1L;
			break;
		}
	}
}

ftype dist(ftype x1, ftype y1, ftype z1, ftype x2, ftype y2,ftype z2) {
	return sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2)+(z1-z2)*(z1-z2));
}

ftype dist(Planet a, Planet b) {
	return sqrt((a.x-b.x)*(a.x-b.x)+(a.y-b.y)*(a.y-b.y)+(a.z-b.z)*(a.z-b.z));
}

int main(char[][] args) {
	string inputFile;
	if(args.length == 2) {
		inputFile = cast(string)args[1];
	} else {
		inputFile = "planets.dat";
	}

  	std.stream.File planetsData = new std.stream.File(inputFile);

  	while( planetsData.eof == false ) {
		char[] name;
		ftype m, x, y, vx, vy, r; 
		planetsData.readf(&name,&m,&x,&y,&vx,&vy,&r);
		if (!(name is null || m is ftype.nan)) {
			debug writefln("Planet read from file: %s (%s kg), at: (%s, %s), speed: (%s, %s), size: %s", name, m, x, y, vx, vy, r);
			auto p = new Planet(cast(string) name, m, x, y, 0 ,vx, vy, 0, r);
			planets ~= p;
		}
	}
	debug writefln("Loaded %s planets from file: %s", planets.length, inputFile);

	ociste.z = 10 * (distP1_PN = 1 + dist(planets[0].x,planets[0].y,planets[0].z,planets[$-1].x,planets[$-1].y,planets[$-1].z));
	writeln("Ociste.z = ",ociste.z);

	glfwInit();
	glfwGetDesktopMode(&desktopMode);

	if( !glfwOpenWindow( width, height, 0,0,0,0,16,0, currentWindowType ) ) {
		glfwTerminate();
		return 0;
	}

	int running = GL_TRUE;
  	double t0 = glfwGetTime();
	double fps;
  	string titlestr;

	registerCallbacks();

	void calculateFps() {
		// Calculate and display FPS (frames per second)
		if( (t-t0) > 1.0 || frames == 0 ) {
			fps = cast(double)frames / (t-t0);
			t0 = t;
			frames = 0;
		}
		frames ++;
	}

	void updateThread() {
		debug writeln("updateThread starting...");
		while (running) {
			for (int i=0; i<100; i++) {
				Planet.Step(planets);
				synchronized(syncO) {
					Planet.Colide(planets);
					while (planets[centerPlanet] is null) {
						centerPlanet = cast(int) ((centerPlanet + 1) % planets.length);
					}
				}
				Thread.sleep(0);
				if (!running) break;
			}
		}
		debug writeln("updateThread stoping...");
	}

	(new Thread(&updateThread)).start();

	// Main loop
	try {
		while (running) {
			t = glfwGetTime();
			glfwGetMousePos( &x, &y );

			calculateFps();
	
			synchronized(syncO) {
				draw();
			}
	
			processMouseInput();
			glfwSwapBuffers();
	
			titlestr = std.string.format("Spinning Triangle (%s FPS) + center at %s, time=%s\0", fps, planets[centerPlanet], t);
			glfwSetWindowTitle(cast(char*)titlestr.ptr);

			running = !glfwGetKey( GLFW_KEY_ESC ) && glfwGetWindowParam( GLFW_OPENED );
		}
	} catch (Exception e) {
		writeln("Exception", e);
	}

	glfwTerminate();
	return 0;
}

bool allwaysClear = false;

void draw() {

	void setModelDraw() {
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
	}

	void setPerspective() {
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		gluPerspective(45,cast(GLfloat)width/cast(GLfloat)height,0.1f,1e30);
		gluLookAt (
		    planets[centerPlanet].x+ociste.x,
		    planets[centerPlanet].y+ociste.y,
		    planets[centerPlanet].z+ociste.z,
		    planets[centerPlanet].x,
		    planets[centerPlanet].y,
		    planets[centerPlanet].z, 0.0, 1.0, 0.0
		);	// ociste x,y,z; glediste x,y,z; up vektor x,y,
	}

	//if(clearscreen > 0 || allwaysClear==true) {
		glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		//clearscreen --;
	//}

	setPerspective();
	setModelDraw();

	glPushMatrix();
	glTranslatef(planets[centerPlanet].x,planets[centerPlanet].y,planets[centerPlanet].z);
	glBegin(GL_LINES);
		glColor3f(0.7f,0.3f,0.3f);
		glVertex3f(0,0,-distP1_PN);
		glVertex3f(0,0,distP1_PN);
		glVertex3f(-distP1_PN,0,0);
		glVertex3f(distP1_PN,0,0);
		glVertex3f(0,-distP1_PN,0);
		glVertex3f(0,distP1_PN,0);    
	glEnd();
	glPopMatrix();

	foreach(planet; planets) {
		if (planets !is null) {
			planet.Draw();
		}
	}
}

void processMouseInput() {
	if(mouseRight == true) {
		if(mouseYDelta != 0 || mouseXDelta != 0) {
			Quaternion.rotate(ociste.x,ociste.y,ociste.z,-0.001*mouseYDelta,1,0,0);
			Quaternion.rotate(ociste.x,ociste.y,ociste.z,-0.001*mouseXDelta,0,1,0);
			clearscreen = true;
		}
	}
}

void registerCallbacks() {
	glfwSetWindowSizeCallback(&windowResize);
	glfwSetCharCallback(&characterCallback);
	
	glfwSetMousePosCallback(&mousePosFunc);
	glfwSetMouseButtonCallback(&mouseButtonFunc);
	glfwSetMouseWheelCallback(&mouseWheelFunc);
}

extern(C) void mouseWheelFunc(int pos) {
	mouseWheelDelta = pos - mouseWheelPos;
	mouseWheelPos = pos;
	
	ociste.x = mouseWheelDelta > 0 ? ociste.x*1.3 : ociste.x/1.3 ;
	ociste.y = mouseWheelDelta > 0 ? ociste.y*1.3 : ociste.y/1.3 ;
	ociste.z = mouseWheelDelta > 0 ? ociste.z*1.3 : ociste.z/1.3 ;
	debug writeln("Ociste = ", ociste);
	
	windowResize(width, height);
	clearscreen = 2;
}

extern(C) void mousePosFunc(int x, int y) {
	mouseXDelta = x - mouseX;
	mouseYDelta = y - mouseY;
	mouseX = x;
	mouseY = y;
}

extern(C) void mouseButtonFunc(int button, int action) {
	if(action == GLFW_PRESS) {
		if(button == GLFW_MOUSE_BUTTON_LEFT) mouseLeft = true;
		if(button == GLFW_MOUSE_BUTTON_RIGHT) mouseRight = true;
		if(button == GLFW_MOUSE_BUTTON_MIDDLE) mouseMiddle = true;
	} else {
		if(button == GLFW_MOUSE_BUTTON_LEFT) mouseLeft = false;
		if(button == GLFW_MOUSE_BUTTON_RIGHT) mouseRight = false;
		if(button == GLFW_MOUSE_BUTTON_MIDDLE) mouseMiddle = false;
	}
}

extern(C) void windowResize(int w, int h) {
	debug writeln("windowResize ", w, " ", h);
	width = w;
	height = h;
	glPolygonMode(GL_FRONT, GL_FILL);
	glPolygonMode(GL_BACK, GL_FILL);

	glClearColor( 0.0f, 0.0f, 0.0f, 0.0f );
	glDepthFunc(GL_LEQUAL);
	glEnable(GL_DEPTH_TEST);
	glfwEnable( GLFW_MOUSE_CURSOR );
	glfwEnable( GLFW_KEY_REPEAT );
	glfwEnable( GLFW_STICKY_KEYS );
	glfwSwapInterval( 1 );
}

extern(C) void characterCallback(int character, int state) {
	char c = cast(char)character;
	if(state == GLFW_PRESS) {
		switch(c) {
			case '+':
				Planet.dt *= 2; glfwSleep(0.1); writeln("Planet.dt = ",Planet.dt);
				break;
			case '-':
				Planet.dt /= 2; glfwSleep(0.1); writeln("Planet.dt = ",Planet.dt);
				break;
			case ' ':
				Planet.Step(planets);
				//Planet.Colide(planets);
				foreach (p; planets) { writeln(p); }
				break;
			case 'q':
				centerPlanet = cast(int)((centerPlanet-1)%planets.length);
				break;
			case 'w':
				centerPlanet = cast(int)((centerPlanet+1)%planets.length);
				break;
			case 'o':
				Planet.showOldPos ^= true;
				writeln("Planet.showOldPos == ",Planet.showOldPos);
				glfwSleep(0.1);
				break;
			case 'p':
				foreach (p; planets) {
					writeln(p);
				}
				break;
			case 'n':
				Planet.nextFunction();
			default: break;
		}
	}

	if(c == 'f' && state == GLFW_PRESS) {
		debug writef("changing window mode: ");
		if(currentWindowType == GLFW_WINDOW) {
			debug write("current WINDOW");
			glfwCloseWindow();
			debug writeln(", change to ",desktopMode.Width, "x", desktopMode.Height);
			glfwOpenWindow( desktopMode.Width, desktopMode.Height, 
			desktopMode.RedBits,desktopMode.GreenBits,desktopMode.BlueBits,0, 0,0, currentWindowType = GLFW_FULLSCREEN );    
			registerCallbacks();
		} else if(currentWindowType == GLFW_FULLSCREEN) {
			debug writeln("current FULLSCREEN");
			glfwCloseWindow();
			glfwOpenWindow( width = origW, height=origH, 0,0,0,0, 0,0, currentWindowType = GLFW_WINDOW );    
			registerCallbacks();
		}
  	}
}

struct Tocka {
	ftype x;
	ftype y;
	ftype z;
}

