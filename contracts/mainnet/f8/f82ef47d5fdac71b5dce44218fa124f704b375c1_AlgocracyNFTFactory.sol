//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./AlgocracyNFT.sol";

/// @title Algocracy NFT Factory
/// @author jolan.eth

contract AlgocracyNFTFactory {
    iAlgocracyNFT public DAO;

    constructor(
        address _DAO
    ) {
        DAO = iAlgocracyNFT(_DAO);
    }

    function deployAlgocracyNFT(
        address _Provider,
        uint256 _REGISTRY_IDENTIFIER
    ) public returns (address) {
        require(
            DAO.Deployer() == msg.sender,
            "AlgocracyNFTFactory::deployAlgocracyNFT() - msg.sender is not Deployer"
        );
        AlgocracyNFT NFT = new AlgocracyNFT(
            address(DAO), _Provider, _REGISTRY_IDENTIFIER
        );
        return address(NFT);
    }
}