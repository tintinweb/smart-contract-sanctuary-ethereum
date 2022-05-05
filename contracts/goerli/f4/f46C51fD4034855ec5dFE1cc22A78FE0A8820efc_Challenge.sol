// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Flag {
    function mint(address) external;
}

contract Challenge {
    address owner = 0x580468614Fa6D839e9e7f3bc5C325cEb67d7fFB1;
    address flag = 0xC95a07eADdEc282bFdF15e9422E88BE43f07D0b0;
    
    function capture() external {
        require(msg.sender == owner);
        Flag(flag).mint(tx.origin);
    }
}