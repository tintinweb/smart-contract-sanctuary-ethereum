//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Flag {
    function mint(address) external;
}

contract Contract {
    address constant flag = 0xB10Aba8aE2BEC37cd6EE513DA1744Cc41295376c;

    function capture() external {
        require(msg.sender != tx.origin, "msg.sender is equal to tx.origin");
        Flag(flag).mint(tx.origin);
    }
}