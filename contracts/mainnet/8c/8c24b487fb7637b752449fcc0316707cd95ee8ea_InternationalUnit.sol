// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract InternationalUnit is ERC20, Ownable {
    constructor() ERC20("International Unit", "ITUT") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}