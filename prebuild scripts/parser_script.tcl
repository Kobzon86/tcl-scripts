post_message "++++++++++++++++++++++++++++++++++++++++++++++"
post_message "This TCL script starts before Quartus II build process!!!"
post_message "Script creates hex file and fills it with data from sopcinfo" 

#Открытие файла
set input [open ./qsys/qsys.sopcinfo]
#Перечисление всех опрашиваемых устройств
#alt_vip_cl_swi
#info_ram
set addresmap { 
	dev_info asmi_cntrlr ams_i2c pu_0 \
	alt_vip_cl_cvi_0 alt_vip_cl_cvi_1 alt_vip_cl_cvi_2 alt_vip_cl_cvi_3 alt_vip_cl_cvi_4 alt_vip_cl_cvi_5 alt_vip_cl_cvi_6 alt_vip_cl_cvi_7 \
	Switch_0 \
	alt_vip_cl_clp_0 alt_vip_cl_clp_1 alt_vip_cl_clp_2 alt_vip_cl_clp_3 \
	alt_vip_cl_scl_0 alt_vip_cl_scl_1 alt_vip_cl_scl_2 alt_vip_cl_scl_3 \
	alt_vip_cl_mix \
	alt_vip_cl_cvo_0 alt_vip_cl_cvo_1 alt_vip_cl_cvo_2 alt_vip_cl_cvo_3 \
	arinc429 arinc429 \
	arinc708 \
	milstd1553 \
	discr_cmd_in \
	discr_cmd_out \
}
#Получение адреса модуля из строки
proc getStartAddr {inStr prevstr} \
{
	set i 0	
	set devname [getName $prevstr]
	global 	addresmap
	global HARDWARE
	global offsets
	while { $i < [llength $addresmap] } {
		if { [string match  [ lindex $addresmap $i ]* $devname] } {
			set addr [formathex [getAddr $inStr] 8 "hex"]
			lset HARDWARE $i 4 $addr
			if { $i == 1 } {
				lset HARDWARE 1  4 [formathex [getOffset $addr [ lindex $offsets 7 ]] 8 "hex"]
				lset HARDWARE 1  5 $addr
			}
			if { $i == 2 } {
				lset HARDWARE 2  4 [formathex [getOffset $addr [ lindex $offsets 6 ]] 8 "hex"]
			}
			if { $i == 27 } {
				lset HARDWARE 26 4 [formathex [getOffset $addr [ lindex $offsets 0 ]] 8 "hex"]
				lset HARDWARE 26 5 [formathex [getOffset $addr [ lindex $offsets 2 ]] 8 "hex"]
				lset HARDWARE 27 4 [formathex [getOffset $addr [ lindex $offsets 1 ]] 8 "hex"]
				lset HARDWARE 27 5 [formathex [getOffset $addr [ lindex $offsets 3 ]] 8 "hex"]
			}
			if { $i == 28 } {
				lset HARDWARE 28 4 [formathex [getOffset $addr [ lindex $offsets 4 ]] 8 "hex"]
				lset HARDWARE 28 5 [formathex [getOffset $addr [ lindex $offsets 5 ]] 8 "hex"]
			}
		}
		incr  i
	}
}
proc getAddr {inStr} \
{
	set trleft [string range $inStr [string first "<baseAddress>" $inStr] end]; #обрезка строки до упоминания модуля	
	set addr [string range $trleft [ expr {[string first "<baseAddress>" $trleft] + [ string length "<baseAddress>" ]} ] [expr { [string first "</baseAddress>" $trleft] - 1 }]];
	return $addr
}
proc getName {inStr} \
{
	set trleft [string trim $inStr]; #обрезка строки до упоминания модуля
	if {[string match *video_core* $trleft]} {
	set name [string range $trleft [string first "alt" $trleft] [expr { [string first "</name>" $trleft] - 1 }]];
	} else {
	set name [string range $trleft [ expr {[string first "<name>" $trleft] + [ string length "<name>" ]} ] [expr { [string first "</name>" $trleft] - 1 }]];
	}

	if {[string match *Switch* $trleft]} {
	set name [string range $trleft [string first "Switch" $trleft] [expr { [string first "</name>" $trleft] - 1 }]];
	}
	
	return $name
}
#Функция проверяет наличие в строке параметра из списка
#возвращает { a b c }, где a = 0 - Arinc429Rx, a = 1 - Arinc429Tx, a = 2 - Arinc708,
# b = 1 требуется преобразование в hex
# c - позиция параметра в строке массива HARDWARE(см. ниже)
proc isParam { prevstr } \
{
	if { [string match "*CMacro.RX_CHANNELS*" $prevstr]} {
		return { 0 1 2 }
	}
	if { [string match "*CMacro.RX_CSR_ALIGN*" $prevstr]} {
		return { 0 0 6 }
	}
	if { [string match "*CMacro.RX_CSR_OFFSET*" $prevstr]} {
		return { 0 0 4 }
	}
	if { [string match "*CMacro.RX_MEM_ALIGN*" $prevstr]} {
		return { 0 0 7 }
	}
	if { [string match "*CMacro.RX_MEM_OFFSET*" $prevstr]} {
		return { 0 0 5 }
	}
	if { [string match "*CMacro.TX_CSR_OFFSET*" $prevstr]} {
		return { 0 1 4 }
	}
	if { [string match "*CMacro.TX_MEM_OFFSET*" $prevstr]} {
		return { 0 1 5 }
	}
	if { [string match "*CMacro.TX_CHANNELS*" $prevstr]} {
		return { 1 1 2 }
	}
	if { [string match "*CMacro.TX_CSR_ALIGN*" $prevstr]} {
		return { 1 0 6 }
	}
	if { [string match "*CMacro.TX_MEM_ALIGN*" $prevstr]} {
		return { 1 0 7 }
	}
	if { [string match "*CMacro.CHANNELS*" $prevstr]} {
		return { 2 1 2 }
	}
	if { [string match "*CMacro.CSR_ALIGN*" $prevstr]} {
		return { 2 0 6 }
	}
	if { [string match "*CMacro.CSR_OFFSET*" $prevstr]} {
		return { 2 0 4 }
	}
	if { [string match "*CMacro.MEM_ALIGN*" $prevstr]} {
		return { 2 0 7 }
	}
	if { [string match "*CMacro.MEM_OFFSET*" $prevstr]} {
		return { 2 0 5 }
	}
	return "DEADBEEF"
	
}
#Получение параметра из строки
proc getParam { inStr } \
{
	if { [string match "*<value>0x*" $inStr] } {
		set out [string range $inStr [ string length "<value>0x" ] [expr { [string first "</value>" $inStr] - 1 }]];
	} else {
		set out [string range $inStr [ string length "<value>" ] [expr { [string first "</value>" $inStr] - 1 }]];
	}
	return $out
}
#Форматирование числа - преобразование в hex и дополнение числа до нужной длины
proc formathex {numb len dehex} \
{
	set b "0"
	if { $dehex == "hex" } {			
		if { $len ==  4} {
			set b [format %4.4X $numb]
		} 
		if { $len ==  8} {
			set b [format %8.8X $numb]
		} 
		if { $len ==  2} {
			set b [format %2.2X $numb]
		}
		return $b
	} else {
		while {[string length $numb] < $len} {
			set numb $b$numb
		}
		return $numb
	}	
}
#Добавление смещения к адресу
proc getOffset {numb1 numb2} \
{
	scan $numb1 %x decimal1
	scan $numb2 %x decimal2
	set orr [expr { $decimal1 + $decimal2 }]
	return $orr
}
#Расчет контрольной суммы строки для записи в hex-файл
proc getCRC {str} \
{
	set summ 0
	for {set i 1} { $i < [string length $str] } {set i [expr { $i + 2}]} {
		set rr [string range $str $i [ expr { $i + 1 }]]
		scan $rr %x decimal
		set summ [expr { $summ + $decimal }]		
	}
	set notsumm [expr { -$summ }]
	set short [expr { $notsumm & 255}]
	return $short
}
#Рабочий массив для записи в память
set HARDWARE [lrepeat 32 [lrepeat 8 "00000000"]]
#массив для инициализации HARDWARE
set INTERFACE_INFO { "00000000" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000010" "00000000" \
                     "00000001" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00010000" \
                     "00000002" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000010" "00000000" \
                     "00000003" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000020" "00000000" \
                     "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000004" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000005" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000006" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000006" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000006" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000006" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000100" "00000000" \
					 "00000007" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000200" "00000000" \
					 "00000007" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000200" "00000000" \
					 "00000007" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000200" "00000000" \
					 "00000007" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000200" "00000000" \
					 "00000008" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000200" "00000000" \
					 "00000009" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000400" "00000000" \
					 "00000009" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000400" "00000000" \
					 "00000009" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000400" "00000000" \
					 "00000009" "00000000" "00000001" "00000000" "DEADBEEF" "00000000" "00000400" "00000000" \
					 "0000000A" "00000000" "00000010" "00000000" "DEADBEEF" "00200000" "00010000" "00010000" \
					 "0000000B" "00000000" "00000006" "00000000" "DEADBEEF" "00280000" "00010000" "00010000" \
					 "0000000C" "00000000" "00000002" "00000000" "DEADBEEF" "00300000" "00010000" "00010000" \
					 "0000000D" "00000000" "00000002" "00000000" "DEADBEEF" "DEADBEEF" "DEADBEEF" "DEADBEEF" \
					 "0000000E" "00000000" "00000008" "00000000" "DEADBEEF" "00000000" "00000010" "00000000" \
					 "0000000F" "00000000" "00000004" "00000000" "DEADBEEF" "00000000" "00000010" "00000000" }
 

#main----------------------------------------------------------------------------
#--------------------------------------------------------------------------------
set i 0	
set y 0	
# буфер предыдущей строки
set prevstr "" 
# буфер смещений адреса
set offsets {0 0 0 0 0 0 6000 10000}
#инициализация HARDWARE
while { $i < [llength $HARDWARE] } {
	while { $y < 8 } {
		lset HARDWARE $i $y [lindex $INTERFACE_INFO [expr { $y + 8 * $i }]]		
		incr y 
	}
	set y 0
	incr i
}

set pci_addresses 0
#Перебор строк файла
while { [gets $input data] >= 0 } {
	#Если строка содержит значение, а в предыдущей строке содержится правильное имя параметра,
	#то параметер записываетс  в HARDWARE и в список смещений offsets
	if { [string match "<value>*</value>" [string trim $data]] } {
		set param [isParam $prevstr]

		if { $param != "DEADBEEF" } {
		 	set value [getParam [string trim $data]]
		 	if {[lindex $param 1] == 1} {
		 		set formatedval [formathex $value 8 "hex"]
		 	} else {
		 		set formatedval [formathex $value 8 "dec"]
		 	}
		 	lset HARDWARE [expr { 26 + [lindex $param 0] }] [lindex $param 2] $formatedval

		 	if { [lindex $param 2] == 4 } {
		 		if { [lindex $param 0] == 2 } {
		 			lset offsets 4 $value
		 		} else {
					lset offsets [expr { 0 + [lindex $param 1] }] $value 
		 		}
		 	}
		 	if { [lindex $param 2] == 5 } {
		 		if { [lindex $param 0] == 2 } {
		 			lset offsets 5 $value
		 		} else {
					lset offsets [expr { 2 + [lindex $param 1] }] $value 
		 		}
		 	}
		}
	}

	if { [string match *name=\"pcie_cv_hip_avmm* $data] && [string match  *<module $prevstr] } {
		set pci_addresses 1
	}
	if {[string match  *</module> $data]} {
		set pci_addresses 0
	}
	#Если строка содержит адреса, то их сравнивают с элементами списка addresmap и записывают в HARDWARE по индексу 4
	#в строки аринков(номера 27 28) записываются адреса со смещениями, полученными ранее
	if { $pci_addresses } {
		if { [string match  *<baseAddress>*</baseAddress> $data]} {
			getStartAddr $data $prevstr
		}
	}
	set prevstr $data

}
close $input
#Заполнение столбца "Индекс"
set prevnum ""
set ccc 0
set i 0
while { $i < [llength $HARDWARE] } {
	if { [lindex $HARDWARE $i 0] == $prevnum } {
		if { [lindex $HARDWARE [expr { $i - 1 }] 4] != "DEADBEEF" } {
			if { [lindex $HARDWARE $i 4] != "DEADBEEF" } {			
				incr ccc
				lset HARDWARE $i 1 [formathex $ccc 8 "hex"]
			}
		}
	} else {
		set ccc 0
	}
	set prevnum [lindex $HARDWARE $i 0]
	incr i
}

#Запись hex файла
#заполнение его массивом HARDWARE , рассчет контрольных сумм
set output [open hrom.hex w]
puts $output ":020000020000FC"
set i 0
set y 0
while { $y < 128 } {
	set strtowrite ":20"
	append strtowrite [formathex [expr { $y * 8 }] 4 "hex"] "00"
	if { $i < [llength $HARDWARE]  } {
		set t_hardware [lindex $HARDWARE $i]
		if { [lindex $HARDWARE $i 4] != "DEADBEEF"} {
			foreach var $t_hardware {
				set strtowrite $strtowrite$var
			}
			set CRC [getCRC $strtowrite]
			append strtowrite [formathex $CRC 2 "hex"]
			puts $output $strtowrite
			incr y						
		}
	} else {
		append strtowrite "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
		set CRC [getCRC $strtowrite]
		append strtowrite [formathex $CRC 2 "hex"]
		puts $output $strtowrite
		incr y
	}
	incr i
}
puts $output ":00000001FF"

close $output

set fd [open "version.svh" "w"]

set hash [exec git describe --always]
post_message "\[INFO\]Current short commit hash: 0x$hash"
puts $fd "`define hash 32'h$hash"

set current_time [clock seconds]
post_message "\[INFO\]Current UNIX Timestamp: $current_time\(0x[format %x $current_time]\)"
puts $fd "`define timestmp $current_time"

set number_version "2958367"
post_message "\[INFO\]Current Version: $number_version\(0x[format %x $number_version]\)"
puts $fd "`define number_version $number_version"
close $fd



post_message "Script was finished !" 