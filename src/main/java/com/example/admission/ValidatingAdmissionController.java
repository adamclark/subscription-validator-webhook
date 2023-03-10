package com.example.admission;

import java.util.HashMap;
import java.util.List;
import java.util.Optional;

import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

import org.eclipse.microprofile.config.ConfigProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.fabric8.kubernetes.api.model.GenericKubernetesResource;
import io.fabric8.kubernetes.api.model.StatusBuilder;
import io.fabric8.kubernetes.api.model.admission.v1.AdmissionResponseBuilder;
import io.fabric8.kubernetes.api.model.admission.v1.AdmissionReview;
import io.fabric8.kubernetes.api.model.admission.v1.AdmissionReviewBuilder;

@Path("/")
public class ValidatingAdmissionController {

    private static final Logger log = LoggerFactory.getLogger(ValidatingAdmissionController.class);

    @Path("/health")
    @GET
    public String health() {
        return "Healthy";
    }

    @Path("/validate")
    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    @Produces(MediaType.APPLICATION_JSON)
    public AdmissionReview validate(AdmissionReview review) {

        log.info("received admission review request: {}", review.getRequest());

        // Get details of the subscription being requested from the admission review request
        GenericKubernetesResource subscription = ((GenericKubernetesResource)review.getRequest().getObject());
        HashMap<String, Object> additionalProperties = (HashMap<String, Object>) subscription.getAdditionalProperties();
        HashMap<String, String> spec = (HashMap<String, String>) additionalProperties.get("spec");

        String operatorName = spec.get("name");
        String channel = spec.get("channel");
        String startingCSV = spec.get("startingCSV");

        log.info("operatorName: {}", operatorName);
        log.info("channel: {}", channel);
        log.info("startingCSV: {}", startingCSV);
        
        // Get the list of allowed channels for this operator (if present)
        Optional<List<String>> allowedChannels = ConfigProvider.getConfig().getOptionalValues(operatorName + ".allowed.channels", String.class);
        
        // Default to allowing the subscription to be created
        boolean allowed = true;
            
        // Disallow if there is a list of allowed channels for this operator but the requested channel has not been configured as allowed.
        if(allowedChannels.isPresent() && !allowedChannels.get().contains(channel)) {
            allowed = false;
        }
    
        if(allowed) {
            return new AdmissionReviewBuilder()
                .withResponse(new AdmissionResponseBuilder()
                    .withAllowed(true)
                    .withUid(review.getRequest().getUid())
                    .build())
                .build();
        } else {
            return new AdmissionReviewBuilder()
                .withResponse(new AdmissionResponseBuilder()
                    .withAllowed(false)
                    .withUid(review.getRequest().getUid())
                    .withStatus(new StatusBuilder()
                        .withMessage("Subscription denied")
                        .withReason("Subscription channel is not allowed")
                        .withCode(400)
                        .build())
                    .build())
                .build();
        }
    }
}