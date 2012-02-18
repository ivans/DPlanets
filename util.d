module util;

private import std.stream;
private import std.math;

class array(T) {
	static T[] opIndex(T[] a ...) {
    	return a.dup;
	}
}

alias real ftype;
alias array!(ftype) newftypeArray;
alias array!(ftype[]) newftypeArrayArray;

class Quaternion {

	static Quaternion opCall(ftype aa1=0, ftype aa2=0, ftype aa3=0, ftype aa4=0) {
		Quaternion q = new Quaternion();
		q.a1 = aa1;
		q.a2 = aa2;
		q.a3 = aa3;
		q.a4 = aa4;
		return q;
	}

	Quaternion dup() {
		return Quaternion(a1,a2,a3,a4);
	}

	static this() {
		p = new Quaternion();
		q = new Quaternion();
		mulres = new Quaternion();
		conjQ = new Quaternion();
	}

	Quaternion opMul(Quaternion that) {
		mulres.set(
			this.a1*that.a1 - this.a2*that.a2 - this.a3*that.a3 - this.a4*that.a4,
			this.a1*that.a2 + this.a2*that.a1 + this.a3*that.a4 - this.a4*that.a3,
			this.a1*that.a3 - this.a2*that.a4 + this.a3*that.a1 + this.a4*that.a2,
			this.a1*that.a4 + this.a2*that.a3 - this.a3*that.a2 + this.a4*that.a1
		);
		return mulres;
	}

	static Quaternion makeRotation(ftype angle, ftype x, ftype y, ftype z) {
		ftype sinus = sin(0.5*angle);
		q.set(cos(0.5*angle), sinus*x, sinus*y, sinus*z);
		return q;
	}

	Quaternion conj() {
		conjQ.set(this.a1,-this.a2,-this.a3,-this.a4);
		return conjQ;
	}

	void set(ftype aa1, ftype aa2, ftype aa3, ftype aa4) {
		this.a1 = aa1;
		this.a2 = aa2;
		this.a3 = aa3;
		this.a4 = aa4;
	}

	void setrot(ftype aa2, ftype aa3, ftype aa4) {
		this.a1 = 0;
		this.a2 = aa2;
		this.a3 = aa3;
		this.a4 = aa4;
	}

	void toStream(Stream s) {
		s.writefln("[", a1, ", ", a2, ", ", a3, ", ", a4,"]");
	}

	ftype[] getPoint() {
		return newftypeArray[a2,a3,a4];
	}

	static void rotate(ref ftype x, ref ftype y, ref ftype z, ftype Ra, ftype Rx, ftype Ry, ftype Rz) {
		p.setrot(x,y,z);
		q = Quaternion.makeRotation(Ra,Rx,Ry,Rz);
		p = (q * p) * q.conj();
		x = p.a2;
		y = p.a3;
		z = p.a4;
	}
  
	string toString() {
		return std.string.format("(%s,%s,%s,%s)",a1,a2,a3,a4);
	}
  
	void rotate(ref ftype x, ref ftype y, ref ftype z) {
		p.setrot(x,y,z);
		q = this;
		p = (q * p) * q.conj();
		x = p.a2;
		y = p.a3;
		z = p.a4;
	}

	Quaternion negativeRot() {
    	return Quaternion(-a1,-a2,-a3,-a4);
	}

	static Quaternion slerp(Quaternion from, Quaternion to, ftype t) {
		Quaternion p = from;

		ftype cosom = from.a1*to.a1 + from.a2*to.a2 + from.a3*to.a3 + from.a4*to.a4;

		Quaternion q = Quaternion();
		Quaternion result = Quaternion();
		
		if(cosom < 0) {
			cosom = -cosom;
			q.data[0] = -to.data[0];
			q.data[1] = -to.data[1];
			q.data[2] = -to.data[2];
			q.data[3] = -to.data[3];
		} else {
			q = to;
		}
		
		ftype sclp, sclq;
		if ((1.0 - cosom) > cast(ftype)0.0001) {
			ftype omega, sinom;
			omega = acos( cosom );
			sinom = sin( omega );
			sclp  = sin( (cast(ftype)1.0 - t) * omega ) / sinom;
			sclq  = sin( t * omega ) / sinom;
		} else {
			sclp = cast(ftype)1.0 - t;
			sclq = t;
		}

		result.data[0] = sclp * p.data[0] + sclq * q.data[0];
		result.data[1] = sclp * p.data[1] + sclq * q.data[1];
		result.data[2] = sclp * p.data[2] + sclq * q.data[2];
		result.data[3] = sclp * p.data[3] + sclq * q.data[3];
		return result;
	}

	static Quaternion p, q, mulres, conjQ;

	union {
		struct {ftype a1, a2, a3, a4;}
		ftype[4] data;
	}
}
