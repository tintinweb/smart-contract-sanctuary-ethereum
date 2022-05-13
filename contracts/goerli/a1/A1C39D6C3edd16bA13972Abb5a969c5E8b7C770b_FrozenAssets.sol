//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract FrozenAssets {
    address owner = msg.sender;
    constructor() payable {}

    function withdraw() external {
        require(msg.sender == owner);
        (bool s, ) = msg.sender.call{ value: address(this).balance }("");
        require(s);
    }
}