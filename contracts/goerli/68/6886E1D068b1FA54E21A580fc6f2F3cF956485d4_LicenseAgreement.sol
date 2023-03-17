/**
 *Submitted for verification at Etherscan.io on 2023-03-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract LicenseAgreement {
    address public owner;
    
    struct License {
        string url;
        bytes32 hash;
    }

    mapping(address => mapping(uint256 => License[])) public licenses;

    constructor() {
        owner = msg.sender;
    }

    function setLicense(address tokenAddress, uint256 tokenId, string memory url, bytes32 hash) public {
        require(msg.sender == owner, "Only the owner can store a license info");
        licenses[tokenAddress][tokenId].push(License(url, hash));
    }

    function getLicense(address tokenAddress, uint256 tokenId) public view returns (License[] memory) {
        return licenses[tokenAddress][tokenId];
    }
}