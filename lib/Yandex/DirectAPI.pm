package Yandex::DirectAPI;

use 5.014002;
use strict;
use warnings;

use LWP::UserAgent;
use JSON;

use URI;

require Exporter;

our $VERSION = '0.01';

use Data::Dumper;
use constant API_URL => 'https://api.direct.yandex.ru/v4/json/';
use constant API_URL_LIVE => 'https://api.direct.yandex.ru/live/v4/json/';

$Data::Dumper::Useqq = 1; binmode STDERR, ':utf8'; { no warnings 'redefine'; sub Data::Dumper::qquote { my $s = shift; return "'$s'";}}


sub new {
  my $class = shift;
  my %params = @_;
  my $self = {};

  $self -> {'ua'} = new LWP::UserAgent;
  $self -> {'token'} = $params{'token'} or die __PACKAGE__ . " constructor failed: access token required!";
  $self -> {'locale'} = $params{'locale'} || 'en';

  return bless($self, $class);
} 

sub _request {
  my $self = shift;
  my $url = shift;
  my $method = shift;
  my $param = shift;

  $self -> {'error'} = undef;

  my $jsonReq = to_json{
    "token" => $self -> {'token'},
    "locale" => $self -> {'locale'} || 'en',
    "method" => $method,
    "param" => $param,
    };

  my $response = $self -> {'ua'} -> request(new HTTP::Request('POST', $url, undef, $jsonReq));
  if ($response -> is_success) {
    my $result = decode_json($response -> content);
    if ($result -> {'error_code'}) {
      # usually api error - wrong params, access, method, etc
      $self -> {'error'} = "$method error: ".$result -> {'error_str'};
      return undef;
    }
    return decode_json($response -> content) -> {'data'};
  }
  else {
    # network error or yandex server down or ...
    $self -> {'error'} = $response -> status_line;
    return undef;
  }
}

sub get_error {
  my $self = shift;
  return $self -> {'error'};
}

sub _reset_error {
  my $self = shift;
  $self -> {'error'} = '';
}

sub get_active_campaigns {
  my $self = shift;
  my $logins = shift;
  my $result = $self -> _request(API_URL, 'GetCampaignsListFilter', {"Logins" => $logins, "Filter" => {"IsActive" => ["Yes"]}});
  return $result;
}

# just an API call. $campaign_ids is an arrayref, max 10 campaigns, error otherwise
sub _get_banners {
  my $self = shift;
  my $campaign_ids = shift; 

  my $result = $self -> _request(API_URL, 'GetBanners', { "CampaignIDS" => $campaign_ids, "Filter" => {'IsActive' => ['Yes']}});
  return $result;
}

# wrap around _get_banners. any amount of campaigns
sub get_banners {
  my $self = shift;
  my $campaign_ids = shift;
  my $split_by = shift || 10;

  # i.e. $split_by = 2, $campaign_ids = [1, 2, 3, 4, 5], then $chunks = [[1, 2], [3, 4], [5]] and so on. 10 is max and default
  my $chunks = [];
  my @clone_camp_ids = @$campaign_ids;
  push @$chunks, [ splice @clone_camp_ids, 0, $split_by ] while (@clone_camp_ids);

  my $result = {};
  for my $chunk (@$chunks) {
    my $banners = $self -> _get_banners($chunk);

    for my $banner (@$banners) {
      my $uri = new URI($banner -> {'Href'});
      $result -> {$banner -> {'BannerID'}} = {$uri -> query_form};
    }
  }
  return $result;
}

sub get_banners_stat {
  my $self = shift;
  my $start_date = shift;
  my $end_date = shift;
  my $campaign_id = shift;

  my $result = $self -> _request(API_URL_LIVE, 'GetBannersStat', {
    'CampaignID' => $campaign_id,
    'StartDate' => $start_date,
    'EndDate' => $end_date,
    'GroupByColumns' => ['clDate', 'clPhrase'],
    'OrderBy' => ['clDate', 'clBanner']
  });

  return $result;
}

sub get_banners_stat_mass {
  my $self = shift;
  my $start = shift;
  my $end = shift;

  my $campaign_ids = shift;

  my $result = {};
  for my $campaign_id (@$campaign_ids) {
    # TODO: get_banners_stat can return undef, it must be checked and possible error must be reported
    $result -> {$campaign_id} = $self -> get_banners_stat($start, $end, $campaign_id) -> {'Stat'};
  }

  return $result;

}

# sub get_banners_by_campaigns {
#   my $self = shift;
#   my $ids = shift;

#   return $self -> _request(API_URL, 'GetBanners', {"CampaignIDS" => $ids});
# }
1;
