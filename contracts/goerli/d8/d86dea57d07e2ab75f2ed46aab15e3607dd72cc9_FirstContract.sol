/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;

contract FirstContract {
    string greeting;
    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
    function getGreeting() public view returns(string memory) {
        return greeting;
    }
}