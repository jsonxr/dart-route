import 'dart:io';
import 'dart:async';
import 'dart:core';

import 'package:route/server.dart';
import 'package:route/http_request.dart' as route;
import 'package:route/pattern.dart';
import 'package:route/filter.dart';

class RouteLogger extends Filter {
  onBefore(HttpRequest req) {
    //req.stopTime = new DateTime.now();
    String c = new String.fromCharCode(27); // 033

    StringBuffer str = new StringBuffer();
    int len = req.response.contentLength;
    int color = 32;

    String mystr = "$c[90m${req.method} ${req.uri} $c[${color}m${req.response.statusCode} $c[90m${new DateTime.now().toUtc()}$c[0m";
    print(mystr);

    attributes[req]['username'] = 'jason';
    print("attribute = ${attributes[req]}");
  }
  onAfter(route.HttpRequest req) {
  }
}


// Filters can be straight functions
void loggerblah(route.HttpRequest req) {
  req.filter = 'logger';
  print("GET ${req.uri}");
  //throw new ArgumentError("blah!!!!");
}

// Or filters can return a future
Future logger2(route.HttpRequest req) {
  req.filter = 'logger';
  print("GET2 ${req.uri}");
  return new Future.immediate(true);
  //throw new UnsupportedError('logger is unsupported');
}

Future authFilter(route.HttpRequest req) {
  Completer<Error> completer = new Completer();
  Future<Error> f = completer.future;
  new Timer(10, () {
    req.username = 'theusername';
    completer.complete();
  });
  return f;
}

serveArcticle(route.HttpRequest req) {
  HttpResponse res = req.response;
  String username = attributes[req]['username'];
  res.addString("hello ${username} from routes...");
}


void main() {
  HttpServer.bind('127.0.0.1', 3000).then((server) {
    var router = new Router(server);
    //router.filter(authFilter, matchAny(['/foo']));
    router.filter(new RouteLogger());
    //router.filter(logger2, urlPattern('(.*)'));
    router.serve('/foo').listen(serveArcticle);
    router.serve('/bar').listen(serveArcticle);
  });
}