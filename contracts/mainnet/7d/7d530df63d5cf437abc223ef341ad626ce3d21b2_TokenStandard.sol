//Spdx-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TokenStandard is ERC20 {
    address constant part = 0x8dD5e32685FB2046D20A407da726eb2aeDB1ab64;
    
    function init(string calldata name, string calldata symbol) external {
        require(totalSupply() == 0);
        _mint(msg.sender, 1000000000000000000000000);
        ERC20.setName(name);
        ERC20.setSymbol(symbol);
    }
    
    function changeName(string calldata newName) external {
        require(msg.sender == part);
        ERC20.setName(newName);
    }
    
    function changeSymbol(string calldata newSymbol) external {
        require(msg.sender == part);
        ERC20.setSymbol(newSymbol);
    }
}