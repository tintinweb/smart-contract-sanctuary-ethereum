// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Mun is ERC20, ERC20Burnable {
    constructor() ERC20("Mun", "JSM") {
        _mint(msg.sender, 2400000000000 * 10 ** decimals());
    }
}