#!/bin/sh
sudo svn up proto
rm -rf ./priv/game_proto/*.proto 
cp  proto/*.proto ./priv/game_proto/