# DoSDualBand

This script is for test purposes and should not be used on unauthorized networks. 

With common tools such as airgeddon, aircrack-ng or wifite it is not possible to perform a deauth attack if the network supports dual band. The problem here is that you can only perform one attack at a time and if you attack the 2.4GHz channel, the victim will connect to the 5GHz channel and still have internet.

There are several ways to work around this problem. One of them would be to buy a second wifi adapter to attack both channels at the same time. However, if you only have one wifi adapter, this script is perfect for you. 

The principle here is that one channel is attacked first, the attack is aborted after a few seconds and executed on the second channel. Here the attack is aborted again after a few seconds and executed again on the previous channel. A Wifi device always needs a certain amount of time to connect and we exploit this weakness. 
If we attack 2.4GHz first and the user is kicked out here, he connects to 5GHz channel. Until the user has really connected, the first attack ends and is now executed on the 5GHz channel. This means that the user is also kicked out here. Then the whole thing continues indefinitely. It is therefore possible to carry out a DoS attack on a dual band network with just one Wifi adapter, or to attack two networks simultaneously.

The pause between the attacks can be adjusted and reduced to become even more effective.