#!/bin/sh

# - IB UD options using UCM provider, large scale settings (Xeon)
export DAPL_UCM_REP_TIME=2000   #/*  REQUEST timer, waiting on REPLY, msecs, default = 800 */
export DAPL_UCM_RTU_TIME=1000   #/* REPLY timer, waiting for RTU in msecs, default=400 */
export DAPL_UCM_RETRY=7       	#/* REQUEST & REPLY retries, default = 7 */
export DAPL_UCM_QP_SIZE=1000	#/* CM req/reply work queue size, default = 500 entries */
export DAPL_UCM_CQ_SIZE=1000	#/* CM req/reply completion queue size, default = 500 entries */
export DAPL_UCM_TX_BURST=100	#/* CM signal rate on send messages */

# - IB RC options using UCM provider, large scale settings (Xeon)
export DAPL_MAX_INLINE=64	#/*  IB RC inline optimization, best small msg latency, def=64 */
export DAPL_ACK_RETRY=7         #/*  IB RC Ack retry count, default 7 */
export DAPL_ACK_TIMER=20       	#/* IB RC Ack retry timer, default 20 */
				# IB formula:: 5 bits, 4.096us*2^ack_timer. 16== 268ms, 20==4.2s
#- IB RC options using SCM provider

#export DAPL_SCM_NETDEV=smic001p-mic0	#/* default is first non-loopback netdev,  use mic0 with KNCs */

#Other  IB settings:
export DAPL_IB_MTU=2048		#/* IB MTU size, default = 2048 */
export DAPL_RNR_TIMER=12	#/* 5 bits, 12 =.64ms, 28 =163ms, 31 =491ms */
export DAPL_RNR_RETRY=7		#/* 3 bits, 7 == infinite */
export DAPL_IB_PKEY= 0		#/* override IB partition key, default is pkey index 0 */
export DAPL_IB_SL=0		#/* override IB Sevice level, default = 0 */

#- Other options:
export DAPL_WR_MAX=500 		#/* used to reduce max qp depth on all IB providers, default = dev attributes */

#Debug logging and Counter settings ( --enable-counters, v2.0.35+)

export DAPL_DBG_SYS_MEM=10	#/* threshold for low sys memory warning, def = 10 percent */
export DAPL_DBG_TYPE=0x0000003 	#/* set log, monitor, and error checking, default = warnings and errors */


  server="smic001"
  parameter0="-i 100 client SR 409600 1 server SR 409600 1"
  parameter1="-i 100 RW 409600 2"
  clienttest0="dapltest -T T -D ofa-v2-mlx4_0-1s -s $server $parameter0"
  clienttest1="dapltest -T P -D ofa-v2-mlx4_0-1s -s $server $parameter1"

  $clienttest0

  $clienttest1

