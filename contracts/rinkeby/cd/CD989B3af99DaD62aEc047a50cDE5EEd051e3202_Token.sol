// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity >=0.8.0 <0.9.0;

contract Token{
    address private owner;

    string public constant name = "MyToken";

    uint private totalSupply;

    mapping(address => uint) private balances;

    constructor(uint _totalSupply){
        owner = msg.sender;
        totalSupply = _totalSupply;
        balances[owner] += totalSupply;
    }

    function transfer(uint _amount, address _to) external{
        require(balances[msg.sender] >= _amount, "Insufficient Amount");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
    }

    function balanceOf(address _to) external view returns (uint _balance){
        _balance = balances[_to];
    }

    function getTotalSupply() external view returns (uint _supply) {
        _supply = totalSupply;
    }
}