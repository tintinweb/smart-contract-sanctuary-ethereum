//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyDeployer.sol";

/// @title Algocracy Deployer
/// @author jolan.eth

contract AlgocracyDeployer {
    iAlgocracyDeployer public DAO;

    constructor(
        address _DAO
    ) {
        DAO = iAlgocracyDeployer(_DAO);
    }

    function deployCollection(
        address _Owner, address _Provider,
        string memory _name, string memory _cover,
        string memory _description, uint256 _maxSupply
    ) public {
        iAlgocracyDeployer PassNFT = iAlgocracyDeployer(DAO.PassNFT());
        
        require(
            PassNFT.getAccessLevel(PassNFT.ownedBy(msg.sender)) == PassNFT.ACCESS_LEVEL_CORE() ||
            PassNFT.getAccessLevel(PassNFT.ownedBy(msg.sender)) == PassNFT.ACCESS_LEVEL_OPERATOR(),
            "AlgocracyDeployer::deployCollection() - msg.sender does not have access level"
        );

        uint256 REGISTRY_IDENTIFIER = iAlgocracyDeployer(DAO.CollectionNFT()).getCollectionRegistryLength();
        address _NFT = iAlgocracyDeployer(DAO.NFTFactory()).deployAlgocracyNFT(_Provider, REGISTRY_IDENTIFIER);
        address _Prime = iAlgocracyDeployer(DAO.PrimeFactory()).deployAlgocracyPrime(REGISTRY_IDENTIFIER);

        iAlgocracyDeployer(DAO.CollectionNFT()).mintCollectionNFT(
            _NFT, _Prime, _Owner, _Provider,
            _name, _cover, _description,
            _maxSupply
        );
    }
}