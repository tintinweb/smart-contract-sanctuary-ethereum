/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract UnchainedIndex_V2 {
    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), owner);

        manifestHashMap[msg.sender][
            "mainnet"
        ] = "QmP4i6ihnVrj8Tx7cTFw4aY6ungpaPYxDJEZ7Vg1RSNSdm"; // empty file
        emit HashPublished(
            msg.sender,
            "mainnet",
            manifestHashMap[msg.sender]["mainnet"]
        );
    }

    // Note: this is purposefully permissionless. Anyone may publish a hash
    // and anyone my query that hash by a given publisher. This is by design.
    // End users themselves must determine who to believe. We suggest it's us,
    // but who's to say?
    function publishHash(string memory chain, string memory hash) public {
        manifestHashMap[msg.sender][chain] = hash;
        emit HashPublished(msg.sender, chain, hash);
    }

    // If, at a certain point, we decide to disable or redirect donations. Otherwise,
    // owner no other purpose. "isOwner isAMistake!"
    function changeOwner(address newOwner) public returns (address oldOwner) {
        require(msg.sender == owner, "msg.sender must be owner");
        oldOwner = owner;
        owner = newOwner;
        emit OwnerChanged(oldOwner, newOwner);
        return oldOwner;
    }

    function donate() public payable {
        require(owner != address(0), "owner is not set");
        emit DonationSent(owner, msg.value, block.timestamp);
        payable(owner).transfer(address(this).balance);
    }

    event HashPublished(address publisher, string chain, string hash);
    event OwnerChanged(address oldOwner, address newOwner);
    event DonationSent(address from, uint256 amount, uint256 ts);

    mapping(address => mapping(string => string)) public manifestHashMap;
    address public owner;
}