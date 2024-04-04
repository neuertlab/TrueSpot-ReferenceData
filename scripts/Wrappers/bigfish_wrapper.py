#!/usr/bin/env python3
import argparse
import os
import gc
import datetime
import math
#from pathlib import Path
import bigfish.stack
import bigfish.plot
import bigfish.detection
import bigfish.segmentation

class BigfishRun:
    def __init__(self):
        self.outpath = None
        self.inpath = None
        self.ch_dapi = 0
        self.ch_light = 0
        self.ch_targ = 0
        self.skip_rescale = False
        self.dump_coords = True
        self.cellseg_thresh = 100
        self.sobj_size_nuc = 50
        self.trgsize_nuc = 256
        self.watershed_alpha = 0.9
        self.voxel_sz = (300, 65, 65)
        self.point_sz = (200, 180, 180)
        self.min_thresh = 10
        self.max_thresh = 400
        self.zkeep = 0.8
        self.dofit = False
        self.is2D = False
        
def parseDimArg(argstring):
    argstring = argstring.replace(" ","")
    argstring = argstring.replace("(","")
    argstring = argstring.replace(")","")
    splitstr = argstring.split(",")
    dimi = []
    for i in range(len(splitstr)):
        dimi.append(int(splitstr[i]))
    return tuple(dimi)

def drawbigfishplot(imgs_3d, titles):
    print("Rendering to plot...")
    imgs_2d = []
    for img in imgs_3d:
        imgs_2d.append(bigfish.stack.maximum_projection(img))
        
    bigfish.plot.plot_images(imgs_2d, contrast=True, titles=titles)
    
def getdtstr():
    now = datetime.datetime.now()
    return "[" + str(now) + "]"

def getStackChannel(stack, chdim, chidx):
    #This function hurts my soul
    if chdim == 0:
        return stack[chidx,:,:,:]
    elif chdim == 1:
        return stack[:,chidx,:,:]
    elif chdim == 2:
        return stack[:,:,chidx,:]
    elif chdim == 3:
        return stack[:,:,:,chidx]
    else:
        return None

def doBigfishRun(runparams):
    print("BigFISH Wrapper Initialized! Version 24.04.04.00")
    
    print("Input File:", runparams.inpath)
    print("Output Directory:", runparams.outpath)
    if runparams.ch_dapi > 0:
        print("DAPI Channel:", runparams.ch_dapi)
    if runparams.ch_light > 0:
        print("TRANS Channel:", runparams.ch_light)
    if runparams.ch_targ > 0:
        print("Target Channel:", runparams.ch_targ)
        
    print("Minimum Scan Threshold:", runparams.min_thresh)
    print("Maximum Scan Threshold:", runparams.max_thresh)
    
    if runparams.is2D:
        print("Pixel Size:", runparams.voxel_sz[1], "x", runparams.voxel_sz[0], "nanometers")
        print("Point Size:", runparams.point_sz[1], "x", runparams.point_sz[0], "nanometers")        
    else:
        print("Voxel Size:", runparams.voxel_sz[2], "x" , runparams.voxel_sz[1], "x", runparams.voxel_sz[0], "nanometers")
        print("Point Size:", runparams.point_sz[2], "x" , runparams.point_sz[1], "x", runparams.point_sz[0], "nanometers")        
        
    print("CellSeg T:", runparams.cellseg_thresh)
    print("Small Object Size (NucSeg):", runparams.sobj_size_nuc)
    print("Target Size (NucSeg):", runparams.trgsize_nuc)
    print("Watershed Alpha (CellSeg):", runparams.watershed_alpha)
    print("Rescale:", (not runparams.skip_rescale))
    print("Subpixel Fit:", runparams.dofit)
        
    #Read image and split channels
    print(getdtstr(), "Reading image file...")
    imgstack = bigfish.stack.read_image(runparams.inpath, True)
    
    #Figure out which dim represents channels because apparently I have to do that...
    ch_dim = 0
    ch_min = 0x7fffffff
    if len(imgstack.shape) > 3:
        for i in range(4):
            if (imgstack.shape[i] < ch_min):
                ch_dim = i;
                ch_min = imgstack.shape[i]
    
        #Split channels
        ch_nuc = None
        ch_trans = None
        ch_sample = None
        print(getdtstr(), "Splitting channels...")
        if runparams.ch_dapi > 0:
            ch_nuc = getStackChannel(imgstack, ch_dim, runparams.ch_dapi-1)
        if runparams.ch_light > 0:
            ch_trans = getStackChannel(imgstack, ch_dim, runparams.ch_light-1)
        if runparams.ch_targ > 0:
            ch_sample = getStackChannel(imgstack, ch_dim, runparams.ch_targ-1)
    else:
        ch_sample = imgstack
        ch_nuc = None
        ch_trans = None

    if ch_sample is None:
        print("No sample provided! Exiting...")
        quit()
    
    images = [ch_nuc, ch_trans, ch_sample]
    titles = ["DAPI", "Light", "Sample"]
    #drawbigfishplot(images, titles)
    
        
    #Preprocessing - apply filters
    #I'm trying to use similar filters to what we use in our pipeline.
    if not runparams.skip_rescale:
        print(getdtstr(), "Rescaling...")
        ch_sample = bigfish.stack.rescale(ch_sample, channel_to_stretch=None) #Rescale
    
    #Trim. I'll try using the out-of-focus calc to determine a z-trim
    if runparams.zkeep < 0.1:
        runparams.zkeep = 0.1
    elif runparams.zkeep > 1.0:
        runparams.zkeep = 1.0
    
    if (runparams.zkeep < 1.0) and not runparams.is2D:
        print(getdtstr(), "Calculating focus scores...")
        focus_scored = bigfish.stack.compute_focus(ch_sample)
        print(getdtstr(), "Picking most in-focus z slices...")
        in_focus_z = bigfish.stack.get_in_focus_indices(focus_scored, runparams.zkeep)
        zmin = in_focus_z[0]
        zmax = in_focus_z[-1]
        ch_sample = ch_sample[zmin:zmax+1,:,:]
    else:
        zmin = 0
        if runparams.is2D:
            zmax = 1
        else:
            zmax = ch_sample.shape[0]
            
    #Image dims
    if runparams.is2D:
        zdim = 1
        ydim = ch_sample.shape[0]
        xdim = ch_sample.shape[1]
    else:
        zdim = ch_sample.shape[0]
        ydim = ch_sample.shape[1]
        xdim = ch_sample.shape[2]            
    
    #Cellseg
    if (ch_nuc is not None) and (ch_trans is not None):
        ch_nuc = ch_nuc[zmin:zmax+1,:,:]
        nuc_2d = bigfish.stack.maximum_projection(ch_nuc)
        print(getdtstr(), "Segmenting nuclei (threshold approach)...")
        nuc_mask = bigfish.segmentation.thresholding(nuc_2d, threshold=runparams.cellseg_thresh)
        nuc_mask = bigfish.segmentation.clean_segmentation(nuc_mask, small_object_size=runparams.sobj_size_nuc, fill_holes=True)
        nuc_label_t = bigfish.segmentation.label_instances(nuc_mask)
        bigfish.stack.save_data_to_csv(nuc_label_t, os.path.join(runparams.outpath, "nuc_t.csv"), delimiter=',')
        del(nuc_mask)
        
        #print(getdtstr(), "Segmenting nuclei (neural network approach)...")
        #nmodel = bigfish.segmentation.unet_3_classes_nuc()
        #nuc_label_n = bigfish.segmentation.apply_unet_3_classes(nmodel, nuc_2d, target_size=runparams.trgsize_nuc, test_time_augmentation=True)
        #bigfish.stack.save_data_to_csv(nuc_label_n, os.path.join(runparams.outpath, "nuc_n.csv"), delimiter=',')
    
        print(getdtstr(), "Segmenting cells (from nuclei mask t)...")
        ch_trans = ch_trans[zmin:zmax+1,:,:]
        light_2d = bigfish.stack.maximum_projection(ch_trans)    
        cell_label_t = bigfish.segmentation.cell_watershed(light_2d, nuc_label_t, threshold=runparams.cellseg_thresh, alpha=runparams.watershed_alpha)
        bigfish.stack.save_data_to_csv(cell_label_t, os.path.join(runparams.outpath, "cell_t.csv"), delimiter=',')
        del(nuc_label_t)
        del(cell_label_t)    
    
        #print(getdtstr(), "Segmenting cells (from nuclei mask n)...")
        #cell_label_n = bigfish.segmentation.cell_watershed(light_2d, nuc_label_n, threshold=runparams.cellseg_thresh, alpha=runparams.watershed_alpha)
        #bigfish.stack.save_data_to_csv(cell_label_n, os.path.join(runparams.outpath, "cell_n.csv"), delimiter=',')
    
        print(getdtstr(), "Garbage collection...")
        del(ch_nuc)
        del(nuc_2d)
        del(ch_trans)
        del(light_2d)
        #del(nuc_label_n)
        #del(cell_label_n)
        gc.collect()
        print(getdtstr(), "Cellseg done!")
    
    #Attempt spot detection...
    #TODO: Make voxel and radius inputs args.
    #print("Running spot detection...")
    #spots, threshold = bigfish.detection.detect_spots(images=ch_sample, return_threshold=True, voxel_size=voxel_sz, spot_radius=point_sz)
    
    #Doing steps separately to extract m-o-r-e-d-a-t-a
    print(getdtstr(), "Determining spot radius...")
    if runparams.is2D:
        log_factor = bigfish.detection.get_object_radius_pixel(voxel_size_nm=runparams.voxel_sz, object_radius_nm=runparams.point_sz, ndim=2) 
    else:
        log_factor = bigfish.detection.get_object_radius_pixel(voxel_size_nm=runparams.voxel_sz, object_radius_nm=runparams.point_sz, ndim=3) 
    print(getdtstr(), "Applying LoG filter...")
    img_filtered = bigfish.stack.log_filter(ch_sample, sigma=log_factor)
    print(getdtstr(), "Detecting local maxima...")
    mask = bigfish.detection.local_maximum_detection(img_filtered, min_distance=log_factor)
    print(getdtstr(), "Running auto threshold...")
    threshold = bigfish.detection.automated_threshold_setting(img_filtered, mask)
    print(getdtstr(), "Auto-threshold selection:", threshold)
    if threshold >= 1 and threshold < runparams.min_thresh:
        runparams.min_thresh = math.floor(threshold)
        print(getdtstr(), "Threshold dump minimum adjusted to:", runparams.min_thresh)
    if threshold > runparams.max_thresh:
        runparams.max_thresh = math.ceil(threshold)   
        print(getdtstr(), "Threshold dump maximum adjusted to:", runparams.max_thresh)
    print(getdtstr(), "Scanning thresholds for spots...")
    for i in range(runparams.max_thresh):
        t = i+1
        if t < runparams.min_thresh:
            continue
        print(getdtstr(), "-> Threshold =", t)
        outsuff = f'spots_{t:04d}.csv'
        spots, _ = bigfish.detection.spots_thresholding(img_filtered, mask, t)
        bigfish.stack.save_data_to_csv(spots, os.path.join(runparams.outpath, outsuff), delimiter=',')
        
    #Subpixel fit (if applicable)
    if runparams.dofit:
        #I am assuming is uses the original image, not filtered for subfit?
        spots_t, _ = bigfish.detection.spots_thresholding(img_filtered, mask, threshold)
        subfit = bigfish.detection.fit_subpixel(ch_sample, spots_t, runparams.voxel_sz, runparams.point_sz)
        bigfish.stack.save_data_to_csv(subfit, os.path.join(runparams.outpath, "fitspots.csv"), delimiter=',')
    
    #Save output
    print(getdtstr(), "Outputting summary...")
    with open(os.path.join(runparams.outpath, "summary.txt"), "w") as outfile:
        outfile.write("Z Range: " + str(zmin) + " - " + str(zmax) + "\n")
        outfile.write("Threshold: " + str(threshold) + "\n")
        outfile.write("LoG Factor: " + str(log_factor) + "\n")
        outfile.write("Image Dimensions: " + str(xdim) + "," + str(ydim) + "," + str(zdim) + "\n")
      
    del(ch_sample)  
    del(img_filtered)
    gc.collect()    
        
    print(getdtstr(), "Done!")    

def main(args):
    runparams = BigfishRun()
    runparams.outpath = args.outpath
    runparams.inpath = args.inpath
    
    if args.ch_dapi:
        runparams.ch_dapi = args.ch_dapi
    if args.ch_light:
        runparams.ch_light = args.ch_light
    if args.ch_target:
        runparams.ch_targ = args.ch_target
    if args.minth:
        runparams.min_thresh = args.minth
    if args.maxth:
        runparams.max_thresh = args.maxth        
    if args.csthresh:
        runparams.cellseg_thresh = args.csthresh
    if args.wsalpha:
        runparams.watershed_alpha = args.wsalpha
    if args.sobjsznuc:
        runparams.sobj_size_nuc = args.sobjsznuc
    if args.trgsznuc:
        runparams.trgsize_nuc = args.trgsznuc      
    if args.norescale:
        runparams.skip_rescale = True
    if args.zkeep:
        runparams.zkeep = args.zkeep
    if args.gaussfit:
        runparams.dofit = True        
    if args.voxelsz:
        runparams.voxel_sz = parseDimArg(args.voxelsz)
    if args.pixelsz:
        runparams.voxel_sz = parseDimArg(args.pixelsz)
        self.is2D = True
    if args.pointsz:
        runparams.point_sz = parseDimArg(args.pointsz)
        
    doBigfishRun(runparams)
        
    
if __name__ == "__main__":
    # Args
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("inpath", help="Input tif image path.")
    parser.add_argument("outpath", help="Output directory path.")
    parser.add_argument("--ch_dapi", type=int, help="Index of DAPI channel.")
    parser.add_argument("--ch_light", type=int, help="Index of light/TRANS channel.")
    parser.add_argument("--ch_target", type=int, help="Index of target sample channel.")
    parser.add_argument("--minth", type=int, help="Minimum threshold to run explicit scan of (does not affect automated scan). (default: 10)")
    parser.add_argument("--maxth", type=int, help="Maximum threshold to run explicit scan of (does not affect automated scan). (default: 400)")
    parser.add_argument("--voxelsz", help="Voxel size in nm formatted 'z,y,x' (default: 300,65,65)")
    parser.add_argument("--pixelsz", help="Pixel size (for 2D image) in nm formatted 'y,x' (default: 65,65)")
    parser.add_argument("--pointsz", help="Expected point size in nm formatted 'z,y,x' or 'y,x' (default: 350,150,150)")
    parser.add_argument("--csthresh", type=int, help="Value to use for cellseg thresh (default: 500)")
    parser.add_argument("--wsalpha", type=int, help="Watershed alpha to use for cellseg (default: 0.9)")
    parser.add_argument("--sobjsznuc", type=int, help="Nucleus small object size to use for nucleus segmentation (default: 2000)")
    parser.add_argument("--trgsznuc", type=int, help="Nucleus target size to use for nucleus segmentation (default: 256)")
    parser.add_argument("--zkeep", type=float, help="Proportion of z-slices to keep untrimmed (default: 0.8)")
    parser.add_argument("--norescale", action="store_true", help="Skip BIGFISH image intensity rescaling step.")
    parser.add_argument("--gaussfit", action="store_true", help="Perform subpixel fitting at BF selected threshold as well.")
    parser.add_argument("--help", "-h", "-?", action="help", help="Show this help message and exit.")
    args = parser.parse_args()
    main(args)