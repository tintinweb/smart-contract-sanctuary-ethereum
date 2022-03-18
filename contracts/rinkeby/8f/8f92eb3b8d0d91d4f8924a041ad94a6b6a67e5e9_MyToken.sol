pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./ManyFile.sol";

//SPDX-License-Identifier: MIT

contract MyToken is ERC20 {
    using SafeMath for uint256;
    constructor(uint256 initialSupply) ERC20("My Token", "MT") {
         _mint(msg.sender, initialSupply.mul(10**18));
    }
}