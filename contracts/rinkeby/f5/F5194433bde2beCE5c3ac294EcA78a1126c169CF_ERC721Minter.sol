// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ERC721Spec.sol";
import "../interfaces/AletheaERC721Spec.sol";
import "../utils/AccessControl.sol";
import "../lib/ECDSA.sol";

/**
 * @title ERC721 Minter
 *
 * @notice ERC721Minter contract introduces a scalable mechanism to mint NFTs to an arbitrary
 *      amount of addresses by leveraging the power of EIP712 signature.
 */
contract ERC721Minter is AccessControl {
	
	/**
	 * @dev Mintable ERC721 contract address to mint tokens of
	 */
	address public immutable targetContract;

	/**
	 * @dev Number of ERC721 token been mint by ERC721Minter
	 */
	uint256 public tokenMintCount;

	/**
	 * @dev Max token can be minted by ERC721Minter
	 */
	uint256 public maxTokenMintLimit;

	/**
	 * @notice Enables the airdrop, redeeming the tokens via EIP712 signature
	 *
	 * @dev Feature FEATURE_REDEEM_ACTIVE must be enabled in order for
	 *      `mintWithAuthorization` and `mintBatchWithAuthorization` functions to succeed
	 */
	uint32 public constant FEATURE_REDEEM_ACTIVE = 0x0000_0001;

	/**
	 * @notice Authorization manager is responsible for supplying the EIP712 signature
	 *      which then can be used to mint tokens, meaning effectively,
	 *      that Authorization manager may act as a minter on the target NFT contract
	 *
	 * @dev Role ROLE_AUTHORIZATION_MANAGER allows minting tokens with authorization
	 */
	uint32 public constant ROLE_AUTHORIZATION_MANAGER = 0x0001_0000;

	/**
	 * @notice mint limit manager is responsible for update ERC721 token mint limit
	 *
	 * @dev Role ROLE_MINT_LIMIT_MANAGER allows update token mint limit
	 */
	uint32 public constant ROLE_MINT_LIMIT_MANAGER = 0x0002_0000;

	/**
	 * @notice EIP-712 contract's domain typeHash,
	 *      see https://eips.ethereum.org/EIPS/eip-712#rationale-for-typehash
	 *
	 * @dev Note: we do not include version into the domain typehash/separator,
	 *      it is implied version is concatenated to the name field, like "ERC721Minter"
	 */
	// keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)")
	bytes32 public constant DOMAIN_TYPEHASH = 0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866;

	/**
	 * @notice EIP-712 contract's domain separator,
	 *      see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
	 */
	bytes32 public immutable DOMAIN_SEPARATOR;

	// keccak256("MintWithAuthorization(address from,address to,uint256 id,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant MINT_WITH_AUTHORIZATION_TYPEHASH = 0xaf4e98e5c9896ed6453d82e308a87caa8a02787c2c671d5a8cd308f9a99ed41f;

	// keccak256("MintBatchWithAuthorization(address from,address to,uint256 id,uint256 amount,uint256 validAfter,uint256 validBefore,bytes32 nonce)")
	bytes32 public constant MINTBATCH_WITH_AUTHORIZATION_TYPEHASH = 0x67c2bc25c87d2f7202a6c00ccb845fe254f34def701c1f45f93e7e9219b1ebb2;

	// keccak256("CancelAuthorization(address authorizer,bytes32 nonce)")
	bytes32 public constant CANCEL_AUTHORIZATION_TYPEHASH = 0x158b0a9edf7a828aad02f63cd515c68ef2f50ba807396f6d12842833a1597429;

	/**
	 * @dev A record of used nonces for meta transactions
	 *
	 * @dev Maps authorizer address => nonce => true/false (used unused)
	 */
	mapping(address => mapping(bytes32 => bool)) private usedNonces;

	/**
	 * @dev Fired whenever the nonce gets used (ex.: `mintWithAuthorization`, `mintBatchWithAuthorization`)
	 *
	 * @param authorizer an address which has used the nonce
	 * @param nonce the nonce used
	 */
	event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @dev Fired whenever the nonce gets cancelled (ex.: `cancelAuthorization`)
	 *
	 * @dev Both `AuthorizationUsed` and `AuthorizationCanceled` imply the nonce
	 *      cannot be longer used, the only difference is that `AuthorizationCanceled`
	 *      implies no smart contract state change made (except the nonce marked as cancelled)
	 *
	 * @param authorizer an address which has cancelled the nonce
	 * @param nonce the nonce cancelled
	 */
	event AuthorizationCanceled(address indexed authorizer, bytes32 indexed nonce);

	/**
	 * @dev Fired whenever token mint Limit is updated (ex.: `updateTokenMintLimit`)
	 *
	 * @param authorizer an address which has updated token mint limit
	 * @param oldLimit old token mint limit
	 * @param newLimit new token mint limit
	 */
	event TokenMintLimitUpdated(address indexed authorizer, uint256 oldLimit, uint256 newLimit);

	/**
	 * @dev Creates/deploys ERC721Minter and binds it to ERC721 smart contract on construction
	 *
	 * @param _target deployed Mintable ERC721 smart contract; contract will mint NFTs of that type
	 */
	constructor(address _target) {
		// verify the input is set
		require(_target != address(0), "target contract is not set");

		// verify the input is valid smart contract of the expected interfaces
		require(
			ERC165(_target).supportsInterface(type(ERC721).interfaceId)
			&& ERC165(_target).supportsInterface(type(MintableERC721).interfaceId),
			"unexpected target type"
		);

		// assign the address
		targetContract = _target;

		// max ERC721Minter contract can mint 1000 token's
		maxTokenMintLimit = 1000;

		// build the EIP-712 contract domain separator, see https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator
		DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes("ERC721Minter")), block.chainid, address(this)));
	}

	/**
	 * @notice Checks if specified nonce was already used
	 *
	 * @dev Nonces are expected to be client-side randomly generated 32-byte values
	 *      unique to the authorizer's address
	 *
	 * @dev Alias for usedNonces(authorizer, nonce)
	 *
	 * @param _authorizer an address to check nonce for
	 * @param _nonce a nonce to check
	 * @return true if the nonce was used, false otherwise
	 */
	function authorizationState(address _authorizer, bytes32 _nonce) public view returns (bool) {
		// simply return the value from the mapping
		return usedNonces[_authorizer][_nonce];
	}

	/**
	 * @notice Receive a token with a signed authorization from the authorization manager
	 *
	 * @dev This has an additional check to ensure that the receiver's address
	 *      matches the caller of this function to prevent front-running attacks.
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _id token ID to mint
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function mintWithAuthorization(
		address _from,
		address _to,
		uint256 _id,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		// verify redeems are enabled
		require(isFeatureEnabled(FEATURE_REDEEM_ACTIVE), "redeems are disabled");

		require(tokenMintCount < maxTokenMintLimit, "minting Limit has been reached!!");

		// derive signer of the EIP712 MintWithAuthorization message
		address signer = __deriveSigner(abi.encode(MINT_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _id, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(isOperatorInRole(signer, ROLE_AUTHORIZATION_MANAGER), "invalid access");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");
		require(_to == msg.sender, "access denied");

		// update token mint count
		tokenMintCount++;

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// mint token to the recipient
		MintableERC721(targetContract).mint(_to, _id);
	}

	/**
	 * @notice Receive tokens with a signed authorization from the authorization manager
	 *
	 * @dev This has an additional check to ensure that the receiver's address
	 *      matches the caller of this function to prevent front-running attacks.
	 *
	 * @param _from token sender and transaction authorizer
	 * @param _to token receiver
	 * @param _id token ID to mint
	 * @param _amount amount of tokens to create, two or more
	 * @param _validAfter signature valid after time (unix timestamp)
	 * @param _validBefore signature valid before time (unix timestamp)
	 * @param _nonce unique random nonce
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function mintBatchWithAuthorization(
		address _from,
		address _to,
		uint256 _id,
		uint256 _amount,
		uint256 _validAfter,
		uint256 _validBefore,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		// verify redeems are enabled
		require(isFeatureEnabled(FEATURE_REDEEM_ACTIVE), "redeems are disabled");

		require(tokenMintCount + _amount <= maxTokenMintLimit, "minting Limit has been reached!!");

		// derive signer of the EIP712 MintBatchWithAuthorization message
		address signer = __deriveSigner(abi.encode(MINTBATCH_WITH_AUTHORIZATION_TYPEHASH, _from, _to, _id, _amount, _validAfter, _validBefore, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _from, "invalid signature");
		require(isOperatorInRole(signer, ROLE_AUTHORIZATION_MANAGER), "invalid access");
		require(block.timestamp > _validAfter, "signature not yet valid");
		require(block.timestamp < _validBefore, "signature expired");
		require(_to == msg.sender, "access denied");

		// update token mint count
		tokenMintCount = tokenMintCount + _amount;

		// use the nonce supplied (verify, mark as used, emit event)
		__useNonce(_from, _nonce, false);

		// mint token to the recipient
		MintableERC721(targetContract).mintBatch(_to, _id, _amount);
	}

	/**
	 * @notice Attempt to cancel an authorization
	 *
	 * @param _authorizer transaction authorizer
	 * @param _nonce unique random nonce to cancel (mark as used)
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function cancelAuthorization(
		address _authorizer,
		bytes32 _nonce,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public {
		// derive signer of the EIP712 ReceiveWithAuthorization message
		address signer = __deriveSigner(abi.encode(CANCEL_AUTHORIZATION_TYPEHASH, _authorizer, _nonce), v, r, s);

		// perform message integrity and security validations
		require(signer == _authorizer, "invalid signature");

		// cancel the nonce supplied (verify, mark as used, emit event)
		__useNonce(_authorizer, _nonce, true);
	}

	/**
	 * @dev Auxiliary function to verify structured EIP712 message signature and derive its signer
	 *
	 * @param abiEncodedTypehash abi.encode of the message typehash together with all its parameters
	 * @param v the recovery byte of the signature
	 * @param r half of the ECDSA signature pair
	 * @param s half of the ECDSA signature pair
	 */
	function __deriveSigner(bytes memory abiEncodedTypehash, uint8 v, bytes32 r, bytes32 s) private view returns(address) {
		// build the EIP-712 hashStruct of the message
		bytes32 hashStruct = keccak256(abiEncodedTypehash);

		// calculate the EIP-712 digest "\x19\x01" ‖ domainSeparator ‖ hashStruct(message)
		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hashStruct));

		// recover the address which signed the message with v, r, s
		address signer = ECDSA.recover(digest, v, r, s);

		// return the signer address derived from the signature
		return signer;
	}

	/**
	 * @dev Auxiliary function to use/cancel the nonce supplied for a given authorizer:
	 *      1. Verifies the nonce was not used before
	 *      2. Marks the nonce as used
	 *      3. Emits an event that the nonce was used/cancelled
	 *
	 * @dev Set `_cancellation` to false (default) to use nonce,
	 *      set `_cancellation` to true to cancel nonce
	 *
	 * @dev It is expected that the nonce supplied is a randomly
	 *      generated uint256 generated by the client
	 *
	 * @param _authorizer an address to use/cancel nonce for
	 * @param _nonce random nonce to use
	 * @param _cancellation true to emit `AuthorizationCancelled`, false to emit `AuthorizationUsed` event
	 */
	function __useNonce(address _authorizer, bytes32 _nonce, bool _cancellation) private {
		// verify nonce was not used before
		require(!usedNonces[_authorizer][_nonce], "invalid nonce");

		// update the nonce state to "used" for that particular signer to avoid replay attack
		usedNonces[_authorizer][_nonce] = true;

		// depending on the usage type (use/cancel)
		if(_cancellation) {
			// emit an event regarding the nonce cancelled
			emit AuthorizationCanceled(_authorizer, _nonce);
		}
		else {
			// emit an event regarding the nonce used
			emit AuthorizationUsed(_authorizer, _nonce);
		}
	}

	/**
	 * @notice Updates max ERC721 token mint Limit of 
	 *			ERC721Minter contract.
	 *
	 * @dev Requires transaction sender to have `ROLE_ACCESS_MANAGER` permission
	 *
	 * @param _tokenMintLimit new ERC721 token mint limit
	 */
	function updateTokenMintLimit(uint256 _tokenMintLimit) public {
		// caller must have a permission to update token mint limit
		require(isSenderInRole(ROLE_MINT_LIMIT_MANAGER), "access denied");

		// fire an event
		emit TokenMintLimitUpdated(msg.sender, maxTokenMintLimit, _tokenMintLimit);

		// update token mint limit
		maxTokenMintLimit = _tokenMintLimit;
	}
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
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 *
 * @dev Copy of the Zeppelin's library:
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/b0cf6fbb7a70f31527f36579ad644e1cf12fdf4e/contracts/utils/cryptography/ECDSA.sol
 */
library ECDSA {
	/**
	 * @dev Returns the address that signed a hashed message (`hash`) with
	 * `signature`. This address can then be used for verification purposes.
	 *
	 * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
	 * this function rejects them by requiring the `s` value to be in the lower
	 * half order, and the `v` value to be either 27 or 28.
	 *
	 * IMPORTANT: `hash` _must_ be the result of a hash operation for the
	 * verification to be secure: it is possible to craft signatures that
	 * recover to arbitrary addresses for non-hashed data. A safe way to ensure
	 * this is by receiving a hash of the original message (which may otherwise
	 * be too long), and then calling {toEthSignedMessageHash} on it.
	 *
	 * Documentation for signature generation:
	 * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
	 * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
	 */
	function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
		// Divide the signature in r, s and v variables
		bytes32 r;
		bytes32 s;
		uint8 v;

		// Check the signature length
		// - case 65: r,s,v signature (standard)
		// - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
		if (signature.length == 65) {
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			assembly {
				r := mload(add(signature, 0x20))
				s := mload(add(signature, 0x40))
				v := byte(0, mload(add(signature, 0x60)))
			}
		}
		else if (signature.length == 64) {
			// ecrecover takes the signature parameters, and the only way to get them
			// currently is to use assembly.
			assembly {
				let vs := mload(add(signature, 0x40))
				r := mload(add(signature, 0x20))
				s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
				v := add(shr(255, vs), 27)
			}
		}
		else {
			revert("invalid signature length");
		}

		return recover(hash, v, r, s);
	}

	/**
	 * @dev Overload of {ECDSA-recover} that receives the `v`,
	 * `r` and `s` signature fields separately.
	 */
	function recover(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (address) {
		// EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
		// unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
		// the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
		// signatures from current libraries generate a unique signature with an s-value in the lower half order.
		//
		// If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
		// with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
		// vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
		// these malleable signatures as well.
		require(
			uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
			"invalid signature 's' value"
		);
		require(v == 27 || v == 28, "invalid signature 'v' value");

		// If the signature is valid (and not malleable), return the signer address
		address signer = ecrecover(hash, v, r, s);
		require(signer != address(0), "invalid signature");

		return signer;
	}

	/**
	 * @dev Returns an Ethereum Signed Message, created from a `hash`. This
	 * produces hash corresponding to the one signed with the
	 * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
	 * JSON-RPC method as part of EIP-191.
	 *
	 * See {recover}.
	 */
	function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
		// 32 is the length in bytes of hash,
		// enforced by the type signature above
		return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
	}

	/**
	 * @dev Returns an Ethereum Signed Typed Data, created from a
	 * `domainSeparator` and a `structHash`. This produces hash corresponding
	 * to the one signed with the
	 * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
	 * JSON-RPC method as part of EIP-712.
	 *
	 * See {recover}.
	 */
	function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
		return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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