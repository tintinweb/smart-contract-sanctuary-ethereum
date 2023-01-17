// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import ".//ERC20.sol";

contract SDKToken is ERC20 {
    constructor() public ERC20("SDKTestToken", "SDKT") {
        _mint(msg.sender, 100000000 * 10**18);
    }
}