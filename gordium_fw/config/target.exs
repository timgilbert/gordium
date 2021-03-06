use Mix.Config

# Authorize the device to receive firmware using your public key.
# See https://hexdocs.pm/nerves_firmware_ssh/readme.html for more information
# on configuring nerves_firmware_ssh.

keys =
  [
    Path.join([System.user_home!(), ".ssh", "id_rsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ecdsa.pub"]),
    Path.join([System.user_home!(), ".ssh", "id_ed25519.pub"])
  ]
  |> Enum.filter(&File.exists?/1)

if keys == [],
  do:
    Mix.raise("""
    No SSH public keys found in ~/.ssh. An ssh authorized key is needed to
    log into the Nerves device and update firmware on it using ssh.
    See your project's config.exs for this error message.
    """)

config :gordium_ui, GordiumUI.Endpoint,
  code_reloader: false,
  http: [port: 80, protocol_options: [idle_timeout: :infinity]],
  load_from_system_env: false,
  server: true

config :nerves_ssh,
  authorized_keys: Enum.map(keys, &File.read!/1)

# Configure nerves_init_gadget.
# See https://hexdocs.pm/nerves_init_gadget/readme.html for more information.

# Setting the node_name will enable Erlang Distribution.
# Only enable this for prod if you understand the risks.
node_name = if Mix.env() != :prod, do: "gordium_fw"

config :vintage_net,
  regulatory_domain: "US",
  config: [
    # {"usb0", %{type: VintageNetDirect}},
    {"wlan0",
     %{
       type: VintageNetWiFi,
       vintage_net_wifi: %{
         key_mgmt: :wpa_psk,
         ssid: System.get_env("NERVES_NETWORK_SSID"),
         psk: System.get_env("NERVES_NETWORK_PSK")
       },
       ipv4: %{method: :dhcp}
     }}
  ]

  config :mdns_lite,
    # The `host` key specifies what hostnames mdns_lite advertises.  `:hostname`
    # advertises the device's hostname.local. For the official Nerves systems, this
    # is "nerves-<4 digit serial#>.local".  mdns_lite also advertises
    # "nerves.local" for convenience. If more than one Nerves device is on the
    # network, delete "nerves" from the list.

    host: [:hostname, "gordium"],
    ttl: 120,

    # Advertise the following services over mDNS.
    services: [
      %{
        name: "SSH Remote Login Protocol",
        protocol: "ssh",
        transport: "tcp",
        port: 22
      },
      %{
        name: "Secure File Transfer Protocol over SSH",
        protocol: "sftp-ssh",
        transport: "tcp",
        port: 22
      },
      %{
        name: "Erlang Port Mapper Daemon",
        protocol: "epmd",
        transport: "tcp",
        port: 4369
      }
    ]

# Import target specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
# Uncomment to use target specific configurations

# import_config "#{Mix.target()}.exs"
