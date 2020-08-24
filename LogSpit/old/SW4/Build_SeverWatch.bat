pp -o=c:\strawberry\perl\bren\serverwatch.exe -log=c:\strawberry\perl\bren\buildlog.txt -vvv -M POE -M POE/Wheel.pm -M POE/Wheel/FollowTail.pm -M POE/Filter.pm -M POE/Filter/Stream.pm -M XML/LibXML/Sax.pm -l libexpat-1__.dll -l libxml2-2__.dll -l libiconv-2__.dll -l liblzma-5__.dll -l zlib1__.dll -l ssleay32__.dll -l libeay32__.dll C:\strawberry\perl\site\lib\serverwatch.pl

ECHO DONE
pause