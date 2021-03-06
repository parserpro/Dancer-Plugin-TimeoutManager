package main;
use strict;
use warnings;

use Test::More import => ['!pass'];

{
    use Dancer;
    use Dancer::Plugin::TimeoutManager;
    use Dancer::Test;

    setting show_errors => 1;

    timeout 2, 'get' => '/success' => sub {
        sleep 1;
        return "ok";
    };

    timeout 2, 'get' => '/fail' => sub {
        sleep 3;
        return "ok";
    };

    timeout 0, 'get' => '/timeout0' => sub {
        sleep 1;
        return "ok";
    };

    timeout undef, 'get' => '/timeoutundef' => sub {
        sleep 3;
        return "ok";
    };

    timeout 'get' => '/timeoutnotset' => sub {
        sleep 3;
        return "ok";
    };

    timeout 'get' => '/timeoutnotsetandnoheader' => sub {
        sleep 3;
        return "ok";
    };

    timeout 'get' => '/timeouttoolong' => sub {
        sleep 5;
        return "ok";
    }
}

response_status_is [GET => '/success'], 200,
  "GET /success works (no timeout triggered)";
response_content_is [GET => '/success'], 'ok',
    "content looks good for /success";

response_status_is [GET => '/fail'], 408,
  "GET /fail works (timeout triggered)";
response_content_like [GET => '/fail'],
    qr{Request Timeout.*2 seconds},
    "content looks good for /fail";

response_status_is [GET => '/timeout0'], 200,
  "GET /success works (no timeout triggered)";
response_content_is [GET => '/timeout0'], 'ok',
    "content looks good for /timeout0";


response_status_is [GET => '/timeoutundef'], 200,
  "GET /timeoutundef works (timeout not triggered)";
response_status_is [GET => '/timeoutundef', {headers => ['X-Dancer-Timeout' => '2']}], 408,
  "GET /timeoutundef works (timeout triggered) the header is correctly get";
response_content_like [GET => '/timeoutundef', {headers => ['X-Dancer-Timeout' => '2']}],
    qr{Request Timeout.*2 seconds},
    "content looks good for /timeoutundef";


response_status_is [GET => '/timeoutnotset', {headers => ['X-Dancer-Timeout' => '1']}], 408,
  "GET /timeoutnotset works (timeout triggered) timeout is not set but it is correctly get from headers";
response_content_like [GET => '/timeoutnotset', {headers => ['X-Dancer-Timeout' => '1']}],
    qr{Request Timeout.*1 seconds},
    "content looks good for /timeoutnotset";

response_status_is [GET => '/timeoutnotsetandnoheader'], 200,
  "GET /timeoutnotsetandnoheader works like a classic route";
response_content_is [GET => '/timeoutnotsetandnoheader'], 'ok', "content looks good for /timeoutnotsetandnoheader";

{
    use Dancer ':tests';

    set disable_timeout => 1;
    set show_errors => 1;

    response_status_is [GET => '/timeouttoolong', {headers => ['X-Dancer-Timeout' => '2']}], 200,
      "GET /timeouttoolong works (timeout not triggered)";
    response_content_is [GET => '/timeouttoolong', {headers => ['X-Dancer-Timeout' => '2']}], 'ok',
      "content looks good for /timeouttoolong";
}

{
    use Dancer ':tests';
    use Dancer::Plugin::TimeoutManager;

    set disable_timeout => 0;
    set show_errors => 1;

    set plugins => {
        TimeoutManager => {
            max_timeout => 3,
        },
    };

    response_status_is [GET => '/timeouttoolong'], 200,
      "GET /timeouttoolong works (timeout not triggered - max_timeout not working if no timeout set)";
    response_content_is [GET => '/timeouttoolong'], 'ok',
      "content looks good for /timeouttoolong";
}

{
    use Dancer ':tests';
    use Dancer::Plugin::TimeoutManager;

    set disable_timeout => 0;
    set show_errors => 1;

    set plugins => {
        TimeoutManager => {
            max_timeout => 3,
        },
    };

    response_status_is [GET => '/timeouttoolong', {headers => ['X-Dancer-Timeout' => '4']}], 408,
      "GET /timeouttoolong works (timeout triggered) max_timeout in action";
    response_content_like [GET => '/timeouttoolong', {headers => ['X-Dancer-Timeout' => '4']}],
      qr{Request Timeout.*3 seconds},
      "content looks good for /timeouttoolong";
}

{
    use Dancer ':tests';
    use Dancer::Plugin::TimeoutManager;
    setting show_errors => 1;

    eval {
        timeout 1, 'putt' => '/timeout_incorrect_method' => sub {
            sleep 1;
            return "ok";
        };
    };
    is $@, "method must be one in get, put, post, delete and putt is used as a method", "Exception is correctly detected on method";
}

{
    use Dancer;
    use Dancer::Plugin::TimeoutManager;
    use Dancer::Test;

    is(Dancer::Plugin::TimeoutManager::register_callback(42), undef, 'Won\'t register non-coderef');
    is(Dancer::Plugin::TimeoutManager::register_callback(\&callback), 1, 'Callback registered');

    my $flag = 0;

    set disable_timeout => 0;
    set show_errors => 1;

    set plugins => {
        TimeoutManager => {
            max_timeout => 3,
        },
    };

    response_status_is [GET => '/timeouttoolong', {headers => ['X-Dancer-Timeout' => '4']}], 408,
      "GET /timeouttoolong works (timeout triggered) max_timeout in action";
    response_content_like [GET => '/timeouttoolong', {headers => ['X-Dancer-Timeout' => '4']}],
      qr{Request Timeout.*3 seconds},
      "content looks good for /timeouttoolong";

    is($flag, 1, 'Callback on timeout called');

    sub callback { $flag = 1; }
}


done_testing;

1;
