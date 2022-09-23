// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./WhitelistType.sol";

contract WhitelistService {
    modifier onlyWhitelistOwner(bytes32 wlHash) {
        require(whitelists[wlHash].owner == msg.sender);
        _;
    }

    modifier whitelistExists(bytes32 wlHash) {
        require(whitelists[wlHash].owner != address(0));
        _;
    }

    mapping(bytes32 => Whitelist) whitelists;

    function getWhitelistHash(address owner, string calldata name) public pure returns (bytes32) {
        return keccak256(abi.encode(owner, name));
    }

    function createWhitelist(string calldata name) public returns (bytes32) {
        bytes32 wlHash = getWhitelistHash(msg.sender, name);
        require(whitelists[wlHash].owner == address(0), "You've already created a whitelist of this name!");
        Whitelist storage wl = whitelists[wlHash];
        wl.owner = msg.sender;
        wl.disabled = false;

        return wlHash;
    }

    function addToWhitelist(bytes32 wlHash, address addr) public onlyWhitelistOwner(wlHash) {
        whitelists[wlHash].whitelist[addr] = true;
    }

    function removeFromWhitelist(bytes32 wlHash, address addr) public onlyWhitelistOwner(wlHash) {
        whitelists[wlHash].whitelist[addr] = false;
    }

    function isWhitelisted(bytes32 wlHash, address addr) public view whitelistExists(wlHash) returns (bool) {
        return (whitelists[wlHash].disabled || whitelists[wlHash].whitelist[addr]);
    }

    function disableWhitelist(bytes32 wlHash) public onlyWhitelistOwner(wlHash) {
        whitelists[wlHash].disabled = true;
    }

    function enableWhitelist(bytes32 wlHash) public onlyWhitelistOwner(wlHash) {
        whitelists[wlHash].disabled = false;
    }

    function transferWhitelistOwnership(bytes32 wlHash, address newOwner) public onlyWhitelistOwner(wlHash) {
        whitelists[wlHash].owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Whitelist {
    address owner;
    bool disabled;
    mapping(address => bool) whitelist;
}