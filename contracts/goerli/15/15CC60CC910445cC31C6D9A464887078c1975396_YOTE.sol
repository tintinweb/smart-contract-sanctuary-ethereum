// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract YOTE is ERC20, ERC20Burnable {
    constructor() ERC20("YOTE", "YOTE") {
        _mint(msg.sender, 10000000000000 * 10 ** decimals());
    }
}