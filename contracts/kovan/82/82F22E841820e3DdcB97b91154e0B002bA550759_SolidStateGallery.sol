// SPDX-License-Identifier: MIT
// Gallery of solid state contracts

pragma solidity ^0.8.0;
pragma abicoder v2;

contract SolidStateGallery {
    mapping(uint256 => address) private artWorkContracts;
    mapping(address => bool) private artWorkVisibility;
    uint256 artWorkCount;
    address[] private owners;
    uint256 ownerCount;
    struct allArtworks {
        address contractAddress;
        bool visibilty;
    }

    modifier onlyOwner() {
        require(msg.sender == owners[ownerCount]);
        _;
    }

    constructor() {
        owners.push(msg.sender);
        artWorkCount = 0;
        ownerCount = 0;
    }

    function addArtWork(address _artWorkAddress) public onlyOwner {
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            require(
                artWorkContracts[artWorkIndex] != _artWorkAddress,
                "Art work already added"
            );
        }
        artWorkContracts[artWorkCount] = _artWorkAddress;
        artWorkVisibility[_artWorkAddress] = false;
        artWorkCount++;
    }

    function getAllArtWorks()
        public
        view
        returns (address[] memory, bool[] memory)
    {
        address[] memory contracts = new address[](artWorkCount);
        bool[] memory visibility = new bool[](artWorkCount);
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            contracts[artWorkIndex] = artWorkContracts[artWorkIndex];
            visibility[artWorkIndex] = artWorkVisibility[
                artWorkContracts[artWorkIndex]
            ];
        }
        return (contracts, visibility);
    }

    function getArtWorks() public view returns (address[] memory) {
        address[] memory contracts = new address[](artWorkCount);
        uint256 count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                contracts[count] = artWorkContracts[artWorkIndex];
                count++;
            }
        }
        return contracts;
    }

    function setArtWorkVisibility(
        address _artWorkContractAddress,
        bool _visibility
    ) public onlyOwner {
        artWorkVisibility[_artWorkContractAddress] = _visibility;
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function newOwner(address _newOwnerAddress) public onlyOwner {
        ownerCount++;
        owners.push(_newOwnerAddress);
    }
}