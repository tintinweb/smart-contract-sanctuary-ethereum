//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./RandomNumber.sol";

abstract contract AssetInterface {
	function getColours(uint64 pathId, RandomNumber randomNumberController)
		public
		virtual
		returns (uint64[] memory result);

	function getObjectURI() public view virtual returns (string memory) {
		return "";
	}

	function getDefaultName() internal virtual returns (string memory);

	function addColour(uint64 pathId, uint64[] memory result) public virtual {
		revert("colours not implemented");
	}

	function getNextPath() external view virtual returns (uint64);

	function pickPath(
		uint64 currentTokenId,
		RandomNumber randomNumberController
	)
		public
		virtual
		returns (
			uint64,
			uint64[] memory,
			string[] memory,
			uint64[] memory,
			string memory
		);

	function setLastAssets(uint64[] memory assets) public virtual;

	function getNames(uint64 nameCount, RandomNumber randomNumberController)
		public
		virtual
		returns (string[] memory results);

	function getRandomAsset(uint64 pathId, RandomNumber randomNumberController)
		external
		virtual
		returns (uint64[] memory assetsId);

	function getMintData(
		uint64 pathId,
		uint64 tokenId,
		RandomNumber randomNumberController
	) public virtual returns (string memory);

	function addAsset(uint256 rarity) public virtual;

	function getNextName(RandomNumber randomNumberController)
		internal
		virtual
		returns (string memory);

	function getPathGroup(uint64 pathId)
		public
		view
		virtual
		returns (bytes memory, uint64);

	function setNextPathId(uint64 pathId) public virtual;

	function getPathSize(uint64 pathId) public view virtual returns (uint64);

	function getNextPathId(RandomNumber randomNumberController)
		public
		virtual
		returns (uint64);
}

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

//
import "./ERC721.sol";
import "./InfinityMintStorage.sol";
import "./Royalty.sol";
import "./Authentication.sol";
import "./MinterInterface.sol";
import "./InfinityMintObject.sol";

/// @title InfinityMint ERC721 Implementation
/// @author Llydia Cross
/// @notice
/// @dev
contract InfinityMint is ERC721, Authentication, InfinityMintObject {
	/// @notice Interface set to the location of the storage controller, is set in constructor and cannot be modified.
	InfinityMintStorage private storageController;

	/// @notice Interface set to the location of the random number machine which controls how  picks random numbers and primes, is set in constructor and can be modified through setDestinations
	RandomNumber private randomNumberController;

	/// @notice Interface set to the location of the minter controller which controls how InfinityMint mints, is set in constructor and can be modified through setDestinations
	MinterInterface private minterController;

	/// @notice Interface set to the location of the values controller responsible for managing global variables across the smart contract syste,, is set in constructor and cannot be modified.
	InfinityMintValues public valuesController;

	/// @notice Interface set to the location of the royalty controller which controls how  picks random numbers and primes, is set in constructor and can be modified through setDestinations
	Royalty public royaltyController;

	/// @dev will be changed to TokenMinted soon
	event KazooMinted(
		uint64 tokenId,
		bytes encodedData,
		address indexed sender
	);

	/// @dev will be changed to TokenPreviewMinted soon
	event KazooPreviewMinted(
		uint64 tokenId,
		bytes encodedData,
		address indexed sender
	);

	/// @dev will be changed to TokenPreviewComplete soon
	event KazooPreviewComplete(address indexed sender, bytes[] encodedPreviews);

	/// @notice numerical increment of the current tokenId
	uint64 public currentTokenId;

	/// @notice will disallow mints if set to true
	bool public mintsEnabled;

	//sticker factory location
	address public factoryDestination;

	/// @notice a list of locked tokens, can be accessed publically by using tokenId as the index. true will mean the token is locked. False it is not.
	mapping(uint256 => bool) public locked;

	/// @notice InfinityMint Constructor takes tokenName and tokenSymbol and the various destinations of controller contracts
	constructor(
		string memory tokenName,
		string memory tokenSymbol,
		address storageContract,
		address randomNumberContract,
		address valuesContract,
		address minterContract,
		address royaltyContract
	) ERC721(tokenName, tokenSymbol) {
		//storage controller cannot be rewired
		storageController = InfinityMintStorage(storageContract); //address of the storage controlller
		//values controller cannot be rewired
		valuesController = InfinityMintValues(valuesContract);
		//
		setDestinations(randomNumberContract, minterContract, royaltyContract);
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
	 * /// @notice this is used by opensea/polyscan to detect our ERC721
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override
		returns (bool)
	{
		if (valuesController.isTrue("hideMint")) return false;
		return
			interfaceId == type(IERC721).interfaceId ||
			interfaceId == type(IERC721Metadata).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	///@notice Sets the destinations of the random number contract, minter contract and royalty contract
	///@dev Contracts must inherit the the same interfaces this contract has been built with, so version 1 Omega stuff.
	function setDestinations(
		address randomNumberContract,
		address minterContract,
		address royaltyContract
	) public onlyDeployer {
		require(sender() == deployer, "not the deployer");
		require(randomNumberContract != address(0x0));
		require(minterContract != address(0x0));
		require(royaltyContract != address(0x0));

		randomNumberController = RandomNumber(randomNumberContract); //addess of the random number controller
		minterController = MinterInterface(minterContract);
		royaltyController = Royalty(royaltyContract);
	}

	/// @notice returns true if the deployer has set the location of the factory contract
	/// @dev the factory contract is reponsible for creating ERC721 Ethereum Ad Service sticker contracts and also wallet contracts that can accept ERC721, by setting factory destination it allows you to do put the contracts up through this contract.
	function hasFactory() public view returns (bool) {
		return
			factoryDestination != address(0x0) &&
			isContract(factoryDestination);
	}

	/// @notice Sets the location of the factory contract that is reponsible for deploying Ethereum Ad Service + Wallet contrats
	/// @dev
	function setFactory(address newFactoryDestination) public {
		require(
			newFactoryDestination != address(0x0) &&
				isContract(newFactoryDestination),
			"is not a valid factory destination"
		);

		factoryDestination = newFactoryDestination;
	}

	/// @notice Deploys an Ethereum Ad Service sticker contract which mints ERC721 sticker tokens
	/// @dev THIS METHOD DEPLOYS A CONTRACT! This method takes about 4,000,000 gas.
	/// @param tokenId the tokenId to deploy the sticker contract on.
	function deployStickerContract(uint256 tokenId) public {
		require(hasFactory(), "no factory set");

		address sender = (msg.sender);

		require(isApprovedOrOwner(sender, tokenId), "is not approved or owner");
		ReturnObject memory temp = storageController.get(uint64(tokenId));

		require(temp.wallet != address(0x0), "deploy wallet contract first");
		require(
			temp.stickers == address(0x0),
			"sticker contract already deployed"
		);

		(bool success, bytes memory returnData) = address(factoryDestination)
			.call{ value: 0 }(
			abi.encodeWithSignature(
				"unsafeDeployContract(uint64,address,bool)",
				tokenId,
				sender,
				true
			)
		);

		if (!success) {
			if (returnData.length == 0) revert("deploy call reverted");
			else
				assembly {
					let returndata_size := mload(returnData)
					revert(add(32, returnData), returndata_size)
				}
		}
	}

	/// @notice Deploys a wallet contract on a token, a wallet contract can hold ERC 20 tokens and holds the profits of the sticker contract
	/// @dev the wallet contract is attached to the sticker contract as well as the NFT, when you transfer the NFT the sticker contract remains attached.
	/// @param tokenId the tokenId to deploy this wallet contract on.
	function deployWalletContract(uint256 tokenId) public {
		require(hasFactory(), "no factory set");

		address sender = (msg.sender);
		require(isApprovedOrOwner(sender, tokenId));

		ReturnObject memory temp = storageController.get(uint64(tokenId));
		require(
			temp.wallet == address(0x0),
			"wallet contract already deployed"
		);

		(bool success, bytes memory returnData) = address(factoryDestination)
			.call{ value: 0 }(
			abi.encodeWithSignature(
				"unsafeDeployContract(uint64,address,bool)",
				tokenId,
				sender,
				false
			)
		);

		if (!success) {
			if (returnData.length == 0) revert("call reverted");
			else
				assembly {
					let returndata_size := mload(returnData)
					revert(add(32, returnData), returndata_size)
				}
		}
	}

	/// @notice the total supply of tokens
	/// @dev Returns the max supply of tokens, not the amount that have been minted. (so the tokenId)
	function totalSupply() public view returns (uint256) {
		return valuesController.tryGetValue("maxSupply");
	}

	/// @notice Toggles mints allowing people to either mint or not mint tokens.
	function toggleMints() public onlyDeployer {
		mintsEnabled = !mintsEnabled;
	}

	/// @notice Returns a selection of preview mints, these are ghost NFTs which can be chosen from. Their generation values are based off of eachover due to the nature of the number system.
	/// @dev This method is the most gas intensive method in InfinityMint, how ever there is a trade off in the fact that that MintPreview is insanely cheap and does not need a lot of gas. I suggest using low previewCount values of about 2 or 3. Anything higher is dependant in your project configuartion and how much you care about gas prices.
	function getPreview() public {
		mintCheck(0, false); //does not check the price

		//if the user has already had their daily preview mints
		if (
			storageController.isPreviewBlocked(sender()) ||
			valuesController.tryGetValue("previewCount") <= 0
		) revert("Preview Blocked");

		InfinityMintObject.ReturnObject[] memory previews = minterController
			.getPreview(currentTokenId, sender());

		bytes[] memory temp = new bytes[](previews.length);
		for (uint256 i = 0; i < previews.length; i++) {
			temp[i] = encode(previews[i]);
		}

		//set the sender to be preview blocked for a while
		storageController.setPreviews(sender(), previews);

		//once done, emit an event
		emit KazooPreviewComplete(sender(), temp);
	}

	/// @notice Mints a preview. Index is relative to the sender and is the index of the preview in the users preview list
	/// @dev This will wipe other previews once called.
	/// @param index the index of the preview to mint
	function mintPreview(uint64 index) public payable onlyOnce {
		uint256 value = (msg.value);
		mintCheck(value, !approved[sender()]); //will not check the price for approved members

		completeMint(
			minterController.mintPreview(index, currentTokenId, sender()),
			sender(),
			true,
			value
		);
	}

	/// @notice Allows approved or the deployer to pick exactly what token they would like to mint. Does not check if assets/colours/mintData is valid. Implicitly assets what ever.
	/// @dev This is the cheapest way to get InfinityMint to mint something as it literally decides no values on chain. This method can also be called by a rollup solution or something or be used as a way to literally mint anything.
	/// @param pathId the pathid you want to mint
	/// @param pathSize the size of this path (for colour generation)
	/// @param colours the colours of this token
	/// @param assets the assets for this token
	function implicitMint(
		uint64 pathId,
		uint64 pathSize,
		uint64[] memory colours,
		string memory mintData,
		uint64[] memory assets
	) public onlyApproved {
		if (!mintsEnabled) revert();

		royaltyController.registerFreeMint();

		completeMint(
			minterController.implicitMint(
				currentTokenId,
				pathId,
				pathSize,
				colours,
				mintData,
				sender(),
				assets
			),
			sender(),
			false,
			0
		);
	}

	/// @notice Returns the current price of a mint.
	/// @dev the royalty controller actually controls the token price so in order to change it you must send tx to that contract.
	function tokenPrice() public view returns (uint256) {
		return royaltyController.tokenPrice();
	}

	/// @notice Allows the owner to lock their token from being able to be transfered. Must be called with a public key only the toekn owner can see.
	/// @dev The public key and private key for the token owner is trashed after this method is called, you will need to call getPublicKey within two minutes of calling this method and present it to the end user.
	/// @param tokenId the token to lock
	/// @param position a bool stating if it is locked or not
	/// @param key the public key which is checked and allows the token owner to unlock/lock their token.
	function setTokenLockable(
		uint256 tokenId,
		bool position,
		bytes memory key
	) public {
		require(
			isApprovedOrOwner(sender(), tokenId),
			"is not Owner, approved or approved for all"
		);

		//unpack the key
		(, uint256[] memory maybeKey) = abi.decode(key, (address, uint256[]));
		uint256[] memory publicKey = storageController.getKey(sender(), 1);
		uint256[] memory privateKey = storageController.getKey(sender(), 0);

		//verify key
		for (uint256 i = 0; i < maybeKey.length; i++) {
			//check that the actual pub key and the maybe pub key are the same
			require(publicKey[i] == maybeKey[i], "bad key");

			uint256 maybePrime = maybeKey[i];

			//find prime factor
			while (privateKey[i] != maybePrime) {
				//if we get to less than or equal 2 it is a bad prime
				if (maybePrime <= 2) revert("bad key");
				//keep square rooting until we find the prime number
				maybePrime = randomNumberController.sqrt(maybePrime);
			}
		}

		locked[tokenId] = position;
		storageController.newKey(
			sender(),
			randomNumberController.getMaxNumber(3),
			randomNumberController.getRandomPrimes(8)
		); //see newKey comments inside of InfinityMintStorage.sol, but we must call getPublicKey() which is an InfinityMintApi method from the senders context to get their public key. This does not emit/return else
		//that would expose the public key on etherscan. You need to call getPublicKey() on the senders end through the DAPP within two minutes else the key
		//cannot be read on chain anymore for security reasons..
	}

	/// @notice Destroys a lock key associated with a token
	/// @dev call getPublicKey within two minutes of calling this else you wont be able to get the new unlock token
	function deleteKey() public {
		storageController.destroyKey(
			sender(),
			randomNumberController.getMaxNumber(3),
			randomNumberController.getRandomPrimes(8)
		);
	}

	/// @notice Allows a user other than a approved/deployer to decide which pathId they would like, assets will still be randomised for that path group.
	/// @dev when refering to path group, we are refering to the paths object inside of your infinityMint project, when the project is deployed these paths are put on the chain. This method allows the user to pick what path they want, instead of randomising it like normal.
	/// @param pathId the path id the user would like to mint
	function selectiveMint(uint64 pathId) public payable onlyOnce {
		uint256 value = (msg.value);
		//check if mint is valid
		mintCheck(value, !approved[sender()]);

		if (!valuesController.isTrue("selectiveMode")) revert();

		completeMint(
			minterController.selectiveMint(currentTokenId, pathId, sender()),
			sender(),
			false,
			value
		);
	}

	/// @notice Mints a new ERC721 InfinityMint Token
	/// @dev Takes no arguments. You dont have to pay for the mint if you are approved (or the deployer)
	function mint() public payable onlyOnce {
		//save the msg.value value
		uint256 value = (msg.value);
		//check if mint is valid
		mintCheck(value, !approved[sender()]);
		completeMint(
			minterController.mint(currentTokenId, sender()),
			sender(),
			false,
			value
		);
	}

	/// @notice Allows you to withdraw your earnings from the contract.
	/// @dev The totals that the sender can withdraw is managed by the royalty controller
	function withdraw() public onlyOnce {
		if (royaltyController.values(sender()) == 0) revert();

		if (address(this).balance - royaltyController.values(sender()) < 0)
			revert("Cannot afford to withdraw");

		uint256 value = royaltyController.withdraw(sender()); //will revert if bad, results in the value to be deposited. Has Re-entry protection.
		if (value <= 0) revert("Invalid or Empty value");
		payable(sender()).transfer(value);
	}

	/// @notice this can only be called by sticker contracts and is used to pay back the contract owner their sticker cut
	/// @dev the amount that is paid into this function is defined by the sticker price set by the token owner. The royalty controller cuts up the deposited tokens even more depending on if there are any splits.
	function depositStickerRoyalty(uint64 tokenId) public payable onlyOnce {
		address sticker = storageController.get(tokenId).stickers;
		uint256 size;
		assembly {
			size := extcodesize(sticker)
		}
		require(size <= 0, "is not a contract");

		//if the sender isn't the sticker contract attached to this token
		if (sender() != sticker)
			revert(
				"Sender is not the sticker contract associated with this token"
			);

		//increment
		royaltyController.incrementBalance(
			msg.value,
			royaltyController.STICKER_TYPE()
		);

		//dont revert allow deposit
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

	/// @dev internal method that actually invokes the transfer and updates storage
	/// @param from the adress it will be transfered from
	/// @param to the adress the token will be transfered too
	function _transfer(
		address from,
		address to,
		uint64 tokenId,
		bytes memory data
	) internal {
		require(
			isApprovedOrOwner(sender(), tokenId),
			"is not Owner, approved or approved for all"
		);
		require(
			locked[tokenId] != true,
			"This token is locked and needs to be unlocked before it can be transfered"
		);
		storageController.transfer(to, tokenId);
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

	/// @notice sets the token URI
	/// @dev you need to call this from an approved address for the token
	/// @param tokenId the tokenId
	/// @param json an IFPS link or a
	function setTokenURI(uint64 tokenId, string memory json) public {
		require(
			isApprovedOrOwner(sender(), tokenId),
			"is not Owner, approved or approved for all"
		);
		uri[tokenId] = json;
	}

	/// @notice Mints a token and stores its data inside of the storage contract, increments royalty totals and emits event.
	/// @dev This is called after preview mint, implicit mint and normal mints to finish up the transaction. We also wipe previous previews the address might have secretly inside the storageController.set method.
	/// @param data the InfinityMint token data,
	/// @param addr the sender or what should be tx.origin address
	/// @param isPreviewMint is true if the mint was from a preview
	/// @param msgValue the value of the msg
	function completeMint(
		InfinityMintObject.ReturnObject memory data,
		address addr,
		bool isPreviewMint,
		uint256 msgValue
	) private {
		//store it, also registers it for look up + deletes previous previews
		storageController.set(currentTokenId, data);
		//mint it
		ERC721.mint(addr, currentTokenId, bytes(data.mintData));

		//increment royalty balance if we are not approved
		if (!approved[addr])
			royaltyController.incrementBalance(
				msgValue,
				royaltyController.MINT_TYPE()
			);
		else royaltyController.registerFreeMint(); //literally just for the deployer, register as a free mint, this allows the deployer to pay into this contract

		//if the user doesn't have an unlock key, make
		if (!storageController.hasKey(addr))
			storageController.newKey(
				addr,
				randomNumberController.getMaxNumber(3),
				randomNumberController.getRandomPrimes(8)
			);

		if (isPreviewMint)
			//if true then its a preview mint
			emit KazooPreviewMinted(currentTokenId++, encode(data), addr);
		else emit KazooMinted(currentTokenId++, encode(data), addr);
	}

	/// @notice checks the transaction to see if it is valid
	/// @dev checks if the price is the current token price and if mints are disabled and if the maxSupply hasnt been met
	/// @param msgValue the value of the current message
	/// @param checkPrice if we should check the current price
	function mintCheck(uint256 msgValue, bool checkPrice) private view {
		if (checkPrice && msgValue != royaltyController.tokenPrice())
			revert("Price is invalid");
		if (!mintsEnabled) revert("Mints are disabled");
		if (currentTokenId == valuesController.tryGetValue("maxSupply"))
			revert("Maximum amount of tokens minted");
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMint.sol";
import "./AssetInterface.sol";
import "./StickerInterface.sol";
import "./InfinityMintValues.sol";
import "./Royalty.sol";

contract InfinityMintApi is InfinityMintObject {
	InfinityMint mainContract;
	InfinityMintStorage storageContract;
	AssetInterface assetContract;
	InfinityMintValues valueContract;
	Royalty royaltyContract;

	constructor(
		address erc721,
		address storageController,
		address assetController,
		address valueController,
		address royaltyController
	) {
		mainContract = InfinityMint(erc721);
		storageContract = InfinityMintStorage(storageController);
		assetContract = AssetInterface(assetController);
		valueContract = InfinityMintValues(valueController);
		royaltyContract = Royalty(royaltyController);
	}

	function kazooPrice() external view returns (uint256) {
		return royaltyContract.tokenPrice();
	}

	function previewTimeout() external view returns (uint256) {
		return valueContract.tryGetValue("previewTimeout");
	}

	function ownerOf(uint64 tokenId) external view returns (address result) {
		result = storageContract.getOwner(tokenId);

		if (result == address(0x0)) revert();
	}

	function getStickers(address stickerContract)
		external
		view
		returns (uint64[] memory)
	{
		if (stickerContract == address(0x0)) return new uint64[](0);

		StickerInterface sticker = StickerInterface(stickerContract);
		return sticker.getStickers();
	}

	function getObjectURI() external view returns (string memory) {
		return assetContract.getObjectURI();
	}

	function isPreviewBlocked(address sender) external view returns (bool) {
		return storageContract.isPreviewBlocked(sender);
	}

	function allKazooPaged(
		uint64 page,
		uint64 selectionCount,
		address owner
	) external view returns (uint64[] memory tokens) {
		require(selectionCount < 1000, "to big of a selection");

		uint256 startIndex = page * selectionCount;
		uint256 endIndex = startIndex + selectionCount;

		if (startIndex < storageContract.getCount(owner) && startIndex > 0)
			return tokens;

		if (endIndex >= storageContract.getCount(owner))
			endIndex = storageContract.getCount(owner) - 1;

		uint256 count = 0;
		for (uint256 i = 0; i < selectionCount; i++) {
			uint256 actualIndex;
			if (i != 0) actualIndex = startIndex + i;

			if (actualIndex < storageContract.getCount(owner)) count++;
		}

		tokens = new uint64[](count);
		count = 0;
		for (uint256 i = 0; i < selectionCount; i++) {
			uint256 actualIndex;
			if (i != 0) actualIndex = startIndex + i;

			if (actualIndex < storageContract.getCount(owner))
				tokens[count++] = uint64(actualIndex);
		}
	}

	function allKazoos(address owner)
		public
		view
		returns (uint64[] memory tokens)
	{
		return storageContract.getAll(owner);
	}

	function getRaw(uint64 tokenId) external view returns (bytes memory) {
		if (tokenId < 0 || tokenId >= mainContract.currentTokenId()) revert();

		ReturnObject memory data = storageContract.get(tokenId);

		return encode(data);
	}

	function getPath(uint64 pathId) external view returns (bytes memory path) {
		(path, ) = assetContract.getPathGroup(pathId);
	}

	function getCount() external view returns (uint256) {
		return mainContract.balanceOf(sender());
	}

	function getPublicKey() external view returns (bytes memory) {
		require(storageContract.hasKey(sender()), "sender does not have a key");

		uint256[] memory temp = storageContract.getKey(sender(), 2);
		require(
			temp.length > 0 && block.timestamp < temp[0],
			"key has passed its view window"
		);

		return
			abi.encode(
				sender(),
				temp[0],
				uint256(block.timestamp),
				storageContract.getKey(sender(), 1)
			);
	}

	function get(uint64 tokenId) external view returns (ReturnObject memory) {
		return storageContract.get(tokenId);
	}

	function getWalletContract(uint64 tokenId)
		public
		view
		returns (address result)
	{
		return storageContract.get(tokenId).wallet;
	}

	function getStickerContract(uint64 tokenId)
		public
		view
		returns (address result)
	{
		return storageContract.get(tokenId).wallet;
	}

	function allPreviews(address addr) external view returns (uint64[] memory) {
		InfinityMintObject.ReturnObject[] memory previews = storageContract
			.getPreview(addr);

		uint64[] memory rPreviews = new uint64[](previews.length);
		for (uint256 i = 0; i < previews.length; i++) rPreviews[i] = uint64(i);
		return rPreviews;
	}

	function getPreview(uint64 index)
		public
		view
		returns (ReturnObject memory)
	{
		InfinityMintObject.ReturnObject[] memory previews = storageContract
			.getPreview(sender());

		if (index >= previews.length || index < 0) revert("bad preview index");

		return previews[index];
	}

	function isEnabled() external view returns (bool) {
		return mainContract.mintsEnabled();
	}

	function isReady() external view returns (bool) {
		return mainContract.mintsEnabled();
	}

	function totalMints() external view returns (uint64) {
		return mainContract.currentTokenId();
	}

	function originalPrice() external view returns (uint256) {
		return royaltyContract.originalTokenPrice();
	}

	//the total amount of tokens
	function totalSupply() external view returns (uint256) {
		return valueContract.tryGetValue("maxSupply");
	}

	function maxKazoos() external view returns (uint256) {
		return valueContract.tryGetValue("maxSupply");
	}

	function lastPrice() external view returns (uint256) {
		return royaltyContract.lastTokenPrice();
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

import "./InfinityMintObject.sol";
import "./Authentication.sol";

/// @title InfinityMint storage controller
/// @author Llydia Cross
/// @notice Stores the outcomes of the mint process and previews and also unlock keys
/// @dev Attached to to an InfinityMint
contract InfinityMintStorage is Authentication, InfinityMintObject {
	/// @notice previews
	mapping(address => bytes[]) public previews;

	/// @notice all of the token data
	mapping(uint64 => ReturnObject) private tokens;

	/// @notice private mapping holding a list of tokens for owned by the address for quick look up
	mapping(address => uint64[]) private registeredTokens;

	/// @notice private mapping of the private keys associated with each token owner.
	mapping(address => mapping(uint256 => uint256[])) private keys;

	/// @notice returns true if the address is preview blocked and unable to receive more previews
	function isPreviewBlocked(address addr) public view returns (bool) {
		return previews[addr].length != 0;
	}

	/// @notice makes a new key pair for locking/unlocking tokens
	/// @dev keys are prime number based, first get get a random selection of primes and then square root them a random amount of times to generate the public key
	/// @param addr the address to generate a new key pair for
	function newKey(
		address addr,
		uint256 powerOf,
		uint256[] memory primes
	) public onlyApproved {
		//add private primes to the key storage
		keys[addr][0] = primes;

		//add to the keys storage
		keys[addr][1] = getNewPubKey(primes.length, primes, powerOf);

		uint256[] memory temp = new uint256[](1);
		temp[0] = uint256(block.timestamp) + (60 * 2); //dont allow get after 2 minutes

		//add it to the keys storage
		keys[addr][2] = temp;
	}

	/// @notice returns true if the address has a private key setup
	/// @dev Can only be called by approved addresses to the storage
	/// @param addr the address to get the key for
	/// @param index the part of the key, 0 = private key, 1 = public key, 2 = withholdAfter
	function getKey(address addr, uint256 index)
		external
		view
		onlyApproved
		returns (uint256[] memory)
	{
		return keys[addr][index];
	}

	/// @notice returns true if the address has a private key setup
	/// @dev Can only be called by approved addresses to the storage
	/// @param addr the address to check has a key
	function hasKey(address addr) external view onlyApproved returns (bool) {
		return keys[addr][0].length != 0;
	}

	/// @notice Destroys a unlock/lock key associated with the senders address
	/// @dev will kick off the withholdAfter timezone you can view the token, so be sure to have the user call getPublicKey right after calling this, this is put inside of keys[addr][2]
	/// @param addr the address to destroy the key of
	/// @param powerOf the amount of times to power the primes
	/// @param primes the list of primes
	function destroyKey(
		address addr,
		uint256 powerOf,
		uint256[] memory primes
	) public onlyApproved {
		require(keys[addr][0].length != 0, "has no private key");
		newKey(addr, powerOf, primes);
	}

	/// @notice returns address of the owner of this token
	/// @param tokenId the tokenId to get the owner of
	function getOwner(uint64 tokenId) public view returns (address) {
		return tokens[tokenId].owner;
	}

	/// @notice returns an integer array containing the token ids owned by the owner address
	/// @param owner the owner to look for
	function getAll(address owner) public view returns (uint64[] memory) {
		return registeredTokens[owner];
	}

	/// @notice pushes the tokenId to the registeredTokens array for the given address
	/// @param owner the owner to add the token too
	/// @param tokenId the tokenId to add
	function addToRegisteredTokens(address owner, uint64 tokenId)
		public
		onlyApproved
	{
		registeredTokens[owner].push(tokenId);
	}

	/// @notice gets a token at by the owner at a specific index (relative to their tokens
	/// @dev Tokens are indexable instead by their current positon inside of the owner wallets collection, returns a tokenId
	/// @param owner the owner to look up
	/// @param index the index to fetch
	function getAtIndex(address owner, uint256 index)
		public
		view
		returns (uint64 tokenId)
	{
		require(registeredTokens[owner].length < index, "out of bounds");
		return registeredTokens[owner][index];
	}

	/// @notice Gets the amount of tokens the owner has, same as balanceOf on main ERC721
	/// @dev Tokens are indexable instead by their current positon inside of the owner wallets collection, returns a tokenId
	/// @param owner the owner to get the length of
	function getCount(address owner) public view returns (uint256) {
		return registeredTokens[owner].length;
	}

	/// @notice returns a token
	/// @dev returns a struct not bytes, use getEncoded to return bytes instead.
	/// @param tokenId the tokenId to get
	function get(uint64 tokenId) public view returns (ReturnObject memory) {
		if (tokens[tokenId].owner == address(0x0)) revert();

		return tokens[tokenId];
	}

	/// @notice returns a token
	/// @dev returns bytes not a struct, use get to get a struct instead
	/// @param tokenId the tokenId to get
	function getEncoded(uint64 tokenId) public view returns (bytes memory) {
		if (tokens[tokenId].owner == address(0x0)) revert();

		return encode(tokens[tokenId]);
	}

	function transfer(address to, uint64 tokenId) public onlyApproved {
		ReturnObject memory temp = get(tokenId);
		address oldOwner = (temp.owner);

		//change the struct to equal to the new address holder
		set(
			tokenId,
			ReturnObject(
				temp.pathId,
				temp.pathSize,
				temp.currentTokenId,
				to,
				temp.wallet,
				temp.stickers,
				temp.colours,
				temp.mintData,
				temp.assets,
				temp.names
			)
		);

		//delete from the old owners registerTokens array
		deleteInArray(oldOwner, tokenId);
		registeredTokens[to].push(tokenId); //register the new owner
	}

	function set(uint64 tokenId, ReturnObject memory data) public onlyApproved {
		require(data.owner != address(0x0), "null owner");

		//if its a new token set
		if (tokens[tokenId].owner == address(0x0)) {
			addToRegisteredTokens(data.owner, tokenId);
			//delete previews for the address
			deletePreview(data.owner);
		}

		tokens[tokenId] = data;
	}

	function setRaw(uint64 tokenId, bytes memory _data) public onlyApproved {
		set(tokenId, abi.decode(_data, (ReturnObject)));
	}

	function setPreviews(address owner, ReturnObject[] memory data)
		public
		onlyApproved
	{
		bytes[] memory temp = new bytes[](data.length);
		for (uint256 i = 0; i < temp.length; i++) temp[i] = abi.encode(data[i]);

		previews[owner] = temp;
	}

	function getPreview(address owner)
		public
		view
		onlyApproved
		returns (ReturnObject[] memory)
	{
		require(previews[owner].length != 0);
		ReturnObject[] memory temp = new ReturnObject[](previews[owner].length);
		for (uint256 i = 0; i < previews[owner].length; i++)
			temp[i] = abi.decode(previews[owner][i], (ReturnObject));

		return temp;
	}

	function deletePreview(address owner) public onlyApproved {
		delete previews[owner];
	}

	function existsInArray(address sender, uint64 tokenId)
		private
		view
		returns (bool)
	{
		if (registeredTokens[sender].length == 0) return false;

		for (uint256 i = 0; i < registeredTokens[sender].length; i++) {
			if (registeredTokens[sender][i] == tokenId) return true;
		}

		return false;
	}

	function deleteInArray(address sender, uint64 tokenId) private {
		if (registeredTokens[sender].length - 1 <= 0)
			delete registeredTokens[sender];

		uint64 index = 0;
		uint64[] memory newArray = new uint64[](
			registeredTokens[sender].length - 1
		);

		for (uint256 i = 0; i < registeredTokens[sender].length; i++) {
			if (registeredTokens[sender][i] == tokenId) continue;

			newArray[index++] = registeredTokens[sender][i];
		}

		registeredTokens[sender] = newArray;
	}

	/// @notice Returns a new public key.
	/// @dev See newKey inside this same contract for a more detailed description.
	/// @param length the length of the new key to make.
	/// @param privateKey the private key for this user
	/// @param powerOf amount of times to square the prime
	function getNewPubKey(
		uint256 length,
		uint256[] memory privateKey,
		uint256 powerOf
	) private pure returns (uint256[] memory _newKey) {
		_newKey = new uint256[](length);
		if (powerOf <= 0) powerOf = 2;

		for (uint256 i = 0; i < _newKey.length; i++) {
			_newKey[i] = InfinityMintUtil.square(privateKey[i], powerOf);
		}
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
import "./InfinityMintStorage.sol";
import "./AssetInterface.sol";
import "./RandomNumber.sol";
import "./InfinityMintObject.sol";

abstract contract MinterInterface is Authentication {
	InfinityMintValues valuesController;
	InfinityMintStorage storageController;
	AssetInterface assetController;
	RandomNumber randomNumberController;

	/*
	 */
	constructor(
		address valuesContract,
		address storageContract,
		address assetContract,
		address randomNumberContract
	) {
		valuesController = InfinityMintValues(valuesContract);
		storageController = InfinityMintStorage(storageContract);
		assetController = AssetInterface(assetContract);
		randomNumberController = RandomNumber(randomNumberContract);
	}

	function mint(uint64 currentTokenId, address sender)
		public
		virtual
		returns (InfinityMintObject.ReturnObject memory);

	/**
		Fast Mint used in mintAll
	 */
	function implicitMint(
		uint64 currentTokenId,
		uint64 pathId,
		uint64 pathSize,
		uint64[] memory colours,
		string memory mintData,
		address sender,
		uint64[] memory assets
	) external virtual returns (InfinityMintObject.ReturnObject memory);

	/**

     */
	function getPreview(uint64 currentTokenId, address sender)
		external
		virtual
		returns (InfinityMintObject.ReturnObject[] memory);

	function selectiveMint(
		uint64 currentTokenId,
		uint64 pathId,
		address sender
	) external virtual returns (InfinityMintObject.ReturnObject memory);

	/*

    */
	function mintPreview(
		uint64 index,
		uint64 currentTokenId,
		address sender
	) external virtual returns (InfinityMintObject.ReturnObject memory);
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMintValues.sol";

abstract contract RandomNumber {
	uint256 public randomnessFactor;
	bool public hasDeployed = false;
	uint256 public salt = 1;

	InfinityMintValues valuesController;

	modifier hasNotSetup() {
		if (hasDeployed) revert();
		_;
		hasDeployed = true;
	}

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);
		randomnessFactor = valuesController.getValue("randomessFactor");
	}

	function getNumber() external returns (uint256) {
		if (salt + 1 > 2147483647) salt = 0;

		return
			returnNumber(valuesController.getValue("maxRandomNumber"), salt++);
	}

	function getMaxNumber(uint256 maxNumber) external returns (uint256) {
		if (salt + 1 > 2147483647) salt = 0;

		return returnNumber(maxNumber, salt++);
	}

	function sqrt(uint256 x) external pure returns (uint256 y) {
		uint256 z = (x + 1) / 2;
		y = x;
		while (z < y) {
			y = z;
			z = (x / z + z) / 2;
		}
	}

	function getRandomPrimes(uint256 _count)
		external
		virtual
		returns (uint256[] memory);

	//called upon main deployment of the main kazooKid contract, can only be called once!
	function setup(
		address infinityMint,
		address infinityMintStorage,
		address infinityMintAsset
	) public virtual hasNotSetup {}

	function returnNumber(uint256 maxNumber, uint256 _salt)
		public
		view
		virtual
		returns (uint256)
	{
		if (maxNumber <= 0) maxNumber = 1;

		return (_salt + 3) % maxNumber;
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./Authentication.sol";

abstract contract Royalty is Authentication {
	//globals
	InfinityMintValues public valuesController;

	//payout values
	mapping(address => uint256) public values;

	uint256 public tokenPrice;
	uint256 public originalTokenPrice;
	uint256 public lastTokenPrice;
	uint256 public freeMints;
	uint256 public freeSticker;
	uint256 public stickerSplit;

	uint256 public constant MINT_TYPE = 0;
	uint256 public constant STICKER_TYPE = 1;

	event Withdraw(address indexed sender, uint256 amount, uint256 newTotal);

	constructor(address valuesContract) {
		valuesController = InfinityMintValues(valuesContract);

		tokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");
		lastTokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");
		originalTokenPrice =
			valuesController.tryGetValue("startingPrice") *
			valuesController.tryGetValue("baseTokenValue");

		if (valuesController.tryGetValue("stickerSplit") > 100) revert();
		stickerSplit = valuesController.tryGetValue("stickerSplit");
	}

	function changePrice(uint256 _tokenPrice) public onlyDeployer {
		if (_tokenPrice < originalTokenPrice) revert();

		lastTokenPrice = tokenPrice;
		tokenPrice = _tokenPrice;
	}

	function registerFreeMint() public onlyApproved {
		freeMints = freeMints + 1;
	}

	function registerFreeSticker() public onlyApproved {
		freeSticker = freeSticker + 1;
	}

	function withdraw(address addr)
		public
		onlyApproved
		onlyOnce
		returns (uint256 total)
	{
		if (values[addr] <= 0) revert("Invalid or Empty address");

		total = values[addr];
		values[addr] = 0;

		emit Withdraw(addr, total, values[addr]);
	}

	function incrementBalance(uint256 value, uint256 typeOfSplit)
		external
		virtual;
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

import "../InfinityMint.sol";
import "../InfinityMintApi.sol";
import "../IERC721.sol";

contract Marketplace is InfinityMintObject {
	address infinityMint;

	struct OfferObject {
		address sender;
		uint256 tokenId;
		uint256 value;
	}

	struct TransferObject {
		uint256 tokenId;
		address from;
		address to;
		uint256 value;
		bool hasTransfer;
	}

	uint256 internal executionCount;

	mapping(uint64 => mapping(address => OfferObject)) internal tokenOffers;
	mapping(uint64 => address[]) public userOffers;
	mapping(uint64 => TransferObject) internal transfers;

	event Offer(address indexed sender, uint64 tokenId, uint256 amount);
	event AwaitingTransfer(address indexed sender, TransferObject);
	event TransferConfirmed(
		address indexed sender,
		uint256 tokenId,
		address to,
		uint256 amount
	);

	modifier onlyOnce() {
		executionCount += 1;
		uint256 localCounter = executionCount;
		_;
		require(localCounter == executionCount);
	}

	constructor(address _infinityMint) {
		if (!isContract(_infinityMint)) revert("Must be NFT contract address");

		infinityMint = _infinityMint;
	}

	function getOffers(uint64 tokenId) public view returns (address[] memory) {
		return userOffers[tokenId];
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

	function getOffer(uint64 tokenId, address offerSender)
		public
		view
		returns (OfferObject memory)
	{
		return tokenOffers[tokenId][offerSender];
	}

	function awaitingTransfer(uint64 tokenId) public view returns (bool) {
		return (transfers[tokenId].to != address(0x0) &&
			transfers[tokenId].hasTransfer != true);
	}

	function awaitingTransferTo(uint64 tokenId) public view returns (address) {
		return transfers[tokenId].to;
	}

	function ownerOf(uint64 tokenId) public returns (address) {
		(bool success, bytes memory result) = address(infinityMint).call(
			abi.encodeWithSelector(IERC721.ownerOf.selector, uint256(tokenId))
		);

		if (!success) return address(0x0);

		return abi.decode(result, (address));
	}

	function makeOffer(uint64 tokenId) public payable virtual onlyOnce {
		require(!isContract(sender()), "Contracts are not allowed");
		require(msg.value >= 0, "value less than zero");
		require(ownerOf(tokenId) != address(0x0), "Invalid Token");
		require(
			ownerOf(tokenId) != sender(),
			"Cannot make offers on your own token"
		);
		require(
			tokenOffers[tokenId][sender()].sender == address(0x0),
			"You already have an offer open"
		);
		require(
			transfers[tokenId].to == address(0x0),
			"This token has already been sold and is waiting to be transfered"
		);

		tokenOffers[tokenId][sender()] = OfferObject(
			sender(),
			tokenId,
			msg.value
		);
		//add to user offers
		userOffers[tokenId].push(sender());

		emit Offer(sender(), tokenId, msg.value);
	}

	function revokeOffer(uint64 tokenId) public virtual onlyOnce {
		require(!isContract(sender()), "Contracts are not allowed");
		require(
			transfers[tokenId].to != sender(),
			"you cannot revoke at this time"
		);
		require(
			tokenOffers[tokenId][sender()].sender != address(0x0) &&
				tokenOffers[tokenId][sender()].sender == sender(),
			"No offer from this address or incorect sender"
		);

		//send back the monies
		payable(sender()).transfer(tokenOffers[tokenId][sender()].value);
		//delete the offer for the sender
		delete tokenOffers[tokenId][sender()];
		//update the user offers array
		deleteAddress(tokenId, sender());
	}

	function acceptOffer(uint64 tokenId, address offerSender) public virtual {
		require(
			transfers[tokenId].to == address(0x0),
			"This token has already been sold and is waiting to be transfered"
		);
		require(
			tokenOffers[tokenId][offerSender].sender != address(0x0),
			"No offer from this address"
		);
		require(ownerOf(tokenId) != address(0x0), "Invalid Token");
		require(
			ownerOf(tokenId) == sender(),
			"You are not the owner of this token"
		);

		transfers[tokenId] = TransferObject(
			tokenId,
			sender(),
			tokenOffers[tokenId][offerSender].sender,
			tokenOffers[tokenId][offerSender].value,
			false
		);

		emit AwaitingTransfer(sender(), transfers[tokenId]);

		//delete the offer for the sender
		delete tokenOffers[tokenId][offerSender];
		//update the user offers array
		deleteAddress(tokenId, offerSender);
	}

	function confirmTransfer(uint64 tokenId) public virtual onlyOnce {
		require(transfers[tokenId].from == sender(), "not owner");
		require(
			transfers[tokenId].hasTransfer == false,
			"token has already transfered"
		);
		require(
			ownerOf(tokenId) == transfers[tokenId].to,
			"has not transfered"
		);

		uint256 value = (transfers[tokenId].value);
		transfers[tokenId] = TransferObject(
			tokenId,
			address(0x0),
			address(0x0),
			0,
			true
		);
		payable(sender()).transfer(value);
	}

	function deleteAddress(uint64 tokenId, address offerSender) internal {
		if (userOffers[tokenId].length - 1 == 0) {
			userOffers[tokenId] = new address[](0);
			return;
		}

		address[] memory temp = new address[](userOffers[tokenId].length - 1);
		uint256 count = 0;
		for (uint256 i = 0; i < userOffers[tokenId].length; i++) {
			if (userOffers[tokenId][i] == offerSender) continue;
			temp[count++] = userOffers[tokenId][i];
		}
		userOffers[tokenId] = temp;
	}
}