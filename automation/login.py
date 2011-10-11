#!/usr/bin/env python
#
# Copyright (c) 2005-2011 sk89q <http://www.sk89q.com>
#

import sys
from optparse import OptionParser
import MySQLdb
import time

def main():    
    parser = OptionParser("%prog harbor login")
    (options, args) = parser.parse_args()

    if len(args) < 2:
        parser.error("Not enough arguments")
    
    harbor, login = args
    login = login.split("|", 1)
    if len(login) < 2:
        parser.error("Invalid login argument")
    username, password = login
    
    conn = MySQLdb.connect(host="localhost",
                           user="root",
                           passwd="",
                           db="radio")
    
    # Look for a record
    cursor = conn.cursor()
    cursor.execute("""QUERY WENT HERE""", (username, password))
    row = cursor.fetchone()
    cursor.close()
    
    # No login
    if row == None:
        print "Failed to authenticate"
        sys.exit(1)
    
    print "Authenticated as %s (%s)" % (row[1], row[0])
    
    # Log login
    cursor = conn.cursor()
    cursor.execute("""INSERT INTO dj_logins
                      (mid, idname, harbor, time)
                      VALUES
                      (%s, %s, %s, %s)""", 
                   (row[0], row[2], harbor, time.strftime("%Y-%m-%d %H:%M:%S", time.gmtime())))
    cursor.close()
    
    sys.exit(0)

if __name__ == "__main__":
    main();