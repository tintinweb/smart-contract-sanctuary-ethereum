// SPDX-License-Identifier: MIT

// Version
pragma solidity ^0.8.4;

import "./ERC_20.sol";
import "./Context.sol";
import "./Ownable.sol";

contract Verse is Context, Ownable, ERC20{
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) ERC20(_name, _symbol){
        _mint(_msgSender(), _totalSupply * (uint256(10) ** 18));
        _setOwner(0x3B4AA53193396615c201a4bB47a655CbA9176D2b);
    }
}