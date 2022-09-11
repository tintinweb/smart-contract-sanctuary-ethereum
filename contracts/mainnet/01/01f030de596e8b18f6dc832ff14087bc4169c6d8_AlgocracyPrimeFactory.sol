//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./AlgocracyPrime.sol";

/// @title Algocracy Prime Factory
/// @author jolan.eth

contract AlgocracyPrimeFactory {
    iAlgocracyPrime public DAO;

    constructor(
        address _DAO
    ) {
        DAO = iAlgocracyPrime(_DAO);
    }

    function deployAlgocracyPrime(
        uint256 _REGISTRY_IDENTIFIER
    ) public returns (address) {
        require(
            DAO.Deployer() == msg.sender,
            "AlgocracyPrimeFactory::deployAlgocracyPrime() - msg.sender is not Deployer"
        );
        AlgocracyPrime Prime = new AlgocracyPrime(
            address(DAO), _REGISTRY_IDENTIFIER
        );
        return address(Prime);
    }
}