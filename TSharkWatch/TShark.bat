title TSHARK
cd D:\Wireshark
D:
tshark -i 1 -H D:\NetworkSecuirty\hosts -f "dst net 208.115.205.106 and not port 80" -Y "(ip.dst == 208.115.205.106 && !ip.src == 113.161.33.25 && !ip.src == 203.184.50.101 && !udp.dstport == 7707 && !tcp.dstport == 55054 && !udp.dstport == 3793 && !udp.dstport == 7708 && !udp.dstport == 9987 && !udp.dstport == 5000 && !tcp.dstport == 6667 && !tcp.dstport == 10011 && !tcp.dstport == 30033 && !tcp.dstport == 41144)"