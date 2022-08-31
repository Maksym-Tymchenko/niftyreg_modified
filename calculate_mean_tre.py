# filename = "error_list_MRI_to_US.txt"
# filename = "error_list_MRI_to_US_0p2_vox_size.txt"
#filename = "error_list_MRI_to_US_1mm.txt"
# filename = "error_list_MRI_to_US_05mm_fmask.txt"
# filename = "error_list_BITE_MRI_to_US_fmask_05mm.txt"
# filename = "error_list_MRI_to_US_05mm_T1.txt"

filename = "error_list_MRI_to_US_report.txt"
# filename = "error_list_MRI_to_US_rigid.txt"
filename = "error_list_MRI_to_US_rigid_post.txt"

vox_size = 0.5

with open(filename) as f:
    mean_err = 0
    num_el = 0
    for line in f:
        err = line.split()[-1].replace(")", "")
        if err!="nan":
            mean_err += float(err)
            num_el += 1

    mean_err = mean_err / num_el
    print(f"mTRE =  {mean_err:.3f}vox = {mean_err*vox_size:.3f}mm")