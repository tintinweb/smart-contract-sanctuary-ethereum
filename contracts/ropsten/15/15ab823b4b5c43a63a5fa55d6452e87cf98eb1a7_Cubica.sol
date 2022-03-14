/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Cubica {

    struct File {
        uint256 _id;
        string name;
        string data;
    }
    uint256 storedFileCount = 0;
    address ownerAddress;
    mapping(address => File[]) filesArr;

    constructor() {
        ownerAddress = msg.sender;
    }

    function store(string memory fileName , string memory fileData) public {
        storedFileCount += 1;
        filesArr[msg.sender].push(File(storedFileCount , fileName , fileData));
    }

    function retrieveFiles(address _ownerAddress) public view returns (File[] memory) {
        return filesArr[_ownerAddress];
    }
}