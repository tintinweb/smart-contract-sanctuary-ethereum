/**
 *Submitted for verification at Etherscan.io on 2022-05-25
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Not Owner!");
        _;
    }

    function transferOwnership(address new_) external onlyOwner {
        owner = new_;
    }
}

interface iSpore {
    function transfer(address to_, uint256 amount_) external;

    function mintAsController(address to_, uint256 amount_) external;
}

contract MockSporeYield is Ownable {
    // Interfaces
    iSpore public Spore = iSpore(0xC1CE4Af7009c0f0fFD5c10d13d1BD2a580ec4296);

    function setSpore(address address_) external {
        Spore = iSpore(address_);
    }

    function claim(uint256[] calldata tokenIds_) public returns (uint256) {
        // Mint the total tokens for the msg.sender
        Spore.mintAsController(msg.sender, tokenIds_.length * 10);
        // Return the claim amount
        return 10;
    }

    function getPendingTokensMany(uint256[] memory indexes_) public view returns (uint256) {
        return indexes_.length * 10;
    }
}