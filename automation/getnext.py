#!/usr/bin/env python
#
# Copyright (c) 2005-2011 sk89q <http://www.sk89q.com>
#

import os
import os.path
import re
import random
import sys

src_dir = '/home/radio/music/main/'

# NOTE! This song selection algorithm MAY VIOLATE COPYRIGHT / LICENSING LAWS
# WITHIN YOUR COUNTRY!

pool = []
r = re.compile("\\.(?:mp3|ogg)$", re.I);
for root, dirs, files in os.walk(src_dir):
    for file in files:
        if r.search(file):
            pool.append(os.path.join(root, file))
    if '.__ignore__' in dirs:
        dirs.remove('.__ignore__')
print random.choice(pool)