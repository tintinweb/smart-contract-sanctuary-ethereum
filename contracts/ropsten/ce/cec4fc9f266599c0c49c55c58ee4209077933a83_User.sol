/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract User{
    mapping(address => string) public name;
    mapping(address => string) public nickName;
    mapping(address => string) public _address;
    mapping(address => string) public nameOfWork;
    mapping(address => string) public typeOfWork;
    mapping(address => uint32) public date;

    function upload(string memory _name,string memory _nickName,string memory __address, string memory _nameOfWork, string memory _typeOfWork, uint32 _date) public {
        address user = msg.sender;
        name[user] = _name;
        nickName[user] = _nickName;
        _address[user] = __address;
        nameOfWork[user] = _nameOfWork;
        typeOfWork[user] = _typeOfWork;
        date[user] = _date;
    }
}