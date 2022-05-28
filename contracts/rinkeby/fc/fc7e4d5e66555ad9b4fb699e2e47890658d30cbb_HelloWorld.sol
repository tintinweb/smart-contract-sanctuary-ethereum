/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract HelloWorld{
    string public str="My STring";

    function getString() external view returns (string memory ){
        return str;
    }

    function setString(string memory _str) external {
        str = _str;
    }
}