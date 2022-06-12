// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract UnchainedIndex_V2 {
    constructor() {
        owner = msg.sender;
        manifestHashMap[msg.sender][
            "mainnet"
        ] = "QmP4i6ihnVrj8Tx7cTFw4aY6ungpaPYxDJEZ7Vg1RSNSdm"; // empty file
        emit HashPublished(
            msg.sender,
            "mainnet",
            manifestHashMap[msg.sender]["mainnet"]
        );
        emit OwnerChanged(address(0), owner);
    }

    function publishHash(string memory chain, string memory hash) public {
        manifestHashMap[msg.sender][chain] = hash;
        emit HashPublished(msg.sender, chain, hash);
    }

    function readHash(address publisher, string memory chain)
        public
        view
        returns (string memory)
    {
        return manifestHashMap[publisher][chain];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

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