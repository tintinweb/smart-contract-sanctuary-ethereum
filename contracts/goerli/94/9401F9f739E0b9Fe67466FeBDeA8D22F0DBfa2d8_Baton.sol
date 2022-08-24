// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./ERC20.sol";

// Just verify please!!!
contract Baton is ERC20 {
    constructor() ERC20("Baton", "BTON") {}

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}