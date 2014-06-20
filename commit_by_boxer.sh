#!/bin/sh

rake deploy
git add .
git commit -m $* 
git push origin source
