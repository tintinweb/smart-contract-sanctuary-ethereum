/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract Storage {

    string private name;

    function setName (string memory newName) public {
        name = newName;
    }

    function getName() public view returns (string memory) {
        return name;
    }

}