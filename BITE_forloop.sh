#!/bin/bash

rm BITE_forloop_output.txt

for IMG in 01 02 03 04 05 06 07 08 09 10 11 12 13 14

do sh ./BITE_MRI_to_US.sh $IMG >> BITE_forloop_output.txt

done

grep '^(' BITE_forloop_output.txt > error_list_BITE_MRI_to_US_rigid.txt
