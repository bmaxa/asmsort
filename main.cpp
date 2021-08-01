#include <cstdlib>
#include <ctime>
#include <vector>
#include <list>
#include <algorithm>
#include <iostream>
#include <sys/time.h>

#include "QSort.h"
/*extern "C" void radix_sort_avx2(int*,int);
extern "C" void bitonic_sort_avx2(int,int*,int);*/
struct Gen{
  int operator()()
  {
    return rand()%100000;
  }
};

static int cmp(const void* l, const void* r)
{
  const int ll = *(const int*)(l), rr = *(const int*)(r);
  if (ll < rr) return -1;
  else return ll > rr;
}

const long N = 4096*4096;
using namespace std;
int main()
{
  vector<int> unsorted_arr(N),arr0,arr1,arr2,arr3,arr4;
  list<int> unsorted_lst(N),lst0,lst1;
  srand(time(0));
  generate(unsorted_arr.begin(),unsorted_arr.end(),Gen());
  generate(unsorted_lst.begin(),unsorted_lst.end(),Gen());
  arr0 = arr1 = arr2 = arr3 = arr4 = unsorted_arr;
  lst0 = lst1 = unsorted_lst;
  timeval start;
  gettimeofday(&start,0);
  //radix_sort_avx2(&arr0[0],arr0.size());
  timeval end;
  gettimeofday(&end,0);
  cout<<"radix asm sort "<<((end.tv_sec-start.tv_sec)*1000.0 + (end.tv_usec-start.tv_usec)/1000.0)<<'\n';
  gettimeofday(&start,0);
  //bitonic_sort_avx2(1,&arr4[0],arr4.size());
  gettimeofday(&end,0);
  cout<<"asm bitonic sort "<<((end.tv_sec-start.tv_sec)*1000.0 + (end.tv_usec-start.tv_usec)/1000.0)<<'\n';
  gettimeofday(&start,0);
  sort(arr1.begin(),arr1.end());
  gettimeofday(&end,0);
  cout<<"C++ sort "<<((end.tv_sec-start.tv_sec)*1000.0 + (end.tv_usec-start.tv_usec)/1000.0)<<'\n';
  gettimeofday(&start,0);
  VLib::qsort(arr2.begin(),arr2.end(),0,0);
  gettimeofday(&end,0);
  cout<<"VLib sort "<<((end.tv_sec-start.tv_sec)*1000.0 + (end.tv_usec-start.tv_usec)/1000.0)<<'\n';
  gettimeofday(&start,0);
  qsort(&arr3[0],arr3.size(),sizeof(int),cmp);
  gettimeofday(&end,0);
  cout<<"C qsort "<<((end.tv_sec-start.tv_sec)*1000.0 + (end.tv_usec-start.tv_usec)/1000.0)<<'\n';
  gettimeofday(&start,0);
  lst0.sort();
  gettimeofday(&end,0);
  cout<<"C++ list sort "<<((end.tv_sec-start.tv_sec)*1000.0 + (end.tv_usec-start.tv_usec)/1000.0)<<'\n';
  gettimeofday(&start,0);
  VLib::qsort(lst1.begin(),lst1.end(),0,0);
  gettimeofday(&end,0);
  cout<<"VLib list sort "<<((end.tv_sec-start.tv_sec)*1000.0 + (end.tv_usec-start.tv_usec)/1000.0)<<'\n';
  if (lst0 == lst1 && arr1 == arr0 && arr1 == arr2 && arr1 == arr3) cout << "all set\n";
  else cout <<"fail\n";
}
