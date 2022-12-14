// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";

contract PNE is ERC20("Decarbonice", "PNE") {

  /**
  * @param wallet Address of the wallet, where tokens will be transferred to
  */
  constructor(address wallet) {
    _mint(wallet, uint256(240540540) * 1 ether);
  }
}