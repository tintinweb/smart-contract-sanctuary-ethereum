// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./utils/EnumerableEscrow.sol";
import "./interfaces/ICounterfeitMoney.sol";
import "./interfaces/IStolenNFT.sol";
import "./interfaces/IBlackMarket.sol";

error MarketIsClosed();
error NotTheSeller();
error NotTheTokenOwner();
error TokenNotListed();
error TransactionFailed();

/// @title A place where bad people do bad deals
contract BlackMarket is IBlackMarket, EnumerableEscrow, Ownable {
	/// ERC20 Token used to pay for a listing
	ICounterfeitMoney public money;
	/// ERC721 Token that is listed for sale
	IStolenNFT public stolenNFT;
	/// Whether listing / buying is possible
	bool public marketClosed;

	/// Mappings between listed tokenIds and listings seller and price
	mapping(uint256 => Listing) private listings;

	constructor(
		address _owner,
		address _stolenNFT,
		address _money
	) Ownable(_owner) {
		stolenNFT = IStolenNFT(_stolenNFT);
		money = ICounterfeitMoney(_money);
	}

	/// @inheritdoc IBlackMarket
	function buyWithPermit(
		uint256 tokenId,
		uint256 price,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external override {
		money.permit(msg.sender, address(this), price, deadline, v, r, s);
		buy(tokenId);
	}

	/// @inheritdoc IBlackMarket
	function listNftWithPermit(
		uint256 tokenId,
		uint256 price,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external override {
		stolenNFT.permit(msg.sender, address(this), tokenId, deadline, v, r, s);
		listNft(tokenId, price);
	}

	/// @inheritdoc IBlackMarket
	function updateListing(uint256 tokenId, uint256 newPrice) external override {
		Listing storage listing = listings[tokenId];
		if (msg.sender != listing.seller) revert NotTheSeller();

		listing.price = newPrice;

		emit Listed(msg.sender, tokenId, newPrice);
	}

	/// @inheritdoc IBlackMarket
	function cancelListing(uint256 tokenId) external override {
		Listing memory listing = listings[tokenId];
		if (msg.sender != listing.seller && msg.sender != Ownable.owner()) revert NotTheSeller();

		_unlist(listing.seller, tokenId);
		emit Canceled(listing.seller, tokenId, listing.price);

		stolenNFT.transferFrom(address(this), listing.seller, tokenId);
	}

	/// @inheritdoc IBlackMarket
	function closeMarket(bool _marketClosed) external override onlyOwner {
		marketClosed = _marketClosed;
		emit MarketClosed(_marketClosed);
	}

	/// @inheritdoc IBlackMarket
	function getListing(uint256 tokenId) external view override returns (Listing memory) {
		if (listings[tokenId].seller == address(0)) revert TokenNotListed();
		return listings[tokenId];
	}

	/// @inheritdoc IBlackMarket
	function listNft(uint256 tokenId, uint256 price) public override {
		if (stolenNFT.ownerOf(tokenId) != msg.sender) revert NotTheTokenOwner();
		if (marketClosed) revert MarketIsClosed();

		_list(msg.sender, tokenId, price);
		emit Listed(msg.sender, tokenId, price);

		stolenNFT.transferFrom(msg.sender, address(this), tokenId);
	}

	/// @inheritdoc IBlackMarket
	function buy(uint256 tokenId) public override {
		Listing memory listing = listings[tokenId];
		if (listing.seller == address(0)) revert TokenNotListed();
		if (marketClosed) revert MarketIsClosed();

		_unlist(listing.seller, tokenId);
		emit Sold(msg.sender, listing.seller, tokenId, listing.price);

		(address royaltyReceiver, uint256 royaltyShare) = stolenNFT.royaltyInfo(
			tokenId,
			listing.price
		);

		if (royaltyShare > 0) {
			bool sentRoyalty = money.transferFrom(msg.sender, royaltyReceiver, royaltyShare);
			if (!sentRoyalty) revert TransactionFailed();
		}

		bool sent = money.transferFrom(msg.sender, listing.seller, listing.price - royaltyShare);
		if (!sent) revert TransactionFailed();

		stolenNFT.transferFrom(address(this), msg.sender, tokenId);
	}

	/// @dev Adds the listed NFT to the listings and enumerations mapping
	/// @param seller The listings seller
	/// @param tokenId The listed token
	/// @param price The listings price
	function _list(
		address seller,
		uint256 tokenId,
		uint256 price
	) internal {
		listings[tokenId] = Listing(seller, price);
		EnumerableEscrow._addTokenToEnumeration(seller, tokenId);
	}

	/// @dev Removes the listed NFT to the listings and enumerations mapping
	/// @param seller The listings seller
	/// @param tokenId The listed token
	function _unlist(address seller, uint256 tokenId) internal {
		delete listings[tokenId];
		EnumerableEscrow._removeTokenFromEnumeration(seller, tokenId);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

error CallerNotTheOwner();
error NewOwnerIsZeroAddress();

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
abstract contract Ownable {
	address private _contractOwner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the given owner as the initial owner.
	 */
	constructor(address contractOwner_) {
		_transferOwnership(contractOwner_);
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view virtual returns (address) {
		return _contractOwner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		if (owner() != msg.sender) revert CallerNotTheOwner();
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
		if (newOwner == address(0)) revert NewOwnerIsZeroAddress();
		_transferOwnership(newOwner);
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Internal function without access restriction.
	 */
	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _contractOwner;
		_contractOwner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)
pragma solidity ^0.8.0;

import "./IEnumerableEscrow.sol";

error OwnerIndexOutOfBounds(uint256 index);
error GlobalIndexOutOfBounds(uint256 index);

/**
 * @title Adapted ERC-721 enumeration extension for escrow contracts
 */
abstract contract EnumerableEscrow is IEnumerableEscrow {
	// Mapping from owner to amount of tokens stored in escrow
	mapping(address => uint256) private _ownedTokenBalances;

	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) private _ownedTokensIndex;

	// Array with all token ids, used for enumeration
	uint256[] private _allTokens;

	// Mapping from token id to position in the allTokens array
	mapping(uint256 => uint256) private _allTokensIndex;

	/**
	 * @dev See {IEnumerableEscrow-tokenOfOwnerByIndex}.
	 */
	function balanceOf(address owner) public view returns (uint256) {
		return _ownedTokenBalances[owner];
	}

	/**
	 * @dev See {IEnumerableEscrow-tokenOfOwnerByIndex}.
	 */
	function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
		if (index >= _ownedTokenBalances[owner]) revert OwnerIndexOutOfBounds(index);
		return _ownedTokens[owner][index];
	}

	/**
	 * @dev See {IEnumerableEscrow-totalSupply}.
	 */
	function totalSupply() public view returns (uint256) {
		return _allTokens.length;
	}

	/**
	 * @dev See {IEnumerableEscrow-tokenByIndex}.
	 */
	function tokenByIndex(uint256 index) public view returns (uint256) {
		if (index >= EnumerableEscrow.totalSupply()) revert GlobalIndexOutOfBounds(index);
		return _allTokens[index];
	}

	/**
	 * @dev Internal function to remove a token from this extension's token-and-ownership-tracking data structures.
	 * Checks whether token is part of the collection beforehand, so it can be used as part of token recovery
	 * @param owner address representing the previous owner of the given token ID
	 * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
	 */
	function _removeTokenFromEnumeration(address owner, uint256 tokenId) internal {
		_removeTokenFromAllTokensEnumeration(tokenId);
		_removeTokenFromOwnerEnumeration(owner, tokenId);
	}

	/**
	 * @dev Internal function to add a token to this extension's token-and-ownership-tracking data structures.
	 * @param owner address representing the new owner of the given token ID
	 * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
	 */
	function _addTokenToEnumeration(address owner, uint256 tokenId) internal {
		_addTokenToAllTokensEnumeration(tokenId);
		_addTokenToOwnerEnumeration(owner, tokenId);
	}

	/**
	 * @dev Private function to add a token to this extension's ownership-tracking data structures.
	 * @param owner address representing the new owner of the given token ID
	 * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
	 */
	function _addTokenToOwnerEnumeration(address owner, uint256 tokenId) private {
		uint256 length = _ownedTokenBalances[owner];
		_ownedTokens[owner][length] = tokenId;
		_ownedTokensIndex[tokenId] = length;
		_ownedTokenBalances[owner]++;
	}

	/**
	 * @dev Private function to add a token to this extension's token tracking data structures.
	 * @param tokenId uint256 ID of the token to be added to the tokens list
	 */
	function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
		_allTokensIndex[tokenId] = _allTokens.length;
		_allTokens.push(tokenId);
	}

	/**
	 * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
	 * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
	 * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
	 * This has O(1) time complexity, but alters the order of the _ownedTokens array.
	 * @param owner address representing the previous owner of the given token ID
	 * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
	 */
	function _removeTokenFromOwnerEnumeration(address owner, uint256 tokenId) private {
		// To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
		// then delete the last slot (swap and pop).

		uint256 lastTokenIndex = _ownedTokenBalances[owner] - 1;
		uint256 tokenIndex = _ownedTokensIndex[tokenId];

		// When the token to delete is the last token, the swap operation is unnecessary
		if (tokenIndex != lastTokenIndex) {
			uint256 lastTokenId = _ownedTokens[owner][lastTokenIndex];

			_ownedTokens[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
			_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		}

		// This also deletes the contents at the last position of the array
		delete _ownedTokensIndex[tokenId];
		delete _ownedTokens[owner][lastTokenIndex];
		_ownedTokenBalances[owner]--;
	}

	/**
	 * @dev Private function to remove a token from this extension's token tracking data structures.
	 * This has O(1) time complexity, but alters the order of the _allTokens array.
	 * @param tokenId uint256 ID of the token to be removed from the tokens list
	 */
	function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
		// To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
		// then delete the last slot (swap and pop).

		uint256 lastTokenIndex = _allTokens.length - 1;
		uint256 tokenIndex = _allTokensIndex[tokenId];

		// When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
		// rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
		// an 'if' statement (like in _removeTokenFromOwnerEnumeration)
		uint256 lastTokenId = _allTokens[lastTokenIndex];

		_allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
		_allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

		// This also deletes the contents at the last position of the array
		delete _allTokensIndex[tokenId];
		_allTokens.pop();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/// @title Counterfeit Money is just as good as "real" money
/// @dev ERC20 Token with dynamic supply, supporting EIP-2612 signatures for token approvals
interface ICounterfeitMoney is IERC20, IERC20Permit {
	/// @notice Prints and sends a certain amount of CounterfeitMoney to an user
	/// @dev Emits an Transfer event from zero-address
	/// @param to The address receiving the freshly printed money
	/// @param amount The amount of money that will be printed
	function print(address to, uint256 amount) external;

	/// @notice Burns and removes an approved amount of CounterfeitMoney from an user
	/// @dev Emits an Transfer event to zero-address
	/// @param from The address losing the CounterfeitMoney
	/// @param amount The amount of money that will be removed from the account
	function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "../tokens/IERC721Permit.sol";

/// @title Steal somebody's NFTs (with their permission of course)
/// @dev ERC721 Token supporting EIP-2612 signatures for token approvals
interface IStolenNFT is IERC2981, IERC721Metadata, IERC721Enumerable, IERC721Permit {
	/// @notice Emitted when a user steals / mints a NFT
	/// @param thief The user who stole a NFT
	/// @param originalChainId The chain the Nft was stolen from
	/// @param originalContract The original NFTs contract address
	/// @param originalId The original NFTs token ID
	/// @param stolenId The token ID of the minted StolenNFT
	event Stolen(
		address indexed thief,
		uint64 originalChainId,
		address indexed originalContract,
		uint256 indexed originalId,
		uint256 stolenId
	);

	/// @notice Emitted when a user was reported and gets his StolenNFT taken away / burned
	/// @param thief The user who returned the StolenNFT
	/// @param originalChainId The chain the Nft was stolen from
	/// @param originalContract The original NFTs contract address
	/// @param originalId The original NFTs token ID
	/// @param stolenId The token ID of the StolenNFT
	event Seized(
		address indexed thief,
		uint64 originalChainId,
		address originalContract,
		uint256 originalId,
		uint256 indexed stolenId
	);

	/// @notice Struct to store the contract and token ID of the NFT that was stolen
	struct NftData {
		uint32 tokenRoyalty;
		uint64 chainId;
		address contractAddress;
		uint256 tokenId;
	}

	/// @notice Steal / Mint an original NFT to create a StolenNFT
	/// @dev Emits a Stolen event
	/// @param originalChainId The chainId the NFT originates from, used to trace where the nft was stolen from
	/// @param originalAddress The original NFTs contract address
	/// @param originalId The original NFTs token ID
	/// @param mintFrom Optional address the StolenNFT will be minted and transferred from
	/// @param royaltyFee Optional royalty that should be payed to the original owner on secondary market sales
	/// @param uri Optional Metadata URI to overwrite / censor the original NFT
	function steal(
		uint64 originalChainId,
		address originalAddress,
		uint256 originalId,
		address mintFrom,
		uint32 royaltyFee,
		string memory uri
	) external payable returns (uint256);

	/// @notice Allows the StolenNFT to be taken away / burned by the authorities
	/// @dev Emits a Swatted event
	/// @param stolenId The token ID of the StolenNFT
	function swatted(uint256 stolenId) external;

	/// @notice Allows the holder to return / burn the StolenNFT
	/// @dev Emits a Swatted event
	/// @param stolenId The token ID of the StolenNFT
	function surrender(uint256 stolenId) external;

	/// @notice Returns the stolenID for a given original NFT address and tokenID if stolen
	/// @param originalAddress The contract address of the original NFT
	/// @param originalId The tokenID of the original NFT
	/// @return The stolenID
	function getStolen(address originalAddress, uint256 originalId)
		external
		view
		returns (uint256);

	/// @notice Returns the original NFT address and tokenID for a given stolenID if stolen
	/// @param stolenId The stolenID to lookup
	/// @return originalChainId The chain the NFT was stolen from
	/// @return originalAddress The contract address of the original NFT
	/// @return originalId The tokenID of the original NFT
	function getOriginal(uint256 stolenId)
		external
		view
		returns (
			uint64,
			address,
			uint256
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/IEnumerableEscrow.sol";

/// @title A place where bad people do bad deals
interface IBlackMarket is IEnumerableEscrow {
	/// @notice Emitted when a user lists a StolenNFT
	/// @param seller The user who lists the StolenNFT
	/// @param tokenId The token ID of the listed StolenNFT
	/// @param price The listing price
	event Listed(address indexed seller, uint256 indexed tokenId, uint256 price);

	/// @notice Emitted when a user canceled a listed StolenNFT
	/// @param seller The user who listed the StolenNFT / canceled the listing
	/// @param tokenId The token ID of the listed StolenNFT
	/// @param price The original listing price
	event Canceled(address indexed seller, uint256 indexed tokenId, uint256 price);

	/// @notice Emitted when the market closes or opens
	/// @param state Whether the market closed or opened
	event MarketClosed(bool state);

	/// @notice Emitted when a user sells a StolenNFT
	/// @param buyer The user who buys the StolenNFT
	/// @param seller The user who sold the StolenNFT
	/// @param tokenId The token ID of the sold StolenNFT
	/// @param price The paid price
	event Sold(
		address indexed buyer,
		address indexed seller,
		uint256 indexed tokenId,
		uint256 price
	);

	/// @notice Struct to stores a listings seller and price
	struct Listing {
		address seller;
		uint256 price;
	}

	/// @notice Buy a listed StolenNFT on the market
	/// @dev Emits a {Sold} Event
	/// @param tokenId The token id of the StolenNFT to buy
	function buy(uint256 tokenId) external;

	/// @notice Buy a listed NFT on the market by providing a valid EIP-2612 Permit for the Money transaction
	/// @dev Same as {xref-IBlackMarket-buy-uint256-}[`buy`], with additional signature parameters which
	/// allow the approval and transfer of CounterfeitMoney in a single Transaction using EIP-2612 Permits
	/// Emits a {Sold} Event
	/// @param tokenId The token id of the StolenNFT to buy
	/// @param deadline timestamp until when the given signature will be valid
	/// @param v The parity of the y co-ordinate of r of the signature
	/// @param r The x co-ordinate of the r value of the signature
	/// @param s The x co-ordinate of the s value of the signature
	function buyWithPermit(
		uint256 tokenId,
		uint256 price,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/// @notice List a StolenNFT on the market
	/// @dev Emits a {Listed} Event
	/// @param tokenId The token id of the StolenNFT to list
	/// @param price The price the StolenNFT should be listed for
	function listNft(uint256 tokenId, uint256 price) external;

	/// @notice List a StolenNFT on the market by providing a valid EIP-2612 Permit for the token transaction
	/// @dev Same as {xref-IBlackMarket-listNft-uint256-uint256-}[`listNft`], with additional signature parameters which
	/// allow the approval and transfer of CounterfeitMoney in a single Transaction using EIP-2612 Permits
	/// Emits a {Listed} Event
	/// @param tokenId The token id of the StolenNFT to list
	/// @param price The price the StolenNFT should be listed for
	/// @param deadline timestamp until when the given signature will be valid
	/// @param v The parity of the y co-ordinate of r of the signature
	/// @param r The x co-ordinate of the r value of the signature
	/// @param s The x co-ordinate of the s value of the signature
	function listNftWithPermit(
		uint256 tokenId,
		uint256 price,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/// @notice Update an existing listing on the market
	/// @dev Emits a {Listed} Event
	/// @param tokenId The token id of the StolenNFT that is already listed
	/// @param newPrice The new price the StolenNFT
	function updateListing(uint256 tokenId, uint256 newPrice) external;

	/// @notice Cancel an existing listing on the market
	/// @dev Emits a {Canceled} Event
	/// @param tokenId The token id of the listed StolenNFT that should be canceled
	function cancelListing(uint256 tokenId) external;

	/// @notice Allows the market to be closed, disabling listing and buying
	/// @param _marketClosed Whether the market should be closed or opened
	function closeMarket(bool _marketClosed) external;

	/// @notice Get an existing listing on the market by its tokenId
	/// @param tokenId The token id of the listed StolenNFT that should be retrieved
	function getListing(uint256 tokenId) external view returns (Listing memory);
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)
pragma solidity ^0.8.0;

/**
 * @title Adapted ERC-721 enumeration interface for escrow contracts
 */
interface IEnumerableEscrow {
	/**
	 * @dev Returns the users balance of tokens stored by the contract.
	 */
	function balanceOf(address owner) external view returns (uint256);

	/**
	 * @dev Returns the total amount of tokens stored by the contract.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
	 * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
	 */
	function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

	/**
	 * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
	 * Use along with {totalSupply} to enumerate all tokens.
	 */
	function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @dev Interface of extending the IERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 approval (see {IERC721-approval}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC721Permit is IERC20Permit {

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