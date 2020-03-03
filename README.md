Для всех манипуляций с настройкими загрузки ядра был убран параметр console ttyS0 c данной опцией нет реакции на изменения параметров загрузки

1. Попасть в систему без пароля несколькими способами
1.1 В этом способе используется shell корневой файловой системы  
```
...init=/bin/sh                 # дописываем в конец строки с параметрами ядра, начинается в linux6, все лишнии параметры
                                # можно убрать, это не повлияет на загрузку
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
```
 
 
1.2 rd.break  
```
mount -o remount,rw /sysroot
chroot /sysroot
passwd root
touch /.autorelabel
```

1.3 init=/sysroot/bin/sh   
```
 init=/sysroot/bin/sh   


```

2. Установить систему с LVM, после чего переименовать VG    
```
vgrename 
/etc/fstab                   # необходимо посмотреть UUID нужного раздела через blkid и поправить /etc/fstab 
/etc/default/grub            # поправить имя VG, можно предварительно  grep'нуть на наличие имени 
/boot/grub2/grub.cfg         # аналогично проверить на актуальность путь к корневому разделу
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)  # пересчитываем файл initramfs на актуальные настройки
reboot                       # перезагружаемся
```

3. Добавить модуль в initrd   
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
```
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)          # актуализируем файл initramfs 
or
dracut -f -v

lsinitrd -m /boot/initramfs-$(uname -r).img | grep test             # проверяем модуль на наличие в системе инициализации
telinit 6
```
