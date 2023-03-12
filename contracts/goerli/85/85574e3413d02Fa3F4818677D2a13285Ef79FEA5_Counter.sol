// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Counter {
    uint public counter;
    address public ownerAddress;

    constructor (uint _count){
        counter = _count;
        ownerAddress = msg.sender;
        
    }

    modifier Ower() {
        require(msg.sender == ownerAddress, "need ower address");
        _;
    }


    function count() public Ower {
        counter = counter + 1;
    }

    function add(uint x) public{
         counter = counter + x;
    }

}