// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyDAO.sol";

import "./AlgocracyVRFConsumer.sol";

import "./AlgocracyNFTFactory.sol";
import "./AlgocracyPrimeFactory.sol";
import "./AlgocracyDeployer.sol";

import "./AlgocracyPass.sol";
import "./AlgocracyCollection.sol";
import "./AlgocracyRandom.sol";

/// @title Algocracy Genesis
/// @author jolan.eth

contract AlgocracyDAO {
    string public symbol = "ALGOV";
    string public name = "Algocracy";
    string public module = "GENESIS";

    iAlgocracyDAO public VRFConsumer;

    iAlgocracyDAO public Deployer;
    iAlgocracyDAO public NFTFactory;
    iAlgocracyDAO public PrimeFactory;

    iAlgocracyDAO public PassNFT;
    iAlgocracyDAO public CollectionNFT;
    iAlgocracyDAO public RandomNFT;

    iAlgocracyDAO public PassProvider;
    iAlgocracyDAO public CollectionProvider;

    constructor (
        address _Link,
        address _VRFCoordinator,
        bytes32 _VRFKeyhash
    ) {
        AlgocracyVRFConsumer _VRFConsumer = new AlgocracyVRFConsumer(
            address(this), _Link, _VRFCoordinator, _VRFKeyhash
        );
        
        AlgocracyDeployer _Deployer = new AlgocracyDeployer(address(this));
        AlgocracyNFTFactory _NFTFactory = new AlgocracyNFTFactory(address(this));
        AlgocracyPrimeFactory _PrimeFactory = new AlgocracyPrimeFactory(address(this));

        AlgocracyPass _PassNFT = new AlgocracyPass(address(this), msg.sender);
        AlgocracyCollection _CollectionNFT = new AlgocracyCollection(address(this));
        AlgocracyRandom _RandomNFT = new AlgocracyRandom(address(this));
        
        VRFConsumer = iAlgocracyDAO(address(_VRFConsumer));
        
        Deployer = iAlgocracyDAO(address(_Deployer));
        NFTFactory = iAlgocracyDAO(address(_NFTFactory));
        PrimeFactory = iAlgocracyDAO(address(_PrimeFactory));

        PassNFT = iAlgocracyDAO(address(_PassNFT));
        CollectionNFT = iAlgocracyDAO(address(_CollectionNFT));
        RandomNFT = iAlgocracyDAO(address(_RandomNFT));
    }

    function setProviderInterface(
        address _PassProvider,
        address _CollectionProvider
    ) public {
        require(
            PassNFT.getAccessLevel(PassNFT.ownedBy(msg.sender)) == PassNFT.ACCESS_LEVEL_CORE(),
            "AlgocracyDAO::setProviderInterface() - msg.sender does not have access level"
        );

        require(
            address(PassProvider) == address(0) &&
            address(CollectionProvider) == address(0),
            "AlgocracyDAO::setProviderInterface() - interface already set"
        );

        PassProvider = iAlgocracyDAO(_PassProvider);
        CollectionProvider = iAlgocracyDAO(_CollectionProvider);
    }

    function chain()
    public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}