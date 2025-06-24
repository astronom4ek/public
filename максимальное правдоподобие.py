'''
Данный файл реализует метод максимального правдоподобия для оценки кривой вращения (те скорости вращения) дисковой галактики Млечный Путь
'''
import numpy as np
from dataclasses import dataclass
from scipy.optimize import minimize

#библиотеки необходимые в дальнейшем
import astropy.io
import matplotlib.pyplot as plt
from astropy.table import Table
from astropy.table import QTable
from astropy.coordinates import SkyCoord
from mpl_toolkits import mplot3d

#расстояние до центра галактики в кило парсеках
R0=8.2

@dataclass 
class Parameters():
    """
    Класс для записи свободных параметров в функции правдоподобия
    """
    U0: float #скорость солнца 
    V0: float
    W0: float
    siqu: float #эллипсодиды скоростей
    siqv: float
    siqw: float
    w0: float
    w1: float
    w2: float #вторая производная локальной угловой скорости 

@dataclass
class Stars ():
    """Хранения параметров населения звезд, все данные в массивах"""
    #Сферические координаты  в гелиоцентрической галактической СК
    r: np.array #Гелиоцентрическое расстояние kpk
    l: np.array #Долгота deg
    b: np.array #Широта deg
        
    #Cферические скорости  собсвенного движения в гелиоцентрической галактической СК
    vr: np.array #радиальная
    vl: np.array #долготная
    vb: np.array #широтная
    
    #Ошибки  скоростей  собсвенного движения в sunГалСК
    vr_err: np.array
    vl_err: np.array
    vb_err: np.array

class Likelihood (): 
    """
    Класс функции правдоподобия LF. При каждой итерации класс изменяет свои внутренние параметры
    метод self.LF(x) Изменяет внутренние параметры с соотвествием массива х
        и  возращает значение LF  при данных параметров.
    Ожидается следующее использование класса в функции минимизатора 
    minimize(likelihood.LF), где likelihood экземляр класса
    
    """
    def __init__ (self,param: Parameters, stars: Stars):
        self.param = param #параметры  ['U0', 'V0', 'W0', 'siqu', 'siqv', 'siqw', 'w0', 'w1', 'w2']
        #Список названий параметров, которые можно варьировать при минимизаци, остальные параметры считаются закрепленными
        self.current_param_key  = list(self.param.__dict__)         
        self.stars = stars #Хранит  данные о звездах,(очевидно данные не изменяются данным классом)
        
        #Вспомогательные расчеты матриц переход, ошибок и тп
        #Делает массив 3-ех мерных векторов скоростей звезд [V1, V2,... Vn] где Vi=[Vr,Vl,Vb]. Для удобства обращения 
        self.NVobs = np.array([[self.stars.vr[i],self.stars.vl[i],self.stars.vb[i]]for i,_ in enumerate(self.stars.vr)])
        #Массив из матриц поворота Gs те [Gs_1, Gs_2,... Gs_N](Gs поворот элипсоида скоростей к локальным, см методичку)
        self.Gs = np.array([Gs_fun(self.stars.r[i], self.stars.b[i], self.stars.l[i]) for i,_ in enumerate(self.stars.b)])
        #Массив из матриц  ошибок скоростей [Lerr_1, Lerr_2, ... Lerr_N]. (см методичку)
        self.Lerr = np.array([[
                        [self.stars.vr_err[i]**2 ,0,0],
                        [0,self.stars.vl_err[i]**2,0],
                        [0,0,self.stars.vb_err[i]**2]]\
                            for i,_ in enumerate(self.stars.vr_err)])
        #массив растояний от звезды до центра галактики
        self.R = np.array([r_centriod_galcenter(self.stars.r[i], self.stars.l[i], self.stars.b[i]) for i,_ in enumerate(self.stars.r)])
        ##Массив из матриц перехода GT те [GT_1, GT_2,... GT_N] (GT поворот, для учета вклада  Vsun на направление на звездy, см методичку)
        self.GT = np.array([GT_fun(self.stars.r[i], self.stars.l[i], self.stars.b[i]) for i,_ in enumerate(self.stars.r)])
        #текущие значенеи функции правдоподобия
        self.lf = float('inf')
        
    def get_x0 (self):
        '''возрашает начальный вектор значения для минимизатора, состоит из НЕ закрепленных  значений '''
        x0 = list()
        for key in self.current_param_key:
            x0.append(self.param.__dict__[key])
        return np.array(x0)
    def set_x0_param(self, var_dict: dict):
        '''для удобвста записывает параметры в виде словаре, чтобы потом вызвать x0, 
        может поменть значение фиксированных переменных, но оставит их фиксированными
        '''
        for key, val in var_dict.items():
            self.edit_param(key, val)
        return self.get_x0()
    
    def edit_param (self, key, value):
        """ Изменяет параметры по ключу и значению"""
        if key in list(param.__dict__):
            self.param.__dict__[key] = value
        else: print(f"{key} not in { param.__dict__.keys()}") 
    
    def fix_var(self, var_dict: dict):
        """фиксирует заданые название значение, предыдущие закрпленные параметры стираются
        то есть по новой идет фиксация, без учета пердыдущий
        """
        keys = list(self.param.__dict__) #список всех доступных наименований параметров
        for key, value in var_dict.items(): 
            keys.remove(key) #убираю фикс парам из списка доступных для изменения названий параметров 
            self.edit_param(key, value)
        self.current_param_key = keys 
        
    def edit_param_from_array(self, x :np.array):
        """ Изменяет параметры по массиву значений
         предпологается, что порядок в массиве соотвествует переменным в пордяке self.current_param_key
         При коррекной работе с классом это гарантированно будет выполнено
        """
        if (len(x) != len (self.current_param_key)):
            raise Exception(f"длина x не свопадает с количеством незафиксированных параметров x: {x},\
                self: {self.current_param_key}")
        for key, xx in zip(self.current_param_key, x):
            self.edit_param(key, xx)
 
    def LF(self, x: np.array):
        """Возращает значени функции максимального правдоподобия при параметрах X и
        сохранает это значение в self.lf
        """
        self.edit_param_from_array(x) #изменение внутренних параметрами согласно x 
        lf = 0
        for i,_ in enumerate(self.stars.r): #для каждой звезды считается значение функции и затем складывается 
            global R0
            R0 = R0 #расстояние до центра галактики kpс
            # индекс i в 'naei' имени переменной означает что подсчитанно только для i-ой звезды, и не массив [name1,name2,... nameN]
            Lsi= np.array([ #матрица дисперсий (неизвестные параметры)
                    [self.param.siqu**2,0,0],
                    [0,self.param.siqv**2,0],
                    [0,0,self.param.siqw**2]
            ])
            
            #модифицированная матрица ковариациий
            #Lobs=Lloc + Lerr
            Lobsi = self.Gs[i].dot(Lsi.dot(self.Gs[i].T)) + self.Lerr[i]
        
            #Разложение в ряд угловой скорости
            w_w0 = self.param.w1*(self.R[i]-R0) +0.5*self.param.w2*(self.R[i]-R0)**2
            
            #Расчет пикулярной скорости 
            #Вклад кругового вращения 
            roti = np.array([
                    R0*w_w0*sin(self.stars.l[i])*cos(self.stars.b[i]),\
                    (R0*cos(self.stars.l[i])-self.stars.r[i]*cos(self.stars.b[i]))*w_w0 - self.param.w0*self.stars.r[i]*cos(self.stars.b[i]),\
                    -R0*w_w0*sin(self.stars.l[i])*sin(self.stars.b[i])\
                    ])
            #Проекция скорости солнца на звезду
            Vsuni = self.GT[i].dot(np.array([self.param.U0,self.param.V0,self.param.W0]))
            #Пикулярная скорость
            dVi = self.NVobs[i] - roti + Vsuni 
            
            #расчет логорифма функции распределения (в трехмерии для нормального трёхосного распределения, см методичку)
            lf+= 0.75*np.log(2*np.pi) + 0.5*np.log(np.abs(np.linalg.det(Lobsi))) +0.5*dVi.dot(np.linalg.inv(Lobsi).dot(dVi))
        #print (lf)
        self.lf = lf
        return lf
    

if __name__=="__main__":
    #начальные параметры 
    param = Parameters(U0=10,V0=12,W0=7,siqu=14,siqv=9,siqw=7,w0=27.5,w1=-4.4,w2=0.8)
   
    #параметры скоростей ниже считались на основе наблюдений скоростей движения звезд, их подсчет в данном примере не интересен
    #сгенерирум случайно распределенные звезды
    stars_sun = Stars(
        r = np.zeros(1000),
        l = np.zeros(1000),
        b = np.zeros(1000),
        vr = np.zeros(1000),
        vl = np.random.normal(12,20,size=1000), 
        vb = np.zeros(1000),
        vr_err = np.zeros(1000),
        vl_err = np.zeros(1000),
        vb_err = np.zeros(1000),   
    )

    #иницилиазируем объект начальными параметрами
    step = Likelihood(param,stars_sun)

    #проведем тестирование функционала
    #Выведем список доступных параметров для проверки реализации
    print("изначально все пармаетры свободные: ", step.current_param_key)  #['U0', 'V0', 'W0', 'siqu', 'siqv', 'siqw', 'w0', 'w1', 'w2']
    print ("   *****   зафиксируем U0")
    step.fix_var({'U0': 15})
    print("после фиксации из списка пропала закрпеленная UO: ", step.current_param_key)

    #запускаем минимизацию. Печатаются текущие значение LF Видно что в конце они очень медленно уменьшаются (это почти плато минимума)
    res0 = minimize(step.LF, step.get_x0(), method='nelder-mead',
        options={'xtol': 1e-8, 'disp': True})

    
    #запускаем минимизацию. Печатаются текущие значение LF Видно что в конце они очень медленно уменьшаются (это почти плато минимума)
    res0 = minimize(step.LF, step.get_x0(), method='nelder-mead',
        options={'xtol': 1e-8, 'disp': True})

    print (res0)
    #прооверим значение переменных
    print(step.param.__dict__)
    #необходимо повторить минимизацию пока фит не будет успешным, обычно хватает два раза, с заменой НУ на результат фита 
