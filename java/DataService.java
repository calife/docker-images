    import javax.xml.transform.Source;
    import javax.xml.transform.stream.StreamSource;
    import javax.xml.ws.Endpoint;
    import javax.xml.ws.Provider;
    import javax.xml.ws.WebServiceProvider;
    import javax.xml.ws.http.HTTPBinding;
    import java.io.StringReader;
    @WebServiceProvider
    public class DataService implements Provider<Source> {
        public static int RANDOM_ID = (int) (Math.random() * 5000);
        public static String SERVER_URL = "http://0.0.0.0:9080/";
        public Source invoke(Source request) {
            return new StreamSource(new StringReader("<result><name>hello</name><id>" + RANDOM_ID + "</id></result>"));
        }
        public static void main(String[] args) throws InterruptedException {
            Endpoint.create(HTTPBinding.HTTP_BINDING, new DataService()).publish(SERVER_URL);
            Thread.sleep(Long.MAX_VALUE);
        }
    }
