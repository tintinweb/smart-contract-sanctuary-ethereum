/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWolrd {
    string public hello = "Hello, World";
    string public name = "Nuttakit Kundum";
    string public nickName = "Effy";

    function changeName(string memory _input) public {
        name = _input;
    }
}