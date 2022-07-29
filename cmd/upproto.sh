#!/bin/sh
sudo svn up ../pb
rm -rf ./priv/game_proto/*.proto 
cp ../pb/*.proto ./priv/game_proto/