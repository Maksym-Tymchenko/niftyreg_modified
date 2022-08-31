#!/bin/sh

# Input arguments

case_num=${1-"02"}
image_folder=${2:-"bucket/BITE_group2_nii/${case_num}"}
us_image_uncompressed="US3DT.nii"
mri_image_uncompressed="MR.nii"
tag_file="bucket/BITE_group2_nii/BITE_group2_nii_tags/${case_num}/${case_num}_all.tag"

# Create directory to store the outputs
mkdir -p $image_folder/output/niftyreg

output_folder="$image_folder/output/niftyreg"

us_image="$image_folder/US3DT.nii"
mri_image="$image_folder/MR.nii"


# Resample images into a common reference frame and isotropic voxel size of 1x1x1 mm
vox_size=0.5

c3d $us_image $mri_image -reslice-identity -resample-mm ${vox_size}x${vox_size}x${vox_size}mm -o $output_folder/Case${case_num}-MRI_in_US.nii
c3d $us_image -resample-mm ${vox_size}x${vox_size}x${vox_size}mm -o $output_folder/Case${case_num}-US.nii


# Extract US background (pixels with 0 intensity exactly)
c3d $output_folder/Case${case_num}-US.nii -threshold 0 0 0 1 -o $output_folder/mask_US.nii

# Dilate the background by 10 voxels (2mm)
#c3d $output_folder/mask_US.nii -dilate 1 10x10x10vox -o $output_folder/mask_US.nii

# Remove background from MRI
#c3d $output_folder/Case${case_num}-MRI_in_US.nii $output_folder/mask_US.nii -multiply -o $output_folder/Case${case_num}-MRI_in_US_clean.nii

# Perform affine registration step
reg_aladin -ref $output_folder/Case${case_num}-US.nii \
-flo $output_folder/Case${case_num}-MRI_in_US.nii \
-res $output_folder/Case${case_num}-MRI_to_US_result.nii \
-rmask $output_folder/mask_US.nii \
-fmask $output_folder/mask_US.nii \
-aff $output_folder/affine_matrix.txt #-rigOnly #-noSym # -rigOnly

# Generate 2 text files containing landmarks
python3 ./landmarks_split_txt.py --inputtag $tag_file --savetxt $output_folder/Case${case_num}_lm

# Generate landmark segmentations as a NIFTI file
c3d $output_folder/Case${case_num}-MRI_in_US.nii -scale 0 -landmarks-to-spheres $output_folder/Case${case_num}_lm_mri.txt 1 -o $output_folder/Case${case_num}-MRI-landmarks.nii
c3d $output_folder/Case${case_num}-US.nii -scale 0 -landmarks-to-spheres $output_folder/Case${case_num}_lm_us.txt 1 -o $output_folder/Case${case_num}-US-landmarks.nii

# Apply the transformation to the landmarks
reg_resample -ref $output_folder/Case${case_num}-US.nii \
-flo $output_folder/Case${case_num}-MRI-landmarks.nii \
-res $output_folder/Case${case_num}-deformed_seg.nii \
-trans $output_folder/affine_matrix.txt \
-inter 0

# Calculate mTRE
python3 ./landmarks_centre_mass.py --inputnii $output_folder/Case${case_num}-US-landmarks.nii \
--movingnii $output_folder/Case${case_num}-deformed_seg.nii \
--savetxt $output_folder/Case${case_num}--results
