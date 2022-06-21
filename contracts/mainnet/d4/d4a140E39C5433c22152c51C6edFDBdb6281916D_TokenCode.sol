// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TokenCode is ERC20 {

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
    constructor(address receivingAddress) ERC20("GLT", "GLT") {
        _mint(receivingAddress,  300*10**10);
    }
}