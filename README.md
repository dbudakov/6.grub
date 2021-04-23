### Домашнее задание
Работа с загрузчиком  
Цель: Студент получил навыки работы с LVM.  
1. Попасть в систему без пароля несколькими способами  
2. Установить систему с LVM, после чего переименовать VG  
3. Добавить модуль в initrd  

4(*). Сконфигурировать систему без отдельного раздела с /boot, а только с LVM  
Репозиторий с пропатченым grub: https://yum.rumyantsev.com/centos/7/x86_64/  
PV необходимо инициализировать с параметром --bootloaderareasize 1m   
Критерии оценки: Описать действия, описать разницу между методами получения шелла в процессе загрузки.  
Где получится - используем script, где не получается - словами или копипастой описываем действия.  

### Решение
ПРИМЕЧАНИЕ: Для всех манипуляций с настройкими загрузки ядра был убран параметр console ttyS0 c данной опцией нет реакции на изменения параметров загрузки  

1. Попасть в систему без пароля несколькими способами   
1.1 init=/bin/sh   
В этом способе используется shell корневой файловой системы     
```
...init=/bin/sh                 # дописываем в конец строки с параметрами ядра, 
                                # строка начинается с linux6, все лишнии параметры можно
                                # убрать, это не повлияет на загрузку
mount -o remount,rw /           # монтируем корень фс в режим rw
mount | grep root               # проверяем режим монтирования корня
chroot /                        # назначаем корень корнем отсчёта для оболочки
passwd root                     # меняем пароль root
touch .autorelabel              # создаем файл, который является меткой для SELinux на пересчёт ФС, необходимо для 
                                # активации пароля, без данной операции доступа к ОС не будет
reboot                          # перезагрузка системы
                                # после перезагрузки пройдёт оперецация пересчёта со стороны SELinux,
                                # после чего произойдёт вторая перезагрузка
                                # перезагрузка после чего, у root будет новый пароль

### При запуске /bin/sh возможно что оболочка не будет знать команд reboot и shutdown в таком случае, необходимо послать сигналы на ядро:
   echo 1 > /proc/sys/kernel/sysrq
   или
   echo b > /proc/sysrq-trigger
```
 
 

1.2 rd.break   
```
### в данном примере оболочка уже будет знать алиасы и пути для табуляции
rd.break                            # аналогично первому варианту, но дописываем в настройки загрузки 
                                    # указанный параметр, это прервет загрузки, и даст произвести настройку
mount -o remount,rw /sysroot        # перемонтируем корень ФС, в режим rw
chroot /sysroot                     # назначаем указаный каталог корневым для активного шелла
passwd root                         # меняем пароль root
touch /.autorelabel                 # создаем флаг-файл для пересчета SElinux
                                    # аналогично первому варианту произойдёт перезагрузка после SElinux,
                                    # обратитьь внимание на примечание в шапке решения
```


1.3 init=/sysroot/bin/sh    
```
### в данном примере оболчка будет знать алиасы и пути табуляции
init=/sysroot/bin/sh                # в конец строки с параметрами загрузки ядра дописывается указаный 
                                    # параметр означающий загрузку в оболочку SH установленной ОС
mount -o remount,rw /sysroot        # перемонтируем корень ФС, в режим rw
chroot /sysroot                     # назначаем указаный каталог корневым для активного шелла
passwd root                         # меняем пароль root
touch /.autorelabel                 # создаем флаг-файл для пересчета SElinux
                                    # аналогично первому варианту произойдёт перезагрузка после SElinux,
                                    # обратитьь внимание на примечание в шапке решения
```


2. Установить систему с LVM, после чего переименовать VG     
```
vgrename [VG] [new_name_VG]  # переименовываем VG  
less /etc/fstab              # необходимо посмотреть UUID нужного раздела через blkid и поправить /etc/fstab 
less /etc/default/grub       # поправить имя VG, можно предварительно  grep'нуть на наличие имени 
less /boot/grub2/grub.cfg    # аналогично проверить на актуальность путь к корневому разделу
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)  # пересчитываем файл initramfs на актуальные настройки
reboot                       # перезагружаемся
```

3. Добавить модуль в initrd    
```
mkdir /usr/lib/dracut/modules.d/01test 
cat > module-setup.sh
```
module-setup.sh [[здесь]](https://github.com/dbudakov/6.grub/blob/master/file/module-setup.sh)  
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
test.sh  [[здесь]](https://github.com/dbudakov/6.grub/blob/master/file/test.sh)  
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
mkinitrd -f -v /boot/initramfs-$(uname -r).img $(uname -r)    # актуализируем файл initramfs  
or  
dracut -f -v  

lsinitrd -m /boot/initramfs-$(uname -r).img | grep test       # проверяем модуль на наличие 
                                                              # в системе инициализации
reboot  
```

### Дополнительно
BIOS -> MBR -> GRUB -> Kernel -> Init -> Runlevel  [link](https://habr.com/ru/post/113350/)   

### Загрузка из grub
[it610.com](https://www.linux.com/training-tutorials/how-rescue-non-booting-grub-2-linux/)  

```sh
grub> ls
grub> ls (hd0,1)/
  lost+found/ bin/ boot/ cdrom/ dev/ etc/ home/  lib/
  lib64/ media/ mnt/ opt/ proc/ root/ run/ sbin/ 
  srv/ sys/ tmp/ usr/ var/ vmlinuz vmlinuz.old 
  initrd.img initrd.img.old
grub> set root=(hd0,1)
grub> linux /boot/vmlinuz-3.13.0-29-generic root=/dev/sda1
grub> initrd /boot/initrd.img-3.13.0-29-generic
grub> boot
```
