/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Token {
    address private owner;
    string public constant name = "KirToken";
    uint private totalSupply;
    mapping(address => uint256) private balance;

    constructor(uint256 _totalSupply) {
        owner = msg.sender;
        totalSupply = _totalSupply;
        balance[owner] += totalSupply;
    }

    function transfer(uint256 _amount, address _to) external {
        require(balance[msg.sender] >= _amount, "Not enough funds");
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
    }

    function balanceOf(address _address)
        external
        view
        returns (uint256 result)
    {
        result = balance[_address];
    }

    function getTotalSupply() external view returns (uint256 _totalSupply) {
        _totalSupply = totalSupply;
    }
}