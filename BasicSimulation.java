import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;

import java.time.Duration;

public class BasicSimulation extends Simulation {

    // Add the HttpProtocolBuilder:
    HttpProtocolBuilder httpProtocol = http.baseUrl("http://10.154.0.14:8080")
            .acceptHeader("application/json")
            .contentTypeHeader("application/json")
            .shareConnections();


    // Add the ScenarioBuilder:
    ScenarioBuilder myFirstScenario = scenario("Logstash POST Scenario")
            .exec(http("Submit event request")
                    .post("/")
//                    .body(RawFileBody("/Users/andrea/workspace/performance_test_with_gatling/payload_1k.json"))
                    .body(RawFileBody("payload_1k.json"))
                    .header("keep-alive", "150")
                    //.body(StringBody("{\"id1\":\"0000000000\" }")).asJson()
                    .check(status().is(200)));

    // Add the setUp block:
    {
        setUp(
                //myFirstScenario.injectOpen(constantUsersPerSec(2).during(60))
                myFirstScenario.injectClosed(
//                        constantUsersPerSec(700).during(5*60)
                        constantConcurrentUsers(10).during(Duration.ofMinutes(5))
                )
        ).throttle(reachRps(12000).in(Duration./*ofSeconds(10)*/ofMinutes(1)),
                holdFor(Duration.ofMinutes(10))/*,
                   reachRps(300).in(Duration.ofSeconds(10)),
                   holdFor(Duration.ofMinutes(5))*/
        ).protocols(httpProtocol);

//        setUp(
//                //myFirstScenario.injectOpen(constantUsersPerSec(2).during(60))
//                myFirstScenario.injectOpen(
////                        constantUsersPerSec(700).during(5*60)
//                        constantUsersPerSec(1).during(Duration.ofMinutes(5))
//                )
//        ).throttle(reachRps(3000000).in(Duration.ofSeconds(10)),
//                   holdFor(Duration.ofMinutes(5))/*,
//                   reachRps(300).in(Duration.ofSeconds(10)),
//                   holdFor(Duration.ofMinutes(5))*/
//        ).protocols(httpProtocol);
    }
}