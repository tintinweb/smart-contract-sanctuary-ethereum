// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TsmToken is ERC20{
  constructor() ERC20("TSM Token", "TTK") {
    _mint(msg.sender, 1000 * 10 ** decimals());
  }
}