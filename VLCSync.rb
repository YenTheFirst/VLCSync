#open vlc with --extraintf rc --rc-host

require 'socket'
class VLCconn
	attr_accessor :socket,:state,:time
	def to_io
		socket
	end
end

print "initial connections: \n"
all_conns=[]
count=1
loop do
	print "connection #{count} address: "
	addr=$stdin.gets.strip
	break if addr.empty?
	print "connection #{count} port: "
	port=$stdin.gets.strip
	break if port.empty?

	temp=VLCconn.new
	temp.socket=TCPSocket.new(addr,port)
	temp.state=3
	temp.time=0
	all_conns << temp
	count+=1
end
print "all_conns = #{all_conns.length}\n"

while all_conns.length > 0
#	a=Kernel.select(all_conns+[$stdin],nil,nil,10)
	a=Kernel.select([all_conns[0]],nil,nil,10)
	if a.nil?
		print "nothing for this 10 seconds\n"
		#all_conns[0].to_io.print "get_time\n"
	else
		if a[0].include? $stdin
			#add command-line stuff here
			print "got '#{$stdin.gets}' from stdin\n"
			a[0].delete $stdin
		end
		a[0].each do |conn|
			case b=conn.to_io.gets
			when /status change.*(\d+)/
				conn.state=$1
				print "status_change #{$1}\n"
				if a[0].length==1
					(all_conns.select {|x| x.state!=conn.state}).each {|y| y.to_io.print "pause\n"}
					conn.to_io.print "get_time\n"
				end
			when /^(\d+)/
				conn.time=$1.to_i
				print "time @ #{$1}\n"
				if a[0].length==1
					(all_conns.select {|x| (x.time-conn.time).abs > 5}).each {|y| y.to_io.print "seek #{conn.time}\n"}
				end
			when /quit/
				print "closing connection\n"
				conn.to_io.close
				all_conns.delete(conn)
			when nil
				puts "connection died"
				all_conns.delete(conn)
			else
				print "unknown '#{b}'\n"
			end
		end
	end
end
