/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract KeepYourName2 {
    string private yourname;

    constructor(string memory _greeting) {
        yourname = _greeting;
    }

    function getName() public view returns (string memory) {
        return yourname;
    }

    function setName(string memory fullname) public {
        yourname = fullname;
    }

    function setName(string memory first, string memory last) public {
        yourname = string(abi.encodePacked(first, last));
    }
}