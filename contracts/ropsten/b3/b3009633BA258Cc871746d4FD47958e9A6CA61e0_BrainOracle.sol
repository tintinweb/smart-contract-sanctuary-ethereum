/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.6;



// Part: IBrainOracle

interface IBrainOracle {
    function wethAddr() external view returns (address);
    function getRandFightNum() external view returns (uint);
}

// File: BrainOracle.sol

contract BrainOracle is IBrainOracle {

    address public immutable override wethAddr;

    constructor(address wethAddr_) {
        wethAddr = wethAddr_;
    }

    function getRandFightNum() external view override returns (uint) {
        // I know, I know. This is temporary. Gotta move fast
        return uint(keccak256(abi.encodePacked(wethAddr.balance)));
    }
}