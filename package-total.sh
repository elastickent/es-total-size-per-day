#!/bin/bash

echo "@timestamp, bytes" > total.csv && cat es_total_change-* >> total.csv