@isTest 
private class WeatherControllerTest {
    
    private class WeatherAPIMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            // Verify the request
            System.assert(req.getEndpoint().contains('api.weatherapi.com'));
            System.assertEquals('GET', req.getMethod());
            
            // Create mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody(getMockWeatherResponse());
            return res;
        }
    }
    
    private class WeatherAPIMock400 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setStatus('Bad Request');
            res.setBody('{"error":{"code":1006,"message":"No matching location found."}}');
            return res;
        }
    }

    private class WeatherAPIMock401 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(401);
            res.setStatus('Unauthorized');
            res.setBody('{"error":{"code":2006,"message":"API key is invalid."}}');
            return res;
        }
    }
    
    private class WeatherAPIMockTimeout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new System.CalloutException('Read timed out');
        }
    }

    @isTest
    static void testGetWeatherSuccess() {
        Test.setMock(HttpCalloutMock.class, new WeatherAPIMockSuccess());
        
        Test.startTest();
        WeatherController.WeatherData result = WeatherController.getWeather('London');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Weather data should be returned');
        System.assertEquals('London', result.city);
        System.assertEquals('United Kingdom', result.country);
        System.assertEquals(15.0, result.temperatureC);
        System.assertEquals(59.0, result.temperatureF);
        System.assertEquals('Partly cloudy', result.condition);
        System.assertNotEquals(null, result.iconUrl);
        System.assertEquals(72, result.humidity);
    }

    @isTest
    static void testGetWeatherEmptyCity() {
        Test.startTest();
        try {
            WeatherController.getWeather('');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('City name is required'));
        }
        Test.stopTest();
    }

    @isTest
    static void testGetWeatherNullCity() {
        Test.startTest();
        try {
            WeatherController.getWeather(null);
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('City name is required'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetWeatherCityNotFound() {
        Test.setMock(HttpCalloutMock.class, new WeatherAPIMock400());
        
        Test.startTest();
        try {
            WeatherController.getWeather('InvalidCityXYZ123');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('City not found'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetWeatherInvalidApiKey() {
        Test.setMock(HttpCalloutMock.class, new WeatherAPIMock401());
        
        Test.startTest();
        try {
            WeatherController.getWeather('London');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid API key'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGetWeatherTimeout() {
        Test.setMock(HttpCalloutMock.class, new WeatherAPIMockTimeout());
        
        Test.startTest();
        try {
            WeatherController.getWeather('London');
            System.assert(false, 'Should have thrown exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unable to connect'));
        }
        Test.stopTest();
    }
    
    private static String getMockWeatherResponse() {
        return '{"location":{"name":"London","region":"City of London, Greater London","country":"United Kingdom","lat":51.52,"lon":-0.11,"tz_id":"Europe/London","localtime_epoch":1706800000,"localtime":"2024-02-01 12:00"},"current":{"last_updated_epoch":1706799600,"last_updated":"2024-02-01 11:45","temp_c":15.0,"temp_f":59.0,"is_day":1,"condition":{"text":"Partly cloudy","icon":"//cdn.weatherapi.com/weather/64x64/day/116.png","code":1003},"wind_mph":8.1,"wind_kph":13.0,"wind_degree":220,"wind_dir":"SW","pressure_mb":1013.0,"pressure_in":29.91,"precip_mm":0.0,"precip_in":0.0,"humidity":72,"cloud":75,"feelslike_c":14.2,"feelslike_f":57.6,"vis_km":10.0,"vis_miles":6.0,"uv":4.0,"gust_mph":10.5,"gust_kph":16.9}}';
    }
}