/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Testament{

address public _manager;
mapping(address=>address) _heir;   // _ is private variable
mapping(address=>uint) _balance;
event Create(address indexed owner, address indexed heir, uint amount);
event Report(address indexed owner, address indexed heir, uint amount);

constructor(){
    _manager = msg.sender;
}

//owner create testament
function create(address heir) public payable{   // no _ is public variable
    require(msg.value>0,"Please enter money greater than 0");
    require(_balance[msg.sender]<=0,"Testament already exists");
    _heir[msg.sender] = heir;
    _balance[msg.sender] = msg.value;
    emit Create(msg.sender, heir, msg.value);
}

function getTestament(address owner) public view returns(address heir, uint amount){
    return (_heir[owner], _balance[owner]);
}

function reportOfDeath(address owner) public{
    require(msg.sender == _manager, "Unauthorized, You are not manager.");
    require(_balance[owner]>0,"Have no Testament yet.");
    emit Report(owner, _heir[owner], _balance[owner]);
    payable(_heir[owner]).transfer(_balance[owner]);    //อ่านจากข้างหลังมาข้างหน้า

    _balance[owner] = 0;
    _heir[owner] = address(0);      // address(0) is reset to default 
}
}