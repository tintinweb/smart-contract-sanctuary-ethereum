/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IHackRand {
    function predict(bytes32 x) external;
}

contract Interaction {

    address shadelingAddr = 0x3362E3753eb6CF14ab0ef3c27E22860Aa2cf8371;

    function setShadelingAddr(address _shadeling) public {
       shadelingAddr = _shadeling;
    }

    function hackRand() external {
        bytes32 x = keccak256(abi.encode(block.timestamp));
        IHackRand(shadelingAddr).predict(x);
    }
}