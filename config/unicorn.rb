#
# Catarse / 512Mb Vhost unicorn config
#
# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.
worker_processes 3 # 4
preload_app true

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory "/srv/mutitude"

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
listen "/tmp/mutitude.socket", :backlog => 1024

# nuke workers after 30 seconds instead of 60 seconds (the default)
timeout 30

# feel free to point this anywhere accessible on the filesystem
user 'deployer', 'deployer'
shared_path = "/srv/mutitude"
pid "#{shared_path}/tmp/pids/unicorn.pid"
stderr_path "#{shared_path}/log/unicorn.stderr.log"
stdout_path "#{shared_path}/log/unicorn.stdout.log"
