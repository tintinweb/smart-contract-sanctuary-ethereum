// SPDX-License-Identifier: MIT
// Gallery of solid state contracts

pragma solidity ^0.8.0;
pragma abicoder v2;

contract SolidStateGallery {
    mapping(uint256 => address) private artWorkContracts;
    mapping(uint256 => string) private artWorkCollections;
    mapping(uint256 => uint256) private artWorkCollection;
    mapping(address => bool) private artWorkVisibility;
    uint256 private artWorkCount;
    uint256 private collectionCount;
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
        collectionCount = 0;
    }

    function addArtWork(address _artWorkAddress, uint256 _collectionId)
        public
        onlyOwner
    {
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
        artWorkCollection[artWorkCount] = _collectionId;
        artWorkVisibility[_artWorkAddress] = false;
        artWorkCount++;
    }

    function addCollection(string memory _collectionName) public onlyOwner {
        for (
            uint256 collectionIndex = 0;
            collectionIndex < collectionCount;
            collectionIndex++
        ) {
            require(
                compareStrings(
                    artWorkCollections[collectionIndex],
                    _collectionName
                ) == false,
                "Collection is already added"
            );
        }
        artWorkCollections[collectionCount] = _collectionName;

        collectionCount++;
    }

    function getCollectionIdByName(string memory _collectionName)
        public
        view
        returns (uint256)
    {
        bool isName = false;
        for (
            uint256 collectionIndex = 0;
            collectionIndex < collectionCount;
            collectionIndex++
        ) {
            if (
                compareStrings(
                    artWorkCollections[collectionIndex],
                    _collectionName
                ) == true
            ) {
                return collectionIndex;
            }
        }
        require(isName == true, "No Collection By That Name");
        return 0;
    }

    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getCollections() public view returns (string[] memory) {
        string[] memory collections = new string[](collectionCount);
        for (
            uint256 collectionIndex = 0;
            collectionIndex < collectionCount;
            collectionIndex++
        ) {
            collections[collectionIndex] = artWorkCollections[collectionIndex];
        }
        return collections;
    }

    function getAllArtWorksByCollectionId(uint256 _Id)
        public
        view
        returns (address[] memory, bool[] memory)
    {
        uint256 count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkCollection[artWorkIndex] == _Id) {
                count++;
            }
        }
        address[] memory contracts = new address[](count);
        bool[] memory visibility = new bool[](count);
        count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkCollection[artWorkIndex] == _Id) {
                contracts[count] = artWorkContracts[artWorkIndex];
                visibility[count] = artWorkVisibility[
                    artWorkContracts[artWorkIndex]
                ];
                count++;
            }
        }
        return (contracts, visibility);
    }

    function getArtWorksByCollectionId(uint256 _Id)
        public
        view
        returns (address[] memory)
    {
        uint256 count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                if (artWorkCollection[artWorkIndex] == _Id) {
                    count++;
                }
            }
        }
        address[] memory contracts = new address[](count);
        count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                if (artWorkCollection[artWorkIndex] == _Id) {
                    contracts[count] = artWorkContracts[artWorkIndex];
                    count++;
                }
            }
        }
        return contracts;
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
        uint256 count = 0;
        for (
            uint256 artWorkIndex = 0;
            artWorkIndex < artWorkCount;
            artWorkIndex++
        ) {
            if (artWorkVisibility[artWorkContracts[artWorkIndex]] == true) {
                count++;
            }
        }
        address[] memory contracts = new address[](count);
        count = 0;
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