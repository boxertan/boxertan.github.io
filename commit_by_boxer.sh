#!/bin/sh

rake generate
rake deploy
git add .
git commit -m $* 
git push origin source
