// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.1;

contract Notarization  {

    mapping(string => uint256) private hashRegistry; //Mapping to link hash based evidences (String) with time of registry (uint256).
    address public owner;

    modifier onlyOwner {
            require(owner == msg.sender, "Only the owner can register, or change the current owner."); //Only the owner can register evidences.
            _;
        }

    constructor() {
        owner = msg.sender; //Set the owner of the contract. The only address that can register evidences.
    }

    function register(string memory hash) public onlyOwner {
        hashRegistry[hash] = block.timestamp; //Evidences (hashes) registering in map, linked to current time.
    }

    function getHashEvidence(string memory hash) public view returns (uint256){
        return (hashRegistry[hash]); //If the hash is not registered, the returned value will be 0 (uint256 default value).
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

}