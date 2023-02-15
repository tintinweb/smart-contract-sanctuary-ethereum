/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImplementationContract {
    bool initialized;
    uint32 nonce;
    event Log(uint32);

    //initializer function that will be called once, during deployment.
    function initializer() external {
        require(!initialized);
        initialized = true;
        nonce = 2;
        nonce++;
    }

    function getNonce() external returns (uint32) {
        nonce++;
        emit Log(nonce);
        return nonce;
    }
}