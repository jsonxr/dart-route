import 'dart:io';
import 'dart:async';

import 'package:route/server.dart';
import 'package:route/http_request.dart' as route;
import 'package:route/pattern.dart';


Future<bool> authFilter(route.HttpRequest req) {
  Completer<bool> completer = new Completer();
  Future<bool> f = completer.future;
  new Timer(10, () {
    req.username = 'me';
    completer.complete(true);
  });
  return f;
}

serveArcticle(route.HttpRequest req) {
  HttpResponse res = req.response;
  res.addString("hello ${req.username} from routes...");
  res.close();
}


void main() {
  HttpServer.bind('127.0.0.1', 3000).then((server) {
    var router = new Router(server);
    router.filter(matchAny(['/foo']), authFilter);
    router.serve('/foo').listen(serveArcticle);
    router.serve('/bar').listen(serveArcticle);
  });
}