/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL3
pragma solidity ^0.8.1;

interface NFTLifeCycle{
     function ownerOf(uint256 tokenId) external view returns (address);
}

contract accessControl {

    address private owner;
    mapping(string =>  uint256) Access_map;
    address myNFTContractAddress;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is the NFT owner
    modifier onlyNFTOwner(uint256 tokenId) {
        address ownerAddress;
        ownerAddress = NFTLifeCycle(myNFTContractAddress).ownerOf(tokenId);
        require(msg.sender == ownerAddress, "Caller is not the NFT owner");
        _;
    }

    // modifier to check if caller is the smart contract owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    function setValidUserContractAddress(address _myNFTContractAddress) public isOwner {
       myNFTContractAddress = _myNFTContractAddress;
    }

    function updateAccessRight(string memory userAddress_tokenId, uint tokenID, uint256 accessCode) public onlyNFTOwner(tokenID) {
        Access_map[userAddress_tokenId] = accessCode;
    }  

    function getAccessRight(string memory userAddress_tokenId) public view returns (uint256)   {
        return Access_map[userAddress_tokenId];
    }

}