//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ERC20.sol";

contract MyERC20Token_1 is ERC20 {
    uint constant _initial_supply = 10000 * (10**18);
    constructor() ERC20("MyERC20Token_1", "MyERC20_1") public {
        _mint(msg.sender, _initial_supply);
    }
}