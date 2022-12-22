/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

contract Attempter {
    function attempt() external {
        (bool success,) = 0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502.call(abi.encodeWithSignature("attempt()"));
        require(success);
    }
}