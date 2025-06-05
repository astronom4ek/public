"""
Данный код работает с кубом спектральных данных
    проверяет наличие данных, если их нет скачивает 
    Вырезает из данных нужный кусок
    Запускает стрипт BBarolo для их обработки
    Рисует графики с резульататом
"""


import marvin 
from astropy.io import fits 
import os
import wget
import numpy as np
import matplotlib.pyplot as plt
import marvin
from marvin import config
config.switchSasUrl(sasmode='mirror')
import pandas as pd
from astropy.units import angstrom
import subprocess
import sys

PLT_TIME_PAUSE=5 #in sec

def downloads_cube(plateifu, dirname='cubefile/'):
    #скачиваем файл
    name_manga = f'manga-{plateifu}-LINCUBE.fits.gz'
    save_path=dirname+name_manga
    if not os.path.isfile(save_path):
        plate = name_manga.split('-')[1]
        url = f'https://data.sdss.org/sas/dr17/manga/spectro/redux/v3_1_1/{plate}/stack/{name_manga}'
        # wget.download(url,save_path)
        subprocess.run(['wget', "-o", save_path, "-c", url])

    else:
        print("file is exist")
    return save_path

def get_z (plateifu,all_gal_path="~/rotate/list_galaxy_from_Beom_v2.csv"):
    all_gal_df = pd.read_csv("~/rotate/list_galaxy_from_Beom_v2.csv")
    z =  all_gal_df[all_gal_df.PlateifuID==plateifu]['z']
    return np.array(z)[0]

def plot_center_spectr(cube, center=None,block:bool=False,plot=True):
    """строим общий вид спектра"""
    if center==None: center=cube.flux.shape[1]//2
    z = get_z(cube.plateifu)
    cube[center,center].flux.plot()
    if plot==True:
        plt.axvline(6563*(1+z),color="green")
        plt.axvline(6584*(1+z),color='red')
        plt.show(block=False)
        plt.pause(PLT_TIME_PAUSE)    

def choice_line_and_width (cube,z,center=None,plot=True):
    #границы линий (пока автоматически)
    if center==None: 
        center=cube.flux.shape[1]//2
    haleft, haright = np.searchsorted(cube.flux.wavelength, np.array([6553,6573])*(1+z)*angstrom)
    niileft, niiright = np.searchsorted(cube.flux.wavelength,np.array([6574,6594])*(1+z)*angstrom)
    line_center_flux = cube.flux[np.searchsorted(cube.flux.wavelength,np.array([6564,6584])*(1+z)*angstrom),center,center]
    if (line_center_flux[0]-line_center_flux[1])>0:#Halpga biger
        left, right = haleft, haright
        center_line = 6563
    else: #Nii biger
        left, right = niileft, niiright
        center_line = 6584
    flux=cube.flux
    center=flux.shape[1]//2
    ha_nii = flux[haleft:niiright,center,center]
    local_mediad = np.median(ha_nii.value)
    if plot == True:
        plt.close()
        plt.plot(ha_nii.wavelength,ha_nii,"o-")
        plt.axvline(6563*(1+z), color="green", label=r'$H_\alpha \ line$')
        plt.axvline(6584*(1+z), color='red', label=r'$Nii \ line$')
        plt.plot(flux.wavelength[[left,right]].value,[local_mediad,local_mediad])
        plt.ylabel(ha_nii.unit)
        plt.xlabel(ha_nii.wavelength.unit)
        plt.legend()
        plt.title("Центральный пиксель")
        plt.show(block=False)
        plt.pause(PLT_TIME_PAUSE)
    return left,right,center_line
    #input()
    #настроим чтобы выбирать более четко в ручную


def cut_line_from_cube(cube, left, right, plot: bool = True, median_width=50):
    cut_line_fluxe = cube.flux[left:right]
    cut_line_fluxe_median = np.median(cube.flux[left-median_width:right+median_width],axis=0)
    if plot is True:
        plt.close()
        plt.imshow(cut_line_fluxe[(right-left)//2].value, origin='lower')
        plt.contour(cut_line_fluxe_median.value)
        plt.show(block=False)
        plt.pause(PLT_TIME_PAUSE)
    return cut_line_fluxe, cut_line_fluxe_median


def save_new_cube (cube, cut_line_fluxe, cut_line_fluxe_median, center_line, res_name=None, dir_name='cutfits/'):
    if res_name == None:
        # res_name = name_manga[6:-3]
        res_name = cube.plateifu+'.fits.gz'
    res_path = dir_name+res_name
    # header = cube.header.copy()
    header = cube.header
    plateifu = cube.plateifu
    z = get_z(plateifu)
    hdr =fits.Header()
    hdr['OBJECT'] = res_name 
    hdr['BEAMFWHM'] = header['RFWHM'] 
    hdr['BUNIT'] = '1E-17 erg/s/cm^2/Angstrom'

    hdr['CRPIX1']=cube.header['CRPIX1']
    hdr['CRVAL1'] =cube.header['CRVAL1']
    hdr['CDELT1']=cube.header['CD1_1']
    hdr['CTYPE1']=cube.header['CTYPE1']
    hdr['CUNIT1']=cube.header['CUNIT1']

    hdr['CRPIX2']=cube.header['CRPIX2']
    hdr['CRVAL2'] =cube.header['CRVAL2']
    hdr['CDELT2']=cube.header['CD2_2']
    hdr['CTYPE2']=cube.header['CTYPE2']
    hdr['CUNIT2']=cube.header['CUNIT2']
    hdr['CRVAL3'] = cut_line_fluxe.wavelength[0].value
    hdr['CDELT3']=1.0 #CD3_3
    hdr['CRPIX3']=1.0
    hdr['CTYPE3']= 'WAVE    ' 
    hdr['CUNIT3']='angstrom'
    # Выше необходимый набор данных. про обхект его координаты и тп 
    hdr['TELESCOP'] = cube.header['TELESCOP']
    hdr['REDSHIFT']=z

    # hdr['RESTWAVE'] = 6563.0
    # hdr['VELDEF']='RELATIVISTIC' #Do define wave\freq 
    # hdr['VELDEF']='OPTICAL' #Do define wave\freq r
    hdr['BMAJ'] = header['RFWHM']/3600 #кажется надо давать в градусах (типо в размерности оси 2:
    hdr['BMIN'] = header['RFWHM']/3600
    hdr['BPA']=0
    # hdr['RESTWAVE']=center_line
    #LINEAR
    hdu = fits.PrimaryHDU(data=(cut_line_fluxe - cut_line_fluxe_median).value,header=hdr)
    # hdu = fits.PrimaryHDU(data=(cut_line_fluxe).value,header=hdr)
    hdu.writeto(res_path,overwrite=True)
    return res_path

def run_bbarolo(file, param=[]):
    # param += ["plots=false","FLAGERRORS=false"]
    subprocess.run(["BBarolo", "-f", file, *param])

def downloads_gal_by_list(N=10):
    my_gal_df = pd.read_csv("my_gal_df.csv") #delimiter="\s+")b
    # df = pathgallist 
    all_gal_df = pd.read_csv("~/rotate/list_galaxy_from_Beom_v2.csv")
    for i,plateifu in enumerate(my_gal_df.PlateifuID):
        print(i, ': ', plateifu)
        downloads_cube(plateifu)
        if i>N:
            break

def reduse(plateifu,plot=True):
    my_gal_df = pd.read_csv("my_gal_df.csv") #delimiter="\s+")bs
    all_gal_df = pd.read_csv("~/rotate/list_galaxy_from_Beom_v2.csv")
    #задаем галактику 
    # plateifu = my_gal_df.PlateifuID[N] #8085-6101
    name_manga = f'manga-{plateifu}-LINCUBE.fits.gz'
    dirname = 'cubefile/'
    path = dirname+name_manga

    print("*"*10)
    print(f"\n galaxy:  {plateifu}")
    print("*"*10)
   
    #open cube
    my_cube = marvin.tools.Cube(filename=path)
    z = get_z(plateifu)

    #скачиваем файл
    cube = marvin.tools.Cube(path)

    #Проверка на ошибки данных
    if cube.quality_flag.bits:
        print('have some issue with data')
        print(cube.quality_flag.bits)
        print("************************* \n\n\n\n**********")

    center=cube.flux.shape[1]//2
    
    #проверим вид спектра
    plot_center_spectr(cube,center,plot=plot)
    left, right, center_line = choice_line_and_width(cube,z,center, plot=plot)
    cut_line_fluxe, cut_line_fluxe_median = cut_line_from_cube(cube, left-10, right+10,plot=plot)
    res_path = save_new_cube(cube, cut_line_fluxe, cut_line_fluxe_median,center_line)
    run_bbarolo(res_path, ["plots=true","FLAGERRORS=false",f"RESTWAVE={center_line}"])
    print(f"\n galaxy:  {plateifu}")

def restart_reduse (plateifu,bbarolo_param,plot=True, dir_name='cutfits/',res_name = None):
    if res_name == None:
        res_name = cube.plateifu+'.fits.gz'
    res_path = dir_name+res_name
    if bbarolo_param == None:
        bbarolo_param=["plots=true","FLAGERRORS=false",f"RESTWAVE={center_line}"]
    run_bbarolo(res_path, bbarolo_param)
    print(f"\n galaxy:  {plateifu}")
    
def start(N=10):
    my_gal_df = pd.read_csv("my_gal_df.csv") #delimiter="\s+")bs
    for plateifu in my_gal_df.PlateifuID[10:]:
        reduse(plateifu)

if __name__=="__main__":
    downloads_gal_by_list(N=100)
    plateifu ='7980-1902'

    N=3
    try:
        N=int(sys.argv[1])
    except:
        print(sys.argv[1])
        # break
        #остановим программу
        x=1/0
        N=4

    plot=True

    my_gal_df = pd.read_csv("my_gal_df.csv") #delimiter="\s+")bs
    # df = pathgallist 
    all_gal_df = pd.read_csv("~/rotate/list_galaxy_from_Beom_v2.csv")
    # df = pd.read_csv(pathgallist)
    
    #задаем галактику 
    plateifu = my_gal_df.PlateifuID[N] #8085-6101
    name_manga = f'manga-{plateifu}-LINCUBE.fits.gz'
    dirname = 'cubefile/'
    path = dirname+name_manga

    print("*"*10)
    print(f"\n galaxy:  {plateifu}")
    print("*"*10)
   
    #open cube
    my_cube = marvin.tools.Cube(filename=path)
    z = get_z(plateifu)

    #скачиваем файл
    path = downloads_cube(plateifu)
    cube = marvin.tools.Cube(path)

    #Проверка на ошибки данных
    if cube.quality_flag.bits:
        print('have some issue with data')
        print(cube.quality_flag.bits)
        print("************************* \n\n\n\n**********")

    center=cube.flux.shape[1]//2
    #проверим вид спектра
    plot_center_spectr(cube,center,plot=plot)
    left, right, center_line = choice_line_and_width(cube,z,center, plot=plot)
    cut_line_fluxe, cut_line_fluxe_median = cut_line_from_cube(cube, left-10, right+10,plot=plot)
    res_path = save_new_cube(cube, cut_line_fluxe, cut_line_fluxe_median,center_line)
    run_bbarolo(res_path, ["plots=true","FLAGERRORS=false",f"RESTWAVE={center_line}"])
    print(f"\n galaxy:  {plateifu}")

    #"XPOS=27.4"," YPOS"])
    # # plot_center_spectr(cube,center)
    # left, right, center_line = choice_line_and_width(cube,z,center)
    # cut_line_fluxe, cut_line_fluxe_median = cut_line_from_cube(cube, left-1000, right+1000)
    # res_path = save_new_cube(cube, cut_line_fluxe, cut_line_fluxe_median,center_line)
    # print("res_path: ", res_path)
    # run_bbarolo(res_path, ["plots=true","FLAGERRORS=false",f"RESTWAVE={center_line}"])





