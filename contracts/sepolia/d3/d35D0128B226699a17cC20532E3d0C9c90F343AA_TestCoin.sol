// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract TestCoin is ERC20, Ownable {
    constructor() ERC20("TestCoin", "$TEST") {
        _mint(msg.sender, 21000000000 * 10 ** decimals());
    }
}