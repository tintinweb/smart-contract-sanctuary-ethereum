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
		if (msg.sender != deployer) revert("not deployer");
		_;
	}

	modifier onlyApproved() {
		if (approved[msg.sender] == false) revert("not approved");
		_;
	}

	function togglePrivilages(address addr) public onlyDeployer {
		approved[addr] = !approved[addr];
	}

	function transferOwnership(address addr) public onlyDeployer {
		deployer = addr;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./ERC165.sol";
import "./IERC165.sol";

/// @title ERC-721 Infinity Mint Implementation
/// @author Llydia Cross
/// @notice This is a basic ERC721 Implementation that is designed to be as simple and gas efficient as possible.
/// @dev This contract supports tokenURI (the Metadata extension) but does not include the Enumerable extension.
contract ERC721 is ERC165, IERC721, IERC721Metadata {
	///@notice Storage for the tokens
	///@dev indexed by tokenId
	mapping(uint256 => address) internal tokens; //(slot 0)
	///@notice Storage the token metadata
	///@dev indexed by tokenId
	mapping(uint256 => string) internal uri; //(slot 1)
	///@notice Storage the token metadata
	///@dev indexed by tokenId
	mapping(uint256 => address) internal approvedTokens; //(slot 2)
	///@notice Stores approved operators for the addresses tokens.
	mapping(address => mapping(address => bool)) internal operators; //(slot 3)
	///@notice Stores the balance of tokens
	mapping(address => uint256) internal balance; //(slot 4)

	///@notice The name of the ERC721
	string internal _name; //(slot 5)
	///@notice The Symbol of the ERC721
	string internal _symbol; //(slot 6)

	/**
        @notice ERC721 Constructor takes tokenName and tokenSymbol
     */
	constructor(string memory tokenName, string memory tokenSymbol) {
		_name = tokenName;
		_symbol = tokenSymbol;
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 * /// @notice this is used by opensea/polyscan to detect our ERC721
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC165, IERC165)
		returns (bool)
	{
		return
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
        @notice blanceOf returns the number of tokens an address currently holds.
     */
	function balanceOf(address _owner) public view override returns (uint256) {
		return balance[_owner];
	}

	/**
        @notice Returns the owner of a current token
        @dev will Throw if the token does not exist
     */
	function ownerOf(uint256 _tokenId)
		public
		view
		virtual
		override
		returns (address)
	{
		require(exists(_tokenId));
		return tokens[_tokenId];
	}

	/**
        @notice Will approve an operator for the senders tokens
    */
	function setApprovalForAll(address _operator, bool _approved)
		public
		override
	{
		operators[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	/**
        @notice Will returns true if the operator is approved by the owner address
    */
	function isApprovedForAll(address _owner, address _operator)
		public
		view
		override
		returns (bool)
	{
		return operators[_owner][_operator];
	}

	/**
        @notice Returns the tokens URI Metadata object
    */
	function tokenURI(uint256 _tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		return uri[_tokenId];
	}

	/**
        @notice Returns the name of the ERC721  for display on places like Etherscan
    */
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	/**
        @notice Returns the symbol of the ERC721 for display on places like Polyscan
    */
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	/**
        @notice Returns the approved adress for this token.
    */
	function getApproved(uint256 _tokenId)
		public
		view
		override
		returns (address)
	{
		return approvedTokens[_tokenId];
	}

	/// @notice Is true if the sender is either the owner of the token, approved for the token, or approved for all of the owners tokens.
	/// @dev will Throw if tokenId does not exist
	function isAllowed(address _sender, uint256 _tokenId)
		internal
		view
		returns (bool)
	{
		address owner = ERC721.ownerOf(_tokenId);
		return (_sender == owner ||
			getApproved(_tokenId) == _sender ||
			isApprovedForAll(owner, _sender));
	}

	/**
        @notice Sets an approved adress for this token
        @dev will Throw if tokenId does not exist
    */
	function approve(address _to, uint256 _tokenId) public override {
		require(isAllowed(msg.sender, _tokenId), "sender is not approved");

		approvedTokens[_tokenId] = _to;
		emit Approval(ownerOf(_tokenId), _to, _tokenId);
	}

	/**
        @notice Mints a token.
        @dev If you are transfering a token to a contract the contract will make sure that it can recieved the ERC721 (implements a IERC721Receiver)
        if it does not it will revert the transcation. Emits a {Transfer} event.
    */
	function mint(
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal {
		require(_to != address(0x0), "Cannot mint to 0x0");
		require(!exists(_tokenId), "Token has already minted");

		balance[_to] += 1;
		tokens[_tokenId] = _to;

		emit Transfer(address(0x0), _to, _tokenId);

		//check that the ERC721 has been received
		require(
			checkERC721Received(msg.sender, address(0x0), _to, _tokenId, _data)
		);
	}

	/**
        @notice Returns true if a token exists.
     */
	function exists(uint256 _tokenId) public view returns (bool) {
		return tokens[_tokenId] != address(0x0);
	}

	/**
        @notice Transfers a token from one address to another. Use safeTransferFrom as that will double check that the address you send this token too is a contract that can actually receive it.
		@dev Emits a {Transfer} event.
     */
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override {
		require(isAllowed(msg.sender, _tokenId), "sender is not approved");
		require(
			ERC721.ownerOf(_tokenId) == _from,
			"From address does not match the owner of the token"
		);
		require(_to != address(0x0), "You cannot transfer to 0x0");

		approve(address(0x0), _tokenId);
		balance[_from] -= 1;
		balance[_to] -= 1;
		tokens[_tokenId] = _to;

		emit Transfer(_from, _to, _tokenId);
	}

	/// @notice will returns true if the address is apprroved for all, approved operator or is the owner of a token
	/// @dev same as open zepps
	function isApprovedOrOwner(address addr, uint256 tokenId)
		internal
		view
		returns (bool)
	{
		return (ERC721.ownerOf(tokenId) == addr ||
			ERC721.isAllowed(addr, tokenId) ||
			ERC721.isApprovedForAll(ERC721.ownerOf(tokenId), addr));
	}

	/**
        @notice Just like transferFrom except we will check if the to address is a contract and is an IERC721Receiver implementer
		@dev Emits a {Transfer} event.
     */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) public virtual override {
		_safeTransferFrom(_from, _to, _tokenId, _data);
	}

	/**
        @notice Just like the method above except with no data field we pass to the implemeting contract.
		@dev Emits a {Transfer} event.
     */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override {
		_safeTransferFrom(_from, _to, _tokenId, "");
	}

	/**
        @notice Internal method to transfer the token and require that checkERC721Recieved is equal to true.
     */
	function _safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) private {
		ERC721.transferFrom(_from, _to, _tokenId);
		//check that it implements an IERC721 receiver if it is a contract
		require(
			checkERC721Received(msg.sender, _from, _to, _tokenId, _data),
			"ERC721 Receiver Confirmation Is Bad"
		);
	}

	/**
        @notice Checks first if the to address is a contract, if it is it will confirm that the contract is an ERC721 implentor by confirming the selector returned as documented in the ERC721 standard. If the to address isnt a contract it will just return true. Based on the code inside of OpenZeppelins ERC721
     */
	function checkERC721Received(
		address _operator,
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) private returns (bool) {
		if (!isContract(_to)) return true;

		try
			IERC721Receiver(_to).onERC721Received(
				_operator,
				_from,
				_tokenId,
				_data
			)
		returns (bytes4 confirmation) {
			return (confirmation == IERC721Receiver.onERC721Received.selector);
		} catch (bytes memory reason) {
			if (reason.length == 0) {
				revert("This contract does not implement an IERC721Receiver");
			} else {
				assembly {
					revert(add(32, reason), mload(reason))
				}
			}
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

import "./InfinityMintStickers.sol";
import "./InfinityMintWallet.sol";

/// @title InfinityMint Sticker + Wallet Factory Contract
/// @author Llydia Cross
/// @notice Deploys new ERC721 Sticker contracts to an InfinityMint token, this contract is meant to be linked to an InfinityMint but will technically work with any ERC721
/// @dev The factory is deployed precompiled with the ABI's we are strapping onto the tokens, this way we can deploy new factories which attach new EAS versions at any time.
contract InfinityMintFactory {
	/// @notice the location of the main ERC721 contract
	address public erc721;
	/// @notice location of InfinityMint values contract
	address public valuesController;
	/// @notice location of the storage contract
	address public storageDestination;

	/// @notice Is a copy of the one found in /contracts/InfinityMintObject.sol
	struct ReturnObject {
		uint64 pathId;
		uint64 pathSize;
		uint64 currentTokenId;
		address owner;
		address wallet;
		address stickers;
		uint64[] colours;
		string mintData;
		uint64[] assets;
		string[] names;
	}

	constructor(
		address _storageDestination,
		address erc721Destination,
		address _valuesController
	) {
		storageDestination = _storageDestination;
		erc721 = erc721Destination;
		valuesController = _valuesController;
	}

	event StickerContractDeployed(
		uint64 tokenId,
		address stickerContract,
		address indexed sender
	);

	event WalletContractDeployed(
		uint64 tokenId,
		address stickerContract,
		address indexed sender
	);

	/// @notice Deploys an a wallet contract.
	/// @dev THIS METHOD DEPLOYS A CONTRACT! This method takes about 400k gas.
	/// @param tokenId the tokenId to deploy the wallet contract on.
	function deployWalletContract(uint64 tokenId) external {
		address sender = (msg.sender);
		require(ownerOf(tokenId) == sender, "Not the owner of this token");

		//get object
		ReturnObject memory temp = get(tokenId);
		require(temp.wallet == address(0x0), "wallet already set");

		deployContract(tokenId, sender, true);
	}

	/// @notice Deploys sticker/wallet contract to a token but called from the main ERC721, considered unsafe as this tx could not be called by the user but is forced by the main ERC721
	/// @dev Allows main ERC721 to link back to this contract and mint.
	/// @param tokenId the tokenId to deploy the sticker/wallet contract on.
	/// @param sender the sender aka msg.sender or in the context of unsafe the sender from the main ERC721 contract
	/// @param isSticker deploys sticker contract, emits StickerContractDeployed if true, Deploys wallet, emits WalletContractDeployed if false
	function unsafeDeployContract(
		uint64 tokenId,
		address sender,
		bool isSticker
	) public {
		require(
			msg.sender == erc721,
			"can only be called from InfinityMint contract"
		);

		deployContract(tokenId, sender, isSticker);
	}

	/// @notice Deploys either an Ethereum Ad Service sticker contract, or a wallet contract.
	/// @dev Deploying a sticker contract costs about 3,000,000 gas, the wallet is tiny at only about 400k
	/// @param tokenId the tokenId to deploy the sticker/wallet contract on.
	/// @param sender the sender aka msg.sender or in the context of unsafe the sender from the main ERC721 contract
	/// @param isSticker deploys sticker contract, emits StickerContractDeployed if true, Deploys wallet, emits WalletContractDeployed if false
	function deployContract(
		uint64 tokenId,
		address sender,
		bool isSticker
	) private {
		//get object
		ReturnObject memory temp = get(tokenId);

		address location;
		if (isSticker)
			//deploy new stickers contract
			location = address(
				new InfinityMintStickers(
					tokenId,
					sender,
					erc721,
					temp.wallet,
					address(valuesController)
				)
			);
		else
			location = address(
				new InfinityMintWallet(tokenId, msg.sender, erc721)
			);

		set(
			tokenId,
			ReturnObject(
				temp.pathId,
				temp.pathSize,
				temp.currentTokenId,
				temp.owner,
				(!isSticker ? location : temp.wallet),
				(isSticker ? location : temp.stickers), //set the new address of the deployed sticker contract
				temp.colours,
				temp.mintData,
				temp.assets,
				temp.names
			)
		);

		if (isSticker) emit StickerContractDeployed(tokenId, location, sender);
		else emit WalletContractDeployed(tokenId, location, sender);
	}

	/// @notice gets token
	/// @dev erc721 address must be ERC721 implementor.
	function get(uint64 tokenId) private view returns (ReturnObject memory) {
		(bool success, bytes memory result) = address(storageDestination)
			.staticcall(
				abi.encodeWithSignature("get(uint64)", uint64(tokenId))
			);

		require(success, "invalid token");

		return abi.decode(result, (ReturnObject));
	}

	/// @notice Deploys an EADS sticker contract.
	/// @dev THIS METHOD DEPLOYS A CONTRACT! This method takes at max 4m gas.
	/// @param tokenId the tokenId to deploy the sticker contract on.
	function deployStickerContract(uint64 tokenId) public {
		address sender = (msg.sender);
		require(ownerOf(tokenId) == sender, "Not the owner of this token");

		//get object
		ReturnObject memory temp = get(tokenId);

		require(temp.stickers == address(0x0), "stickers already set");
		require(temp.wallet != address(0x0), "deploy wallet first");

		deployContract(tokenId, sender, true);
	}

	/// @notice Returns the owner of token
	/// @dev erc721 address must be ERC721 implementor.
	function ownerOf(uint64 tokenId) private view returns (address) {
		(bool success, bytes memory result) = address(erc721).staticcall(
			abi.encodeWithSignature("ownerOf(uint256)", uint256(tokenId))
		);

		if (!success) return address(0x0);

		return abi.decode(result, (address));
	}

	/// @notice sets the token to a new value
	/// @dev this contract must have approval access to the storage contract
	function set(uint64 tokenId, ReturnObject memory data) private {
		(bool success, bytes memory returnData) = address(storageDestination)
			.call(
				abi.encodeWithSignature(
					"setRaw(uint64,bytes)",
					tokenId,
					abi.encode(data)
				)
			);

		if (!success) {
			if (returnData.length == 0) revert("set call reverted");
			else
				assembly {
					let returndata_size := mload(returnData)
					revert(add(32, returnData), returndata_size)
				}
		}
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

//this is implemented by every contract in our system
import "./InfinityMintUtil.sol";
import "./InfinityMintValues.sol";

abstract contract InfinityMintObject {
	/// @notice The main InfinityMint object, TODO: Work out a way for this to easily be modified
	struct ReturnObject {
		uint64 pathId;
		uint64 pathSize;
		uint64 currentTokenId;
		address owner;
		address wallet;
		address stickers;
		uint64[] colours;
		string mintData;
		uint64[] assets;
		string[] names;
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
	/// @param wallet the wallet location
	function createReturnObject(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		uint64[] memory assets,
		string[] memory names,
		uint64[] memory colours,
		string memory mintData,
		address _sender,
		address wallet
	) internal pure returns (ReturnObject memory) {
		return
			ReturnObject(
				pathId,
				pathSize,
				currentTokenId,
				_sender, //the sender aka owner
				wallet, //the address of the wallet contract
				address(0x0), //stores stickers
				colours,
				mintData,
				assets,
				names
			);
	}

	/// @notice basically unpacks a return object into bytes.
	function encode(ReturnObject memory data)
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
				data.wallet,
				data.stickers,
				abi.encode(data.colours),
				bytes(data.mintData),
				data.assets,
				data.names
			);
	}

	/// @notice Copied behavours of the open zeppelin content due to prevent msg.sender rewrite through assembly
	function sender() internal view virtual returns (address) {
		return msg.sender;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Stickers.sol";
import "./ERC721.sol";

/// @title InfinityMint Ethereum Ad Service Sticker ERC721
/// @author Llydia Cross
/// @notice This is an ERC721 contract powering eads stickers, these are attached to every token minted by InfinityMint.
/// @dev Must be created with its core controllers already deployed, such as InfinityMintStorage, randomNumber and Royalty.
contract InfinityMintStickers is Stickers, ERC721 {
	uint256 internal tokenValue;
	bool internal enabled;

	InfinityMintValues public valuesController;

	mapping(uint64 => bytes) internal flags;

	constructor(
		uint64 tokenId,
		address owner,
		address erc721Destination,
		address EASWalletAddress,
		address valuesContract
	) StickerInterface() ERC721("EAS Sticker", "EAS-S") {
		currentTokenId = tokenId;
		valuesController = InfinityMintValues(valuesContract);
		stickerPrice = 1 * valuesController.tryGetValue("baseTokenValue");
		erc721 = erc721Destination;
		EASWallet = InfinityMintWallet(EASWalletAddress);
		enabled = true;
		//authentication stuff
		togglePrivilages(owner);
		transferOwnership(owner);
	}

	function totalSupply() external view returns (uint256) {
		return currentStickerId;
	}

	function setPrice(uint256 tokenPrice) public onlyDeployer {
		require(tokenPrice >= 0);
		stickerPrice = tokenPrice * tokenValue;
	}

	function setWalletAddresss(address EASWalletAddress) public onlyDeployer {
		require(isContract(EASWalletAddress), "is not a contract");
		require(
			InfinityMintWallet(EASWalletAddress).deployer() == deployer,
			"the deployer for this contract and the wallet contract must be the same"
		);

		EASWallet = InfinityMintWallet(EASWalletAddress);
	}

	function updateSticker(uint64 stickerId, bytes memory packed) public {
		address sender = (msg.sender);
		require(isApprovedOrOwner(sender, uint256(stickerId)));
		require(isSafe(packed), "your packed sticker is unsafe");
		require(
			enabled,
			"stickers are not enabled right now and need to be enabled in order to update"
		);

		(, , , address theirOwner) = InfinityMintUtil.unpackSticker(packed);
		(, , , address actualOwner) = InfinityMintUtil.unpackSticker(
			stickers[stickerId]
		);

		require(theirOwner == actualOwner, "trying to change the owner");

		stickers[stickerId] = packed;
	}

	function setEnabled(bool isEnabled) public onlyDeployer {
		enabled = isEnabled;
	}

	function setFlaggedSticker(uint64 stickerId, bool isFlagged)
		public
		onlyDeployer
	{
		setFlaggedSticker(stickerId, isFlagged, "no reason");
	}

	function isStickerFlagged(uint64 stickerId)
		external
		view
		returns (bool, string memory)
	{
		if (flags[stickerId].length == 0) return (false, "");
		return abi.decode(flags[stickerId], (bool, string));
	}

	function setFlaggedSticker(
		uint64 stickerId,
		bool isFlagged,
		string memory reason
	) public onlyDeployer {
		require(stickerId < currentStickerId);

		if (!isFlagged && flags[stickerId].length != 0) delete flags[stickerId];
		else flags[stickerId] = abi.encode(isFlagged, reason);
	}

	/// @notice Transfers a token from one address to the other, use this over transferFrom as this checks if the 'to' address is a contract and if it can implement ERC721
	/// @dev you need to call this from an approved address for the token
	/// @param from the adress it will be transfered from
	/// @param to the adress the token will be transfered too
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory data
	) public override onlyOnce {
		_transfer(from, to, uint64(tokenId), data);
	}

	// @notice Transfers a token from one address to the other, use this over transferFrom as this checks if the 'to' address is a contract and if it can implement ERC721
	/// @dev you need to call this from an approved address for the token
	/// @param from the adress it will be transfered from
	/// @param to the adress the token will be transfered too
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override onlyOnce {
		_transfer(from, to, uint64(tokenId), bytes(""));
	}

	function _transfer(
		address from,
		address to,
		uint64 tokenId,
		bytes memory data
	) internal {
		(, string memory checkSum, string memory object, ) = InfinityMintUtil
			.unpackSticker(stickers[tokenId]);

		//save the sticker to point to the new owner
		stickers[tokenId] = abi.encode(tokenId, checkSum, object, to);
		//add to new registered owner
		registeredOwners[to].push(currentStickerId);

		//update the old owners array
		if (registeredOwners[from].length - 1 <= 0)
			registeredOwners[from] = new uint64[](0);
		else {
			uint64[] memory temp = new uint64[](
				registeredOwners[from].length - 1
			);
			uint64[] memory copy = (registeredOwners[from]);
			uint256 index = 0;
			for (uint256 i = 0; i < copy.length; i++) {
				if (copy[i] == tokenId) continue;
				temp[index++] = tokenId;
			}
			registeredOwners[from] = temp;
		}

		ERC721.safeTransferFrom(from, to, tokenId, data);
	}

	/// @notice Transfers a token from one address to the other, use safeTransferFrom as that checks if the receiver is a contract and if they can hold NFT's
	/// @dev you need to call this from an approved address for the token
	/// @param from the adress it will be transfered from
	/// @param to the adress the token will be transfered too
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public override onlyOnce {
		_transfer(from, to, uint64(tokenId), bytes(""));
	}

	function acceptRequest(address sender, uint64 index)
		public
		override
		onlyApproved
		onlyOnce
	{
		require(requests[sender][index].length != 0);

		(uint256 price, address savedSender, bytes memory packed) = abi.decode(
			requests[sender][index],
			(uint256, address, bytes)
		);

		require(sender == savedSender, "sender and saved sender are different");

		if (price > 0) {
			uint256 cut = (price / 100) *
				valuesController.tryGetValue("stickerSplit");

			//deduct the cut from the price but only if it does not completely take the price
			if (price - cut > 0)
				price = price - cut;
				//else set the cut to zero
			else cut = 0;

			//transfer the cut back tot the main ERC721
			(bool success, bytes memory returnData) = address(erc721).call{
				value: cut
			}(
				abi.encodeWithSignature(
					"depositStickerRoyalty(uint64)",
					currentTokenId
				)
			);

			//TODO: Maybe hold the money if it reverts?
			if (!success) {
				if (returnData.length == 0)
					revert("deposit sticker royalty call reverted");
				else
					assembly {
						let returndata_size := mload(returnData)
						revert(add(32, returnData), returndata_size)
					}
			}

			EASWallet.deposit{ value: price }(); //deposit it to us
		}

		//mint the sticker
		ERC721.mint(savedSender, currentStickerId, packed);
		//save the sticker
		stickers[currentStickerId] = packed;
		//delete the request
		deleteRequest(sender, index);
		registeredOwners[sender].push(currentStickerId); //push this sticker id to the registered owners

		//emit
		emit EASRequestAccepted(currentStickerId++, sender, price, packed);
	}

	function tokenURI(uint256 stickerId)
		public
		view
		override
		returns (string memory)
	{
		if (
			bytes(uri[stickerId]).length == 0 &&
			stickers[uint64(stickerId)].length == 0
		) revert("Token URI for non existent token");

		if (bytes(uri[stickerId]).length != 0) return uri[stickerId];

		require(
			isSafe(stickers[uint64(stickerId)]),
			"request is not safely packed"
		);

		(, , string memory object, ) = InfinityMintUtil.unpackSticker(
			stickers[uint64(stickerId)]
		);

		return object;
	}

	function addRequest(bytes memory packed) public payable override onlyOnce {
		require(msg.value == stickerPrice, "not the sticker price");
		require(isSafe(packed), "your packed sticker is unsafe");
		require(enabled, "no new stickers can be added right now");

		address sender = (msg.sender);
		//add it!
		requests[sender].push(abi.encode(msg.value, sender, packed));
		if (!hasOpenRequests(sender)) openRequests.push(sender);

		emit EASRequestAdded(
			uint64(requests[sender].length - 1),
			sender,
			msg.value,
			packed
		); //emit
	}

	function withdrawRequest(uint64 index) public override onlyOnce {
		address sender = (msg.sender);

		require(requests[sender][index].length != 0);

		(uint256 price, address savedSender, bytes memory packed) = abi.decode(
			requests[sender][index],
			(uint256, address, bytes)
		);

		//require the current sender and the saved sender to be the same
		require(savedSender == sender);
		//transfer
		payable(savedSender).transfer(price); //transfer back the price to the sender
		//delete the rquest
		deleteRequest(sender, index);
		//emit
		emit EASRequestWithdrew(index, savedSender, price, packed);
	}

	function denyRequest(address sender, uint64 index)
		public
		override
		onlyApproved
		onlyOnce
	{
		require(requests[sender][index].length != 0);

		(uint256 price, address savedSender, bytes memory packed) = abi.decode(
			requests[sender][index],
			(uint256, address, bytes)
		);

		//delete the request
		deleteRequest(sender, index);
		//send the money back to the sender of the sticker offer
		payable(savedSender).transfer(price);
		emit EASRequestDenied(index, sender, price, packed);
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

	function square(uint256 num, uint256 amount)
		internal
		pure
		returns (uint256)
	{
		if (amount <= 1) return (num * num);

		for (uint256 i = 0; i < amount; i++) num = (num * num);
		return num;
	}

	function getRSV(bytes memory signature)
		internal
		pure
		returns (
			bytes32 r,
			bytes32 s,
			uint8 v
		)
	{
		require(signature.length == 65, "invalid length");
		assembly {
			r := mload(add(signature, 32))
			s := mload(add(signature, 64))
			v := byte(0, mload(add(signature, 96)))
		}
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

	function unpackSticker(bytes memory sticker)
		internal
		pure
		returns (
			uint64 tokenId,
			string memory checkSum,
			string memory object,
			address owner
		)
	{
		return abi.decode(sticker, (uint64, string, string, address));
	}

	function unpackKazoo(bytes memory preview)
		internal
		pure
		returns (
			uint64 pathId,
			uint64 pathSize,
			uint64 tokenId,
			address owner,
			address wallet,
			address stickers,
			bytes memory colours,
			bytes memory data,
			uint64[] memory assets,
			string[] memory names
		)
	{
		return
			abi.decode(
				preview,
				(
					uint64,
					uint64,
					uint64,
					address,
					address,
					address,
					bytes,
					bytes,
					uint64[],
					string[]
				)
			);
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

	function tryGetValue(string memory key) external view returns (uint256) {
		if (!registeredValues[key]) return 1;

		return values[key];
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";

contract InfinityMintWallet is Authentication {
	/// @notice the location of the main ERC721 contract this wallet was spawned from;
	address public erc721;
	/// @notice the main ERC721 contract this wallet is attached too
	uint64 public currentTokenId;
	/// @notice the value/balance of the current wallet
	uint256 private walletValue;

	/// @notice Fired when a deposit is made
	event Deposit(address indexed sender, uint256 amount, uint256 newTotal);
	/// @notice Fired with a withdraw is made
	event Withdraw(address indexed sender, uint256 amount, uint256 newTotal);

	/// @notice Creates new wallet contract, tokenId refers to the ERC721 contract this wallet was spawned from.
	/// @dev makes the owner field the owner of the contract not the deployer.
	/// @param tokenId the tokenId from the main ERC721 contract
	/// @param owner who this contract is owned by
	/// @param erc721Destinaton the main ERC721 contract
	constructor(
		uint64 tokenId,
		address owner,
		address erc721Destinaton
	) Authentication() {
		//this only refers to being allowed to deposit into the wallet
		currentTokenId = tokenId;
		erc721 = erc721Destinaton;
		walletValue = 0;
		//authentication stuff
		togglePrivilages(owner);
		transferOwnership(owner);
	}

	/// @notice Returns the balance of the wallet
	function getBalance() public view onlyApproved returns (uint256) {
		return walletValue;
	}

	/// @notice Allows anyone to deposit ERC20 into this wallet.
	function deposit() public payable onlyOnce {
		uint256 value = (msg.value);
		require(value >= 0);

		walletValue = walletValue + value;
		emit Deposit(msg.sender, value, walletValue);
	}

	/// @notice Allows you to withdraw
	function withdraw() public onlyOnce onlyApproved {
		//to stop re-entry attack
		uint256 balance = (walletValue);
		walletValue = 0;
		payable(deployer).transfer(balance);
		emit Withdraw(msg.sender, address(this).balance, walletValue);
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";

abstract contract StickerInterface is Authentication {
	function acceptRequest(address sender, uint64 index) public virtual;

	function addRequest(bytes memory packed) public payable virtual;

	function withdrawRequest(uint64 index) public virtual;

	function denyRequest(address sender, uint64 index) public virtual;

	function getStickers()
		external
		view
		virtual
		returns (uint64[] memory result);

	function getSticker(uint64 stickerId)
		external
		view
		virtual
		returns (bytes memory result);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintWallet.sol";
import "./StickerInterface.sol";

abstract contract Stickers is StickerInterface {
	address public erc721;
	uint64 public currentTokenId;
	uint256 public stickerPrice;
	uint64 public currentStickerId;

	InfinityMintWallet EASWallet;

	mapping(uint64 => bytes) internal stickers;
	mapping(address => bytes[]) internal requests;
	mapping(address => uint64[]) internal registeredOwners;
	address[] public openRequests;

	//events
	event EASRequestAccepted(
		uint64 stickerId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event EASRequestDenied(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event EASRequestWithdrew(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);
	event EASRequestAdded(
		uint64 requestId,
		address indexed sender,
		uint256 price,
		bytes packed
	);

	function setStickerPrice(uint256 price) public onlyApproved {
		stickerPrice = price;
	}

	function hasStickers(address addr) external view returns (bool) {
		return registeredOwners[addr].length != 0;
	}

	function deleteRequest(address sender, uint256 index) internal {
		//if this is the last request
		if (requests[sender].length - 1 <= 0) {
			requests[sender] = new bytes[](0);
			removeFromOpenRequests(sender);
			return;
		}

		//create new temp
		bytes[] memory temp = new bytes[](requests[sender].length - 1);
		//copy to memory so not accessing storage
		bytes[] memory copy = (requests[sender]);
		uint256 count = 0; //temps index
		//for length of copy
		for (uint256 i = 0; i < copy.length; i++)
			//if i !== the deleted index add it to the new temp array
			if (i != index) temp[count++] = copy[i];

		//overwrite
		requests[sender] = temp;

		//remove this request
		if (requests[sender].length == 0) removeFromOpenRequests(sender);
	}

	function getMyRequest(uint64 index)
		external
		view
		returns (bytes memory result)
	{
		require(index < requests[msg.sender].length, "out of bounds");
		return requests[msg.sender][index];
	}

	function getMyRequests() external view returns (bytes[] memory result) {
		return requests[msg.sender];
	}

	function getUserStickers(address addr)
		external
		view
		returns (uint64[] memory)
	{
		return registeredOwners[addr];
	}

	function getSticker(uint64 stickerId)
		external
		view
		override
		returns (bytes memory result)
	{
		require(stickers[stickerId].length != 0);
		return stickers[stickerId];
	}

	function getRequest(address owner, uint64 index)
		external
		view
		onlyApproved
		returns (bytes memory result)
	{
		require(requests[owner][index].length != 0);
		return requests[owner][index];
	}

	function getStickers()
		external
		view
		override
		returns (uint64[] memory result)
	{
		uint64 count = 0;
		for (uint64 i = 0; i < currentStickerId; i++)
			if (stickers[i].length != 0) count++;

		if (count != 0) {
			//ceate new array with the size of count
			result = new uint64[](count);
			count = 0; //reset count
			for (uint64 i = 0; i < currentStickerId; i++)
				if (stickers[i].length != 0) result[count++] = i;
		}
	}

	function getRequestsByUser(address sender)
		external
		view
		returns (bytes[] memory)
	{
		return requests[sender];
	}

	function getRequests()
		external
		view
		onlyApproved
		returns (bytes[] memory result)
	{
		uint256 count = 0;
		for (uint256 i = 0; i < openRequests.length; i++) {
			count += requests[openRequests[i]].length;
		}

		result = new bytes[](count);
		count = 0;
		for (uint256 i = 0; i < openRequests.length; i++) {
			for (uint256 x = 0; x < requests[openRequests[i]].length; x++) {
				result[count++] = requests[openRequests[i]][x];
			}
		}

		return result;
	}

	function removeFromOpenRequests(address addr) internal {
		if (openRequests.length - 1 == 0) {
			openRequests = new address[](0);
			return;
		}

		address[] memory temp = new address[](openRequests.length - 1);
		address[] memory copy = (openRequests);
		uint256 index = 0;
		for (uint256 i = 0; i < copy.length; i++) {
			if (copy[i] == addr) continue;
			temp[index++] = copy[i];
		}
		openRequests = temp;
	}

	function hasOpenRequests(address addr) internal view returns (bool) {
		for (uint256 i = 0; i < openRequests.length; i++) {
			if (openRequests[i] == addr) return true;
		}
		return false;
	}

	function isSafe(bytes memory _p) internal view returns (bool) {
		//will call exception if it is bad
		(uint64 tokenId, , , ) = InfinityMintUtil.unpackSticker(_p);
		return tokenId == currentTokenId;
	}

	function isRequestOwner(bytes memory _p, address addr)
		internal
		pure
		returns (bool)
	{
		(, address owner, , ) = abi.decode(
			_p,
			(uint256, address, bytes, uint64)
		);
		return owner == addr;
	}
}