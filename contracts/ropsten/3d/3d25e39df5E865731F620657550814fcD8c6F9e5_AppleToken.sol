// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";

contract AppleToken is ERC20 {

    uint8 constant _decimals = 18;
    uint256 constant _totalSupply = 100 * (10**6) * 10**_decimals;  // 100m tokens for distribution

    constructor() ERC20("Apple", "APL") {        
        _mint(msg.sender, _totalSupply);
    }
}