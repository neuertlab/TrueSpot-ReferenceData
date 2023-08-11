import os
import simfish
import bigfish.stack

#mESC RNA like (100X)
#yeast RNA like (100X)
#mESC histone like (100X)
#yeast Msb2 like (100X)
#mESC RNA like (20X)
#yeast RNA like (20X)

def saveSimImage(sim_results, outdir, nameroot):
     bigfish.stack.save_data_to_csv(sim_results[1], os.path.join(outdir, nameroot + "_key.csv"), delimiter=',')
     
     simimg = sim_results[0]
     Z = simimg.shape[0]
     
     for z in range(Z):
          outsuff = nameroot + f'_imgz_{z:04d}.csv'
          bigfish.stack.save_data_to_csv(simimg[z,:,:], os.path.join(outdir, outsuff), delimiter=',')
          
def generateIntensityBkgSeries(outdir):
     print("")

def main(args):
     img_per = 3
     #outdir = "D:\\usr\\bghos\\labdat\\imgproc\\img\\sim"
     outdir = "C:\\Users\\hospelb\\labdata\\imgproc\\img\\sim"
    
     #Test
     #res = simfish.simulate_image(3, 300, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=12, random_n_spots_cluster=True, image_shape=(69, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.35, amplitude=3000, random_amplitude=0.5, noise_level=250, random_noise=0.05)
     #saveSimImage(res, outdir, "simtest")
     
     #mESC RNA like (100X)
     #res = simfish.simulate_image(3, 300, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=12, random_n_spots_cluster=True, image_shape=(69, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.35, amplitude=3000, random_amplitude=0.5, noise_level=250, random_noise=0.05)
     #saveSimImage(res, outdir, "mESC_RNA_100x_3")   
     
     #mESC RNA like (TMR)
     #res = simfish.simulate_image(3, 500, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=20, random_n_spots_cluster=True, image_shape=(69, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.35, amplitude=10000, random_amplitude=0.5, noise_level=1100, random_noise=0.05)
     #saveSimImage(res, outdir, "mESC_RNA_TMRLike_100x_3")
     
     #yeast RNA like (100X) - TMR
     #res = simfish.simulate_image(3, 4000, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=15, random_n_spots_cluster=True, image_shape=(25, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(310, 90, 90), random_sigma=0.30, amplitude=1500, random_amplitude=0.5, noise_level=180, random_noise=0.05)
     #saveSimImage(res, outdir, "yeast_RNA_TMRlike_100x_2")     
     #yeast RNA like (100X) - CY5
     #res = simfish.simulate_image(3, 4000, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=15, random_n_spots_cluster=True, image_shape=(25, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(310, 90, 90), random_sigma=0.30, amplitude=3000, random_amplitude=0.5, noise_level=1300, random_noise=0.05)
     #saveSimImage(res, outdir, "yeast_RNA_CY5like_100x_2")
     
     #mESC histone AF488 like (100X)
     #res = simfish.simulate_image(3, 10000, random_n_spots=True, n_clusters=20, random_n_clusters=True, n_spots_cluster=15, random_n_spots_cluster=True, image_shape=(81, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(310, 85, 85), random_sigma=0.30, amplitude=2500, random_amplitude=0.55, noise_level=1000, random_noise=0.1)
     #saveSimImage(res, outdir, "mESC_histone_100x_3")
     
     #yeast protein-like (100X)
     #Not exactly sure how to go about this atm, since it needs to be pretty blurry?
     #res = simfish.simulate_image(3, 2000, random_n_spots=True, n_clusters=500, random_n_clusters=True, n_spots_cluster=150, random_n_spots_cluster=True, image_shape=(13, 1024, 1024), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(100, 30, 30), random_sigma=0.40, amplitude=3200, random_amplitude=0.8, noise_level=2250, random_noise=0.05)
     #res = simfish.simulate_image(3, 5000, random_n_spots=True, n_clusters=500, random_n_clusters=True, n_spots_cluster=200, random_n_spots_cluster=True, image_shape=(13, 1024, 1024), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(100, 30, 30), random_sigma=0.40, amplitude=5000, random_amplitude=0.8, noise_level=1000, random_noise=0.05)
     #For this second one, I artificially separated noise and signal to see if that would produce a result more akin to the target images after applying a gaussian blur?
     #saveSimImage(res, outdir, "yeast_proteinGFP_100x_2")
     
     #mESC RNA like (20X)
     #res = simfish.simulate_image(3, 1500, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=12, random_n_spots_cluster=True, image_shape=(69, 2048, 2048), subpixel_factors=None, voxel_size=(1500, 325, 325), sigma=(340, 95, 95), random_sigma=0.35, amplitude=3000, random_amplitude=0.5, noise_level=250, random_noise=0.05)
     #saveSimImage(res, outdir, "mESC_RNA_20x_3")      
     
     #yeast RNA like (20X) - TMR
     #res = simfish.simulate_image(3, 20000, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=15, random_n_spots_cluster=True, image_shape=(25, 2048, 2048), subpixel_factors=None, voxel_size=(1500, 325, 325), sigma=(310, 90, 90), random_sigma=0.30, amplitude=1500, random_amplitude=0.5, noise_level=180, random_noise=0.05)
     #saveSimImage(res, outdir, "yeast_RNA_TMRlike_20x_2")     
     #yeast RNA like (20X) - CY5
     #res = simfish.simulate_image(3, 20000, random_n_spots=True, n_clusters=10, random_n_clusters=True, n_spots_cluster=15, random_n_spots_cluster=True, image_shape=(25, 2048, 2048), subpixel_factors=None, voxel_size=(1500, 325, 325), sigma=(310, 90, 90), random_sigma=0.30, amplitude=3000, random_amplitude=0.5, noise_level=1300, random_noise=0.05)
     #saveSimImage(res, outdir, "yeast_RNA_CY5like_20x_2")     
     
     #mESC very low expression (100X) AF594 like
     res = simfish.simulate_image(3, 50, random_n_spots=True, n_clusters=5, random_n_clusters=True, n_spots_cluster=3, random_n_spots_cluster=True, image_shape=(69, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.35, amplitude=3000, random_amplitude=0.5, noise_level=250, random_noise=0.05)
     saveSimImage(res, outdir, "mESC_RNA_LE_100x_3")       
     
     #yeast very low expression (100X) CY5 like
     #res = simfish.simulate_image(3, 100, random_n_spots=True, n_clusters=5, random_n_clusters=True, n_spots_cluster=5, random_n_spots_cluster=True, image_shape=(25, 2048, 2048), subpixel_factors=None, voxel_size=(200, 65, 65), sigma=(210, 90, 90), random_sigma=0.30, amplitude=3000, random_amplitude=0.5, noise_level=1300, random_noise=0.05)
     #saveSimImage(res, outdir, "yeast_RNA_LE_CY5like_100x_2")     
     
     #mESC very low expression high background (100X) AF594 like
     #res = simfish.simulate_image(3, 50, random_n_spots=True, n_clusters=5, random_n_clusters=True, n_spots_cluster=3, random_n_spots_cluster=True, image_shape=(69, 2048, 2048), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.35, amplitude=3000, random_amplitude=0.5, noise_level=1000, random_noise=0.15)
     #saveSimImage(res, outdir, "mESC_RNA_LEHB_100x_3")

     print("Hold")
        
main(None)
    