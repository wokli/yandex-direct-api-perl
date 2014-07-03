use strict;
use warnings;
use Data::Dumper;

use DateTime;
use Test::More qw(no_plan);

use constant V => 0;
use utf8;

my $login = $ENV{YANDEX_DIRECT_API_LOGIN};
my $token = $ENV{YANDEX_DIRECT_API_TOKEN};

$|++;
$Data::Dumper::Useqq = 1; binmode STDERR, ':utf8'; { no warnings 'redefine'; sub Data::Dumper::qquote { my $s = shift; return "'$s'";}}

BEGIN { diag "testing started"; use_ok('Yandex::DirectAPI') };
ok (my $api = new Yandex::DirectAPI("token" => $token, "login" => $login), "constructor;");
ok(my $campaigns = $api -> get_active_campaigns([$login]), 'get_active_campaigns;');
is(ref $campaigns, "ARRAY", 'get_active_campaigns result type;');

my $campaign_ids = [map {''.$_ -> {'CampaignID'}} @$campaigns];

ok (my $banners = $api -> get_banners($campaign_ids, 2), 'get_banners;');
is(ref $banners, "HASH", 'get_banners result type;');
diag Dumper($banners) if V;

my $yesterday = DateTime -> now() -> subtract(days => 1) -> ymd;
ok(my $banners_stat = $api -> get_banners_stat($yesterday, $yesterday, $campaign_ids -> [1]), 'get_banners_stat;');
is(ref $banners_stat, "HASH", 'get_banners_stat result type;');
diag Dumper($banners_stat) if V;

ok(my $mass_banners = $api -> get_banners_stat_mass($yesterday, $yesterday, $campaign_ids), 'get_banners_stat_mass;' );
is(ref $mass_banners, "HASH", 'get_banners_stat_mass result type;');
diag Dumper($mass_banners) if V;