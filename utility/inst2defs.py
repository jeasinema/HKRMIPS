#!/usr/bin/env python
# -*- coding:UTF-8 -*-
# -----------------------------------------------------
# File Name : inst2defs.py
# Purpose :
# Creation Date : 19-10-2016
# Last Modified : Wed Oct 19 12:53:33 2016
# Created By : Jeasine Ma [jeasinema[at]gmail[dot]com]
# -----------------------------------------------------

import sys
import os

class Inst2Defs:
    
    def __init__(self):
        if (len(sys.argv) != 3):
            print u"need 2 arguments, but provide " + str(len(sys.argv))
            return False;
        if not os.path.isfile(sys.argv[1]):
            print u"No such inst set: " + sys.argv[1]
            return False
        self.fr = open(sys.argv[1], "r")
        self.fw = open(sys.argv[2], "w+")
        if self.fr is None or self.fw is None:
            print u"file open error"
            return False

    def inst2def(self, *args, **kwargs):
        index = 0
        for i in self.fr.readlines():
            self.fw.write("`define " + "INST_" + i[:-1].upper() + " 8'd" + str(index))
            self.fw.write("\n")
            index = index + 1
        self.fw.close()
        self.fr.close()

if __name__ == "__main__":
    m = Inst2Defs()
    m.inst2def()
