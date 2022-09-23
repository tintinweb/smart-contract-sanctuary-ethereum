/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract a {
    string name;
    string [] array;

    function push(string memory name) public {
        array.push(name);
    }

     function get(uint n) public view returns(string memory){
        return array[n];
    }

    function lastget() public view returns(uint){
        return array.length;
    }

}