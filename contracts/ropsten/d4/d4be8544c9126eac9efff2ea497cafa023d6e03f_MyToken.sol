//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

import "ERC20.sol";

contract MyToken is ERC20 {
    uint256 constant _initial_supply = 1000 * (10**18);

    constructor() ERC20("MyToken", "MYT") {
        _mint(msg.sender, _initial_supply);
    }
}