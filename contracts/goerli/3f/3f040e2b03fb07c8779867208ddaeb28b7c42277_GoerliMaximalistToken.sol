// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";


contract GoerliMaximalistToken is ERC20 {
    constructor() ERC20("GoerliMaximalistToken", "GMT") {
    }


    function claim() public {
        _mint(msg.sender, 6942000000000000000000);
    }

}