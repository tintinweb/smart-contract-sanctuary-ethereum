// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyPass.sol";
import "./AlgocracyPassNFT.sol";
import "./AlgocracyPassRegistry.sol";

/// @title Algocracy Pass
/// @author jolan.eth

contract AlgocracyPass is AlgocracyPassNFT, AlgocracyPassRegistry {
    iAlgocracyPass public DAO;

    constructor(
        address _DAO,
        address _Core
    ) {
        DAO = iAlgocracyPass(_DAO);
        AlgocracyPassRegistry.setPassRegistration(ACCESS_LEVEL_CORE);
        AlgocracyPassNFT._mint(_Core);
    }

    function name() 
    public view returns (string memory) {
        return DAO.name();
    }

    function symbol() 
    public view returns (string memory) {
        return DAO.symbol();
    }

    function mintPassFromCollection(address to, uint256 _PRIME_REGISTRY_IDENTIFIER)
    public {
        iAlgocracyPass CollectionNFT = iAlgocracyPass(DAO.CollectionNFT());

        require(
            CollectionNFT.getCollectionContract(
                _PRIME_REGISTRY_IDENTIFIER
            ).Prime == msg.sender && !LOCK,
            "AlgocracyPass::mintPass() - msg.sender does not match requirement"
        );
            
        AlgocracyPassRegistry.setPassRegistration(
            AlgocracyPassRegistry.ACCESS_LEVEL_BASE
        );
            
        AlgocracyPassNFT._mint(to);
    }

    function mintPassFromCore(address to)
    public {
        require(
            AlgocracyPassRegistry.getAccessLevel(
                AlgocracyPassNFT.ownedBy(msg.sender)
            ) == AlgocracyPassRegistry.ACCESS_LEVEL_CORE,
            "AlgocracyPass::mintPass() - msg.sender does not match requirement"
        );
            
        AlgocracyPassRegistry.setPassRegistration(
            AlgocracyPassRegistry.ACCESS_LEVEL_BASE
        );
            
        AlgocracyPassNFT._mint(to);
    }

    function setLock()
    public {
        require(
            AlgocracyPassRegistry.getAccessLevel(
                ownedBy(msg.sender)
            ) == AlgocracyPassRegistry.ACCESS_LEVEL_CORE,
            "AlgocracyPass::setLock() - msg.sender does not have access level"
        );

        AlgocracyPassRegistry.LOCK = false;
    }

    function setOperatorPassAccessLevel(uint256 id)
    public {
        require(
            AlgocracyPassRegistry.getAccessLevel(
                ownedBy(msg.sender)
            ) == AlgocracyPassRegistry.ACCESS_LEVEL_CORE,
            "AlgocracyPass::setOperatorPassAccessLevel() - msg.sender does not have access level"
        );

        require(
            AlgocracyPassRegistry.getAccessLevel(id) == AlgocracyPassRegistry.ACCESS_LEVEL_BASE,
            "AlgocracyPass::setOperatorPassAccessLevel() - current ACCESS_LEVEL do not match"
        );

        AlgocracyPassRegistry.PassRegistry[id].ACCESS_LEVEL = AlgocracyPassRegistry.ACCESS_LEVEL_OPERATOR;
    }

    function unsetOperatorPassAccessLevel(uint256 id)
    public {
        require(
            AlgocracyPassRegistry.getAccessLevel(
                ownedBy(msg.sender)
            ) == AlgocracyPassRegistry.ACCESS_LEVEL_CORE,
            "AlgocracyPass::unsetOperatorPassAccessLevel() - msg.sender does not have access level"
        );

        require(
            AlgocracyPassRegistry.getAccessLevel(id) == AlgocracyPassRegistry.ACCESS_LEVEL_OPERATOR,
            "AlgocracyPass::unsetOperatorPassAccessLevel() - current ACCESS_LEVEL do not match"
        );

        AlgocracyPassRegistry.PassRegistry[id].ACCESS_LEVEL = AlgocracyPassRegistry.ACCESS_LEVEL_BASE;
    }
    
    function tokenURI(uint256 id)
    public view returns (string memory) {
        iAlgocracyPass PassProvider = iAlgocracyPass(DAO.PassProvider());

        require(
            AlgocracyPassNFT.exist(id),
            "AlgocracyPass::tokenUri() - id do not exist"
        );

        return PassProvider.generateMetadata(id);
    }

    function owner()
    public view returns (address) {
        return AlgocracyPassNFT.ownerOf(1);
    }
}