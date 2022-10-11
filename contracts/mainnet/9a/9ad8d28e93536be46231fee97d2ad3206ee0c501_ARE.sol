// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC20.sol";

contract ARE is ERC20("Arealeum", "ARE") {

  /**
  * @param wallet Address of the wallet, where tokens will be transferred to
  */
  constructor(address wallet) {
    _mint(wallet, uint256(3050000000) * 1 ether);
    // save owner address to receive fee from each tx in future
    _setOwner(wallet);
  }
}