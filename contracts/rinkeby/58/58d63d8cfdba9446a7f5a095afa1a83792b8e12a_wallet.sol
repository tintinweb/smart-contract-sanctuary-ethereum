/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract wallet {
    uint256 walletValue;

    constructor() {
    }

    function incrementWalletValue() public {
        walletValue +=1;
    }

    function getWalletValue() public view returns (uint256) {
        return walletValue;
    }
}