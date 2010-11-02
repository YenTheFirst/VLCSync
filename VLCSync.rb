#open vlc with --extraintf rc --rc-host

require 'socket'
class VLCconn
	attr_accessor :socket,:state,:time
	def initialize(state=3,time=0,socket=nil)
		@socket=socket
		@state=state
		@time=time
	end
	def to_io
		socket
	end
	def to_s
		"(#{self.class.name}: #{socket.peeraddr[2]}:#{socket.peeraddr[1]})"
	end
end

all_conns=[]
count=1

argument_connections = 	ARGV.select {|param| param.match /[-\.\w]+:\d+/}
if argument_connections.empty?
	puts "Input the initial connections:"
	puts "(enter an empty line to finish)"

	loop do
		print "connection #{count} address: "
		addr=$stdin.gets.strip
		break if addr.empty?
		print "connection #{count} port: "
		port=$stdin.gets.strip
		break if port.empty?

		all_conns << VLCconn.new(3,0,TCPSocket.new(addr,port))
		count+=1
	end
else
	all_conns = argument_connections.map {|param| VLCconn.new(3,0,TCPSocket.new(*param.split(':')))}
		#assumes param is host:port
end


if ARGV.include? "-v" or ARGV.include? "--verbose"
	def say(message)
		STDOUT.puts message
	end
else
	def say(message)
	end
end

while all_conns.length > 0
#	a=Kernel.select(all_conns+[$stdin],nil,nil,10)
	a=Kernel.select(all_conns,nil,nil,10)
	if a.nil?
		#if nothing happened, check to make sure everyone's sync'd up. we'll use the first connection as the reference point
		say "nothing for this 10 seconds"
		all_conns[0].to_io.print "get_time\n"
	else
		if a[0].include? $stdin
			#add command-line stuff here
			print "got '#{$stdin.gets}' from stdin\n"
			a[0].delete $stdin
		end
		a[0].each do |conn|
			case b=conn.to_io.gets.strip
			when /status change: \( play state: (\d+)/
				#this connection did a play/pause state change. record the new state, and send messages to all the other connections, as neccesary, to bring them up to date.
				conn.state=$1
				say "#{conn}: #{b}"
				if a[0].length==1
					(all_conns.select {|x| x.state!=conn.state}).each {|y| y.to_io.print "pause\n"}
					conn.to_io.print "get_time\n"
				end
			when /^(\d+)/
				#this connection told us the time, in seconds. update our record. if anyone is woefully out of sync, bring them in line
				conn.time=$1.to_i
				say "#{conn}: time @ #{$1}"
				if a[0].length==1
					(all_conns.select {|x| (x.time-conn.time).abs > 5}).each {|y| y.to_io.print "seek #{conn.time}\n"}
				end
			when /quit/
				say "#{conn}: closing connection\n"
				conn.to_io.close
				all_conns.delete(conn)
			when nil
				say "#{conn}: connection died"
				all_conns.delete(conn)
			else
				say "#{conn}: unknown message: '#{b}'\n"
			end
		end
	end
end

puts "all connections closed, exiting"
