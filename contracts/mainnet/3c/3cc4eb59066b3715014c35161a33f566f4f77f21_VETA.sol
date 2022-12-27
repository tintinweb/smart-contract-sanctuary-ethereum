// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";

contract VETA is ERC20("VetAPP", "VETA") {

  /**
  * @param wallet Address of the wallet, where tokens will be transferred to
  */
  constructor(address wallet) {
    _mint(wallet, uint256(500000000) * 1 ether);
  }
}