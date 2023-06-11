// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ERC20.sol";


contract TestToken is ERC20 {

    constructor()
        ERC20("Test Token", "TEST")
    {
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

}