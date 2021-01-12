import os
import sys
import src.PySiCroFClass.SiCroF

# Creating instance
world=src.PySiCroFClass.SiCroF.SiCroF()

#### Pre-Processing ####
#world.prepro.setNumOfCore(1)
#world.prepro.addObject("debug/scandata/case1GM.png")
#world.prepro.addObject("debug/scandata/case2GM.png")
#world.prepro.addObject("debug/scandata/case3GM.png")
#world.prepro.addObject("debug/scandata/case4GM.png")
#world.prepro.removeObject("debug/scandata/case3GM.png")
#world.prepro.addObject("debug/scandata/case3GM.png")
#
#world.prepro.setRGBColor(28,255,255)
#world.prepro.exportFortranScript()
#
#
#world.prepro.run()
#exit()
#### Pre-Processing ####

#### Solver ####
# set Num of CPU cores
world.solver.setNumOfCore(1)
os.system("touch Debug_domainlist.txt")
os.system("echo '1' > Debug_domainlist.txt")
os.system("echo 'FEMDomain1.scf' >> Debug_domainlist.txt")
#os.system("FEMDomain2.scf >> Debug_domainlist.txt")
os.system("touch Debug_Ifacelist.txt")
os.system("echo '0' > Debug_Ifacelist.txt")

# set Domain-List (.scf-formatted input files for SiCroF)
world.solver.importDomains("Debug_domainlist.txt")
# set Iinterface-List (.scf-formatted input files for SiCroF)
world.solver.importInterfaces("Debug_Ifacelist.txt")
# setup simulation-time
world.solver.setSimulationTime(1.00)
world.solver.setTimeStep(1)
# output intermediate file for Fortran2003
world.solver.exportFortranScript()

# run simulation
world.solver.run()
#### Solver ####

