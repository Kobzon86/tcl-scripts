#
# Pre flow script
#

load_package flow
load_package misc

if { [ file exists "./output_files/mfd15.sof" ] == 1 && [ file exists "./mfd15.cof" ] == 1 } {
  qexec "quartus_cpf -c ./mfd15.cof > ./output_files/mfd15_cof.rpt"
}
