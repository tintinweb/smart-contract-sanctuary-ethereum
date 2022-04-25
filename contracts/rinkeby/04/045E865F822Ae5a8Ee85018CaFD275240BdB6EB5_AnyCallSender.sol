//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface CallProxy {
  function anyCall(
    address _to,
    bytes calldata _data,
    address _fallback,
    uint256 _toChainID
  ) external;
}

contract AnyCallSender {
  CallProxy public immutable CALLPROXY_BSCTESTNET = CallProxy(0x1FF2e90F22dA39d5cB5748AB786C5AD6D9eBa440);
  CallProxy public immutable CALLPROXY_RINKEBY = CallProxy(0xf8a363Cf116b6B633faEDF66848ED52895CE703b);

  uint256 public immutable CHAINID_BSCTESTNET = 97;
  uint256 public immutable CHAINID_RINKEBY = 4;

  function inc(address _callProxy, address _to, address _fallback, uint256 _toChainID) external {
    CallProxy(_callProxy).anyCall(
      _to,
      abi.encodeWithSignature("inc()"),
      _fallback,
      _toChainID
    );
  }
}