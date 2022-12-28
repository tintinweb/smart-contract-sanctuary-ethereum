// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;


contract Call {
    address private CONTRACT_ADDRESS =
        0xcF469d3BEB3Fc24cEe979eFf83BE33ed50988502;

    function attempt() external {
        (bool s, ) = CONTRACT_ADDRESS.call(
            abi.encodeWithSignature("attempt()")
        );
        require(s, "Invalid attempt");
    }
}