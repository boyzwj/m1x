#!/bin/sh
if [ ! -n "$REMOTE_HOST" ]; then
  REMOTE_HOST=root@192.168.15.200
fi

if [ ! -n "$NODE_NAME" ]; then
  NODE_NAME=develop
fi

REMOTE_PASS="qweasd1004"

echo "update server to $REMOTE_HOST"

rm -rf ./priv/game_proto/*.proto 
cp proto/*.proto ./priv/game_proto/

MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite

echo 'upload to remote ....'
sudo rsync -rltDvz --password-file=/etc/rsyncd.passwd _build/prod/rel/ $REMOTE_HOST::data
echo '>>>>  upload finish  <<<<'
echo 'begin restart server'

ssh -t $REMOTE_HOST "RELEASE_NODE=$NODE_NAME /release/m1x/bin/m1x stop"
ssh -t $REMOTE_HOST "PHX_SERVER=true RELEASE_NODE=$NODE_NAME DB_PATH=/databases/$NODE_NAME /release/m1x/bin/m1x daemon"
echo 'begin restart dsa'
ssh -t $REMOTE_HOST "RELEASE_NODE=dsa_1 /release/m1x/bin/m1x stop"
ssh -t $REMOTE_HOST "RELEASE_NODE=dsa_1 DSA_PORT=20081 /release/m1x/bin/m1x daemon"
echo '>>>>  restart finish <<<<'