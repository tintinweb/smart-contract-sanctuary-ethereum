//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./RandomNumber.sol";

abstract contract Asset {
	struct PartialStruct {
		uint32 pathId;
		uint32 pathSize;
		uint32[] assets;
		string[] names;
		uint32[] colours;
		bytes mintData;
	}

	function getColours(uint32 pathId, RandomNumber randomNumberController)
		public
		virtual
		returns (uint32[] memory result);

	function getDefaultName() internal virtual returns (string memory);

	function getNextPath() external view virtual returns (uint32);

	function pickPath(
		uint32 currentTokenId,
		RandomNumber randomNumberController
	) public virtual returns (PartialStruct memory);

	function isValidPath(uint32 pathId) external view virtual returns (bool);

	function pickPath(
		uint32 pathId,
		uint32 currentTokenId,
		RandomNumber randomNumberController
	) public virtual returns (PartialStruct memory);

	function setLastAssets(uint32[] memory assets) public virtual;

	function getNames(uint256 nameCount, RandomNumber randomNumberController)
		public
		virtual
		returns (string[] memory results);

	function getRandomAsset(uint32 pathId, RandomNumber randomNumberController)
		external
		virtual
		returns (uint32[] memory assetsId);

	function getMintData(
		uint32 pathId,
		uint32 tokenId,
		RandomNumber randomNumberController
	) public virtual returns (bytes memory);

	function addAsset(uint256 rarity) public virtual;

	function getPathGroup(uint32 pathId)
		public
		view
		virtual
		returns (bytes memory, uint32);

	function setNextPathId(uint32 pathId) public virtual;

	function getPathSize(uint32 pathId) public view virtual returns (uint32);

	function getNextPathId(RandomNumber randomNumberController)
		public
		virtual
		returns (uint32);
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
	 * @notice this is used by opensea/polyscan to detect our ERC721
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
		require(exists(_tokenId), "invalid tokenId");
		return tokens[_tokenId];
	}

	/**
        @notice Will approve an operator for the senders tokens
    */
	function setApprovalForAll(address _operator, bool _approved)
		public
		override
	{
		operators[_sender()][_operator] = _approved;
		emit ApprovalForAll(_sender(), _operator, _approved);
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

	/**
        @notice Sets an approved adress for this token
        @dev will Throw if tokenId does not exist
    */
	function approve(address _to, uint256 _tokenId) public override {
		address owner = ERC721.ownerOf(_tokenId);

		require(_to != owner, "cannot approve owner");
		require(
			_sender() == owner || isApprovedForAll(owner, _sender()),
			"ERC721: approve caller is not token owner or approved for all"
		);
		approvedTokens[_tokenId] = _to;
		emit Approval(owner, _to, _tokenId);
	}

	/**
        @notice Mints a token.
        @dev If you are transfering a token to a contract the contract will make sure that it can recieved the ERC721 (implements a IERC721Receiver) if it does not it will revert the transcation. Emits a {Transfer} event.
    */
	function mint(
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal {
		require(_to != address(0x0), "0x0 mint");
		require(!exists(_tokenId), "already minted");

		balance[_to] += 1;
		tokens[_tokenId] = _to;

		emit Transfer(address(0x0), _to, _tokenId);

		//check that the ERC721 has been received
		require(
			checkERC721Received(_sender(), address(this), _to, _tokenId, _data)
		);
	}

	/**
        @notice Returns true if a token exists.
     */
	function exists(uint256 _tokenId) public view returns (bool) {
		return tokens[_tokenId] != address(0x0);
	}

	/// @notice Is ran before every transfer, overwrite this function with your own logic
	/// @dev Must return true else will revert
	function beforeTransfer(
		address _from,
		address _to,
		uint256 _tokenId
	) internal virtual {}

	/**
        @notice Transfers a token fsrom one address to another. Use safeTransferFrom as that will double check that the address you send this token too is a contract that can actually receive it.
		@dev Emits a {Transfer} event.
     */
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) public virtual override {
		require(
			isApprovedOrOwner(_sender(), _tokenId),
			"not approved or owner"
		);
		require(_from != address(0x0), "sending to null address");

		//before the transfer
		beforeTransfer(_from, _to, _tokenId);

		delete approvedTokens[_tokenId];
		balance[_from] -= 1;
		balance[_to] += 1;
		tokens[_tokenId] = _to;

		emit Transfer(_from, _to, _tokenId);
	}

	/// @notice will returns true if the address is apprroved for all, approved operator or is the owner of a token
	/// @dev same as open zepps
	function isApprovedOrOwner(address addr, uint256 tokenId)
		public
		view
		returns (bool)
	{
		address owner = ERC721.ownerOf(tokenId);
		return (addr == owner ||
			isApprovedForAll(owner, addr) ||
			getApproved(tokenId) == addr);
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
		transferFrom(_from, _to, _tokenId);
		//check that it implements an IERC721 receiver if it is a contract
		require(
			checkERC721Received(_sender(), _from, _to, _tokenId, _data),
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

	///@notice secures msg.sender so it cannot be changed
	function _sender() internal view returns (address) {
		return (msg.sender);
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
import "./Minter.sol";
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
	Minter private minterController;

	/// @notice Interface set to the location of the values controller responsible for managing global variables across the smart contract syste,, is set in constructor and cannot be modified.
	InfinityMintValues public valuesController;

	/// @notice Interface set to the location of the royalty controller which controls how  picks random numbers and primes, is set in constructor and can be modified through setDestinations
	Royalty public royaltyController;

	/// @dev will be changed to TokenMinted soon
	event TokenMinted(
		uint32 tokenId,
		bytes encodedData,
		address indexed sender
	);

	/// @dev will be changed to TokenPreviewMinted soon
	event TokenPreviewMinted(
		uint32 tokenId,
		bytes encodedData,
		address indexed sender
	);

	/// @notice Fired when ever a preview has been completed
	event TokenPreviewComplete(address indexed sender, uint256 previewCount);

	/// @notice numerical increment of the current tokenId
	uint32 public currentTokenId;

	/// @notice will disallow mints if set to true
	bool public mintsEnabled;

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
		minterController = Minter(minterContract);
		royaltyController = Royalty(royaltyContract);
	}

	/// @notice the total supply of tokens
	/// @dev Returns the max supply of tokens, not the amount that have been minted. (so the tokenId)
	function totalSupply() public view returns (uint256) {
		return valuesController.tryGetValue("maxSupply");
	}

	/// @notice Toggles mints allowing people to either mint or not mint tokens.
	function setMintsEnabled(bool value) public onlyApproved {
		mintsEnabled = value;
	}

	/// @notice Returns a selection of preview mints, these are ghost NFTs which can be chosen from. Their generation values are based off of eachover due to the nature of the number system.
	/// @dev This method is the most gas intensive method in InfinityMint, how ever there is a trade off in the fact that that MintPreview is insanely cheap and does not need a lot of gas. I suggest using low previewCount values of about 2 or 3. Anything higher is dependant in your project configuartion and how much you care about gas prices.
	function getPreview() public {
		require(veriyMint(0, false), "failed mint verification"); //does not check the price

		//if the user has already had their daily preview mints
		require(
			valuesController.tryGetValue("previewCount") > 0,
			"previews are disabled"
		);

		//the preview timer will default to zero unless a preview has already been minted so there for it can be used like a check
		require(
			block.timestamp > storageController.getPreviewTimestamp(sender()),
			"please mint previews or wait until preview counter is up"
		);

		//minter controller will store the previews for us
		uint256 previewCount = minterController.getPreview(
			currentTokenId,
			sender()
		);

		//get cooldown of previews
		uint256 timestamp = valuesController.tryGetValue(
			"previewCooldownSeconds"
		);
		//if it is 0 (not set), set to 60 seconds
		if (timestamp == 0) timestamp = 60;
		//set it
		storageController.setPreviewTimestamp(
			sender(),
			block.timestamp + timestamp
		);

		//once done, emit an event
		emit TokenPreviewComplete(sender(), previewCount);
	}

	/// @notice Mints a preview. Index is relative to the sender and is the index of the preview in the users preview list
	/// @dev This will wipe other previews once called.
	/// @param index the index of the preview to mint
	function mintPreview(uint32 index) public payable onlyOnce {
		uint256 value = (msg.value);
		require(
			veriyMint(value, !approved[sender()]),
			"failed mint verification"
		); //will not check the price for approved members

		completeMint(
			minterController.mintPreview(index, currentTokenId, sender()),
			sender(),
			true,
			value
		);
	}

	/// @notice Allows approved or the deployer to pick exactly what token they would like to mint. Does not check if assets/colours/mintData is valid. Implicitly assets what ever.
	/// @dev This is the cheapest way to get InfinityMint to mint something as it literally decides no values on chain. This method can also be called by a rollup solution or something or be used as a way to literally mint anything.
	/// @param receiver the address to receive the mint
	/// @param pathId the pathid you want to mint
	/// @param pathSize the size of this path (for colour generation)
	/// @param colours the colours of this token
	/// @param assets the assets for this token
	function implicitMint(
		address receiver,
		uint32 pathId,
		uint32 pathSize,
		uint32[] memory colours,
		bytes memory mintData,
		uint32[] memory assets,
		string[] memory names
	) public onlyApproved {
		require(
			currentTokenId != valuesController.tryGetValue("maxSupply"),
			"max supply has been reached raise it before minting"
		);
		require(
			valuesController.tryGetValue("maxTokensPerWallet") == 0 ||
				balanceOf(receiver) <
				valuesController.tryGetValue("maxTokensPerWallet"),
			"wallet has reached maximum tokens allowed"
		);

		completeMint(
			createInfinityObject(
				currentTokenId,
				pathId,
				pathSize,
				assets,
				names,
				colours,
				mintData,
				receiver,
				new address[](0)
			),
			receiver,
			false,
			0
		);
	}

	/// @notice Returns the current price of a mint.
	/// @dev the royalty controller actually controls the token price so in order to change it you must send tx to that contract.
	function tokenPrice() public view returns (uint256) {
		return royaltyController.tokenPrice();
	}

	/// @notice Public method to mint a token but taking input data in the form of packed bytes
	/// @dev must have byteMint enabled in valuesController
	function mintArguments(bytes memory data) public payable onlyOnce {
		require(
			valuesController.isTrue("byteMint"),
			"must mint with mint instead of byteMint"
		);
		require(data.length != 0, "length of bytes is zero");

		_mint(data);
	}

	/// @notice Public method to mint a token taking no bytes argument
	function mint() public payable onlyOnce {
		require(
			!valuesController.isTrue("byteMint"),
			"must mint with byteMint instead of mint"
		);

		_mint(bytes(""));
	}

	/// @notice returns the tokenURI for a token, will return the
	function tokenURI(uint256 tokenId)
		public
		view
		override
		returns (string memory result)
	{
		require(tokenId < currentTokenId, "tokenURI for non-existent token");

		result = "https://bafybeibfbgz4fmug7fml6ceqhzpobvt6ngjvc63lsg7yv3qbqsemw26irm.ipfs.w3s.link/default_uri.json"; //our default
		string memory defaultTokenURI = storageController.getOption(
			address(this),
			"defaultTokenURI"
		); //NOTE: assuming this is JSON or URI is http address...
		//This must have in it somewhere the key "default": true else the react applicaton will think that this is an actual tokenURI

		if (bytes(defaultTokenURI).length != 0) result = defaultTokenURI;

		address owner = ownerOf(tokenId);
		string memory currentTokenURI = uri[tokenId];

		if (
			storageController.tokenFlag(uint32(tokenId), "forceTokenURI") &&
			bytes(currentTokenURI).length != 0
		) result = currentTokenURI;
		else if (
			storageController.flag(owner, "usingRoot") ||
			storageController.flag(address(this), "usingRoot")
		) {
			//if the owner of the token is using the root, then return the address of the owner, if the project is using a root, return this current address
			address selector = storageController.flag(owner, "usingRoot")
				? owner
				: address(this);
			//gets the root of the tokenURI destination, could be anything, HTTP link or more.
			string memory root = storageController.getOption(selector, "root");
			//the preix to add to the end or the stitch, by default .json will be added unless the boolean inside of the
			//values controller called "removeDefaultSuffix" is true.
			string memory rootSuffix = storageController.getOption(
				selector,
				"rootSuffix"
			);
			if (
				bytes(rootSuffix).length == 0 &&
				!valuesController.isTrue("removeDefaultSuffix")
			) rootSuffix = ".json";

			if (bytes(root).length != 0)
				result = InfinityMintUtil.filepath(
					root,
					InfinityMintUtil.toString(tokenId),
					rootSuffix
				);
		}
	}

	/// @notice Allows you to withdraw your earnings from the contract.
	/// @dev The totals that the sender can withdraw is managed by the royalty controller
	function withdraw() public onlyOnce {
		uint256 total = royaltyController.values(sender());
		require(total > 0, "no balance to withdraw");
		require(address(this).balance - total > 0, "cannot afford to withdraw");

		total = royaltyController.dispenseRoyalty(sender()); //will revert if bad, results in the value to be deposited. Has Re-entry protection.
		require(total > 0, "value returned from royalty controller is bad");

		(bool success, ) = sender().call{ value: total }("");
		require(success, "failure to withdraw");
	}

	/// @notice this can only be called by sticker contracts and is used to pay back the contract owner their sticker cut TODO: Turn this into a non static function capable of accepting payments not just from the sticker
	/// @dev the amount that is paid into this function is defined by the sticker price set by the token owner. The royalty controller cuts up the deposited tokens even more depending on if there are any splits.
	function depositStickerRoyalty(uint32 tokenId) public payable onlyOnce {
		InfinityObject memory temp = storageController.get(tokenId);
		//if the sender isn't the sticker contract attached to this token
		require(
			storageController.validDestination(tokenId, 1),
			"sticker contract not set"
		);
		require(
			sender() == temp.destinations[1],
			"Sender must be the sticker contract attached to this token"
		);

		//if the value is less than 100 and we cannot split it up efficiently then do not incre
		if (value() == 0 || value() > 100)
			//increment
			royaltyController.incrementBalance(
				value(),
				royaltyController.SPLIT_TYPE_STICKER()
			);
		else revert("value given must be over 100, or zero");
	}

	/// @notice Allows approved contracts to deposit royalty types
	function depositSystemRoyalty(uint32 royaltyType)
		public
		payable
		onlyOnce
		onlyApproved
	{
		require(msg.value >= 0, "not allowed to deposit zero values");
		require(
			royaltyType == royaltyController.SPLIT_TYPE_MINT() &&
				royaltyType != royaltyController.SPLIT_TYPE_STICKER(),
			"invalid royalty type"
		);

		//increment
		royaltyController.incrementBalance(msg.value, royaltyType);
		//dont revert allow deposit
	}

	/// @notice Allows the ability for multiple tokens to be transfered at once.
	/// @dev must be split up into chunks of 32
	function transferBatch(uint256[] memory tokenIds, address destination)
		public
	{
		require(tokenIds.length < 32, "please split up into chunks of 32");
		for (uint256 i = 0; i < tokenIds.length; ) {
			safeTransferFrom(sender(), destination, tokenIds[i]);
			unchecked {
				++i;
			}
		}
	}

	/// @notice See {ERC721}
	function beforeTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override {
		require(
			storageController.tokenFlag(uint32(tokenId), "locked") != true,
			"This token is locked and needs to be unlocked before it can be transfered"
		);

		//used in InfinityMint linker, means that non permament links can be relinked
		storageController.setTokenFlag(tokenId, "canUnlink", true);
		storageController.transfer(to, uint32(tokenId));

		if (!valuesController.isTrue("disableRegisteredTokens")) {
			storageController.addToRegisteredTokens(to, uint32(tokenId));

			if (from != address(0x0))
				storageController.deleteFromRegisteredTokens(
					from,
					uint32(tokenId)
				);
		}
	}

	/// @notice sets the token URI
	/// @dev you need to call this from an approved address for the token
	/// @param tokenId the tokenId
	/// @param json an IFPS link or a
	function setTokenURI(uint32 tokenId, string memory json) public {
		require(
			isApprovedOrOwner(sender(), tokenId),
			"is not Owner, approved or approved for all"
		);
		uri[tokenId] = json;
	}

	/// @notice Mints a token and stores its data inside of the storage contract, increments royalty totals and emits event.
	/// @dev This is called after preview mint, implicit mint and normal mints to finish up the transaction. We also wipe previous previews the address might have secretly inside the storageController.set method.
	/// @param data the InfinityMint token data,
	/// @param mintReceiver the sender or what should be tx.origin address
	/// @param isPreviewMint is true if the mint was from a preview
	/// @param mintPrice the value of the msg
	function completeMint(
		InfinityMintObject.InfinityObject memory data,
		address mintReceiver,
		bool isPreviewMint,
		uint256 mintPrice
	) private {
		//mint it
		ERC721.mint(mintReceiver, currentTokenId, data.mintData);
		//store it, also registers it for look up + deletes previous previews
		storageController.set(currentTokenId, data);

		//added for fast on chain look up on ganache basically, in a live environment registeredTokens should be disabled
		if (!valuesController.isTrue("disableRegisteredTokens"))
			storageController.addToRegisteredTokens(
				mintReceiver,
				currentTokenId
			);
		//deletes previews and preview timestamp so they can receive more previews
		storageController.deletePreview(
			mintReceiver,
			valuesController.tryGetValue("previewCount")
		);

		//increment balance inside of royalty controller
		royaltyController.incrementBalance(
			mintPrice,
			royaltyController.SPLIT_TYPE_MINT()
		);

		if (isPreviewMint) {
			//if true then its a preview mint
			emit TokenPreviewMinted(
				currentTokenId++,
				encode(data),
				mintReceiver
			);
			return;
		}

		emit TokenMinted(currentTokenId++, encode(data), mintReceiver);
	}

	/// @notice Mints a new ERC721 InfinityMint Token
	/// @dev Takes no arguments. You dont have to pay for the mint if you are approved (or the deployer)
	function _mint(bytes memory data) private {
		//check if mint is valid
		require(
			veriyMint(value(), !approved[sender()]),
			"failed mint verification"
		);
		completeMint(
			minterController.mint(currentTokenId, sender(), data),
			sender(),
			false,
			value()
		);
	}

	/// @notice checks the transaction to see if it is valid
	/// @dev checks if the price is the current token price and if mints are disabled and if the maxSupply hasnt been met
	/// @param mintPrice the value of the current message
	/// @param checkPrice if we should check the current price
	function veriyMint(uint256 mintPrice, bool checkPrice)
		private
		view
		returns (bool)
	{
		return
			(mintsEnabled &&
				currentTokenId != valuesController.tryGetValue("maxSupply") &&
				!checkPrice) || (mintPrice == royaltyController.tokenPrice());
	}
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

import "./InfinityMint.sol";
import "./Asset.sol";
import "./StickerInterface.sol";
import "./InfinityMintValues.sol";
import "./Royalty.sol";

/// @title InfinityMint API
/// @author Llydia Cross
/// @notice The purpose of this contract is to act as a service to provide data in a web3 or web2 context. You will find methods for data retrival here for previews, tokens, and stickers. and it is advised that you use get from here and not actual storage contract!
/// @dev
contract InfinityMintApi is InfinityMintObject {
	InfinityMint mainContract;
	InfinityMintStorage storageContract;
	Asset assetContract;
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
		assetContract = Asset(assetController);
		valueContract = InfinityMintValues(valueController);
		royaltyContract = Royalty(royaltyController);
	}

	function getPrice() external view returns (uint256) {
		return royaltyContract.tokenPrice();
	}

	function ownerOf(uint32 tokenId) external view returns (address result) {
		result = storageContract.getOwner(tokenId);

		require(result != address(0x0), "bad address");
	}

	/// @notice WARNING! This method is not scalable! Will return all of the stickers associated with a contract.
	function getStickers(address stickerContract)
		external
		view
		returns (uint32[] memory)
	{
		if (stickerContract == address(0x0)) return new uint32[](0);

		StickerInterface sticker = StickerInterface(stickerContract);
		return sticker.getStickers();
	}

	function isPreviewBlocked(address sender) external view returns (bool) {
		return block.timestamp < storageContract.getPreviewTimestamp(sender);
	}

	/// @notice only returns a maximum of 256 tokens use offchain retrival services to obtain token information on owner!
	function allTokens(address owner)
		public
		view
		returns (uint32[] memory tokens)
	{
		require(
			!valueContract.isTrue("disableRegisteredTokens"),
			"all tokens method is disabled"
		);

		return storageContract.getAllRegisteredTokens(owner);
	}

	function getRaw(uint32 tokenId) external view returns (bytes memory) {
		if (tokenId < 0 || tokenId >= mainContract.currentTokenId()) revert();

		InfinityObject memory data = storageContract.get(tokenId);

		return encode(data);
	}

	function getPath(uint32 pathId) external view returns (bytes memory path) {
		(path, ) = assetContract.getPathGroup(pathId);
	}

	function balanceOf(address sender) external view returns (uint256) {
		return mainContract.balanceOf(sender);
	}

	/// @notice gets the balance of a wallet associated with a tokenId
	function getBalanceOfWallet(uint32 tokenId) public view returns (uint256) {
		address addr = getLink(tokenId, 0);
		if (addr == address(0x0)) return 0;
		(bool success, bytes memory returnData) = addr.staticcall(
			abi.encodeWithSignature("getBalance")
		);

		if (!success) return 0;

		return abi.decode(returnData, (uint256));
	}

	function get(uint32 tokenId) external view returns (InfinityObject memory) {
		return storageContract.get(tokenId);
	}

	function getWalletContract(uint32 tokenId)
		public
		view
		returns (address result)
	{
		return getLink(tokenId, 0);
	}

	function getLink(uint32 tokenId, uint256 index)
		public
		view
		returns (address)
	{
		if (tokenId > storageContract.get(tokenId).destinations.length)
			return address(0x0);

		return storageContract.get(tokenId).destinations[index];
	}

	function getStickerContract(uint32 tokenId)
		public
		view
		returns (address result)
	{
		return getLink(tokenId, 1);
	}

	function getPreviewTimestamp(address addr) public view returns (uint256) {
		return storageContract.getPreviewTimestamp(addr);
	}

	function getPreviewCount(address addr) public view returns (uint256 count) {
		//find previews
		InfinityMintObject.InfinityObject[] memory previews = storageContract
			.findPreviews(addr, valueContract.tryGetValue("previewCount"));

		//since mappings initialize their values at defaults we need to check if we are owner
		count = 0;
		for (uint256 i = 0; i < previews.length; ) {
			if (previews[i].owner == addr) count++;

			unchecked {
				++i;
			}
		}
	}

	function allPreviews(address addr) external view returns (uint32[] memory) {
		require(addr != address(0x0), "cannot view previews for null address");

		//find previews
		InfinityMintObject.InfinityObject[] memory previews = storageContract
			.findPreviews(addr, valueContract.tryGetValue("previewCount"));

		//since mappings initialize their values at defaults we need to check if we are owner
		uint256 count = 0;
		for (uint256 i = 0; i < previews.length; ) {
			if (previews[i].owner == addr) count++;
			unchecked {
				++i;
			}
		}

		if (count > 0) {
			uint32[] memory rPreviews = new uint32[](count);
			count = 0;
			for (uint256 i = 0; i < previews.length; ) {
				rPreviews[count++] = uint32(i);
				unchecked {
					++i;
				}
			}

			return rPreviews;
		}

		return new uint32[](0);
	}

	function getPreview(uint32 index)
		public
		view
		returns (InfinityObject memory)
	{
		return storageContract.getPreviewAt(sender(), index);
	}

	function totalMints() external view returns (uint32) {
		return mainContract.currentTokenId();
	}

	//the total amount of tokens
	function totalSupply() external view returns (uint256) {
		return valueContract.tryGetValue("maxSupply");
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

import "./InfinityMintObject.sol";
import "./Authentication.sol";

/// @title InfinityMint storage controller
/// @author Llydia Cross
/// @notice Stores the outcomes of the mint process and previews and also unlock keys
/// @dev Attached to to an InfinityMint
contract InfinityMintStorage is Authentication, InfinityMintObject {
	/// @notice previews
	mapping(address => mapping(uint256 => InfinityObject)) public previews;
	/// @notice previews timestamps of when new previews can be made
	mapping(address => uint256) public previewTimestamp;
	/// @notice all of the token data
	mapping(uint32 => InfinityObject) private tokens;
	/// @notice Address flags can be toggled and effect all of the tokens
	mapping(address => mapping(string => bool)) private flags;
	/// @notice a list of tokenFlags associated with the token
	mapping(uint256 => mapping(string => bool)) public tokenFlags;
	/// @notice a list of options
	mapping(address => mapping(string => string)) private options;
	/// @notice private mapping holding a list of tokens for owned by the address for quick look up
	mapping(address => uint32[]) private registeredTokens;

	/// @notice returns true if the address is preview blocked and unable to receive more previews
	function getPreviewTimestamp(address addr) external view returns (uint256) {
		return previewTimestamp[addr];
	}

	/// @notice sets a time in the future they an have more previews
	function setPreviewTimestamp(address addr, uint256 timestamp)
		public
		onlyApproved
	{
		require(timestamp > block.timestamp, "timestamp must be in the future");
		previewTimestamp[addr] = timestamp;
	}

	/// @notice Allows those approved with the contract to directly force a token flag. The idea is a seperate contract would control immutable this way
	/// @dev NOTE: This can only be called by contracts to curb rugging potential
	function forceTokenFlag(
		uint256 tokenId,
		string memory _flag,
		bool position
	) public onlyApproved {
		tokenFlags[tokenId][_flag] = position;
	}

	//// @notice Allows the current token owner to toggle a flag on the token, for instance, locked flag being true will mean token cannot be transfered
	function setTokenFlag(
		uint256 tokenId,
		string memory _flag,
		bool position
	) public {
		require(this.flag(tokenId, "immutable") != true, "token is immutable");
		require(
			!InfinityMintUtil.isEqual(bytes(_flag), "immutable"),
			"token immutable/mutable state cannot be modified this way for security reasons"
		);
		tokenFlags[tokenId][_flag] = position;
	}

	/// @notice returns the value of a flag
	function flag(uint256 tokenId, string memory _flag)
		external
		view
		returns (bool)
	{
		return tokenFlags[tokenId][_flag];
	}

	/// @notice sets an option for a users tokens
	/// @dev this is used for instance inside of tokenURI
	function setOption(
		address addr,
		string memory key,
		string memory option
	) public onlyApproved {
		options[addr][key] = option;
	}

	/// @notice deletes an option
	function deleteOption(address addr, string memory key) public onlyApproved {
		delete options[addr][key];
	}

	/// @notice returns a global option for all the addresses tokens
	function getOption(address addr, string memory key)
		external
		view
		returns (string memory)
	{
		return options[addr][key];
	}

	//// @notice Allows the current token owner to toggle a flag on the token, for instance, locked flag being true will mean token cannot be transfered
	function setFlag(
		address addr,
		string memory _flag,
		bool position
	) public onlyApproved {
		flags[addr][_flag] = position;
	}

	function tokenFlag(uint32 tokenId, string memory _flag)
		external
		view
		returns (bool)
	{
		return tokenFlags[tokenId][_flag];
	}

	function validDestination(uint32 tokenId, uint256 index)
		external
		view
		returns (bool)
	{
		return (tokens[tokenId].owner != address(0x0) &&
			tokens[tokenId].destinations.length != 0 &&
			index < tokens[tokenId].destinations.length &&
			tokens[tokenId].destinations[index] != address(0x0));
	}

	/// @notice returns the value of a flag
	function flag(address addr, string memory _flag)
		external
		view
		returns (bool)
	{
		return flags[addr][_flag];
	}

	/// @notice returns address of the owner of this token
	/// @param tokenId the tokenId to get the owner of
	function getOwner(uint32 tokenId) public view returns (address) {
		return tokens[tokenId].owner;
	}

	/// @notice returns an integer array containing the token ids owned by the owner address
	/// @dev NOTE: This will only track 256 tokens
	/// @param owner the owner to look for
	function getAllRegisteredTokens(address owner)
		public
		view
		returns (uint32[] memory)
	{
		return registeredTokens[owner];
	}

	/// @notice this method adds a tokenId from the registered tokens list which is kept for the owner. these methods are designed to allow limited data retrival functionality on local host environments
	/// @dev for local testing purposes mostly, to make it scalable the length is capped to 128. Tokens should be indexed by web2 server not on chain.
	/// @param owner the owner to add the token too
	/// @param tokenId the tokenId to add
	function addToRegisteredTokens(address owner, uint32 tokenId)
		public
		onlyApproved
	{
		//if the l
		if (registeredTokens[owner].length < 128)
			registeredTokens[owner].push(tokenId);
	}

	/// @notice Gets the amount of registered tokens
	/// @dev Tokens are indexable instead by their current positon inside of the owner wallets collection, returns a tokenId
	/// @param owner the owner to get the length of
	function getRegisteredTokenCount(address owner)
		public
		view
		returns (uint256)
	{
		return registeredTokens[owner].length;
	}

	/// @notice returns a token
	/// @dev returns an InfinityObject defined in {InfinityMintObject}
	/// @param tokenId the tokenId to get
	function get(uint32 tokenId) public view returns (InfinityObject memory) {
		if (tokens[tokenId].owner == address(0x0)) revert("invalid token");

		return tokens[tokenId];
	}

	/// @notice Sets the owner field in the token to another value
	function transfer(address to, uint32 tokenId) public onlyApproved {
		//set to new owner
		tokens[tokenId].owner = to;
	}

	function set(uint32 tokenId, InfinityObject memory data)
		public
		onlyApproved
	{
		require(data.owner != address(0x0), "null owner");
		require(data.currentTokenId == tokenId, "tokenID mismatch");
		tokens[tokenId] = data;
	}

	/// @notice use normal set when can because of the checks it does before the set, this does no checks
	function setUnsafe(uint32 tokenId, bytes memory data) public onlyApproved {
		tokens[tokenId] = abi.decode(data, (InfinityObject));
	}

	function setPreview(
		address owner,
		uint256 index,
		InfinityObject memory data
	) public onlyApproved {
		previews[owner][index] = data;
	}

	function getPreviewAt(address owner, uint256 index)
		external
		view
		returns (InfinityObject memory)
	{
		require(
			previews[owner][index].owner != address(0x0),
			"invalid preview"
		);

		return previews[owner][index];
	}

	function findPreviews(address owner, uint256 previewCount)
		public
		view
		onlyApproved
		returns (InfinityObject[] memory)
	{
		InfinityObject[] memory temp = new InfinityObject[](previewCount);
		for (uint256 i = 0; i < previewCount; ) {
			temp[i] = previews[owner][i];

			unchecked {
				++i;
			}
		}

		return temp;
	}

	function deletePreview(address owner, uint256 previewCount)
		public
		onlyApproved
	{
		for (uint256 i = 0; i < previewCount; ) {
			delete previews[owner][i];

			unchecked {
				++i;
			}
		}

		delete previewTimestamp[owner];
	}

	/// @notice this method deletes a tokenId from the registered tokens list which is kept for the owner. these methods are designed to allow limited data retrival functionality on local host environments
	/// @dev only works up to 256 entrys, not scalable
	function deleteFromRegisteredTokens(address sender, uint32 tokenId) public {
		if (registeredTokens[sender].length - 1 <= 0) {
			registeredTokens[sender] = new uint32[](0);
			return;
		}

		uint32[] memory newArray = new uint32[](
			registeredTokens[sender].length - 1
		);
		uint256 index = 0;
		for (uint256 i = 0; i < registeredTokens[sender].length; ) {
			if (index == newArray.length) break;
			if (tokenId == registeredTokens[sender][i]) {
				unchecked {
					++i;
				}
				continue;
			}

			newArray[index++] = registeredTokens[sender][i];

			unchecked {
				++i;
			}
		}

		registeredTokens[sender] = newArray;
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

import "./Authentication.sol";
import "./InfinityMintStorage.sol";
import "./Asset.sol";
import "./RandomNumber.sol";
import "./InfinityMintObject.sol";

abstract contract Minter is Authentication {
	InfinityMintValues valuesController;
	InfinityMintStorage storageController;
	Asset assetController;
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
		assetController = Asset(assetContract);
		randomNumberController = RandomNumber(randomNumberContract);
	}

	function mint(
		uint32 currentTokenId,
		address sender,
		bytes memory mintData
	) public virtual returns (InfinityMintObject.InfinityObject memory);

	/**

     */
	function getPreview(uint32 currentTokenId, address sender)
		external
		virtual
		returns (uint256 previewCount);

	/*

    */
	function mintPreview(
		uint32 index,
		uint32 currentTokenId,
		address sender
	) external virtual returns (InfinityMintObject.InfinityObject memory);
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
		unchecked {
			++salt;
		}

		return returnNumber(valuesController.getValue("maxRandomNumber"), salt);
	}

	function getMaxNumber(uint256 maxNumber) external returns (uint256) {
		unchecked {
			++salt;
		}

		return returnNumber(maxNumber, salt);
	}

	/// @notice cheap return number
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
	address public erc721Destination;

	//payout values
	mapping(address => uint256) public values;
	mapping(uint256 => uint256) public freebies;

	uint256 public tokenPrice;
	uint256 public originalTokenPrice;
	uint256 public lastTokenPrice;
	uint256 public stickerSplit;

	uint8 public constant SPLIT_TYPE_MINT = 0;
	uint8 public constant SPLIT_TYPE_STICKER = 1;

	uint256 internal remainder;

	event DispensedRoyalty(
		address indexed sender,
		uint256 amount,
		uint256 newTotal
	);

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

		if (valuesController.tryGetValue("stickerSplit") > 100)
			revert("sticker split is a value over 100");
		stickerSplit = valuesController.tryGetValue("stickerSplit");
	}

	function changePrice(uint256 _tokenPrice) public onlyDeployer {
		lastTokenPrice = tokenPrice;
		tokenPrice = _tokenPrice;
	}

	function registerFree(uint256 splitType) public onlyApproved {
		freebies[splitType]++;
	}

	function dispenseRoyalty(address addr)
		public
		onlyApproved
		onlyOnce
		returns (uint256 total)
	{
		if (values[addr] <= 0) revert("Invalid or Empty address");

		total = values[addr];
		values[addr] = 0;

		emit DispensedRoyalty(addr, total, values[addr]);
	}

	function incrementBalance(uint256 value, uint256 typeOfSplit)
		external
		virtual;
}

//SPDX-License-Identifier: UNLICENSED
//llydia cross 2021
pragma solidity ^0.8.0;

interface StickerInterface {
	function acceptRequest(address sender, uint32 index) external;

	function addRequest(bytes memory packed) external payable;

	function withdrawRequest(uint32 index) external;

	function denyRequest(address sender, uint32 index) external;

	function getStickers() external view returns (uint32[] memory result);

	function getSticker(uint32 stickerId)
		external
		view
		returns (bytes memory result);

	function getRequests() external view returns (bytes[] memory result);

	function getRequestCount() external view returns (uint256);

	function getStickerCount() external view returns (uint256);

	function getMyRequests() external view returns (bytes[] memory result);
}