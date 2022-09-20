/**
 *Submitted for verification at Etherscan.io on 2022-09-20
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

    function getNumber()external view returns(uint){
        return number;
    }
    function setNumber(uint _number)external {
        number = _number;
    }
    function getBalance()external view returns(uint){
        return address(this).balance;
    }
    function transferEther()external payable {
        payable(address(this)).transfer(msg.value);
    }
    function transferOwner(address payable _to)external ownerOnly(_to) {
        _to.transfer(address(this).balance);
    }
}