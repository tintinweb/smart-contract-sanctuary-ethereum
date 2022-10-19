/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT
// File: contracts/SPromotion.sol


pragma solidity 0.8.15;

contract Promotion {
    address private ownerAddress;
    address private nftAddress;
    
    address[] private mintedAddresses;
    mapping(address => mapping(uint256 => uint256))
        private adrressToBoxIdMintCount;

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, "Only owner address");
        _;
    }

    modifier onlyNFT() {
        require(msg.sender == nftAddress, "Only NFT address");
        _;
    }

    constructor() {
        ownerAddress = msg.sender;
    }

    function setNFTAddress(address _nftAddress) external onlyOwner {
        nftAddress = _nftAddress;
    }

    function getAddressMintList() external view returns (address[] memory) {
        return mintedAddresses;
    }

    function getTotalMintPerAddress(address minterAddress, uint256 boxId)
        external
        view
        returns (uint256)
    {
        return adrressToBoxIdMintCount[minterAddress][boxId];
    }

    function updatePromotionMint(uint256 boxId, uint256 quantity)
        external
        onlyNFT
    {
        require(nftAddress != address(0), "NFT address not yet set");
        if (adrressToBoxIdMintCount[tx.origin][boxId] == 0) {
            mintedAddresses.push(tx.origin);
        }
        adrressToBoxIdMintCount[tx.origin][boxId] += quantity;
    }

    function isMintable(
        uint256 boxId,
        uint256 totalSupply,
        uint256 totalMint,
        bool closed,
        bool paused,
        uint256 hashLength,
        uint256 mintLimitPerTransaction,
        uint256 mintLimitPerBox,
        uint256 quantity
    ) external view onlyNFT returns (bool, string memory) {
        if (
            adrressToBoxIdMintCount[tx.origin][boxId] + quantity >
            mintLimitPerBox
        ) {
            return (false, "Exceed mint quantity limit");
        }
        if (closed) {
            return (false, "The box is closed");
        }
        if (paused) {
            return (false, "The box is paused");
        }
        if (hashLength < quantity) {
            return (false, "Exceed box hash limit");
        }
        if (totalMint + quantity > totalSupply) {
            return (false, "The box is sold out");
        }
        if (quantity > mintLimitPerTransaction) {
            return (false, "Exceed quantity limit");
        }
        return (true, "Mintable");
    }
}