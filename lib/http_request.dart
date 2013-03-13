/*
 This is just a copy of the HttpRequest object.  I've extended it with the
 ability to add attributes to the request to support filter.
*/
library route.server;

import 'dart:io' as io;
import 'dart:async';
import 'dart:uri';
import 'dart:collection';

class HttpRequest extends io.HttpRequest {

  io.HttpRequest _httpRequest;
  Map<String, dynamic> _attributes;

  HttpRequest(this._httpRequest) {
    this._attributes = new Map<String, dynamic>();
  }

  Map<String, dynamic> get attributes => this._attributes;

  dynamic noSuchMethod(InvocationMirror msg) {
    if (msg.isSetter) {
      this._attributes[msg.memberName.substring(0, msg.memberName.length - 1)] = msg.positionalArguments[0];
    } else if (msg.isGetter) {
      if (this._attributes.containsKey(msg.memberName)) {
        return this._attributes[msg.memberName];
      } else {
        return null;
      }
    } else {
      return super.noSuchMethod(msg);
    }
  }

  // Delegate ALL methods to the underlying class because we can't inherit from _HttpRequest
  int get contentLength => this._httpRequest.contentLength;
  String get method => this._httpRequest.method;
  Uri get uri => this._httpRequest.uri;
  Map<String, String> get queryParameters => this._httpRequest.queryParameters;
  io.HttpHeaders get headers => this._httpRequest.headers;
  List<io.Cookie> get cookies => this._httpRequest.cookies;
  bool get persistentConnection => this._httpRequest.persistentConnection;
  io.X509Certificate get certificate => this._httpRequest.certificate;
  io.HttpSession get session => this._httpRequest.session;
  String get protocolVersion => this._httpRequest.protocolVersion;
  io.HttpConnectionInfo get connectionInfo => this._httpRequest.connectionInfo;
  io.HttpResponse get response => this._httpRequest.response;
  bool get isBroadcast => this._httpRequest.isBroadcast;
  Stream<List<int>> asBroadcastStream() => this._httpRequest.asBroadcastStream();
  StreamSubscription<List<int>> listen(void onData(List<int> event), { void onError(AsyncError error), void onDone(), bool unsubscribeOnError}) =>
    this._httpRequest.listen(onData, onError: onError, onDone: onDone, unsubscribeOnError: unsubscribeOnError);
  Stream<List<int>> where(bool test(List<int> event)) => this._httpRequest.where(test);
  Stream map(convert(List<int> event)) => this._httpRequest.map(convert);
  Stream<List<int>> handleError(void handle(AsyncError error), { bool test(error) }) =>
    this._httpRequest.handleError(handle, test: test);
  Stream expand(Iterable convert(List<int> value)) => this._httpRequest.expand(convert);
  Future pipe(StreamConsumer<List<int>, dynamic> streamConsumer) => this._httpRequest.pipe(streamConsumer);
  Stream transform(StreamTransformer<List<int>, dynamic> streamTransformer) => this._httpRequest.transform(streamTransformer);
  Future reduce(initialValue, combine(previous, List<int> element)) => this._httpRequest.reduce(initialValue, combine);
  Future pipeInto(StreamSink<List<int>> sink, {void onError(AsyncError error), bool unsubscribeOnError}) =>
    this._httpRequest.pipeInto(sink, onError: onError, unsubscribeOnError: unsubscribeOnError);
  Future<bool> contains(List<int> match) => this._httpRequest.contains(match);
  Future<bool> every(bool test(List<int> element)) => this._httpRequest.every(test);
  Future<bool> any(bool test(List<int> element)) => this._httpRequest.any(test);
  Future<int> get length => this._httpRequest.length;
  Future<List> min([int compare(List<int> a, List<int> b)]) => this._httpRequest.min(compare);
  Future<List> max([int compare(List<int> a, List<int> b)]) => this._httpRequest.max(compare);
  Future<bool> get isEmpty => this._httpRequest.isEmpty;
  Future<List<List>> toList() => this._httpRequest.toList();
  Future<Set<List>> toSet() => this._httpRequest.toSet();
  Stream<List> take(int count) => this._httpRequest.take(count);
  Stream<List> takeWhile(bool test(List<int> value)) => this._httpRequest.takeWhile(test);
  Stream<List> skip(int count) => this._httpRequest.skip(count);
  Stream<List> skipWhile(bool test(List<int> value)) => this._httpRequest.skipWhile(test);
  Stream<List> distinct([bool equals(List<int> previous, List<int> next)]) => this._httpRequest.distinct(equals);
  Future<List> get first => this._httpRequest.first;
  Future<List> get last => this._httpRequest.last;
  Future<List> get single => this._httpRequest.single;
  Future<List<int>> firstMatching(bool test(List<int> value), {List<int> defaultValue()}) =>
    this._httpRequest.firstMatching(test, defaultValue:defaultValue);
  Future<List> lastMatching(bool test(List<int> value), {List<int> defaultValue()}) =>
    this._httpRequest.lastMatching(test, defaultValue: defaultValue);
  Future<List> singleMatching(bool test(List<int> value)) => this._httpRequest.singleMatching(test);
  Future<List> elementAt(int index) => this._httpRequest.elementAt(index);

}

