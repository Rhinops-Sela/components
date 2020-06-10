#!/bin/bash
export AWS_PROFILE=sela
eksctl create cluster -f ./cluster/cluster.yaml