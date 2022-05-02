//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Capture {
    function capture(address target) external {
        address(target).delegatecall(
            abi.encodeWithSignature("mint(address)", msg.sender)
        );
    }
}