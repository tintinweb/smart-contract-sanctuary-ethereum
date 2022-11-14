/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Counter {

    int256 number;      

    function storeTheNumber(int256 num) public  {  
        number = num;
    }
    function retrieveTheNumber() public view returns (int256){   
        return number;
    }
}