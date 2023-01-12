// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract King {

    function iAmKing() payable external  {
        (bool success, bytes memory data) = payable(0x6a325eb80CC9E71bf0D091e9d742Bb1016f2357C).call{value: msg.value}("");
        require(success, string(data));
    }

    receive() external payable {
        (bool success, bytes memory data) = payable(0x6a325eb80CC9E71bf0D091e9d742Bb1016f2357C).call{value: msg.value + 1}("");
        require(success, string(data));
    }
}