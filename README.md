# Repeatable performance test
The project contains a set of Bash scripts to setup Gatling on remote hosts and to retrieve the results to create a global report.
This guide describe how to set up the nodes and run the Gatling tests.


# Test environment setup
The test is composed of a Logstash node that executes a simple HTTP input pipeline and a couple of other loader nodes.
The loader nodes execute a predefined Gatling scenario to make requests at a steady rate against Logstash node.


## Logstash node configuration
Install Logstash fromo tar.gz and configure it for monitoring:
- configure Logstash to be monitored by Elastic stack, using the the Agent and the Logstash integration. This permit to have
 some dashboards to monitor events per seconds, latency, memory consumption and CPU usage. Refer to https://www.elastic.co/guide/en/logstash/current/monitoring-with-elastic-agent.html .
- enable JMX monitoring of the Logstash instance. This is usefull to have more fine grained metrics readable from VisualVM tool (https://visualvm.github.io/download.html).
- open an SSH tunnel to remote access the JMX ports. 


### Enable JMX monitoring of the Logstash instance

Edit the `config/jvm.options` to contain:
```
-Dcom.sun.management.jmxremote
-Dcom.sun.management.jmxremote=true
-Dcom.sun.management.jmxremote.port=5555
-Dcom.sun.management.jmxremote.rmi.port=5556
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.ssl=false

-Djava.rmi.server.hostname=localhost
```

### Open an SSH tunnel to remote access the JMX ports.
Open an SSH tunnel to the two interested ports (5555 and 5556), supposing the user `testuser` connecting to remote Logstash host `216.58.205.35`

```sh
ssh -L 5555:127.0.0.1:5555 -L 5556:127.0.0.1:5556 testuser@216.58.205.35
```

Discussed in https://dresselhaus.biz/connect-java-visualvm-or-jconsole-via-ssh-tunnel/


### Configure Logstash pipeline and run

Use the following definition of a simple pipeline that just respond to HTTP and drop all events.

```ruby
input {
  http {
    response_headers => {"Content-Type" => "application/json"}
    ecs_compatibility => disabled

  }
}

filter {
  ruby {
    init => "Thread.new { loop { logger.info 'Direct mem: ' + Java::io.netty.buffer.ByteBufAllocator::DEFAULT.metric.used_direct_memory.to_s + ' pinned: ' + Java::io.netty.buffer.ByteBufAllocator::DEFAULT.pinned_direct_memory.to_s + ' - Heap mem: ' + Java::io.netty.buffer.ByteBufAllocator::DEFAULT.metric.used_heap_memory.to_s + ' pinned: ' + Java::io.netty.buffer.ByteBufAllocator::DEFAULT.pinned_heap_memory.to_s; sleep 5 } }"
    code => ""
  }
}

output {
  sink {}
}
```

Run it with Logstash
```
bin/logstash -f /path/to/test_pipeline.conf
```

Connect with VisualVM creating a local connection to `127.0.0.1:5555` and check that monitoring data flow into the monitoring cluster.

## Gatling loader nodes configuration
Open an SSH on each Gatling loader host, clone this reposiory, setup and run the test.

### Clone this repository
```sh
git clone https://github.com/andsel/gatling_test.git
```


### Setup Gatling test
Edit the `BasicSimulation.java` `baseUrl("http://10.154.0.14:8080")` to point to the Logstash host. Then executes the stup, which copies this file in the proper location inside local Gatling installation.
```sh
> cd gatling_test
gatling_test> ./setup.sh
```


### Run the test
To run the simulation with Gatling:
```sh
gatling_test> test_run/gatling-charts-highcharts-bundle-3.10.5/bin/gatling.sh -nr -rm local -s BasicSimulation
```

## Report creation
Once the simulation has terminated on all nodes, download the log files and create the report. To do this you need to clone the `gatling_test` on your host.
Edit `retrieve_data.sh` to properly fill `HOSTS` eenvironment variable with the list of the Gatling loader hosts and `USER_NAME`.
Then retrieve the data:
```sh
./retrieve_data.sh
```

Then execute the report gerneration:
```sh
gatling_test> ../gatling_test/test_run/gatling-charts-highcharts-bundle-3.10.5/bin/gatling.sh -ro reports
```