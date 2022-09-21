/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

contract HelloWorld {

    string text_ = "Hello Encode!";


    function helloworld () public view returns(string memory){
        return text_;
        
    }

    function setText(string memory newText) public {
        text_ = newText;
    }

}