// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.13;

import '../interfaces/IAccessManager.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IERC2981.sol';
import '../utils/tokens/erc1155/ERC1155.sol';

import '../utils/Owned.sol';

contract AccessManager is ERC1155, IERC2981, IAccessManager, Owned {
	/*///////////////////////////////////////////////////////////////
													EVENTS
	//////////////////////////////////////////////////////////////*/

	event ItemMinted(address indexed account, uint256 indexed tokenId, uint256 indexed level);

	event ItemAdded(uint256 indexed tokenId, uint256 indexed level);

	event ItemMintLive(uint256 tokenId, bool setting);

	/*///////////////////////////////////////////////////////////////
													ERRORS
	//////////////////////////////////////////////////////////////*/

	error Unauthorised();

	error MintingClosed();

	error InvalidItem();

	error ItemUnavailable();

	error AlreadyOwner();

	error InsufficientLevel();

	error IncorrectValue();

	/*///////////////////////////////////////////////////////////////
													ACCESS STORAGE
	//////////////////////////////////////////////////////////////*/

	address public shieldManager;
	address public roundtableRelay;

	string public name;
	string public symbol;
	string public baseURI;

	uint256 internal itemCount;

	// Access Levels
	uint256 constant NONE = uint256(AccessLevels.NONE);
	uint256 constant BASIC = uint256(AccessLevels.BASIC);
	uint256 constant BRONZE = uint256(AccessLevels.BRONZE);
	uint256 constant SILVER = uint256(AccessLevels.SILVER);
	uint256 constant GOLD = uint256(AccessLevels.GOLD);

	// Discounts on items (based of 10000 = 100%)
	uint256 internal goldLevelDiscount = 10000;
	uint256 internal silverLevelDiscount = 5000;
	uint256 internal bronzeLevelDiscount = 1000;

	mapping(uint256 => Item) public itemList;
	mapping(address => uint256) public memberLevel;
	mapping(address => mapping(uint256 => bool)) public roundtableWhitelist;

	/*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

	constructor(
		string memory name_,
		string memory symbol_,
		string memory baseURI_
	) Owned(msg.sender) {
		name = name_;

		symbol = symbol_;

		baseURI = baseURI_;

		emit URI(baseURI, 0);

		// Add placeholder items for NONE level item
		itemList[itemCount] = Item({
			live: true,
			price: 0,
			maxSupply: 0,
			currentSupply: 0,
			accessLevel: 0,
			resaleRoyalty: 0
		});

		emit ItemAdded(itemCount, itemList[itemCount].accessLevel);
		++itemCount;
	}

	/// ----------------------------------------------------------------------------------------
	/// Owner Interface
	/// ----------------------------------------------------------------------------------------

	// Sets the relay and assignes GOLD access (this allows free minting, without adding any logic)
	function setRoundtableRelay(address relay) external onlyOwner {
		roundtableRelay = relay;
		memberLevel[relay] = GOLD;
	}

	function collectFees() external onlyOwner {
		(bool success, ) = payable(msg.sender).call{value: address(this).balance}(new bytes(0));
		require(success, 'AccessManager: Transfer failed');
	}

	function collectERC20(IERC20 erc20) external onlyOwner {
		IERC20(erc20).transfer(owner, erc20.balanceOf(address(this)));
	}

	function setURI(string memory baseURI_) external onlyOwner {
		baseURI = baseURI_;

		emit URI(baseURI, 0);
	}

	function addItem(
		uint256 price,
		uint256 itemSupply,
		uint256 accessLevel,
		uint256 resaleRoyalty
	) external onlyOwner {
		itemList[itemCount] = Item({
			live: false,
			price: price,
			maxSupply: itemSupply,
			currentSupply: 0,
			accessLevel: accessLevel,
			resaleRoyalty: resaleRoyalty
		});

		emit ItemAdded(itemCount, accessLevel);

		++itemCount;
	}

	function setItemMintLive(uint256 itemId, bool setting) external onlyOwner {
		itemList[itemId].live = setting;

		emit ItemMintLive(itemCount, setting);
	}

	function mintAndDrop(
		uint256[] calldata tokenId,
		uint256[] calldata amount,
		address[] calldata receivers
	) external {
		if (!(msg.sender == owner || msg.sender == roundtableRelay)) revert Unauthorised();

		if (tokenId[0] > itemCount) revert InvalidItem();

		if (itemList[tokenId[0]].live == false) revert ItemUnavailable();

		if (itemList[tokenId[0]].currentSupply + amount[0] > itemList[tokenId[0]].maxSupply)
			revert ItemUnavailable();

		_batchMint(msg.sender, tokenId, amount, '');

		for (uint256 i = 0; i < receivers.length; ) {
			if (balanceOf[receivers[i]][tokenId[0]] == 0) {
				safeTransferFrom(msg.sender, receivers[i], tokenId[0], 1, '');
			}

			// Receives will never be a large number
			unchecked {
				++i;
			}
		}
	}

	// Owner or relay can set whitelist
	function toggleItemWhitelist(address user, uint256 itemId) external {
		if (!(msg.sender == owner || msg.sender == roundtableRelay)) revert Unauthorised();

		roundtableWhitelist[user][itemId] = !roundtableWhitelist[user][itemId];
	}

	/// ----------------------------------------------------------------------------------------
	/// Public Interface
	/// ----------------------------------------------------------------------------------------

	function mintItem(uint256 itemId, address member) external payable {
		// If minting not live only a whitelisted member or the relay can mint
		if (
			!itemList[itemId].live &&
			!(roundtableWhitelist[member][itemId] || msg.sender == roundtableRelay)
		) revert MintingClosed();

		if (itemList[itemId].currentSupply == itemList[itemId].maxSupply) revert ItemUnavailable();

		// These are acces passes and members can only have 1 of each
		if (balanceOf[member][itemId] > 0) revert AlreadyOwner();

		if (msg.value != discountedPrice(itemId, member)) revert IncorrectValue();

		// If item is a level pass
		if (itemId <= GOLD) {
			// If user does not already have a higher level pass, update their global level
			// If user already has a level pass, revert since the upgradeLevel function should be called
			if (memberLevel[member] < BRONZE) memberLevel[member] = itemId;
			else revert InvalidItem();
		}

		_mint(member, itemId, 1, '');
		++itemList[itemId].currentSupply;

		emit ItemMinted(member, itemId, itemList[itemId].accessLevel);
	}

	function upgradeLevel(uint256 itemId, address member) external payable {
		if (memberLevel[member] == NONE) revert Unauthorised();

		if (itemId > GOLD) revert InvalidItem();

		if (itemId <= memberLevel[member]) revert InvalidItem();

		if (itemList[itemId].currentSupply >= itemList[itemId].maxSupply) revert ItemUnavailable();

		if (msg.value != itemList[itemId].price - itemList[memberLevel[member]].price)
			revert IncorrectValue();

		// Burn current level item, then mint new level and adjust supply
		_burn(member, memberLevel[member], 1);
		--itemList[memberLevel[member]].currentSupply;

		_mint(member, itemId, 1, '');
		++itemList[itemId].currentSupply;

		memberLevel[member] = itemId;

		emit ItemMinted(member, itemId, itemList[itemId].accessLevel);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual override {
		// If item is a membership level
		if (id <= GOLD)
			if (
				// New level must be higher than old to prevent forced transfer to lower level.
				memberLevel[to] < id
			) {
				// Update receivers level
				memberLevel[to] = id;
				// Set the transferrer back to basic level -> NONE
				memberLevel[from] = NONE;
			} else {
				revert InvalidItem();
			}

		super.safeTransferFrom(from, to, id, amount, data);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual override {
		uint256 idsLength = ids.length; // Saves MLOADs.

		if (idsLength != amounts.length) revert InvalidItem();

		if (!(msg.sender == from || isApprovedForAll[from][msg.sender])) revert Unauthorised();

		// Storing these outside the loop saves ~15 gas per iteration.
		uint256 id;
		uint256 amount;

		for (uint256 i = 0; i < idsLength; ) {
			id = ids[i];
			amount = amounts[i];

			// If item is a membership level
			if (id <= GOLD)
				if (
					// New level must be higher than old to prevent forced transfer to lower level.
					memberLevel[to] < id
				) {
					// Update receivers level
					memberLevel[to] = id;
					// Set the transferrer back to basic level -> NONE
					memberLevel[from] = NONE;
				} else {
					revert InvalidItem();
				}

			balanceOf[from][id] -= amount;
			balanceOf[to][id] += amount;

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				++i;
			}
		}

		emit TransferBatch(msg.sender, from, to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
					ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	/// ----------------------------------------------------------------------------------------
	/// Public View Functions
	/// ----------------------------------------------------------------------------------------

	function uri(uint256 id) public view override returns (string memory) {
		return string(abi.encodePacked(baseURI, uint2str(id), '.json'));
	}

	function getItemCount() public view returns (uint256) {
		return itemCount;
	}

	function itemDetails(uint256 item) public view returns (Item memory) {
		return itemList[item];
	}

	function discountedPrice(uint256 itemId, address member) public returns (uint256 price) {
		// If memberLevel >= level for this item, member doesnt pay -> this covers gold level
		if (memberLevel[member] >= itemList[itemId].accessLevel) {
			return 0;
		}

		// If Whitelist
		if (roundtableWhitelist[member][itemId]) {
			roundtableWhitelist[member][itemId] = false;
			return 0;
		}

		// Non-member pays full price
		if (memberLevel[member] == NONE || memberLevel[member] == BASIC) {
			return itemList[itemId].price;
		}

		if (memberLevel[member] == BRONZE) {
			return itemList[itemId].price - (itemList[itemId].price * bronzeLevelDiscount) / 10000;
		}

		if (memberLevel[member] == SILVER) {
			return itemList[itemId].price - (itemList[itemId].price * silverLevelDiscount) / 10000;
		}
	}

	function royaltyInfo(uint256 tokenId, uint256 salePrice)
		public
		view
		returns (address receiver, uint256 royaltyAmount)
	{
		receiver = address(this);

		royaltyAmount = (salePrice * itemList[tokenId].resaleRoyalty) / 10000;

		return (receiver, royaltyAmount);
	}

	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(ERC1155, IERC165)
		returns (bool)
	{
		return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
	}

	/// ----------------------------------------------------------------------------------------
	/// Internal Interface
	/// ----------------------------------------------------------------------------------------

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return '0';
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

/// @dev Access Level Manager for Roundtable
interface IAccessManager {
	enum AccessLevels {
		NONE,
		BASIC,
		BRONZE,
		SILVER,
		GOLD
	}

	// resaleRoyalty is based off 10000 basis points (eg. resaleRoyalty = 100 => 1.00%)
	struct Item {
		bool live;
		uint256 price;
		uint256 maxSupply;
		uint256 currentSupply;
		uint256 accessLevel;
		uint256 resaleRoyalty;
	}

	function memberLevel(address) external view returns (uint256);

	function roundtableWhitelist(address, uint256) external view returns (bool);

	function toggleItemWhitelist(address, uint256) external;

	function addItem(
		uint256 price,
		uint256 itemSupply,
		uint256 accessLevel,
		uint256 resaleRoyalty
	) external;

	function mintItem(uint256, address) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

/// @dev Interface of the ERC20 standard as defined in the EIP.
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.13;

import './IERC165.sol';

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
	/// ERC165 bytes to add to interface array - set in parent contract
	/// implementing this standard
	///
	/// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
	/// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
	/// _registerInterface(_INTERFACE_ID_ERC2981);

	/// @notice Called with the sale price to determine how much royalty
	//          is owed and to whom.
	/// @param _tokenId - the NFT asset queried for royalty information
	/// @param _salePrice - the sale price of the NFT asset specified by _tokenId
	/// @return receiver - address of who should be sent the royalty payment
	/// @return royaltyAmount - the royalty payment amount for _salePrice
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
		external
		view
		returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
	/*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

	event TransferSingle(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256 id,
		uint256 amount
	);

	event TransferBatch(
		address indexed operator,
		address indexed from,
		address indexed to,
		uint256[] ids,
		uint256[] amounts
	);

	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	event URI(string value, uint256 indexed id);

	/*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

	mapping(address => mapping(uint256 => uint256)) public balanceOf;

	mapping(address => mapping(address => bool)) public isApprovedForAll;

	/*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

	function uri(uint256 id) public view virtual returns (string memory);

	/*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

	function setApprovalForAll(address operator, bool approved) public virtual {
		isApprovedForAll[msg.sender][operator] = approved;

		emit ApprovalForAll(msg.sender, operator, approved);
	}

	function safeTransferFrom(
		address from,
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) public virtual {
		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		balanceOf[from][id] -= amount;
		balanceOf[to][id] += amount;

		emit TransferSingle(msg.sender, from, to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function safeBatchTransferFrom(
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) public virtual {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		require(msg.sender == from || isApprovedForAll[from][msg.sender], 'NOT_AUTHORIZED');

		// Storing these outside the loop saves ~15 gas per iteration.
		uint256 id;
		uint256 amount;

		for (uint256 i = 0; i < idsLength; ) {
			id = ids[i];
			amount = amounts[i];

			balanceOf[from][id] -= amount;
			balanceOf[to][id] += amount;

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				++i;
			}
		}

		emit TransferBatch(msg.sender, from, to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
					ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function balanceOfBatch(address[] memory owners, uint256[] memory ids)
		public
		view
		virtual
		returns (uint256[] memory balances)
	{
		uint256 ownersLength = owners.length; // Saves MLOADs.

		require(ownersLength == ids.length, 'LENGTH_MISMATCH');

		balances = new uint256[](ownersLength);

		// Unchecked because the only math done is incrementing
		// the array index counter which cannot possibly overflow.
		unchecked {
			for (uint256 i = 0; i < ownersLength; ++i) {
				balances[i] = balanceOf[owners[i]][ids[i]];
			}
		}
	}

	/*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

	function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
		return
			interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
			interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
			interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
	}

	/*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

	function _mint(
		address to,
		uint256 id,
		uint256 amount,
		bytes memory data
	) internal {
		balanceOf[to][id] += amount;

		emit TransferSingle(msg.sender, address(0), to, id, amount);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
					ERC1155TokenReceiver.onERC1155Received.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchMint(
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[to][ids[i]] += amounts[i];

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				++i;
			}
		}

		emit TransferBatch(msg.sender, address(0), to, ids, amounts);

		require(
			to.code.length == 0
				? to != address(0)
				: ERC1155TokenReceiver(to).onERC1155BatchReceived(
					msg.sender,
					address(0),
					ids,
					amounts,
					data
				) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
			'UNSAFE_RECIPIENT'
		);
	}

	function _batchBurn(
		address from,
		uint256[] memory ids,
		uint256[] memory amounts
	) internal {
		uint256 idsLength = ids.length; // Saves MLOADs.

		require(idsLength == amounts.length, 'LENGTH_MISMATCH');

		for (uint256 i = 0; i < idsLength; ) {
			balanceOf[from][ids[i]] -= amounts[i];

			// An array can't have a total length
			// larger than the max uint256 value.
			unchecked {
				++i;
			}
		}

		emit TransferBatch(msg.sender, from, address(0), ids, amounts);
	}

	function _burn(
		address from,
		uint256 id,
		uint256 amount
	) internal {
		balanceOf[from][id] -= amount;

		emit TransferSingle(msg.sender, from, address(0), id, amount);
	}
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver {
	function onERC1155Received(
		address operator,
		address from,
		uint256 id,
		uint256 amount,
		bytes calldata data
	) external returns (bytes4);

	function onERC1155BatchReceived(
		address operator,
		address from,
		uint256[] calldata ids,
		uint256[] calldata amounts,
		bytes calldata data
	) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
	/*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

	event OwnerUpdated(address indexed user, address indexed newOwner);

	/*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

	address public owner;

	modifier onlyOwner() virtual {
		require(msg.sender == owner, 'UNAUTHORIZED');

		_;
	}

	/*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

	constructor(address _owner) {
		owner = _owner;

		emit OwnerUpdated(address(0), _owner);
	}

	/*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

	function setOwner(address newOwner) public virtual onlyOwner {
		owner = newOwner;

		emit OwnerUpdated(msg.sender, newOwner);
	}
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.13;

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