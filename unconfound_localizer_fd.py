#!/usr/bin/env python3
import os
import sys
import numpy as np
import pandas as pd
import csv


sid = sys.argv[1]
task_list = ['localizer_run-1', 'localizer_run-2']
#task_list = ['emotion_run-1']

main_dir = '/scratch/csng/CSNG/data/output/fmriprep'


for rid in range(0,2):

    # read in confounds file
    confounds_fpt = main_dir + '/sub-' + sid + '/func/sub-' + sid + '_task-' + task_list[rid] + '_desc-confounds_timeseries.tsv'
    output_fpt = main_dir + '/sub-' + sid + '/func/sub-' + sid + '_task-' + task_list[rid] + '_desc-confounds_compcor24.tsv'

    confounds = pd.read_csv(confounds_fpt, sep='\t')
    out_vars = pd.DataFrame()
    fd = pd.DataFrame(confounds, columns = ['framewise_displacement'])
                    
    # nonsteady state
    for eqlb in range(4):
        eqlbvals = np.zeros(len(fd))
        eqlbvals[eqlb] = 1
        eq_col_name = 'non_steady_state0'+str(eqlb)
        eq_col_data = eqlbvals
        out_vars.loc[:,eq_col_name] = eq_col_data
            
        
    spikes = np.where(fd > 0.5)
    nspikes = len(spikes[0])
    if nspikes > 0:
        spiki = spikes[0]
        for sp in range(nspikes):
            spikereg = np.zeros(len(fd))
            spikereg[spiki[sp]]=1
            fd_col_name = 'fd'+str(sp)
            fd_col_data = spikereg
            out_vars.loc[:,fd_col_name] = fd_col_data


    r = out_vars
    confound_matrix =np.asmatrix(r)
        
    np.savetxt(output_fpt,confound_matrix, delimiter=',')


