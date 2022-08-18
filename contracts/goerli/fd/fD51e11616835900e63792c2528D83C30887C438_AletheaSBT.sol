// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RoyalSBT.sol";

/**
 * @title Alethea SBT
 *
 * @notice Alethea SBT is soulbound token implementation
 *
 * @dev Alethea SBT is a Tiny SBT, it supports batch minting and burning,
 *      its token ID space is limited to 32 bits
 *
 * @author Basil Gorin
 */
contract AletheaSBT is RoyalSBT {
	/**
	 * @inheritdoc TinySBT
	 */
	uint256 public constant override TOKEN_UID = 0x2f364f57d77e8b29071fc2349fa6ed9b9834a2db406a6e0a60f625f2d1d6a8c6;

	/**
	 * @dev Constructs/deploys Alethea SBT instance
	 *      with the name and symbol defined during the deployment
	 */
	constructor(string memory _name, string memory _symbol) RoyalSBT(_name, _symbol) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./TinySBT.sol";

/**
 * @title Royal ER721
 *
 * @dev Introduces fake "owner" to support OpenSea collections
 *
 * @author Basil Gorin
 */
abstract contract RoyalSBT is TinySBT {
	/**
	 * @dev OpenSea expects NFTs to be "Ownable", that is having an "owner",
	 *      we introduce a fake "owner" here with no authority
	 */
	address public owner;

	/**
	 * @notice Contract level metadata to define collection name, description, and royalty fees.
	 *         see https://docs.opensea.io/docs/contract-level-metadata
	 *
	 * @dev Should be set by URI manager. Empty by default
	 */
	string public contractURI;

	/**
	 * @notice Owner manager is responsible for setting/updating an "owner" field
	 *
	 * @dev Role ROLE_OWNER_MANAGER allows updating the "owner" field
	 *      (executing `setOwner` function)
	 */
	uint32 public constant ROLE_OWNER_MANAGER = 0x0040_0000;

	/**
	 * @dev Fired in setContractURI()
	 *
	 * @param _by an address which executed update
	 * @param _value new contractURI value
	 */
	event ContractURIUpdated(address indexed _by, string _value);

	/**
	 * @dev Fired in setOwner()
	 *
	 * @param _by an address which set the new "owner"
	 * @param _oldVal previous "owner" address
	 * @param _newVal new "owner" address
	 */
	event OwnerUpdated(address indexed _by, address indexed _oldVal, address indexed _newVal);

	/**
	 * @dev Fired in setOwner() - OpenZeppelin Ownable compliant event
	 *
	 * @param previousOwner previous "owner" address
	 * @param newOwner new "owner" address
	 */
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Constructs/deploys ERC721 with EIP-2981 instance with the name and symbol specified
	 *
	 * @param _name token name (ERC721Metadata)
	 * @param _symbol token symbol (ERC721Metadata)
	 */
	constructor(string memory _name, string memory _symbol) TinySBT(_name, _symbol) {
		// initialize the "owner" as a deployer account
		owner = msg.sender;
	}

	/**
	 * @dev Restricted access function which updates the contract URI
	 *
	 * @dev Requires executor to have ROLE_URI_MANAGER permission
	 *
	 * @param _contractURI new contract URI to set
	 */
	function setContractURI(string memory _contractURI) public {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// update the contract URI
		contractURI = _contractURI;

		// emit an event
		emit ContractURIUpdated(msg.sender, _contractURI);
	}

	/**
	 * @notice Checks if the address supplied is an "owner" of the smart contract
	 *      Note: an "owner" doesn't have any authority on the smart contract and is "nominal"
	 *
	 * @return true if the caller is the current owner.
	 */
	function isOwner(address _addr) public view returns(bool) {
		// just evaluate and return the result
		return _addr == owner;
	}

	/**
	 * @dev Restricted access function to set smart contract "owner"
	 *      Note: an "owner" set doesn't have any authority, and cannot even update "owner"
	 *
	 * @dev Requires executor to have ROLE_OWNER_MANAGER permission
	 *
	 * @param _owner new "owner" of the smart contract
	 */
	function transferOwnership(address _owner) public {
		// verify the access permission
		require(isSenderInRole(ROLE_OWNER_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit OwnerUpdated(msg.sender, owner, _owner);

		// emit zeppelin ownable-compliant ownership transfer event
		emit OwnershipTransferred(owner, _owner);

		// update "owner"
		owner = _owner;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC721Spec.sol";
import "../interfaces/AletheaERC721Spec.sol";
import "../lib/AddressUtils.sol";
import "../lib/ArrayUtils.sol";
import "../lib/StringUtils.sol";
import "../utils/AccessControl.sol";

/**
 * @title Tiny SBT (Soulbound Token)
 *
 * @notice SBT is an NFT without transfer capabilities
 *
 * @dev Tiny SBT defines a Soulbound Token with 32 bits ID space.
 *
 * @dev See TinyERC721.sol for ERC721 related design ideas and implementation details.
 *
 * @dev Following ERC721 functions are removed (disabled):
 *      - getApproved
 *      - isApprovedForAll
 *      - approve
 *      - setApprovalForAll
 *      - safeTransferFrom
 *      - transferFrom
 *
 * @author Basil Gorin
 */
abstract contract TinySBT is ERC721Enumerable, ERC721Metadata, WithBaseURI, MintableERC721, BurnableERC721, AccessControl {
	// enable push32 optimization for uint32[]
	using ArrayUtils for uint32[];

	/**
	 * @dev Smart contract unique identifier, a random number
	 *
	 * @dev Should be regenerated each time smart contact source code is changed
	 *      and changes smart contract itself is to be redeployed
	 *
	 * @dev Generated using https://www.random.org/bytes/
	 * @dev Example value: 0xdbdd2b4ff38a8516da0b8e7ae93288b5e2fed0c92fb051cee90ccf4e4ec9736e
	 */
	function TOKEN_UID() external view virtual returns(uint256);

	/**
	 * @notice ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 *
	 * @inheritdoc ERC721Metadata
	 */
	string public override name;

	/**
	 * @notice ERC-20 compatible abbreviated name for a collection of NFTs in this contract
	 *
	 * @inheritdoc ERC721Metadata
	 */
	string public override symbol;

	/**
	 * @notice Current implementation includes a function `decimals` that returns uint8(0)
	 *      to be more compatible with ERC-20
	 *
	 * @dev ERC20 compliant token decimals is equal to zero since ERC721 token is non-fungible
	 *      and therefore non-divisible
	 */
	uint8 public constant decimals = 0;

	/**
	 * @notice Ownership information for all the tokens in existence
	 *
	 * @dev Maps `Token ID => Token ID Global Index | Token ID Local Index | Token Owner Address`, where
	 *      - Token ID Global Index denotes Token ID index in the array of all the tokens,
	 *      - Token ID Local Index denotes Token ID index in the array of all the tokens owned by the owner,
	 *      - Token ID indexes are 32 bits long,
	 *      - `|` denotes bitwise concatenation of the values
	 * @dev Token Owner Address for a given Token ID is lower 160 bits of the mapping value
	 */
	mapping(uint256 => uint256) internal tokens;

	/**
	 * @notice Enumerated collections of the tokens owned by particular owners
	 *
	 * @dev We call these collections "Local" token collections
	 *
	 * @dev Maps `Token Owner Address => Owned Token IDs Array`
	 *
	 * @dev Token owner balance is the length of their token collection:
	 *      `balanceOf(owner) = collections[owner].length`
	 */
	mapping(address => uint32[]) internal collections;

	/**
	 * @notice An array of all the tokens in existence
	 *
	 * @dev We call this collection "Global" token collection
	 *
	 * @dev Array with all Token IDs, used for enumeration
	 *
	 * @dev Total token supply `tokenSupply` is the length of this collection:
	 *      `totalSupply() = allTokens.length`
	 */
	uint32[] internal allTokens;

	/**
	 * @dev Base URI is used to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 *
	 * @dev If token URI is set with `setTokenURI()` it will be returned as is via `tokenURI()`
	 */
	string public override baseURI = "";

	/**
	 * @dev Optional mapping for token URIs to be returned as is when `tokenURI()`
	 *      is called; if mapping doesn't exist for token, the URI is constructed
	 *      as `base URI + token ID`, where plus (+) denotes string concatenation
	 */
	mapping(uint256 => string) internal _tokenURIs;

	/**
	 * @dev 32 bit token ID space is optimal for batch minting in batches of size 8
	 *      8 * 32 = 256 - single storage slot in global/local collection(s)
	 */
	uint8 public constant BATCH_SIZE_MULTIPLIER = 8;

	/**
	 * @notice Enables token owners to burn their own tokens
	 *
	 * @dev Feature FEATURE_OWN_BURNS must be enabled in order for
	 *      `burn()` function to succeed when called by token owner
	 */
	uint32 public constant FEATURE_OWN_BURNS = 0x0000_0008;

	/**
	 * @notice Token creator is responsible for creating (minting)
	 *      tokens to an arbitrary address
	 * @dev Role ROLE_TOKEN_CREATOR allows minting tokens
	 *      (calling `mint` function)
	 */
	uint32 public constant ROLE_TOKEN_CREATOR = 0x0001_0000;

	/**
	 * @notice Token destroyer is responsible for destroying (burning)
	 *      tokens owned by an arbitrary address
	 * @dev Role ROLE_TOKEN_DESTROYER allows burning tokens
	 *      (calling `burn` function)
	 */
	uint32 public constant ROLE_TOKEN_DESTROYER = 0x0002_0000;

	/**
	 * @notice URI manager is responsible for managing base URI
	 *      part of the token URI ERC721Metadata interface
	 *
	 * @dev Role ROLE_URI_MANAGER allows updating the base URI
	 *      (executing `setBaseURI` function)
	 */
	uint32 public constant ROLE_URI_MANAGER = 0x0010_0000;

	/**
	 * @dev Fired in setBaseURI()
	 *
	 * @param _by an address which executed update
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event BaseURIUpdated(address indexed _by, string _oldVal, string _newVal);

	/**
	 * @dev Fired in setTokenURI()
	 *
	 * @param _by an address which executed update
	 * @param _tokenId token ID which URI was updated
	 * @param _oldVal old _baseURI value
	 * @param _newVal new _baseURI value
	 */
	event TokenURIUpdated(address indexed _by, uint256 _tokenId, string _oldVal, string _newVal);

	/**
	 * @dev Constructs/deploys ERC721 instance with the name and symbol specified
	 *
	 * @param _name name of the token to be accessible as `name()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 * @param _symbol token symbol to be accessible as `symbol()`,
	 *      ERC-20 compatible descriptive name for a collection of NFTs in this contract
	 */
	constructor(string memory _name, string memory _symbol) {
		// set the name
		name = _name;

		// set the symbol
		symbol = _symbol;
	}

	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @inheritdoc MintableERC721
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) public override view returns(bool) {
		// read ownership information and return a check if it's not zero (set)
		return tokens[_tokenId] != 0;
	}

	/**
	 * @inheritdoc ERC165
	 */
	function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
		// construct the interface support from required and optional ERC721 interfaces
		return interfaceId == type(ERC165).interfaceId
			|| interfaceId == type(ERC721).interfaceId
			|| interfaceId == type(ERC721Metadata).interfaceId
			|| interfaceId == type(ERC721Enumerable).interfaceId
			|| interfaceId == type(MintableERC721).interfaceId
			|| interfaceId == type(BurnableERC721).interfaceId;
	}

	// ===== Start: ERC721 Metadata =====

	/**
	 * @dev Restricted access function which updates base URI used to construct
	 *      ERC721Metadata.tokenURI
	 *
	 * @dev Requires executor to have ROLE_URI_MANAGER permission
	 *
	 * @param _baseURI new base URI to set
	 */
	function setBaseURI(string memory _baseURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// emit an event first - to log both old and new values
		emit BaseURIUpdated(msg.sender, baseURI, _baseURI);

		// and update base URI
		baseURI = _baseURI;
	}

	/**
	 * @dev Returns token URI if it was previously set with `setTokenURI`,
	 *      otherwise constructs it as base URI + token ID
	 *
	 * @inheritdoc ERC721Metadata
	 */
	function tokenURI(uint256 _tokenId) public view override returns (string memory) {
		// verify token exists
		require(exists(_tokenId), "token doesn't exist");

		// read the token URI for the token specified
		string memory _tokenURI = _tokenURIs[_tokenId];

		// if token URI is set
		if(bytes(_tokenURI).length > 0) {
			// just return it
			return _tokenURI;
		}

		// if base URI is not set
		if(bytes(baseURI).length == 0) {
			// return an empty string
			return "";
		}

		// otherwise concatenate base URI + token ID
		return StringUtils.concat(baseURI, StringUtils.itoa(_tokenId, 10));
	}

	/**
	 * @dev Sets the token URI for the token defined by its ID
	 *
	 * @param _tokenId an ID of the token to set URI for
	 * @param _tokenURI token URI to set
	 */
	function setTokenURI(uint256 _tokenId, string memory _tokenURI) public virtual {
		// verify the access permission
		require(isSenderInRole(ROLE_URI_MANAGER), "access denied");

		// we do not verify token existence: we want to be able to
		// preallocate token URIs before tokens are actually minted

		// emit an event first - to log both old and new values
		emit TokenURIUpdated(msg.sender, _tokenId, _tokenURIs[_tokenId], _tokenURI);

		// and update token URI
		_tokenURIs[_tokenId] = _tokenURI;
	}

	// ===== End: ERC721 Metadata =====

	// ===== Start: ERC721, ERC721Enumerable Getters (view functions) =====

	/**
	 * @inheritdoc ERC721
	 */
	function balanceOf(address _owner) public view override returns (uint256) {
		// check `_owner` address is set
		require(_owner != address(0), "zero address");

		// derive owner balance for the their owned tokens collection
		// as the length of that collection
		return collections[_owner].length;
	}

	/**
	 * @inheritdoc ERC721
	 */
	function ownerOf(uint256 _tokenId) public view override returns (address) {
		// derive ownership information of the token from the ownership mapping
		// by extracting lower 160 bits of the mapping value as an address
		address owner = address(uint160(tokens[_tokenId]));

		// verify owner/token exists
		require(owner != address(0), "token doesn't exist");

		// return owner address
		return owner;
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function totalSupply() public view override returns (uint256) {
		// derive total supply value from the array of all existing tokens
		// as the length of this array
		return allTokens.length;
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function tokenByIndex(uint256 _index) public view override returns (uint256) {
		// index out of bounds check
		require(_index < totalSupply(), "index out of bounds");

		// find the token ID requested and return
		return allTokens[_index];
	}

	/**
	 * @inheritdoc ERC721Enumerable
	 */
	function tokenOfOwnerByIndex(address _owner, uint256 _index) public view override returns (uint256) {
		// index out of bounds check
		require(_index < balanceOf(_owner), "index out of bounds");

		// find the token ID requested and return
		return collections[_owner][_index];
	}

	/**
	 * @inheritdoc ERC721
	 *
	 * @dev SBT Disables all ERC721 transfers
	 */
	function getApproved(uint256) public pure override returns (address) {
		// throw with the error message clarifying the operation is not supported for SBTs
		revert("operation is not supported for SBT");
	}

	/**
	 * @inheritdoc ERC721
	 *
	 * @dev SBT Disables all ERC721 transfers
	 */
	function isApprovedForAll(address, address) public pure override returns (bool) {
		// throw with the error message clarifying the operation is not supported for SBTs
		revert("operation is not supported for SBT");
	}

	// ===== End: ERC721, ERC721Enumerable Getters (view functions) =====

	// ===== Start: ERC721 mutative functions (transfers, approvals) =====

	/**
	 * @inheritdoc ERC721
	 *
	 * @dev SBT Disables all ERC721 transfers
	 */
	function safeTransferFrom(address, address, uint256, bytes memory) public pure override {
		// throw with the error message clarifying the operation is not supported for SBTs
		revert("operation is not supported for SBT");
	}

	/**
	 * @inheritdoc ERC721
	 *
	 * @dev SBT Disables all ERC721 transfers
	 */
	function safeTransferFrom(address, address, uint256) public pure override {
		// throw with the error message clarifying the operation is not supported for SBTs
		revert("operation is not supported for SBT");
	}

	/**
	 * @inheritdoc ERC721
	 *
	 * @dev SBT Disables all ERC721 transfers
	 */
	function transferFrom(address, address, uint256) public pure override {
		// throw with the error message clarifying the operation is not supported for SBTs
		revert("operation is not supported for SBT");
	}

	/**
	 * @inheritdoc ERC721
	 *
	 * @dev SBT Disables all ERC721 transfers
	 */
	function approve(address, uint256) public pure override {
		// throw with the error message clarifying the operation is not supported for SBTs
		revert("operation is not supported for SBT");
	}

	/**
	 * @inheritdoc ERC721
	 *
	 * @dev SBT Disables all ERC721 transfers
	 */
	function setApprovalForAll(address, bool) public pure override {
		// throw with the error message clarifying the operation is not supported for SBTs
		revert("operation is not supported for SBT");
	}

	// ===== End: ERC721 mutative functions (transfers, approvals) =====

	// ===== Start: mint/burn support =====

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) public override {
		// delegate to unsafe mint
		mint(_to, _tokenId);

		// make it safe: execute `onERC721Received`

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// check it supports ERC721 interface - execute onERC721Received()
			bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId, _data);

			// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
			// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
			require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
		}
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) public override {
		// delegate to `safeMint` with empty data
		safeMint(_to, _tokenId, "");
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) public override {
		// delegate to unsafe mint
		mintBatch(_to, _tokenId, n);

		// make it safe: execute `onERC721Received`

		// if receiver `_to` is a smart contract
		if(AddressUtils.isContract(_to)) {
			// onERC721Received: for each token minted
			for(uint256 i = 0; i < n; i++) {
				// check it supports ERC721 interface - execute onERC721Received()
				bytes4 response = ERC721TokenReceiver(_to).onERC721Received(msg.sender, address(0), _tokenId + i, _data);

				// expected response is ERC721TokenReceiver(_to).onERC721Received.selector
				// bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
				require(response == ERC721TokenReceiver(_to).onERC721Received.selector, "invalid onERC721Received response");
			}
		}
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) public override {
		// delegate to `safeMint` with empty data
		safeMintBatch(_to, _tokenId, n, "");
	}

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) public override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// verify the inputs

		// verify destination address is set
		require(_to != address(0), "zero address");
		// verify the token ID is "tiny" (32 bits long at most)
		require(uint32(_tokenId) == _tokenId, "token ID overflow");

		// verify token doesn't yet exist
		require(!exists(_tokenId), "already minted");

		// create token ownership record,
		// add token to `allTokens` and new owner's collections
		// add token to both local and global collections (enumerations)
		__addToken(_tokenId, _to);

		// fire ERC721 transfer event
		emit Transfer(address(0), _to, _tokenId);
	}

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_CREATOR` permission
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) public override {
		// check if caller has sufficient permissions to mint tokens
		require(isSenderInRole(ROLE_TOKEN_CREATOR), "access denied");

		// verify the inputs

		// verify destination address is set
		require(_to != address(0), "zero address");
		// verify n is set properly
		require(n > 1, "n is too small");
		// verify the token ID is "tiny" (32 bits long at most)
		require(uint32(_tokenId) == _tokenId, "token ID overflow");
		require(uint32(_tokenId + n - 1) == _tokenId + n - 1, "n-th token ID overflow");

		// verification: for each token to be minted
		for(uint256 i = 0; i < n; i++) {
			// verify token doesn't yet exist
			require(!exists(_tokenId + i), "already minted");
		}

		// create token ownership records,
		// add tokens to `allTokens` and new owner's collections
		// add tokens to both local and global collections (enumerations)
		__addTokens(_to, _tokenId, n);

		// events: for each token minted
		for(uint256 i = 0; i < n; i++) {
			// fire ERC721 transfer event
			emit Transfer(address(0), _to, _tokenId + i);
		}
	}

	/**
	 * @dev Destroys the token with token ID specified
	 *
	 * @dev Requires executor to have `ROLE_TOKEN_DESTROYER` permission
	 *      or FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features to be enabled
	 *
	 * @dev Can be disabled by the contract creator forever by disabling
	 *      FEATURE_OWN_BURNS/FEATURE_BURNS_ON_BEHALF features and then revoking
	 *      its own roles to burn tokens and to enable burning features
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) public override {
		// read token owner data
		// verifies token exists under the hood
		address _from = ownerOf(_tokenId);

		// check if caller has sufficient permissions to burn tokens
		// and if not - check for possibility to burn own tokens or to burn on behalf
		if(!isSenderInRole(ROLE_TOKEN_DESTROYER)) {
			// require own burns feature to be enabled
			require(isFeatureEnabled(FEATURE_OWN_BURNS), "burns are disabled");

			// verify sender is token owner
			require(_from == msg.sender, "access denied");
		}

		// remove token ownership record (also clears approval),
		// remove token from both local and global collections
		__removeToken(_tokenId);

		// delete token URI mapping
		delete _tokenURIs[_tokenId];

		// fire ERC721 transfer event
		emit Transfer(_from, address(0), _tokenId);
	}

	// ===== End: mint/burn support =====

	// ----- Start: auxiliary internal/private functions -----

	/**
	 * @dev Add token to both local and global collections (enumerations),
	 *      used internally to mint new tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to add
	 * @param _to new owner address to add token to
	 */
	function __addToken(uint256 _tokenId, address _to) internal virtual {
		// get a reference to the collection where token goes to
		uint32[] storage destination = collections[_to];

		// update token global and local indexes, ownership
		tokens[_tokenId] = uint224(allTokens.length) << 192 | uint192(destination.length) << 160 | uint160(_to);

		// push token into the collection
		destination.push(uint32(_tokenId));

		// push it into the global `allTokens` collection (enumeration)
		allTokens.push(uint32(_tokenId));
	}

	/**
	 * @dev Add tokens to both local and global collections (enumerations),
	 *      used internally to mint new tokens in batches
	 *
	 * @dev Token IDs to be added: [_tokenId, _tokenId + n)
	 *      n is expected to be greater or equal 2, but this is not checked
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _to new owner address to add token to
	 * @param _tokenId first token ID to add
	 * @param n how many tokens to add, sequentially increasing the _tokenId
	 */
	function __addTokens(address _to, uint256 _tokenId, uint256 n) internal virtual {
		// get a reference to the collection where tokens go to
		uint32[] storage destination = collections[_to];

		// for each token to be added
		for(uint256 i = 0; i < n; i++) {
			// update token global and local indexes, ownership
			tokens[_tokenId + i] = uint224(allTokens.length + i) << 192 | uint192(destination.length + i) << 160 | uint160(_to);
		}

		// push tokens into the local collection
		destination.push32(uint32(_tokenId), uint32(n));
		// push tokens into the global `allTokens` collection (enumeration)
		allTokens.push32(uint32(_tokenId), uint32(n));
	}

	/**
	 * @dev Removes token from owner's local collection,
	 *      used internally to transfer or burn existing tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to remove
	 */
	function __removeLocal(uint256 _tokenId) internal virtual {
		// read token data, containing global and local indexes, owner address
		uint256 token = tokens[_tokenId];

		// get a reference to the token's owner collection (local)
		uint32[] storage source = collections[address(uint160(token))];

		// token index within the collection
		uint32 i = uint32(token >> 160);

		// get an ID of the last token in the collection
		uint32 sourceId = source[source.length - 1];

		// if the token we're to remove from the collection is not the last one,
		// we need to move last token in the collection into index `i`
		if(i != source.length - 1) {
			// we put the last token in the collection to the position released

			// update last token local index to point to proper place in the collection
			// preserve global index and ownership info
			tokens[sourceId] = tokens[sourceId]
				//  |unused |global | local | ownership information (address)      |
				& 0x00000000FFFFFFFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
				| uint192(i) << 160;

			// put it into the position `i` within the collection
			source[i] = sourceId;
		}

		// trim the collection by removing last element
		source.pop();
	}

	/**
	 * @dev Removes token from both local and global collections (enumerations),
	 *      used internally to burn existing tokens
	 *
	 * @dev Unsafe: doesn't check for data structures consistency
	 *      (token existence, token ownership, etc.)
	 *
	 * @dev Must be kept private at all times. Inheriting smart contracts
	 *      may be interested in overriding this function.
	 *
	 * @param _tokenId token ID to remove
	 */
	function __removeToken(uint256 _tokenId) internal virtual {
		// remove token from owner's (local) collection first
		__removeLocal(_tokenId);

		// token index within the global collection
		uint32 i = uint32(tokens[_tokenId] >> 192);

		// delete the token
		delete tokens[_tokenId];

		// get an ID of the last token in the collection
		uint32 lastId = allTokens[allTokens.length - 1];

		// if the token we're to remove from the collection is not the last one,
		// we need to move last token in the collection into index `i`
		if(i != allTokens.length - 1) {
			// we put the last token in the collection to the position released

			// update last token global index to point to proper place in the collection
			// preserve local index and ownership info
			tokens[lastId] = tokens[lastId]
				//  |unused |global | local | ownership information (address)      |
				& 0x0000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
				| uint224(i) << 192;

			// put it into the position `i` within the collection
			allTokens[i] = lastId;
		}

		// trim the collection by removing last element
		allTokens.pop();
	}

	// ----- End: auxiliary internal/private functions -----
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC165Spec.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev Solidity issue #3412: The ERC721 interfaces include explicit mutability guarantees for each function.
 *      Mutability guarantees are, in order weak to strong: payable, implicit nonpayable, view, and pure.
 *      Implementation MUST meet the mutability guarantee in this interface and MAY meet a stronger guarantee.
 *      For example, a payable function in this interface may be implemented as nonpayable
 *      (no state mutability specified) in implementing contract.
 *      It is expected a later Solidity release will allow stricter contract to inherit from this interface,
 *      but current workaround is that we edit this interface to add stricter mutability before inheriting:
 *      we have removed all "payable" modifiers.
 *
 * @dev The ERC-165 identifier for this interface is 0x80ac58cd.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721 is ERC165 {
	/// @dev This emits when ownership of any NFT changes by any mechanism.
	///  This event emits when NFTs are created (`from` == 0) and destroyed
	///  (`to` == 0). Exception: during contract creation, any number of NFTs
	///  may be created and assigned without emitting Transfer. At the time of
	///  any transfer, the approved address for that NFT (if any) is reset to none.
	event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

	/// @dev This emits when the approved address for an NFT is changed or
	///  reaffirmed. The zero address indicates there is no approved address.
	///  When a Transfer event emits, this also indicates that the approved
	///  address for that NFT (if any) is reset to none.
	event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

	/// @dev This emits when an operator is enabled or disabled for an owner.
	///  The operator can manage all NFTs of the owner.
	event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

	/// @notice Count all NFTs assigned to an owner
	/// @dev NFTs assigned to the zero address are considered invalid, and this
	///  function throws for queries about the zero address.
	/// @param _owner An address for whom to query the balance
	/// @return The number of NFTs owned by `_owner`, possibly zero
	function balanceOf(address _owner) external view returns (uint256);

	/// @notice Find the owner of an NFT
	/// @dev NFTs assigned to zero address are considered invalid, and queries
	///  about them do throw.
	/// @param _tokenId The identifier for an NFT
	/// @return The address of the owner of the NFT
	function ownerOf(uint256 _tokenId) external view returns (address);

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT. When transfer is complete, this function
	///  checks if `_to` is a smart contract (code size > 0). If so, it calls
	///  `onERC721Received` on `_to` and throws if the return value is not
	///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	/// @param _data Additional data with no specified format, sent in call to `_to`
	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external /*payable*/;

	/// @notice Transfers the ownership of an NFT from one address to another address
	/// @dev This works identically to the other function with an extra data parameter,
	///  except this function just sets data to "".
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
	///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
	///  THEY MAY BE PERMANENTLY LOST
	/// @dev Throws unless `msg.sender` is the current owner, an authorized
	///  operator, or the approved address for this NFT. Throws if `_from` is
	///  not the current owner. Throws if `_to` is the zero address. Throws if
	///  `_tokenId` is not a valid NFT.
	/// @param _from The current owner of the NFT
	/// @param _to The new owner
	/// @param _tokenId The NFT to transfer
	function transferFrom(address _from, address _to, uint256 _tokenId) external /*payable*/;

	/// @notice Change or reaffirm the approved address for an NFT
	/// @dev The zero address indicates there is no approved address.
	///  Throws unless `msg.sender` is the current NFT owner, or an authorized
	///  operator of the current owner.
	/// @param _approved The new approved NFT controller
	/// @param _tokenId The NFT to approve
	function approve(address _approved, uint256 _tokenId) external /*payable*/;

	/// @notice Enable or disable approval for a third party ("operator") to manage
	///  all of `msg.sender`'s assets
	/// @dev Emits the ApprovalForAll event. The contract MUST allow
	///  multiple operators per owner.
	/// @param _operator Address to add to the set of authorized operators
	/// @param _approved True if the operator is approved, false to revoke approval
	function setApprovalForAll(address _operator, bool _approved) external;

	/// @notice Get the approved address for a single NFT
	/// @dev Throws if `_tokenId` is not a valid NFT.
	/// @param _tokenId The NFT to find the approved address for
	/// @return The approved address for this NFT, or the zero address if there is none
	function getApproved(uint256 _tokenId) external view returns (address);

	/// @notice Query if an address is an authorized operator for another address
	/// @param _owner The address that owns the NFTs
	/// @param _operator The address that acts on behalf of the owner
	/// @return True if `_operator` is an approved operator for `_owner`, false otherwise
	function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
	/// @notice Handle the receipt of an NFT
	/// @dev The ERC721 smart contract calls this function on the recipient
	///  after a `transfer`. This function MAY throw to revert and reject the
	///  transfer. Return of other than the magic value MUST result in the
	///  transaction being reverted.
	///  Note: the contract address is always the message sender.
	/// @param _operator The address which called `safeTransferFrom` function
	/// @param _from The address which previously owned the token
	/// @param _tokenId The NFT identifier which is being transferred
	/// @param _data Additional data with no specified format
	/// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
	///  unless throwing
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x5b5e139f.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Metadata is ERC721 {
	/// @notice A descriptive name for a collection of NFTs in this contract
	function name() external view returns (string memory _name);

	/// @notice An abbreviated name for NFTs in this contract
	function symbol() external view returns (string memory _symbol);

	/// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
	/// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
	///  3986. The URI may point to a JSON file that conforms to the "ERC721
	///  Metadata JSON Schema".
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 *
 * @notice See https://eips.ethereum.org/EIPS/eip-721
 *
 * @dev The ERC-165 identifier for this interface is 0x780e9d63.
 *
 * @author William Entriken, Dieter Shirley, Jacob Evans, Nastassia Sachs
 */
interface ERC721Enumerable is ERC721 {
	/// @notice Count NFTs tracked by this contract
	/// @return A count of valid NFTs tracked by this contract, where each one of
	///  them has an assigned and queryable owner not equal to the zero address
	function totalSupply() external view returns (uint256);

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Alethea Mintable ERC721
 *
 * @notice Defines mint capabilities for Alethea ERC721 tokens.
 *      This interface should be treated as a definition of what mintable means for ERC721
 *
 * @author Basil Gorin
 */
interface MintableERC721 {
	/**
	 * @notice Checks if specified token exists
	 *
	 * @dev Returns whether the specified token ID has an ownership
	 *      information associated with it
	 *
	 * @param _tokenId ID of the token to query existence for
	 * @return whether the token exists (true - exists, false - doesn't exist)
	 */
	function exists(uint256 _tokenId) external view returns(bool);

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMint` instead of `mint`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function mint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Unsafe: doesn't execute `onERC721Received` on the receiver.
	 *      Prefer the use of `saveMintBatch` instead of `mintBatch`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint tokens to
	 * @param _tokenId ID of the first token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function mintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 */
	function safeMint(address _to, uint256 _tokenId) external;

	/**
	 * @dev Creates new token with token ID specified
	 *      and assigns an ownership `_to` for this token
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMint(address _to, uint256 _tokenId, bytes memory _data) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n) external;

	/**
	 * @dev Creates new tokens starting with token ID specified
	 *      and assigns an ownership `_to` for these tokens
	 *
	 * @dev Token IDs to be minted: [_tokenId, _tokenId + n)
	 *
	 * @dev n must be greater or equal 2: `n > 1`
	 *
	 * @dev Checks if `_to` is a smart contract (code size > 0). If so, it calls
	 *      `onERC721Received` on `_to` and throws if the return value is not
	 *      `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 *
	 * @dev Should have a restricted access handled by the implementation
	 *
	 * @param _to an address to mint token to
	 * @param _tokenId ID of the token to mint
	 * @param n how many tokens to mint, sequentially increasing the _tokenId
	 * @param _data additional data with no specified format, sent in call to `_to`
	 */
	function safeMintBatch(address _to, uint256 _tokenId, uint256 n, bytes memory _data) external;
}

/**
 * @title Alethea Burnable ERC721
 *
 * @notice Defines burn capabilities for Alethea ERC721 tokens.
 *      This interface should be treated as a definition of what burnable means for ERC721
 *
 * @author Basil Gorin
 */
interface BurnableERC721 {
	/**
	 * @notice Destroys the token with token ID specified
	 *
	 * @dev Should be accessible publicly by token owners.
	 *      May have a restricted access handled by the implementation
	 *
	 * @param _tokenId ID of the token to burn
	 */
	function burn(uint256 _tokenId) external;
}

/**
 * @title With Base URI
 *
 * @notice A marker interface for the contracts having the baseURI() function
 *      or public string variable named baseURI
 *      NFT implementations like TinyERC721, or ShortERC721 are example of such smart contracts
 *
 * @author Basil Gorin
 */
interface WithBaseURI {
	/**
	 * @dev Usually used in NFT implementations to construct ERC721Metadata.tokenURI as
	 *      `base URI + token ID` if token URI is not set (not present in `_tokenURIs` mapping)
	 *
	 * @dev For example, if base URI is https://api.com/token/, then token #1
	 *      will have an URI https://api.com/token/1
	 */
	function baseURI() external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Address Utils
 *
 * @dev Utility library of inline functions on addresses
 *
 * @dev Copy of the Zeppelin's library:
 *      https://github.com/gnosis/openzeppelin-solidity/blob/master/contracts/AddressUtils.sol
 */
library AddressUtils {

	/**
	 * @notice Checks if the target address is a contract
	 *
	 * @dev It is unsafe to assume that an address for which this function returns
	 *      false is an externally-owned account (EOA) and not a contract.
	 *
	 * @dev Among others, `isContract` will return false for the following
	 *      types of addresses:
	 *        - an externally-owned account
	 *        - a contract in construction
	 *        - an address where a contract will be created
	 *        - an address where a contract lived, but was destroyed
	 *
	 * @param addr address to check
	 * @return whether the target address is a contract
	 */
	function isContract(address addr) internal view returns (bool) {
		// a variable to load `extcodesize` to
		uint256 size = 0;

		// XXX Currently there is no better way to check if there is a contract in an address
		// than to check the size of the code at that address.
		// See https://ethereum.stackexchange.com/a/14016/36603 for more details about how this works.
		// TODO: Check this again before the Serenity release, because all addresses will be contracts.
		// solium-disable-next-line security/no-inline-assembly
		assembly {
			// retrieve the size of the code at address `addr`
			size := extcodesize(addr)
		}

		// positive size indicates a smart contract address
		return size > 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Array Utils
 *
 * @notice Solidity doesn't always work with arrays in an optimal way.
 *      This library collects functions helping to optimize gas usage
 *      when working with arrays in Solidity.
 *
 * @dev One of the most important use cases for arrays is "tight" arrays -
 *      arrays which store values significantly less than 256-bits numbers
 *
 * @author Basil Gorin
 */
library ArrayUtils {
	/**
	 * @dev Pushes `n` 32-bits values sequentially into storage allocated array `data`
	 *      starting from the 32-bits value `v0`
	 *
	 * @dev Optimizations comparing to non-assembly implementation:
	 *      - reads+writes to array size slot only once (instead of `n` times)
	 *      - reads from the array data slots only once (instead of `7n/8` times)
	 *      - writes into array data slots `n/8` times (instead of `n` times)
	 *
	 * @dev Maximum gas saving estimate: ~3n sstore, or 15,000 * n
	 *
	 * @param data storage array pointer to an array of 32-bits elements
	 * @param v0 first number to push into the array
	 * @param n number of values to push, pushes [v0, ..., v0 + n - 1]
	 */
	function push32(uint32[] storage data, uint32 v0, uint32 n) internal {
		// we're going to write 32-bits values into 256-bits storage slots of the array
		// each 256-slot can store up to 8 32-bits sub-blocks, it can also be partially empty
		assembly {
			// for dynamic arrays their slot (array.slot) contains the array length
			// array data is stored separately in consequent storage slots starting
			// from the slot with the address keccak256(array.slot)

			// read the array length into `len` and increase it by `n`
			let len := sload(data.slot)
			sstore(data.slot, add(len, n))

			// find where to write elements and store this location into `loc`
			// load array storage slot number into memory onto position 0,
			// calculate the keccak256 of the slot number (first 32 bytes at position 0)
			// - this will point to the beginning of the array,
			// so we add array length divided by 8 to point to the last array slot
			mstore(0, data.slot)
			let loc := add(keccak256(0, 32), div(len, 8))

			// if we start writing data into already partially occupied slot (`len % 8 != 0`)
			// we need to modify the contents of that slot: read it and rewrite it
			let offset := mod(len, 8)
			if not(iszero(offset)) {
				// how many 32-bits sub-blocks left in the slot
				let left := sub(8, offset)
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// load the contents of the first slot (partially occupied)
				let v256 := sload(loc)
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `(j + offset) * 32` bits, length: 32-bits
					// v256 |= (v0 + j) << (j + offset) * 32
					v256 := or(v256, shl(mul(add(j, offset), 32), add(v0, j)))
				}
				// write first slot back, it can be still partially occupied, it can also be full
				sstore(loc, v256)
				// update `loc`: move to the next slot
				loc := add(loc, 1)
				// update `v0`: increment by number of values pushed
				v0 := add(v0, left)
				// update `n`: decrement by number of values pushed
				n := sub(n, left)
			}

			// rest of the slots (if any) are empty and will be only written to
			// write the array in 256-bits (8x32) slots
			// `i` iterates [0, n) with the 256-bits step, which is 8 taken `n` is 32-bits long
			for { let i := 0 } lt(i, n) { i := add(i, 8) } {
				// how many 32-bits sub-blocks left in the slot
				let left := 8
				// update the `left` value not to exceed `n`
				if gt(left, n) { left := n }
				// init the 256-bits slot value
				let v256 := 0
				// write the slot in 32-bits sub-blocks
				for { let j := 0 } lt(j, left) { j := add(j, 1) } {
					// write sub-block `j` at offset: `j * 32` bits, length: 32-bits
					// v256 |= (v0 + i + j) << j * 32
					v256 := or(v256, shl(mul(j, 32), add(v0, add(i, j))))
				}
				// write slot `i / 8`
				sstore(add(loc, div(i, 8)), v256)
			}
		}
	}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title String Utils Library
 *
 * @dev Library for working with strings, primarily converting
 *      between strings and integer types
 *
 * @author Basil Gorin
 */
library StringUtils {
	/**
	 * @dev Converts a string to unsigned integer using the specified `base`
	 * @dev Throws on invalid input
	 *      (wrong characters for a given `base`)
	 * @dev Throws if given `base` is not supported
	 * @param a string to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return i a number representing given string
	 */
	function atoi(string memory a, uint8 base) internal pure returns (uint256 i) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// convert string into bytes for convenient iteration
		bytes memory buf = bytes(a);

		// iterate over the string (bytes buffer)
		for(uint256 p = 0; p < buf.length; p++) {
			// extract the digit
			uint8 digit = uint8(buf[p]) - 0x30;

			// if digit is greater then 10 - mind the gap
			// see `itoa` function for more details
			if(digit > 10) {
				// remove the gap
				digit -= 7;
			}

			// check if digit meets the base
			require(digit < base);

			// move to the next digit slot
			i *= base;

			// add digit to the result
			i += digit;
		}

		// return the result
		return i;
	}

	/**
	 * @dev Converts a integer to a string using the specified `base`
	 * @dev Throws if given `base` is not supported
	 * @param i integer to convert
	 * @param base number base, one of 2, 8, 10, 16
	 * @return a a string representing given integer
	 */
	function itoa(uint256 i, uint8 base) internal pure returns (string memory a) {
		// check if the base is valid
		require(base == 2 || base == 8 || base == 10 || base == 16);

		// for zero input the result is "0" string for any base
		if(i == 0) {
			return "0";
		}

		// bytes buffer to put ASCII characters into
		bytes memory buf = new bytes(256);

		// position within a buffer to be used in cycle
		uint256 p = 0;

		// extract digits one by one in a cycle
		while(i > 0) {
			// extract current digit
			uint8 digit = uint8(i % base);

			// convert it to an ASCII code
			// 0x20 is " "
			// 0x30-0x39 is "0"-"9"
			// 0x41-0x5A is "A"-"Z"
			// 0x61-0x7A is "a"-"z" ("A"-"Z" XOR " ")
			uint8 ascii = digit + 0x30;

			// if digit is greater then 10,
			// fix the 0x3A-0x40 gap of punctuation marks
			// (7 characters in ASCII table)
			if(digit >= 10) {
				// jump through the gap
				ascii += 7;
			}

			// write character into the buffer
			buf[p++] = bytes1(ascii);

			// move to the next digit
			i /= base;
		}

		// `p` contains real length of the buffer now,
		// allocate the resulting buffer of that size
		bytes memory result = new bytes(p);

		// copy the buffer in the reversed order
		for(p = 0; p < result.length; p++) {
			// copy from the beginning of the original buffer
			// to the end of resulting smaller buffer
			result[result.length - p - 1] = buf[p];
		}

		// construct string and return
		return string(result);
	}

	/**
	 * @dev Concatenates two strings `s1` and `s2`, for example, if
	 *      `s1` == `foo` and `s2` == `bar`, the result `s` == `foobar`
	 * @param s1 first string
	 * @param s2 second string
	 * @return s concatenation result s1 + s2
	 */
	function concat(string memory s1, string memory s2) internal pure returns (string memory s) {
		// an old way of string concatenation (Solidity 0.4) is commented out
/*
		// convert s1 into buffer 1
		bytes memory buf1 = bytes(s1);
		// convert s2 into buffer 2
		bytes memory buf2 = bytes(s2);
		// create a buffer for concatenation result
		bytes memory buf = new bytes(buf1.length + buf2.length);

		// copy buffer 1 into buffer
		for(uint256 i = 0; i < buf1.length; i++) {
			buf[i] = buf1[i];
		}

		// copy buffer 2 into buffer
		for(uint256 j = buf1.length; j < buf2.length; j++) {
			buf[j] = buf2[j - buf1.length];
		}

		// construct string and return
		return string(buf);
*/

		// simply use built in function
		return string(abi.encodePacked(s1, s2));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title Access Control List
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission bit set.
 *
 * @notice Access manager is a special role which allows to grant/revoke other roles.
 *      Access managers can only grant/revoke permissions which they have themselves.
 *      As an example, access manager with no other roles set can only grant/revoke its own
 *      access manager permission and nothing else.
 *
 * @notice Access manager permission should be treated carefully, as a super admin permission:
 *      Access manager with even no other permission can interfere with another account by
 *      granting own access manager permission to it and effectively creating more powerful
 *      permission set than its own.
 *
 * @dev Both current and OpenZeppelin AccessControl implementations feature a similar API
 *      to check/know "who is allowed to do this thing".
 * @dev Zeppelin implementation is more flexible:
 *      - it allows setting unlimited number of roles, while current is limited to 256 different roles
 *      - it allows setting an admin for each role, while current allows having only one global admin
 * @dev Current implementation is more lightweight:
 *      - it uses only 1 bit per role, while Zeppelin uses 256 bits
 *      - it allows setting up to 256 roles at once, in a single transaction, while Zeppelin allows
 *        setting only one role in a single transaction
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @dev Access manager permission has a bit 255 set.
 *      This bit must not be used by inheriting contracts for any other permissions/features.
 *
 * @author Basil Gorin
 */
contract AccessControl {
	/**
	 * @notice Access manager is responsible for assigning the roles to users,
	 *      enabling/disabling global features of the smart contract
	 * @notice Access manager can add, remove and update user roles,
	 *      remove and update global features
	 *
	 * @dev Role ROLE_ACCESS_MANAGER allows modifying user roles and global features
	 * @dev Role ROLE_ACCESS_MANAGER has single bit at position 255 enabled
	 */
	uint256 public constant ROLE_ACCESS_MANAGER = 0x8000000000000000000000000000000000000000000000000000000000000000;

	/**
	 * @dev Bitmask representing all the possible permissions (super admin role)
	 * @dev Has all the bits are enabled (2^256 - 1 value)
	 */
	uint256 private constant FULL_PRIVILEGES_MASK = type(uint256).max; // before 0.8.0: uint256(-1) overflows to 0xFFFF...

	/**
	 * @notice Privileged addresses with defined roles/permissions
	 * @notice In the context of ERC20/ERC721 tokens these can be permissions to
	 *      allow minting or burning tokens, transferring on behalf and so on
	 *
	 * @dev Maps user address to the permissions bitmask (role), where each bit
	 *      represents a permission
	 * @dev Bitmask 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
	 *      represents all possible permissions
	 * @dev 'This' address mapping represents global features of the smart contract
	 */
	mapping(address => uint256) public userRoles;

	/**
	 * @dev Fired in updateRole() and updateFeatures()
	 *
	 * @param _by operator which called the function
	 * @param _to address which was granted/revoked permissions
	 * @param _requested permissions requested
	 * @param _actual permissions effectively set
	 */
	event RoleUpdated(address indexed _by, address indexed _to, uint256 _requested, uint256 _actual);

	/**
	 * @notice Creates an access control instance,
	 *      setting contract creator to have full privileges
	 */
	constructor() {
		// contract creator has full privileges
		userRoles[msg.sender] = FULL_PRIVILEGES_MASK;
	}

	/**
	 * @notice Retrieves globally set of features enabled
	 *
	 * @dev Effectively reads userRoles role for the contract itself
	 *
	 * @return 256-bit bitmask of the features enabled
	 */
	function features() public view returns(uint256) {
		// features are stored in 'this' address  mapping of `userRoles` structure
		return userRoles[address(this)];
	}

	/**
	 * @notice Updates set of the globally enabled features (`features`),
	 *      taking into account sender's permissions
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 * @dev Function is left for backward compatibility with older versions
	 *
	 * @param _mask bitmask representing a set of features to enable/disable
	 */
	function updateFeatures(uint256 _mask) public {
		// delegate call to `updateRole`
		updateRole(address(this), _mask);
	}

	/**
	 * @notice Updates set of permissions (role) for a given user,
	 *      taking into account sender's permissions.
	 *
	 * @dev Setting role to zero is equivalent to removing an all permissions
	 * @dev Setting role to `FULL_PRIVILEGES_MASK` is equivalent to
	 *      copying senders' permissions (role) to the user
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param operator address of a user to alter permissions for or zero
	 *      to alter global features of the smart contract
	 * @param role bitmask representing a set of permissions to
	 *      enable/disable for a user specified
	 */
	function updateRole(address operator, uint256 role) public {
		// caller must have a permission to update user roles
		require(isSenderInRole(ROLE_ACCESS_MANAGER), "access denied");

		// evaluate the role and reassign it
		userRoles[operator] = evaluateBy(msg.sender, userRoles[operator], role);

		// fire an event
		emit RoleUpdated(msg.sender, operator, role, userRoles[operator]);
	}

	/**
	 * @notice Determines the permission bitmask an operator can set on the
	 *      target permission set
	 * @notice Used to calculate the permission bitmask to be set when requested
	 *     in `updateRole` and `updateFeatures` functions
	 *
	 * @dev Calculated based on:
	 *      1) operator's own permission set read from userRoles[operator]
	 *      2) target permission set - what is already set on the target
	 *      3) desired permission set - what do we want set target to
	 *
	 * @dev Corner cases:
	 *      1) Operator is super admin and its permission set is `FULL_PRIVILEGES_MASK`:
	 *        `desired` bitset is returned regardless of the `target` permission set value
	 *        (what operator sets is what they get)
	 *      2) Operator with no permissions (zero bitset):
	 *        `target` bitset is returned regardless of the `desired` value
	 *        (operator has no authority and cannot modify anything)
	 *
	 * @dev Example:
	 *      Consider an operator with the permissions bitmask     00001111
	 *      is about to modify the target permission set          01010101
	 *      Operator wants to set that permission set to          00110011
	 *      Based on their role, an operator has the permissions
	 *      to update only lowest 4 bits on the target, meaning that
	 *      high 4 bits of the target set in this example is left
	 *      unchanged and low 4 bits get changed as desired:      01010011
	 *
	 * @param operator address of the contract operator which is about to set the permissions
	 * @param target input set of permissions to operator is going to modify
	 * @param desired desired set of permissions operator would like to set
	 * @return resulting set of permissions given operator will set
	 */
	function evaluateBy(address operator, uint256 target, uint256 desired) public view returns(uint256) {
		// read operator's permissions
		uint256 p = userRoles[operator];

		// taking into account operator's permissions,
		// 1) enable the permissions desired on the `target`
		target |= p & desired;
		// 2) disable the permissions desired on the `target`
		target &= FULL_PRIVILEGES_MASK ^ (p & (FULL_PRIVILEGES_MASK ^ desired));

		// return calculated result
		return target;
	}

	/**
	 * @notice Checks if requested set of features is enabled globally on the contract
	 *
	 * @param required set of features to check against
	 * @return true if all the features requested are enabled, false otherwise
	 */
	function isFeatureEnabled(uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing `features` property
		return __hasRole(features(), required);
	}

	/**
	 * @notice Checks if transaction sender `msg.sender` has all the permissions required
	 *
	 * @param required set of permissions (role) to check against
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isSenderInRole(uint256 required) public view returns(bool) {
		// delegate call to `isOperatorInRole`, passing transaction sender
		return isOperatorInRole(msg.sender, required);
	}

	/**
	 * @notice Checks if operator has all the permissions (role) required
	 *
	 * @param operator address of the user to check role for
	 * @param required set of permissions (role) to check
	 * @return true if all the permissions requested are enabled, false otherwise
	 */
	function isOperatorInRole(address operator, uint256 required) public view returns(bool) {
		// delegate call to `__hasRole`, passing operator's permissions (role)
		return __hasRole(userRoles[operator], required);
	}

	/**
	 * @dev Checks if role `actual` contains all the permissions required `required`
	 *
	 * @param actual existent role
	 * @param required required role
	 * @return true if actual has required role (all permissions), false otherwise
	 */
	function __hasRole(uint256 actual, uint256 required) internal pure returns(bool) {
		// check the bitmask for the role required and return the result
		return actual & required == required;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title ERC-165 Standard Interface Detection
 *
 * @dev Interface of the ERC165 standard, as defined in the
 *       https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * @dev Implementers can declare support of contract interfaces,
 *      which can then be queried by others.
 *
 * @author Christian Reitwießner, Nick Johnson, Fabian Vogelsteller, Jordi Baylina, Konrad Feldmeier, William Entriken
 */
interface ERC165 {
	/**
	 * @notice Query if a contract implements an interface
	 *
	 * @dev Interface identification is specified in ERC-165.
	 *      This function uses less than 30,000 gas.
	 *
	 * @param interfaceID The interface identifier, as specified in ERC-165
	 * @return `true` if the contract implements `interfaceID` and
	 *      `interfaceID` is not 0xffffffff, `false` otherwise
	 */
	function supportsInterface(bytes4 interfaceID) external view returns (bool);
}