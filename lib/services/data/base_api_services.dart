abstract class BaseApiServices {
   Future<dynamic> getApi(String url,String? token);
   Future<dynamic> postApi(dynamic data,String url,String? token,{bool isJson} );
   Future<dynamic> putApi(dynamic data, String url, String? token, {bool isJson});
   Future<dynamic> patchApi(dynamic data, String url, String? token, {bool isJson});
    Future<dynamic> deleteApi(String url, String? token,dynamic? data);
}