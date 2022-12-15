/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Hoffnung {

    string count = "Hoffnung means Hope in German";

    function my_function() public view returns(string memory){
        return count;
    }
}