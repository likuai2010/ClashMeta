import { nativeFetchAndValid, nativeInit, nativeLoad, nativeQueryGroup, nativeQueryGroupNames,
  nativeQueryTunnelState,
  nativeReadOverride,
  nativeWriteOverride} from 'libentry.so'
import { common } from '@kit.AbilityKit';
import map from '@hms.core.map.map';


export enum ProxySort {
  Default = "Default", Title = "Title", Delay = "Delay"
}
export enum TunnelState {
  Direct = "direct", Global = "global", Rule = "rule", Script = "script", None = "None"
}

export enum ProxyType {
  Direct = "Direct",
  Reject = "Reject",
  RejectDrop = "RejectDrop",
  Compatible = "Compatible",
  Pass = "Pass",

  Shadowsocks = "Shadowsocks",
  ShadowsocksR = "ShadowsocksR",
  Snell = "Snell",
  Socks5 = "Socks5",
  Http = "Http",
  Vmess = "Vmess",
  Vless = "Vless",
  Trojan = "Trojan",
  Hysteria = "Hysteria",
  Hysteria2 = "Hysteria2",
  Tuic = "Tuic",
  WireGuard = "WireGuard",
  Dns = "Dns",
  Ssh = "Ssh",

  Relay = "Relay",
  Selector = "Selector",
  Fallback = "Fallback",
  URLTest = "URLTest",
  LoadBalance = "LoadBalance",

  Unknown = "Unknown"
}
export interface Proxy {
  name: string;
  title: string;
  subtitle: string;
  type: ProxyType;
  delay: number;
}

export interface ProxyGroup{
  type: ProxyType
  proxies: Array<Proxy>
  now: string
}
export enum OverrideSlot{
  Persist, Session
}

enum LogMessageLevel {
  Debug = "debug",
  Info = "info",
  Warning = "warning",
  Error = "error",
  Silent = "silent",
  Unknown = "unknown"
}

export interface ConfigurationOverride {
  port?: number;
  "socks-port"?: number;
  "redir-port"?: number;
  "tproxy-port"?: number;
  "mixed-port"?: number;
  authentication?: string[];
  "allow-lan"?: boolean;
  "bind-address"?: string;
  mode?: TunnelState;
  "log-level"?: LogMessageLevel;
  ipv6?: boolean;
  "external-controller"?: string;
  "external-controller-tls"?: string;
  "external-controller-cors"?: string;
  secret?: string;
  hosts?: Record<string, string>;
  "unified-delay"?: boolean;
  "geodata-mode"?: boolean;
  "tcp-concurrent"?: boolean;
  "find-process-mode"?: FindProcessMode;
  dns?: Dns;
  app?: App;
  sniffer?: Sniffer;
  "geox-url"?: GeoXUrl;
}

export interface Dns {
  enable?: boolean;
  "prefer-h3"?: boolean;
  listen?: string;
  ipv6?: boolean;
  "use-hosts"?: boolean;
  "enhanced-mode"?: DnsEnhancedMode;
  nameserver?: string[];
  fallback?: string[];
  "default-nameserver"?: string[];
  "fake-ip-filter"?: string[];
  "fake-ip-filter-mode"?: string[];
  "fallback-filter"?: DnsFallbackFilter;
  "nameserver-policy"?: Record<string, string>;
}

export interface DnsFallbackFilter {
  geoIp?: boolean;
  geoIpCode?: string;
  ipcidr?: string[];
  domain?: string[];
}

export interface App {
  appendSystemDns?: boolean;
}

export enum FindProcessMode {
  Off = "off",
  Strict = "strict",
  Always = "always",
}

export enum DnsEnhancedMode {
  None = "normal",
  Mapping = "redir-host",
  FakeIp = "fake-ip",
}

export interface  Sniffer {
  enable?: boolean;
  sniffing?: string[];
  "force-dns-mapping"?: boolean;
  "parse-pure-ip"?: boolean;
  "override-destination"?: boolean;
  "force-domain"?: string[];
  "skip-domain"?: string[];
  "port-whitelist"?: string[];
  "sniff"?:Record<string, Sniff>
}
export interface Sniff{
  ports: string[],
  'override-destination'?: boolean
}

export interface  GeoXUrl {
  geoip?: string;
  mmdb?: string;
  geosite?: string;
}


