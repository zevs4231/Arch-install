#!/bin/bash
#bash
loadkeys ru
setfont cyr-sun16
modprobe dm-mod
modprobe dm-crypt
clear
echo " 
Разметка диска производится в cfdisk! 
Указать: 
(для UEFI):  type=EFI для boot раздела 
(для BIOS):  type=linux83 + флажок bootable
Также указать :
type=linux82 для swap
type=linux83 для других разделов будущей системы ( root, home ) 
КАЖДОЕ ИЗМЕНЕНИЕ WRITE->yes!
"
###
echo "Добро пожаловать в установку ArchLinux"
###
echo ""
echo " Здесь выбрать то, каким режимом запущен установочный образ ArchLinux"
while 
    read -n1 -p  "
    1 - UEFI

    2 - GRUB-legacy

    0 - exit " menu # sends right after the keypress
#    echo ''
[[ "$menu" =~ [^120] ]]
do
    : 
done
if [[ $menu == 1 ]]; then
    clear
    ###################################################
    ################часть первая#######################
    pacman -Sy --noconfirm
    echo ""
    lsblk -f
    echo " Здесь вы можете удалить boot от старой системы, файлы Windows загрузчика не затрагиваются."
    echo " если вам необходимо полность очистить boot раздел, то пропустите этот этап, далее установка предложит отформатировать boot раздел "
    echo " При установке дуал бут раздел не нужно форматировать! "
    echo ""
    echo 'удалим старый загрузчик linux?'
    while 
        read -n1 -p  "
        1 - удалим старый загрузчкик линукс 
        
        0 -(пропустить) - данный этап можно пропустить если установка производиться первый раз или несколько OS  " boots 
        echo ''
        [[ "$boots" =~ [^10] ]]
    do
        :
    done
    if [[ $boots == 1 ]]; then
        clear
        lsblk -f
        echo ""
        read -p "Укажите boot раздел ( например sda2, nvme0n1p3 ):" bootd
        mount /dev/$bootd /mnt
        cd /mnt
        ls | grep -v EFI | xargs rm -rfv
        cd /mnt/EFI
        ls | grep -v Boot | grep -v Microsoft | xargs rm -rfv
        cd /root
        umount /mnt
    elif [[ $boots == 0 ]]; then
        echo " очистка boot раздела пропущена, далее вы сможете его отформатировать! "   
    fi
    #
    pacman -Sy --noconfirm
    ##############################
    clear
    echo ""
    echo " Выбирайте "1 ", если ранее не производилась разметка диска и у вас нет разделов для ArchLinux "
    echo ""
    echo 'Нужна разметка диска?'
    while 
        read -n1 -p  "
        1 - да
        
        0 - нет: " cfdis # sends right after the keypress
        echo ''
        [[ "$cfdis" =~ [^10] ]]
    do
        :
    done
    if [[ $cfdis == 1 ]]; then
        clear
        lsblk -f
        echo "Сейчас будет провдиться разметка диска."
        echo "Создайте 3 раздела: sda1 тип EFI system"
        echo "                    sda2 тип linux 82 solaris"
        echo "                    sda3 тип linux 83"
        read -p "Укажите диск (например sda или nvme0n1) : " cfd
        cfdisk /dev/$cfd
        echo ""
        clear
    elif [[ $cfdis == 0 ]]; then
        echo ""
        clear
        echo 'разметка пропущена.'   
    fi
    #
    clear
    lsblk -f
    echo ""
    
    ############ swap   ####################################################
    clear
    lsblk -f
    while 
        read -n1 -p  "
        1 - форматируем и монтируем swap
        
        2 - пропустить если swap раздела нет : " swa
        echo ''
        [[ "$swa" =~ [^12] ]]
    do
        :
    done
    if [[ $swa == 1 ]]; then
        read -p "Укажите swap раздел(например sda2, nvme0n1p2): " swaps
        mkswap /dev/$swaps -L swap
        swapon /dev/$swaps
    elif [[ $swa == 2 ]]; then
        echo " идем дальше "
    fi
    
    ################  root     ############################################################ 
    clear
    echo ""
    echo " Приступаем к созданию логического объема."
    echo ""
    lsblk -f
    read -p "Укажите ЛВМ раздел(например sda3, nvme0n1p3): " root

    pvcreate /dev/$root
    vgcreate vg_arch /dev/$root
    lvcreate -l 100%FREE -n root vg_arch
    clear
    echo "Вот вывод PVDISPLAY:"
    pvdisplay
    read -n 1 -s -r -p "Press any key to continue"
    clear
    echo "Вот вывод VGDISPLAY:"
    vgdisplay
    read -n 1 -s -r -p "Press any key to continue"
    clear
    echo "Вот вывод LVDISPLAY:"
    lvdisplay
    read -n 1 -s -r -p "Press any key to continue"

    ############ mount ################
    mkfs.ext4 /dev/vg_arch/root

    mount /dev/vg_arch/root /mnt/

    ########## boot  ########
    clear
    lsblk -f
    echo ""
    echo 'форматируем BOOT?'
    while 
        read -n1 -p  "
        1 - да
        
        0 - нет: " boots # sends right after the keypress
        echo ''
        [[ "$boots" =~ [^10] ]]
    do
        :
    done
    if [[ $boots == 1 ]]; then
        read -p "Укажите BOOT раздел(например sda1, nvme0n1p1):" bootdd
        mkfs.fat -F32 /dev/$bootd
        mkdir /mnt/boot
        mount /dev/$bootdd /mnt/boot
    elif [[ $boots == 0 ]]; then
        read -p "Укажите BOOT раздел(например sda1, nvme0n1p1):" bootdd 
        mkdir /mnt/boot
        mount /dev/$bootdd /mnt/boot
    fi
    clear

    ################################################################################### 
    # смена зеркал  
    echo ""
    echo " Данный этап можно пропустить если не уверены в своем выборе!!! " 
    echo " "
    echo 'Сменим зеркала (reflector) для увеличения скорости загрузки пакетов?'
    while 
        read -n1 -p  "
        1 - да
        
        0 - нет: " zerkala # sends right after the keypress
        echo ' '
        [[ "$zerkala" =~ [^10] ]]
    do
        :
    done
    if [[ $zerkala == 1 ]]; then
        pacman -S reflector --noconfirm
        reflector --verbose -l 50 -p https --sort rate --save /etc/pacman.d/mirrorlist
        reflector --verbose -l 15 --sort rate --save /etc/pacman.d/mirrorlist
        clear
    elif [[ $zerkala == 0 ]]; then
        clear
        echo 'смена зеркал пропущена.'   
    fi
    pacman -Sy --noconfirm 
    ######
    clear 
    echo 'Установка базовой системы'
    pacstrap /mnt base base-devel linux linux-headers dhcpcd inetutils wget vim linux-firmware efibootmgr grub mkinitcpio git
    genfstab -p -U /mnt >> /mnt/etc/fstab
    ##################################################
    clear
    echo "Если вы производите установку используя Wifi тогда рекомендую  "1" "
    echo ""
    echo "если проводной интернет тогда "2" " 
    echo ""
    echo 'wifi или dhcpcd ?'
    arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/zevs4231/Arch-install/main/chroot.sh)"
    echo "################################################################"
    echo "###################    T H E   E N D      ######################"
    echo "################################################################"
    read -n 1 -s -r -p "Press any key to continue"
    umount -R /mnt
    reboot  
fi
#####################################
###############часть вторая##########
elif [[ $menu == 2 ]]; then 
    clear
    echo "Добро пожаловать в установку ArchLinux режим GRUB-Legacy "
    lsblk -f
    echo ""
    echo " Выбирайте "1", если ранее не производилась разметка диска и у вас нет разделов для ArchLinux "
    echo " Лучше выбрать 1, чтоб правильно поставить ЛВМ!"
    echo ""
    echo 'Нужна разметка диска?'
    while 
    read -n1 -p  "
    1 - да
        
    0 - нет: " cfdis # sends right after the keypress
        echo ''
        [[ "$cfdis" =~ [^10] ]]
    do
        :
    done
    if [[ $cfdis == 1 ]]; then
        clear
        lsblk -f
        echo ""
        echo "Сейчас будет производиться разметка диска."
        echo "Создайте 3 раздела: sda1 с флагом boot тип linux 83;"
        echo "                    sda2 тип linux 82 solaris"
        echo "                    sda3 тип linux 83"
        read -p " Укажите диск (например, sda или nvme0n1) " cfd
        cfdisk /dev/$cfd
    elif [[ $cfdis == 0 ]]; then
        echo 'разметка пропущена.'   
    fi
    #
    clear
    lsblk -f
    echo ""
    

    ############ swap   ####################################################
    clear
    lsblk -f
    while 
        read -n1 -p  "
        1 - форматируем и монтируем swap
        
        2 - пропустить если swap раздела нет : " swa
        echo ''
        [[ "$swa" =~ [^12] ]]
    do
        :
    done
    if [[ $swa == 1 ]]; then
        read -p "Укажите swap раздел(например sda2, nvme0n1p2):" swaps
        mkswap /dev/$swaps -L swap
        swapon /dev/$swaps
    elif [[ $swa == 2 ]]; then
        echo " идем дальше "
    fi
    
    ################  root     ############################################################ 
    clear
    echo ""
    echo " Приступаем к созданию логического объема."
    echo ""
    lsblk -f
    read -p "Укажите ЛВМ раздел(например sda3, nvme0n1p3):" home

    pvcreate /dev/$root
    vgcreate vg_arch /dev/$root
    lvcreate -l 100%FREE -n root vg_arch
    clear
    echo "Вот вывод PVDISPLAY:"
    pvdisplay
    read -n 1 -s -r -p "Press any key to continue"
    clear
    echo "Вот вывод VGDISPLAY:"
    vgdisplay
    read -n 1 -s -r -p "Press any key to continue"
    clear
    echo "Вот вывод LVDISPLAY:"
    lvdisplay
    read -n 1 -s -r -p "Press any key to continue"

    ############ mount ################
    mkfs.ext4 /dev/vg_arch/root
    mount /dev/vg_arch/root /mnt/
    ########################
    ########## boot  ########
    echo ' добавим и отформатируем BOOT?'
    echo " Если производиться установка, и у вас уже имеется бут раздел от предыдущей системы "
    echo " тогда вам необходимо его форматировать "1", если у вас бут раздел не вынесен на другой раздел тогда "
    echo " этот этап можно пропустить "2" "
    while 
        read -n1 -p  "
        1 - форматировать и монтировать на отдельный раздел
        
        2 - пропустить если бут раздела нет : " boots 
        echo ''
        [[ "$boots" =~ [^12] ]]
    do
        :
    done
    if [[ $boots == 1 ]]; then
        read -p "Укажите BOOT раздел(например sda1, nvme0n1p1): " bootdd
        mkfs.ext2  /dev/$bootdd -L boot
        mkdir /mnt/boot
        mount /dev/$bootdd /mnt/boot
    elif [[ $boots == 2 ]]; then
        echo " идем дальше "
    fi
    clear
    # смена зеркал  
    echo ""
    echo " Данный этап можно пропустить если не уверены в своем выборе! " 
    echo " "
    echo 'Сменим зеркала (reflector) для увеличения скорости загрузки пакетов?'
    while 
        read -n1 -p  "
        1 - да
        
        0 - нет: " zerkala # sends right after the keypress
        echo ' '
        [[ "$zerkala" =~ [^10] ]]
    do
        :
    done
    if [[ $zerkala == 1 ]]; then
        pacman -S reflector --noconfirm
        reflector --verbose -l 50 -p https --sort rate --save /etc/pacman.d/mirrorlist
        reflector --verbose -l 15 --sort rate --save /etc/pacman.d/mirrorlist
        clear
    elif [[ $zerkala == 0 ]]; then
        clear
        echo 'смена зеркал пропущена.'   
    fi
    pacman -Sy --noconfirm
    ################################################################################### 
    clear
    echo ""
    echo 'Установка базовой системы'
    pacstrap /mnt base base-devel linux linux-headers dhcpcd inetutils wget vim linux-firmware grub mkinitcpio git
    genfstab -pU /mnt >> /mnt/etc/fstab
    arch-chroot /mnt sh -c "$(curl -fsSL https://raw.githubusercontent.com/zevs4231/Arch-install/main/chroot.sh)"
    echo "################################################################"
    echo "###################    T H E   E N D      ######################"
    echo "################################################################"
    read -n 1 -s -r -p "Press any key to continue"
    umount -R /mnt
    reboot  
fi

##############################################
elif [[ $menu == 0 ]]; then
exit
fi