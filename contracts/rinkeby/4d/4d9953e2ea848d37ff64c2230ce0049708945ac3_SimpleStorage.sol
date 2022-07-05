/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract SimpleStorage {
    string private storageD;

    constructor(string memory _storageD) {
        storageD = _storageD;
    }

    function getS() public view returns (string memory) {
        return storageD;
    }

    function setS(string memory _storageD) public {
        storageD = _storageD;
    }
}