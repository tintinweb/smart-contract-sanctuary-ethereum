/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Delegator {
    uint256 public i;
    constructor() {
        i = 0;
    }
    receive() external payable {}
    function delegate() public {
        address storageContract = 0x6A580320b9a5Ef47f16665693609eaa5561632FB;
        storageContract.delegatecall(abi.encodeWithSignature("increment(uint256)", 10));
    }
}