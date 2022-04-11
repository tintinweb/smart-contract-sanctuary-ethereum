/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.8.0;

contract hello {
    string name = "zzz";

    function changeName(string memory n) public {
        name = n;
    }

    function getName() public view returns(string memory) {
        return name;
    }
}