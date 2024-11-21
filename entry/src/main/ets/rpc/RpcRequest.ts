export  class CommonConstants{
  static  IP_ADDRESS = "127.0.0.1"
  static  IP_PORT = 13245
  static  TCP_CONNECT_TIMEOUT = 10000
}


export interface RpcRequest {
  method: number;
  params: (string | number | boolean) [];
}

export interface RpcResult {
  result?: string | number | boolean ;
  error?: string;
}