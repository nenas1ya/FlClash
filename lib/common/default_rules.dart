/// The global rules a new install starts with, taken from the quick actions:
/// proxy loopback blocked, then LAN and BitTorrent direct.
const defaultGlobalRules = [
  'IP-CIDR,127.0.0.0/8,REJECT,no-resolve',
  'IP-CIDR,0.0.0.0/32,REJECT,no-resolve',
  'IP-CIDR6,::1/128,REJECT,no-resolve',
  'IP-CIDR6,::/128,REJECT,no-resolve',
  'AND,((IN-TYPE,TUN),(DST-PORT,853)),REJECT',
  'GEOSITE,private,DIRECT',
  'GEOIP,LAN,DIRECT,no-resolve',
  'GEOSITE,category-public-tracker,DIRECT',
  'GEOSITE,category-pt,DIRECT',
  r'PROCESS-NAME-REGEX,(?i)^(qbittorrent|transmission.*|deluge.*|aria2c|motrix|utorrent|bitcomet)(\.exe)?$,DIRECT',
];
