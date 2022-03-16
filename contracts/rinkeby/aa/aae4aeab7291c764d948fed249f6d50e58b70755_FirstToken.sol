// contracts/OurToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";

contract FirstToken is ERC20 {
    // wei
    constructor(uint256 initialSupply) ERC20("ThirdToken", "TT") {
        _mint(msg.sender, initialSupply);
    }
    
}