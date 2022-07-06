// simulate a REST callout for testing async processing

@RestResource(urlMapping='/Translate/')
global class SimulatedTranslator {
    
    @HttpPost
    global static string doPost(String source){
        return (source + ' in Spanish...');
    }

    private class PostClass {
        String source;
    }

    public static String translate(String sourceText) {
        if (sourceText==null) return null;
        HTTPRequest req = new HTTPRequest();
        req.setEndpoint(URL.getOrgDomainUrl().toExternalForm() + '/services/apexrest/Translate/');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type', 'application-json');
        req.setMethod('POST');
        PostClass p = new PostClass();
        p.source = sourceText;
        req.setBody(JSON.serialize(p));
        HttpResponse result = new Http().send(req);
        return result.getBody();
    }

    public class MockTranslator implements HttpCalloutMock
	{
		public HTTPResponse respond(HTTPRequest req)
		{
			String requestBodyJSON = req.getBody();
			String requestBody = ((PostClass)JSON.deserialize(requestBodyJSON, postClass.class)).source;
			HttpResponse res = new HttpResponse();
			res.setHeader('Content-Type', 'text');
			res.setBody(requestBody + ' in Spanish');
			res.setStatusCode(200);
			return res;
		}
	}

}
