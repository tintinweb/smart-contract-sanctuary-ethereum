// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract whiteList{
    struct ListMap {
        mapping(address => uint8) list;
        address[] addrList;
    }
    address public owner;

    ListMap listMap;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr!= address(0), "No-valid Address");
        _;
    }

    function setMem(address _addr, uint8 _n) public isOwner validAddress(_addr) returns(bool) {
        //list[_addr] = _n;
        uint8 value = listMap.list[_addr];
        listMap.list[_addr] = _n;
        if(value == 0 && _n > 0) {
            listMap.addrList.push(_addr);
        }
        return true;
    }

    function getMem(address _addr) public view validAddress(_addr) returns(uint8) {
        return listMap.list[_addr];
    }

    function getList() public view isOwner returns(address[] memory){
        return listMap.addrList;
    }
}