//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20C.sol";

contract QAXHC is ERC20C {

    constructor() ERC20C("QAXHC", "QXC") {
        _mint(msg.sender, 0);
    }

    function decimals() public view virtual override returns (uint8) {
        return 2;
    }
}