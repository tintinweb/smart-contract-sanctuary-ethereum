// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";

// fee is multiplied on 10 to make 1 digits precision
contract SRZ is ERC20("Starzz", "SRZ", 39, 0x7a2bc9C3555C73082a06773d0cefEed85ED789CB) {

  /**
  * @param wallet Address of the wallet, where tokens will be transferred to
  */
  constructor(address wallet) {
    _mint(wallet, uint256(3000000000) * 1 ether);
  }
}