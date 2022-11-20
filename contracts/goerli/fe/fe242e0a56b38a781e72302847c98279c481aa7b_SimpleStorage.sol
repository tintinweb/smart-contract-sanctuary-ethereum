/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0

pragma solidity >=0.7.0 <0.9.0;

contract SimpleStorage{

    uint storeData;

    function set(uint k) public {

        storeData = k;
    }

    function get() public view returns(uint){

        return storeData;
    }
    
}