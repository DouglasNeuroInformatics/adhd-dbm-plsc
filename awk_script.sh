#!/bin/bash

awk -F'\t' -v OFS='\t' '$2 == "1" {$2 = "ADHD"} 1' ./"$1" > tmp.tsv && mv tmp.tsv "$1"
awk -F'\t' -v OFS='\t' '$2 == "2" {$2 = "Control"} 1' ./"$1" > tmp.tsv && mv tmp.tsv "$1"
awk -F'\t' -v OFS='\t' '$4 == "1" {$4 = "Female"} 1' ./"$1" > tmp.tsv && mv tmp.tsv "$1"
awk -F'\t' -v OFS='\t' '$4 == "2" {$4 = "Male"} 1' ./"$1" > tmp.tsv && mv tmp.tsv "$1"
