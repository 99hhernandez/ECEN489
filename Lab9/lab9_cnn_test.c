#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>

#define WIDTH 16
#define DECIMAL 8

#define MAXTESTCASE 1000

#define LENW 0x1f54*WIDTH/8
#define LENIN 28*28*WIDTH/8

int main() {
	int i,j;
	FILE *fptr;
	char ch;
    fptr = fopen("cnn_data", "r");
	if (fptr == NULL){
		printf("Cannot open CNN data\n");
		exit(0);
	}
	/*
	char data[LEN];
	i=0;
	ch = fgetc(fptr);
	while (i<LEN){
		data[i]=ch;
		ch = fgetc(fptr);
		i++;
	}*/
	
    int fd;
    
    fd=open("/dev/transfpga",O_RDWR);
    
    if(fd == -1) {
        printf("Failed to open device file!\n");
        return -1;
    }
    int temp[1];
    
    int correct=0;
    
    int test;
    for(test=0;test<MAXTESTCASE;test++){
		if(test<2)
		printf("send the figure and weights to FPGA\n");
		temp[0]=0x3;
		write(fd, (char*)temp, 0);
		
		temp[0]=0;
		write(fd, (char*)temp, 1);
		if(test==0)
		temp[0]=0;
		else
		temp[0]=1;
		write(fd, (char*)temp, 2);
		
		if(test==0){
			for(i=1;i<LENW+1;i++){
				temp[0]=i;
				write(fd, (char*)temp, 1);
				ch = fgetc(fptr);
				temp[0]=ch;
				write(fd, (char*)temp, 2);
			}
		}
		
		for(i=LENW+1;i<LENW+LENIN+1;i++){
			temp[0]=i;
			write(fd, (char*)temp, 1);
			ch = fgetc(fptr);
			temp[0]=ch;
			write(fd, (char*)temp, 2);
		}
		
		temp[0]=0x0;
		write(fd, (char*)temp, 0);
		if(test<2)
		printf("trigger systolic array\n");
		if(test<2)
		printf("wait for systolic array\n");
		read(fd, (char*)temp, 3);
		while((temp[0]&0x100)==0){
			read(fd, (char*)temp, 3);
		}
		if(test<2)
		printf("read back the results\n");
		temp[0]=0x1;
		write(fd, (char*)temp, 0);
		/*
		for(i=0;i<100;i++){
			temp[0]=i;
			write(fd, (char*)temp, 1);
			read(fd, (char*)temp, 3);
			printf("%d->%x\n",i,temp[0]&0xff);
		}
		
		for(i=30000;i<30000+0x2000;i++){
			temp[0]=i;
			write(fd, (char*)temp, 1);
			read(fd, (char*)temp, 3);
			if((temp[0]&0xff)!=0)
			printf("%d->%x\n",i,temp[0]&0xff);
		}*/
		int decision=-1;
		signed int max=-10000000;
		signed int number=0;
		for(i=0;i<10;i++){
			number=0;
			for(j=0;j<WIDTH/8;j++){
				temp[0]=20000+WIDTH/8*i+j;
				write(fd, (char*)temp, 1);
				read(fd, (char*)temp, 3);
				number=number|((temp[0]&0xff)<<(8*j));
			}
			if(number&(1<<(WIDTH-1))){
				number=number|(0xffffffff<<WIDTH);
			}
			if(number>=max){
				max=number;
				decision=i;
			}
			if(test<2)
			printf("testcase %d, probability: %d->%f\n",test,i,((double)number)/(1<<DECIMAL));
		}
		if(test<2)
		printf("testcase %d, the number is %d\n",test,decision);
		number=0;
		for(j=0;j<WIDTH/8;j++){
			/*
			if(test<2){
			printf("%x\n",fgetc(fptr));
			printf("%x\n",fgetc(fptr));
			}else{
				fgetc(fptr);
				fgetc(fptr);
			}*/
			number=number|(fgetc(fptr)<<(8*j));
		}
		if(decision==(number>>DECIMAL)){
			if(test<2)
			printf("correct\n");
			correct++;
		}
	}
	printf("accuracy: %f\n",((double)correct)/MAXTESTCASE);
    close(fd);
    return 0;
}
