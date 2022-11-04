// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// openzeppelin ERC777 Token
import "./ERC777.sol";

contract styleToken is ERC777 {
    
    constructor(
        uint256 initialSupply,//920000000
        address[] memory defaultOperators
    )
        ERC777("STYLE Protocol", "STYLE", defaultOperators)
    {
        _mint(msg.sender, initialSupply, "", "");
    }
}