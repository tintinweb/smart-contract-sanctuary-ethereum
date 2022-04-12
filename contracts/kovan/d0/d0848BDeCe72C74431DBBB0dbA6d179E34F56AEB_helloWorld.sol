/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.1;
contract helloWorld{
    string a="Hello World!";
    function print() public view returns(string memory){
        return a;
    }
}