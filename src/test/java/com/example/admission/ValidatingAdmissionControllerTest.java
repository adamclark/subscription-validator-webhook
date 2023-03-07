package com.example.admission;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.containsString;

import java.io.InputStream;

import javax.ws.rs.core.MediaType;

@QuarkusTest
public class ValidatingAdmissionControllerTest {
    
    InputStream allowedAMQReview = getClass().getClassLoader().getResourceAsStream("amq-allowed-review.json");
    InputStream disallowedAMQReview = getClass().getClassLoader().getResourceAsStream("amq-disallowed-review.json");
    InputStream allowedJDGReview = getClass().getClassLoader().getResourceAsStream("jdg-allowed-review.json");
    InputStream disallowedJDGReview = getClass().getClassLoader().getResourceAsStream("jdg-disallowed-review.json");

    @Test
    public void allowedAMQ() {
        given()
            .when()
            .body(allowedAMQReview)
            .contentType(MediaType.APPLICATION_JSON)
            .post("/validate")
            .then()
            .statusCode(200)
            .body(containsString("\"allowed\":true"));
    }
    
    @Test
    public void disallowedAMQ() {
        given()
            .when()
            .body(disallowedAMQReview)
            .contentType(MediaType.APPLICATION_JSON)
            .post("/validate")
            .then()
            .statusCode(200)
            .body(containsString("\"allowed\":false"));
    }
    @Test
    public void allowedJDG() {
        given()
            .when()
            .body(allowedJDGReview)
            .contentType(MediaType.APPLICATION_JSON)
            .post("/validate")
            .then()
            .statusCode(200)
            .body(containsString("\"allowed\":true"));
    }
    
    @Test
    public void disallowedJDG() {
        given()
            .when()
            .body(disallowedJDGReview)
            .contentType(MediaType.APPLICATION_JSON)
            .post("/validate")
            .then()
            .statusCode(200)
            .body(containsString("\"allowed\":false"));
    }
}