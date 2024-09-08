import {
  ConfigurationOverride,
  OverrideSlot, ProxyGroup, ProxySort, TunnelState } from '../entryability/ClashViewModel';

export class ProviderList{
  data: Provider[]
}
interface Provider {
  name: string;
  type: ProviderType;
  vehicleType: VehicleType;
  updatedAt: number;
}
export enum ProviderType {
  Proxy = "Proxy",
  Rule = "Rule"
}
export enum VehicleType {
  HTTP = "HTTP",
  File = "File",
  Compatible = "Compatible"
}
export enum ClashRpcType{
  queryTunnelState = 1,
  queryTrafficTotal = 2,
  queryProxyGroupNames = 3,
  queryProxyGroup = 4,
  queryProviders = 5,
  patchSelector = 6,
  healthCheck = 7,
  updateProvider = 8,
  queryOverride = 9,
  patchOverride = 10,
  clearOverride = 11,
  setLogObserver = 12,
  queryConfiguration = 13,
  load = 14,
}
export interface IClashManager {
  queryTunnelState(): Promise<TunnelState>;
  queryTrafficTotal(): Promise<number>;
  queryProxyGroupNames(excludeNotSelectable: boolean): Promise<string[]>;
  queryProxyGroup(name: string, proxySort: ProxySort): Promise<ProxyGroup>;
  queryConfiguration(): Promise<string>;
  queryProviders(): Promise<ProviderList>;

  patchSelector(group: string, name: string): Promise<boolean>;

  healthCheck(group: string): Promise<void>;
  updateProvider(type: ProviderType, name: string): Promise<void>;

  queryOverride(slot: OverrideSlot): Promise<ConfigurationOverride>;
  patchOverride(slot: OverrideSlot, configuration: ConfigurationOverride): Promise<void>;
  clearOverride(slot: OverrideSlot): Promise<void>;
  load(path: string): Promise<void>;
  // setLogObserver(observer: ILogObserver | null): Promise<void>;
}