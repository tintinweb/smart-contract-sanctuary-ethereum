/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
/**
    a simple study case
 */
contract SimpleStorage {
    uint storedData;

    //set function
    function set(uint x) public {
        storedData = x;
    }

    //get function
    function get() public view returns (uint) {
        return storedData;
    }

    function hello() public pure returns(string memory){
        return "Hello World";
    }

    function say() public returns(string memory){
        return "this is say";
    }
   
}