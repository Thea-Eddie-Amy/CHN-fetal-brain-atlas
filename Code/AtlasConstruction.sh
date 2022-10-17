#!/bin/sh

# This is the code demo script for FETAL ATLAS construction
# Author: Xinyi XU   2021.5
# Note: 1) datadir should be the folder cotaining the subjects MRI images
#		2) If Nifti images were .nii.gz format, change the filelist=$(ls ${datadir}*.nii.gz)
#		3) N: subjects numbers
#		4) iterations: define the number of iterative group-wise registrations
#		5) w: Adapative kernel weights which was calculated before in matlab.
#		6) gradientstep: the parameter for shape update which was recommended by ANTs developers.

########### Initial Parameters #############
datadir= #path to the subjects images
filelist=$(ls ${datadir}*.nii)
N=$(ls $datadir | grep ".nii" |wc -l)
iterations=10
gradientstep=-0.15
W=(1.01273519514003	1.01273519514003	1.01273519514003	1.02312213219363	1.02312213219363	0.982202814005487	0.933347336187153) # weight of each subject * NumberOfSubjects
########## Check File Format ##########
for file in ${filelist}
do
{
   if [[ $file == *.gz* ]];then
      gzip -d $file
   fi
}
done

filelist=$(ls ${datadir}*.nii)
# rename files
a=1
for file in ${filelist}
do
{
    new=${file%.nii*}${a}.nii
    mv $file $new
    let a=a+1
}
done
filelist=$(ls ${datadir}*.nii)

########### Creating Initial Template ##############

echo 
echo "----------------------------------------------------------------------"
echo "Creating Initial Template"
echo "Pair-Wise Registration & Weighted Average"
echo "----------------------------------------------------------------------"
echo

echo "Normalize Images to [0,1]"
for template in ${filelist}
do
{

    ImageMath 3 $template Normalize $template

}&
done
wait

for template in ${filelist}
do
{


    echo "Take $template as Fixed Image"
    regisDIR=${datadir}${template:0-5:1}/
    mkdir -p $regisDIR
 
     for file in ${filelist}
     do
     {

         # echo "antsRegistrationSyN.sh -d 3 -f $template -m $file -o ${regisDIR}${file:0-5:1}to${template:0-5:1}_"
         # echo "----------------------------------------------------------------------------------------------------------"
         antsRegistrationSyN.sh -d 3 -f $template -m $file -o ${regisDIR}${file:0-5:1}to${template:0-5:1}_ -j 1 >/dev/null
 
     }&
     done
     wait
    
  
    echo 
    echo "Voxel-wise weighted averaging of warped images to $template"
    echo "-----------------------------------------------------------------"

    for n in $(seq $N)
    do
    {
        #echo "MultiplyImages 3 ${regisDIR}${n}to${template:0-5:1}_Warped.nii.gz ${W[`expr $n - 1`]} ${regisDIR}${n}.nii.gz"
        MultiplyImages 3 ${regisDIR}${n}to${template:0-5:1}_Warped.nii.gz ${W[`expr $n - 1`]} ${regisDIR}${n}.nii.gz

    }&
    done
    wait
    
    #echo "AverageImages 3 ${regisDIR}Average_${template:0-5:1}.nii.gz 0 `ls ${regisDIR}?.nii.gz`"
    AverageImages 3 ${regisDIR}Average_${template:0-5:1}.nii.gz 0 `ls ${regisDIR}?.nii.gz` >/dev/null

        
    MultiplyImages 3 ${regisDIR}Average_${template:0-5:1}.nii.gz ${W[`expr ${template:0-5:1} - 1`]} ${regisDIR}Aver${template:0-5:1}.nii.gz
    mv ${regisDIR}Aver${template:0-5:1}.nii.gz ${datadir}    

}&
done
wait
AverageImages 3 ${datadir}InitialTemplate0.nii.gz 0 `ls ${datadir}Aver*.nii.gz` >/dev/null
rm -r ${datadir}?/

echo "Starting Rigid Alignment"
echo "----------------------------------"
for n in $(seq $N)
do
{
    antsRegistrationSyN.sh -d 3 -f ${datadir}InitialTemplate0.nii.gz -m ${datadir}Aver${n}.nii.gz -o ${datadir}Aver${n} -t a -j 1 >/dev/null
}&
done
wait

AverageImages 3 ${datadir}InitialTemplate0.nii.gz 0 `ls ${datadir}Aver?Warped.nii.gz` >/dev/null
rm ${datadir}Aver*

echo
echo "Sharpen Initial Template"
echo "---------------------------------"
ImageMath 3 ${datadir}InitialTemplate0.nii.gz Sharpen ${datadir}InitialTemplate0.nii.gz



##################################### Iteratively Group-wise Registration #############################################
for ii in $(seq $iterations) #iterations
do
{
    echo
    echo "Starting SyN Registration of $ii Iteration"
    echo "---------------------------------------------------------"

    iterdir=${datadir}iter_`expr $ii`/
    mkdir -p $iterdir
    for file in ${filelist}
    do
    {
        antsRegistrationSyN.sh -d 3 -f ${datadir}InitialTemplate0.nii.gz -m $file -o ${iterdir}${file:0-5:1} >/dev/null

    }&
    done
    wait

    echo
    echo "Voxel-wise weighted average of Warped Images "
    echo "----------------------------------------------------------"
    for n in $(seq $N)
    do
    {
       
       MultiplyImages 3 ${iterdir}${n}Warped.nii.gz ${W[`expr $n - 1`]} ${iterdir}${n}.nii.gz
       # MultiplyImages 3 ${iterdir}${n}1Warp.nii.gz ${W[`expr $n - 1`]} ${iterdir}${n}weightWarp.nii.gz

    }&
    done
    wait
    AverageImages 3 ${iterdir}Template0.nii.gz 0 `ls ${iterdir}?.nii.gz` >/dev/null

    echo
    echo "Starting Shape update"
    echo "----------------------------------------------------------"

    # WARPLIST=( `ls ${iterdir}*weightWarp.nii.gz 2> /dev/null` )

    AverageImages 3 ${iterdir}Averagewarp.nii.gz 0 `ls ${iterdir}*1Warp.nii.gz` >/dev/null  # Averaging the Warp.nii.gz (from subject to template) 
    MultiplyImages 3 ${iterdir}Averagewarp.nii.gz ${gradientstep} ${iterdir}Averagewarp.nii.gz  # Scale Averaged Warp.nii.gz
    AverageAffineTransform 3 ${iterdir}Average0GenericAffine.mat ${iterdir}?0GenericAffine.mat >/dev/null   # Average all GenericAffine matrix
    antsApplyTransforms -d 3 -e vector -i ${iterdir}Averagewarp.nii.gz -o ${iterdir}Averagewarp.nii.gz -t [ ${iterdir}Average0GenericAffine.mat,1 ] -r ${iterdir}Template0.nii.gz --verbose 1  # Calculate inverse average Warp.nii.gz by average affine matrix
    antsApplyTransforms -d 3 --verbose 1 -i ${iterdir}Template0.nii.gz -o ${iterdir}TemplateUpdate.nii.gz -t [ ${iterdir}Average0GenericAffine.mat,1 ] -t ${iterdir}Averagewarp.nii.gz -t ${iterdir}Averagewarp.nii.gz -t ${iterdir}Averagewarp.nii.gz -t ${iterdir}Averagewarp.nii.gz -r ${iterdir}Template0.nii.gz # update template shape using average Warp.nii.gz and average Affine matrix
    ImageMath 3 ${iterdir}TemplateUpdateSharp.nii.gz Sharpen ${iterdir}TemplateUpdate.nii.gz >/dev/null
    cp ${iterdir}TemplateUpdateSharp.nii.gz ${datadir}InitialTemplate0.nii.gz

}
done

