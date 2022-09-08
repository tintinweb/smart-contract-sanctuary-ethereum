/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: GPL-3.0  
pragma solidity ^0.8.16;  
contract List {     
    address addr;     
    address[] addrList;     
    mapping(address => bool) addrMap;       
    struct balancePair{         
        address holder;         
        uint balance;     
    }       
    function getBalance(address _addr) public view returns (uint ){
                 return _addr.balance;     
    }     
    function get() public view returns (address[] memory){
        return addrList;     
    } 
    // function getAll() public view returns (balancePair[] memory){ 
        // uint i=0; 
        // balancePair[] memory balanceArray;
        // for(i;i<addrList.length;i++){
                // balanceArray[i].holder = addrList[i];
                // balanceArray[i].balance = addrList[i].balance;
            // } 
            // return balanceArray; 
        // }
    function manipulateArrayMap(address[] memory _addr) public {
        // addr = _addr;
        for(uint i=0;i<_addr.length;i++){

            if (!addrMap[_addr[i]]){
                addrMap[_addr[i]] = true;
                addrList.push(_addr[i]);
            }    
 
        }
    }
}