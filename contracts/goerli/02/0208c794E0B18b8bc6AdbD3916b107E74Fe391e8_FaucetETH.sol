/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract FaucetETH {
    receive() external payable {}

    mapping (address => bool) isFaucet;

    function faucet() external payable {
        require(isFaucet[msg.sender]==false, "Your address is already faucet!");

        if (address(this).balance > 100000000 gwei) {
            payable(address(msg.sender)).transfer(100000000 gwei);
        }
    }
}