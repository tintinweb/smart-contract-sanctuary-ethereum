//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Boom {
  fallback() external payable {
    selfdestruct(0x7474658eDA4B4A635Cb13941E7b7f285eaB2e686);
  }
}