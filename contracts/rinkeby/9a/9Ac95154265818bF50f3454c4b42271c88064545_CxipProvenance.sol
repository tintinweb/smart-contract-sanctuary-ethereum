// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./interface/ICxipERC721.sol";
import "./interface/ICxipRegistry.sol";
import "./library/Address.sol";
import "./library/Signature.sol";
import "./struct/CollectionData.sol";
import "./struct/InterfaceType.sol";
import "./struct/Token.sol";
import "./struct/TokenData.sol";
import "./struct/Verification.sol";

/**
 * @title CXIP Provenance
 * @author CXIP-Labs
 * @notice A smart contract for managing and validating all of CXIP's provenance.
 * @dev For a CXIP Identity to be valid, it needs to be made through CXIP Provenance.
 */
contract CxipProvenance {
    /**
     * @dev Reentrancy implementation from OpenZepellin. State 1 == NOT_ENDERED, State 2 == ENTERED
     */
    uint256 private _reentrancyState;

    /**
     * @dev Array of addresses for all collection that were created by the identity.
     */
    address[] private _collectionArray;

    /**
     * @dev Map with interface type definitions for identity created collections.
     */
    mapping(address => InterfaceType) private _additionalInfo;

    /**
     * @notice Constructor is empty and only reentrancy guard is implemented.
     * @dev There is no data that needs to be set on first time deployment.
     */
    constructor() {
        _reentrancyState = 1;
    }

    /**
     * @dev Implementation from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
     */
    modifier nonReentrant() {
        require(_reentrancyState != 2, "ReentrancyGuard: reentrant call");
        _reentrancyState = 2;
        _;
        _reentrancyState = 1;
    }

    /**
     * @notice Check if an identity collection is open to external minting.
     * @dev For now this always returns false. Left as a placeholder for future development where shared collections might be used.
     * @dev Since it's not being used, the collection variable is commented out to avoid compiler warnings.
     * @return bool Returns true of false, to indicate if a specific collection is open/shared.
     */
    function isCollectionOpen(
        address/* collection*/
    ) external pure returns (bool) {
        return false;
    }

    /**
     * @notice Create an ERC721 collection.
     * @dev Creates and associates the ERC721 collection with the identity.
     * @param saltHash A salt used for deploying a collection to a specific address.
     * @param collectionCreator Specific wallet, associated with the identity, that will be marked as the creator of this collection.
     * @param verification Signature created by the collectionCreator wallet to validate the integrity of the collection data.
     * @param collectionData The collection data struct, with all the default collection info.
     * @return address Returns the address of the newly created collection.
     */
    function createERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData
    ) public nonReentrant returns (address) {
        if(collectionCreator != msg.sender) {
            require(
                Signature.Valid(
                    collectionCreator,
                    verification.r,
                    verification.s,
                    verification.v,
                    abi.encodePacked(
                        address(this),
                        collectionCreator,
                        collectionData.name,
                        collectionData.name2,
                        collectionData.symbol,
                        collectionData.royalties,
                        collectionData.bps
                    )
                ),
                "CXIP: invalid signature"
            );
        }
        bytes memory bytecode = hex"608060405234801561001057600080fd5b5060f68061001f6000396000f3fe60806040819052632c5feccb60e11b8152600090735fbdb2315678afecb367f032d93f642f64180aa3906358bfd99690608490602090600481865afa158015604b573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190606d91906092565b90503660008037600080366000845af43d6000803e808015608d573d6000f35b3d6000fd5b60006020828403121560a357600080fd5b81516001600160a01b038116811460b957600080fd5b939250505056fea26469706673582212200ccd0771ef68a12b3c78ffcaf88afcf10e0d0f2a51e9296249fb5a9282c0b42664736f6c634300080c0033";
        address cxipAddress;
        assembly {
            cxipAddress := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                saltHash
            )
        }
        ICxipERC721(cxipAddress).init(collectionCreator, collectionData);
        _addCollectionToEnumeration(cxipAddress, InterfaceType.ERC721);
        return(cxipAddress);
    }

    /**
     * @notice Create a custom ERC721 collection.
     * @dev Creates and associates the custom ERC721 collection with the identity.
     * @param saltHash A salt used for deploying a collection to a specific address.
     * @param collectionCreator Specific wallet, associated with the identity, that will be marked as the creator of this collection.
     * @param verification Signature created by the collectionCreator wallet to validate the integrity of the collection data.
     * @param collectionData The collection data struct, with all the default collection info.
     * @param slot Hash of proxy contract slot where the source is saved in registry.
     * @param bytecode The bytecode used for deployment. Validated against slot code for abuse prevention.
     * @return address Returns the address of the newly created collection.
     */
    function createCustomERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData,
        bytes32 slot,
        bytes memory bytecode
    ) public nonReentrant returns (address) {
        if(collectionCreator != msg.sender) {
            require(
                Signature.Valid(
                    collectionCreator,
                    verification.r,
                    verification.s,
                    verification.v,
                    abi.encodePacked(
                        address(this),
                        collectionCreator,
                        collectionData.name,
                        collectionData.name2,
                        collectionData.symbol,
                        collectionData.royalties,
                        collectionData.bps
                    )
                ),
                "CXIP: invalid signature"
            );
        }
        address cxipAddress;
        assembly {
            cxipAddress := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                saltHash
            )
        }
        require(
            keccak256(cxipAddress.code) == keccak256(ICxipRegistry(0x5FbDB2315678afecb367f032d93F642f64180aa3).getCustomSource(slot).code),
            "CXIP: byte code missmatch"
        );
        ICxipERC721(cxipAddress).init(collectionCreator, collectionData);
        _addCollectionToEnumeration(cxipAddress, InterfaceType.ERC721);
        return(cxipAddress);
    }

    /**
     * @dev This retrieves a collection by index. Don't be confused by the ID in the title.
     * @param index Index of the item to get from the array.
     * @return address Returns the collection contract address at that index of array.
     */
    function getCollectionById(uint256 index) public view returns (address) {
        return _collectionArray[index];
    }

    /**
     * @notice Get the collection's Interface Type: ERC20, ERC721, ERC1155.
     * @dev Collection must be associated with identity.
     * @param collection Contract address of the collection.
     * @return InterfaceType Returns an enum (uint8) of the collection interface type.
     */
    function getCollectionType(address collection) public view returns (InterfaceType) {
        return _additionalInfo[collection];
    }

    /**
     * @dev Reserved function for later use. Will be used to identify if collection was heavily vetted.
     * @param collection Contract address of the collection.
     * @return bool Returns true if collection is associated with the identity.
     */
    function isCollectionCertified(
        address collection
    ) public view returns (bool) {
        return _isCollectionValid(collection);
    }

    /**
     * @notice Check if a collection is registered with identity.
     * @dev For now will only return true for collections created directly from the identity contract.
     * @param collection Contract address of the collection.
     * @return bool Returns true if collection is associated with the identity.
     */
    function isCollectionRegistered(
        address collection
    ) public view returns (bool) {
        return _isCollectionValid(collection);
    }

    /**
     * @dev Reserved function for later use. Will be used to identify if token was heavily vetted.
     * @param collection Contract address of the collection.
     * @param tokenId Id of the token.
     * @return bool Returns true if token is associated with the identity.
     */
    function isTokenCertified(
        address collection,
        uint256 tokenId
    ) public view returns (bool) {
        return _isValidToken(collection, tokenId);
    }

    /**
     * @notice Check if a token is registered with identity.
     * @dev For now will only return true for tokens created directly from the identity contract.
     * @param collection Contract address of the collection.
     * @param tokenId Id of the token.
     * @return bool Returns true if token is associated with the identity.
     */
    function isTokenRegistered(
        address collection,
        uint256 tokenId
    ) public view returns (bool) {
        return _isValidToken(collection, tokenId);
    }

    /**
     * @notice List all collections associated with this identity.
     * @dev Use in conjunction with the totalCollections function, for pagination.
     * @param offset Index from where to start pagination. Start at 0.
     * @param length Length of slice to return, starting from offset index.
     * @return address[] Returns a fixed length array starting from offset.
     */
    function listCollections(
        uint256 offset,
        uint256 length
    ) public view returns (address[] memory) {
        uint256 limit = offset + length;
        if(limit > _collectionArray.length) {
            limit = _collectionArray.length;
        }
        address[] memory collections = new address[](limit - offset);
        uint256 n = 0;
        for(uint256 i = offset; i < limit; i++) {
            collections[n] = _collectionArray[i];
            n++;
        }
        return collections;
    }

    /**
     * @notice Get total number of collections associated with this identity.
     * @dev Use in conjunction with the listCollections, for pagination.
     * @return uint256 Returns the total length of collections.
     */
    function totalCollections() public view returns (uint256) {
        return _collectionArray.length;
    }

    /**
     * @dev Add collection to identity.
     * @param collection Contract address of the collection to add.
     * @param collectionType Interface type of the collection being added.
     */
    function _addCollectionToEnumeration(
        address collection,
        InterfaceType collectionType
    ) internal {
        _collectionArray.push(collection);
        _additionalInfo[collection] = collectionType;
    }

    /**
     * @dev Remove collection from identity.
     * @param index Array index of the collection to remove.
     */
    function _removeCollectionFromEnumeration(uint256 index) internal {
        require(
            _collectionArray.length != 0,
            "CXIP: removing from empty array"
        );
        delete _additionalInfo[_collectionArray[index]];
        uint256 lastIndex = _collectionArray.length - 1;
        if(lastIndex != 0) {
            if(index != lastIndex) {
                address lastCollection = _collectionArray[lastIndex];
                _collectionArray[index] = lastCollection;
            }
        }
        if(lastIndex == 0) {
            delete _collectionArray;
        } else {
            delete _collectionArray[lastIndex];
        }
    }

    /**
     * @dev Check if collection is associated with this identity.
     * @param collection Contract address of the collection.
     * @return bool Returns true if collection is associated with this identity.
     */
    function _isCollectionValid(
        address collection
    ) internal view returns (bool) {
        return _additionalInfo[collection] != InterfaceType.NULL;
    }

    /**
     * @dev Check if token is associated with this identity.
     * @param collection Contract address of the collection.
     * @dev Since it's not being used yet, the tokenId variable is commented out to avoid compiler warnings.
     * @return bool Returns true if token is associated with this identity.
     */
    function _isValidToken(
        address collection,
        uint256/* tokenId*/
    ) internal view returns (bool) {
        return _additionalInfo[collection] != InterfaceType.NULL;
    }

    /**
     * @dev Get the top-level CXIP Registry smart contract. Function must always be internal to prevent miss-use/abuse through bad programming practices.
     * @return ICxipRegistry The address of the top-level CXIP Registry smart contract.
     */
    function getRegistry() internal pure returns (ICxipRegistry) {
        return ICxipRegistry(0x5FbDB2315678afecb367f032d93F642f64180aa3);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "../struct/CollectionData.sol";
import "../struct/TokenData.sol";
import "../struct/Verification.sol";

interface ICxipERC721 {
    function arweaveURI(uint256 tokenId) external view returns (string memory);

    function contractURI() external view returns (string memory);

    function creator(uint256 tokenId) external view returns (address);

    function httpURI(uint256 tokenId) external view returns (string memory);

    function ipfsURI(uint256 tokenId) external view returns (string memory);

    function name() external view returns (string memory);

    function payloadHash(uint256 tokenId) external view returns (bytes32);

    function payloadSignature(uint256 tokenId) external view returns (Verification memory);

    function payloadSigner(uint256 tokenId) external view returns (address);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function tokensOfOwner(address wallet) external view returns (uint256[] memory);

    function verifySHA256(bytes32 hash, bytes calldata payload) external pure returns (bool);

    function approve(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function init(address newOwner, CollectionData calldata collectionData) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    function setApprovalForAll(address to, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external payable;

    function cxipMint(uint256 id, TokenData calldata tokenData) external returns (uint256);

    function setApprovalForAll(
        address from,
        address to,
        bool approved
    ) external;

    function setName(bytes32 newName, bytes32 newName2) external;

    function setSymbol(bytes32 newSymbol) external;

    function transferOwnership(address newOwner) external;

    function balanceOf(address wallet) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address wallet, address operator) external view returns (bool);

    function isOwner() external view returns (bool);

    function isOwner(address wallet) external view returns (bool);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address wallet, uint256 index) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

interface ICxipRegistry {
    function getCustomSource(bytes32 name) external view returns (address);

    function getCustomSourceFromString(string memory name) external view returns (address);

    function getERC1155CollectionSource() external view returns (address);

    function getERC721CollectionSource() external view returns (address);

    function getPA1D() external view returns (address);

    function getPA1DSource() external view returns (address);

    function getProvenance() external view returns (address);

    function getProvenanceSource() external view returns (address);

    function owner() external view returns (address);

    function setCustomSource(string memory name, address source) external;

    function setERC1155CollectionSource(address source) external;

    function setERC721CollectionSource(address source) external;

    function setPA1D(address proxy) external;

    function setPA1DSource(address source) external;

    function setProvenance(address proxy) external;

    function setProvenanceSource(address source) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 &&
            codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function isZero(address account) internal pure returns (bool) {
        return (account == address(0));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

library Signature {
    function Derive(
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory encoded
    )
        internal
        pure
        returns (
            address derived1,
            address derived2,
            address derived3,
            address derived4
        )
    {
        bytes32 encoded32;
        assembly {
            encoded32 := mload(add(encoded, 32))
        }
        derived1 = ecrecover(encoded32, v, r, s);
        derived2 = ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)),
            v,
            r,
            s
        );
        encoded32 = keccak256(encoded);
        derived3 = ecrecover(encoded32, v, r, s);
        encoded32 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32));
        derived4 = ecrecover(encoded32, v, r, s);
    }

    function PackMessage(bytes memory encoded, bool geth) internal pure returns (bytes32) {
        bytes32 hash = keccak256(encoded);
        if (geth) {
            hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        }
        return hash;
    }

    function Valid(
        address target,
        bytes32 r,
        bytes32 s,
        uint8 v,
        bytes memory encoded
    ) internal pure returns (bool) {
        bytes32 encoded32;
        address derived;
        if (encoded.length == 32) {
            assembly {
                encoded32 := mload(add(encoded, 32))
            }
            derived = ecrecover(encoded32, v, r, s);
            if (target == derived) {
                return true;
            }
            derived = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", encoded32)),
                v,
                r,
                s
            );
            if (target == derived) {
                return true;
            }
        }
        bytes32 hash = keccak256(encoded);
        derived = ecrecover(hash, v, r, s);
        if (target == derived) {
            return true;
        }
        hash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        derived = ecrecover(hash, v, r, s);
        return target == derived;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./UriType.sol";

struct CollectionData {
    bytes32 name;
    bytes32 name2;
    bytes32 symbol;
    address royalties;
    uint96 bps;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

// This is a 256 value limit (uint8)
enum InterfaceType {
    NULL, // 0
    ERC20, // 1
    ERC721, // 2
    ERC1155 // 3
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./InterfaceType.sol";

struct Token {
    address collection;
    uint256 tokenId;
    InterfaceType tokenType;
    address creator;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

import "./Verification.sol";

struct TokenData {
    bytes32 payloadHash;
    Verification payloadSignature;
    address creator;
    bytes32 arweave;
    bytes11 arweave2;
    bytes32 ipfs;
    bytes14 ipfs2;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

struct Verification {
    bytes32 r;
    bytes32 s;
    uint8 v;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

// This is a 256 value limit (uint8)
enum UriType {
    ARWEAVE, // 0
    IPFS, // 1
    HTTP // 2
}