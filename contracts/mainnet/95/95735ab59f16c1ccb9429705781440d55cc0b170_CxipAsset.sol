/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

/*______/\\\\\\\\\__/\\\_______/\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\___
 _____/\\\////////__\///\\\___/\\\/__\/////\\\///__\/\\\/////////\\\_
  ___/\\\/_____________\///\\\\\\/________\/\\\_____\/\\\_______\/\\\_
   __/\\\_________________\//\\\\__________\/\\\_____\/\\\\\\\\\\\\\/__
    _\/\\\__________________\/\\\\__________\/\\\_____\/\\\/////////____
     _\//\\\_________________/\\\\\\_________\/\\\_____\/\\\_____________
      __\///\\\_____________/\\\////\\\_______\/\\\_____\/\\\_____________
       ____\////\\\\\\\\\__/\\\/___\///\\\__/\\\\\\\\\\\_\/\\\_____________
        _______\/////////__\///_______\///__\///////////__\///____________*/

/**
 * @title CXIP Asset
 * @author CXIP-Labs
 * @notice A smart contract for providing a single entry for checking validity of collections and tokens minted through CXIP.
 * @dev Listen events broadcasted by this smart contract, to get all collections and NFT being minted with CXIP smart contracts.
 */
contract CxipAsset {
	function getRegistry () internal pure returns (ICxipRegistry) {
		return ICxipRegistry (0xC267d41f81308D7773ecB3BDd863a902ACC01Ade);
	}

	using Address for address;

	event CollectionAdded (address collectionAddress, address creatorWallet);
	event CollectionCreated (address collectionAddress, address creatorWallet);
	event TokenAdded (address collectionAddress, address creatorWallet, uint256 tokenId);
	event TokenCreated (address collectionAddress, address creatorWallet, uint256 tokenId);

	UriType private _defaultUri;

	mapping (address => address) _collectionIdentity;

	constructor () {
		_defaultUri = UriType.ARWEAVE;
	}

	function defaultUriType () public view returns (UriType) {
		return _defaultUri;
	}

	function AddCollection (address creator, address collection, bool fresh) public {
		address identityAddress = msg.sender;
		require (
			ICxipProvenance (getRegistry ().getProvenance ()).isIdentityValid (identityAddress),
			'CXIP: invalid Identity contract'
		);
		ICxipIdentity identity = ICxipIdentity (identityAddress);
		require (identity.isWalletRegistered (creator), 'CXIP: creator wallet not owner');
		require (identity.isCollectionRegistered (collection), 'CXIP: not registered collection');
		bool certified = false;
		if (fresh) {
			require (identity.isNew (), 'CXIP: not a new collection');
			certified = true;
			emit CollectionCreated (collection, creator);
		} else {
			emit CollectionAdded (collection, creator);
		}
		_collectionIdentity [collection] = identityAddress;
	}

	function AddToken (address creator, address collection, uint256 tokenId, bool fresh) public {
		address identityAddress = msg.sender;
		require (
			ICxipProvenance (getRegistry ().getProvenance ()).isIdentityValid (identityAddress),
			'CXIP: invalid Identity contract'
		);
		ICxipIdentity identity = ICxipIdentity (identityAddress);
		require (identity.isWalletRegistered (creator), 'CXIP: creator wallet not owner');
		require (identity.isCollectionRegistered (collection), 'CXIP: not registered collection');
		require (identity.isTokenRegistered (collection, tokenId), 'CXIP: not registered token');
		bool certified = false;
		if (fresh) {
			require (identity.isNew (), 'CXIP: not a new collection token');
			certified = true;
			emit TokenCreated (collection, creator, tokenId);
		} else {
			emit TokenAdded (collection, creator, tokenId);
		}
	}

	function _getIdentity (address collection) internal view returns (ICxipIdentity) {
		address identityAddress = _collectionIdentity [collection];
		return ICxipIdentity (identityAddress);
	}

	function getCollectionIdentity (address collection) public view returns (address) {
		ICxipIdentity identity = _getIdentity (collection);
		return address (identity);
	}

	function getCollectionType (address collection) public view returns (InterfaceType) {
		ICxipIdentity identity = _getIdentity (collection);
		require (!address (identity).isZero (), 'CXIP: not registered collection');
		return identity.getCollectionType (collection);
	}

	function isCollectionOpen (address collection) public view returns (bool) {
		ICxipIdentity identity = _getIdentity (collection);
		if (address (identity).isZero ()) {
			return false;
		}
		return identity.isCollectionOpen (collection);
	}

	function isCollectionCertified (address collection) public view returns (bool) {
		ICxipIdentity identity = _getIdentity (collection);
		if (address (identity).isZero ()) {
			return false;
		}
		return identity.isCollectionCertified (collection);
	}

	function isCollectionRegistered (address collection) public view returns (bool) {
		ICxipIdentity identity = _getIdentity (collection);
		if (address (identity).isZero ()) {
			return false;
		}
		return identity.isCollectionRegistered (collection);
	}

	function isTokenCertified (address collection, uint256 tokenId) public view returns (bool) {
		ICxipIdentity identity = _getIdentity (collection);
		if (address (identity).isZero ()) {
			return false;
		}
		return identity.isTokenCertified (collection, tokenId);
	}

	function isTokenRegistered (address collection, uint256 tokenId) public view returns (bool) {
		ICxipIdentity identity = _getIdentity (collection);
		if (address (identity).isZero ()) {
			return false;
		}
		return identity.isTokenRegistered (collection, tokenId);
	}
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }

    function isZero(address account) internal pure returns (bool) {
        return (account == address(0));
    }
}

struct CollectionData {
    bytes32 name;
    bytes32 name2;
    bytes32 symbol;
    address royalties;
    uint96 bps;
}

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

    /* Disabled due to tokenEnumeration not enabled.
    function tokensOfOwner(
        address wallet
    ) external view returns (uint256[] memory);
    */

    function verifySHA256(bytes32 hash, bytes calldata payload) external pure returns (bool);

    function approve(address to, uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function init(address newOwner, CollectionData calldata collectionData) external;

    /* Disabled since this flow has not been agreed on.
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
    */

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

    /*
    // Disabled due to tokenEnumeration not enabled.
    function balanceOf(address wallet) external view returns (uint256);
    */
    function baseURI() external view returns (string memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function getIdentity() external view returns (address);

    function isApprovedForAll(address wallet, address operator) external view returns (bool);

    function isOwner() external view returns (bool);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    /* Disabled due to tokenEnumeration not enabled.
    function tokenByIndex(uint256 index) external view returns (uint256);
    */

    /* Disabled due to tokenEnumeration not enabled.
    function tokenOfOwnerByIndex(
        address wallet,
        uint256 index
    ) external view returns (uint256);
    */

    /* Disabled due to tokenEnumeration not enabled.
    function totalSupply() external view returns (uint256);
    */

    function totalSupply() external view returns (uint256);

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4);
}

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

    function listCollections(uint256 offset, uint256 length) external view returns (address[] memory);

    function nextNonce(address wallet) external view returns (uint256);

    function totalCollections() external view returns (uint256);

    function isCollectionOpen(address collection) external pure returns (bool);
}

interface ICxipProvenance {
    function createIdentity(
        bytes32 saltHash,
        address wallet,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256, address);

    function createIdentityBatch(
        bytes32 saltHash,
        address[] memory wallets,
        uint8[] memory V,
        bytes32[] memory RS
    ) external returns (uint256, address);

    function getIdentity() external view returns (address);

    function getWalletIdentity(address wallet) external view returns (address);

    function informAboutNewWallet(address newWallet) external;

    function isIdentityValid(address identity) external view returns (bool);

    function nextNonce(address wallet) external view returns (uint256);
}

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

// This is a 256 value limit (uint8)
enum InterfaceType {
    NULL, // 0
    ERC20, // 1
    ERC721, // 2
    ERC1155 // 3
}

struct Token {
    address collection;
    uint256 tokenId;
    InterfaceType tokenType;
    address creator;
}

struct TokenData {
    bytes32 payloadHash;
    Verification payloadSignature;
    address creator;
    bytes32 arweave;
    bytes11 arweave2;
    bytes32 ipfs;
    bytes14 ipfs2;
}

// This is a 256 value limit (uint8)
enum UriType {
    ARWEAVE, // 0
    IPFS, // 1
    HTTP // 2
}

struct Verification {
    bytes32 r;
    bytes32 s;
    uint8 v;
}