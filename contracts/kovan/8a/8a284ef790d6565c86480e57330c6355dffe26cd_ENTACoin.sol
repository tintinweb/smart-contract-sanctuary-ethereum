/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;
pragma abicoder v2;

contract ENTACoin {

    address public owner = msg.sender;

    string public tokenName;
    string public tokenTag;

    mapping (address => uint256) public balanceOf;

    function ETC(uint256 initialBalance, string memory _tokenName, string memory _tokenTag) public{

        balanceOf[owner] = initialBalance;
        tokenName= _tokenName;
        tokenTag = _tokenTag;
    }

    function transfer(address _to, uint256 _amount) public returns (bool success){
        
        require (balanceOf[msg.sender] >= _amount);
        require (balanceOf[_to] + _amount >= balanceOf[_to]);

        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        return true;
    }


}