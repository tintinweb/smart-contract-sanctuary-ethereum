//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";

contract MINKtoken is ERC20, Ownable {
    constructor(uint256 totalSupply) ERC20("MINK", "MINK") {
        _mint(owner(), totalSupply);
    }

    function decimals() public view override returns (uint8) {
        return 3;
    }
}