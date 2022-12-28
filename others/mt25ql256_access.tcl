#invoked by Tcl code that wishes to use a particular version of a
#particular package
package require Tcl 8.5

#set base address according to Platform Designer system
set base 0x00000000

#set the variables to their respective offset
set wr_enable [expr {$base + 0x0}]
set wr_disable [expr {$base + 0x4}]
set wr_status [expr {$base + 0x8}]
set rd_status [expr {$base + 0xc}]
set sector_erase [expr {$base + 0x10}]
set subsector_erase [expr {$base + 0x14}]
set control [expr {$base + 0x20}]
set wr_non_volatile_conf_reg [expr {$base + 0x34}]
set rd_non_volatile_conf_reg [expr {$base + 0x38}]
set rd_flag_status_reg [expr {$base + 0x3c}]
set clr_flag_status_reg [expr {$base + 0x40}]
set bulk_erase [expr {$base + 0x44}]
set die_erase [expr {$base + 0x48}]
set 4bytes_addr_en [expr {$base + 0x4c}]
set 4bytes_addr_ex [expr {$base + 0x50}]
set sector_protect [expr {$base + 0x54}]
set rd_memory_capacity_id [expr {$base + 0x58}]

#assign variable mp to the string that is the 0th element in the list
#returned by get_service_paths master
set mp [lindex [get_service_paths master] 0]

#procedure to open the connection to the master module
proc start_service_master { } {
 global mp
 open_service master $mp
}

#procedure to close the connection to the master module
 proc stop_service_master {} {
 global mp
 close_service master $mp
}

#read silicon id from RD_MEMORY_CAPACITY_ID register
proc read_silicon_id {} {
 global mp rd_memory_capacity_id
 set id [master_read_32 $mp $rd_memory_capacity_id 1]
 puts $id
}

#read status register from RD_STATUS register
proc read_status_register {} {
 global mp rd_status
 set status [master_read_32 $mp $rd_status 1]
 puts $status
}

#write 1 to WR_ENABLE register to perform write enable
proc write_enable {} {
 global mp wr_enable
 master_write_32 $mp $wr_enable 1
}
#applicable for EPCQ256 or EPCQ512/A only
proc enable_4byte_addressing {} {
 global mp 4bytes_addr_en
 master_write_32 $mp $4bytes_addr_en 1
}

#applicable for EPCQ256 or EPCQ512/A only
proc exit_4byte_addressing {} {
 global mp 4bytes_addr_ex
 master_write_32 $mp $4bytes_addr_ex 1
}

#memory read
proc read_memory {addr bytes_size} {
 global mp
 master_read_32 $mp $addr $bytes_size
}

#wait until WIP bit in status register is ready after issue write_memory
proc write_memory {addr data} {
 global mp
 master_write_32 $mp $addr $data
}

#wait until WIP in status register is ready after issue erase_sector
proc erase_sector {sector_addr} {
 global mp sector_erase
 master_write_32 $mp $sector_erase $sector_addr
}

proc erase_bulk {} {
 global mp bulk_erase
 master_write_32 $mp $bulk_erase 1
}

#modify Block Protect Bit and Top/Bottom Bit in Status Register to perform
#block protect
#wait until WIP bit in status register is ready after issue sector_protect
proc sector_protect {block_protect} {
 global mp sector_protect
 write_enable
 master_write_32 $mp $sector_protect $block_protect
}

proc read_nvcr {} {
 global mp rd_non_volatile_conf_reg
 master_read_32 $mp $rd_non_volatile_conf_reg 1
}

#not applicable for EPCQA
proc read_flag_status_reg {} {
 global mp rd_flag_status_reg
 master_read_32 $mp $rd_flag_status_reg 1
}

#not applicable for EPCQA
proc clear_flag_status_reg {value} {
 global mp clr_flag_status_reg
 write_enable
 master_write_32 $mp $clr_flag_status_reg $value
}

#write NVCR[15:0]
#wait until WIP bit in status register is ready after issue write_nvcr
proc write_nvcr {value} {
 global mp wr_non_volatile_conf_reg
 write_enable
 master_write_32 $mp $wr_non_volatile_conf_reg $value
}

#calling the start_service_master procedure
 start_service_master
