//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
contract Force {
mapping(address=>uint) addressIndexes;
address[] addresses=[0xA3C007E9297E072d723C14b6c44360c8975A7081,0x4f076Ce882734d25AF934B622C01da68f393E006,0x47FF8226634BBdd349849e4CB3cd5961fE61f168];

function remove(address _address) public{
addresses[addressIndexes[_address]]=addresses[addresses.length-1];
addresses.pop();
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