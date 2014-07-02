/*

ring.c

This program uses blocking sends and receives to send a message around
a ring of processors. That is, processor 0 sends to processor 1, which
sends to processor 2, etc. The last processor returns the message to
processor 0. 

sol0@lehigh.edu
LUCC, 2004/10/08.

Sample output:

Mac OS X> lamboot -v bhosts 

LAM 7.1.1/MPI 2 C++/ROMIO - Indiana University

n-1<996> ssi:boot:base:linear: booting n0 (192.168.1.27)
n-1<996> ssi:boot:base:linear: finished
Mac OS X> mpicc -o ring ring.c -l mpi
Mac OS X> mpirun -np 4 ring
Process 0 on Dragonfly started.
Initial message is 'Hello World from process 0!'.
Process 1 on Dragonfly started.
Process 3 on Dragonfly started.
Process 2 on Dragonfly started.
Final mesage is 'Hello World from process 0! (1/Dragonfly) (2/Dragonfly) (3/Dragonfly)'.

*/

#include "mpi.h"
#include <stdio.h>

#define BUF_MAX 1024		/* maximum message size in chars */

void init( int argc, char *argv[] );
void ring();
void fini();

int  rank, size;
int  namelen;
char processor_name[ MPI_MAX_PROCESSOR_NAME ];

int main( int argc, char *argv[]) {

    init( argc, argv );
    ring();
    fini();

} /* end main */

void fini() {

    MPI_Finalize();
    exit( 0 );

} /* end fini */

void init( int argc, char *argv[] ) {
    /*

      Initialize MPI: fetch the total process count, our rank, and the
      name of the computer we are running on.

    */

    MPI_Init( &argc, &argv );
    MPI_Comm_size( MPI_COMM_WORLD, &size );
    MPI_Comm_rank( MPI_COMM_WORLD, &rank );
    MPI_Get_processor_name( processor_name, &namelen );

    printf( "Process %d on %s started.\n", rank, processor_name );

    /*

      At this point in time all MPI processes are running. Process
      zero is special: it's the head and tail of the message ring.
      That is, it sends the first message and receives the last
      message. All other processes receive then send.

     */

} /* end init */

void ring() {

  /*

    Process 0 starts the message passing. As other processes receive the
    message they sign it with their rank and processor name and pass it
    on the the next process in the ring.

  */

  int        count;			/* byte count of received data */
  char       imsg[ BUF_MAX + 1 ];	/* MPI_Recv buffer */
  char       msg[] = "Hello World from process 0!";
  int        next;			/* next     processor ordinal in ring */
  char       omsg[ BUF_MAX + 1 ];	/* MPI_Send buffer */
  int        prev;			/* previous processor ordinal in ring */
  MPI_Status stat[ sizeof( MPI_Status ) ];

  prev = ( rank - 1 + size ) % size;
  next = ( rank + 1 )        % size;

  if( rank == 0 ) {		/* initiate send, wait for last process */

    printf( "Initial message is '%s'.\n", msg );
    MPI_Send( msg, strlen( msg ), MPI_CHAR, next, 0, MPI_COMM_WORLD );
    MPI_Recv( imsg, BUF_MAX, MPI_CHAR, prev, 0, MPI_COMM_WORLD, stat );
    MPI_Get_count( stat, MPI_CHAR, &count );
    imsg[ count ] = '\0';
    printf( "Final mesage is '%s'.\n", imsg );

  } else {			/* receive message, foreward to next process */

    MPI_Recv( imsg, BUF_MAX, MPI_CHAR, prev, 0, MPI_COMM_WORLD, stat );
    MPI_Get_count( stat, MPI_CHAR, &count );
    imsg[ count ] = '\0';
    if( strlen( imsg) + 2 + 2 + 1 + strlen( processor_name ) + 1 < BUF_MAX ) {	/* Assumption: rank <= 99 */
      sprintf( omsg, "%s (%d/%s)", imsg, rank, processor_name );
    } else {
      strcpy( omsg, imsg );
    }
    MPI_Send( omsg, strlen( omsg ), MPI_CHAR, next, 0, MPI_COMM_WORLD );

  }

} /* end ring */
