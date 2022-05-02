//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Flag {
    function mint(address) external;
}

contract Contract {
    address constant flag = 0x68CD31401aCada85d8d526bb348F88c5C988bB43;

    function capture() external {
        require(msg.sender != tx.origin, "msg.sender is equal to tx.origin");
        Flag(flag).mint(tx.origin);
    }
}