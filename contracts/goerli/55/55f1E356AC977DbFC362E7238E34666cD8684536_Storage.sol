// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Storage {
    string public information;

    function setInformation(string memory _information) public {
        information = _information;
    }

    function getInformation() public view returns (string memory) {
        return information;
    }
}