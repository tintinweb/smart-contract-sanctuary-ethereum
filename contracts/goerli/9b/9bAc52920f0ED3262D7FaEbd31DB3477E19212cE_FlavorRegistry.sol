// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title NFTC Flavor Registry
 * @author @NiftyMike, NFT Culture
 * @notice Flavor registry settings
 * Purpose of this contract is to persist and query flavor settings.
 */
contract FlavorRegistry {
    address private _owner;

    struct FlavorSettings {
        uint256 maxFlavors;
    }

    mapping(address => FlavorSettings) private _flavorState;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function setMaxFlavors(address addr, uint256 maxFlavors) external payable onlyOwner {
        _flavorState[addr] = FlavorSettings({
            maxFlavors: maxFlavors
        });
    }

    function getMaxFlavors(address addr) external view returns (uint256) {
        FlavorSettings memory flavorSettings = _flavorState[addr];

        return flavorSettings.maxFlavors;
    }
}