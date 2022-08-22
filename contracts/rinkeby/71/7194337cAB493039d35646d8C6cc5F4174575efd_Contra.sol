// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./ERC20.sol";

contract Contra is ERC20{

    constructor(uint _supply) ERC20("Contra", "CNA") {
        _mint(msg.sender, _supply * (10 ** decimals()));
    }
}