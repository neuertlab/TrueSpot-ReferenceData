import os
import simfish
import bigfish.stack

def saveSimImage(sim_results, outdir, nameroot):
     bigfish.stack.save_data_to_csv(sim_results[1], os.path.join(outdir, nameroot + "_key.csv"), delimiter=',')
     
     simimg = sim_results[0]
     Z = simimg.shape[0]
     
     for z in range(Z):
          outsuff = nameroot + f'_imgz_{z:04d}.csv'
          bigfish.stack.save_data_to_csv(simimg[z,:,:], os.path.join(outdir, outsuff), delimiter=',')

def main(args):
     #outdir = "D:\\usr\\bghos\\labdat\\imgproc\\img\\simvar"
     outdir = "C:\\Users\\hospelb\\labdata\\imgproc\\img\\simvar"
     
     xydim = 512;
     zdim = 16;
     
     #Varied expression level
     itr = 7
     spot_count = 16
     for i in range(itr):
          res = simfish.simulate_image(3, spot_count, random_n_spots=True, n_clusters=5, random_n_clusters=True, n_spots_cluster=3, random_n_spots_cluster=True, image_shape=(zdim, xydim, xydim), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.15, amplitude=2500, random_amplitude=0.4, noise_level=500, random_noise=0.075)
          saveSimImage(res, outdir, f'expr_var_{spot_count:d}')
          spot_count *= 4
     
     #Varied intensity variability
     amp_vary = 0.2;
     for i in range(itr):
          res = simfish.simulate_image(3, 256, random_n_spots=True, n_clusters=5, random_n_clusters=True, n_spots_cluster=3, random_n_spots_cluster=True, image_shape=(zdim, xydim, xydim), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.15, amplitude=2500, random_amplitude=amp_vary, noise_level=500, random_noise=0.075)
          saveSimImage(res, outdir, f'amplvar_var_{amp_vary:.1f}')
          amp_vary += 0.1
          
     #Varied background variation, constant intensity avg
     bkg_vary = 0.05;
     for i in range(itr):
          res = simfish.simulate_image(3, 256, random_n_spots=True, n_clusters=5, random_n_clusters=True, n_spots_cluster=3, random_n_spots_cluster=True, image_shape=(zdim, xydim, xydim), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.15, amplitude=2500, random_amplitude=0.4, noise_level=500, random_noise=bkg_vary)
          saveSimImage(res, outdir, f'bkgvar_var_{bkg_vary:.2f}')
          bkg_vary += 0.05     
     
     #Varied intensity avg, constant background level
     intensity_value = 100;
     for i in range(itr):
          res = simfish.simulate_image(3, 256, random_n_spots=True, n_clusters=5, random_n_clusters=True, n_spots_cluster=3, random_n_spots_cluster=True, image_shape=(zdim, xydim, xydim), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.15, amplitude=intensity_value, random_amplitude=0.4, noise_level=500, random_noise=0.075)
          saveSimImage(res, outdir, f'intensity_var_{intensity_value:d}')
          intensity_value += 100     
     
     
     #Varied cluster density
     cluster_count = 2;
     cluster_per = 3;
     for i in range(itr):
          res = simfish.simulate_image(3, 256, random_n_spots=True, n_clusters=cluster_count, random_n_clusters=True, n_spots_cluster=cluster_per, random_n_spots_cluster=True, image_shape=(zdim, xydim, xydim), subpixel_factors=None, voxel_size=(300, 65, 65), sigma=(340, 95, 95), random_sigma=0.15, amplitude=2500, random_amplitude=0.4, noise_level=500, random_noise=0.075)
          saveSimImage(res, outdir, f'cluster_var_{cluster_count:d}_{cluster_per:d}')
          cluster_count += 2
          cluster_per += 7

     print("Hold")
        
main(None)
    