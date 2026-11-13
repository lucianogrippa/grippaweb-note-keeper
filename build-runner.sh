#!/bin/bash
exec dart run build_runner watch --delete-conflicting-outputs &
wait
ps aux | grep build_runner