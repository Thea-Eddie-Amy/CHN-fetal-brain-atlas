# CHN-fetal-brain-atlas
A spatiotemporal fetal brain atlas based on Chinese population\
2022 CHN fetal brain atlas V1

Contact:\
Xinyi Xu: xuxinyi_bme@zju.edu.cn\
Dan Wu: danwu.bme@zju.edu.cn

**17/10/2022 Update:**
1. Segmentation resultes of atlases were updated which were processed by nnUnet.
2. Please note the weighted-averaged ages of templates may not correspond exactly to integers. (see Table S6)
3. The transformation across timepoints by coregistering atlases between adjacent gestational weeks in ascending order from 23w atlas to 38w atlas using deformable SyN registrations in ANTs (https://github.com/ANTsX/ANTs). The files can be downloaded at [here](https://drive.google.com/file/d/1NaOycMvN7NN_CstHKtvJo2bbmLTQMJgy/view?usp=sharing).

**This version of the CHN fetal brain atlas was last edited on 04/05/2022**\

Note: all the segementation results were obtained by DrawEM [^1] and cortical grey matter was manually corrected, so there is no warranty of the acuracy or precision of the segmentations.
[^1]: Makropoulos A, Gousias I S, Ledig C, et al. Automatic Whole Brain MRI Segmentation of the Developing Neonatal Brain. IEEE Trans Med Imaging. 2014;33(9): 1818-1831.

Original generated atlas was named as "Atlas_xxw.nii.gz"\
DrawEM 7 tissue labels segmentation was named as "Atlas_xxw_tissue_labels.nii.gz"\
DrawEM 57 parcellation labels segmentation was named as "Atlas_xxw_labels.nii.gz"\
DrawEM 89 all regional labels segmentation was named as "Atlas_xxw_all_labels.nii.gz"

For more details, please refer to: Spatiotemporal atlas of the fetal brain depicts cortical developmental gradient in Chinese population. (https://www.biorxiv.org/content/10.1101/2022.05.09.491258v2)
