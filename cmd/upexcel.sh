#!/bin/sh
sudo svn up ./excel
rm -rf ./lib/m1x/data/*.ex 
cp  excel/server_out/*.ex ./lib/m1x/data/