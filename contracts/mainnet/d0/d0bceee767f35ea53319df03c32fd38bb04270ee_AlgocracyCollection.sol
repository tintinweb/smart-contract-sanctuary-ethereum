// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyCollection.sol";
import "./AlgocracyCollectionNFT.sol";
import "./AlgocracyCollectionRegistry.sol";

/// @title Algocracy Collection
/// @author jolan.eth

contract AlgocracyCollection is AlgocracyCollectionNFT, AlgocracyCollectionRegistry {
    iAlgocracyCollection public DAO;

    constructor(
        address _DAO
    ) {
        DAO = iAlgocracyCollection(_DAO);
    }

    function name()
    public view returns (string memory) {
        return string(abi.encodePacked(DAO.name(), ' Collection'));
    }

    function symbol()
    public view returns (string memory) {
        return DAO.symbol();
    }

    function mintCollectionNFT(
        address _NFT, address _Prime,
        address _Owner, address _Provider,
        string memory _name, string memory _cover, string memory _description,
        uint256 _maxSupply
    ) public {
        require (
            DAO.Deployer() == msg.sender, 
            "AlgocracyCollection::mintCollectionNFT() - msg.sender is not DAO.Deployer()"
        );

        uint256 REGISTRY_IDENTIFIER = AlgocracyCollectionRegistry.collectionIndex++;
        AlgocracyCollectionRegistry.setCollectionRegistration(
            _NFT, _Prime, _Provider,
            _name, _cover, _description,
            _maxSupply, REGISTRY_IDENTIFIER
        );
        
        AlgocracyCollectionNFT._mint(_Owner);
    }

    function setCollectionState(
        uint256 id, bool isActive, uint256 maxQuantity, uint256 price
    ) public {
        require(
            AlgocracyCollectionNFT.ownerOf(id) == msg.sender,
            "AlgocracyCollection::setCollectionState() - msg.sender is not ownerOf id"
        );

        Mint memory oldState = AlgocracyCollectionRegistry.getCollectionState(id);
        Mint memory newState = Mint(isActive, oldState.isRandom, oldState.isAllowListed, maxQuantity, price);
        AlgocracyCollectionRegistry.CollectionRegistry[id].State = newState;
    }

    function setCollectionStateAllowListInternal(
        uint256 id, bool isAllowListed
    ) public {
        require(
            AlgocracyCollectionRegistry.getCollectionContract(id).Prime == msg.sender,
            "AlgocracyCollection::setCollectionStateInternal() - msg.sender is not Prime of id"
        );

        Mint memory oldState = AlgocracyCollectionRegistry.getCollectionState(id);
        Mint memory newState = Mint(oldState.isActive, oldState.isRandom, isAllowListed, oldState.maxQuantity, oldState.price);
        AlgocracyCollectionRegistry.CollectionRegistry[id].State = newState;
    }

    function setCollectionStateRandomInternal(
        uint256 id, bool isRandom
    ) public {
        require(
            AlgocracyCollectionRegistry.getCollectionContract(id).Prime == msg.sender,
            "AlgocracyCollection::setCollectionStateInternal() - msg.sender is not Prime of id"
        );

        Mint memory oldState = AlgocracyCollectionRegistry.getCollectionState(id);
        Mint memory newState = Mint(oldState.isActive, isRandom, oldState.isAllowListed, oldState.maxQuantity, oldState.price);
        AlgocracyCollectionRegistry.CollectionRegistry[id].State = newState;
    }
    
    function tokenURI(uint256 id)
    public view returns (string memory) {
        iAlgocracyCollection CollectionProvider = iAlgocracyCollection(DAO.CollectionProvider());

        require(
            AlgocracyCollectionNFT.exist(id),
            "AlgocracyCollection::tokenUri() - id do not exist"
        );
        
        return CollectionProvider.generateMetadata(id);
    }

    function owner()
    public view returns (address) {
        iAlgocracyCollection PassNFT = iAlgocracyCollection(DAO.PassNFT());

        return PassNFT.ownerOf(1);
    }
}