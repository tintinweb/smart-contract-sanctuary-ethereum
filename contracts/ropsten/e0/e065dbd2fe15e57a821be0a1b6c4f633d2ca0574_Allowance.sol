//SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;


contract Allowance  {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    event AllowanceChanged(address indexed _forWho, address indexed _byWhom, uint _oldAmount, uint _newAmount);

    mapping(address => uint) allowance;

    function isOwner() public view returns(bool) {
        return msg.sender == owner;
    }
    

    modifier allowedWithdraw(uint _amount) {
        require(isOwner() || allowance[msg.sender] >= _amount, "You are not allowed");
        _;
    }


    function reduceAllowance(address _address, uint _amount) internal allowedWithdraw(_amount) {
        allowance[_address] -= _amount;
        emit AllowanceChanged(_address, msg.sender, allowance[_address], allowance[_address] - _amount);
    }

    function getMyBalance() public view returns(uint) {
        return allowance[msg.sender];
    }

    function addAllowance(address _address, uint _amount) internal {
        allowance[_address] = _amount;
        emit AllowanceChanged(_address, msg.sender, 0, _amount);
    }

}