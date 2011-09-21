# gl_tail.rb - OpenGL visualization of your server traffic
# Copyright 2007 Erlend Simonsen <mr@fudgie.org>
#
# Licensed under the GNU General Public License v2 (see LICENSE)
#

# Parser which handles nginx logs

$srlist = Hash.new
$srlist["dirtystory"]="dirtystory"
$srlist["dirtyjoke"]="dirtyjoke"
$srlist["read_message"]="read_message"
$srlist["message"]="message"
#$srlist["getbyid"]="queryimage"
$srlist["user_info_public"]="user_info_public"
$srlist["/user"]="user"
$srlist["diggjokeEn"]="diggjokeEn"
$srlist["diggjoke"]="diggjoke"
$srlist["rateme"]="rateme"
$srlist["needadvicecn"]="needadvicecn"
$srlist["myphotocn"]="myphotocn"
$srlist["funnypicsen"]="funnypicsen"
$srlist["horoscopecn"]="horoscopecn"
$srlist["blondejokes"]="blondejokes"
$srlist["friends"]="friends"
$srlist["littlejohnny"]="littlejohnny"
$srlist["funnypicscn"]="funnypicscn"



class NginxParser < Parser

  def parse( line )
    #10.28.53.4 - - [20/Sep/2011:01:12:09 -0500] "GET /comments/kmpf/.json?limit=1000&sort=top HTTP/1.0" 200 1958 "-" "Reddit_Joke/1.9 (iPhone; iPhone OS 4.2.1; zh-Hans; iPhone1,2; 156762c18a12d32085a974eb83784ff67417f7c1; 0; JB_0; AS_0)" 211.151.67.116
    #_, remote_addr, remote_user, status, request, size, referrer, http_user_agent, http_x_forwarded_for = /^([^\s]+) - ([^\s]+) \[.*\] (\d+) \"(.+)\" (\d+) \"(.*)\" \"([^\"]*)\" \"(.*)\"/.match(line).to_a

    #/^([^\s]+) - - \[.*\] \"([^"]+)\" ([^\s]+) ([^\s]+) "-" \"([^"]+)\" ([^\s]+)/.match(line).to_a
    _,remote_addr,request,status,size,http_user_agent,http_x_forward_for = /^([^\s]+) - - \[.*\] \"([^"]+)\" ([^\s]+) ([^\s]+) "-" \"([^"]+)\" ([^\s]+)/.match(line).to_a    
    #puts "request", remote_addr
    #puts request
    referrer = nil
    if request
      _, referrer_host, referrer_url = /^http[s]?:\/\/([^\/]+)(\/.*)/.match(referrer).to_a if referrer
      method, full_url, _ = request.split(' ')
      url, parameters = full_url.split('?')

      #add_activity(:block => 'sites', :name => server.name, :size => size.to_i)
      add_activity(:block => 'urls', :name => url)
      #add_activity(:block => 'users', :name => remote_addr, :size => size.to_i)
      add_activity(:block => 'referrers', :name => referrer) unless (referrer_host.nil? || referrer_host.include?(server.name) || referrer_host.include?(server.host) || referrer == '-')
      add_activity(:block => 'user agents', :name => http_user_agent, :type => 3) unless http_user_agent.nil?

      if( url.include?('.gif') || url.include?('.jpg') || url.include?('.png') || url.include?('.ico'))
        type = 'image'
      elsif url.include?('.css')
        type = 'css'
      elsif url.include?('comments')
        type = 'comments'
      elsif url.include?('.swf')
        type = 'flash'
      elsif( url.include?('.avi') || url.include?('.ogm') || url.include?('.flv') || url.include?('.mpg') )
        type = 'movie'
      elsif( url.include?('.mp3') || url.include?('.wav') || url.include?('.fla') || url.include?('.aac') || url.include?('.ogg'))
        type = 'music'
      else
        type = 'otherpage'
        $srlist.each do|name,value|
          if url.include?(name)
            type = value
          end
        end
        if type == 'otherpage'
          #puts url
        end
      end

      add_activity(:block => 'content', :name => type)  if type != 'otherpage'
      add_activity(:block => 'status', :name => status, :type => 3)

      add_event(:block => 'info', :name => "Logins", :message => "Login...", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/login')
      add_event(:block => 'info', :name => "Registration", :message => "Register", :update_stats => true, :color => [1.5, 0.0, 0.0, 1.0]) if method == "POST" && url.include?('/register')
      add_event(:block => 'info', :name => "Posts", :message => "Post", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/submit')
      add_event(:block => 'info', :name => "Comments", :message => "Comment", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/comment')
      add_event(:block => 'info', :name => "Vote", :message => "Vote", :update_stats => true, :color => [1.5, 1.0, 0.5, 1.0]) if method == "POST" && url.include?('/vote')
    end
  end
end
