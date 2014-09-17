#!/usr/bin/env python

import sys
import math
import getopt
import re
import copy
import time
import subprocess
import xml.dom
from xml.dom.minidom import parse, parseString


element_node='Node'	# Basic node of pbsnodes xml output

# Only for debugging: Arguments overwritten by input
args=['-s','status','-n','mike[001-130,210,343]',\
      '-u','foo1,foo2','-u','foo3','-f','file',\
      '-u','user','-j','jobid1,jobid2', '-j', 'jobid3']

# Options to be parsed
opts='-f:-u:-s:-j:-n:-h'

#----------------------------
# Compile useful re searches
#----------------------------
#
# For parsing name,state and status 
np_srch=   re.compile('(np=)([0-9]+)') #-Processors
gpus_srch= re.compile('(gpus=)([0-9]+)') #-GPUs
time_srch= re.compile('(rectime=)([0-9]+)') #-Recent Time
load_srch= re.compile('(loadave=)([0-9.]+)') #-Node Load
jobs_srch= re.compile('(jobs=)([0-9.a-z ]+)') #-Node Jobs
amem_srch= re.compile('(availmem=)([0-9]+)([a-zA-Z]b)') #-Avail Mem
pmem_srch= re.compile('(physmem=)([0-9]+)([a-zA-Z]b)') #-Phys Mem
tmem_srch= re.compile('(totmem=)([0-9]+)([a-zA-Z]b)') #-Total Mem
gpu_usrch= re.compile('gpu_utilization=([0-9]+%)')
gpu_msrch= re.compile('gpu_memory_utilization=([0-9]+%)')
# For parsing hostlist passed via '-n'
hname_srch      = re.compile('[a-zA-Z]+') # Hostname
htacc_srch      = re.compile('[a-zA-Z]+')
intvl_srch      = re.compile(':([0-9]+)') # Interval
solo_node_srch  = re.compile('[0-9]+')    # Single node
nodes_list_srch = re.compile('[0-9,-:]+') # Block of nodes
split_nodes_srch= re.compile('([0-9]+)-([0-9]+)') # Comma sep. block

helptext="""
+-------+
| Usage :
+-------+
                    
  python  -n host[001-020:2,101-120:3,202,430]
               Run pbsnodes on 001 though 003 at intervals of 2
               Run pbsnodes on 101 though 120 at intervals of 3
               and additionally on comma separated values 202,430

  python       Without arguments, it runs pbsnodes on all nodes

  python  -h   Will print help message and exit

"""
def help():
    print helptext

# +------------------------------------------------
# ! Scan nodes:
# !   -n host[001-100:10,113]
# !   will scan host001,host011,...,host091,host113
# +------------------------------------------------
def process_nodes(a):
  # +--------------------------------
  # ! Transforms hosts to a flat list
  # +--------------------------------
  m0=hname_srch.search(a)
  cluster=a[m0.start():m0.end()]
  m1=nodes_list_srch.search(a)
  nodelist=a[m1.start():m1.end()]
  b=[]
  if m1:
    for x in nodelist.split(','):
      m2=split_nodes_srch.search(x)
      if m2:
        begin=m2.groups()[0]
	end=m2.groups()[1] if m2.groups()[1] else begin
        m4=intvl_srch.search(x)
        #print begin,end,x[m4.start()+1:m4.end()]
        intvl=int(x[m4.start()+1:m4.end()]) if m4 else 1
        pow=int(math.log(int(begin),10))
        for y in range(int(begin) ,int(end)+1,intvl):
          pow=int(math.log(y,10))+1
          node=cluster+begin[0:len(begin)-pow]+str(y)
          b.insert(0,str(node))
      else:
        m3=solo_node_srch.search(x)
        #print 'solo',m3
        if m3:
          node=cluster+x[m3.start():m3.end()]
          b.insert(0,node)
  if b==[]:
    print "No useful nodes found with -n "
  # sys.exit()
  return b


#----------------------------
# Parse Input:  getopt
#----------------------------
#
if sys.argv:
  args=sys.argv[1:]

optlist,arglist=getopt.getopt(args,opts)
#print optlist
print "Options Supplied \n %s" %optlist

opts_dic={}

for o,a in optlist:
  if o=='-u':
    if o in opts_dic:
      opts_dic[o]+=a
    else:
      opts_dic[o]=[a]
    print "User   search %s" %a
  elif o=='-j':
    print "Jobid  search %s" %a
    if o in opts_dic:
      opts_dic[o]+=[a]
    else:
      opts_dic[o]=[a]
  elif o=='-n':
    b=process_nodes(a)
    if o in opts_dic:
      opts_dic[o]+=b
    else:
      opts_dic[o]=b
    #print "Scanning Nodes \n %s " %(opts_dic[o])
    #sys.exit()
  elif o=='-s':
    print "Status search %s" %a
    if o in opts_dic:
      opts_dic[o]+=[a]
    else:
      opts_dic[o]=[a]
  elif o=='-f':
    print "Using file    %s" %a
    if o in opts_dic:
      opts_dic[o]+=[a]
    else:
      opts_dic[o]=[a]
  elif o=='-h':
    help()
    sys.exit()
  else:
    print "Unrecognized option %s" %a

nodelist=[]
#print opts_dic['-n']
if '-n' in opts_dic:
  nodelist.extend(opts_dic['-n'])
elif '-u' in opts_dic:
  print "ToDo: Union of n and u"
elif '-j' in opts_dic:
  print "ToDo: Union of n, u and"


#-------------------------------------------
# System command to get output from pbsnodes
#-------------------------------------------  
#
print b
