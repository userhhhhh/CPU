#include "io.h"
int a[100]={1,2,3,4,5,6,7,8,9,10};
int b[100]={10,9,8,7,6,5,4,3,2,1};
int main() {
  int e=5;
  int c=9; int d=1;
  for (int i = 0; i < 100; ++i) { 
    a[i]=i;
    b[i]=i;
  }
    for(int i = 0; i  < 100; ++i){
      c+= a[i]+b[i];
      e = d+e;
    }
    outl(c);
    outl(e);
}
