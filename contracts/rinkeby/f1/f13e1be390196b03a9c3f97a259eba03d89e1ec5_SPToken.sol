// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Token.sol";

contract SPToken is Token{
    string constant public name = "SPToken";
    uint8 constant public decimals = 3;
    string constant public symbol = "SPT";
    uint256 constant public totalSupply = 10**10;

    constructor(){
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

}