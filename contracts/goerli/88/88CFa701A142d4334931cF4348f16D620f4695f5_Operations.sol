// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Operations {

   mapping(address => uint) public balances;

    function deposit(uint256 _amount) public {
        balances[msg.sender] = _amount;
        emit DepositEvent(_amount, msg.sender);
    }


    function transfer(uint256 _sendAmount, address _to) public {
        require(balances[msg.sender] >= _sendAmount, "Not enough to transfer");
        balances[msg.sender] = balances[msg.sender] - _sendAmount;
        balances[_to] = balances[_to] + _sendAmount;
        emit TransferEvent(_sendAmount, msg.sender, _to);
    }

    event DepositEvent(uint256 deposited, address account);
    event TransferEvent(uint256 transferred, address sender, address receiver);


}