Для всех манипуляций с настройкими загрузки ядра был убран параметр console ttyS0 c данной опцией нет реакции на изменения параметров загрузки

1. Попасть в систему без пароля несколькими способами

В этом способе используется shell корневой файловой системы
init=/bin/sh
mount -o remount,rw /           # монтируем корень фс в режим rw
mount | grep root               # проверяем режим монтирования корня
chroot /                        # назначаем корень корнем отсчёта для оболочки
passwd root                     # меняем пароль root
touch .autorelabel              # создаем файл, который является меткой для SELinux на пересчёт ФС, необходимо для 
                                # активации пароля, без данной операции доступа к ОС не будет
reboot                          # перезагрузка системы
                                # после перезагрузки пройдёт оперецация пересчёта со стороны SELinux, пойдёт вторая
                                # перезагрузка после чего, у root будет новый пароль

####################################
при запуске /bin/sh возможно что система не будет знать команд reboot и shutdown в таком случе необходимо послать сигналы на ядро:
   echo 1 > /proc/sys/kernel/sysrq
   или
   echo b > /proc/sysrq-trigger

 
 
rd.break
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
  
init=/sysroot/bin/sh 


2. Установитþ систему с LVM, после чего переименоватþ VG  
vgrename 
/etc/fstab, /etc/default/grub, /boot/grub2/grub.cfg
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
   


3. Добавитþ модулþ в initrd   
mkdir /usr/lib/dracut/modules.d/01test
module-setup.sh
```

#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
```
test.sh
```
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
```
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)
or
dracut -f -v

lsinitrd -m /boot/initramfs-$(uname -r).img | grep test
telinit 6
