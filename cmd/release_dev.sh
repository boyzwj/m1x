#!/bin/sh
if [ ! -n "$REMOTE_HOST" ]; then
  REMOTE_HOST=tom@192.168.15.101
fi

if [ ! -n "$NODE_NAME" ]; then
  NODE_NAME=develop
fi

REMOTE_PASS="1"

echo "update server to $REMOTE_HOST"

rm -rf ./priv/game_proto/*.proto 
cp proto/*.proto ./priv/game_proto/

MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release --overwrite

echo 'upload to remote ....'
sudo rsync -rltDvz --password-file=/etc/rsyncd.passwd _build/prod/rel/ $REMOTE_HOST::data
echo '>>>>  upload finish  <<<<'
echo 'begin restart server'

sshpass -p "1" ssh -t $REMOTE_HOST "sudo RELEASE_NODE=$NODE_NAME /release/m1x/bin/m1x stop"
sshpass -p "1" ssh -t $REMOTE_HOST "sudo PHX_SERVER=true RELEASE_NODE=$NODE_NAME DB_PATH=\$HOME/db_data/$NODE_NAME /release/m1x/bin/m1x daemon_iex"
echo 'begin restart dsa'
sshpass -p "1" ssh -t $REMOTE_HOST "sudo RELEASE_NODE=dsa_1 /release/m1x/bin/m1x stop"
sshpass -p "1" ssh -t $REMOTE_HOST "sudo RELEASE_NODE=dsa_1 DSA_PORT=20081 /release/m1x/bin/m1x daemon_iex"
echo '>>>>  restart finish <<<<'