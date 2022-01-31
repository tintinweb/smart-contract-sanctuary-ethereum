/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.6.0;


contract IPFSupload {
    string public difference = "I_am_an_IPFS_hash";
    

    uint public myUint; //number of delivery

    
    function setMyUint(uint _myUint) public {
        myUint = _myUint;
    }
    
    
    function setIPFShash(string memory _difference) public { 
    difference = _difference;
    }
    
}