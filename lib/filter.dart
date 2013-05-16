library route.server;

import 'dart:io';

class Filter {
  Future onBefore(HttpRequest request) {}
  Future onAfter(HttpRequest request) {}
}
