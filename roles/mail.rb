name "mail"
description "Role applied to all mail servers"

default_attributes(
  :exim => {
    :local_domains => [
      "openstreetmap.org",
      "osm.org",
      "noreply.openstreetmap.org",
      "openstreetmap.co.uk",
      "openstreetmap.org.uk",
      "openstreetmap.com",
      "openstreetmap.io",
      "openstreetmap.pro",
      "openstreetmaps.org",
      "osm.io"
    ],
    :daemon_smtp_ports => [25, 26],
    :smarthost_name => "mail.openstreetmap.org",
    :smarthost_via => false,
    :dns_blacklists => ["sbl-xbl.spamhaus.org"],
    :routes => {
      :messages => {
        :comment => "messages.openstreetmap.org",
        :domains => ["messages.openstreetmap.org"],
        :host => ["spike-01.openstreetmap.org", "spike-02.openstreetmap.org", "spike-03.openstreetmap.org"]
      },
      :otrs => {
        :comment => "otrs.openstreetmap.org",
        :domains => ["otrs.openstreetmap.org"],
        :host => "ridley.ucl.openstreetmap.org"
      },
      :tickets => {
        :comment => "tickets.openstreetmap.org",
        :domains => ["tickets.openstreetmap.org"],
        :host => "ridley.ucl.openstreetmap.org"
      },
      :join => {
        :comment => "join.osmfoundation.org",
        :domains => ["join.osmfoundation.org"],
        :host => "ridley.ucl.openstreetmap.org"
      }
    },
    :aliases => {
      "abuse" => "root",
      "postmaster" => "root",
      "webmaster" => "support",
      "clamav" => "root",
      "rails" => "root",
      "trac" => "root",
      "munin" => "root",
      "thinkup" => "root",
      "www-data" => "root",
      "osmbackup" => "root",
      "noreply" => "/dev/null",
      "bounces" => "/dev/null",
      "wishlist" => "/dev/null",
      "treasurer" => "treasurer@osmfoundation.org",
      "donations" => "treasurer@osmfoundation.org",
      "secretary" => "secretary@osmfoundation.org",
      "chairman" => "chairman@osmfoundation.org",
      "accountant" => "accountant@osmfoundation.org",
      "data" => "data@otrs.openstreetmap.org",
      "otrs" => "otrs@otrs.openstreetmap.org",
      "support" => "support@otrs.openstreetmap.org",
      "memorial" => "communication@osmfoundation.org",
      "legal" => "legal@osmfoundation.org",
      "dmca" => "dmca@osmfoundation.org"
    },
    :private_aliases => "mail"
  },
  :munin => {
    :plugins => {
      :exim_mailqueue => {
        :mails => {
          :warning => 500,
          :critical => 1000
        }
      }
    }
  }
)

run_list(
  "recipe[clamav]",
  "recipe[spamassassin]"
)
