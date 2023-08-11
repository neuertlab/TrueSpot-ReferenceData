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
    outdir = "D:\\usr\\bghos\\labdat\\imgproc\\img\\simvarmass"
    
    dim_xy = 512
    dim_z = 16
    
    voxel_xy = 65
    voxel_z = 200
    
    ptsig_xy = 95
    ptsig_z = 210
    
    bg_level = 500
    cluster_count = 5
    spots_per_clust = 3
    random_sig = 0.15
    
    bg_var_min = 0.05
    bg_var_max = 0.5
    
    amplvar_min = 0.05
    amplvar_max = 0.9
    
    amp_min = bg_level
    amp_max = bg_level * 10
    
    spots_min = 12
    spots_max = 5000
    
    genamt = 1000
    
    outfile = open(os.path.join(outdir, "siminfo.csv"), "w")
    outfile.write("#ID,SpotsSeed,Ampl,AmplVar,BGVar\n")
    for i in range(genamt):
        randomid = random.randrange(0, (2 << 31), 1)
        idstr = f'{randomid:08x}'
        spot_amt = random.randrange(spots_min, spots_max, 1)
        ampl = random.randrange(amp_min, amp_max, 1)
        amplvar = random.uniform(amplvar_min, amplvar_max)
        bgvar = random.uniform(bg_var_min, bg_var_max)
        res = simfish.simulate_image(3, spot_amt, random_n_spots=True, n_clusters=cluster_count, random_n_clusters=True, n_spots_cluster=spots_per_clust, random_n_spots_cluster=True, image_shape=(dim_z, dim_xy, dim_xy), subpixel_factors=None, voxel_size=(voxel_z, voxel_xy, voxel_xy), sigma=(ptsig_z, ptsig_xy, ptsig_xy), random_sigma=random_sig, amplitude=ampl, random_amplitude=amplvar, noise_level=bg_level, random_noise=bgvar)
        saveSimImage(res, outdir, idstr)
        outfile.write(idstr + "," + str(spot_amt) + "," + str(ampl) + "," + str(amplvar) + "," + str(bgvar) + "\n")
    outfile.close()
    print("hold")
    
main(None)