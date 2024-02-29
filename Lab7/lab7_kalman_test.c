#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <math.h>

#define DSIZE 16
#define DECIMAL 10

#define pi 3.14159265358979323846

int read_word(int fd, unsigned int *addr){
	int data=0;
	int i;
	int temp[1];
	for(i=0;i<DSIZE/8;i++){
		temp[0]=(*addr)+i;
		write(fd, (char*)temp, 1);
		read(fd, (char*)temp, 3);
		data=data|((temp[0]&0xff)<<(8*i));
	}
	if(data>>(DSIZE-1)){
		data=data|(0xffffffff<<DSIZE);
	}
	(*addr)=(*addr)+DSIZE/8;
	return data;
}

void write_word(int fd, unsigned int *addr, int data){
	int i;
	int temp[1];
	for(i=0;i<DSIZE/8;i++){
		temp[0]=(*addr)+i;
		write(fd, (char*)temp, 1);
		temp[0]=(data>>(8*i))&0xff;
		write(fd, (char*)temp, 2);
	}
	(*addr)=(*addr)+DSIZE/8;
}

void write_double(int fd, unsigned int *addr, double data){
	write_word(fd, addr, (int)(data*(1<<DECIMAL)));
}

int main(int argc, char** argv) {
	if(argc<2){
		printf("please input the number of the FPGA clock cycles between each sampling\n");
		exit(0);
	}
	
	int gap;
	sscanf(argv[1], "%d", &gap);
	printf("Your interval between sampling is %d\n",gap);
	
	int i,j;
	
    int fd;
    
    fd=open("/dev/transfpga",O_RDWR);
    
    if(fd == -1) {
        printf("Failed to open device file!\n");
        return -1;
    }
    
    FILE *fptr;
	unsigned char ch;
    fptr = fopen("lab7_data", "r");
	if (fptr == NULL){
		printf("Cannot open lab7_data\n");
		exit(0);
	}
	
	int ori[1000],u[1000],p[1000],v[1000];
	int readdata;
	for(i=0;i<1000;i++){
		readdata=0;
		for(j=0;j<DSIZE/8;j++){
			ch=fgetc(fptr);
			readdata=readdata|(ch<<(8*j));
		}
		u[i]=readdata;
	}
	for(i=0;i<1000;i++){
		readdata=0;
		for(j=0;j<DSIZE/8;j++){
			ch=fgetc(fptr);
			readdata=readdata|(ch<<(8*j));
		}
		p[i]=readdata;
	}
	for(i=0;i<1000;i++){
		readdata=0;
		for(j=0;j<DSIZE/8;j++){
			ch=fgetc(fptr);
			readdata=readdata|(ch<<(8*j));
		}
		v[i]=readdata;
	}
	for(i=0;i<1000;i++){
		readdata=0;
		for(j=0;j<DSIZE/8;j++){
			ch=fgetc(fptr);
			readdata=readdata|(ch<<(8*j));
		}
		ori[i]=readdata;
	}
	fclose(fptr);
    
    double t;
    double dt;
    dt=0.1;
    
    int temp[1];
    temp[0]=0x3;
	write(fd, (char*)temp, 0);
    
    //x0
    int addr[1];
    addr[0]=0;
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.0);
    //P0
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.0);
    //F
    write_double(fd, addr, 1.0);
    write_double(fd, addr, 1.0*gap*dt);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 1.0);
    //B
    write_double(fd, addr, 0.5*gap*dt*gap*dt);
    write_double(fd, addr, 1.0*gap*dt);
    //H
    write_double(fd, addr, 1.0);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 1.0);
    //Q
    write_double(fd, addr, 0.2);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.2);
    //R
    write_double(fd, addr, 0.2);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.0);
    write_double(fd, addr, 0.2);
    
    (*addr)=100;
    for(i=0;i<1000;i++){
		write_word(fd, addr, u[i]);
		write_word(fd, addr, p[i]);
		write_word(fd, addr, v[i]);
	}
    /*
    double a=0.0;
    double v=0.0;
    double p=0.0;
    for(i=0;i<1000;i++){
		a=sin(pi/2*i*0.1)/10;
		write_double(fd, addr, a);
		p=p+v*dt+0.5*a*dt*dt;
		v=v+a*dt;
		write_double(fd, addr, p);
		write_double(fd, addr, v);
	}*/
    
    temp[0]=0x0;
	write(fd, (char*)temp, 0);
	//printf("trigger FPGA\n");
	
	//printf("wait for FPGA\n");
	read(fd, (char*)temp, 3);
	while((temp[0]&0x100)==0){
		read(fd, (char*)temp, 3);
	}
	
	//printf("read back the results\n");
	temp[0]=0x1;
	write(fd, (char*)temp, 0);
	
	int data;
	double vdata;
	
	/*
	(*addr)=0;
	for(i=0;i<250;i++){
		data=read_word(fd, addr);
		vdata=((double)data)/(1<<DECIMAL);
		printf("%d, %f\n",i,vdata);
	}*/
	
	//int data;
	//double vdata;
	(*addr)=15000;
	for(i=0;i<1000;i++){
		data=read_word(fd, addr);
		if(data!=(1<<(DSIZE-1))-1){
			vdata=((double)data)/(1<<DECIMAL);
			printf("time: %f, filtered data: %f, difference with ideal output: %f\n",0.1*i,vdata,vdata-((double)(ori[i]))/(1<<DECIMAL));
		}
	}
    close(fd);
    return 0;
}
