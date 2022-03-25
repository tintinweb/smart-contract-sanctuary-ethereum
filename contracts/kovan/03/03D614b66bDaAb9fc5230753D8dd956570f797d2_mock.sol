// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.8;

contract mock {
    event Sync(uint112 reserve0, uint112 reserve1);

    uint112 private reserve0 = 100;           
    uint112 private reserve1 = 100; 

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
    }

    function emitEvent() public {
        emit Sync (reserve0, reserve1);
    }
}