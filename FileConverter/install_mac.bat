#!/bin/sh

"/Applications/Adobe Flash Builder 4.7/sdks/4.6.0/bin/adt" -package -tsa none -storetype pkcs12 -keystore ../../Certificate/fileconverter-2.p12 -storepass axaio ../FileConverter.air src/FileConverter-app.xml -C bin-debug FileConverter.swf -C res axaio_rot_128.png
