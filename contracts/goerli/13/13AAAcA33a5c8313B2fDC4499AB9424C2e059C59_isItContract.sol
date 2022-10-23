//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract isItContract{
    // this function gets the address of a contract
    function contractAddress() public view returns (address) {  
       address theAddress = address(this); //contract address  
       return theAddress;  
    }

    // these functions check if the address is a smartcontract 
    
    // method 1
    function checkContract(address addr) public view returns (bool) {
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    bytes32 codehash;
    assembly {
        codehash := extcodehash(addr)
    }
    return (codehash != 0x0 && codehash != accountHash);
    }
    
    // method 2
    function isContract(address addr) public view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
    }
}