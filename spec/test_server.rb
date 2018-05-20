# encoding: utf-8
require "socket"

class TestServer

  PORT = 5678
  CRLF = "\r\n"
  RESPONSE_200 = "HTTP/1.1 200 OK#{CRLF}" +
                 "Content-Type: text/plain#{CRLF}" +
                 "Content-Length: 0#{CRLF}" +
                 "Connection: close#{CRLF}" +
                 "#{CRLF}"

  RESPONSE_429 = "HTTP/1.1 429 Too Many Requests#{CRLF}" +
                 "Content-Type: text/plain#{CRLF}" +
                 "Retry-After: 3600#{CRLF}" +
                 "#{CRLF}"
  
  attr_reader :queue
  attr_writer :response

  def initialize(response = RESPONSE_200)
    @requests = Queue.new()
    @response = response
    @server = TCPServer.new PORT
  end # def initialize

  def start()
    @thread = Thread.new { 
      while session = @server.accept
        request = session.gets
        @requests << request
        session.print @response
        session.close
      end
    }
    @thread
  end # def start

  def stop()
    @thread.kill()
    @thread.join()
  end # def stop

  def drain()
    @requests.size.times.map { @requests.deq() }
  end

end # class
