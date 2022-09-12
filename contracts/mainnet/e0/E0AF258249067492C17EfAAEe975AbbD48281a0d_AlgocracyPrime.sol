//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./iAlgocracyPrime.sol";

/// @title Algocracy Prime
/// @author jolan.eth

contract AlgocracyPrime {
    uint256 public REGISTRY_IDENTIFIER;

    iAlgocracyPrime public DAO;

    uint256[] shuffledTokenIds;
    uint256 shuffledTokenIdsIndex;

    uint256 public allowListIndex;
    mapping(uint256 => mapping (address => bool)) public allowList;

    constructor(
        address _DAO,
        uint256 _REGISTRY_IDENTIFIER
    ) {
        DAO = iAlgocracyPrime(_DAO);
        REGISTRY_IDENTIFIER = _REGISTRY_IDENTIFIER;
    }

    receive() external payable {}
    fallback() external payable {}

    function setShuffledTokenIds(uint256[] memory ids, uint256 randomId)
    public {
        iAlgocracyPrime RandomNFT = iAlgocracyPrime(DAO.RandomNFT());
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());
        iAlgocracyPrime AlgocracyNFT = iAlgocracyPrime(
            CollectionNFT.getCollectionContract(REGISTRY_IDENTIFIER).NFT
        );

        iAlgocracyPrime.Random memory Object = RandomNFT.getRandomRegistry(randomId);

        require(
            AlgocracyNFT.totalSupply() == 0,
            "AlgocracyPrime::setShuffledTokenIds() - total supply is higher than 0"
        );

        require(
            !CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isActive,
            "AlgocracyPrime::setShuffledTokenIds() - prime is active"
        );

        require(
            CollectionNFT.ownerOf(REGISTRY_IDENTIFIER) == msg.sender,
            "AlgocracyPrime::setShuffledTokenIds() - msg.sender is not the contract owner"
        );

        require(
            Object.id != 0,
            "AlgocracyPrime::setShuffledTokenIds() - randomId does not exist"
        );

        require(
            ids.length == AlgocracyNFT.maxSupply() && ids.length <= 1000,
            "AlgocracyPrime::setShuffledtokenIds() - ids length does not match requirement"
        );

        require(
            shuffledTokenIds.length == 0,
            "AlgocracyPrime::setshuffledtokenIds() - shuffledTokenIds can be initialized only once"
        );

        unchecked {
            uint256 i = 0;
            while (i < ids.length) {
                uint256 n = i + Object.provableRandom % (ids.length - i);
                uint256 temp = ids[n];
                ids[n] = ids[i];
                ids[i] = temp;
                i++;
            }

            shuffledTokenIds = ids;
        }

        CollectionNFT.setCollectionStateRandomInternal(
            REGISTRY_IDENTIFIER, 
            true
        );
    }

    function setAllowList(address[] memory _allowList)
    public {
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());
        
        require(
            CollectionNFT.ownerOf(REGISTRY_IDENTIFIER) == msg.sender,
            "AlgocracyPrime::setAllowList() - msg.sender is not the contract owner"
        );
        
        uint256 i = 0;
        uint256 len = _allowList.length;
        uint256 index = allowListIndex++;
        while (i < len)
            allowList[index][_allowList[i]] = !allowList[index][_allowList[i++]];

        CollectionNFT.setCollectionStateAllowListInternal(
            REGISTRY_IDENTIFIER, true
        );
    }

    function unsetAllowList()
    public {
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());

        require(
            CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isAllowListed,
            "AlgocracyPrime::unsetAllowList() - allowList is not set"
        );
        
        require(
            CollectionNFT.ownerOf(REGISTRY_IDENTIFIER) == msg.sender,
            "AlgocracyPrime::unsetAllowList() - msg.sender is not the contract owner"
        );

        CollectionNFT.setCollectionStateAllowListInternal(
            REGISTRY_IDENTIFIER, false
        );
    }

    function withdrawETH(address to)
    public {
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());

        require(
            CollectionNFT.ownerOf(REGISTRY_IDENTIFIER) == msg.sender,
            "AlgocracyPrime::withdrawETH() - msg.sender is not the contract owner"
        );

        uint256 balance = address(this).balance;
        require(payable(to).send(balance));
    }

    function distributeNFT(address to, uint256 quantity)
    public {
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());
        iAlgocracyPrime AlgocracyNFT = iAlgocracyPrime(
            CollectionNFT.getCollectionContract(REGISTRY_IDENTIFIER).NFT
        );

        require(
            CollectionNFT.ownerOf(REGISTRY_IDENTIFIER) == msg.sender,
            "AlgocracyPrime::distributeNFT() - msg.sender is not the contract owner"
        );

        if (!CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isRandom) {
            AlgocracyNFT.mintSequentialNFT(to, quantity);
        } else {
            uint256 tmp = shuffledTokenIdsIndex;
            shuffledTokenIdsIndex+=quantity;

            uint256 i = 0;
            uint256[] memory tokenIds = new uint256[](quantity);
            while (i < quantity) {
                tokenIds[i] = shuffledTokenIds[tmp++];
                i++;
            }

            AlgocracyNFT.mintRandomNFT(to, tokenIds);
        }
    }

    function distributeBatchNFT(address[] memory _snapshot)
    public {
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());
        iAlgocracyPrime AlgocracyNFT = iAlgocracyPrime(
            CollectionNFT.getCollectionContract(REGISTRY_IDENTIFIER).NFT
        );

        require(
            CollectionNFT.ownerOf(REGISTRY_IDENTIFIER) == msg.sender,
            "AlgocracyPrime::distributeBatchNFT() - msg.sender is not the contract owner"
        );

        require(
            _snapshot.length > 1 && _snapshot.length <= 100,
            "AlgocracyPrime::distributeBatchNFT() - _snapshot length is out of bound"
        );

        uint256 i = 0;
        uint256 max = _snapshot.length;
        while (i < max) {
            address snap = _snapshot[i];
            if (!CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isRandom) {
                AlgocracyNFT.mintSequentialNFT(snap, 1);
            } else {
                uint256 tmp = shuffledTokenIdsIndex;
                shuffledTokenIdsIndex+=1;

                uint256 x = 0;
                uint256[] memory tokenIds = new uint256[](1);
                while (x < 1) tokenIds[x++] = shuffledTokenIds[tmp++];
                
                AlgocracyNFT.mintRandomNFT(snap, tokenIds);
            }
            i++;
        }
    }

    function claimNFT(uint256 quantity)
    public {
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());
        iAlgocracyPrime AlgocracyNFT = iAlgocracyPrime(
            CollectionNFT.getCollectionContract(REGISTRY_IDENTIFIER).NFT
        );

        require(
            CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isActive,
            "AlgocracyPrime::claimNFT() - is not active"
        );
        
        require (
            quantity <= CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).maxQuantity,
            "AlgocracyPrime::claimNFT() - quantity is higher than maxQuantity"
        );

        if (CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isAllowListed) {
            require(
                allowList[allowListIndex-1][msg.sender],
                "AlgocracyPrime::claimNFT() - msg.sender is not allowlisted"
            );
            delete allowList[allowListIndex-1][msg.sender];
        }

        require(
            CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).price == 0,
            "AlgocracyPrime::claimNFT() - price is not 0"
        );
            
        if (!CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isRandom) {
            AlgocracyNFT.mintSequentialNFT(msg.sender, quantity);
        } else {
            uint256 tmp = shuffledTokenIdsIndex;
            shuffledTokenIdsIndex+=quantity;

            uint256 i = 0;
            uint256[] memory tokenIds = new uint256[](quantity);
            while (i < quantity) {
                tokenIds[i] = shuffledTokenIds[tmp++];
                i++;
            }

            AlgocracyNFT.mintRandomNFT(msg.sender, tokenIds);
        }
    }

    function buyNFT(uint256 quantity)
    public payable {
        iAlgocracyPrime PassNFT = iAlgocracyPrime(DAO.PassNFT());
        iAlgocracyPrime CollectionNFT = iAlgocracyPrime(DAO.CollectionNFT());
        iAlgocracyPrime AlgocracyNFT = iAlgocracyPrime(
            CollectionNFT.getCollectionContract(REGISTRY_IDENTIFIER).NFT
        );

        require(
            CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isActive,
            "AlgocracyPrime::buyNFT() - is not active"
        );

        require (
            quantity <= CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).maxQuantity,
            "AlgocracyPrime::buyNFT() - quantity is higher than maxQuantity"
        );

        if (CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isAllowListed) {
            bool allowance = allowList[allowListIndex-1][msg.sender];
            delete allowList[allowListIndex-1][msg.sender];
            require(
                allowance,
                "AlgocracyPrime::buyNFT() - msg.sender is not allowlisted"
            );
        }

        require(
            CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).price > 0,
            "AlgocracyPrime::buyNFT() - price is 0"
        );

        require(
            msg.value == (CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).price * quantity),
            "AlgocracyPrime::buyNFT() - msg.value do not match price"
        );

        if (PassNFT.balanceOf(msg.sender) == 0 && !PassNFT.LOCK())
            PassNFT.mintPassFromCollection(msg.sender, REGISTRY_IDENTIFIER);
            
        if (!CollectionNFT.getCollectionState(REGISTRY_IDENTIFIER).isRandom) {
            AlgocracyNFT.mintSequentialNFT(msg.sender, quantity);
        } else {
            uint256 tmp = shuffledTokenIdsIndex;
            shuffledTokenIdsIndex+=quantity;

            uint256 i = 0;
            uint256[] memory tokenIds = new uint256[](quantity);
            while (i < quantity) {
                tokenIds[i] = shuffledTokenIds[tmp++];
                i++;
            }

            AlgocracyNFT.mintRandomNFT(msg.sender, tokenIds);
        }
    }
}