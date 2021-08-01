//=============================================================================
//
// Copyright  :  (c) 2004 by Dzenis Softic / http://www.dzeni.com
//
// Filename   : 
//
// Description: 
//
// Company    : Seenetix D.O.O.
//
// Authors    : B. Maksimovic
//
// $Id$
//
//=============================================================================
#ifndef VLIBQSORT_H
#define VLIBQSORT_H

#include <pthread.h>
#include <algorithm>
#include <functional>

namespace VLib{
using std::swap;

template <typename T, typename F>
inline T median_of_three(T a, T b, T c, F f)
{
  if (f(*a , *b))
    if (f(*b , *c))
      return b; 
    else if (f(*a , *c))
           return c;
         else
           return a;
  else if (f(*a , *c))
         return a;
       else if (f(*b , *c))
              return c;
            else
              return b;
}


template <typename T, typename F>
void insertion_sort(T begin, T end, F f)
{
  if(begin == end)return;
  T i = begin;
  ++i;
  for(;i!=end;++i)
  {
    typeof(*i) v = *i;
    T j = i;
    --j;
    while(f(v,*j))
    {
      T k = j;
      ++k;
      *k = *j;
      if(j == begin){--j;break;}
      --j;
    }
    ++j;
    *j = v;
  }
}


template <typename T,typename F>
void qsort(T begin, T end, unsigned size, int t, F f)
{
  struct Data{ 
   T i, j; unsigned k,t; F f;
   static void* qs(void* d)
   {
    Data* t = (Data*)d;
    VLib::qsort(t->i,t->j,t->k,t->t-1,t->f);
    return 0;
   }
  };
  class Thread{
  public:
   typedef void* (*f_t)(void*);
   Thread(f_t f,void* p)
   : f_(f),data_(p)
   {
    pthread_attr_init(&attr_);
    pthread_attr_setstacksize(&attr_,256*1024);
   }
   void start()
   {
    pthread_create(&tid_,&attr_,f_,data_);
   }
   void join()
   {
    pthread_join(tid_,0);
   }
   ~Thread()
   {
    pthread_attr_destroy(&attr_);
    join();
   }
  private:
   pthread_t tid_;
   pthread_attr_t attr_;
   f_t f_;
   void* data_;
  };

  if(begin == end)return;

  T high = end, low = begin;
  if(!size)
  {
   T tmp = begin;
   while(tmp!=end){ high=tmp++;++size; }
  }
  else --high;

  if(size == 1)return;
  if(size <= 16)
  {
    insertion_sort(begin,end,f);
    return;
  }
  unsigned count = 0;
  T it = begin;
  while(++count<size/2)++it;
  it = median_of_three(begin,it,high,f);
  typeof(*it) pivot = *it;
  unsigned counthigh = 0,countlow = 0;
  do
  {
    while(high != low && f(pivot,*high)){ --high;++counthigh; }
    while(low != high && f(*low,pivot)){ ++low;++countlow; }
    if(low != high && !f(*low,pivot) && !f(pivot,*low) && !f(pivot,*high) && !f(*high,pivot))
    {
     while(high != low && !f(*high,*low) && !f(*low,*high)){ --high;++counthigh; }
    }
    swap(*low,*high);
  }while(low != high);
  T i = low;
  while(++i != end && !f(*i,*low) && !f(*low,*i) )--counthigh;

  if(t>0 && size > 1000)
  {
   Data d1 = {begin,low,countlow,t,f}, d2 = {i,end,counthigh,t,f};
   Thread t1(Data::qs,&d1),t2(Data::qs,&d2);
   t1.start();
   t2.start();
  } 
  else 
  {
   VLib::qsort(begin,low,countlow,0,f);
   VLib::qsort(i,end,counthigh,0,f);
  }
}

template <typename T>
inline void qsort(T begin, T end, unsigned size = 0, int t = 2)
{
 VLib::qsort(begin,end,size,t,std::less<typename std::iterator_traits<T>::value_type>());
}

}
#endif
//=============================================================================
// History:
//
// $Log$
// Revision 1.9  2012/06/06 12:11:38  bmaxa
// *** empty log message ***
//
// Revision 1.8  2012/06/05 19:46:35  bmaxa
// *** empty log message ***
//
// Revision 1.7  2012/06/05 09:35:18  bmaxa
// *** empty log message ***
//
// Revision 1.6  2009/12/25 16:59:35  bmaxa
// *** empty log message ***
//
// Revision 1.5  2009/12/25 16:43:40  bmaxa
// *** empty log message ***
//
// Revision 1.4  2009/12/04 13:16:47  bmaxa
// added possibility to pass sorting function
//
// Revision 1.3  2009/12/03 10:50:26  vmp
// increased thread stack size to 256k
//
// Revision 1.2  2009/11/30 21:35:43  vmp
// *** empty log message ***
//
// Revision 1.1  2009/11/30 17:25:34  vmp
// added
//
//
//
//
//
//
//=============================================================================

