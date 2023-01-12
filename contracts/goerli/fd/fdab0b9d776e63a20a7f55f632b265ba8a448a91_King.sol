// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract King {

    function iAmKing() external  {
        (bool success,) = payable(0x6a325eb80CC9E71bf0D091e9d742Bb1016f2357C).call{value: 1000000000000001}("");
        if (!success) {
            revert();
        }
    }

    receive() external payable {
        (bool success,) = payable(0x6a325eb80CC9E71bf0D091e9d742Bb1016f2357C).call{value: msg.value + 1}("");
        if (!success) {
            revert();
        }
    }
}