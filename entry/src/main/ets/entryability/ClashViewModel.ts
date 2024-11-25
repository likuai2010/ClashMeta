import { nativeFetchAndValid, nativeInit, nativeLoad, nativeQueryGroup, nativeQueryGroupNames,
  nativeQueryTunnelState,
  nativeReadOverride,
  nativeWriteOverride} from 'libentry.so'
import { common } from '@kit.AbilityKit';


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
  redirectPort?: number;
  proxyPort?: number;
  mixedPort?: number;
  authentication?: string[];
  allowLan?: boolean;
  bindAddress?: string;
  mode?: TunnelState;
  logLevel?: LogMessageLevel;
  ipv6?: boolean;
  externalController?: string;
  secret?: string;
  hosts?: Record<string, string>;
  unifiedDelay?: boolean;
  geodataMode?: boolean;
  tcpConcurrent?: boolean;
  findProcessMode?: FindProcessMode;
  dns?: Dns;
  app?: App;
  sniffer?: Sniffer;
  geoxurl?: GeoXUrl;
}

export interface Dns {
  enable?: boolean;
  preferH3?: boolean;
  listen?: string;
  ipv6?: boolean;
  useHosts?: boolean;
  enhancedMode?: DnsEnhancedMode;
  nameServer?: string[];
  fallback?: string[];
  defaultServer?: string[];
  fakeIpFilter?: string[];
  fallbackFilter?: DnsFallbackFilter;
  nameserverPolicy?: Record<string, string>;
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
  forceDnsMapping?: boolean;
  parsePureIp?: boolean;
  overrideDestination?: boolean;
  forceDomain?: string[];
  skipDomain?: string[];
  portWhitelist?: string[];
}

export interface  GeoXUrl {
  geoip?: string;
  mmdb?: string;
  geosite?: string;
}




export class ClashViewModel{

  queryOverride(slot: OverrideSlot): ConfigurationOverride{
    const res = nativeReadOverride(slot.valueOf())
    const config =  JSON.parse(res) as ConfigurationOverride
    console.debug("testTag queryOverride", JSON.stringify(config))
    return {
      redirectPort: config.redirectPort,
      proxyPort: config.proxyPort,
      mixedPort: config.mixedPort,
      authentication: config.authentication,
      allowLan: config.allowLan,
      bindAddress: config.bindAddress,
      mode: config.mode,
      logLevel: config.logLevel,
      ipv6: config.ipv6,
      externalController: config.externalController ||  "127.0.0.1:0",
      secret: config.secret,
      hosts: config.hosts,
      unifiedDelay: config.unifiedDelay,
      geodataMode: config.geodataMode,
      tcpConcurrent: config.tcpConcurrent,
      findProcessMode: config.findProcessMode,
      dns: config.dns || {
        enable: undefined,
        preferH3: undefined,
        listen: undefined,
        ipv6: undefined,
        useHosts: undefined,
        enhancedMode: undefined,
        nameServer: undefined,
        fallback: undefined,
        defaultServer: undefined,
        fakeIpFilter: undefined,
        fallbackFilter: undefined,
        nameserverPolicy: undefined
      } as Dns,
      app: config.app || {
        appendSystemDns: undefined
      },
      sniffer: config.sniffer || {
        enable: undefined,
        sniffing: undefined,
        forceDnsMapping: undefined,
        parsePureIp: undefined,
        overrideDestination: undefined,
        forceDomain: undefined,
        skipDomain: undefined,
        portWhitelist: undefined,
      },
      geoxurl: config.geoxurl || {
        geoip:undefined,
        mmdb:undefined,
        geosite:undefined,
      },
    }
  }
  patchOverride(slot: OverrideSlot, config: ConfigurationOverride){
    //
    // const test = {
    //   port: undefined,
    //   "socks-port": undefined,
    //   "redir-port": config.redirectPort,
    //   "tproxy-port": config.tproxyPort,
    //   "mixed-port": config.mixedPort,
    //   authentication: config.authentication,
    //   "allow-lan": config.allowLan,
    //   "bind-address": config.bindAddress,
    //   mode: config.mode,
    //   "log-level": config.logLevel,
    //   ipv6: config.ipv6,
    //   "external-controller": config.externalController ||  "127.0.0.1:0",
    //   secret: config.secret,
    //   hosts: config.hosts,
    //   "unified-delay": config.unifiedDelay,
    //   "geodata-mode": config.geodataMode,
    //   "tcp-concurrent": config.tcpConcurrent,
    //   "find-process-mode": config.findProcessMode,
    //   dns: {
    //     enable: undefined,
    //     "prefer-h3": undefined,
    //     listen: undefined,
    //     ipv6: undefined,
    //     "use-hosts": undefined,
    //     "enhancedMode": undefined,
    //     "enhanced-mode": undefined,
    //     fallback: undefined,
    //     "default-nameserver": undefined,
    //     "fake-ip-filter": undefined,
    //     "fallback-filter": undefined,
    //     "nameserver-policy": undefined
    //   } as Dns,
    //   "clash-for-android": {
    //     "append-system-dns": undefined
    //   } as App,
    //   sniffer: {
    //     enable: undefined,
    //     sniffing: undefined,
    //     "force-dns-mapping": undefined,
    //     "parse-pure-ip": undefined,
    //     "override-destination": undefined,
    //     "force-domain": undefined,
    //     "skip-domain": undefined,
    //     "port-whitelist": undefined,
    //   } as Sniffer,
    //   "geox-url": {
    //     geoip:undefined,
    //     mmdb:undefined,
    //     geosite:undefined,
    //   },
    // }
    // let json = JSON.stringify(test, (key: string, value:string) => {
    //   return value === undefined ? null : value;
    // })
    // console.log("testTag patchOverride", slot.valueOf(), json)
    nativeWriteOverride(1, `{"mode":"global"}`)
  }

}
export default new ClashViewModel()