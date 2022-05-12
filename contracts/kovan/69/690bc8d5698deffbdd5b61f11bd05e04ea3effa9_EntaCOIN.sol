/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.4.20;

contract EntaCOIN {


    address public owner = msg.sender;
    string public NomeToken;
    string public TagToken;

    mapping (address => uint256) public balanceOf;

    function EntaCOIN(uint256 initialSupply, string _NomeToken, string _TagToken) public {
        balanceOf[owner] = initialSupply;
        NomeToken = _NomeToken;
        TagToken = _TagToken;
    }
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        return true;
    }
}