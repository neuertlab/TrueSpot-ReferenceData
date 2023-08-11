import os
import random
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
    #outdir = "D:\\usr\\bghos\\labdat\\imgproc\\img\\simytc"
    outdir = "C:\\Users\\hospelb\\labdata\\imgproc\\img\\simytc"
    
    dim_xy = 512
    dim_z = 16
    
    voxel_xy = 65
    voxel_z = 200
    
    ptsig_xy = 95
    ptsig_z = 210
    
    cluster_count = 3
    spots_per_clust = 6
    random_sig = 0.15
    
    bg_level_min = 150
    bg_level_max = 210
    
    bg_var_min = 0.05
    bg_var_max = 0.2
    
    amplvar_min = 0.5
    amplvar_max = 0.75
    
    amp_min = 1500
    amp_max = 1750
    
    spots_min = 2
    spots_max = 2500
    
    genamt = 250
    
    #Note THESE CY5/TMR refer to the labels AFTER switching channels. So TMR is channel 2 and CY5 is like channel 1
    outfile = open(os.path.join(outdir, "siminfo.csv"), "w")
    outfile.write("#ID,SpotsSeed,Ampl,AmplVar,BG,BGVar\n")
    for i in range(genamt):
        #CY5 like
        randomid = random.randrange(0, (2 << 31), 1)
        idstr = f'CY5L_{randomid:08x}'
        spot_amt = random.randrange(spots_min, spots_max, 1)
        ampl = random.randrange(amp_min, amp_max, 1)
        amplvar = random.uniform(amplvar_min, amplvar_max)
        bgvar = random.uniform(bg_var_min, bg_var_max)
        bg_level = random.uniform(bg_level_min, bg_level_max)
        res = simfish.simulate_image(3, spot_amt, random_n_spots=True, n_clusters=cluster_count, random_n_clusters=True, n_spots_cluster=spots_per_clust, random_n_spots_cluster=True, image_shape=(dim_z, dim_xy, dim_xy), subpixel_factors=None, voxel_size=(voxel_z, voxel_xy, voxel_xy), sigma=(ptsig_z, ptsig_xy, ptsig_xy), random_sigma=random_sig, amplitude=ampl, random_amplitude=amplvar, noise_level=bg_level, random_noise=bgvar)
        saveSimImage(res, outdir, idstr)
        outfile.write(idstr + "," + str(spot_amt) + "," + str(ampl) + "," + str(amplvar) + "," + str(bg_level) + "," + str(bgvar) + "\n")
        
    bg_level_min = 1300
    bg_level_max = 1700
    amp_min = 2900
    amp_max = 3500    
        
    for i in range(genamt):
        #Other channel, TMR like
        randomid = random.randrange(0, (2 << 31), 1)
        idstr = f'TMRL_{randomid:08x}'
        spot_amt = random.randrange(spots_min, spots_max, 1)
        ampl = random.randrange(amp_min, amp_max, 1)
        amplvar = random.uniform(amplvar_min, amplvar_max)
        bgvar = random.uniform(bg_var_min, bg_var_max)
        bg_level = random.uniform(bg_level_min, bg_level_max)
        res = simfish.simulate_image(3, spot_amt, random_n_spots=True, n_clusters=cluster_count, random_n_clusters=True, n_spots_cluster=spots_per_clust, random_n_spots_cluster=True, image_shape=(dim_z, dim_xy, dim_xy), subpixel_factors=None, voxel_size=(voxel_z, voxel_xy, voxel_xy), sigma=(ptsig_z, ptsig_xy, ptsig_xy), random_sigma=random_sig, amplitude=ampl, random_amplitude=amplvar, noise_level=bg_level, random_noise=bgvar)
        saveSimImage(res, outdir, idstr)
        outfile.write(idstr + "," + str(spot_amt) + "," + str(ampl) + "," + str(amplvar) + "," + str(bg_level) + "," + str(bgvar) + "\n")
        
    outfile.close()
    print("hold")
    
main(None)