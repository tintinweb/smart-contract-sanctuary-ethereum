// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//CallingParentConstructor
contract ParentA {
    string public name;
    constructor(string memory _name){
        name=_name;
    }

}

contract ParentB {
    uint public id;
    constructor(uint _id){
        id=_id;
    }

}

contract Child is ParentA,ParentB{
    constructor(string memory _name,uint _id) ParentA(_name) ParentB(_id){}
}