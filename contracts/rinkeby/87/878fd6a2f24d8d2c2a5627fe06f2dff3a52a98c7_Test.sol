/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Test {
    address public constant WITHDRAW_ADDRESS = 0x179c8205800a243B8A6f9153DE47DeD6560d4eb8;

    function withdraw() external {
        require(
            WITHDRAW_ADDRESS != address(0),
            "WITHDRAW_ADDRESS shouldn't be 0"
        );
        (bool sent, ) = WITHDRAW_ADDRESS.call{value: address(this).balance}("");
        require(sent, "failed to move fund to WITHDRAW_ADDRESS contract");
    }

    function receiveEther() external payable {
    }

    function balance() external view returns(uint) {
        return address(this).balance;
    }
}