/**
 *Submitted for verification at Etherscan.io on 2023-03-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDATA {function _tokenData(uint256 tokenId_) external view returns (address);}

contract mintChecker {
    IDATA public DATA = IDATA(0x2D6fEA747C03a20391B472247eE0f1b19e5e9144);
    function checkOwners() public view returns (bool[365] memory) {
        bool[365] memory ownerStatuses;
        for (uint256 i = 1; i <= 365; i++) {
        if (DATA._tokenData(i) == address(0)) {
            ownerStatuses[i - 1] = false;
        } else {
            ownerStatuses[i - 1] = true;
        }
    }
    return ownerStatuses;
    }
}