#include <stdio.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>

#define BRAM_CTRL_0 0x40000000
#define DATA_LEN    6

int fd;
unsigned int *map_base0;

int sigintHandler(int sig_num)
{

     printf("\n Terminating using Ctrl+C \n");
     fflush(stdout);

     close(fd);

     munmap(map_base0, DATA_LEN);

     return 0;
}

int main(int argc, char **argv)
{
     signal(SIGINT, sigintHandler);

     fd = open("/dev/mem", O_RDWR | O_SYNC);

     if (fd < 0) 
     {
          printf("can not open /dev/mem \n");
          return (-1);
     }   

     printf("/dev/mem is open \n");

     map_base0 = mmap(NULL, DATA_LEN * 4, PROT_READ | PROT_WRITE, MAP_SHARED, fd, BRAM_CTRL_0);

     if (map_base0 == 0)
     {
          printf("NULL pointer\n");
     }   
     else
     {
          printf("mmap successful\n");
     }   

     unsigned long addr;
     unsigned int content;
     int i = 0;

     addr = (unsigned long)(map_base0 + 1);
     content = 0x7;
     map_base0[1] = content;

     printf("%2dth data, address: 0x%lx data_write: 0x%x\t\t\n", i, addr, content);

     addr = (unsigned long)(map_base0 + 0);
     content = 0x1;
     map_base0[0] = content;

     printf("%2dth data, address: 0x%lx data_write: 0x%x\t\t\n", i, addr, content);
     
     addr = (unsigned long)(map_base0 + 2);
     content = 0x7;
     map_base0[2] = content;

     printf("%2dth data, address: 0x%lx data_write: 0x%x\t\t\n", i, addr, content);

     addr = (unsigned long)(map_base0 + 0);
     content = 0x2;
     map_base0[0] = content;

     printf("%2dth data, address: 0x%lx data_write: 0x%x\t\t\n", i, addr, content);

     while(1)
     {
          addr = (unsigned long)(map_base0 + 0);
          content = 0x3;
          map_base0[0] = content;

          printf("%2dth data, address: 0x%lx data_write: 0x%x\t\t\n", i, addr, content);

          sleep(1);

          printf("\nread data from bram\n");
          for (i = 0; i < DATA_LEN; i++)
          {
               addr = (unsigned long)(map_base0 + i);
               content = map_base0[i];
               printf("%2dth data, address: 0x%lx data_read: 0x%x\t\t\n", i, addr, content);
          }   

          
     }
     
}

