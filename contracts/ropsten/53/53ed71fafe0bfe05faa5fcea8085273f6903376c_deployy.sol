/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract deployy{
    string lastText = "deployment";

    function set(string memory text) public  {
        lastText = text;
    }

    function get() public view returns(string memory){
          return lastText;
    }
}