
#!/bin/bash
#/usr/lib/dracut/modules.d/01test/module-setup.sh

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/test.sh"
}
