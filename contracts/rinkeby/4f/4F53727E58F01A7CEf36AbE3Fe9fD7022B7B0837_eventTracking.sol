// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.13;

contract eventTracking {
    event Stored(uint _id, uint _password);
    mapping (uint => uint) public data;

    function getData(uint _id, uint _password) public {
        data[_id] = _password;
        
        emit Stored(_id, _password);
    } 
}