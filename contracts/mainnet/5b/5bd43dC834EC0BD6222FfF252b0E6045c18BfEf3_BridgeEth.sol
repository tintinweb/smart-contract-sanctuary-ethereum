// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BridgeBase.sol';

contract BridgeEth is BridgeBase {
 
 /* passa o endereço do tokenEth para o construtor
 e passa esse endereço para o construtor da bridgeBase
 */
  constructor(address token) BridgeBase(token) {}
}