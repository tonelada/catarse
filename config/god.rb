#
# Catarse God Config
#
# 2011  by nofxx
#
# run with: sudo god -c /path/to/this.file
#

# Conf
APP_ROOT = "/srv/mutitude"
APP_USER = "deployer"

#OPT = YAML.load(File.read(APP_ROOT + "/config/daemons.yml"))[SELF_ENV]
OPT = {
  :db  =>  ['postgres'],
  :web =>  ['nginx', 'unicorn'],
  :daemon => []
}

# Notify
#
God::Contacts::Email.defaults do |d|
  d.from_email = "god@xxxxx.com"
  d.from_name = "God [app]"

  d.delivery_method = :smtp
  d.server_host = "mail.xxx.com"
  d.server_port = 25
  d.server_auth = :plain
  d.server_domain = "xxxxxx.com"
  d.server_user = "x@xxxxxx.com"
  d.server_password = "xxxxxxxx"
end

God.contact(:email) do |c|
  c.name     = "nofxx"
  c.to_email = "x@xxxxx.com"
end

ARCH = File.exists?("/etc/arch-release")
RC   = ARCH ? "/etc/rc.d/" : "/sbin/service"
SELF_ENV = ARGV[0] || "production"
WEBAPP = {
  "production"  => { :sudo => true, :uid => APP_USER, :gid => APP_USER, :path => APP_ROOT},
  "development" => { :sudo => false, :uid => `whoami`.chomp, :gid => `groups`.split(/\s/)[0], :path => APP_ROOT}
}[SELF_ENV]


# GodWeb
#
begin
  require 'god_web' rescue nil
  GodWeb.watch(:config => '/etc/god_web.yml') if defined?("GodWeb")
rescue LoadError => e
  puts "Starting w/o GodWeb"
end

# Generic Monitor
#
def generic_monitoring(w, options = {})
  w.interval = 30.seconds # default
  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 10.seconds
      c.running = false
    end
  end

  w.restart_if do |restart|
    restart.condition(:memory_usage) do |c|
      c.notify = {:contacts => ["nofxx", "developers"], :priority => 1, :category => "mem"}
      c.above = options[:memory_limit]
      c.times = [3, 5] # 3 out of 5 intervals
    end

    restart.condition(:cpu_usage) do |c|
      c.notify = {:contacts => ["nofxx", "developers"], :priority => 1, :category => "cpu"}
      c.above = options[:cpu_limit]
      c.times = 5
    end
  end

  w.lifecycle do |on|
    on.condition(:flapping) do |c|
      c.to_state = [:start, :restart]
      c.times = 5
      c.within = 5.minute
      c.transition = :unmonitored
      c.retry_in = 10.minutes
      c.retry_times = 5
      c.retry_within = 2.hours
    end
  end
end

# Nginx
#
if OPT[:web].include? "nginx"
  puts "Web => nginx"
  God.watch do |w|
    w.name = "nginx"
    w.uid = "root"
    w.gid = "root"
    w.group = "webapp"
    w.start = "#{RC}nginx start"
    w.stop  = "#{RC}nginx stop"
    w.restart = "#{RC}nginx restart"
    w.start_grace = 10.seconds
    w.restart_grace = 10.seconds
    w.pid_file = File.join("/var/run/nginx.pid")
    w.behavior(:clean_pid_file)
    generic_monitoring(w, :cpu_limit => 80.percent, :memory_limit => 800.megabytes)
  end
end

# Unicorn
#
if OPT[:web].include? "unicorn"
  puts "Unicorn ..}"
  God.watch do |w|
    w.name = "unicorn"
    w.group = "servers"
    if WEBAPP[:sudo]
      w.uid = WEBAPP[:uid]
      w.gid = WEBAPP[:gid]
    end
    w.pid_file = "#{WEBAPP[:path]}/tmp/pids/unicorn.pid"
    #w.pid_file = File.join(WEBAPP[:path], "tmp", "pids", "unicorn.pid")
    w.start = "cd #{WEBAPP[:path]} && bundle exec unicorn -c #{WEBAPP[:path]}/config/unicorn.rb -E #{SELF_ENV} -D"
    w.stop = "kill -QUIT #{WEBAPP[:path]}/tmp/pids/unicorn.pid"
    w.restart = "kill -USR2 `cat #{WEBAPP[:path]}/tmp/pids/unicorn.pid`"
    w.start_grace = 20.seconds
    w.restart_grace = 20.seconds
    w.behavior :clean_pid_file
    generic_monitoring(w, :cpu_limit => 80.percent, :memory_limit => 800.megabytes)
  end
end

# PostgreSQL
#
if OPT[:db].include? "postgresql"
  puts "DB => postgresql"
  God.watch do |w|
    w.name = "postgresql"
    w.uid = "root"
    w.gid = "root"
    w.group = "db"
    w.start = "#{RC}postgresql start" #w.start = "service postgresql start"
    w.stop = "#{RC}postgresql stop"   #w.stop = "service postgresql stop"
    w.restart = "#{RC}postgresql restart"
    w.start_grace = 20.seconds
    w.restart_grace = 20.seconds
    w.pid_file = ARCH ? "/var/lib/postgresql/postmaster.pid" : "/var/run/postmaster.5432.pid"
    w.behavior(:clean_pid_file)
    generic_monitoring(w, :cpu_limit => 80.percent, :memory_limit => 800.megabytes)
  end
end
