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

import "./interface/ICxipIdentity.sol";
import "./interface/ICxipRegistry.sol";
import "./library/Address.sol";
import "./library/Signature.sol";
import "./struct/Verification.sol";

/**
 * @title CXIP Provenance
 * @author CXIP-Labs
 * @notice A smart contract for managing and validating all of CXIP's provenance.
 * @dev For a CXIP Identity to be valid, it needs to be made through CXIP Provenance.
 */
contract CxipProvenance {
    /**
     * @dev Complete map of all wallets and their associated identities.
     */
    mapping(address => address) private _walletToIdentityMap;
    /**
     * @dev Used for mapping created identity addresses.
     */
    mapping(address => bool) private _identityMap;
    /**
     * @dev Special map for storing blacklisted identities.
     */
    mapping(address => bool) private _blacklistMap;

    /**
     * @dev Reentrancy implementation from OpenZepellin. State 1 == NOT_ENDERED, State 2 == ENTERED
     */
    uint256 private _reentrancyState;

    /**
     * @notice Event emitted when an identity gets blacklisted.
     * @dev This is reserved for later use, in cases where an identity needs to be publicly blacklisted.
     * @param identityAddress Address of the identity being blacklisted.
     * @param reason A string URI to Arweave, IPFS, or HTTP with a detailed explanation for the blacklist.
     */
    event IdentityBlacklisted(address indexed identityAddress, string reason);
    /**
     * @notice Event emitted when a new identity is created.
     * @dev Can subscribe to this even on Provenance to get all CXIP created identities.
     * @param identityAddress Address of the identity being created.
     */
    event IdentityCreated(address indexed identityAddress);
    /**
     * @notice Event emitted when a new wallet is added to the identity.
     * @dev A wallet can only be added to one identity. It will not be possible to ever use it with another identity after that.
     * @param identityAddress Address of the identity being created.
     * @param initiatingWallet The address of wallet that initiated adding the new wallet.
     * @param newWallet The address of new wallet being added.
     */
    event IdentityWalletAdded(
        address indexed identityAddress,
        address indexed initiatingWallet,
        address indexed newWallet
    );

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
     * @notice Create a new identity smart contract.
     * @dev Only a wallet that is not already associated with any CXIP Identity can create a new identity.
     * @param saltHash A salt made up of 12 bytes random data and 20 bytes msg.sender address.
     * @param secondaryWallet An additional wallet to add to identity. Used mostly for proxy wallets.
     * @param verification Signatures made by msg.sender to validate identity creation.
     */
    function createIdentity(
        bytes32 saltHash,
        address secondaryWallet,
        Verification calldata verification
    ) public nonReentrant {
        bool usingSecondaryWallet = !Address.isZero(secondaryWallet);
        address wallet = msg.sender;
        require(
            !Address.isContract(wallet),
            "CXIP: cannot use smart contracts"
        );
        require(
            Address.isZero(_walletToIdentityMap[wallet]),
            "CXIP: wallet already used"
        );
        require(
            address(
                uint160(
                    bytes20(saltHash)
                )
            ) == wallet,
            "CXIP: invalid salt hash"
        );
        if(usingSecondaryWallet) {
            require(
                !Address.isContract(secondaryWallet),
                "CXIP: cannot use smart contracts"
            );
            require(
                Address.isZero(_walletToIdentityMap[secondaryWallet]),
                "CXIP: second wallet already used"
            );
            require(
                Signature.Valid(
                    secondaryWallet,
                    verification.r,
                    verification.s,
                    verification.v,
                    abi.encodePacked(
                        address(this),
                        wallet,
                        secondaryWallet
                    )
                ),
                "CXIP: invalid signature"
            );
        }
        bytes memory bytecode = hex"608060405234801561001057600080fd5b5060f68061001f6000396000f3fe6080604081905263071b938d60e31b815260009073e7f1725e7734ce288f8367e1bb143e90bb3f0512906338dc9c6890608490602090600481865afa158015604b573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190606d91906092565b90503660008037600080366000845af43d6000803e808015608d573d6000f35b3d6000fd5b60006020828403121560a357600080fd5b81516001600160a01b038116811460b957600080fd5b939250505056fea26469706673582212208946e1a7de585e83ddba36332acc62598a9d62e903d96e35157330f329e2f70d64736f6c634300080c0033";
        address identityAddress;
        assembly {
            identityAddress := create2(
                0,
                add(bytecode, 0x20),
                mload(bytecode),
                saltHash
            )
        }
        ICxipIdentity(identityAddress).init(wallet, secondaryWallet);
        _walletToIdentityMap[wallet] = identityAddress;
        _identityMap[identityAddress] = true;
        _notifyIdentityCreated(identityAddress);
        _notifyIdentityWalletAdded(identityAddress, wallet, wallet);
        if(usingSecondaryWallet) {
            _notifyIdentityWalletAdded(
                identityAddress,
                wallet,
                secondaryWallet
            );
        }
    }

    /**
     * @notice Tells provenance to emit IdentityWalletAdded event(s).
     * @dev Can only be called by a valid identity associated wallet.
     * @param newWallet Address of wallet to emit event for.
     */
    function informAboutNewWallet(address newWallet) public nonReentrant {
        address identityAddress = msg.sender;
        require(
            _identityMap[identityAddress],
            "CXIP: invalid Identity contract"
        );
        require(
            Address.isZero(_walletToIdentityMap[newWallet]),
            "CXIP: wallet already added"
        );
        ICxipIdentity identity = ICxipIdentity(identityAddress);
        require(
            identity.isWalletRegistered(newWallet),
            "CXIP: unregistered wallet"
        );
        _notifyIdentityWalletAdded(
            identityAddress,
            identity.getAuthorizer(newWallet),
            newWallet
        );
        _walletToIdentityMap[newWallet] = identityAddress;
    }

    /**
     * @notice Get the identity of current wallet.
     * @dev Gets identity of msg.sender.
     * @return address Returns an identity contract address, or zero address if wallet is not associated with any identity.
     */
    function getIdentity() public view returns (address) {
        return _walletToIdentityMap[msg.sender];
    }

    /**
     * @notice Get the identity associated with a wallet.
     * @dev Can also be used to check if a wallet can create a new identity.
     * @param wallet Address of wallet to get identity for.
     * @return address Returns an identity contract address, or zero address if wallet is not associated with any identity.
     */
    function getWalletIdentity(address wallet) public view returns (address) {
        return _walletToIdentityMap[wallet];
    }

    /**
     * @notice Check if an identity is blacklisted.
     * @dev This is an optional function that can be used to decide if an identity should be not interacted with.
     * @param identityAddress Contract address of the identity
     * @return bool Returns true if identity was blacklisted.
     */
    function isIdentityBlacklisted(
        address identityAddress
    ) public view returns (bool) {
        return _blacklistMap[identityAddress];
    }

    /**
     * @notice Check if an identity is valid.
     * @dev This is used to ensure provenance and prevent malicious actors from creating smart contract clones.
     * @param identityAddress Contract address of the identity
     * @return bool Returns true if identity was created through proper provenance.
     */
    function isIdentityValid(
        address identityAddress
    ) public view returns (bool) {
        return (
            _identityMap[identityAddress]
            && !_blacklistMap[identityAddress]
        );
    }

    /**
     * @dev Trigger the IdentityBlacklisted event.
     * @param contractAddress Address of identity that is being blacklisted.
     * @param reason String URI of Arweave, IPFS, or HTTP link explaining reason for blacklisting.
     */
    function _notifyIdentityBlacklisted(
        address contractAddress,
        string calldata reason
    ) internal {
        emit IdentityBlacklisted(contractAddress, reason);
    }

    /**
     * @dev Trigger the IdentityCreated event.
     * @param contractAddress Address of identity that is being created.
     */
    function _notifyIdentityCreated(address contractAddress) internal {
        emit IdentityCreated(contractAddress);
    }

    /**
     * @dev Trigger the IdentityWalletAdded event.
     * @param identityAddress Address of identity that wallet is being added to.
     * @param intiatingWallet Address of wallet that is triggering this event.
     * @param newWallet Address of wallet that is being added to this identity.
     */
    function _notifyIdentityWalletAdded(
        address identityAddress,
        address intiatingWallet,
        address newWallet
    ) internal {
        emit IdentityWalletAdded(identityAddress, intiatingWallet, newWallet);
    }

    /**
     * @dev Get the top-level CXIP Registry smart contract. Function must always be internal to prevent miss-use/abuse through bad programming practices.
     * @return ICxipRegistry The address of the top-level CXIP Registry smart contract.
     */
    function getRegistry() internal pure returns (ICxipRegistry) {
        return ICxipRegistry(0x415225c0d082CB195AeE69f490c218def30966da);
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
import "../struct/InterfaceType.sol";
import "../struct/Token.sol";
import "../struct/TokenData.sol";

interface ICxipIdentity {
    function addSignedWallet(
        address newWallet,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function addWallet(address newWallet) external;

    function connectWallet() external;

    function createERC721Token(
        address collection,
        uint256 id,
        TokenData calldata tokenData,
        Verification calldata verification
    ) external returns (uint256);

    function createERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData
    ) external returns (address);

    function createCustomERC721Collection(
        bytes32 saltHash,
        address collectionCreator,
        Verification calldata verification,
        CollectionData calldata collectionData,
        bytes32 slot,
        bytes memory bytecode
    ) external returns (address);

    function init(address wallet, address secondaryWallet) external;

    function getAuthorizer(address wallet) external view returns (address);

    function getCollectionById(uint256 index) external view returns (address);

    function getCollectionType(address collection) external view returns (InterfaceType);

    function getWallets() external view returns (address[] memory);

    function isCollectionCertified(address collection) external view returns (bool);

    function isCollectionRegistered(address collection) external view returns (bool);

    function isNew() external view returns (bool);

    function isOwner() external view returns (bool);

    function isTokenCertified(address collection, uint256 tokenId) external view returns (bool);

    function isTokenRegistered(address collection, uint256 tokenId) external view returns (bool);

    function isWalletRegistered(address wallet) external view returns (bool);

    function listCollections(uint256 offset, uint256 length)
        external
        view
        returns (address[] memory);

    function nextNonce(address wallet) external view returns (uint256);

    function totalCollections() external view returns (uint256);

    function isCollectionOpen(address collection) external pure returns (bool);
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
    function getAsset() external view returns (address);

    function getAssetSigner() external view returns (address);

    function getAssetSource() external view returns (address);

    function getCopyright() external view returns (address);

    function getCopyrightSource() external view returns (address);

    function getCustomSource(bytes32 name) external view returns (address);

    function getCustomSourceFromString(string memory name) external view returns (address);

    function getERC1155CollectionSource() external view returns (address);

    function getERC721CollectionSource() external view returns (address);

    function getIdentitySource() external view returns (address);

    function getPA1D() external view returns (address);

    function getPA1DSource() external view returns (address);

    function getProvenance() external view returns (address);

    function getProvenanceSource() external view returns (address);

    function owner() external view returns (address);

    function setAsset(address proxy) external;

    function setAssetSigner(address source) external;

    function setAssetSource(address source) external;

    function setCopyright(address proxy) external;

    function setCopyrightSource(address source) external;

    function setCustomSource(string memory name, address source) external;

    function setERC1155CollectionSource(address source) external;

    function setERC721CollectionSource(address source) external;

    function setIdentitySource(address source) external;

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

// This is a 256 value limit (uint8)
enum UriType {
    ARWEAVE, // 0
    IPFS, // 1
    HTTP // 2
}