/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract SamlpeContract{
    address private owner;
    uint number = 0;

    receive()external payable{}
    fallback()external payable{}

    constructor(){
        owner = msg.sender;
    }

    modifier ownerOnly(address _to) {
        require(_to == owner, "Owner Only");
        _;
    }

    function getNumber()public view returns(uint){
        return number;
    }
    function setNumber(uint _number)public {
        number = _number;
    }
    function addNumber(uint _add)public {
        number = number + _add;
    }
    function getBalance()public view returns(uint){
        return address(this).balance;
    }
    function transferEther()external payable {
        payable(address(this)).transfer(msg.value);
    }
    function transferOwner(address payable _to)external ownerOnly(_to) {
        _to.transfer(address(this).balance);
    }
}