name "thorn-03"
description "Master role applied to thorn-03"

default_attributes(
  :networking => {
    :interfaces => {
      :internal_ipv4 => {
        :interface => "eth0",
        :role => :internal,
        :family => :inet,
        :address => "146.179.159.167"
      }
    }
  }
)

run_list(
  "role[ic]",
  "role[hp-g5]",
  "role[web-backend]"
)
