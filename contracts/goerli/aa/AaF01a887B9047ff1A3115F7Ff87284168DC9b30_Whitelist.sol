// SPDX-License-Identifier: MIT
import "./Context.sol";

// File: contracts/Whitelist.sol


pragma solidity ^0.8.4;


struct IsMintNumber {
    uint256 allowed;
    uint256 mintNumber;
}

contract Whitelist is Ownable {
    bool isSetFounder = false;

    address founderAddress;

    mapping(address => IsMintNumber) whitelist;

    constructor() {}

    function addToWhitelist(address[] calldata toAddAddresses, uint256[] calldata allowedType) 
    external onlyOwner
    {
        for (uint i = 0; i < toAddAddresses.length; i++) {
            whitelist[toAddAddresses[i]] = IsMintNumber(allowedType[i], 0);
        }
    }

    function removeFromWhitelist(address[] calldata toRemoveAddresses)
    external onlyOwner
    {
        for (uint i = 0; i < toRemoveAddresses.length; i++) {
            whitelist[toRemoveAddresses[i]] = IsMintNumber(0, 0);
        }
    }

    function getWhitelist(address owner) external view returns(uint256, uint256) {
        return (whitelist[owner].allowed, whitelist[owner].mintNumber);
    }

    function whitelistMintNumberIncrement(address owner) external {
        whitelist[owner].mintNumber += 1;
    }

    function setFounderAddress(address _founder) public onlyOwner {
        require(isSetFounder == false, "Set founder address can only run one");
        founderAddress = _founder;
        isSetFounder = true;
        whitelist[_founder] = IsMintNumber(3, 0);
    }

    function getFounderAddress() external view returns (address) {
        return founderAddress;
    }
}