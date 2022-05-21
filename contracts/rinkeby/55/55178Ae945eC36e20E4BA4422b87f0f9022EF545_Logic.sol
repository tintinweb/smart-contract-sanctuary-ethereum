// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Logic {
    bool initialized;
    uint256 magicNumber;
    event Magic(address user);

    function initialize() public {
        require(!initialized, "already initialized");
        magicNumber = 62;
        initialized = true;
    }

    function setMagicNumber(uint256 newMagicNumber) public {
        magicNumber = newMagicNumber;
        emit Magic(msg.sender);
    }

    function getMagicNumber() public view returns (uint256) {
        return magicNumber;
    }
}