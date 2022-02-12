// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721 } from "./ERC721/ERC721.sol";
import { ERC721M } from "./ERC721/ERC721M.sol";
import { ERC721Tradable } from "./ERC721/extensions/ERC721Tradable.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Mingoes is ERC721M, ERC721Tradable, Ownable {
	uint256 public constant PRICE = 0.04 ether;

	uint256 public constant MAX_SUPPLY = 10000;
	uint256 public constant MAX_RESERVE = 300;
	uint256 public constant MAX_PUBLIC = 9700; // MAX_SUPPLY - MAX_RESERVE
	uint256 public constant MAX_FREE = 200;

	uint256 public constant MAX_TX = 20;

	uint256 public reservesMinted;

	string public baseURI;

	bool public isSaleActive;

	mapping (address => bool) public hasClaimed;

	/* -------------------------------------------------------------------------- */
	/*                                 CONSTRUCTOR                                */
	/* -------------------------------------------------------------------------- */

	constructor(
		address _openSeaProxyRegistry,
		address _looksRareTransferManager,
		string memory _baseURI
	) payable ERC721M("Mingoes", "MINGOES") ERC721Tradable(_openSeaProxyRegistry, _looksRareTransferManager) {
		baseURI = _baseURI;
	}

	/* -------------------------------------------------------------------------- */
	/*                                    USER                                    */
	/* -------------------------------------------------------------------------- */

	/// @notice Mints an amount of tokens and transfers them to the caller during the public sale.
	/// @param amount The amount of tokens to mint.
	function publicMint(uint256 amount) external payable {
		require(isSaleActive, "Sale is not active");
		require(msg.sender == tx.origin, "No contracts allowed");

		uint256 _totalSupply = totalSupply();
		if (_totalSupply < MAX_FREE) {
			require(!hasClaimed[msg.sender], "Already claimed");
			hasClaimed[msg.sender] = true;
			
			_mint(msg.sender, 1);
			
			return;
		}
			
		require(msg.value == PRICE * amount, "Wrong ether amount");
		require(amount <= MAX_TX, "Amount exceeds tx limit");
		require(_totalSupply + amount <= MAX_PUBLIC, "Max public supply reached");

		_mint(msg.sender, amount);
	}

	/* -------------------------------------------------------------------------- */
	/*                                    OWNER                                   */
	/* -------------------------------------------------------------------------- */

	/// @notice Enables or disables minting through {publicMint}.
	/// @dev Requirements:
	/// - Caller must be the owner.
	function setIsSaleActive(bool _isSaleActive) external onlyOwner {
		isSaleActive = _isSaleActive;
	}

	/// @notice Mints tokens to multiple addresses.
	/// @dev Requirements:
	/// - Caller must be the owner.
	/// @param recipients The addresses to mint the tokens to.
	/// @param amounts The amounts of tokens to mint.
	function reserveMint(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
		unchecked {
			uint256 sum;
			uint256 length = recipients.length;
			for (uint256 i; i < length; i++) {
				address to = recipients[i];
				require(to != address(0), "Invalid recipient");
				uint256 amount = amounts[i];

				_mint(to, amount);
				sum += amount;
			}

			uint256 totalReserves = reservesMinted + sum;

			require(totalSupply() <= MAX_SUPPLY, "Max supply reached");
			require(totalReserves <= MAX_RESERVE, "Amount exceeds reserve limit");

			reservesMinted = totalReserves;
		}
	}

	/// @notice Sets the base Uniform Resource Identifier (URI) for token metadata.
	/// @dev Requirements:
	/// - Caller must be the owner.
	/// @param _baseURI The base URI.
	function setBaseURI(string calldata _baseURI) external onlyOwner {
		baseURI = _baseURI;
	}

	/// @notice Withdraws all contract balance to the caller.
	/// @dev Requirements:
	/// - Caller must be the owner.
	function withdrawETH() external onlyOwner {
		_transferETH(msg.sender, address(this).balance);
	}

	/// @dev Requirements:
	/// - Caller must be the owner.
	/// @inheritdoc ERC721Tradable
	function setMarketplaceApprovalForAll(bool approved) public override onlyOwner {
		marketPlaceApprovalForAll = approved;
	}

	/* -------------------------------------------------------------------------- */
	/*                             SOLIDITY OVERRIDES                             */
	/* -------------------------------------------------------------------------- */

	/// @inheritdoc ERC721
	function tokenURI(uint256 id) public view override returns (string memory) {
		require(_exists(id), "NONEXISTENT_TOKEN");
		string memory _baseURI = baseURI;
		return bytes(_baseURI).length == 0 ? "" : string(abi.encodePacked(_baseURI, toString(id)));
	}

	/// @inheritdoc ERC721Tradable
	function isApprovedForAll(address owner, address operator) public view override(ERC721, ERC721Tradable) returns (bool) {
		return ERC721Tradable.isApprovedForAll(owner, operator);
	}

	/* -------------------------------------------------------------------------- */
	/*                                    UTILS                                   */
	/* -------------------------------------------------------------------------- */

	function _transferETH(address to, uint256 value) internal {
		// solhint-disable-next-line avoid-low-level-calls
		(bool success, ) = to.call{ value: value }("");
		require(success, "ETH transfer failed");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721TokenReceiver } from "./ERC721TokenReceiver.sol";

abstract contract ERC721 {
	/* -------------------------------------------------------------------------- */
	/*                                   EVENTS                                   */
	/* -------------------------------------------------------------------------- */

	/// @dev Emitted when `id` token is transferred from `from` to `to`.
	event Transfer(address indexed from, address indexed to, uint256 indexed id);

	/// @dev Emitted when `owner` enables `approved` to manage the `id` token.
	event Approval(address indexed owner, address indexed spender, uint256 indexed id);

	/// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	/* -------------------------------------------------------------------------- */
	/*                              METADATA STORAGE                              */
	/* -------------------------------------------------------------------------- */

	/// @dev The collection name.
	string private _name;

	/// @dev The collection symbol.
	string private _symbol;

	/* -------------------------------------------------------------------------- */
	/*                               ERC721 STORAGE                               */
	/* -------------------------------------------------------------------------- */

	/// @dev ID => spender
	mapping(uint256 => address) internal _tokenApprovals;

	/// @dev owner => operator => approved
	mapping(address => mapping(address => bool)) internal _operatorApprovals;

	/* -------------------------------------------------------------------------- */
	/*                                 CONSTRUCTOR                                */
	/* -------------------------------------------------------------------------- */

	/// @param name_ The collection name.
	/// @param symbol_ The collection symbol.
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	/* -------------------------------------------------------------------------- */
	/*                                ERC165 LOGIC                                */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns true if this contract implements an interface from its ID.
	/// @dev See the corresponding
	/// [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
	/// to learn more about how these IDs are created.
	/// @return The implementation status.
	function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
			interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
			interfaceId == 0x780e9d63; // ERC165 Interface ID for ERC721Enumerable
	}

	/* -------------------------------------------------------------------------- */
	/*                               METADATA LOGIC                               */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns the collection name.
	/// @return The collection name.
	function name() public view virtual returns (string memory) {
		return _name;
	}

	/// @notice Returns the collection symbol.
	/// @return The collection symbol.
	function symbol() public view virtual returns (string memory) {
		return _symbol;
	}

	/// @notice Returns the Uniform Resource Identifier (URI) for `id` token.
	/// @param id The token ID.
	/// @return The URI.
	function tokenURI(uint256 id) public view virtual returns (string memory);

	/* -------------------------------------------------------------------------- */
	/*                              ENUMERABLE LOGIC                              */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns the total amount of tokens stored by the contract.
	/// @return The token supply.
	function totalSupply() public view virtual returns (uint256);

	/// @notice Returns a token ID owned by `owner` at a given `index` of its token list.
	/// @dev Use along with {balanceOf} to enumerate all of `owner`'s tokens.
	/// @param owner The address to query.
	/// @param index The index to query.
	/// @return The token ID.
	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);

	/// @notice Returns a token ID at a given `index` of all the tokens stored by the contract.
	/// @dev Use along with {totalSupply} to enumerate all tokens.
	/// @param index The index to query.
	/// @return The token ID.
	function tokenByIndex(uint256 index) public view virtual returns (uint256);

	/* -------------------------------------------------------------------------- */
	/*                                ERC721 LOGIC                                */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns the account approved for a token ID.
	/// @dev Requirements:
	/// - `id` must exist.
	/// @param id Token ID to query.
	/// @return The account approved for `id` token.
	function getApproved(uint256 id) public virtual returns (address) {
		require(_exists(id), "NONEXISTENT_TOKEN");
		return _tokenApprovals[id];
	}

	/// @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
	/// @param owner The address of the owner.
	/// @param operator The address of the operator.
	/// @return True if `operator` was approved by `owner`.
	function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
		return _operatorApprovals[owner][operator];
	}

	/// @notice Gives permission to `to` to transfer `id` token to another account.
	/// @dev The approval is cleared when the token is transferred.
	/// Only a single account can be approved at a time, so approving the zero address clears previous approvals.
	/// Requirements:
	/// - The caller must own the token or be an approved operator.
	/// - `id` must exist.
	/// Emits an {Approval} event.
	/// @param spender The address of the spender to approve to.
	/// @param id The token ID to approve.
	function approve(address spender, uint256 id) public virtual {
		address owner = ownerOf(id);

		require(isApprovedForAll(owner, msg.sender) || msg.sender == owner, "NOT_AUTHORIZED");

		_tokenApprovals[id] = spender;

		emit Approval(owner, spender, id);
	}

	/// @notice Approve or remove `operator` as an operator for the caller.
	/// @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
	/// Emits an {ApprovalForAll} event.
	/// @param operator The address of the operator to approve.
	/// @param approved The status to set.
	function setApprovalForAll(address operator, bool approved) public virtual {
		_operatorApprovals[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	/// @notice Transfers `id` token from `from` to `to`.
	/// WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
	/// @dev Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must be owned by `from`.
	/// - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	/// Emits a {Transfer} event.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	function transferFrom(
		address from,
		address to,
		uint256 id
	) public virtual {
		_transfer(from, to, id);
	}

	/// @notice Safely transfers `id` token from `from` to `to`.
	/// @dev Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must exist and be owned by `from`.
	/// - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	/// - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
	/// Emits a {Transfer} event.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	function safeTransferFrom(
		address from,
		address to,
		uint256 id
	) public virtual {
		_transfer(from, to, id);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/// @notice Safely transfers `id` token from `from` to `to`.
	/// @dev Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must exist and be owned by `from`.
	/// - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
	/// - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver-onERC721Received}, which is called upon a safe transfer.
	/// Emits a {Transfer} event.
	/// Additionally passes `data` in the callback.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	/// @param data The calldata to pass in the {ERC721TokenReceiver-onERC721Received} callback.
	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		bytes memory data
	) public virtual {
		_transfer(from, to, id);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/// @notice Returns the number of tokens in an account.
	/// @param owner The address to query.
	/// @return The balance.
	function balanceOf(address owner) public view virtual returns (uint256);

	/// @notice Returns the owner of a token ID.
	/// @dev Requirements:
	/// - `id` must exist.
	/// @param id The token ID.
	function ownerOf(uint256 id) public view virtual returns (address);

	/* -------------------------------------------------------------------------- */
	/*                               INTERNAL LOGIC                               */
	/* -------------------------------------------------------------------------- */

	/// @dev Returns whether a token ID exists.
	/// Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	/// Tokens start existing when they are minted.
	/// @param id Token ID to query.
	function _exists(uint256 id) internal view virtual returns (bool);

	/// @dev Transfers `id` from `from` to `to`.
	/// Requirements:
	/// - `to` cannot be the zero address.
	/// - `id` token must be owned by `from`.
	/// Emits a {Transfer} event.
	/// @param from The address to transfer from.
	/// @param to The address to transfer to.
	/// @param id The token ID to transfer.
	function _transfer(
		address from,
		address to,
		uint256 id
	) internal virtual;

	/// @dev Mints `amount` tokens to `to`.
	/// Requirements:
	/// - there must be `amount` tokens remaining unminted in the total collection.
	/// - `to` cannot be the zero address.
	/// Emits `amount` {Transfer} events.
	/// @param to The address to mint to.
	/// @param amount The amount of tokens to mint.
	function _mint(address to, uint256 amount) internal virtual;

	/// @dev Safely mints `amount` of tokens and transfers them to `to`.
	/// If `to` is a contract it must implement {ERC721TokenReceiver.onERC721Received}
	/// that returns {ERC721TokenReceiver.onERC721Received.selector}.
	/// @param to The address to mint to.
	/// @param amount The amount of tokens to mint.
	function _safeMint(address to, uint256 amount) internal virtual {
		_mint(to, amount);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(address(0), to, totalSupply() - amount + 1, "") == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/// @dev Safely mints `amount` of tokens and transfers them to `to`.
	/// Requirements:
	/// - `id` must not exist.
	/// - If `to` refers to a smart contract, it must implement {ERC721TokenReceiver.onERC721Received}, which is called upon a safe transfer.
	/// Additionally passes `data` in the callback.
	/// @param to The address to mint to.
	/// @param amount The amount of tokens to mint.
	/// @param data The calldata to pass in the {ERC721TokenReceiver.onERC721Received} callback.
	function _safeMint(
		address to,
		uint256 amount,
		bytes memory data
	) internal virtual {
		_mint(to, amount);

		require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(address(0), to, totalSupply() - amount + 1, data) == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT");
	}

	/* -------------------------------------------------------------------------- */
	/*                                    UTILS                                   */
	/* -------------------------------------------------------------------------- */

	/// @notice Converts a `uint256` to its ASCII `string` decimal representation.
	/// @dev https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
	function toString(uint256 value) internal pure virtual returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return "0";
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import { ERC721 } from "./ERC721.sol";

abstract contract ERC721M is ERC721 {
	/* -------------------------------------------------------------------------- */
	/*                               ERC721M STORAGE                              */
	/* -------------------------------------------------------------------------- */

	/// @dev The index is the token ID counter and points to its owner.
	address[] internal _owners;

	/* -------------------------------------------------------------------------- */
	/*                                 CONSTRUCTOR                                */
	/* -------------------------------------------------------------------------- */

	constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
		// Initializes the index to 1.
		_owners.push();
	}

	/* -------------------------------------------------------------------------- */
	/*                              ENUMERABLE LOGIC                              */
	/* -------------------------------------------------------------------------- */

	/// @inheritdoc ERC721
	function totalSupply() public view override returns (uint256) {
		// Overflow is impossible as _owners.length is initialized to 1.
		unchecked {
			return _owners.length - 1;
		}
	}

	/// @dev O(totalSupply), it is discouraged to call this function from other contracts
	/// as it can become very expensive, especially with higher total collection sizes.
	/// @inheritdoc ERC721
	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
		require(index < balanceOf(owner), "INVALID_INDEX");

		// Both of the counters cannot overflow because the loop breaks before that.
		unchecked {
			uint256 count;
			uint256 _currentIndex = _owners.length; // == totalSupply() + 1 == _owners.length - 1 + 1
			for (uint256 i; i < _currentIndex; i++) {
				if (owner == ownerOf(i)) {
					if (count == index) return i;
					else count++;
				}
			}
		}

		revert("NOT_FOUND");
	}

	/// @inheritdoc ERC721
	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		require(_exists(index), "INVALID_INDEX");
		return index;
	}

	/* -------------------------------------------------------------------------- */
	/*                                ERC721 LOGIC                                */
	/* -------------------------------------------------------------------------- */

	/// @dev O(totalSupply), it is discouraged to call this function from other contracts
	/// as it can become very expensive, especially with higher total collection sizes.
	/// @inheritdoc ERC721
	function balanceOf(address owner) public view virtual override returns (uint256 balance) {
		require(owner != address(0), "INVALID_OWNER");

		unchecked {
			// Start at 1 since token 0 does not exist
			uint256 _currentIndex = _owners.length; // == totalSupply() + 1 == _owners.length - 1 + 1
			for (uint256 i = 1; i < _currentIndex; i++) {
				if (owner == ownerOf(i)) {
					balance++;
				}
			}
		}
	}

	/// @dev O(MAX_TX), gradually moves to O(1) as more tokens get transferred and
	/// the owners are explicitly set.
	/// @inheritdoc ERC721
	function ownerOf(uint256 id) public view virtual override returns (address owner) {
		require(_exists(id), "NONEXISTENT_TOKEN");

		for (uint256 i = id; ; i++) {
			owner = _owners[i];
			if (owner != address(0)) {
				return owner;
			}
		}
	}

	/* -------------------------------------------------------------------------- */
	/*                               INTERNAL LOGIC                               */
	/* -------------------------------------------------------------------------- */

	/// @inheritdoc ERC721
	function _mint(address to, uint256 amount) internal virtual override {
		require(to != address(0), "INVALID_RECIPIENT");
		require(amount != 0, "INVALID_AMOUNT");

		unchecked {
			uint256 _currentIndex = _owners.length; // == totalSupply() + 1 == _owners.length - 1 + 1

			for (uint256 i; i < amount - 1; i++) {
				// storing address(0) while also incrementing the index
				_owners.push();
				emit Transfer(address(0), to, _currentIndex + i);
			}

			// storing the actual owner
			_owners.push(to);
			emit Transfer(address(0), to, _currentIndex + (amount - 1));
		}
	}

	/// @inheritdoc ERC721
	function _exists(uint256 id) internal view virtual override returns (bool) {
		return id != 0 && id < _owners.length;
	}

	/// @inheritdoc ERC721
	function _transfer(
		address from,
		address to,
		uint256 id
	) internal virtual override {
		require(ownerOf(id) == from, "WRONG_FROM");
		require(to != address(0), "INVALID_RECIPIENT");
		require(msg.sender == from || getApproved(id) == msg.sender || isApprovedForAll(from, msg.sender), "NOT_AUTHORIZED");

		delete _tokenApprovals[id];

		_owners[id] = to;

		unchecked {
			uint256 prevId = id - 1;
			if (_owners[prevId] == address(0)) {
				_owners[prevId] = from;
			}
		}

		emit Transfer(from, to, id);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721 } from "../ERC721.sol";

/// @notice An interface for the OpenSea Proxy Registry.
interface IProxyRegistry {
	function proxies(address) external view returns (address);
}

abstract contract ERC721Tradable is ERC721 {
	/* -------------------------------------------------------------------------- */
	/*                              IMMUTABLE STORAGE                             */
	/* -------------------------------------------------------------------------- */

	/// @notice The OpenSea Proxy Registry address.
	address public immutable openSeaProxyRegistry;

	/// @notice The LooksRare Transfer Manager (ERC721) address.
	address public immutable looksRareTransferManager;

	/* -------------------------------------------------------------------------- */
	/*                               MUTABLE STORAGE                              */
	/* -------------------------------------------------------------------------- */

	/// @notice Returns true if the stored marketplace addresses are whitelisted in {isApprovedForAll}.
	/// @dev Enabled by default. Can be turned off with {setMarketplaceApprovalForAll}.
	bool public marketPlaceApprovalForAll = true;

	/* -------------------------------------------------------------------------- */
	/*                                 CONSTRUCTOR                                */
	/* -------------------------------------------------------------------------- */

	/// OpenSea proxy registry addresses:
	/// - ETHEREUM MAINNET: 0xa5409ec958C83C3f309868babACA7c86DCB077c1
	/// - ETHEREUM RINKEBY: 0xF57B2c51dED3A29e6891aba85459d600256Cf317
	/// LooksRare Transfer Manager addresses (https://docs.looksrare.org/developers/deployed-contract-addresses):
	/// - ETHEREUM MAINNET: 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e
	/// - ETHEREUM RINKEBY: 0x3f65A762F15D01809cDC6B43d8849fF24949c86a
	/// @param _openSeaProxyRegistry The OpenSea proxy registry address.
	constructor(address _openSeaProxyRegistry, address _looksRareTransferManager) {
		require(_openSeaProxyRegistry != address(0) && _looksRareTransferManager != address(0), "INVALID_ADDRESS");
		openSeaProxyRegistry = _openSeaProxyRegistry;
		looksRareTransferManager = _looksRareTransferManager;
	}

	/* -------------------------------------------------------------------------- */
	/*                            ERC721ATradable LOGIC                           */
	/* -------------------------------------------------------------------------- */

	/// @notice Enables or disables the marketplace whitelist in {isApprovedForAll}.
	/// @dev Must be implemented in inheriting contracts.
	/// Recommended to use in combination with an access control contract (e.g. OpenZeppelin's Ownable).
	function setMarketplaceApprovalForAll(bool approved) public virtual;

	/// @return True if `operator` is a whitelisted marketplace contract or if it was approved by `owner` with {ERC721A.setApprovalForAll}.
	/// @inheritdoc ERC721
	function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
		if (marketPlaceApprovalForAll && (operator == IProxyRegistry(openSeaProxyRegistry).proxies(owner) || operator == looksRareTransferManager)) return true;
		return super.isApprovedForAll(owner, operator);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
	function onERC721Received(
		address operator,
		address from,
		uint256 id,
		bytes calldata data
	) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}