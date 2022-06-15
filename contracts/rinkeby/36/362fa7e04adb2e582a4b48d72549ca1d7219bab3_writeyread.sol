/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract writeyread {
    string public saludo;

    function write(string memory _str) public {
        saludo = _str;
    }

    function read() public view returns (string memory) {
        return saludo;
    }

}