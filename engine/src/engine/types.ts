import type {Platform} from '../data/clients';
export type Policy=string; // PROXY | DIRECT | REJECT | HOME | R:HK ...
export type Location='cn'|'hk'|'mo'|'tw'|'overseas';
export type Network='mobile'|'telecom'|'unicom'|'cellular'|'campus'|'company'|'overseas'|'other';
export interface CustomSet{id:string;name:string;url:string;kind:'domain'|'ip'|'classical';policy:Policy}
export interface SubItem{name:string;url:string}
export interface AppRoute{id:string;kind:'preset'|'package'|'process'|'domain';value:string;label:string;policy:Policy}
export interface Opts{
  ipv6:boolean;tun:boolean;mtu:number;mixedPort:number;apiPort:number;secret:string;logLevel:'warning'|'info'|'debug'|'error';
  allowLan:boolean;
  dnsCn:string[];dnsRemote:string[];fakeIp:boolean;
  blockQuic:'foreign'|'off';stun:'proxy'|'reject'|'off';
  unknown:'proxy'|'direct';ads:'off'|'lite'|'full';telemetry:boolean;trackers:boolean;icons:boolean;
  lowMemory:boolean;keepAlive:boolean;testUrl:string;urlTestInterval:number;
  campusDomain:string;campusCidr:string;homeDomain:string;lanGateway:string;lanDns:string;
  wifiCalling:boolean;mcc:string;mnc:string;wifiRegion:string;
  tunStack:'mixed'|'gvisor'|'system';
  panelOrigins:string[];
  nodeInclude:string;nodeExclude:string;lbGroup:boolean;tolerance:number;failover:boolean;
}
export interface State{
  client:string;platform:Platform;location:Location;network:Network;
  subs:SubItem[];nodesText:string;nodeMode?:'config'|'app';manualNodes?:import('./manual').ManualNode[];
  regions:string[];
  groups:Record<string,{on:boolean;policy:Policy}>;
  apps:AppRoute[];customDomains:{domain:string;policy:Policy}[];
  opts:Opts;
  customSets?:CustomSet[];
  wifi?:{ids:string[];custom:{mcc:string;mnc:string}[];extra:string};
  modules?:ModItem[];mitmHosts?:string;rewrites?:UserRewrite[];
  customRegions?:{id:string;name:string;regex:string}[];
}
export type ModKind='adblock'|'rewrite'|'enhance'|'routing'|'other';
export interface ModItem{id:string;name:string;url:string;content:string;kind:ModKind;on:boolean}
export interface UserRewrite{id:string;pattern:string;action:'reject'|'reject-200'|'reject-img'|'reject-dict'|'302'|'307';target:string;on:boolean}
