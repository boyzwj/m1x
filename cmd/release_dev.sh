#!/bin/sh
if [ ! -n "$REMOTE_HOST" ]; then
  REMOTE_HOST=tom@192.168.15.101
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
sshpass -p "1" ssh $REMOTE_HOST "sudo PHX_SERVER=true RELEASE_NODE=develop /release/m1x/bin/m1x restart"
echo 'begin restart dsa'
sshpass -p "1" ssh $REMOTE_HOST "sudo RELEASE_NODE=dsa_1 DSA_PORT=20081 /release/m1x/bin/m1x restart"
echo '>>>>  restart finish <<<<'