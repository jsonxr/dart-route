// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library provides a simple API for routing HttpRequests based on thier
 * URL.
 */
library route.server;

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'url_pattern.dart';
export 'url_pattern.dart';
import 'pattern.dart';

import 'http_request.dart' as my;
import 'filter.dart';

//typedef Future<bool> Filter(HttpRequest request);

Expando<Map<dynamic, dynamic>> attributes = new Expando<Map<dynamic, dynamic>>();

/**
 * A request router that makes it easier to handle [HttpRequest]s from an
 * [HttpServer].
 *
 * [serve] creates a new [Stream] of requests whose paths match against the
 * given pattern. Matching requests are not sent to any other streams created by
 * a server() call.
 *
 * [filter] registers a [Filter] function to run against matching requests. On
 * each request the filters that match are run in order, waiting for each to
 * complete since filters return a Future. If any filter completes false, the
 * subsequent filters and request handlers are not run. This way a filter can
 * prevent further processing, like needed for authentication.
 *
 * Requests not matched by a call to [serve] are sent to the [defaultStream].
 * If there's no subscriber to the defaultStream then a 404 is sent to the
 * response.
 *
 * Example:
 *     import 'package:route/server.dart';
 *     import 'package:route/pattern.dart';
 *
 *     HttpServer.bind().then((server) {
 *       var router = new Router(server);
 *       router.filter(matchesAny(['/foo', '/bar']), authFilter);
 *       router.serve('/foo').listen(fooHandler);
 *       router.serve('/bar').listen(barHandler);
 *       router.defaultStream.listen(send404);
 *     });
 */
class Router {
  final Stream<HttpRequest> _incoming;

  final Map<Pattern, StreamController> _controllers =
      new LinkedHashMap<Pattern, StreamController>();

  final Map<Pattern, List<Filter>> _filters = new LinkedHashMap<Pattern, List<Filter>>();

  final StreamController<HttpRequest> _defaultController =
      new StreamController<HttpRequest>();

  /**
   * Create a new Router that listens to the [incoming] stream, usually an
   * instance of [HttpServer].
   */
  Router(Stream<HttpRequest> incoming) : _incoming = incoming {
    _incoming.listen(handleRequest);
  }

  /**
   * Request whose URI matches [url] are sent to the stream created by this
   * method, and not sent to any other router streams.
   */
  Stream<HttpRequest> serve(Pattern url) {
    var controller = new StreamController<HttpRequest>();
    _controllers[url] = controller;
    return controller.stream;
  }

  /**
   * A [Filter] returns a [Future<bool>] that tells the router whether to apply
   * the remaining filters and send requests to the streams created by [serve].
   *
   * If the filter returns true, the request is passed to the next filter, and
   * then to the first matching server stream. If the filter returns false, it's
   * assumed that the filter is handling the request and it's not forwarded.
   */
  void filter(Filter filter, [Pattern url]) {
    if (url == null) {
      url = urlPattern('(.*)');
    }
    List<Filter> filters = _filters[url];
    if (filters == null) {
      print("creating filters for ${url}...");
      filters = new List<Filter>();
      _filters[url] = filters;
    }
    print("adding filter for ${url} => ${filter}");
    filters.add(filter);
  }

  Stream<HttpRequest> get defaultStream => _defaultController.stream;

  void handleRequest(HttpRequest req) {
    //my.HttpRequest req = new my.HttpRequest(request);
    attributes[req] = new Map<dynamic, dynamic>();
    List<Future> futures = new List<Future>();

    // Gather all the futures that match
    _filters.keys.forEach((pattern) {
      if (matchesFull(pattern, req.uri.path)) {
        _filters[pattern].forEach((filter) {
          print("filter=$filter");
          futures.add(filter);
        });
      }
    });

    doError(err) {
      print("caught $err");
      this.handleError(req, err);
    }

    filtersReversed() {
      Future.forEach(futures.reversed, (f) {
        print("onAfter=$f");
        try {
          var r = f.onAfter(req);
          if (r is Future) {
            return r;
          } else {
            return new Future.immediate(r);
          }
        } catch(err) {
            return new Future.immediateError(err);
        }
      })
      .then( (_) {
        req.response.close();
      })
      .catchError(doError);
    }


    doThen(_) {
      print("continue????");

      bool handled = false;
      for (Pattern pattern in _controllers.keys) {
        if (matchesFull(pattern, req.uri.path)) {
          _controllers[pattern].add(req);
          handled = true;
          break;
        }
      }
      if (handled) {
        filtersReversed();
      } else {
        if (_defaultController.hasSubscribers) {
          _defaultController.add(req);
        } else {
          this.handle404(req);
        }
      }
    }

    try {
      Future.forEach(futures, (f) {
        print("onBefore=$f");
        try {
          var r = f.onBefore(req);
          if (r is Future) {
            return r;
          } else {
            return new Future.immediate(r);
          }
        } catch(err) {
            return new Future.immediateError(err);
        }
      }).then((_) {
        doThen(_);
      }).catchError(doError);
    } catch(err) {
      //TODO When m4 is released, remove the try/catch because it will work
      // This is to work around bug https://code.google.com/p/dart/source/detail?r=19164
      doError(err);
    }

  }

  void handleError(HttpRequest req, Error error) {
    req.response.statusCode = HttpStatus.NOT_FOUND;
    req.response.addString("error: ${error}");
    req.response.close();
  }

  void handle404(HttpRequest req) {
    req.response.statusCode = HttpStatus.NOT_FOUND;
    req.response.addString("Not Found");
    req.response.close();
  }

  void _handleRequest(HttpRequest request) {
    my.HttpRequest req = new my.HttpRequest(request);
    Error err = null;
    doWhile(_filters.keys, (pattern) {
      if (matchesFull(pattern, req.uri.path)) {
        return doWhile(_filters[pattern], (filter) {
          if (err == null) {
            return filter(req).then((c) {
              print("then filter ${c}");
              err = c;
              return c;
            });
          } else {
            return new Future<Error>.immediate(err);
          }
        }).then( (c) {
          return new Future<Error>.immediate(c);
        });
      } else {
        print("skip filter ${pattern}");
        return new Future<Error>.immediate(null);
      }
    }).then((_) {
      if (err != null) {
        bool handled = false;
        for (Pattern pattern in _controllers.keys) {
          if (matchesFull(pattern, req.uri.path)) {
            _controllers[pattern].add(req);
            handled = true;
            break;
          }
        }
        if (!handled) {
          if (_defaultController.hasSubscribers) {
            _defaultController.add(req);
          } else {
            this.handle404(req);
          }
        }
      } else {
        print("??error: ${err}");
        req.error = err;
        sendFilterFailed(req, err);
      }
    });
  }


//    _filters.forEach((pattern, filter) {
//      if (matchesFull(pattern, req.uri.path)) {
//        print("match! ${pattern}  ${req.uri.path}");
//        return _filters[pattern](req).then((c) {
//          cont = c;
//          return c;
//        });
//      }
//    });
//    doWhile(_filters.keys, (List<Pattern> patterns) {
//      doWhile(patterns, (pattern) {
//        if (matchesFull(pattern, req.uri.path)) {
//          return _filters[pattern](req).then((c) {
//            cont = c;
//            return c;
//          });
//        }
//        return new Future.immediate(true);
//      });
//    }).then((_) {
//      if (cont) {
//        bool handled = false;
//        for (Pattern pattern in _controllers.keys) {
//          if (matchesFull(pattern, req.uri.path)) {
//            _controllers[pattern].add(req);
//            handled = true;
//            break;
//          }
//        }
//        if (!handled) {
//          if (_defaultController.hasSubscribers) {
//            _defaultController.add(req);
//          } else {
//            send404(req);
//          }
//        }
//      }
//    });
//  }
}

