#!/bin/bash

export IPT="iptables"

# Внешний интерфейс
export WAN=eth0
export WAN_IP=85.31.203.127

# Локальная сеть
export LAN1=eth1
export LAN1_IP_RANGE=10.1.3.0/24

# Очищаем правила
$IPT -F
$IPT -F -t nat
$IPT -F -t mangle
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X

# Запрещаем все, что не разрешено
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

# Разрешаем localhost и локалку
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A INPUT -i $LAN1 -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
$IPT -A OUTPUT -o $LAN1 -j ACCEPT

# Рзрешаем пинги
$IPT -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
$IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# Разрешаем исходящие подключения сервера
$IPT -A OUTPUT -o $WAN -j ACCEPT
#$IPT -A INPUT -i $WAN -j ACCEPT

# разрешаем установленные подключения
$IPT -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

# Отбрасываем неопознанные пакеты
$IPT -A INPUT -m state --state INVALID -j DROP
$IPT -A FORWARD -m state --state INVALID -j DROP

# Отбрасываем нулевые пакеты
$IPT -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

# Закрываемся от syn-flood атак
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP

# Блокируем доступ с указанных адресов
#$IPT -A INPUT -s 84.122.21.197 -j REJECT

# Пробрасываем порт в локалку
#$IPT -t nat -A PREROUTING -p tcp --dport 23543 -i ${WAN} -j DNAT --to 10.1.3.50:3389
#$IPT -A FORWARD -i $WAN -d 10.1.3.50 -p tcp -m tcp --dport 3389 -j ACCEPT

# Разрешаем доступ из локалки наружу
$IPT -A FORWARD -i $LAN1 -o $WAN -j ACCEPT
# Закрываем доступ снаружи в локалку
$IPT -A FORWARD -i $WAN -o $LAN1 -j REJECT


# Включаем NAT
$IPT -t nat -A POSTROUTING -o $WAN -s $LAN1_IP_RANGE -j MASQUERADE

# открываем доступ к SSH
$IPT -A INPUT -i $WAN -p tcp --dport 22 -j ACCEPT

# Открываем доступ к почтовому серверу
#$IPT -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
#$IPT -A INPUT -p tcp -m tcp --dport 465 -j ACCEPT
#$IPT -A INPUT -p tcp -m tcp --dport 110 -j ACCEPT
#$IPT -A INPUT -p tcp -m tcp --dport 995 -j ACCEPT
#$IPT -A INPUT -p tcp -m tcp --dport 143 -j ACCEPT
#$IPT -A INPUT -p tcp -m tcp --dport 993 -j ACCEPT

#Открываем доступ к web серверу
#$IPT -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
#$IPT -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT

#Открываем доступ к DNS серверу
#$IPT -A INPUT -i $WAN -p udp --dport 53 -j ACCEPT

# Включаем логирование
#$IPT -N block_in
#$IPT -N block_out
#$IPT -N block_fw

#$IPT -A INPUT -j block_in
#$IPT -A OUTPUT -j block_out
#$IPT -A FORWARD -j block_fw

#$IPT -A block_in -j LOG --log-level info --log-prefix "--IN--BLOCK"
#$IPT -A block_in -j DROP
#$IPT -A block_out -j LOG --log-level info --log-prefix "--OUT--BLOCK"
#$IPT -A block_out -j DROP
#$IPT -A block_fw -j LOG --log-level info --log-prefix "--FW--BLOCK"
#$IPT -A block_fw -j DROP

# Сохраняем правила
/sbin/iptables-save  > /etc/sysconfig/iptables
