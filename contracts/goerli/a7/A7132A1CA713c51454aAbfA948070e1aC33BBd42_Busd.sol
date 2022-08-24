// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./ERC20.sol";

// Just verify please!!!
contract Busd is ERC20 {
    constructor() ERC20("Busd", "BUSD") {}

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}