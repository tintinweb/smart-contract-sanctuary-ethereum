/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RandomTransactions {
    uint256 it = 1000;

    function start() external {
        uint256 _it = it;
        for (uint256 i; i < _it; ++i) {
            (bool success, ) = address(
                uint160(uint256(keccak256(abi.encodePacked(i))))
            ).call(abi.encodeWithSignature("func"));
            require(success);
        }
    }

    function setIt(uint256 _it) external {
        it = _it;
    }
}