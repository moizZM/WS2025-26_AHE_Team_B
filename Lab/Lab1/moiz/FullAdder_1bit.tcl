
################################################################
# This is a generated script based on design: FullAdder_1bit
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2025.1
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source FullAdder_1bit_script.tcl

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7vx485tffg1157-1
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name FullAdder_1bit

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:user:full_adder:1.0\
xilinx.com:ip:xlslice:1.0\
xilinx.com:ip:xlconcat:2.1\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports

  # Create ports
  set A [ create_bd_port -dir I A ]
  set B [ create_bd_port -dir I B ]
  set C_in [ create_bd_port -dir I C_in ]
  set S [ create_bd_port -dir O -from 3 -to 0 S ]
  set C_out [ create_bd_port -dir O C_out ]

  # Create instance: full_adder_0, and set properties
  set full_adder_0 [ create_bd_cell -type ip -vlnv xilinx.com:user:full_adder:1.0 full_adder_0 ]

  # Create instance: full_adder_1, and set properties
  set full_adder_1 [ create_bd_cell -type ip -vlnv xilinx.com:user:full_adder:1.0 full_adder_1 ]

  # Create instance: full_adder_2, and set properties
  set full_adder_2 [ create_bd_cell -type ip -vlnv xilinx.com:user:full_adder:1.0 full_adder_2 ]

  # Create instance: full_adder_3, and set properties
  set full_adder_3 [ create_bd_cell -type ip -vlnv xilinx.com:user:full_adder:1.0 full_adder_3 ]

  # Create instance: xlslice_0, and set properties
  set xlslice_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0 ]

  # Create instance: xlslice_1, and set properties
  set xlslice_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1 ]

  # Create instance: xlslice_2, and set properties
  set xlslice_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2 ]

  # Create instance: xlslice_3, and set properties
  set xlslice_3 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3 ]

  # Create instance: xlslice_4, and set properties
  set xlslice_4 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4 ]

  # Create instance: xlslice_5, and set properties
  set xlslice_5 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5 ]

  # Create instance: xlslice_7, and set properties
  set xlslice_7 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_7 ]

  # Create instance: xlslice_8, and set properties
  set xlslice_8 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_8 ]

  # Create instance: xlslice_11, and set properties
  set xlslice_11 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_11 ]

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
  set_property CONFIG.NUM_PORTS {4} $xlconcat_0


  # Create port connections
  connect_bd_net -net A_1  [get_bd_ports A] \
  [get_bd_pins xlslice_0/Din] \
  [get_bd_pins xlslice_3/Din] \
  [get_bd_pins xlslice_11/Din] \
  [get_bd_pins xlslice_4/Din]
  connect_bd_net -net B_1  [get_bd_ports B] \
  [get_bd_pins xlslice_1/Din] \
  [get_bd_pins xlslice_5/Din] \
  [get_bd_pins xlslice_8/Din] \
  [get_bd_pins xlslice_7/Din]
  connect_bd_net -net C_in_1  [get_bd_ports C_in] \
  [get_bd_pins xlslice_2/Din]
  connect_bd_net -net full_adder_0_S  [get_bd_pins full_adder_0/S] \
  [get_bd_pins xlconcat_0/In0]
  connect_bd_net -net full_adder_0_c_out  [get_bd_pins full_adder_0/c_out] \
  [get_bd_pins full_adder_1/c_in]
  connect_bd_net -net full_adder_1_S  [get_bd_pins full_adder_1/S] \
  [get_bd_pins xlconcat_0/In1]
  connect_bd_net -net full_adder_1_c_out  [get_bd_pins full_adder_1/c_out] \
  [get_bd_pins full_adder_2/c_in]
  connect_bd_net -net full_adder_2_S  [get_bd_pins full_adder_2/S] \
  [get_bd_pins xlconcat_0/In2]
  connect_bd_net -net full_adder_2_c_out  [get_bd_pins full_adder_2/c_out] \
  [get_bd_pins full_adder_3/c_in]
  connect_bd_net -net full_adder_3_S  [get_bd_pins full_adder_3/S] \
  [get_bd_pins xlconcat_0/In3]
  connect_bd_net -net full_adder_3_c_out  [get_bd_pins full_adder_3/c_out] \
  [get_bd_ports C_out]
  connect_bd_net -net xlconcat_0_dout  [get_bd_pins xlconcat_0/dout] \
  [get_bd_ports S]
  connect_bd_net -net xlslice_0_Dout  [get_bd_pins xlslice_0/Dout] \
  [get_bd_pins full_adder_0/A]
  connect_bd_net -net xlslice_11_Dout  [get_bd_pins xlslice_11/Dout] \
  [get_bd_pins full_adder_2/A]
  connect_bd_net -net xlslice_1_Dout  [get_bd_pins xlslice_1/Dout] \
  [get_bd_pins full_adder_0/B]
  connect_bd_net -net xlslice_2_Dout  [get_bd_pins xlslice_2/Dout] \
  [get_bd_pins full_adder_0/c_in]
  connect_bd_net -net xlslice_3_Dout  [get_bd_pins xlslice_3/Dout] \
  [get_bd_pins full_adder_1/A]
  connect_bd_net -net xlslice_4_Dout  [get_bd_pins xlslice_4/Dout] \
  [get_bd_pins full_adder_3/A]
  connect_bd_net -net xlslice_5_Dout  [get_bd_pins xlslice_5/Dout] \
  [get_bd_pins full_adder_1/B]
  connect_bd_net -net xlslice_7_Dout  [get_bd_pins xlslice_7/Dout] \
  [get_bd_pins full_adder_3/B]
  connect_bd_net -net xlslice_8_Dout  [get_bd_pins xlslice_8/Dout] \
  [get_bd_pins full_adder_2/B]

  # Create address segments


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


