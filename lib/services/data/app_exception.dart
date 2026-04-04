class AppExceptions implements Exception {
    
    final String? message;
    final String? prefix;
    AppExceptions([this.message,this.prefix]);

    @override
      String toString(){
        return '$prefix$message';
    }
}

class InternetException extends AppExceptions{
     InternetException([String? message]):super(message,'');
}


class RequestTimeOutException extends AppExceptions{
     RequestTimeOutException([String? message]):super(message,'');
}

class ServerException extends AppExceptions{
     ServerException([String? message]):super(message,'');
}

class InvalidUrlException extends AppExceptions{
     InvalidUrlException([String? message]):super(message,'');
}

class FetchDataException extends AppExceptions{
     FetchDataException([String? message]):super(message,'');
}



class BadRequestException extends AppExceptions {
  BadRequestException([String? message]) : super(message, '');
}

class UnAuthorizedException extends AppExceptions {
  UnAuthorizedException([String? message]) : super(message, '');
}