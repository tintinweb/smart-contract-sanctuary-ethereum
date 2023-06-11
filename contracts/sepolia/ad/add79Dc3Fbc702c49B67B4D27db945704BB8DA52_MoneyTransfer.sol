//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MoneyTransfer {
    mapping(address => uint256) balances;

    event Transfer(address indexed from , address indexed to , uint256 amount);

    function transfer(address _to , uint256 _amount ) public payable {
        require(balances[msg.sender] >= _amount , "Insufficient balance");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender , _to , _amount);
    }

    function getBalance(address account) public view returns (uint256){
        return balances[account];
    }
}