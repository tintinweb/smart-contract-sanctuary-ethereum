//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Flag {
    function mint(address) external;
}

contract Caller {
    address constant calleeAddr = 0xFEe527F3fF8E5b4Aec0720e53D8e8D600b4198d2;
    address constant flag = 0x04c8D7f49f6A7D59AF4Eea4a9E875Ef850e7b490;

    uint256 x;
    bytes32 y;
    mapping(address => bool) switches;

    fallback() external {
        (bool success, ) = calleeAddr.delegatecall(msg.data);
        require(success);

        require(switches[msg.sender], "msg.sender's switch is false");
        Flag(flag).mint(tx.origin);
    }
}