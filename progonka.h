//Решение уравнения теплопроводности методом прямой и обратной прогонки
//выполнено в 2023 году


#define PI 3.141592653589793

//An*Vmn1-CnVmn+An*Vmn_1=-Fn
struct Step_param{
  double A; 
  double C;
  double B;
  double kapa1;
  double eta1;
  double kapa2;
  double eta2;
};

struct Grid_param{
  int Nx; //количесво точек разбиения по коодинате 
  int Ny;
  int Nt; // по времени (не используется толком) 
  double t; // шаг по времени
  double hx; // шаг по коорднате 
  double hy; // шаг по коорднате 
  double start_x; // начальные точки старта для коррдинаты и времени. конечные вычислятся по h и Nh
  double start_y; // начальные точки старта для коррдинаты и времени. конечные вычислятся по h и Nh
  double start_t; // время задачи НУ (те 0); конечные вычилсяются по внешне задангом T (до куда считать) 
};

double fi(int m,int n,  double s, Grid_param grid_p){
  //double x = m*grid_p.hx*m;
  double y = m*grid_p.hy;
  return cos(PI*y)*exp(-s);
}
double Ksi_m1(Step_param stepp_n, double & Fn, double &ksin, double &etan){
  return stepp_n.B/(stepp_n.C-stepp_n.A*ksin);}
double Gama_m1(Step_param stepp_n,double & Fn, double &ksin, double &gaman){
  return (Fn+stepp_n.A*gaman)/(stepp_n.C-stepp_n.A*ksin);}

void premoy(Step_param stepp_n, std::vector <double>& Fn, std::vector <double>& Y, Grid_param grid_p){
  //std::vector <double> *Y = new std::vector<double> (gridp.Nh);
  const int N=Y.size();
  std::vector <double> *KSI = new std::vector<double> (Y.size());
  std::vector <double> *GAMA = new std::vector<double> (Y.size());
  
  //считает прогоночные коффициенты прямым ходом
  (*KSI)[0] =stepp_n.kapa1;
  (*GAMA)[0]=stepp_n.eta1;
  for (int n=1; n<N;n++){          
    (*KSI)[n] =Ksi_m1 (stepp_n, Fn[n-1],(*KSI)[n-1], (*GAMA)[n-1]);
    (*GAMA)[n]=Gama_m1(stepp_n, Fn[n-1],(*KSI)[n-1], (*GAMA)[n-1]);

  }
    
  //считаем yN обратнотным ходом
  //N-1 так ка индекская идет не включитлеьно N
  Y[N-1]=(stepp_n.eta2+stepp_n.kapa2*(*GAMA)[N-1])/(1-stepp_n.kapa2*(*KSI)[N-1]);
  for(int n=N-1; n>0;n--  ){
   Y[n-1]=(*KSI)[n]* Y[n]+(*GAMA)[n];
  }
  // на Выходе имеем массви Y на s+0.5 слое  

}

void time_step(std::vector <std::vector <double>> &GRID, std::vector <std::vector <double>> &GRID_new, Grid_param grid_p, double S){
  //S время текущега шага
  std::vector <double> Z(grid_p.Nx,-1);
  std::vector <double> Fn(grid_p.Nx,0);
  Step_param stepp_n;

 //прогонка вдоль y
  stepp_n.A=1/(grid_p.hy*grid_p.hy) ;
  stepp_n.C=1/(grid_p.hy*grid_p.hy)+2/grid_p.t;
  stepp_n.B=1/(grid_p.hx*grid_p.hx) ;

  //зависит от уравнения 
  stepp_n.eta1= 0;
  stepp_n.eta2= 0;
  stepp_n.kapa1=1 ;
  stepp_n.kapa2=1 ;
  //сетка n по y;  m по х 
  for(int m =0;m<grid_p.Nx;m++){
    for (int n=0;n<grid_p.Ny;n++){
      Fn[n]=2/grid_p.t*GRID[n][m]+1/grid_p.hx/grid_p.hx *(GRID[n][m+1]-2*GRID[n][m]+GRID[n][m-1])+fi(m,n,S+0.5*grid_p.t, grid_p);
    }
    premoy(stepp_n, Fn, Z, grid_p);
    //std::cout<<"Z IS: ";
    //for (int i=0; i<Z.size();i++){std::cout<<Z[i]<<' ';}
    //std::cout<<'\n';
    for (int n=0;n<grid_p.Ny;n++){
      GRID_new[n][m]=Z[n];
    }
  }
  
   // прогонка вдоль y 
   Z.resize(grid_p.Ny);
  Fn.resize(grid_p.Ny);
  stepp_n.A=1/(grid_p.hx*grid_p.hx) ;
  stepp_n.C=1/(grid_p.hx*grid_p.hx)+2/grid_p.t;
  stepp_n.B=1/(grid_p.hy*grid_p.hy) ;

  //зависит от уравнения 
  stepp_n.eta1= 0;
  stepp_n.eta2= 0;
  stepp_n.kapa1= 1;
  stepp_n.kapa2= 1;
//возможо надо начинать +-1  индекс
  for(int n=1;n<grid_p.Ny-1;n++){
    for(int m=1;m<grid_p.Nx-1;m++){
      Fn[m]=2/grid_p.t*GRID[n][m]+1/grid_p.hy/grid_p.hy *(GRID[n+1][m]-2*GRID[n][m]+GRID[n-1][m])+fi(m,n,S+1*grid_p.t,grid_p);
    }
    premoy(stepp_n,Fn, Z, grid_p);
    for(int m;m<grid_p.Nx;m++){
      GRID_new[n][m]=Z[m];
    }
  }
}

void show_grid (std::vector <std::vector <double> >& GRID){
   //std::vector <std::vector <double> > GRID=*p;
  //std::cout<<GRID[0].size()<<'\n';
    for(int i=0;i<GRID.size();i++){
      for(int j=0;j<GRID[0].size();j++){
        std::cout<<GRID[i][j]<<" ";
        //GRID[i][j] = i*20+j;
      }
      std::cout<<std::endl;
    }

}
void solve_system(double N, double T_end){
  //std::vector <double> * = new std::vector<double> (gridp.Nh);
  //DRID[x][y]
  Grid_param grid_p;
  grid_p.Nx =N;
  grid_p.Ny =N;
  grid_p.Nt=T_end*N;
  grid_p.hx=1/N;
  grid_p.hy=1/N;
  grid_p.t=T_end/grid_p.Nt;

  grid_p.start_t=0;

  std::vector <std::vector <double> > GRID(grid_p.Ny, std::vector<double>(grid_p.Nx,0));
  std::vector <std::vector <double> > GRID_new(grid_p.Ny, std::vector<double>(grid_p.Nx,0));

  std::vector <std::vector <double> >* pGRID=&GRID;
  std::vector <std::vector <double> >* pGRID_new=&GRID_new;
  std::vector <std::vector <double> >* ptmp;

  std::cout<<"xsize: "<<GRID[0].size()<<" ysize: "<<GRID.size()<< " tzise: "<<grid_p.Nt<<'\n';
  //зададим начальные условия. Оно уже задано по умолчанию нулями все ок; 
  for(int i=0;i<GRID.size();i++){
      for(int j=0;j<GRID[0].size();j++){
        GRID[i][j] = 0;
      }
    }

  for (double T=grid_p.start_t; T<T_end; T+=grid_p.t){
     //зададим граничные условия

     time_step(*pGRID, *pGRID_new, grid_p, T);
      
     std::cout<<"time: "<<T<<'\n';
     show_grid(*pGRID);
      
     //меняем сетку местами
     ptmp=pGRID_new;
     pGRID_new=pGRID;
     pGRID=ptmp;
  }
  
}

///для запуска используется код из отдельного файла 
//второе задание на тепловроподность
//задача 10

#include<iostream>
#include<stdlib.h>
#include<math.h>
#include<vector>

#include"progonka.h"

void show (std::vector <std::vector <double> >& GRID){
   //std::vector <std::vector <double> > GRID=*p;
  std::cout<<GRID[0].size()<<'\n';
    for(int i=0;i<GRID.size();i++){
      for(int j=0;j<GRID[0].size();j++){
        std::cout<<GRID[i][j]<<" ";
        GRID[i][j] = i*20+j;
        }
        std::cout<<std::endl;
    }

}
int main(int argc, const char**argv){
  solve_system(10,10); 
  return 0;
}
