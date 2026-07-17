#!/bin/bash -e

echo '> phdconf Secure Boot key:'
if ! (sudo certutil -L -d /etc/pki/pesign | grep 'phdconf Secure Boot key'); then
    echo '> Not found.'
    sudo efikeygen --dbdir /etc/pki/pesign --self-sign --kernel --common-name 'CN=phdconf Secure Boot key' --nickname 'phdconf Secure Boot key' || true
fi

echo '> /etc/kernel/phdconf_secure_boot_cert.cer:'
if [ ! -e /etc/kernel/phdconf_secure_boot_cert.cer ]; then
    echo '> Not found.'
    (sudo certutil -d /etc/pki/pesign -n 'phdconf Secure Boot key' -Lr | sudo tee /etc/kernel/phdconf_secure_boot_cert.cer >/dev/null) || true
    echo 'Enter a one-time password that will be used in BIOS to enroll this key:'
    sudo mokutil --import /etc/kernel/phdconf_secure_boot_cert.cer || true
    echo 'Reboot now and follow your BIOS procedure to enroll this key.'
fi

echo '> OK'
