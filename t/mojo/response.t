use Mojo::Base -strict;

use Test::More tests => 277;

# "Quick Smithers. Bring the mind eraser device!
#  You mean the revolver, sir?
#  Precisely."
use Mojo::Asset::File;
use Mojo::Content::Single;
use Mojo::Content::MultiPart;
use Mojo::Headers;

use_ok 'Mojo::Message::Response';

# Status code and message
my $res = Mojo::Message::Response->new;
is $res->code,            undef,       'no status';
is $res->default_message, 'Not Found', 'right default message';
is $res->message,         undef,       'no message';
$res->message('Test');
is $res->message, 'Test', 'right message';
$res->code(500);
is $res->code,            500,                     'right status';
is $res->message,         'Test',                  'right message';
is $res->default_message, 'Internal Server Error', 'right default message';
$res = Mojo::Message::Response->new;
is $res->code(400)->default_message, 'Bad Request', 'right default message';
$res = Mojo::Message::Response->new;
is $res->code(1)->default_message, '', 'empty default message';

# Parse HTTP 1.1 response start line, no headers and body
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 200 OK\x0d\x0a\x0d\x0a");
ok $res->is_finished, 'response is finished';
is $res->code,        200, 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';

# Parse HTTP 1.1 response start line, no headers and body (small chunks)
$res = Mojo::Message::Response->new;
$res->parse('H');
ok !$res->is_finished, 'response is not finished';
$res->parse('T');
ok !$res->is_finished, 'response is not finished';
$res->parse('T');
ok !$res->is_finished, 'response is not finished';
$res->parse('P');
ok !$res->is_finished, 'response is not finished';
$res->parse('/');
ok !$res->is_finished, 'response is not finished';
$res->parse('1');
ok !$res->is_finished, 'response is not finished';
$res->parse('.');
ok !$res->is_finished, 'response is not finished';
$res->parse('1');
ok !$res->is_finished, 'response is not finished';
$res->parse(' ');
ok !$res->is_finished, 'response is not finished';
$res->parse('2');
ok !$res->is_finished, 'response is not finished';
$res->parse('0');
ok !$res->is_finished, 'response is not finished';
$res->parse('0');
ok !$res->is_finished, 'response is not finished';
$res->parse(' ');
ok !$res->is_finished, 'response is not finished';
$res->parse('O');
ok !$res->is_finished, 'response is not finished';
$res->parse('K');
ok !$res->is_finished, 'response is not finished';
$res->parse("\x0d");
ok !$res->is_finished, 'response is not finished';
$res->parse("\x0a");
ok !$res->is_finished, 'response is not finished';
$res->parse("\x0d");
ok !$res->is_finished, 'response is not finished';
$res->parse("\x0a");
ok $res->is_finished, 'response is finished';
is $res->code,        200, 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';

# Parse HTTP 1.1 response start line, no headers and body (no message)
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 200\x0d\x0a\x0d\x0a");
ok $res->is_finished, 'response is finished';
is $res->code,        200, 'right status';
is $res->message,     undef, 'no message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';

# Parse HTTP 0.9 response
$res = Mojo::Message::Response->new;
$res->parse("HTT... this is just a document and valid HTTP 0.9\n\n");
ok $res->is_finished, 'response is finished';
is $res->version, '0.9', 'right version';
ok $res->at_least_version('0.9'), 'at least version 0.9';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->body, "HTT... this is just a document and valid HTTP 0.9\n\n",
  'right content';

# Parse HTTP 1.0 response start line and headers but no body
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.0 404 Damn it\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Content-Length: 0\x0d\x0a\x0d\x0a");
ok $res->is_finished, 'response is finished';
is $res->code,        404, 'right status';
is $res->message,     'Damn it', 'right message';
is $res->version,     '1.0', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_type, 'text/plain', 'right "Content-Type" value';
is $res->headers->content_length, 0, 'right "Content-Length" value';

# Parse full HTTP 1.0 response
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.0 500 Internal Server Error\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Content-Length: 27\x0d\x0a\x0d\x0a");
$res->parse("Hello World!\n1234\nlalalala\n");
ok $res->is_finished, 'response is finished';
is $res->code,        500, 'right status';
is $res->message,     'Internal Server Error', 'right message';
is $res->version,     '1.0', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_type, 'text/plain', 'right "Content-Type" value';
is $res->headers->content_length, 27, 'right "Content-Length" value';

# Parse full HTTP 1.0 response (missing Content-Length)
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.0 500 Internal Server Error\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Connection: close\x0d\x0a\x0d\x0a");
$res->parse("Hello World!\n1234\nlalalala\n");
ok !$res->is_finished, 'response is not finished';
is $res->code,    500,                     'right status';
is $res->message, 'Internal Server Error', 'right message';
is $res->version, '1.0',                   'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_type,   'text/plain', 'right "Content-Type" value';
is $res->headers->content_length, undef,        'no "Content-Length" value';
is $res->body, "Hello World!\n1234\nlalalala\n", 'right content';

# Parse full HTTP 1.0 response (missing Content-Length and Connection)
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.0 500 Internal Server Error\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a\x0d\x0a");
$res->parse("Hello World!\n1234\nlalalala\n");
ok !$res->is_finished, 'response is not finished';
is $res->code,    500,                     'right status';
is $res->message, 'Internal Server Error', 'right message';
is $res->version, '1.0',                   'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_type,   'text/plain', 'right "Content-Type" value';
is $res->headers->content_length, undef,        'no "Content-Length" value';
is $res->body, "Hello World!\n1234\nlalalala\n", 'right content';

# Parse full HTTP 1.1 response (missing Content-Length)
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 500 Internal Server Error\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Connection: close\x0d\x0a\x0d\x0a");
$res->parse("Hello World!\n1234\nlalalala\n");
ok !$res->is_finished, 'response is not finished';
is $res->code,    500,                     'right status';
is $res->message, 'Internal Server Error', 'right message';
is $res->version, '1.1',                   'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_type,   'text/plain', 'right "Content-Type" value';
is $res->headers->content_length, undef,        'no "Content-Length" value';
is $res->body, "Hello World!\n1234\nlalalala\n", 'right content';

# Parse HTTP 1.1 response (413 error in one big chunk)
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 413 Request Entity Too Large\x0d\x0a"
    . "Connection: Close\x0d\x0a"
    . "Date: Tue, 09 Feb 2010 16:34:51 GMT\x0d\x0a"
    . "Server: Mojolicious (Perl)\x0d\x0a"
    . "X-Powered-By: Mojolicious (Perl)\x0d\x0a\x0d\x0a");
ok !$res->is_finished, 'response is not finished';
is $res->code,    413,                        'right status';
is $res->message, 'Request Entity Too Large', 'right message';
is $res->version, '1.1',                      'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_length, undef, 'right "Content-Length" value';

# Parse HTTP 1.1 chunked response
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 500 Internal Server Error\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Transfer-Encoding: chunked\x0d\x0a\x0d\x0a");
$res->parse("4\x0d\x0a");
$res->parse("abcd\x0d\x0a");
$res->parse("9\x0d\x0a");
$res->parse("abcdefghi\x0d\x0a");
$res->parse("0\x0d\x0a\x0d\x0a");
ok $res->is_finished, 'response is finished';
is $res->code,        500, 'right status';
is $res->message,     'Internal Server Error', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_type, 'text/plain', 'right "Content-Type" value';
is $res->headers->content_length, 13, 'right "Content-Length" value';
is $res->content->body_size,      13, 'right size';

# Parse HTTP 1.1 multipart response
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 200 OK\x0d\x0a");
$res->parse("Content-Length: 420\x0d\x0a");
$res->parse('Content-Type: multipart/form-data; bo');
$res->parse("undary=----------0xKhTmLbOuNdArY\x0d\x0a\x0d\x0a");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse("Content-Disposition: form-data; name=\"text1\"\x0d\x0a");
$res->parse("\x0d\x0ahallo welt test123\n");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse("Content-Disposition: form-data; name=\"text2\"\x0d\x0a");
$res->parse("\x0d\x0a\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse('Content-Disposition: form-data; name="upload"; file');
$res->parse("name=\"hello.pl\"\x0d\x0a\x0d\x0a");
$res->parse("Content-Type: application/octet-stream\x0d\x0a\x0d\x0a");
$res->parse("#!/usr/bin/perl\n\n");
$res->parse("use strict;\n");
$res->parse("use warnings;\n\n");
$res->parse("print \"Hello World :)\\n\"\n");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY--");
ok $res->is_finished, 'response is finished';
is $res->code,        200, 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
ok $res->headers->content_type =~ m#multipart/form-data#,
  'right "Content-Type" value';
isa_ok $res->content->parts->[0], 'Mojo::Content::Single', 'right part';
isa_ok $res->content->parts->[1], 'Mojo::Content::Single', 'right part';
isa_ok $res->content->parts->[2], 'Mojo::Content::Single', 'right part';
is $res->content->parts->[0]->asset->slurp, "hallo welt test123\n",
  'right content';

# Parse HTTP 1.1 multipart response with missing boundary
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 200 OK\x0d\x0a");
$res->parse("Content-Length: 420\x0d\x0a");
$res->parse("Content-Type: multipart/form-data; bo\x0d\x0a\x0d\x0a");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse("Content-Disposition: form-data; name=\"text1\"\x0d\x0a");
$res->parse("\x0d\x0ahallo welt test123\n");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse("Content-Disposition: form-data; name=\"text2\"\x0d\x0a");
$res->parse("\x0d\x0a\x0d\x0a------------0xKhTmLbOuNdArY\x0d\x0a");
$res->parse('Content-Disposition: form-data; name="upload"; file');
$res->parse("name=\"hello.pl\"\x0d\x0a\x0d\x0a");
$res->parse("Content-Type: application/octet-stream\x0d\x0a\x0d\x0a");
$res->parse("#!/usr/bin/perl\n\n");
$res->parse("use strict;\n");
$res->parse("use warnings;\n\n");
$res->parse("print \"Hello World :)\\n\"\n");
$res->parse("\x0d\x0a------------0xKhTmLbOuNdArY--");
ok $res->is_finished, 'response is finished';
is $res->code,        200, 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
ok $res->headers->content_type =~ m#multipart/form-data#,
  'right "Content-Type" value';
isa_ok $res->content, 'Mojo::Content::Single', 'right content';
like $res->content->asset->slurp, qr/hallo welt/, 'right content';

# Build HTTP 1.1 response start line with minimal headers
$res = Mojo::Message::Response->new;
$res->code(404);
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res = Mojo::Message::Response->new->parse($res->to_string);
ok $res->is_finished, 'response is finished';
is $res->code,        '404', 'right status';
is $res->message,     'Not Found', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->date, 'Sun, 17 Aug 2008 16:27:35 GMT', 'right "Date" value';
is $res->headers->content_length, 0, 'right "Content-Length" value';

# Build HTTP 1.1 response start line with minimal headers (strange message)
$res = Mojo::Message::Response->new;
$res->code(404);
$res->message('Looks-0k!@ ;\':" #$%^<>,.\\o/ &*()');
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res = Mojo::Message::Response->new->parse($res->to_string);
ok $res->is_finished, 'response is finished';
is $res->code,        '404', 'right status';
is $res->message,     'Looks-0k!@ ;\':" #$%^<>,.\\o/ &*()', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->date, 'Sun, 17 Aug 2008 16:27:35 GMT', 'right "Date" value';
is $res->headers->content_length, 0, 'right "Content-Length" value';

# Build HTTP 1.1 response start line and header
$res = Mojo::Message::Response->new;
$res->code(200);
$res->headers->connection('keep-alive');
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res = Mojo::Message::Response->new->parse($res->to_string);
ok $res->is_finished, 'response is finished';
is $res->code,        '200', 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->connection, 'keep-alive', 'right "Connection" value';
is $res->headers->date, 'Sun, 17 Aug 2008 16:27:35 GMT', 'right "Date" value';
is $res->headers->content_length, 0, 'right "Content-Length" value';

# Build full HTTP 1.1 response
$res = Mojo::Message::Response->new;
$res->code(200);
$res->headers->connection('keep-alive');
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res->body("Hello World!\n");
$res = Mojo::Message::Response->new->parse($res->to_string);
ok $res->is_finished, 'response is finished';
is $res->code,        '200', 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->connection, 'keep-alive', 'right "Connection" value';
is $res->headers->date, 'Sun, 17 Aug 2008 16:27:35 GMT', 'right "Date" value';
is $res->headers->content_length, '13', 'right "Content-Length" value';
is $res->body, "Hello World!\n", 'right content';

# Build HTTP 0.9 response
$res = Mojo::Message::Response->new;
$res->version('0.9');
$res->body("this is just a document and valid HTTP 0.9\nlalala\n");
is $res->to_string, "this is just a document and valid HTTP 0.9\nlalala\n",
  'right message';
$res = Mojo::Message::Response->new->parse($res->to_string);
ok $res->is_finished, 'response is finished';
is $res->code,        undef, 'no status';
is $res->message,     undef, 'no message';
is $res->version,     '0.9', 'right version';
ok $res->at_least_version('0.9'), 'at least version 0.9';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->body, "this is just a document and valid HTTP 0.9\nlalala\n",
  'right content';

# Build HTTP 1.1 multipart response
$res = Mojo::Message::Response->new;
$res->content(Mojo::Content::MultiPart->new);
$res->code(200);
$res->headers->content_type('multipart/mixed; boundary=7am1X');
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
push @{$res->content->parts},
  Mojo::Content::Single->new(asset => Mojo::Asset::File->new);
$res->content->parts->[-1]->asset->add_chunk('Hallo Welt lalalalalala!');
my $content = Mojo::Content::Single->new;
$content->asset->add_chunk("lala\nfoobar\nperl rocks\n");
$content->headers->content_type('text/plain');
push @{$res->content->parts}, $content;
$res = Mojo::Message::Response->new->parse($res->to_string);
ok $res->is_finished, 'response is finished';
is $res->code,        200, 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->date, 'Sun, 17 Aug 2008 16:27:35 GMT', 'right "Date" value';
is $res->headers->content_length, '108', 'right "Content-Length" value';
is $res->headers->content_type, 'multipart/mixed; boundary=7am1X',
  'right "Content-Type" value';
is $res->content->parts->[0]->asset->slurp, 'Hallo Welt lalalalalala!',
  'right content';
is $res->content->parts->[1]->headers->content_type, 'text/plain',
  'right "Content-Type" value';
is $res->content->parts->[1]->asset->slurp, "lala\nfoobar\nperl rocks\n",
  'right content';

# Parse response with cookie
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.0 200 OK\x0d\x0a");
$res->parse("Content-Type: text/plain\x0d\x0a");
$res->parse("Content-Length: 27\x0d\x0a");
$res->parse("Set-Cookie: foo=bar; Version=1; Path=/test\x0d\x0a\x0d\x0a");
$res->parse("Hello World!\n1234\nlalalala\n");
ok $res->is_finished, 'response is finished';
is $res->code,        200, 'right status';
is $res->message,     'OK', 'right message';
is $res->version,     '1.0', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->content_type, 'text/plain', 'right "Content-Type" value';
is $res->headers->content_length, 27, 'right "Content-Length" value';
is $res->headers->set_cookie, 'foo=bar; Version=1; Path=/test',
  'right "Set-Cookie" value';
my $cookies = $res->cookies;
is $cookies->[0]->name,  'foo',   'right name';
is $cookies->[0]->value, 'bar',   'right value';
is $cookies->[0]->path,  '/test', 'right path';
is $res->cookie('foo')->value, 'bar',   'right value';
is $res->cookie('foo')->path,  '/test', 'right path';

# Parse WebSocket handshake response
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 101 Switching Protocols\x0d\x0a");
$res->parse("Upgrade: websocket\x0d\x0a");
$res->parse("Connection: Upgrade\x0d\x0a");
$res->parse("Sec-WebSocket-Accept: abcdef=\x0d\x0a");
$res->parse("Sec-WebSocket-Protocol: sample\x0d\x0a\x0d\x0a");
ok $res->is_finished, 'response is finished';
is $res->code,        101, 'right status';
is $res->message,     'Switching Protocols', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->upgrade,    'websocket', 'right "Upgrade" value';
is $res->headers->connection, 'Upgrade',   'right "Connection" value';
is $res->headers->sec_websocket_accept, 'abcdef=',
  'right "Sec-WebSocket-Accept" value';
is $res->headers->sec_websocket_protocol, 'sample',
  'right "Sec-WebSocket-Protocol" value';
is $res->body, '', 'no content';

# Build WebSocket handshake response
$res = Mojo::Message::Response->new;
$res->code(101);
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res->headers->upgrade('websocket');
$res->headers->connection('Upgrade');
$res->headers->sec_websocket_accept('abcdef=');
$res->headers->sec_websocket_protocol('sample');
$res = Mojo::Message::Response->new->parse($res->to_string);
ok $res->is_finished, 'response is finished';
is $res->code,        '101', 'right status';
is $res->message,     'Switching Protocols', 'right message';
is $res->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res->headers->connection, 'Upgrade', 'right "Connection" value';
is $res->headers->date, 'Sun, 17 Aug 2008 16:27:35 GMT', 'right "Date" value';
is $res->headers->upgrade,        'websocket', 'right "Upgrade" value';
is $res->headers->content_length, 0,           'right "Content-Length" value';
is $res->headers->sec_websocket_accept, 'abcdef=',
  'right "Sec-WebSocket-Accept" value';
is $res->headers->sec_websocket_protocol,
  'sample', 'right "Sec-WebSocket-Protocol" value';
is $res->body, '', 'no content';

# Build and parse HTTP 1.1 response with 3 cookies
$res = Mojo::Message::Response->new;
$res->code(404);
$res->headers->date('Sun, 17 Aug 2008 16:27:35 GMT');
$res->cookies(
  {name => 'foo', value => 'bar', path => '/foobar'},
  {name => 'bar', value => 'baz', path => '/test/23'}
);
$res->cookies({name => 'baz', value => 'yada', path => '/foobar'});
ok !!$res->to_string, 'message built';
my $res2 = Mojo::Message::Response->new;
$res2->parse($res->to_string);
ok $res2->is_finished, 'response is finished';
is $res2->code,        404, 'right status';
is $res2->version,     '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
is $res2->headers->content_length, 0, 'right "Content-Length" value';
ok defined $res2->cookie('foo'),   'cookie "foo" exists';
ok defined $res2->cookie('bar'),   'cookie "bar" exists';
ok defined $res2->cookie('baz'),   'cookie "baz" exists';
ok !defined $res2->cookie('yada'), 'cookie "yada" does not exist';
is $res2->cookie('foo')->path,  '/foobar',  'right path';
is $res2->cookie('foo')->value, 'bar',      'right value';
is $res2->cookie('bar')->path,  '/test/23', 'right path';
is $res2->cookie('bar')->value, 'baz',      'right value';
is $res2->cookie('baz')->path,  '/foobar',  'right path';
is $res2->cookie('baz')->value, 'yada',     'right value';

# Build response with callback (make sure it's called)
$res = Mojo::Message::Response->new;
$res->code(200);
$res->headers->content_length(10);
$res->write('lala', sub { die "Body coderef was called properly\n" });
$res->get_body_chunk(0);
eval { $res->get_body_chunk(3) };
is $@, "Body coderef was called properly\n", 'right error';

# Build response with callback (consistency calls)
$res = Mojo::Message::Response->new;
my $body = 'I is here';
$res->headers->content_length(length($body));
my $cb;
$cb = sub { shift->write(substr($body, pop, 1), $cb) };
$res->write('', $cb);
my $full   = '';
my $count  = 0;
my $offset = 0;
while (1) {
  my $chunk = $res->get_body_chunk($offset);
  last unless $chunk;
  $full .= $chunk;
  $offset = length($full);
  $count++;
}
$res->fix_headers;
is $res->headers->connection, undef, 'no "Connection" value';
ok !$res->is_dynamic, 'no dynamic content';
is $count, length($body), 'right length';
is $full, $body, 'right content';

# Build response with callback (no Content-Length header)
$res  = Mojo::Message::Response->new;
$body = 'I is here';
$cb   = sub { shift->write(substr($body, pop, 1), $cb) };
$res->write('', $cb);
$res->fix_headers;
$full   = '';
$count  = 0;
$offset = 0;
while (1) {
  my $chunk = $res->get_body_chunk($offset);
  last unless $chunk;
  $full .= $chunk;
  $offset = length($full);
  $count++;
}
is $res->headers->connection, 'close', 'right "Connection" value';
ok $res->is_dynamic, 'dynamic content';
is $count, length($body), 'right length';
is $full, $body, 'right content';

# Body helper
$res = Mojo::Message::Response->new;
$res->body('hi there!');
is $res->body, 'hi there!', 'right content';
$res->body('');
is $res->body, '', 'right content';
$res->body('hi there!');
is $res->body, 'hi there!', 'right content';
ok $res->content->has_subscribers('read'), 'has subscribers';
$cb = $res->body(sub { });
ok $res->content->has_subscribers('read'), 'has subscribers';
$res->content->unsubscribe(read => $cb);
ok !$res->content->has_subscribers('read'), 'no subscribers';
$res->body('');
is $res->body, '', 'right content';
$res->body(0);
is $res->body, 0, 'right content';
ok !$res->content->has_subscribers('read'), 'no subscribers';
$cb = $res->body(sub { });
ok $res->content->has_subscribers('read'), 'has subscribers';
$res->content->unsubscribe(read => $cb);
$res->body('hello!');
ok !$res->content->has_subscribers('read'), 'no subscribers';
is $res->body, 'hello!', 'right content';
ok !$res->content->has_subscribers('read'), 'no subscribers';
$res->content(Mojo::Content::MultiPart->new);
$res->body('hi!');
is $res->body, 'hi!', 'right content';

# Version management
$res = Mojo::Message::Response->new;
is $res->version, '1.1', 'right version';
ok $res->at_least_version('1.0'), 'at least version 1.0';
ok !$res->at_least_version('1.2'), 'not version 1.2';
ok $res->at_least_version('1.1'), 'at least version 1.1';
ok $res->at_least_version('1.0'), 'at least version 1.0';
$res = Mojo::Message::Response->new(version => '1.0');
is $res->version, '1.0', 'right version';
ok !$res->at_least_version('1.1'), 'not version 1.1';
ok $res->at_least_version('1.0'), 'at least version 1.0';
$res = Mojo::Message::Response->new(version => '0.9');
ok !$res->at_least_version('1.0'), 'not version 1.0';
ok $res->at_least_version('0.9'), 'at least version 0.9';

# Build dom from request with charset
$res = Mojo::Message::Response->new;
$res->parse("HTTP/1.1 200 OK\x0a");
$res->parse(
  "Content-Type: application/atom+xml; charset=UTF-8; type=feed\x0a");
$res->parse("\x0a");
$res->body('<p>foo <a href="/">bar</a><a href="/baz">baz</a></p>');
ok !$res->is_finished, 'request is not finished';
is $res->headers->content_type,
  'application/atom+xml; charset=UTF-8; type=feed',
  'right "Content-Type" value';
ok $res->dom, 'dom built';
$count = 0;
$res->dom('a')->each(sub { $count++ });
is $count, 2, 'all anchors found';
