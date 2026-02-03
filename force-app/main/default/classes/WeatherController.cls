public with sharing class WeatherController {

    @AuraEnabled(cacheable=false)
    public static WeatherData getWeather(String city) {
 
        if (String.isBlank(city)) {
            throw new AuraHandledException('City name is required');
        }
        
        try {
            String apiKey = getApiKey();
            
            if (String.isBlank(apiKey)) {
                throw new AuraHandledException('Weather API key not configured. Please contact your administrator.');
            }
            
            String endpoint = 'https://api.weatherapi.com/v1/current.json';
            endpoint += '?key=' + apiKey;
            endpoint += '&q=' + EncodingUtil.urlEncode(city, 'UTF-8');
            endpoint += '&aqi=no'; 

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            request.setTimeout(10000); 
            
            HttpResponse response = http.send(request);
            

            if (response.getStatusCode() == 200) {
                return parseWeatherResponse(response.getBody(), city);
            } else if (response.getStatusCode() == 400) {
                throw new AuraHandledException('City not found. Please check the spelling.');
            } else if (response.getStatusCode() == 401) {
                throw new AuraHandledException('Invalid API key. Please contact your administrator.');
            } else {
                throw new AuraHandledException('Weather service returned error: ' + response.getStatus());
            }
            
        } catch (System.CalloutException e) {
            throw new AuraHandledException('Unable to connect to weather service. Please try again later.');
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            System.debug('Weather API Error: ' + e.getMessage());
            throw new AuraHandledException('An unexpected error occurred: ' + e.getMessage());
        }
    }
    
    private static String getApiKey() {
        try {
            Weather_API_Setting__mdt setting = [
                SELECT API_Key__c 
                FROM Weather_API_Setting__mdt 
                WHERE DeveloperName = 'Default' 
                LIMIT 1
            ];
            return setting.API_Key__c;
        } catch (Exception e) {
            System.debug('Failed to retrieve API key: ' + e.getMessage());
            return null;
        }
    }
    
    private static WeatherData parseWeatherResponse(String jsonResponse, String city) {
        try {
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            
            Map<String, Object> location = (Map<String, Object>) responseMap.get('location');
            
            Map<String, Object> current = (Map<String, Object>) responseMap.get('current');
            Map<String, Object> condition = (Map<String, Object>) current.get('condition');
            
            WeatherData weather = new WeatherData();
            weather.city = (String) location.get('name');
            weather.country = (String) location.get('country');
            weather.temperatureC = (Decimal) current.get('temp_c');
            weather.temperatureF = (Decimal) current.get('temp_f');
            weather.condition = (String) condition.get('text');
            weather.iconUrl = 'https:' + (String) condition.get('icon'); 
            weather.humidity = (Integer) current.get('humidity');
            weather.windKph = (Decimal) current.get('wind_kph');
            weather.windMph = (Decimal) current.get('wind_mph');
            weather.lastUpdated = (String) current.get('last_updated');
            
            return weather;
            
        } catch (Exception e) {
            System.debug('JSON Parsing Error: ' + e.getMessage());
            throw new AuraHandledException('Unable to parse weather data');
        }
    }
    
    public class WeatherData {
        @AuraEnabled public String city;
        @AuraEnabled public String country;
        @AuraEnabled public Decimal temperatureC;
        @AuraEnabled public Decimal temperatureF;
        @AuraEnabled public String condition;
        @AuraEnabled public String iconUrl;
        @AuraEnabled public Integer humidity;
        @AuraEnabled public Decimal windKph;
        @AuraEnabled public Decimal windMph;
        @AuraEnabled public String lastUpdated;
    }
}