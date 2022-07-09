/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

/**
 *Submitted for verification at polygonscan.com on 2022-07-07
*/

/*
  Copyright (c) 2015-2016 Oraclize SRL
  Copyright (c) 2016 Oraclize LTD
*/

pragma solidity >= 0.4.0 < 0.5.0;


contract OraclizeAddrResolver {

    address public addr;
    
    address owner;
    
    function OraclizeAddrResolver(){
        owner = msg.sender;
    }
    
    function changeOwner(address newowner){
        if (msg.sender != owner) throw;
        owner = newowner;
    }
    
    function getAddress() returns (address oaddr){
        return addr;
    }
    
    function setAddr(address newaddr){
        if (msg.sender != owner) throw;
        addr = newaddr;
    }
    
}