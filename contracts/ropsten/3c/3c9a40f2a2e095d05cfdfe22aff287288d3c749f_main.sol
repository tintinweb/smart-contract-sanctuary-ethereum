/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

//SPDX-Licence-Identifier: MIT

pragma solidity ^0.8.14;
contract main

{
    mapping (address => bool) valid;
    mapping (address => uint) balance;
    function DepositMoney() public payable 
    {
        valid[msg.sender] = true;
        balance[msg.sender] += msg.value;
    }
    function AccountBalance() public view returns(uint)
    {
        require (valid[msg.sender] == true);
        return(balance[msg.sender]);
    }
    function SendMoney(uint Ammount,address payable Address)public payable
    {
        require(valid[msg.sender] == true);
        balance[msg.sender] -= Ammount;
        Address.transfer(Ammount);
    }
    function CloseAccount() public payable
    {
        require(valid[msg.sender] == true);
        address payable cus = payable(msg.sender);
        uint tempAmo = balance[msg.sender];
        balance[msg.sender] = 0;
        cus.transfer(tempAmo);
    } 
}