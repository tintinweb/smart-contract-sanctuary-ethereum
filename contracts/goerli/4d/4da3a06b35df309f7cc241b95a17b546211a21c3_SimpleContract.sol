/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract SimpleContract {
    address public deployer;
    bytes32 public hashedAddress = 0xc031855f9b7b2efeebeb951525a45554e0e3a2bcd9b539485a8a15fdfbbf3908;

    constructor() {
        deployer = msg.sender;
    }

    function isDeployer() external view returns (bool) {
        return msg.sender == deployer;
    }

    function hasHashedAddress() external view returns (bool) {
        return keccak256(abi.encodePacked(msg.sender)) == hashedAddress;
    }
}