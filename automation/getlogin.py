#!/usr/bin/env python
#
# Copyright (c) 2005-2011 sk89q <http://www.sk89q.com>
#

import sys
from optparse import OptionParser
import MySQLdb
import time

def main():    
    parser = OptionParser("%prog harbor")
    (options, args) = parser.parse_args()

    if len(args) < 1:
        parser.error("Not enough arguments")
    
    harbor, = args
    
    conn = MySQLdb.connect(host="localhost",
                           user="root",
                           passwd="",
                           db="radio")
    
    # Look for a record
    cursor = conn.cursor()
    cursor.execute("""SELECT idname
                      FROM dj_logins
                      WHERE harbor = %s
                      ORDER BY id DESC
                      LIMIT 1""", (harbor))
    row = cursor.fetchone()
    cursor.close()
    
    # No login
    if row == None:
        print "Unknown"
        sys.exit(0)
    
    print row[0]
    sys.exit(0)

if __name__ == "__main__":
    main();