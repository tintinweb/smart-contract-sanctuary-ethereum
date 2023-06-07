// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/*
Verify on Etherscan
1. Activate Etherscan plugin
2. Deploy contract
3. Verify with Etherscan plugin
4. Check contract is verified at etherscan.io
*/

/*
# Verify on Etherscan
1. Deploy contract
2. Check contract at etherscan
3. Activate Etherscan plugin
4. Get API key
5. Verify with Etherscan plugin (get hex encoded constructor args from etherscan)
6. Re-check contract is verified at etherscan
*/

contract TestVerifyContract {
    uint public arg1;
    uint public arg2;

    constructor(uint _arg1, uint _arg2) {
        arg1 = _arg1;
        arg2 = _arg2;
    }
}