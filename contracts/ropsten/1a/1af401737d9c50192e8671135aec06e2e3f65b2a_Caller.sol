/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Caller{

    function callOther(address addr,string memory name) public returns(string memory){
        Testcontract c = Testcontract(addr);
        return c.getData(name);
    }
}

interface Testcontract {
    function getData(string memory) external returns(string memory); 
}