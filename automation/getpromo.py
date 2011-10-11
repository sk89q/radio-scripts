#!/usr/bin/env python
#
# Copyright (c) 2005-2011 sk89q <http://www.sk89q.com>
#

import glob
import random

files = glob.glob("/home/radio/intros/DU_promo.mp3")
print random.choice(files)