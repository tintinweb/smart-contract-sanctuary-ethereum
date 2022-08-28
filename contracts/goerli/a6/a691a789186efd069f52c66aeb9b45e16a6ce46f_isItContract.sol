/**
 *Submitted for verification at Etherscan.io on 2022-08-28
*/

pragma solidity ^0.8.0;
contract isItContract {
    function contractAddress() public view returns (address) {  
       address contAddress = address(this); //contract address  
       return contAddress;  
    }  

    function checkContract(address addr) public view returns (bool) {
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;                                                                                             
        bytes32 codehash;
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}