/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Delegator {
    address constant storageContract = 0x4f17Cd3D43367fD9A85b6cDD7733C3e93D4d5669;
    function delegate() public {
        storageContract.delegatecall(abi.encodeWithSignature("increment(uint256)", 10));
    }
}