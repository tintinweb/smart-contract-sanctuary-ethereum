// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyRandom.sol";
import "./AlgocracyRandomRegistry.sol";

/// @title Algocracy Random
/// @author jolan.eth

contract AlgocracyRandom is AlgocracyRandomRegistry {
    iAlgocracyRandom public DAO;

    constructor(
        address _DAO
    ) {
        DAO = iAlgocracyRandom(_DAO);
    }

    function mintRandom(uint256 id, uint256 provableRandom) 
    public {
        require(
            DAO.VRFConsumer() == msg.sender,
            "AlgocracyRandom::mintRandom() - msg.sender is not DAO.VRFConsumer()"
        );

        AlgocracyRandomRegistry.setRandomRegistration(id, provableRandom);
    }
}