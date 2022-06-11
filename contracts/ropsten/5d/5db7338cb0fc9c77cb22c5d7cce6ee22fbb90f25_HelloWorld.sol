/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld{

    string public greet = "GG";

    function getGreet() public view returns(string memory)
    {
        return greet;
    }

}