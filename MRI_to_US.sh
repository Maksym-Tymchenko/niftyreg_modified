#!/bin/sh

# Input arguments

case_num=${1-"2"}
image_folder=${2:-"bucket/RESECT/RESECT/NIFTI/Case${case_num}"}
us_image_compressed=${3:-"US/Case${case_num}-US-before.nii.gz"}
mri_image_compressed=${4:-"MRI/Case${case_num}-FLAIR.nii.gz"}
tag_file=${5:-"Landmarks/Case${case_num}-MRI-beforeUS.tag"}

# Unzip the nii files
gunzip -dkf $image_folder/$us_image_compressed
gunzip -dkf $image_folder/$mri_image_compressed

us_image="US/Case${case_num}-US-before.nii"
mri_image="MRI/Case${case_num}-FLAIR.nii"

# Create directory to store the outputs
mkdir -p $image_folder/output

# Resample images into a common reference frame and isotropic voxel size of 1x1x1 mm
c3d $image_folder/$us_image $image_folder/$mri_image -reslice-identity -resample-mm 1x1x1mm -o $image_folder/output/Case${case_num}-MRI_in_US.nii
c3d $image_folder/$us_image -resample-mm 1x1x1mm -o $image_folder/output/Case${case_num}-US.nii

# Perform affine registration step
reg_aladin -ref $image_folder/output/Case${case_num}-US.nii -flo $image_folder/output/Case${case_num}-MRI_in_US.nii -res $image_folder/output/Case${case_num}-MRI_to_US_niftyreg_result.nii \
-aff $image_folder/output/niftyreg_affine_matrix.txt -noSym

# Generate 2 text files containing landmarks
python3 ./landmarks_split_txt.py --inputtag $image_folder/$tag_file --savetxt $image_folder/output/Case${case_num}_lm

# Generate landmark segmentations as a NIFTI file
c3d $image_folder/output/Case${case_num}-MRI_in_US.nii -scale 0 -landmarks-to-spheres $image_folder/output/Case${case_num}_lm_mri.txt 1 -o $image_folder/output/Case${case_num}-MRI-landmarks.nii
c3d $image_folder/output/Case${case_num}-US.nii -scale 0 -landmarks-to-spheres $image_folder/output/Case${case_num}_lm_us.txt 1 -o $image_folder/output/Case${case_num}-US-landmarks.nii

# Apply the transformation to the landmarks
reg_resample -ref $image_folder/output/Case${case_num}-US.nii \
-flo $image_folder/output/Case${case_num}-MRI-landmarks.nii \
-res $image_folder/output/Case${case_num}-niftyreg_deformed_seg.nii \
-trans $image_folder/output/niftyreg_affine_matrix.txt \
-inter 0

# Calculate mTRE
python3 ./landmarks_centre_mass.py --inputnii $image_folder/output/Case${case_num}-US-landmarks.nii \
--movingnii $image_folder/output/Case${case_num}-niftyreg_deformed_seg.nii \
--savetxt $image_folder/output/Case${case_num}-niftyreg-results