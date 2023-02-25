// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";
import "./ERC20Burnable.sol";


contract YOTETESTE is ERC20, ERC20Burnable {
    constructor() ERC20("YOTETESTE", "YOTE") {
        _mint(msg.sender, 10000000000000 * 10 ** decimals());
    }
}