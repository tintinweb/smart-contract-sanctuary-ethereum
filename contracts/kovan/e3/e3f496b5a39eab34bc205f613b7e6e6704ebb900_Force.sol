//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
contract Force {
mapping(address=>uint) addressIndexes;
address[] addresses;

function remove(address _address) public{
addresses[addressIndexes[_address]]=addresses[addresses.length-1];
}

function add(address _adr) public{
   addresses.push(_adr); 
}
function get(address _adr) public view returns( uint ){
    return addressIndexes[_adr];
}
function get1(uint number) public view returns( address ){
    return addresses[number];
}
}