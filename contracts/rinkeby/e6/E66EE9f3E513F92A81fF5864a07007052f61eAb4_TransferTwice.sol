// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TransferTwice {
    function helloTransfer(address _addr) public payable{
        uint256 half = msg.value / 2;
        (bool success1, ) = _addr.call{value: half}("");
        require(success1);
        (bool success2, ) = _addr.call{value: half}("");
        require(success2);
    }
}