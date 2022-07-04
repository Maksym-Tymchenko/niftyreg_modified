#!/bin/sh

# Input arguments

case_num=${1-"1"}
image_folder=${2:-"bucket/EASY-RESECT/NIFTI/Case${case_num}"}

us_image=${3:-"Case${case_num}-US-before-resize.nii"}
mri_image=${4:-"Case${case_num}-FLAIR-resize.nii"}

# Create directory to store the outputs
mkdir -p $image_folder/output


# Perform affine registration step
reg_aladin -ref  $image_folder/$us_image -flo $image_folder/$mri_image  -res $image_folder/output/Case${case_num}-MRI_to_US_niftyreg_result.nii \
-aff $image_folder/output/niftyreg_affine_matrix.txt -noSym

"""
# Perform non linear registration step
reg_f3d -ref $image_folder/output/Case${case_num}-US.nii -flo $image_folder/output/Case${case_num}-MRI_in_US.nii \
-res $image_folder/output/Case${case_num}_niftyreg_MRI_deformed.nii \
-aff $image_folder/output/niftyreg_affine_matrix.txt \
-cpp $image_folder/output/Case${case_num}_output_cpp.nii
"""

# Apply the transformation to the landmarks
reg_resample -ref $image_folder/$us_image \
-flo $image_folder//../landmarks/Case${case_num}-MRI-landmarks.nii \
-res $image_folder/output/Case${case_num}-niftyreg_deformed_seg.nii \
-trans $image_folder/output/niftyreg_affine_matrix.txt \
-inter 0


# Calculate mTRE
python3 ./landmarks_centre_mass.py --inputnii $image_folder/../landmarks/Case${case_num}-US-landmarks.nii.gz \
--movingnii $image_folder/output/Case${case_num}-niftyreg_deformed_seg.nii \
--savetxt $image_folder/output/Case${case_num}-niftyreg-results
