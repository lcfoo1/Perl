use threads;    

sub start_thread
{
        print "Thread started\n";
}    

my $thread  = threads->create("start_thread","argument");
my $thread2 = $thread->create(sub { print "I am a thread"},"argument");
#my $thread3 = async { foreach (@files) { ... } };    
$thread->join();
$thread->detach();    
$thread = threads->self();
$thread = threads->object( $tid );   
$thread->tid();
threads->tid();
threads->self->tid();    
threads->yield();    
threads->list();