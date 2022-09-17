//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintObject.sol";

abstract contract Authentication {
	address public deployer;
	/// @notice for re-entry prevention, keeps track of a methods execution count
	uint256 private executionCount;

	mapping(address => bool) internal approved;

	constructor() {
		deployer = msg.sender;
		approved[msg.sender] = true;
		executionCount = 0;
	}

	/// @notice Limits execution of a method to once in the given context.
	/// @dev prevents re-entry attack
	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	modifier onlyDeployer() {
		require(deployer == msg.sender, "not deployer");
		_;
	}

	modifier onlyApproved() {
		require(msg.sender == deployer || approved[msg.sender], "not approved");
		_;
	}

	function togglePrivilages(address addr) public onlyDeployer {
		approved[addr] = !approved[addr];
	}

	function setPrivilages(address addr, bool value) public onlyDeployer {
		approved[addr] = value;
	}

	function transferOwnership(address addr) public onlyDeployer {
		approved[deployer] = false;
		deployer = addr;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol) (Thanks <3)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
	/**
	 * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
	 */
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
	 */
	event Approval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	 */
	event ApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);

	/**
	 * @dev Returns the number of tokens in ``owner``'s account.
	 */
	function balanceOf(address owner) external view returns (uint256 balance);

	/**
	 * @dev Returns the owner of the `tokenId` token.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function ownerOf(uint256 tokenId) external view returns (address owner);

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	/**
	 * @dev Transfers `tokenId` token from `from` to `to`.
	 *
	 * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	/**
	 * @dev Gives permission to `to` to transfer `tokenId` token to another account.
	 * The approval is cleared when the token is transferred.
	 *
	 * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
	 *
	 * Requirements:
	 *
	 * - The caller must own the token or be an approved operator.
	 * - `tokenId` must exist.
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address to, uint256 tokenId) external;

	/**
	 * @dev Returns the account approved for `tokenId` token.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function getApproved(uint256 tokenId)
		external
		view
		returns (address operator);

	/**
	 * @dev Approve or remove `operator` as an operator for the caller.
	 * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
	 *
	 * Requirements:
	 *
	 * - The `operator` cannot be the caller.
	 *
	 * Emits an {ApprovalForAll} event.
	 */
	function setApprovalForAll(address operator, bool _approved) external;

	/**
	 * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
	 *
	 * See {setApprovalForAll}
	 */
	function isApprovedForAll(address owner, address operator)
		external
		view
		returns (bool);

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes calldata data
	) external;
}

/// @title ERC-721 Non-Fungible Token Standard, ERC721 Receiver
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IERC721Receiver {
	/**
	 * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
	 * by `operator` from `from`, this function is called.
	 *
	 * It must return its Solidity selector to confirm the token transfer.
	 * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
	 *
	 * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
	 */
	function onERC721Received(
		address operator,
		address from,
		uint256 tokenId,
		bytes calldata data
	) external returns (bytes4);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata is IERC721 {
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

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//this is implemented by every contract in our system
import "./InfinityMintUtil.sol";
import "./InfinityMintValues.sol";

abstract contract InfinityMintObject {
	/// @notice The main InfinityMint object, TODO: Work out a way for this to easily be modified
	struct InfinityObject {
		uint32 pathId;
		uint32 pathSize;
		uint32 currentTokenId;
		address owner;
		uint32[] colours;
		bytes mintData;
		uint32[] assets;
		string[] names;
		address[] destinations;
	}

	/// @notice Creates a new struct from arguments
	/// @dev Stickers are not set through this, structs cannot be made with sticker contracts already set and have to be set manually
	/// @param currentTokenId the tokenId,
	/// @param pathId the infinity mint paths id
	/// @param pathSize the size of the path (only for vectors)
	/// @param assets the assets which make up the token
	/// @param names the names of the token, its just the name but split by the splaces.
	/// @param colours decimal colours which will be convered to hexadecimal colours
	/// @param mintData variable dynamic field which is passed to ERC721 Implementor contracts and used in a lot of dynamic stuff
	/// @param _sender aka the owner of the token
	/// @param destinations a list of contracts associated with this token
	function createInfinityObject(
		uint32 currentTokenId,
		uint32 pathId,
		uint32 pathSize,
		uint32[] memory assets,
		string[] memory names,
		uint32[] memory colours,
		bytes memory mintData,
		address _sender,
		address[] memory destinations
	) internal pure returns (InfinityObject memory) {
		return
			InfinityObject(
				pathId,
				pathSize,
				currentTokenId,
				_sender, //the sender aka owner
				colours,
				mintData,
				assets,
				names,
				destinations
			);
	}

	/// @notice basically unpacks a return object into bytes.
	function encode(InfinityObject memory data)
		internal
		pure
		returns (bytes memory)
	{
		return
			abi.encode(
				data.pathId,
				data.pathSize,
				data.currentTokenId,
				data.owner,
				abi.encode(data.colours),
				data.mintData,
				data.assets,
				data.names,
				data.destinations
			);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function sender() internal view returns (address) {
		return (msg.sender);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function value() internal view returns (uint256) {
		return (msg.value);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

library InfinityMintUtil {
	function toString(uint256 _i)
		internal
		pure
		returns (string memory _uintAsString)
	{
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

	function filepath(
		string memory directory,
		string memory file,
		string memory extension
	) internal pure returns (string memory) {
		return
			abi.decode(abi.encodePacked(directory, file, extension), (string));
	}

	//checks if two strings (or bytes) are equal
	function isEqual(bytes memory s1, bytes memory s2)
		internal
		pure
		returns (bool)
	{
		bytes memory b1 = bytes(s1);
		bytes memory b2 = bytes(s2);
		uint256 l1 = b1.length;
		if (l1 != b2.length) return false;
		for (uint256 i = 0; i < l1; i++) {
			//check each byte
			if (b1[i] != b2[i]) return false;
		}
		return true;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

contract InfinityMintValues {
	mapping(string => uint256) private values;
	mapping(string => bool) private booleanValues;
	mapping(string => bool) private registeredValues;

	address deployer;

	constructor() {
		deployer = msg.sender;
	}

	modifier onlyDeployer() {
		if (msg.sender != deployer) revert();
		_;
	}

	function setValue(string memory key, uint256 value) public onlyDeployer {
		values[key] = value;
		registeredValues[key] = true;
	}

	function setupValues(
		string[] memory keys,
		uint256[] memory _values,
		string[] memory booleanKeys,
		bool[] memory _booleanValues
	) public onlyDeployer {
		require(keys.length == _values.length);
		require(booleanKeys.length == _booleanValues.length);
		for (uint256 i = 0; i < keys.length; i++) {
			setValue(keys[i], _values[i]);
		}

		for (uint256 i = 0; i < booleanKeys.length; i++) {
			setBooleanValue(booleanKeys[i], _booleanValues[i]);
		}
	}

	function setBooleanValue(string memory key, bool value)
		public
		onlyDeployer
	{
		booleanValues[key] = value;
		registeredValues[key] = true;
	}

	function isTrue(string memory key) external view returns (bool) {
		return booleanValues[key];
	}

	function getValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) revert("Invalid Value");

		return values[key];
	}

	/// @dev Default value it returns is zero
	function tryGetValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) return 0;

		return values[key];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./../Authentication.sol";
import "./../IERC721.sol";

contract Mod_Redemption is IERC721Receiver, Authentication, InfinityMintObject {
	IERC721 erc721;

	mapping(uint256 => bytes) private activeRedemptions;
	mapping(uint256 => bytes) private requests;
	mapping(address => bool) private blockedWallets;
	mapping(uint256 => address) private successfulRedemptions;
	uint256[] private tokenIds;

	event RequestSubmitted(uint256 tokenId, address indexed sender);

	constructor(address erc721Destination) {
		erc721 = IERC721(erc721Destination);
	}

	/// @notice Allows you to block an address to combat griefing
	function toggleWalletBlocked(address sender, bool value)
		public
		onlyApproved
	{
		blockedWallets[sender] = value;
	}

	function getRequestOwner(uint256 tokenId) external view returns (address) {
		if (requests[tokenId].length == 0) return address(0x0);
		//decode request
		(
			address sender,
			bytes memory theirRedemption,
			bytes memory theirKey,
			uint256 blockNumber
		) = abi.decode(requests[tokenId], (address, bytes, bytes, uint256));

		return sender;
	}

	function getRequest(uint256 tokenId)
		public
		view
		onlyApproved
		returns (bytes memory)
	{
		return requests[tokenId];
	}

	function getActiveRedemption(uint256 tokenId)
		public
		view
		onlyApproved
		returns (bytes memory)
	{
		return activeRedemptions[tokenId];
	}

	function isRedeemable(uint256 tokenId) external view returns (bool) {
		return bytes(activeRedemptions[tokenId]).length != 0;
	}

	function makeUnredeemable(uint256 tokenId) public {
		require(
			bytes(activeRedemptions[tokenId]).length != 0,
			"must be redeemable"
		);
		require(
			successfulRedemptions[tokenId] == address(0x0),
			"already redeemed cannot change"
		);

		delete activeRedemptions[tokenId];
	}

	/// @notice Allows this redemption contract to receive ERC721
	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external view onlyApproved returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}

	/// @notice Rejects a request to redeem a token
	function rejectRedeem(uint256 tokenId) public onlyApproved {
		require(requests[tokenId].length != 0, "invalid request");
		require(
			bytes(activeRedemptions[tokenId]).length != 0,
			"invalid redemption token id"
		);
		require(
			successfulRedemptions[tokenId] == address(0x0),
			"token has already been redeemed"
		);

		delete requests[tokenId];
	}

	/// @notice Approves a request to redeem a token
	function approveRedeem(bytes memory request) public onlyApproved onlyOnce {
		(uint256 tokenId, bytes memory redemption) = abi.decode(
			request,
			(uint256, bytes)
		);

		//is valid request
		require(requests[tokenId].length != 0, "invalid request");
		//active redemption valid
		require(
			bytes(activeRedemptions[tokenId]).length != 0,
			"invalid redemption token id"
		);
		//has already been redeemed
		require(
			successfulRedemptions[tokenId] == address(0x0),
			"token has already been redeemed"
		);
		//check that the passcode is equal to the activeRedemptions passcode.
		require(
			InfinityMintUtil.isEqual(redemption, activeRedemptions[tokenId]),
			"check failed"
		);

		//decode request
		(
			address sender,
			bytes memory theirRedemption,
			bytes memory theirKey,
			uint256 blockNumber
		) = abi.decode(requests[tokenId], (address, bytes, bytes, uint256));
		require(block.number > blockNumber, "validation unsuccessful");

		//second passcode check
		require(
			InfinityMintUtil.isEqual(redemption, theirRedemption),
			"validation failed"
		);

		//write to storage
		successfulRedemptions[tokenId] = sender;
		delete requests[tokenId];
		//transfer the token from this contract to the sender
		erc721.safeTransferFrom(address(this), sender, tokenId);
	}

	/// @notice Requests a token to be transfered to the sender
	function requestToken(bytes memory request) public {
		require(!isContract(sender()), "cannot be invoked by contract");
		require(request.length < 5012, "request too large");
		require(!blockedWallets[sender()], "check failed");

		(uint256 tokenId, bytes memory redemption, bytes memory theirKey) = abi
			.decode(request, (uint256, bytes, bytes));

		require(
			successfulRedemptions[tokenId] == address(0x0),
			"token has already been redeemed"
		);
		require(
			bytes(activeRedemptions[tokenId]).length != 0,
			"invalid redemption token id"
		);
		require(
			requests[tokenId].length == 0,
			"request already open for this token"
		);
		require(
			InfinityMintUtil.isEqual(redemption, activeRedemptions[tokenId]),
			"validation failed"
		);

		requests[tokenId] = abi.encode(
			sender(),
			redemption,
			theirKey,
			block.number
		);
		emit RequestSubmitted(tokenId, sender());
	}

	function addRedemption(uint256 tokenId, bytes memory redemption)
		public
		onlyApproved
	{
		require(bytes(activeRedemptions[tokenId]).length == 0, "already set");

		require(
			erc721.ownerOf(tokenId) == address(this),
			"please transfer the token to this contract first"
		);

		tokenIds.push(tokenId);
		activeRedemptions[tokenId] = redemption;
	}

	function addRedemptions(bytes[] memory redemptions) public onlyApproved {
		for (uint256 i = 0; i < redemptions.length; ) {
			(uint256 tokenId, bytes memory redemption) = abi.decode(
				redemptions[i],
				(uint256, bytes)
			);
			tokenIds.push(tokenId);
			activeRedemptions[tokenId] = redemption;
		}
	}

	///@notice Returns true if the address is a contract
	///@dev Sometimes doesnt work and contracts might be disgused as addresses
	function isContract(address _address) internal view returns (bool) {
		uint256 size;
		assembly {
			size := extcodesize(_address)
		}
		return size > 0;
	}
}