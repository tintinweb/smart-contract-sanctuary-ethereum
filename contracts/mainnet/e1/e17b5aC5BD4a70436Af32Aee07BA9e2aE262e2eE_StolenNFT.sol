// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Ownable.sol";
import "./tokens/ERC721Enumerable.sol";
import "./tokens/ERC721Permit.sol";
import "./interfaces/IStolenNFT.sol";
import "./interfaces/ICriminalRecords.sol";

error AlreadyStolen(uint256 tokenId);
error CallerNotTheLaw();
error CriminalRecordsOffline();
error CrossChainUriMissing();
error ErrorSendingTips();
error InvalidChainId();
error InvalidRoyalty();
error NothingLeftToSteal();
error NoTips();
error ReceiverIsRetired();
error SenderIsRetired();
error StealingFromZeroAddress();
error StealingStolenNft();
error ThiefIsRetired();
error UnsupportedToken();
error YouAreRetired();
error YouAreWanted();

/// @title Steal somebody's NFTs (with their permission of course)
/// @dev ERC721 Token supporting EIP-2612 signatures for token approvals
contract StolenNFT is IStolenNFT, Ownable, ERC721Permit, ERC721Enumerable {
	/// Contract used to track the thief's action
	ICriminalRecords public criminalRecords;
	/// Maximum supply of stolen NFTs
	uint256 public maximumSupply;
	/// Used for unique stolen token ids
	uint256 private _tokenCounter;
	/// Mapping from the original address & token id hash to a StolenNFT token id
	mapping(bytes32 => uint256) private _stolenNfts;
	/// Mapping from a StolenNFT token id to a struct containing the original address & token id
	mapping(uint256 => NftData) private _stolenNftsById;
	/// Optional mapping of StolenNFTs token ids to tokenURIs
	mapping(uint256 => string) private _tokenURIs;
	/// Mapping of thief's to whether they are retired to disable interaction / transfer with StolenNFTs
	mapping(address => bool) private _retiredThief;

	constructor(address _owner) Ownable(_owner) ERC721Permit("StolenNFT", "SNFT") {
		maximumSupply = type(uint256).max;
	}

	receive() external payable {}

	/// @inheritdoc IStolenNFT
	function steal(
		uint64 originalChainId,
		address originalAddress,
		uint256 originalId,
		address mintFrom,
		uint32 royaltyFee,
		string memory uri
	) external payable override returns (uint256) {
		if (retired(msg.sender)) revert YouAreRetired();
		if (totalSupply() >= maximumSupply) revert NothingLeftToSteal();
		if (originalAddress == address(0)) revert StealingFromZeroAddress();
		if (originalAddress == address(this)) revert StealingStolenNft();
		if (originalChainId == 0 || originalChainId > type(uint64).max / 2 - 36)
			revert InvalidChainId();
		if ((royaltyFee > 0 && originalChainId != block.chainid) || royaltyFee > 10000)
			revert InvalidRoyalty();

		bytes32 nftHash = keccak256(abi.encodePacked(originalAddress, originalId));
		if (_stolenNfts[nftHash] != 0) revert AlreadyStolen(_stolenNfts[nftHash]);

		uint256 stolenId = ++_tokenCounter;

		// Set the tokenUri if given
		if (bytes(uri).length > 0) {
			_tokenURIs[stolenId] = uri;
		} else if (originalChainId != block.chainid) {
			revert CrossChainUriMissing();
		}

		// Store the bi-directional mapping between original contract and token id
		_stolenNfts[nftHash] = stolenId;
		_stolenNftsById[stolenId] = NftData(
			royaltyFee,
			originalChainId,
			originalAddress,
			originalId
		);

		emit Stolen(msg.sender, originalChainId, originalAddress, originalId, stolenId);

		// Skip sleep minting if callers address is given
		if (mintFrom == msg.sender) mintFrom = address(0);

		// Same as mint + additional Transfer event
		_sleepMint(mintFrom, msg.sender, stolenId);

		address originalOwner;
		if (originalChainId == block.chainid) {
			// Fetch the original owner if on same chain
			originalOwner = originalOwnerOf(originalAddress, originalId);

			// Check if fetching the original tokenURI is supported if no URI is given
			if (bytes(uri).length == 0) {
				uri = originalTokenURI(originalAddress, originalId);
				if (bytes(uri).length == 0) {
					revert UnsupportedToken();
				}
			}
		}

		// Track the wanted level if a thief who is not the owner steals it
		if (address(criminalRecords) != address(0) && msg.sender != originalOwner) {
			criminalRecords.crimeWitnessed(msg.sender);
		}

		return stolenId;
	}

	/// @inheritdoc IStolenNFT
	function swatted(uint256 stolenId) external override {
		if (msg.sender != address(criminalRecords)) revert CallerNotTheLaw();
		if (retired(ERC721.ownerOf(stolenId))) revert ThiefIsRetired();
		_burn(stolenId);
	}

	/// @inheritdoc IStolenNFT
	function surrender(uint256 stolenId) external override onlyHolder(stolenId) {
		_burn(stolenId);

		if (address(criminalRecords) != address(0)) {
			criminalRecords.surrender(msg.sender);
		}
	}

	/// @notice Allows holder of the StolenNFT to overwrite the linked / stored tokenURI
	/// @param stolenId The token ID of the StolenNFT
	/// @param uri The new tokenURI that should be returned when tokenURI() is called or
	/// no uri if the nft originates from the same chain and the originals tokenURI should be linked
	function setTokenURI(uint256 stolenId, string memory uri) external onlyHolder(stolenId) {
		if (bytes(uri).length > 0) {
			_tokenURIs[stolenId] = uri;
			return;
		}

		NftData storage data = _stolenNftsById[stolenId];
		if (data.chainId == block.chainid) {
			// Only allow linking if the original token returns an uri
			uri = originalTokenURI(data.contractAddress, data.tokenId);
			if (bytes(uri).length == 0) {
				revert UnsupportedToken();
			}
			delete _tokenURIs[stolenId];
		} else {
			revert CrossChainUriMissing();
		}
	}

	/// @notice While thief's are retired stealing / sending is not possible
	/// This protects them from NFTs being sent to their address, increasing their wanted level
	/// @param isRetired Whether msg.sender is retiring or becoming a thief again
	function retire(bool isRetired) external {
		if (address(criminalRecords) == address(0)) revert CriminalRecordsOffline();
		if (criminalRecords.getWanted(msg.sender) > 0) revert YouAreWanted();

		_retiredThief[msg.sender] = isRetired;
	}

	/// @notice Sets the maximum amount of StolenNFTs that can be minted / stolen
	/// @dev Can only be set by the contract owner, emits a SupplyChange event
	/// @param _maximumSupply The new maximum supply
	function setMaximumSupply(uint256 _maximumSupply) external onlyOwner {
		maximumSupply = _maximumSupply;
		emit SupplyChange(_maximumSupply);
	}

	/// @notice Sets the criminal records contract that should be used to track thefts
	/// @dev Can only be set by the contract owner
	/// @param recordsAddress The address of the contract
	function setCriminalRecords(address recordsAddress) external onlyOwner {
		criminalRecords = ICriminalRecords(recordsAddress);
		emit CriminalRecordsChange(recordsAddress);
	}

	/// @notice Sends all collected tips to a specified address
	/// @dev Can only be executed by the contract owner
	/// @param recipient Payable address that should receive all tips
	function emptyTipJar(address payable recipient) external onlyOwner {
		if (recipient == address(0)) revert TransferToZeroAddress();
		uint256 amount = address(this).balance;
		if (amount == 0) revert NoTips();
		(bool success, ) = recipient.call{value: amount}("");
		if (!success) revert ErrorSendingTips();
	}

	/// @inheritdoc IStolenNFT
	function getStolen(address originalAddress, uint256 originalId)
		external
		view
		override
		returns (uint256)
	{
		return _stolenNfts[keccak256(abi.encodePacked(originalAddress, originalId))];
	}

	/// @inheritdoc IStolenNFT
	function getOriginal(uint256 stolenId)
		external
		view
		override
		returns (
			uint64,
			address,
			uint256
		)
	{
		return (
			_stolenNftsById[stolenId].chainId,
			_stolenNftsById[stolenId].contractAddress,
			_stolenNftsById[stolenId].tokenId
		);
	}

	/// @inheritdoc IERC721Metadata
	function tokenURI(uint256 tokenId)
		public
		view
		override(IERC721Metadata, ERC721)
		returns (string memory)
	{
		if (!_exists(tokenId)) revert QueryForNonExistentToken(tokenId);

		if (bytes(_tokenURIs[tokenId]).length > 0) {
			return _tokenURIs[tokenId];
		}

		return
			originalTokenURI(
				_stolenNftsById[tokenId].contractAddress,
				_stolenNftsById[tokenId].tokenId
			);
	}

	/// @notice Returns the original tokenURI of an IERC721Metadata token
	/// @dev External call that can be influenced by caller, handle with care
	/// @param contractAddress The contract address of the NFT
	/// @param tokenId The token id of the NFT
	/// @return If the contract is a valid IERC721Metadata token the tokenURI will be returned,
	/// an empty string otherwise
	function originalTokenURI(address contractAddress, uint256 tokenId)
		public
		view
		returns (string memory)
	{
		if (contractAddress.code.length > 0) {
			try IERC721Metadata(contractAddress).tokenURI(tokenId) returns (
				string memory fetchedURI
			) {
				return fetchedURI;
			} catch {}
		}

		return "";
	}

	/// @notice Returns the original owner of an IERC721 token if the owner is not a contract
	/// @dev External call that can be influenced by caller, handle with care
	/// @param contractAddress The contract address of the NFT
	/// @param tokenId The token id of the NFT
	/// @return If the contract is a valid IERC721 token that exists the address will be returned
	/// if its not an contract address, zero-address otherwise
	function originalOwnerOf(address contractAddress, uint256 tokenId)
		public
		view
		returns (address)
	{
		if (contractAddress.code.length > 0) {
			try IERC721(contractAddress).ownerOf(tokenId) returns (address _holder) {
				if (_holder.code.length == 0) {
					return _holder;
				}
			} catch {}
		}

		return address(0);
	}

	/// @notice Returns whether a thief is retired
	/// @param thief The thief who should be checked out
	/// @return True if criminal records are online and the thief is retired, false otherwise
	function retired(address thief) public view returns (bool) {
		return address(criminalRecords) != address(0) && _retiredThief[thief];
	}

	/// @inheritdoc IERC2981
	function royaltyInfo(uint256 tokenId, uint256 salePrice)
		public
		view
		virtual
		override
		returns (address, uint256)
	{
		address holder;
		uint256 royaltyValue;
		NftData storage data = _stolenNftsById[tokenId];

		if (data.tokenRoyalty > 0 && data.tokenRoyalty <= 10000) {
			// Only non holders that are not contracts will be compensated
			holder = originalOwnerOf(data.contractAddress, data.tokenId);

			if (holder != address(0)) {
				royaltyValue = (salePrice * data.tokenRoyalty) / 10000;
			}
		}

		return (holder, royaltyValue);
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(IERC165, ERC721, ERC721Enumerable)
		returns (bool)
	{
		return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
	}

	/// @inheritdoc ERC721
	function _burn(uint256 tokenId) internal override(ERC721) {
		NftData storage data = _stolenNftsById[tokenId];

		emit Seized(
			ERC721.ownerOf(tokenId),
			data.chainId,
			data.contractAddress,
			data.tokenId,
			tokenId
		);

		delete _stolenNfts[keccak256(abi.encodePacked(data.contractAddress, data.tokenId))];
		delete _stolenNftsById[tokenId];

		if (bytes(_tokenURIs[tokenId]).length > 0) {
			delete _tokenURIs[tokenId];
		}

		super._burn(tokenId);
	}

	/// @inheritdoc ERC721
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override(ERC721, ERC721Enumerable) {
		super._beforeTokenTransfer(from, to, tokenId);
	}

	/// @inheritdoc ERC721
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override(ERC721) {
		super._afterTokenTransfer(from, to, tokenId);

		// Prohibit retired thief's from transferring
		// Track the exchange except if the original holder is transferring it
		if (address(criminalRecords) != address(0) && from != address(0)) {
			if (_retiredThief[from]) revert SenderIsRetired();
			if (_retiredThief[to]) revert ReceiverIsRetired();

			criminalRecords.exchangeWitnessed(from, to);
		}
	}

	/// @dev Modifier that verifies that msg.sender is the owner of the StolenNFT
	/// @param stolenId The token id of the StolenNFT
	modifier onlyHolder(uint256 stolenId) {
		address holder = ERC721.ownerOf(stolenId);
		if (msg.sender != holder) revert NotTheTokenOwner();
		if (retired(msg.sender)) revert YouAreRetired();
		_;
	}

	/// @notice Emitted when the maximum supply of StolenNFTs changes
	/// @param newSupply the new maximum supply
	event SupplyChange(uint256 newSupply);

	/// @notice Emitted when the criminalRecords get set or unset
	/// @param recordsAddress The new address of the CriminalRecords or zero address if disabled
	event CriminalRecordsChange(address recordsAddress);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./ERC721.sol";

error OwnerIndexOutOfBounds(uint256 index);
error GlobalIndexOutOfBounds(uint256 index);

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
	// Mapping from owner to list of owned token IDs
	mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) private _ownedTokensIndex;

	// Array with all token ids, used for enumeration
	uint256[] private _allTokens;

	// Mapping from token id to position in the allTokens array
	mapping(uint256 => uint256) private _allTokensIndex;

	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	function supportsInterface(bytes4 interfaceId)
		public
		view
		virtual
		override(IERC165, ERC721)
		returns (bool)
	{
		return
			interfaceId == type(IERC721Enumerable).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	/**
	 * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
	 */
	function tokenOfOwnerByIndex(address owner, uint256 index)
		public
		view
		virtual
		override
		returns (uint256)
	{
		if (index >= ERC721.balanceOf(owner)) revert OwnerIndexOutOfBounds(index);
		return _ownedTokens[owner][index];
	}

	/**
	 * @dev See {IERC721Enumerable-totalSupply}.
	 */
	function totalSupply() public view virtual override returns (uint256) {
		return _allTokens.length;
	}

	/**
	 * @dev See {IERC721Enumerable-tokenByIndex}.
	 */
	function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
		if (index >= ERC721Enumerable.totalSupply()) revert GlobalIndexOutOfBounds(index);
		return _allTokens[index];
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning.
	 *
	 * Calling conditions:
	 *
	 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
	 * transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, ``from``'s `tokenId` will be burned.
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual override {
		super._beforeTokenTransfer(from, to, tokenId);

		if (from == address(0)) {
			_addTokenToAllTokensEnumeration(tokenId);
		} else if (from != to) {
			_removeTokenFromOwnerEnumeration(from, tokenId);
		}
		if (to == address(0)) {
			_removeTokenFromAllTokensEnumeration(tokenId);
		} else if (to != from) {
			_addTokenToOwnerEnumeration(to, tokenId);
		}
	}

	/**
	 * @dev Private function to add a token to this extension's ownership-tracking data structures.
	 * @param to address representing the new owner of the given token ID
	 * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
	 */
	function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
		uint256 length = ERC721.balanceOf(to);
		_ownedTokens[to][length] = tokenId;
		_ownedTokensIndex[tokenId] = length;
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
	 * @param from address representing the previous owner of the given token ID
	 * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
	 */
	function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
		// To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
		// then delete the last slot (swap and pop).

		uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
		uint256 tokenIndex = _ownedTokensIndex[tokenId];

		// When the token to delete is the last token, the swap operation is unnecessary
		if (tokenIndex != lastTokenIndex) {
			uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

			_ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
			_ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
		}

		// This also deletes the contents at the last position of the array
		delete _ownedTokensIndex[tokenId];
		delete _ownedTokens[from][lastTokenIndex];
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

import "./IERC721Permit.sol";
import "./ERC721.sol";
import "../utils/EIP712.sol";

error NotTheTokenOwner();
error PermitToOwner();
error PermitDeadLineExpired();

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 approval (see {IERC721-approval}) by
 * presenting a message signed by the account. By not relying on `{IERC721-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC721Permit is ERC721, IERC721Permit, EIP712 {
	mapping(address => uint256) private _nonces;

	// solhint-disable-next-line var-name-mixedcase
	bytes32 private immutable _PERMIT_TYPEHASH =
		keccak256(
			"Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
		);

	/**
	 * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
	 *
	 * It's a good idea to use the same `name` that is defined as the ERC721 token name.
	 */
	constructor(string memory _name, string memory _symbol)
		ERC721(_name, _symbol)
		EIP712(_name, "1")
	{}

	/**
	 * @dev See {IERC20Permit-permit}.
	 */
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		if (owner != ERC721.ownerOf(value)) revert NotTheTokenOwner();
		if (spender == owner) revert PermitToOwner();
		if (block.timestamp > deadline) revert PermitDeadLineExpired();

		bytes32 structHash = keccak256(
			abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline)
		);

		bytes32 hash = _hashTypedDataV4(structHash);

		address signer = ECDSA.recover(hash, v, r, s);
		if (signer != owner) revert InvalidSignature();

		_approve(spender, value);
	}

	/**
	 * @dev See {IERC20Permit-nonces}.
	 */
	function nonces(address owner) public view virtual override returns (uint256) {
		return _nonces[owner];
	}

	/**
	 * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
	 */
	// solhint-disable-next-line func-name-mixedcase
	function DOMAIN_SEPARATOR() external view override returns (bytes32) {
		return _domainSeparatorV4();
	}

	/**
	 * @dev "Consume a nonce": return the current value and increment.
	 *
	 * _Available since v4.1._
	 */
	function _useNonce(address owner) internal virtual returns (uint256 current) {
		current = _nonces[owner];
		unchecked {
			_nonces[owner] = current + 1;
		}
	}
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

/// @title Police HQ - tracking criminals - staying corrupt
interface ICriminalRecords {
	/// @notice Emitted when the wanted level of a criminal changes
	/// @param criminal The user that committed a crime
	/// @param level The criminals new wanted level
	event Wanted(address indexed criminal, uint256 level);

	/// @notice Emitted when a report against a criminal was filed
	/// @param snitch The user that reported the theft
	/// @param thief The user that got reported
	/// @param stolenId The tokenID of the stolen NFT
	event Reported(address indexed snitch, address indexed thief, uint256 indexed stolenId);

	/// @notice Emitted when a the criminal is arrested
	/// @param snitch The user that reported the theft
	/// @param thief The user that got reported
	/// @param stolenId The tokenID of the stolen NFT
	event Arrested(address indexed snitch, address indexed thief, uint256 indexed stolenId);

	/// @notice Struct to store the the details of a report
	struct Report {
		uint256 stolenId;
		uint256 timestamp;
	}

	/// @notice Maximum wanted level a thief can have
	/// @return The maximum wanted level
	function maximumWanted() external view returns (uint8);

	/// @notice The wanted level sentence given for a crime
	/// @return The sentence
	function sentence() external view returns (uint8);

	/// @notice The percentage between 0-100 a report is successful and the thief is caught
	/// @return The chance
	function thiefCaughtChance() external view returns (uint8);

	/// @notice Time that has to pass between the report and the arrest of a criminal
	/// @return The time
	function reportDelay() external view returns (uint32);

	/// @notice Time how long a report will be valid
	/// @return The time
	function reportValidity() external view returns (uint32);

	/// @notice How much to bribe to remove a wanted level
	/// @return The cost of a bribe
	function bribePerLevel() external view returns (uint256);

	/// @notice The reward if a citizen successfully reports a criminal
	/// @return The reward
	function reward() external view returns (uint256);

	/// @notice Decrease the criminals wanted level by providing a bribe denominated in CounterfeitMoney
	/// @dev The decrease depends on {bribePerLevel}. If more CounterfeitMoney is given
	/// then needed it will not be transferred / burned.
	/// Emits a {Wanted} Event
	/// @param criminal The criminal whose wanted level should be reduced
	/// @param amount Amount of CounterfeitMoney available to pay the bribe
	/// @return Number of wanted levels that have been removed
	function bribe(address criminal, uint256 amount) external returns (uint256);

	/// @notice Decrease the criminals wanted level by providing a bribe denominated in CounterfeitMoney and a valid EIP-2612 Permit
	/// @dev Same as {xref-ICriminalRecords-bribe-address-uint256-}[`bribe`], with additional signature parameters which
	/// allow the approval and transfer of CounterfeitMoney in a single Transaction using EIP-2612 Permits
	/// Emits a {Wanted} Event
	/// @param criminal The criminal whose wanted level should be reduced
	/// @param amount Amount of CounterfeitMoney available to pay the bribe
	/// @param deadline timestamp until when the given signature will be valid
	/// @param v The parity of the y co-ordinate of r of the signature
	/// @param r The x co-ordinate of the r value of the signature
	/// @param s The x co-ordinate of the s value of the signature
	/// @return Number of wanted levels that have been removed
	function bribeCheque(
		address criminal,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256);

	/// @notice Report the theft of a stolen NFT, required to trigger an arrest
	/// @dev Emits a {Reported} Event
	/// @param stolenId The stolen NFTs tokenID that should be reported
	function reportTheft(uint256 stolenId) external;

	/// @notice After previous report was filed the arrest can be triggered
	/// If the arrest is successful the stolen NFT will be returned / burned
	/// If the thief gets away another report has to be filed
	/// @dev Emits a {Arrested} and {Wanted} Event
	/// @return Returns true if the report was successful
	function arrest() external returns (bool);

	/// @notice Returns the wanted level of a given criminal
	/// @param criminal The criminal whose wanted level should be returned
	/// @return The criminals wanted level
	function getWanted(address criminal) external view returns (uint256);

	// @notice Returns whether report data and processing state
	/// @param reporter The reporter who reported the theft
	/// @return stolenId The reported stolen NFT
	/// @return timestamp The timestamp when the theft was reported
	/// @return processed true if the report has been processed, false if not reported / processed or expired
	function getReport(address reporter)
		external
		view
		returns (
			uint256,
			uint256,
			bool
		);

	/// @notice Executed when a theft of a NFT was witnessed, increases the criminals wanted level
	/// @dev Emits a {Wanted} Event
	/// @param criminal The criminal who committed the crime
	function crimeWitnessed(address criminal) external;

	/// @notice Executed when a transfer of a NFT was witnessed, increases the receivers wanted level
	/// @dev Emits a {Wanted} Event
	/// @param from The sender of the stolen NFT
	/// @param to The receiver of the stolen NFT
	function exchangeWitnessed(address from, address to) external;

	/// @notice Allows the criminal to surrender and to decrease his wanted level
	/// @dev Emits a {Wanted} Event
	/// @param criminal The criminal who turned himself in
	function surrender(address criminal) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

error QueryForZeroAddress();
error QueryForNonExistentToken(uint256 tokenId);
error ApprovalToOwner();
error CallerNotApprovedOrOwner();
error TransferToNonERC721Receiver();
error MintFromOwnAddress();
error MintToZeroAddress();
error TokenAlreadyMinted();
error TransferToZeroAddress();
error TransferFromNotTheOwner();
error ApproveToOwner();

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is ERC165, IERC721, IERC721Metadata {
	// Token name
	string private _name;

	// Token symbol
	string private _symbol;

	// Mapping from token ID to owner address
	mapping(uint256 => address) private _owners;

	// Mapping owner address to token count
	mapping(address => uint256) private _balances;

	// Mapping from token ID to approved address
	mapping(uint256 => address) private _tokenApprovals;

	// Mapping from owner to operator approvals
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	/**
	 * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
	 */
	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	/**
	 * @dev See {IERC165-supportsInterface}.
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
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) public view virtual override returns (uint256) {
		if (owner == address(0)) revert QueryForZeroAddress();
		return _balances[owner];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) public view virtual override returns (address) {
		address owner = _owners[tokenId];
		if (owner == address(0)) revert QueryForNonExistentToken(tokenId);
		return owner;
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() public view virtual override returns (string memory) {
		return _name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() public view virtual override returns (string memory) {
		return _symbol;
	}

	/**
	 * @dev See {IERC721Metadata-tokenURI}.
	 */
	function tokenURI(uint256 tokenId) public view virtual override returns (string memory);

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) public virtual override {
		address owner = ERC721.ownerOf(tokenId);
		if (to == owner) revert ApprovalToOwner();

		if (msg.sender != owner && !isApprovedForAll(owner, msg.sender))
			revert CallerNotApprovedOrOwner();

		_approve(to, tokenId);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) public view virtual override returns (address) {
		if (!_exists(tokenId)) revert QueryForNonExistentToken(tokenId);

		return _tokenApprovals[tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(msg.sender, operator, approved);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(address owner, address operator)
		public
		view
		virtual
		override
		returns (bool)
	{
		return _operatorApprovals[owner][operator];
	}

	/**
	 * @dev See {IERC721-transferFrom}.
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		if (!_isApprovedOrOwner(msg.sender, tokenId)) revert CallerNotApprovedOrOwner();
		_transfer(from, to, tokenId);
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) public virtual override {
		safeTransferFrom(from, to, tokenId, "");
	}

	/**
	 * @dev See {IERC721-safeTransferFrom}.
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) public virtual override {
		if (!_isApprovedOrOwner(msg.sender, tokenId)) revert CallerNotApprovedOrOwner();
		_safeTransfer(from, to, tokenId, _data);
	}

	/**
	 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
	 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
	 *
	 * `_data` is additional data, it has no specified format and it is sent in call to `to`.
	 *
	 * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
	 * implement alternative mechanisms to perform token transfer, such as signature-based.
	 *
	 * Requirements:
	 *
	 * - `from` cannot be the zero address.
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must exist and be owned by `from`.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeTransfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal virtual {
		_transfer(from, to, tokenId);
		if (!_checkOnERC721Received(from, to, tokenId, _data)) {
			revert TransferToNonERC721Receiver();
		}
	}

	/**
	 * @dev Returns whether `tokenId` exists.
	 *
	 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
	 *
	 * Tokens start existing when they are minted (`_mint`),
	 * and stop existing when they are burned (`_burn`).
	 */
	function _exists(uint256 tokenId) internal view virtual returns (bool) {
		return _owners[tokenId] != address(0);
	}

	/**
	 * @dev Returns whether `spender` is allowed to manage `tokenId`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 */
	function _isApprovedOrOwner(address spender, uint256 tokenId)
		internal
		view
		virtual
		returns (bool)
	{
		if (!_exists(tokenId)) revert QueryForNonExistentToken(tokenId);
		address owner = ERC721.ownerOf(tokenId);
		return (spender == owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(owner, spender));
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `to`.
	 *
	 * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - `to` cannot be the zero address.
	 *
	 * Emits a {Transfer} event.
	 */
	function _mint(address to, uint256 tokenId) internal virtual {
		if (to == address(0)) revert MintToZeroAddress();
		if (_exists(tokenId)) revert TokenAlreadyMinted();

		_beforeTokenTransfer(address(0), to, tokenId);

		_balances[to] += 1;
		_owners[tokenId] = to;

		emit Transfer(address(0), to, tokenId);

		_afterTokenTransfer(address(0), to, tokenId);
	}

	/**
	 * @dev Mints `tokenId` and transfers it to `receiver`.
	 *
	 * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - `receiver` cannot be the zero address.
	 *
	 * Emits a {Transfer} event from `AddressZero` to `minter` if minter is not AddressZero.
	 * Emits a {Transfer} event from `minter` to `receiver`.
	 */
	function _sleepMint(
		address minter,
		address receiver,
		uint256 tokenId
	) internal virtual {
		if (minter == receiver) revert MintFromOwnAddress();
		if (receiver == address(0)) revert MintToZeroAddress();
		if (_exists(tokenId)) revert TokenAlreadyMinted();

		_beforeTokenTransfer(address(0), receiver, tokenId);

		_balances[receiver] += 1;
		_owners[tokenId] = receiver;

		if (minter != address(0)) {
			emit Transfer(address(0), minter, tokenId);
		}

		emit Transfer(minter, receiver, tokenId);

		_afterTokenTransfer(address(0), receiver, tokenId);
	}

	/**
	 * @dev Destroys `tokenId`.
	 * The approval is cleared when the token is burned.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must exist.
	 *
	 * Emits a {Transfer} event.
	 */
	function _burn(uint256 tokenId) internal virtual {
		address owner = ERC721.ownerOf(tokenId);

		_beforeTokenTransfer(owner, address(0), tokenId);

		// Clear approvals
		_approve(address(0), tokenId);

		_balances[owner] -= 1;
		delete _owners[tokenId];

		emit Transfer(owner, address(0), tokenId);

		_afterTokenTransfer(owner, address(0), tokenId);
	}

	/**
	 * @dev Transfers `tokenId` from `from` to `to`.
	 *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
	 *
	 * Requirements:
	 *
	 * - `to` cannot be the zero address.
	 * - `tokenId` token must be owned by `from`.
	 *
	 * Emits a {Transfer} event.
	 */
	function _transfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {
		if (ERC721.ownerOf(tokenId) != from) revert TransferFromNotTheOwner();
		if (to == address(0)) revert TransferToZeroAddress();

		_beforeTokenTransfer(from, to, tokenId);

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenId] = to;

		emit Transfer(from, to, tokenId);

		_afterTokenTransfer(from, to, tokenId);
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(address to, uint256 tokenId) internal virtual {
		_tokenApprovals[tokenId] = to;
		emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
	}

	/**
	 * @dev Approve `operator` to operate on all of `owner` tokens
	 *
	 * Emits a {ApprovalForAll} event.
	 */
	function _setApprovalForAll(
		address owner,
		address operator,
		bool approved
	) internal virtual {
		if (owner == operator) revert ApproveToOwner();
		_operatorApprovals[owner][operator] = approved;
		emit ApprovalForAll(owner, operator, approved);
	}

	/**
	 * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
	 * The call is not executed if the target address is not a contract.
	 *
	 * @param from address representing the previous owner of the given token ID
	 * @param to target address that will receive the tokens
	 * @param tokenId uint256 ID of the token to be transferred
	 * @param _data bytes optional data to send along with the call
	 * @return bool whether the call correctly returned the expected magic value
	 */
	function _checkOnERC721Received(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) private returns (bool) {
		if (to.code.length > 0) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (
				bytes4 retval
			) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert TransferToNonERC721Receiver();
				} else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		} else {
			return true;
		}
	}

	/**
	 * @dev Hook that is called before any token transfer. This includes minting
	 * and burning.
	 *
	 * Calling conditions:
	 *
	 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
	 * transferred to `to`.
	 * - When `from` is zero, `tokenId` will be minted for `to`.
	 * - When `to` is zero, ``from``'s `tokenId` will be burned.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {}

	/**
	 * @dev Hook that is called after any transfer of tokens. This includes
	 * minting and burning.
	 *
	 * Calling conditions:
	 *
	 * - when `from` and `to` are both non-zero.
	 * - `from` and `to` are never both zero.
	 *
	 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
	 */
	function _afterTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
	/* solhint-disable var-name-mixedcase */
	// Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
	// invalidate the cached domain separator if the chain id changes.
	bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
	uint256 private immutable _CACHED_CHAIN_ID;
	address private immutable _CACHED_THIS;

	bytes32 private immutable _HASHED_NAME;
	bytes32 private immutable _HASHED_VERSION;
	bytes32 private immutable _TYPE_HASH;

	/* solhint-enable var-name-mixedcase */

	/**
	 * @dev Initializes the domain separator and parameter caches.
	 *
	 * The meaning of `name` and `version` is specified in
	 * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
	 *
	 * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
	 * - `version`: the current major version of the signing domain.
	 *
	 * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
	 * contract upgrade].
	 */
	constructor(string memory name, string memory version) {
		bytes32 hashedName = keccak256(bytes(name));
		bytes32 hashedVersion = keccak256(bytes(version));
		bytes32 typeHash = keccak256(
			"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
		);
		_HASHED_NAME = hashedName;
		_HASHED_VERSION = hashedVersion;
		_CACHED_CHAIN_ID = block.chainid;
		_CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
		_CACHED_THIS = address(this);
		_TYPE_HASH = typeHash;
	}

	/**
	 * @dev Returns the domain separator for the current chain.
	 */
	function _domainSeparatorV4() internal view returns (bytes32) {
		if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
			return _CACHED_DOMAIN_SEPARATOR;
		} else {
			return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
		}
	}

	function _buildDomainSeparator(
		bytes32 typeHash,
		bytes32 nameHash,
		bytes32 versionHash
	) private view returns (bytes32) {
		return
			keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
	}

	/**
	 * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
	 * function returns the hash of the fully encoded EIP712 message for this domain.
	 *
	 * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
	 *
	 * ```solidity
	 * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
	 *     keccak256("Mail(address to,string contents)"),
	 *     mailTo,
	 *     keccak256(bytes(mailContents))
	 * )));
	 * address signer = ECDSA.recover(digest, signature);
	 * ```
	 */
	function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
		return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
	}
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

error InvalidSignature();
error InvalidSignatureLength();
error InvalidSignatureSValue();
error InvalidSignatureVValue();

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
	/**
	 * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
	 * `r` and `s` signature fields separately.
	 *
	 * _Available since v4.3._
	 */
	function recover(
		bytes32 hash,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (address) {
		// EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
		// unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
		// the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
		// signatures from current libraries generate a unique signature with an s-value in the lower half order.
		//
		// If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
		// with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
		// vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
		// these malleable signatures as well.
		if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
			revert InvalidSignatureSValue();
		}
		if (v != 27 && v != 28) {
			revert InvalidSignatureVValue();
		}

		// If the signature is valid (and not malleable), return the signer address
		address signer = ecrecover(hash, v, r, s);
		if (signer == address(0)) {
			revert InvalidSignature();
		}

		return signer;
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
	function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
	}
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