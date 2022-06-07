// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import {LibERC721} from '../libraries/LibERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibSplits} from '../libraries/LibSplits.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, Chain, MeemProperties, PropertyType, PermissionType, MeemPermission, Split, IMeemSplitsStandard} from '../interfaces/MeemStandard.sol';
import {IRoyaltiesProvider} from '../../royalties/IRoyaltiesProvider.sol';
import {RoyaltiesV2} from '../../royalties/RoyaltiesV2.sol';
import {LibPart} from '../../royalties/LibPart.sol';

contract MeemSplitsFacet is RoyaltiesV2, IMeemSplitsStandard {
	function getRaribleV2Royalties(uint256 tokenId)
		external
		view
		override
		returns (LibPart.Part[] memory)
	{
		return LibSplits.getRaribleV2Royalties(tokenId);
	}

	function nonOwnerSplitAllocationAmount()
		external
		view
		override
		returns (uint256)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.nonOwnerSplitAllocationAmount;
	}

	function lockSplits(uint256 tokenId, PropertyType propertyType)
		external
		override
	{
		LibSplits.lockSplits(tokenId, propertyType);
	}

	function setSplits(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] memory splits
	) external override {
		LibSplits.setSplits(tokenId, propertyType, splits);
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) external override {
		LibSplits.addSplit(tokenId, propertyType, split);
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) external override {
		LibSplits.removeSplitAt(tokenId, propertyType, idx);
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) external override {
		LibSplits.updateSplitAt(tokenId, propertyType, idx, split);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {Array} from '../utils/Array.sol';
import {LibMeem} from '../libraries/LibMeem.sol';
import {LibAccessControl} from '../libraries/LibAccessControl.sol';
import {Meem, MeemType, URISource} from '../interfaces/MeemStandard.sol';
import {Error} from '../libraries/Errors.sol';
import {MeemERC721Events} from '../libraries/Events.sol';
import '../interfaces/IERC721TokenReceiver.sol';
import {Base64} from '../utils/Base64.sol';

library LibERC721 {
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

	bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

	function requireOwnsToken(uint256 tokenId) internal view {
		if (ownerOf(tokenId) != msg.sender) {
			revert(Error.NotTokenOwner);
		}
	}

	function burn(uint256 tokenId) internal {
		requireOwnsToken(tokenId);

		address owner = ownerOf(tokenId);

		// Clear approvals
		_approve(address(0), tokenId);

		updateStorageMappingsForTokenTransfer(owner, address(0), tokenId);

		emit Transfer(owner, address(0), tokenId);
		emit MeemERC721Events.MeemTransfer(owner, address(0), tokenId);
	}

	///@notice Query the universal totalSupply of all NFTs ever minted
	///@return totalSupply_ the number of all NFTs that have been minted
	function totalSupply() internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.allTokens.length;
	}

	/**
	 * @dev See {IERC721-balanceOf}.
	 */
	function balanceOf(address owner) internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (owner == address(0)) {
			revert(Error.InvalidZeroAddressQuery);
		}
		return s.ownerTokenIds[owner].length;
	}

	/// @notice Enumerate valid NFTs
	/// @dev Throws if `_index` >= `totalSupply()`.
	/// @param _index A counter less than `totalSupply()`
	/// @return tokenId_ The token identifier for the `_index`th NFT,
	///  (sort order not specified)
	function tokenByIndex(uint256 _index)
		internal
		view
		returns (uint256 tokenId_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (_index >= s.allTokens.length) {
			revert(Error.IndexOutOfRange);
		}
		tokenId_ = s.allTokens[_index];
	}

	/// @notice Enumerate NFTs assigned to an owner
	/// @dev Throws if `_index` >= `balanceOf(_owner)` or if
	///  `_owner` is the zero address, representing invalid NFTs.
	/// @param _owner An address where we are interested in NFTs owned by them
	/// @param _index A counter less than `balanceOf(_owner)`
	/// @return tokenId_ The token identifier for the `_index`th NFT assigned to `_owner`,
	///   (sort order not specified)
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		internal
		view
		returns (uint256 tokenId_)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (_index >= s.ownerTokenIds[_owner].length) {
			revert(Error.IndexOutOfRange);
		}
		tokenId_ = s.ownerTokenIds[_owner][_index];
	}

	/**
	 * @dev See {IERC721-ownerOf}.
	 */
	function ownerOf(uint256 tokenId) internal view returns (address) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		address owner = s.meems[tokenId].owner;
		if (owner == address(0)) {
			revert(Error.TokenNotFound);
		}
		return owner;
	}

	/**
	 * @dev See {IERC721Metadata-name}.
	 */
	function name() internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.name;
	}

	/**
	 * @dev See {IERC721Metadata-symbol}.
	 */
	function symbol() internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.symbol;
	}

	function tokenURI(uint256 tokenId) internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!_exists(tokenId)) {
			revert(Error.TokenNotFound);
		}

		if (s.meems[tokenId].uriSource == URISource.JSON) {
			return
				string(
					abi.encodePacked(
						'data:application/json;base64,',
						Base64.encode(bytes(s.tokenURIs[tokenId]))
					)
				);
		}

		return s.tokenURIs[tokenId];
	}

	/**
	 * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
	 * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
	 * by default, can be overriden in child contracts.
	 */
	function _baseURI() internal pure returns (string memory) {
		return '';
	}

	function baseTokenURI() internal pure returns (string memory) {
		return 'https://meem.wtf/tokens/';
	}

	/**
	 * @dev See {IERC721-approve}.
	 */
	function approve(address to, uint256 tokenId) internal {
		address owner = ownerOf(tokenId);

		if (to == owner) {
			revert(Error.NoApproveSelf);
		}

		if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
			revert(Error.NotApproved);
		}

		_approve(to, tokenId);
	}

	/**
	 * @dev See {IERC721-getApproved}.
	 */
	function getApproved(uint256 tokenId) internal view returns (address) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!_exists(tokenId)) {
			revert(Error.TokenNotFound);
		}

		return s.tokenApprovals[tokenId];
	}

	/**
	 * @dev See {IERC721-setApprovalForAll}.
	 */
	function setApprovalForAll(address operator, bool approved) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (operator == _msgSender()) {
			revert(Error.NoApproveSelf);
		}

		s.operatorApprovals[_msgSender()][operator] = approved;
		emit ApprovalForAll(_msgSender(), operator, approved);
		emit MeemERC721Events.MeemApprovalForAll(
			_msgSender(),
			operator,
			approved
		);
	}

	/**
	 * @dev See {IERC721-isApprovedForAll}.
	 */
	function isApprovedForAll(address owner, address operator)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.operatorApprovals[owner][operator];
	}

	// /**
	//  * @dev See {IERC721-transferFrom}.
	//  */
	// function transferFrom(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId
	// ) internal {
	// 	if (
	// 		// !_isApprovedOrOwner(_msgSender(), tokenId) &&
	// 		!_canFacilitateClaim(_msgSender(), tokenId)
	// 	) {
	// 		revert(Error.NotApproved);
	// 	}

	// 	_transfer(from, to, tokenId);
	// }

	// /**
	//  * @dev See {IERC721-safeTransferFrom}.
	//  */
	// function safeTransferFrom(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId
	// ) internal {
	// 	safeTransferFrom(from, to, tokenId, '');
	// }

	// /**
	//  * @dev See {IERC721-safeTransferFrom}.
	//  */
	// function safeTransferFrom(
	// 	address from,
	// 	address to,
	// 	uint256 tokenId,
	// 	bytes memory _data
	// ) internal {
	// 	if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
	// 		revert(Error.NotApproved);
	// 	}

	// 	_safeTransfer(from, to, tokenId, _data);
	// }

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
	function safeTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		safeTransfer(from, to, tokenId, '');
	}

	function safeTransfer(
		address from,
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		transfer(from, to, tokenId);

		if (!_checkOnERC721Received(from, to, tokenId, _data)) {
			revert(Error.ERC721ReceiverNotImplemented);
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
	function _exists(uint256 tokenId) internal view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.mintedTokens[tokenId];
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
		returns (bool)
	{
		if (!_exists(tokenId)) {
			revert(Error.TokenNotFound);
		}
		address _owner = ownerOf(tokenId);
		return (spender == _owner ||
			getApproved(tokenId) == spender ||
			isApprovedForAll(_owner, spender));
	}

	/**
	 * @dev Safely mints `tokenId` and transfers it to `to`.
	 *
	 * Requirements:
	 *
	 * - `tokenId` must not exist.
	 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
	 *
	 * Emits a {Transfer} event.
	 */
	function _safeMint(address to, uint256 tokenId) internal {
		_safeMint(to, tokenId, '');
	}

	/**
	 * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
	 * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
	 */
	function _safeMint(
		address to,
		uint256 tokenId,
		bytes memory _data
	) internal {
		_mint(to, tokenId);

		if (!_checkOnERC721Received(address(0), to, tokenId, _data)) {
			revert(Error.ERC721ReceiverNotImplemented);
		}
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
	function _mint(address to, uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (to == address(0)) {
			revert(Error.ToAddressInvalid);
		}

		if (_exists(tokenId)) {
			revert(Error.TokenAlreadyExists);
		}

		s.allTokens.push(tokenId);
		s.allTokensIndex[tokenId] = s.allTokens.length;
		s.ownerTokenIds[to].push(tokenId);
		s.ownerTokenIdIndexes[to][tokenId] = s.ownerTokenIds[to].length - 1;
		s.mintedTokens[tokenId] = true;

		emit Transfer(address(0), to, tokenId);
		emit MeemERC721Events.MeemTransfer(address(0), to, tokenId);
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
	function transfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		bool canFacilitateClaim = _canFacilitateClaim(_msgSender(), tokenId);

		uint256 parentTokenId = s.meems[tokenId].parentTokenId;

		// Meems can be transferred if:
		// 1. They are wrapped and the sender can facilitate claim
		// 2. They are owned by this contract and the sender can facilitate claim
		// 3. They are the owner
		if (
			s.meems[tokenId].meemType == MeemType.Wrapped && !canFacilitateClaim
		) {
			revert(Error.NotTokenAdmin);
		} else if (
			s.meems[tokenId].owner == address(this) && !canFacilitateClaim
		) {
			revert(Error.NotTokenAdmin);
		} else if (ownerOf(tokenId) != from) {
			revert(Error.NotTokenOwner);
		} else if (
			s.meems[tokenId].meemType == MeemType.Original &&
			(!s.baseProperties.isTransferrable ||
				(s.baseProperties.transferLockupUntil > 0 &&
					s.baseProperties.transferLockupUntil > block.timestamp))
		) {
			revert(Error.TransfersLocked);
		} else if (
			(s.meems[tokenId].meemType == MeemType.Remix ||
				s.meems[tokenId].meemType == MeemType.Copy) &&
			(!s.meemProperties[parentTokenId].isTransferrable ||
				(s.meemProperties[parentTokenId].transferLockupUntil > 0 &&
					s.meemProperties[parentTokenId].transferLockupUntil >
					block.timestamp))
		) {
			revert(Error.TransfersLocked);
		}

		if (to == address(0)) {
			revert(Error.ToAddressInvalid);
		}

		// Clear approvals from the previous owner
		_approve(address(0), tokenId);

		updateStorageMappingsForTokenTransfer(from, to, tokenId);

		emit Transfer(from, to, tokenId);
		emit MeemERC721Events.MeemTransfer(from, to, tokenId);
	}

	function updateStorageMappingsForTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (from != address(0)) {
			uint256 idx = s.ownerTokenIdIndexes[from][tokenId];
			s.ownerTokenIds[from] = Array.removeAt(s.ownerTokenIds[from], idx);
			delete s.ownerTokenIdIndexes[from][tokenId];
		}
		s.ownerTokenIds[to].push(tokenId);
		s.ownerTokenIdIndexes[to][tokenId] = s.ownerTokenIds[to].length - 1;
		s.meems[tokenId].owner = to;

		if (s.meems[tokenId].meemType == MeemType.Original) {
			s.originalOwnerTokens[from][tokenId] = false;
			s.originalOwnerTokens[to][tokenId] = true;
			s.originalOwnerCount[from]--;
			s.originalOwnerCount[to]++;
		} else if (s.meems[tokenId].meemType == MeemType.Copy) {
			uint256 parentTokenId = s.meems[tokenId].parentTokenId;
			if (from != address(0)) {
				uint256 idx = s.copiesOwnerTokenIndexes[from][parentTokenId];
				s.copiesOwnerTokens[parentTokenId][from] = Array.removeAt(
					s.copiesOwnerTokens[parentTokenId][from],
					idx
				);
				delete s.copiesOwnerTokenIndexes[from][parentTokenId];
			}
			s.copiesOwnerTokens[parentTokenId][to].push(tokenId);
			s.copiesOwnerTokenIndexes[to][parentTokenId] =
				s.copiesOwnerTokens[parentTokenId][to].length -
				1;
		} else if (s.meems[tokenId].meemType == MeemType.Wrapped) {
			// TODO: keep track of wrapped
		} else if (s.meems[tokenId].meemType == MeemType.Remix) {
			uint256 parentTokenId = s.meems[tokenId].parentTokenId;
			if (from != address(0)) {
				uint256 idx = s.remixesOwnerTokenIndexes[from][parentTokenId];
				s.remixesOwnerTokens[parentTokenId][from] = Array.removeAt(
					s.remixesOwnerTokens[parentTokenId][from],
					idx
				);
				delete s.remixesOwnerTokenIndexes[from][parentTokenId];
			}
			s.remixesOwnerTokens[parentTokenId][to].push(tokenId);
			s.remixesOwnerTokenIndexes[to][parentTokenId] =
				s.remixesOwnerTokens[parentTokenId][to].length -
				1;
		}
	}

	/**
	 * @dev Approve `to` to operate on `tokenId`
	 *
	 * Emits a {Approval} event.
	 */
	function _approve(address to, uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		s.tokenApprovals[tokenId] = to;
		emit Approval(ownerOf(tokenId), to, tokenId);
		emit MeemERC721Events.MeemApproval(ownerOf(tokenId), to, tokenId);
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
	) internal returns (bool) {
		if (isContract(to)) {
			try
				IERC721TokenReceiver(to).onERC721Received(
					_msgSender(),
					from,
					tokenId,
					_data
				)
			returns (bytes4 retval) {
				return retval == IERC721TokenReceiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert(Error.ERC721ReceiverNotImplemented);
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

	function _checkOnERC721Received(
		address _operator,
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) internal {
		uint256 size;
		assembly {
			size := extcodesize(_to)
		}
		if (size > 0) {
			require(
				ERC721_RECEIVED ==
					IERC721TokenReceiver(_to).onERC721Received(
						_operator,
						_from,
						_tokenId,
						_data
					),
				'LibERC721: Transfer rejected/failed by _to'
			);
		}
	}

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	/**
	 * @dev Returns true if `account` is a contract.
	 *
	 * [IMPORTANT]
	 * ====
	 * It is unsafe to assume that an address for which this function returns
	 * false is an externally-owned account (EOA) and not a contract.
	 *
	 * Among others, `isContract` will return false for the following
	 * types of addresses:
	 *
	 *  - an externally-owned account
	 *  - a contract in construction
	 *  - an address where a contract will be created
	 *  - an address where a contract lived, but was destroyed
	 * ====
	 */
	function isContract(address account) internal view returns (bool) {
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
	}

	function _canFacilitateClaim(address user, uint256 tokenId)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		Meem memory meem = LibMeem.getMeem(tokenId);
		bool isAdmin = LibAccessControl.hasRole(s.ADMIN_ROLE, user);
		if (
			!isAdmin ||
			(meem.parent == address(0) && meem.owner != address(this)) ||
			(meem.parent == address(this) && meem.owner != address(this))
		) {
			// Meem is an original or a child of another meem and can only be transferred by the owner
			return false;
		}

		return true;
	}

	function contractURI() internal view returns (string memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return
			string(
				abi.encodePacked(
					'data:application/json;base64,',
					Base64.encode(bytes(s.contractURI))
				)
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {LibMeta} from '../libraries/LibMeta.sol';
import {MeemBase, MeemProperties, Chain, BaseProperties} from '../interfaces/MeemStandard.sol';

library LibAppStorage {
	bytes32 constant DIAMOND_STORAGE_POSITION =
		keccak256('meemproject.app.storage');

	struct RoleData {
		mapping(address => bool) members;
	}

	struct AppStorage {
		/** AccessControl Role: Admin */
		bytes32 ADMIN_ROLE;
		/** AccessControl Role: Minter */
		bytes32 MINTER_ROLE;
		/** Counter of next incremental token */
		uint256 tokenCounter;
		/** ERC721 Name */
		string name;
		/** ERC721 Symbol */
		string symbol;
		/** Mapping of addresses => all tokens they own */
		mapping(address => uint256[]) ownerTokenIds;
		/** Mapping of addresses => number of tokens owned */
		mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
		/** Mapping of token to approved address */
		mapping(uint256 => address) approved;
		/** Mapping of address to operators */
		mapping(address => mapping(address => bool)) operators;
		/** Mapping of token => Meem data  */
		mapping(uint256 => MeemBase) meems;
		mapping(uint256 => MeemProperties) meemProperties;
		mapping(uint256 => MeemProperties) meemChildProperties;
		/** The minimum amount that must be allocated to non-owners of a token in splits */
		uint256 nonOwnerSplitAllocationAmount;
		/** The contract URI. Used to describe this NFT collection */
		string contractURI;
		/** The depth allowed for minting of children. If 0, no child copies are allowed. */
		int256 childDepth;
		/** Mapping of token => URIs for each token */
		mapping(uint256 => string) tokenURIs;
		/** Mapping of token to all children */
		mapping(uint256 => uint256[]) remixes;
		/** Mapping of token to all decendants */
		mapping(uint256 => uint256[]) decendants;
		/** Keeps track of assigned roles */
		mapping(bytes32 => RoleData) roles;
		/** Mapping from token ID to approved address */
		mapping(uint256 => address) tokenApprovals;
		/** Mapping from owner to operator approvals */
		mapping(address => mapping(address => bool)) operatorApprovals;
		/** All tokenIds that have been minted and the corresponding index in allTokens */
		uint256[] allTokens;
		/** Index of tokenId => allTokens index */
		mapping(uint256 => uint256) allTokensIndex;
		/** Keep track of whether a tokenId has been minted */
		mapping(uint256 => bool) mintedTokens;
		/** Keep track of tokens that have already been wrapped */
		mapping(Chain => mapping(address => mapping(uint256 => uint256))) chainWrappedNFTs;
		/** Mapping of (parent) tokenId to owners and the child tokenIds they own */
		mapping(uint256 => mapping(address => uint256[])) remixesOwnerTokens;
		/** Keep track of original Meems */
		uint256[] originalMeemTokens;
		/** Index of tokenId => allTokens index */
		mapping(uint256 => uint256) originalMeemTokensIndex;
		mapping(uint256 => uint256[]) copies;
		mapping(uint256 => mapping(address => uint256[])) copiesOwnerTokens;
		/** Keep track of "clipped" meems */
		/** tokenId => array of addresses that have clipped */
		mapping(uint256 => address[]) clippings;
		/** address => tokenIds */
		mapping(address => uint256[]) addressClippings;
		/** address => tokenId => index */
		mapping(address => mapping(uint256 => uint256)) clippingsIndex;
		/** address => tokenId => index */
		mapping(address => mapping(uint256 => uint256)) addressClippingsIndex;
		/** address => tokenId => index */
		mapping(address => mapping(uint256 => bool)) hasAddressClipped;
		/** token => reaction name => total */
		mapping(uint256 => mapping(string => uint256)) tokenReactions;
		/** token => reaction name => address => reactedAt */
		mapping(uint256 => mapping(string => mapping(address => uint256))) addressReactionsAt;
		/** address => token => reaction names[] */
		mapping(address => mapping(uint256 => string[])) addressReactions;
		/** address => token => reaction name => index */
		mapping(address => mapping(uint256 => mapping(string => uint256))) addressReactionsIndex;
		BaseProperties baseProperties;
		MeemProperties defaultProperties;
		MeemProperties defaultChildProperties;
		/** Keeping track of original tokens owner -> token -> isOwner */
		mapping(address => mapping(uint256 => bool)) originalOwnerTokens;
		/** Number of original tokens held by a wallet */
		mapping(address => uint256) originalOwnerCount;
		mapping(address => mapping(uint256 => uint256)) copiesOwnerTokenIndexes;
		mapping(address => mapping(uint256 => uint256)) remixesOwnerTokenIndexes;
		/** role -> addresses[] */
		mapping(bytes32 => address[]) rolesList;
		mapping(bytes32 => mapping(address => uint256)) rolesListIndex;
		bool isInitialized;
	}

	function diamondStorage() internal pure returns (AppStorage storage ds) {
		bytes32 position = DIAMOND_STORAGE_POSITION;
		assembly {
			ds.slot := position
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {PropertyType, Split, MeemProperties, MeemType} from '../interfaces/MeemStandard.sol';
import {LibERC721} from './LibERC721.sol';
import {Error} from './Errors.sol';
import {MeemEvents, MeemBaseEvents} from './Events.sol';
import {LibProperties} from './LibProperties.sol';
import {LibPart} from '../../royalties/LibPart.sol';

library LibSplits {
	function lockSplits(uint256 tokenId, PropertyType propertyType) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.splitsLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.splitsLockedBy = msg.sender;
	}

	function setSplits(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] memory splits
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibProperties.requireAccess(tokenId, propertyType);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.splitsLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		validateOverrideSplits(splits, props.splits);

		delete props.splits;

		for (uint256 i = 0; i < splits.length; i++) {
			props.splits.push(splits[i]);
		}
		address tokenOwner = propertyType == PropertyType.Meem ||
			propertyType == PropertyType.Child
			? LibERC721.ownerOf(tokenId)
			: address(0);

		validateSplits(props, tokenOwner, s.nonOwnerSplitAllocationAmount);

		emit MeemEvents.MeemSplitsSet(tokenId, propertyType, props.splits);
		emit MeemEvents.RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function setBaseSplits(Split[] memory newSplits) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		validateOverrideSplits(newSplits, s.baseProperties.splits);

		delete s.baseProperties.splits;

		for (uint256 i = 0; i < newSplits.length; i++) {
			s.baseProperties.splits.push(newSplits[i]);
		}

		validateSplits(
			s.baseProperties.splits,
			address(0),
			s.nonOwnerSplitAllocationAmount
		);

		emit MeemBaseEvents.MeemSplitsSet(s.baseProperties.splits);
	}

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibProperties.requireAccess(tokenId, propertyType);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.splitsLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}
		props.splits.push(split);

		address tokenOwner = propertyType == PropertyType.Meem ||
			propertyType == PropertyType.Child
			? LibERC721.ownerOf(tokenId)
			: address(0);

		validateSplits(props, tokenOwner, s.nonOwnerSplitAllocationAmount);
		emit MeemEvents.MeemSplitsSet(tokenId, propertyType, props.splits);
		emit MeemEvents.RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) internal {
		LibProperties.requireAccess(tokenId, propertyType);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);
		if (props.splitsLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		if (props.splits[idx].lockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		if (idx >= props.splits.length) {
			revert(Error.IndexOutOfRange);
		}

		for (uint256 i = idx; i < props.splits.length - 1; i++) {
			props.splits[i] = props.splits[i + 1];
		}

		props.splits.pop();
		emit MeemEvents.MeemSplitsSet(tokenId, propertyType, props.splits);
		emit MeemEvents.RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibProperties.requireAccess(tokenId, propertyType);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);
		if (props.splitsLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		if (props.splits[idx].lockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.splits[idx] = split;

		address tokenOwner = propertyType == PropertyType.Meem ||
			propertyType == PropertyType.Child
			? LibERC721.ownerOf(tokenId)
			: address(0);

		validateSplits(props, tokenOwner, s.nonOwnerSplitAllocationAmount);
		emit MeemEvents.MeemSplitsSet(tokenId, propertyType, props.splits);
		emit MeemEvents.RoyaltiesSet(tokenId, getRaribleV2Royalties(tokenId));
	}

	function validateSplits(
		Split[] storage currentSplits,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) internal view {
		// Ensure addresses are unique
		for (uint256 i = 0; i < currentSplits.length; i++) {
			address split1 = currentSplits[i].toAddress;

			for (uint256 j = 0; j < currentSplits.length; j++) {
				address split2 = currentSplits[j].toAddress;
				if (i != j && split1 == split2) {
					revert('Split addresses must be unique');
				}
			}
		}

		uint256 totalAmount = 0;
		uint256 totalAmountOfNonOwner = 0;
		// Require that split amounts
		for (uint256 i = 0; i < currentSplits.length; i++) {
			totalAmount += currentSplits[i].amount;
			if (currentSplits[i].toAddress != tokenOwner) {
				totalAmountOfNonOwner += currentSplits[i].amount;
			}
		}

		if (
			totalAmount > 10000 ||
			totalAmountOfNonOwner < nonOwnerSplitAllocationAmount
		) {
			revert(Error.InvalidNonOwnerSplitAllocationAmount);
		}
	}

	function validateSplits(
		MeemProperties storage self,
		address tokenOwner,
		uint256 nonOwnerSplitAllocationAmount
	) internal view {
		// Ensure addresses are unique
		for (uint256 i = 0; i < self.splits.length; i++) {
			address split1 = self.splits[i].toAddress;

			for (uint256 j = 0; j < self.splits.length; j++) {
				address split2 = self.splits[j].toAddress;
				if (i != j && split1 == split2) {
					revert('Split addresses must be unique');
				}
			}
		}

		uint256 totalAmount = 0;
		uint256 totalAmountOfNonOwner = 0;
		// Require that split amounts
		for (uint256 i = 0; i < self.splits.length; i++) {
			totalAmount += self.splits[i].amount;
			if (self.splits[i].toAddress != tokenOwner) {
				totalAmountOfNonOwner += self.splits[i].amount;
			}
		}

		if (
			totalAmount > 10000 ||
			totalAmountOfNonOwner < nonOwnerSplitAllocationAmount
		) {
			revert(Error.InvalidNonOwnerSplitAllocationAmount);
		}
	}

	function validateOverrideSplits(
		Split[] memory baseSplits,
		Split[] memory overrideSplits
	) internal pure {
		for (uint256 i = 0; i < overrideSplits.length; i++) {
			if (overrideSplits[i].lockedBy != address(0)) {
				// Find the permission in basePermissions
				bool wasFound = false;
				for (uint256 j = 0; j < baseSplits.length; j++) {
					if (
						baseSplits[j].lockedBy == overrideSplits[i].lockedBy &&
						baseSplits[j].amount == overrideSplits[i].amount &&
						baseSplits[j].toAddress == overrideSplits[i].toAddress
					) {
						wasFound = true;
						break;
					}
				}
				if (!wasFound) {
					revert(Error.MissingRequiredSplits);
				}
			}
		}
	}

	function getRaribleV2Royalties(uint256 tokenId)
		internal
		view
		returns (LibPart.Part[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		uint256 tokenIdToUse = s.meems[tokenId].meemType == MeemType.Copy
			? s.meems[tokenId].parentTokenId
			: tokenId;

		uint256 numSplits = s.meemProperties[tokenIdToUse].splits.length;
		LibPart.Part[] memory parts = new LibPart.Part[](numSplits);
		for (
			uint256 i = 0;
			i < s.meemProperties[tokenIdToUse].splits.length;
			i++
		) {
			parts[i] = LibPart.Part({
				account: payable(
					s.meemProperties[tokenIdToUse].splits[i].toAddress
				),
				value: uint96(s.meemProperties[tokenIdToUse].splits[i].amount)
			});
		}

		return parts;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {Array} from '../utils/Array.sol';
import {Error} from './Errors.sol';
import {AccessControlEvents} from './Events.sol';

library LibAccessControl {
	/**
	 * @dev See {IERC165-supportsInterface}.
	 */
	// function supportsInterface(bytes4 interfaceId)
	// 	internal
	// 	view
	// 	virtual
	// 	returns (bool)
	// {
	// 	return
	// 		interfaceId == type(IAccessControlUpgradeable).interfaceId ||
	// 		super.supportsInterface(interfaceId);
	// }

	function requireRole(bytes32 role) internal view {
		if (!hasRole(role, msg.sender)) {
			revert(Error.MissingRequiredRole);
		}
	}

	/**
	 * @dev Returns `true` if `account` has been granted `role`.
	 */
	function hasRole(bytes32 role, address account)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.roles[role].members[account];
	}

	/**
	 * @dev Grants `role` to `account`.
	 *
	 * If `account` had not been already granted `role`, emits a {RoleGranted}
	 * event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 */
	function grantRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
		_grantRole(role, account);
	}

	/**
	 * @dev Revokes `role` from `account`.
	 *
	 * If `account` had been granted `role`, emits a {RoleRevoked} event.
	 *
	 * Requirements:
	 *
	 * - the caller must have ``role``'s admin role.
	 */
	function revokeRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
		_revokeRole(role, account);
	}

	/**
	 * @dev Revokes `role` from the calling account.
	 *
	 * Roles are often managed via {grantRole} and {revokeRole}: this function's
	 * purpose is to provide a mechanism for accounts to lose their privileges
	 * if they are compromised (such as when a trusted device is misplaced).
	 *
	 * If the calling account had been granted `role`, emits a {RoleRevoked}
	 * event.
	 *
	 * Requirements:
	 *
	 * - the caller must be `account`.
	 */
	function renounceRole(bytes32 role, address account) internal {
		if (account != msg.sender) {
			revert(Error.NoRenounceOthers);
		}

		_revokeRole(role, account);
	}

	/**
	 * @dev Grants `role` to `account`.
	 *
	 * If `account` had not been already granted `role`, emits a {RoleGranted}
	 * event. Note that unlike {grantRole}, this function doesn't perform any
	 * checks on the calling account.
	 *
	 * [WARNING]
	 * ====
	 * This function should only be called from the constructor when setting
	 * up the initial roles for the system.
	 *
	 * Using this function in any other way is effectively circumventing the admin
	 * system imposed by {AccessControl}.
	 * ====
	 */
	function _setupRole(bytes32 role, address account) internal {
		_grantRole(role, account);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
	 */
	function toHexString(uint256 value) internal pure returns (string memory) {
		if (value == 0) {
			return '0x00';
		}
		uint256 temp = value;
		uint256 length = 0;
		while (temp != 0) {
			length++;
			temp >>= 8;
		}
		return toHexString(value, length);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
	 */
	function toHexString(uint256 value, uint256 length)
		internal
		pure
		returns (string memory)
	{
		bytes16 _HEX_SYMBOLS = '0123456789abcdef';
		bytes memory buffer = new bytes(2 * length + 2);
		buffer[0] = '0';
		buffer[1] = 'x';
		for (uint256 i = 2 * length + 1; i > 1; --i) {
			buffer[i] = _HEX_SYMBOLS[value & 0xf];
			value >>= 4;
		}
		require(value == 0, 'Strings: hex length insufficient');
		return string(buffer);
	}

	function _grantRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (!hasRole(role, account)) {
			s.roles[role].members[account] = true;
			s.rolesList[role].push(account);
			s.rolesListIndex[role][account] = s.rolesList[role].length - 1;
			emit AccessControlEvents.MeemRoleGranted(role, account, msg.sender);
		}
	}

	function _revokeRole(bytes32 role, address account) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (hasRole(role, account)) {
			s.roles[role].members[account] = false;
			uint256 idx = s.rolesListIndex[role][account];
			Array.removeAt(s.rolesList[role], idx);

			emit AccessControlEvents.MeemRoleRevoked(role, account, msg.sender);
		}
	}

	function _setRole(bytes32 role, address[] memory accounts) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		requireRole(s.ADMIN_ROLE);
		for (uint256 i = 0; i < s.rolesList[role].length; i++) {
			address addy = s.rolesList[role][i];
			delete s.rolesListIndex[role][addy];
			s.roles[role].members[addy] = false;
		}
		delete s.rolesList[role];

		for (uint256 i = 0; i < accounts.length; i++) {
			address addy = accounts[i];
			if (!hasRole(role, addy)) {
				s.rolesList[role].push(addy);
				s.rolesListIndex[role][addy] = i;
				s.roles[role].members[addy] = true;
			}
		}

		emit AccessControlEvents.MeemRoleSet(role, accounts, msg.sender);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

enum Chain {
	Ethereum,
	Polygon,
	Cardano,
	Solana,
	Rinkeby
}

enum PermissionType {
	Copy,
	Remix,
	Read
}

enum Permission {
	Owner,
	Anyone,
	Addresses,
	Holders
}

enum PropertyType {
	Meem,
	Child,
	DefaultMeem,
	DefaultChild
}

enum MeemType {
	Original,
	Copy,
	Remix,
	Wrapped
}

enum URISource {
	Url,
	JSON
}

struct Split {
	address toAddress;
	uint256 amount;
	address lockedBy;
}

struct MeemPermission {
	Permission permission;
	address[] addresses;
	uint256 numTokens;
	address lockedBy;
	uint256 costWei;
}

struct MeemProperties {
	int256 totalRemixes;
	address totalRemixesLockedBy;
	int256 remixesPerWallet;
	address remixesPerWalletLockedBy;
	MeemPermission[] copyPermissions;
	MeemPermission[] remixPermissions;
	MeemPermission[] readPermissions;
	address copyPermissionsLockedBy;
	address remixPermissionsLockedBy;
	address readPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
	int256 totalCopies;
	address totalCopiesLockedBy;
	int256 copiesPerWallet;
	address copiesPerWalletLockedBy;
	bool isTransferrable;
	address isTransferrableLockedBy;
	int256 mintStartTimestamp;
	int256 mintEndTimestamp;
	address mintDatesLockedBy;
	uint256 transferLockupUntil;
	address transferLockupUntilLockedBy;
}

struct BaseProperties {
	int256 totalOriginalsSupply;
	address totalOriginalsSupplyLockedBy;
	MeemPermission[] mintPermissions;
	address mintPermissionsLockedBy;
	Split[] splits;
	address splitsLockedBy;
	int256 originalsPerWallet;
	address originalsPerWalletLockedBy;
	bool isTransferrable;
	address isTransferrableLockedBy;
	int256 mintStartTimestamp;
	int256 mintEndTimestamp;
	address mintDatesLockedBy;
	uint256 transferLockupUntil;
	address transferLockupUntilLockedBy;
}

// struct BasePropertiesInit {
// 	int256 totalOriginalsSupply;
// 	bool isTotalOriginalsSupplyLocked;
// 	MeemPermission[] mintPermissions;
// 	bool isMintPermissionsLocked;
// 	Split[] splits;
// 	bool isSplitsLocked;
// 	int256 originalsPerWallet;
// 	bool isOriginalsPerWalletLocked;
// 	bool isTransferrable;
// 	bool isIsTransferrableLocked;
// 	int256 mintStartTimestamp;
// 	int256 mintEndTimestamp;
// 	bool isMintDatesLocked;
// }

struct MeemBase {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	uint256 mintedAt;
	string data;
	address uriLockedBy;
	MeemType meemType;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct Meem {
	address owner;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	Chain rootChain;
	address root;
	uint256 rootTokenId;
	uint256 generation;
	MeemProperties properties;
	MeemProperties childProperties;
	uint256 mintedAt;
	address uriLockedBy;
	MeemType meemType;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct WrappedItem {
	Chain chain;
	address contractAddress;
	uint256 tokenId;
}

struct MeemMintParameters {
	address to;
	string tokenURI;
	Chain parentChain;
	address parent;
	uint256 parentTokenId;
	MeemType meemType;
	bool isURILocked;
	address mintedBy;
	URISource uriSource;
	string[] reactionTypes;
}

struct Reaction {
	string reaction;
	uint256 count;
}

struct InitParams {
	string symbol;
	string name;
	string contractURI;
	BaseProperties baseProperties;
	MeemProperties defaultProperties;
	MeemProperties defaultChildProperties;
	address[] admins;
	uint256 tokenCounterStart;
	int256 childDepth;
	uint256 nonOwnerSplitAllocationAmount;
}

struct ContractInfo {
	string symbol;
	string name;
	string contractURI;
	BaseProperties baseProperties;
	MeemProperties defaultProperties;
	MeemProperties defaultChildProperties;
	int256 childDepth;
	uint256 nonOwnerSplitAllocationAmount;
}

interface IInitDiamondStandard {
	function init(InitParams memory params) external;
}

interface IMeemBaseStandard {
	function mint(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties
	) external payable;

	function mintAndCopy(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		address toCopyAddress
	) external payable;

	function mintAndRemix(
		MeemMintParameters memory params,
		MeemProperties memory properties,
		MeemProperties memory childProperties,
		MeemMintParameters memory remixParams,
		MeemProperties memory remixProperties,
		MeemProperties memory remixChildProperties
	) external payable;

	// TODO: Implement child minting
	// function mintChild(
	// 	address to,
	// 	string memory mTokenURI,
	// 	Chain chain,
	// 	uint256 parentTokenId,
	// 	MeemProperties memory properties,
	// 	MeemProperties memory childProperties
	// ) external;
}

interface IMeemQueryStandard {
	// Get children meems
	function copiesOf(uint256 tokenId) external view returns (uint256[] memory);

	function ownedCopiesOf(uint256 tokenId, address owner)
		external
		view
		returns (uint256[] memory);

	function numCopiesOf(uint256 tokenId) external view returns (uint256);

	function remixesOf(uint256 tokenId)
		external
		view
		returns (uint256[] memory);

	function ownedRemixesOf(uint256 tokenId, address owner)
		external
		view
		returns (uint256[] memory);

	function numRemixesOf(uint256 tokenId) external view returns (uint256);

	function childDepth() external returns (int256);

	function tokenIdsOfOwner(address _owner)
		external
		view
		returns (uint256[] memory tokenIds_);

	function isNFTWrapped(
		Chain chain,
		address contractAddress,
		uint256 tokenId
	) external view returns (bool);

	function wrappedTokens(WrappedItem[] memory items)
		external
		view
		returns (uint256[] memory);

	function getMeem(uint256 tokenId) external view returns (Meem memory);

	function getBaseProperties() external view returns (BaseProperties memory);

	function getDefaultProperties(PropertyType propertyType)
		external
		view
		returns (MeemProperties memory);

	function getContractInfo() external view returns (ContractInfo memory);

	function getRoles(bytes32 role) external view returns (address[] memory);
}

interface IMeemAdminStandard {
	function setNonOwnerSplitAllocationAmount(uint256 amount) external;

	function setChildDepth(int256 newChildDepth) external;

	function setTokenCounter(uint256 tokenCounter) external;

	function setContractURI(string memory newContractURI) external;

	function setTokenRoot(
		uint256 tokenId,
		Chain rootChain,
		address root,
		uint256 rootTokenId
	) external;

	function setBaseSplits(Split[] memory splits) external;

	function setTotalOriginalsSupply(int256 totalSupply) external;

	function setOriginalsPerWallet(int256 originalsPerWallet) external;

	function setIsTransferrable(bool isTransferrable) external;

	function lockBaseSplits() external;

	function lockTotalOriginalsSupply() external;

	function lockOriginalsPerWallet() external;

	function lockIsTransferrable() external;

	function lockMintDates() external;

	function setMintDates(int256 startTimestamp, int256 endTimestamp) external;

	function setContractInfo(string memory name, string memory symbol) external;

	function setMintPermissions(MeemPermission[] memory permissions) external;

	function lockMintPermissions() external;

	function setTransferLockup(uint256 lockupUntil) external;

	function lockTransferLockup() external;

	function setProperties(
		PropertyType propertyType,
		MeemProperties memory props
	) external;

	function reInitialize(InitParams memory params) external;
}

interface IMeemSplitsStandard {
	function nonOwnerSplitAllocationAmount() external view returns (uint256);

	function lockSplits(uint256 tokenId, PropertyType propertyType) external;

	function setSplits(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] memory splits
	) external;

	function addSplit(
		uint256 tokenId,
		PropertyType propertyType,
		Split memory split
	) external;

	function removeSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx
	) external;

	function updateSplitAt(
		uint256 tokenId,
		PropertyType propertyType,
		uint256 idx,
		Split memory split
	) external;
}

interface IMeemPermissionsStandard {
	function lockPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType
	) external;

	function setPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] memory permissions
	) external;

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) external;

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) external;

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) external;

	function setTotalCopies(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	) external;

	function lockTotalCopies(uint256 tokenId, PropertyType propertyType)
		external;

	function setCopiesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newChildrenPerWallet
	) external;

	function lockCopiesPerWallet(uint256 tokenId, PropertyType propertyType)
		external;

	function setTotalRemixes(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	) external;

	function lockTotalRemixes(uint256 tokenId, PropertyType propertyType)
		external;

	function setRemixesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newChildrenPerWallet
	) external;

	function lockRemixesPerWallet(uint256 tokenId, PropertyType propertyType)
		external;

	function setData(uint256 tokenId, string memory data) external;

	function lockUri(uint256 tokenId) external;

	function setURISource(uint256 tokenId, URISource uriSource) external;

	function setTokenUri(uint256 tokenId, string memory uri) external;

	function setIsTransferrable(uint256 tokenId, bool isTransferrable) external;

	function lockIsTransferrable(uint256 tokenId) external;

	function lockMintDates(uint256 tokenId) external;

	function setMintDates(
		uint256 tokenId,
		int256 startTimestamp,
		int256 endTimestamp
	) external;

	function setTransferLockup(uint256 tokenId, uint256 lockupUntil) external;

	function lockTransferLockup(uint256 tokenId) external;
}

interface IClippingStandard {
	function clip(uint256 tokenId) external;

	function unClip(uint256 tokenId) external;

	function addressClippings(address addy)
		external
		view
		returns (uint256[] memory);

	function hasAddressClipped(uint256 tokenId, address addy)
		external
		view
		returns (bool);

	function clippings(uint256 tokenId)
		external
		view
		returns (address[] memory);

	function numClippings(uint256 tokenId) external view returns (uint256);
}

interface IReactionStandard {
	function addReaction(uint256 tokenId, string memory reaction) external;

	function removeReaction(uint256 tokenId, string memory reaction) external;

	function getReactedAt(
		uint256 tokenId,
		address addy,
		string memory reaction
	) external view returns (uint256);

	function setReactionTypes(uint256 tokenId, string[] memory reactionTypes)
		external;

	function getReactions(uint256 tokenId)
		external
		view
		returns (Reaction[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import './LibPart.sol';

interface IRoyaltiesProvider {
	function getRoyalties(address token, uint256 tokenId)
		external
		returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
pragma abicoder v2;

import './LibPart.sol';

interface RoyaltiesV2 {
	// event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

	function getRaribleV2Royalties(uint256 id)
		external
		view
		returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library LibPart {
	bytes32 public constant TYPE_HASH =
		keccak256('Part(address account,uint96 value)');

	struct Part {
		address payable account;
		uint96 value;
	}

	function hash(Part memory part) internal pure returns (bytes32) {
		return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Array {
	function removeAt(uint256[] storage array, uint256 index)
		internal
		returns (uint256[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(address[] storage array, uint256 index)
		internal
		returns (address[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function removeAt(string[] storage array, uint256 index)
		internal
		returns (string[] memory)
	{
		if (index >= array.length) {
			revert('Index out of range');
		}

		for (uint256 i = index; i < array.length - 1; i++) {
			array[i] = array[i + 1];
		}
		array.pop();
		return array;
	}

	function isEqual(address[] memory arr1, address[] memory arr2)
		internal
		pure
		returns (bool)
	{
		if (arr1.length != arr2.length) {
			return false;
		}

		for (uint256 i = 0; i < arr1.length; i++) {
			if (arr1[i] != arr2[i]) {
				return false;
			}
		}

		return true;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import {WrappedItem, PropertyType, PermissionType, MeemPermission, MeemProperties, URISource, MeemMintParameters, Meem, Chain, MeemType, MeemBase, Permission, BaseProperties, Split} from '../interfaces/MeemStandard.sol';
import {IERC721} from '../interfaces/IERC721.sol';
import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {LibERC721} from './LibERC721.sol';
import {LibAccessControl} from './LibAccessControl.sol';
import {Array} from '../utils/Array.sol';
import {LibProperties} from './LibProperties.sol';
import {LibPermissions} from './LibPermissions.sol';
import {Strings} from '../utils/Strings.sol';
import {Error} from '../libraries/Errors.sol';
import {MeemEvents} from '../libraries/Events.sol';

library LibMeem {
	function mint(
		MeemMintParameters memory params,
		MeemProperties memory mProperties,
		MeemProperties memory mChildProperties
	) internal returns (uint256 tokenId_) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		LibMeem.requireValidMeem(
			params.parentChain,
			params.parent,
			params.parentTokenId
		);

		uint256 tokenId = s.tokenCounter;
		LibERC721._safeMint(params.to, tokenId);

		// Initializes mapping w/ default values
		delete s.meems[tokenId];

		if (params.isURILocked) {
			s.meems[tokenId].uriLockedBy = msg.sender;
		}

		s.meems[tokenId].parentChain = params.parentChain;
		s.meems[tokenId].parent = params.parent;
		s.meems[tokenId].parentTokenId = params.parentTokenId;
		s.meems[tokenId].owner = params.to;
		s.meems[tokenId].mintedAt = block.timestamp;
		s.meems[tokenId].reactionTypes = params.reactionTypes;
		s.meems[tokenId].uriSource = params.uriSource;

		if (
			params.mintedBy != address(0) &&
			LibAccessControl.hasRole(s.MINTER_ROLE, msg.sender)
		) {
			s.meems[tokenId].mintedBy = params.mintedBy;
		} else {
			s.meems[tokenId].mintedBy = msg.sender;
		}

		// Handle creating child meem
		if (params.parent == address(this)) {
			// Verify token exists
			if (s.meems[params.parentTokenId].owner == address(0)) {
				revert(Error.TokenNotFound);
			}
			// Verify we can mint based on permissions
			requireCanMintChildOf(
				params.to,
				params.meemType,
				params.parentTokenId
			);
			handleSaleDistribution(params.parentTokenId);

			if (params.meemType == MeemType.Copy) {
				s.tokenURIs[tokenId] = s.tokenURIs[params.parentTokenId];
				s.meems[tokenId].meemType = MeemType.Copy;
			} else {
				s.tokenURIs[tokenId] = params.tokenURI;
				s.meems[tokenId].meemType = MeemType.Remix;
			}

			if (s.meems[params.parentTokenId].root != address(0)) {
				s.meems[tokenId].root = s.meems[params.parentTokenId].root;
				s.meems[tokenId].rootTokenId = s
					.meems[params.parentTokenId]
					.rootTokenId;
				s.meems[tokenId].rootChain = s
					.meems[params.parentTokenId]
					.rootChain;
			} else {
				s.meems[tokenId].root = params.parent;
				s.meems[tokenId].rootTokenId = params.parentTokenId;
				s.meems[tokenId].rootChain = params.parentChain;
			}

			s.meems[tokenId].generation =
				s.meems[params.parentTokenId].generation +
				1;

			// Merge parent childProperties into this child
			LibProperties.setProperties(
				tokenId,
				PropertyType.Meem,
				mProperties,
				params.parentTokenId,
				true
			);
			LibProperties.setProperties(
				tokenId,
				PropertyType.Child,
				mChildProperties,
				params.parentTokenId,
				true
			);
		} else {
			requireCanMintOriginal(params.to);
			handleSaleDistribution(0);
			s.meems[tokenId].generation = 0;
			s.meems[tokenId].root = params.parent;
			s.meems[tokenId].rootTokenId = params.parentTokenId;
			s.meems[tokenId].rootChain = params.parentChain;
			s.tokenURIs[tokenId] = params.tokenURI;
			if (params.parent == address(0)) {
				if (params.meemType != MeemType.Original) {
					revert(Error.InvalidMeemType);
				}
				s.meems[tokenId].meemType = MeemType.Original;
			} else {
				// Only trusted minter can mint a wNFT
				LibAccessControl.requireRole(s.MINTER_ROLE);
				if (params.meemType != MeemType.Wrapped) {
					revert(Error.InvalidMeemType);
				}
				s.meems[tokenId].meemType = MeemType.Wrapped;
			}
			LibProperties.setProperties(
				tokenId,
				PropertyType.Meem,
				mProperties,
				s.defaultProperties,
				true
			);
			LibProperties.setProperties(
				tokenId,
				PropertyType.Child,
				mChildProperties,
				s.defaultChildProperties,
				true
			);
		}

		if (
			s.childDepth > -1 &&
			s.meems[tokenId].generation > uint256(s.childDepth)
		) {
			revert(Error.ChildDepthExceeded);
		}

		// Keep track of children Meems
		if (params.parent == address(this)) {
			if (s.meems[tokenId].meemType == MeemType.Copy) {
				s.copies[params.parentTokenId].push(tokenId);
				s.copiesOwnerTokens[params.parentTokenId][params.to].push(
					tokenId
				);
				s.copiesOwnerTokenIndexes[params.to][tokenId] =
					s
					.copiesOwnerTokens[params.parentTokenId][params.to].length -
					1;
			} else if (s.meems[tokenId].meemType == MeemType.Remix) {
				s.remixes[params.parentTokenId].push(tokenId);
				s.remixesOwnerTokens[params.parentTokenId][params.to].push(
					tokenId
				);
				s.remixesOwnerTokenIndexes[params.to][tokenId] =
					s
					.remixesOwnerTokens[params.parentTokenId][params.to]
						.length -
					1;
			}
		} else if (params.parent != address(0)) {
			// Keep track of wrapped NFTs
			s.chainWrappedNFTs[params.parentChain][params.parent][
				params.parentTokenId
			] = tokenId;
		} else if (params.parent == address(0)) {
			s.originalMeemTokensIndex[tokenId] = s.originalMeemTokens.length;
			s.originalMeemTokens.push(tokenId);
			s.originalOwnerTokens[params.to][tokenId] = true;
			s.originalOwnerCount[params.to]++;
		}

		if (s.meems[tokenId].root == address(this)) {
			s.decendants[s.meems[tokenId].rootTokenId].push(tokenId);
		}

		s.tokenCounter += 1;

		if (
			!LibERC721._checkOnERC721Received(
				address(0),
				params.to,
				tokenId,
				''
			)
		) {
			revert(Error.ERC721ReceiverNotImplemented);
		}

		return tokenId;
	}

	function getMeem(uint256 tokenId) internal view returns (Meem memory) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		bool isCopy = s.meems[tokenId].meemType == MeemType.Copy;

		Meem memory meem = Meem(
			s.meems[tokenId].owner,
			s.meems[tokenId].parentChain,
			s.meems[tokenId].parent,
			s.meems[tokenId].parentTokenId,
			s.meems[tokenId].rootChain,
			s.meems[tokenId].root,
			s.meems[tokenId].rootTokenId,
			s.meems[tokenId].generation,
			isCopy
				? s.meemProperties[s.meems[tokenId].parentTokenId]
				: s.meemProperties[tokenId],
			isCopy
				? s.meemChildProperties[s.meems[tokenId].parentTokenId]
				: s.meemChildProperties[tokenId],
			s.meems[tokenId].mintedAt,
			s.meems[tokenId].uriLockedBy,
			s.meems[tokenId].meemType,
			s.meems[tokenId].mintedBy,
			s.meems[tokenId].uriSource,
			s.meems[tokenId].reactionTypes
		);

		return meem;
	}

	function handleSaleDistribution(uint256 tokenId) internal {
		if (msg.value == 0) {
			return;
		}

		uint256 leftover = msg.value;
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		Split[] storage splits = tokenId == 0
			? s.baseProperties.splits
			: s.meemProperties[tokenId].splits;

		for (uint256 i = 0; i < splits.length; i++) {
			uint256 amt = (msg.value * splits[i].amount) / 10000;

			address payable receiver = payable(splits[i].toAddress);

			receiver.transfer(amt);
			leftover = leftover - amt;
		}

		if (leftover > 0) {
			if (tokenId == 0) {
				// Original being minted. Refund difference back to the sender
				payable(msg.sender).transfer(leftover);
			} else {
				// Existing token transfer. Pay the current owner before transferring to new owner
				payable(s.meems[tokenId].owner).transfer(leftover);
			}
		}
	}

	function requireValidMeem(
		Chain chain,
		address parent,
		uint256 tokenId
	) internal view {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		// Meem must be unique address(0) or not have a corresponding parent / tokenId already minted
		if (parent != address(0) && parent != address(this)) {
			if (s.chainWrappedNFTs[chain][parent][tokenId] != 0) {
				revert(Error.NFTAlreadyWrapped);
			}
		}
	}

	function isNFTWrapped(
		Chain chainId,
		address contractAddress,
		uint256 tokenId
	) internal view returns (bool) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.chainWrappedNFTs[chainId][contractAddress][tokenId] != 0) {
			return true;
		}

		return false;
	}

	function wrappedTokens(WrappedItem[] memory items)
		internal
		view
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		uint256[] memory result = new uint256[](items.length);

		for (uint256 i = 0; i < items.length; i++) {
			result[i] = s.chainWrappedNFTs[items[i].chain][
				items[i].contractAddress
			][items[i].tokenId];
		}

		return result;
	}

	// Checks if "to" can mint a child of tokenId
	function requireCanMintChildOf(
		address to,
		MeemType meemType,
		uint256 tokenId
	) internal view {
		if (meemType != MeemType.Copy && meemType != MeemType.Remix) {
			revert(Error.NoPermission);
		}

		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemBase storage parent = s.meems[tokenId];

		// Only allow copies if the parent is an original or remix (i.e. no copies of a copy)
		if (parent.meemType == MeemType.Copy) {
			revert(Error.NoChildOfCopy);
		}

		MeemProperties storage parentProperties = s.meemProperties[tokenId];

		if (
			parentProperties.mintStartTimestamp > 0 &&
			block.timestamp < uint256(parentProperties.mintStartTimestamp)
		) {
			revert(Error.MintingNotStarted);
		}

		if (
			parentProperties.mintEndTimestamp > 0 &&
			block.timestamp > uint256(parentProperties.mintEndTimestamp)
		) {
			revert(Error.MintingFinished);
		}

		// Check total children
		if (
			meemType == MeemType.Copy &&
			parentProperties.totalCopies >= 0 &&
			s.copies[tokenId].length + 1 > uint256(parentProperties.totalCopies)
		) {
			revert(Error.TotalCopiesExceeded);
		} else if (
			meemType == MeemType.Remix &&
			parentProperties.totalRemixes >= 0 &&
			s.remixes[tokenId].length + 1 >
			uint256(parentProperties.totalRemixes)
		) {
			revert(Error.TotalRemixesExceeded);
		}

		if (
			meemType == MeemType.Copy &&
			parentProperties.copiesPerWallet >= 0 &&
			s.copiesOwnerTokens[tokenId][to].length + 1 >
			uint256(parentProperties.copiesPerWallet)
		) {
			revert(Error.CopiesPerWalletExceeded);
		} else if (
			meemType == MeemType.Remix &&
			parentProperties.remixesPerWallet >= 0 &&
			s.remixesOwnerTokens[tokenId][to].length + 1 >
			uint256(parentProperties.remixesPerWallet)
		) {
			revert(Error.RemixesPerWalletExceeded);
		}

		// Check permissions
		MeemPermission[] storage perms = LibPermissions.getPermissions(
			parentProperties,
			meemTypeToPermissionType(meemType)
		);

		requireProperPermissions(perms, parent.owner);
	}

	// Checks if "to" can mint a child of tokenId
	function requireCanMintOriginal(address to) internal view {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		BaseProperties storage baseProperties = s.baseProperties;

		// Allow admins to bypass mint start / end checks
		bool isAdmin = LibAccessControl.hasRole(s.ADMIN_ROLE, msg.sender);
		if (
			!isAdmin &&
			baseProperties.mintStartTimestamp > 0 &&
			block.timestamp < uint256(baseProperties.mintStartTimestamp)
		) {
			revert(Error.MintingNotStarted);
		}

		if (
			!isAdmin &&
			baseProperties.mintEndTimestamp > 0 &&
			block.timestamp > uint256(baseProperties.mintEndTimestamp)
		) {
			revert(Error.MintingFinished);
		}

		// Check total supply
		if (
			baseProperties.totalOriginalsSupply >= 0 &&
			s.originalMeemTokens.length + 1 >
			uint256(baseProperties.totalOriginalsSupply)
		) {
			revert(Error.TotalOriginalsSupplyExceeded);
		}

		if (
			baseProperties.originalsPerWallet >= 0 &&
			s.originalOwnerCount[to] + 1 >
			uint256(baseProperties.originalsPerWallet)
		) {
			revert(Error.OriginalsPerWalletExceeded);
		}

		requireProperPermissions(baseProperties.mintPermissions, address(0));
	}

	function requireProperPermissions(
		MeemPermission[] storage permissions,
		address tokenOwner
	) internal view {
		bool hasPermission = false;
		bool hasCostBeenSet = false;
		uint256 costWei = 0;

		for (uint256 i = 0; i < permissions.length; i++) {
			MeemPermission storage perm = permissions[i];
			if (
				// Allowed if permission is anyone
				perm.permission == Permission.Anyone
			) {
				hasPermission = true;
			}

			if (perm.permission == Permission.Addresses) {
				// Allowed if to is in the list of approved addresses
				for (uint256 j = 0; j < perm.addresses.length; j++) {
					if (perm.addresses[j] == msg.sender) {
						hasPermission = true;
						break;
					}
				}
			}

			if (perm.permission == Permission.Owner) {
				// Allowed if to is in the list of approved addresses
				if (tokenOwner == msg.sender) {
					hasPermission = true;
					break;
				}
			}

			if (perm.permission == Permission.Holders) {
				// Check each address
				for (uint256 j = 0; j < perm.addresses.length; j++) {
					uint256 balance = IERC721(perm.addresses[j]).balanceOf(
						msg.sender
					);

					if (balance >= perm.numTokens) {
						hasPermission = true;
						break;
					}
				}
			}

			if (
				hasPermission &&
				(!hasCostBeenSet || (hasCostBeenSet && costWei > perm.costWei))
			) {
				costWei = perm.costWei;
				hasCostBeenSet = true;
			}
			// TODO: Check external token holders on same network
		}

		if (!hasPermission) {
			revert(Error.NoPermission);
		}

		if (costWei != msg.value) {
			revert(Error.IncorrectMsgValue);
		}
	}

	function permissionTypeToMeemType(PermissionType perm)
		internal
		pure
		returns (MeemType)
	{
		if (perm == PermissionType.Copy) {
			return MeemType.Copy;
		} else if (perm == PermissionType.Remix) {
			return MeemType.Remix;
		}

		revert(Error.NoPermission);
	}

	function meemTypeToPermissionType(MeemType meemType)
		internal
		pure
		returns (PermissionType)
	{
		if (meemType == MeemType.Copy) {
			return PermissionType.Copy;
		} else if (meemType == MeemType.Remix) {
			return PermissionType.Remix;
		}

		revert(Error.NoPermission);
	}

	function clip(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.hasAddressClipped[msg.sender][tokenId]) {
			revert(Error.AlreadyClipped);
		}

		s.clippings[tokenId].push(msg.sender);
		s.addressClippings[msg.sender].push(tokenId);
		s.clippingsIndex[msg.sender][tokenId] = s.clippings[tokenId].length - 1;
		s.addressClippingsIndex[msg.sender][tokenId] =
			s.addressClippings[msg.sender].length -
			1;
		s.hasAddressClipped[msg.sender][tokenId] = true;

		emit MeemEvents.MeemClipped(tokenId, msg.sender);
	}

	function unClip(uint256 tokenId) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (!s.hasAddressClipped[msg.sender][tokenId]) {
			revert(Error.NotClipped);
		}

		Array.removeAt(
			s.clippings[tokenId],
			s.clippingsIndex[msg.sender][tokenId]
		);
		Array.removeAt(
			s.addressClippings[msg.sender],
			s.addressClippingsIndex[msg.sender][tokenId]
		);
		s.clippingsIndex[msg.sender][tokenId] = 0;
		s.addressClippingsIndex[msg.sender][tokenId] = 0;
		s.hasAddressClipped[msg.sender][tokenId] = false;

		emit MeemEvents.MeemUnClipped(tokenId, msg.sender);
	}

	function tokenClippings(uint256 tokenId)
		internal
		view
		returns (address[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippings[tokenId];
	}

	function addressClippings(address addy)
		internal
		view
		returns (uint256[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.addressClippings[addy];
	}

	function hasAddressClipped(uint256 tokenId, address addy)
		internal
		view
		returns (bool)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippingsIndex[addy][tokenId] != 0;
	}

	function clippings(uint256 tokenId)
		internal
		view
		returns (address[] memory)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippings[tokenId];
	}

	function numClippings(uint256 tokenId) internal view returns (uint256) {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		return s.clippings[tokenId].length;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import {LibMeta} from '../libraries/LibMeta.sol';
import {MeemBase, MeemProperties, Chain, BaseProperties} from '../interfaces/MeemStandard.sol';

library Error {
	string public constant MissingRequiredRole = 'MISSING_REQUIRED_ROLE';
	string public constant NotTokenOwner = 'NOT_TOKEN_OWNER';
	string public constant NotTokenAdmin = 'NOT_TOKEN_ADMIN';
	string public constant InvalidNonOwnerSplitAllocationAmount =
		'INVALID_NON_OWNER_SPLIT_ALLOCATION_AMOUNT';
	string public constant NoRenounceOthers = 'NO_RENOUNCE_OTHERS';
	string public constant InvalidZeroAddressQuery =
		'INVALID_ZERO_ADDRESS_QUERY';
	string public constant IndexOutOfRange = 'INDEX_OUT_OF_RANGE';
	string public constant TokenNotFound = 'TOKEN_NOT_FOUND';
	string public constant TokenAlreadyExists = 'TOKEN_ALREADY_EXISTS';
	string public constant NoApproveSelf = 'NO_APPROVE_SELF';
	string public constant NotApproved = 'NOT_APPROVED';
	string public constant ERC721ReceiverNotImplemented =
		'ERC721_RECEIVER_NOT_IMPLEMENTED';
	string public constant ToAddressInvalid = 'TO_ADDRESS_INVALID';
	string public constant TransfersLocked = 'TRANSFERS_LOCKED';
	string public constant NoTransferWrappedNFT = 'NO_TRANSFER_WRAPPED_NFT';
	string public constant NFTAlreadyWrapped = 'NFT_ALREADY_WRAPPED';
	string public constant PropertyLocked = 'PROPERTY_LOCKED';
	string public constant InvalidPropertyType = 'INVALID_PROPERTY_TYPE';
	string public constant InvalidPermissionType = 'INVALID_PERMISSION_TYPE';
	string public constant InvalidTotalCopies = 'INVALID_TOTAL_COPIES';
	string public constant TotalCopiesExceeded = 'TOTAL_COPIES_EXCEEDED';
	string public constant InvalidTotalRemixes = 'INVALID_TOTAL_REMIXES';
	string public constant TotalRemixesExceeded = 'TOTAL_REMIXES_EXCEEDED';
	string public constant CopiesPerWalletExceeded =
		'COPIES_PER_WALLET_EXCEEDED';
	string public constant RemixesPerWalletExceeded =
		'REMIXES_PER_WALLET_EXCEEDED';
	string public constant NoPermission = 'NO_PERMISSION';
	string public constant InvalidChildGeneration = 'INVALID_CHILD_GENERATION';
	string public constant InvalidParent = 'INVALID_PARENT';
	string public constant ChildDepthExceeded = 'CHILD_DEPTH_EXCEEDED';
	string public constant MissingRequiredPermissions =
		'MISSING_REQUIRED_PERMISSIONS';
	string public constant MissingRequiredSplits = 'MISSING_REQUIRED_SPLITS';
	string public constant NoChildOfCopy = 'NO_CHILD_OF_COPY';
	string public constant NoCopyUnverified = 'NO_COPY_UNVERIFIED';
	string public constant MeemNotVerified = 'MEEM_NOT_VERIFIED';
	string public constant InvalidURI = 'INVALID_URI';
	string public constant InvalidMeemType = 'INVALID_MEEM_TYPE';
	string public constant InvalidToken = 'INVALID_TOKEN';
	string public constant AlreadyClipped = 'ALREADY_CLIPPED';
	string public constant NotClipped = 'NOT_CLIPPED';
	string public constant URILocked = 'URI_LOCKED';
	string public constant AlreadyReacted = 'ALREADY_REACTED';
	string public constant ReactionNotFound = 'REACTION_NOT_FOUND';
	string public constant IncorrectMsgValue = 'INCORRECT_MSG_VALUE';
	string public constant TotalOriginalsSupplyExceeded =
		'TOTAL_ORIGINALS_SUPPLY_EXCEEDED';
	string public constant OriginalsPerWalletExceeded =
		'ORIGINALS_PER_WALLET_EXCEEDED';
	string public constant MintingNotStarted = 'MINTING_NOT_STARTED';
	string public constant MintingFinished = 'MINTING_FINISHED';
	string public constant InvalidTokenCounter = 'INVALID_TOKEN_COUNTER';
	string public constant NotOwner = 'NOT_OWNER';
	string public constant AlreadyInitialized = 'ALREADY_INITIALIZED';
}

// TODO: Use custom errors when more widely supported

// error MissingRequiredRole(bytes32 requiredRole);

// error NotTokenOwner(uint256 tokenId);

// error NotTokenAdmin(uint256 tokenId);

// error InvalidNonOwnerSplitAllocationAmount(
// 	uint256 minAmount,
// 	uint256 maxAmount
// );

// error NoRenounceOthers();

// error InvalidZeroAddressQuery();

// error IndexOutOfRange(uint256 idx, uint256 max);

// error TokenNotFound(uint256 tokenId);

// error TokenAlreadyExists(uint256 tokenId);

// error NoApproveSelf();

// error NotApproved();

// error ERC721ReceiverNotImplemented();

// error ToAddressInvalid(address to);

// error NoTransferWrappedNFT(address parentAddress, uint256 parentTokenId);

// error NFTAlreadyWrapped(address parentAddress, uint256 parentTokenId);

// error PropertyLocked(address lockedBy);

// error InvalidPropertyType();

// error InvalidPermissionType();

// error InvalidTotalCopies(uint256 currentTotalCopies);

// error TotalCopiesExceeded();

// error InvalidTotalRemixes(uint256 currentTotalRemixes);

// error TotalRemixesExceeded();

// error CopiesPerWalletExceeded();

// error RemixesPerWalletExceeded();

// error NoPermission();

// error InvalidChildGeneration();

// error InvalidParent();

// error ChildDepthExceeded();

// error MissingRequiredPermissions();

// error MissingRequiredSplits();

// error NoChildOfCopy();

// error NoCopyUnverified();

// error MeemNotVerified();

// error InvalidURI();

// error InvalidMeemType();

// error InvalidToken();

// error AlreadyClipped();

// error NotClipped();

// error URILocked();

// error AlreadyReacted();

// error ReactionNotFound();

// error IncorrectMsgValue();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PropertyType, MeemProperties, URISource, MeemPermission, Split, PermissionType} from '../interfaces/MeemStandard.sol';
import {LibPart} from '../../royalties/LibPart.sol';

library InitEvents {
	event MeemContractInitialized(address contractAddress);
}

library AccessControlEvents {
	/**
	 * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
	 *
	 * `ADMIN_ROLE` is the starting admin for all roles, despite
	 * {RoleAdminChanged} not being emitted signaling this.
	 *
	 * _Available since v3.1._
	 */
	event MeemRoleAdminChanged(
		bytes32 indexed role,
		bytes32 indexed previousAdminRole,
		bytes32 indexed newAdminRole
	);

	/**
	 * @dev Emitted when `account` is granted `role`.
	 *
	 * `sender` is the account that originated the contract call, an admin role
	 * bearer except when using {AccessControl-_setupRole}.
	 */
	event MeemRoleGranted(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	/**
	 * @dev Emitted when `account` is revoked `role`.
	 *
	 * `sender` is the account that originated the contract call:
	 *   - if using `revokeRole`, it is the admin role bearer
	 *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
	 */
	event MeemRoleRevoked(
		bytes32 indexed role,
		address indexed account,
		address indexed sender
	);

	event MeemRoleSet(
		bytes32 indexed role,
		address[] indexed account,
		address indexed sender
	);
}

library MeemERC721Events {
	/**
	 * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
	 */
	event MeemTransfer(
		address indexed from,
		address indexed to,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
	 */
	event MeemApproval(
		address indexed owner,
		address indexed approved,
		uint256 indexed tokenId
	);

	/**
	 * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
	 */
	event MeemApprovalForAll(
		address indexed owner,
		address indexed operator,
		bool approved
	);
}

library MeemBaseEvents {
	event MeemTotalOriginalsSupplySet(int256 totalOriginalsSupply);
	event MeemTotalOriginalsSupplyLocked(address lockedBy);

	event MeemMintPermissionsSet(MeemPermission[] mintPermissions);
	event MeemMintPermissionsLocked(address lockedBy);

	event MeemSplitsSet(Split[] splits);
	event MeemSplitsLocked(address lockedBy);

	event MeemOriginalsPerWalletSet(int256 originalsPerWallet);
	event MeemOriginalsPerWalletLocked(address lockedBy);

	event MeemIsTransferrableSet(bool isTransferrable);
	event MeemIsTransferrableLocked(address lockedBy);

	event MeemBaseMintDatesSet(
		int256 mintStartTimestamp,
		int256 mintEndTimestamp
	);
	event MeemBaseMintDatesLocked(address lockedBy);
}

library MeemEvents {
	event MeemPropertiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties props
	);
	event MeemTotalCopiesSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	);
	event MeemTotalCopiesLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event MeemCopiesPerWalletSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	);
	event MeemTotalRemixesSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	);
	event MeemTotalRemixesLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event MeemRemixesPerWalletSet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	);
	event MeemCopiesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);
	event MeemRemixesPerWalletLocked(
		uint256 tokenId,
		PropertyType propertyType,
		address lockedBy
	);

	event MeemURISourceSet(uint256 tokenId, URISource uriSource);

	event MeemURISet(uint256 tokenId, string uri);

	event MeemURILockedBySet(uint256 tokenId, address lockedBy);

	event MeemDataSet(uint256 tokenId, string data);

	event MeemMintDatesSet(
		uint256 tokenId,
		int256 mintStartTimestamp,
		int256 mintEndTimestamp
	);

	event MeemMintDatesLocked(uint256 tokenId, address lockedBy);

	event MeemClipped(uint256 tokenId, address addy);

	event MeemUnClipped(uint256 tokenId, address addy);

	event MeemPermissionsSet(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] permission
	);

	event MeemTokenReactionAdded(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event MeemTokenReactionRemoved(
		uint256 tokenId,
		address addy,
		string reaction,
		uint256 newTotalReactions
	);

	event MeemTokenReactionTypesSet(uint256 tokenId, string[] reactionTypes);

	event MeemSplitsSet(
		uint256 tokenId,
		PropertyType propertyType,
		Split[] splits
	);
	// Rarible royalties event
	event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
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
	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes calldata _data
	) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
	bytes internal constant TABLE =
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

	/// @notice Encodes some bytes to the base64 representation
	function encode(bytes memory data) internal pure returns (string memory) {
		uint256 len = data.length;
		if (len == 0) return '';

		// multiply by 4/3 rounded up
		uint256 encodedLen = 4 * ((len + 2) / 3);

		// Add some extra buffer at the end
		bytes memory result = new bytes(encodedLen + 32);

		bytes memory table = TABLE;

		assembly {
			let tablePtr := add(table, 1)
			let resultPtr := add(result, 32)

			for {
				let i := 0
			} lt(i, len) {

			} {
				i := add(i, 3)
				let input := and(mload(add(data, i)), 0xffffff)

				let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
				)
				out := shl(8, out)
				out := add(
					out,
					and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
				)
				out := shl(224, out)

				mstore(resultPtr, out)

				resultPtr := add(resultPtr, 4)
			}

			switch mod(len, 3)
			case 1 {
				mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
			}
			case 2 {
				mstore(sub(resultPtr, 1), shl(248, 0x3d))
			}

			mstore(result, encodedLen)
		}

		return string(result);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library LibMeta {
	bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
		keccak256(
			bytes(
				'EIP712Domain(string name,string version,uint256 salt,address verifyingContract)'
			)
		);

	function domainSeparator(string memory name, string memory version)
		internal
		view
		returns (bytes32 domainSeparator_)
	{
		domainSeparator_ = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(version)),
				getChainID(),
				address(this)
			)
		);
	}

	function getChainID() internal view returns (uint256 id) {
		assembly {
			id := chainid()
		}
	}

	function msgSender() internal view returns (address sender_) {
		if (msg.sender == address(this)) {
			bytes memory array = msg.data;
			uint256 index = msg.data.length;
			assembly {
				// Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
				sender_ := and(
					mload(add(array, index)),
					0xffffffffffffffffffffffffffffffffffffffff
				)
			}
		} else {
			sender_ = msg.sender;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721Internal} from '@solidstate/contracts/token/ERC721/IERC721Internal.sol';

/**
 * @notice ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal {
	/**
	 * @notice query the balance of given address
	 * @return balance quantity of tokens held
	 */
	function balanceOf(address account) external view returns (uint256 balance);

	/**
	 * @notice query the owner of given token
	 * @param tokenId token to query
	 * @return owner token owner
	 */
	function ownerOf(uint256 tokenId) external view returns (address owner);

	/**
	 * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
	 * @param from sender of token
	 * @param to receiver of token
	 * @param tokenId token id
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external payable;

	/**
	 * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
	 * @param from sender of token
	 * @param to receiver of token
	 * @param tokenId token id
	 * @param data data payload
	 */
	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId,
		bytes calldata data
	) external payable;

	/**
	 * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
	 * @param from sender of token
	 * @param to receiver of token
	 * @param tokenId token id
	 */
	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external payable;

	/**
	 * @notice grant approval to given account to spend token
	 * @param operator address to be approved
	 * @param tokenId token to approve
	 */
	function approve(address operator, uint256 tokenId) external payable;

	/**
	 * @notice get approval status for given token
	 * @param tokenId token to query
	 * @return operator address approved to spend token
	 */
	function getApproved(uint256 tokenId)
		external
		view
		returns (address operator);

	/**
	 * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
	 * @param operator address to be approved
	 * @param status approval status
	 */
	function setApprovalForAll(address operator, bool status) external;

	/**
	 * @notice query approval status of given operator with respect to given address
	 * @param account address to query for approval granted
	 * @param operator address to query for approval received
	 * @return status whether operator is approved to spend tokens held by account
	 */
	function isApprovedForAll(address account, address operator)
		external
		view
		returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {PropertyType, MeemProperties, URISource} from '../interfaces/MeemStandard.sol';
import {LibERC721} from './LibERC721.sol';
import {LibPermissions} from './LibPermissions.sol';
import {LibAccessControl} from './LibAccessControl.sol';
import {LibSplits} from './LibSplits.sol';
import {Strings} from '../utils/Strings.sol';
import {Error} from './Errors.sol';
import {MeemEvents} from './Events.sol';

library LibProperties {
	function requireAccess(uint256 tokenId, PropertyType propertyType)
		internal
		view
	{
		if (
			tokenId > 0 &&
			(propertyType == PropertyType.Meem ||
				propertyType == PropertyType.Child)
		) {
			LibERC721.requireOwnsToken(tokenId);
		} else if (
			propertyType == PropertyType.DefaultMeem ||
			propertyType == PropertyType.DefaultChild
		) {
			LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
			LibAccessControl.requireRole(s.ADMIN_ROLE);
		} else {
			revert(Error.MissingRequiredRole);
		}
	}

	function getProperties(uint256 tokenId, PropertyType propertyType)
		internal
		view
		returns (MeemProperties storage)
	{
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (propertyType == PropertyType.Meem) {
			return s.meemProperties[tokenId];
		} else if (propertyType == PropertyType.Child) {
			return s.meemChildProperties[tokenId];
		} else if (propertyType == PropertyType.DefaultMeem) {
			return s.defaultProperties;
		} else if (propertyType == PropertyType.DefaultChild) {
			return s.defaultChildProperties;
		}

		revert(Error.InvalidPropertyType);
	}

	function setProperties(
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		setProperties(0, propertyType, mProperties, 0, false);
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties
	) internal {
		setProperties(tokenId, propertyType, mProperties, 0, false);
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties,
		uint256 parentTokenId,
		bool shouldMergeParent
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		setProperties(
			tokenId,
			propertyType,
			mProperties,
			s.meemChildProperties[parentTokenId],
			shouldMergeParent
		);
	}

	function setProperties(
		uint256 tokenId,
		PropertyType propertyType,
		MeemProperties memory mProperties,
		MeemProperties memory parentProperties,
		bool shouldMergeParent
	) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);
		MeemProperties memory newProps = mProperties;
		if (shouldMergeParent) {
			newProps = mergeProperties(mProperties, parentProperties);
		}

		delete props.copyPermissions;
		delete props.remixPermissions;
		delete props.readPermissions;
		delete props.splits;

		for (uint256 i = 0; i < newProps.copyPermissions.length; i++) {
			props.copyPermissions.push(newProps.copyPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.remixPermissions.length; i++) {
			props.remixPermissions.push(newProps.remixPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.readPermissions.length; i++) {
			props.readPermissions.push(newProps.readPermissions[i]);
		}

		for (uint256 i = 0; i < newProps.splits.length; i++) {
			props.splits.push(newProps.splits[i]);
		}

		props.totalCopies = newProps.totalCopies;
		props.totalCopiesLockedBy = newProps.totalCopiesLockedBy;
		props.totalRemixes = newProps.totalRemixes;
		props.totalRemixesLockedBy = newProps.totalRemixesLockedBy;
		props.copiesPerWallet = newProps.copiesPerWallet;
		props.copiesPerWalletLockedBy = newProps.copiesPerWalletLockedBy;
		props.remixesPerWallet = newProps.remixesPerWallet;
		props.remixesPerWalletLockedBy = newProps.remixesPerWalletLockedBy;
		props.copyPermissionsLockedBy = newProps.copyPermissionsLockedBy;
		props.remixPermissionsLockedBy = newProps.remixPermissionsLockedBy;
		props.readPermissionsLockedBy = newProps.readPermissionsLockedBy;
		props.splitsLockedBy = newProps.splitsLockedBy;
		props.isTransferrable = newProps.isTransferrable;
		props.isTransferrableLockedBy = newProps.isTransferrableLockedBy;
		props.mintStartTimestamp = newProps.mintStartTimestamp;
		props.mintEndTimestamp = newProps.mintEndTimestamp;
		props.mintDatesLockedBy = newProps.mintDatesLockedBy;
		props.transferLockupUntil = newProps.transferLockupUntil;
		props.transferLockupUntilLockedBy = newProps
			.transferLockupUntilLockedBy;

		if (
			propertyType == PropertyType.Meem ||
			propertyType == PropertyType.Child
		) {
			LibSplits.validateSplits(
				props,
				LibERC721.ownerOf(tokenId),
				s.nonOwnerSplitAllocationAmount
			);
		}

		emit MeemEvents.MeemPropertiesSet(tokenId, propertyType, props);
	}

	// Merges the base properties with any overrides
	function mergeProperties(
		MeemProperties memory baseProperties,
		MeemProperties memory overrideProps
	) internal pure returns (MeemProperties memory) {
		MeemProperties memory mergedProps = baseProperties;

		if (overrideProps.totalCopiesLockedBy != address(0)) {
			mergedProps.totalCopiesLockedBy = overrideProps.totalCopiesLockedBy;
			mergedProps.totalCopies = overrideProps.totalCopies;
		}

		if (overrideProps.copiesPerWalletLockedBy != address(0)) {
			mergedProps.copiesPerWalletLockedBy = overrideProps
				.copiesPerWalletLockedBy;
			mergedProps.copiesPerWallet = overrideProps.copiesPerWallet;
		}

		if (overrideProps.totalRemixesLockedBy != address(0)) {
			mergedProps.totalRemixesLockedBy = overrideProps
				.totalRemixesLockedBy;
			mergedProps.totalRemixes = overrideProps.totalRemixes;
		}

		if (overrideProps.remixesPerWalletLockedBy != address(0)) {
			mergedProps.remixesPerWalletLockedBy = overrideProps
				.remixesPerWalletLockedBy;
			mergedProps.remixesPerWallet = overrideProps.remixesPerWallet;
		}

		if (overrideProps.isTransferrableLockedBy != address(0)) {
			mergedProps.isTransferrableLockedBy = overrideProps
				.isTransferrableLockedBy;
			mergedProps.isTransferrable = overrideProps.isTransferrable;
		}

		if (overrideProps.mintDatesLockedBy != address(0)) {
			mergedProps.mintDatesLockedBy = overrideProps.mintDatesLockedBy;
			mergedProps.mintStartTimestamp = overrideProps.mintStartTimestamp;
			mergedProps.mintEndTimestamp = overrideProps.mintEndTimestamp;
		}

		// Merge / validate properties
		if (overrideProps.copyPermissionsLockedBy != address(0)) {
			mergedProps.copyPermissionsLockedBy = overrideProps
				.copyPermissionsLockedBy;
			mergedProps.copyPermissions = overrideProps.copyPermissions;
		} else {
			LibPermissions.validatePermissions(
				mergedProps.copyPermissions,
				overrideProps.copyPermissions
			);
		}

		if (overrideProps.remixPermissionsLockedBy != address(0)) {
			mergedProps.remixPermissionsLockedBy = overrideProps
				.remixPermissionsLockedBy;
			mergedProps.remixPermissions = overrideProps.remixPermissions;
		} else {
			LibPermissions.validatePermissions(
				mergedProps.remixPermissions,
				overrideProps.remixPermissions
			);
		}

		if (overrideProps.readPermissionsLockedBy != address(0)) {
			mergedProps.readPermissionsLockedBy = overrideProps
				.readPermissionsLockedBy;
			mergedProps.readPermissions = overrideProps.readPermissions;
		} else {
			LibPermissions.validatePermissions(
				mergedProps.readPermissions,
				overrideProps.readPermissions
			);
		}

		// Validate splits
		if (overrideProps.splitsLockedBy != address(0)) {
			mergedProps.splitsLockedBy = overrideProps.splitsLockedBy;
			mergedProps.splits = overrideProps.splits;
		} else {
			LibSplits.validateOverrideSplits(
				mergedProps.splits,
				overrideProps.splits
			);
		}

		return mergedProps;
	}

	function setTotalCopies(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (newTotalCopies > -1) {
			if (
				propertyType == PropertyType.Meem &&
				uint256(newTotalCopies) < s.copies[tokenId].length
			) {
				revert(Error.InvalidTotalCopies);
			}
		}

		if (props.totalCopiesLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.totalCopies = newTotalCopies;
		emit MeemEvents.MeemTotalCopiesSet(
			tokenId,
			propertyType,
			newTotalCopies
		);
	}

	function lockTotalCopies(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.totalCopiesLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.totalCopiesLockedBy = msg.sender;
		emit MeemEvents.MeemTotalCopiesLocked(
			tokenId,
			propertyType,
			msg.sender
		);
	}

	function setCopiesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalCopies
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.copiesPerWalletLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.copiesPerWallet = newTotalCopies;
		emit MeemEvents.MeemCopiesPerWalletSet(
			tokenId,
			propertyType,
			newTotalCopies
		);
	}

	function lockCopiesPerWallet(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.copiesPerWalletLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.copiesPerWalletLockedBy = msg.sender;
		emit MeemEvents.MeemCopiesPerWalletLocked(
			tokenId,
			propertyType,
			msg.sender
		);
	}

	function setTotalRemixes(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (newTotalRemixes > -1) {
			if (
				propertyType == PropertyType.Meem &&
				uint256(newTotalRemixes) < s.remixes[tokenId].length
			) {
				revert(Error.InvalidTotalRemixes);
			}
		}

		if (props.totalRemixesLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.totalRemixes = newTotalRemixes;
		emit MeemEvents.MeemTotalRemixesSet(
			tokenId,
			propertyType,
			newTotalRemixes
		);
	}

	function lockTotalRemixes(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.totalRemixesLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.totalRemixesLockedBy = msg.sender;
		emit MeemEvents.MeemTotalRemixesLocked(
			tokenId,
			propertyType,
			msg.sender
		);
	}

	function setRemixesPerWallet(
		uint256 tokenId,
		PropertyType propertyType,
		int256 newTotalRemixes
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.remixesPerWalletLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.remixesPerWallet = newTotalRemixes;
		emit MeemEvents.MeemRemixesPerWalletSet(
			tokenId,
			propertyType,
			newTotalRemixes
		);
	}

	function lockRemixesPerWallet(uint256 tokenId, PropertyType propertyType)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		if (props.remixesPerWalletLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		props.remixesPerWalletLockedBy = msg.sender;
		emit MeemEvents.MeemRemixesPerWalletLocked(
			tokenId,
			propertyType,
			msg.sender
		);
	}

	function setData(uint256 tokenId, string memory data) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert(Error.URILocked);
		}

		s.meems[tokenId].data = data;
		emit MeemEvents.MeemDataSet(tokenId, s.meems[tokenId].data);
	}

	function lockUri(uint256 tokenId) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert(Error.URILocked);
		}

		s.meems[tokenId].uriLockedBy = msg.sender;

		emit MeemEvents.MeemURILockedBySet(
			tokenId,
			s.meems[tokenId].uriLockedBy
		);
	}

	function setURISource(uint256 tokenId, URISource uriSource) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert(Error.URILocked);
		}

		s.meems[tokenId].uriSource = uriSource;
		emit MeemEvents.MeemURISourceSet(tokenId, uriSource);
	}

	function setTokenUri(uint256 tokenId, string memory uri) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meems[tokenId].uriLockedBy != address(0)) {
			revert(Error.URILocked);
		}

		s.tokenURIs[tokenId] = uri;

		emit MeemEvents.MeemURISet(tokenId, uri);
	}

	function setIsTransferrable(uint256 tokenId, bool isTransferrable)
		internal
	{
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meemProperties[tokenId].isTransferrableLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}
		s.meemProperties[tokenId].isTransferrable = isTransferrable;
	}

	function lockIsTransferrable(uint256 tokenId) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meemProperties[tokenId].isTransferrableLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}
		s.meemProperties[tokenId].isTransferrableLockedBy = msg.sender;
	}

	function lockMintDates(uint256 tokenId) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meemProperties[tokenId].mintDatesLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}
		s.meemProperties[tokenId].mintDatesLockedBy = msg.sender;
	}

	function setMintDates(
		uint256 tokenId,
		int256 startTimestamp,
		int256 endTimestamp
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (s.meemProperties[tokenId].mintDatesLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		s.meemProperties[tokenId].mintStartTimestamp = startTimestamp;
		s.meemProperties[tokenId].mintEndTimestamp = endTimestamp;
	}

	function setTransferLockup(uint256 tokenId, uint256 lockupUntil) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (
			s.meemProperties[tokenId].transferLockupUntilLockedBy != address(0)
		) {
			revert(Error.PropertyLocked);
		}
		s.meemProperties[tokenId].transferLockupUntil = lockupUntil;
	}

	function lockTransferLockup(uint256 tokenId) internal {
		LibERC721.requireOwnsToken(tokenId);
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();
		if (
			s.meemProperties[tokenId].transferLockupUntilLockedBy != address(0)
		) {
			revert(Error.PropertyLocked);
		}
		s.meemProperties[tokenId].transferLockupUntilLockedBy = msg.sender;
	}

	// function requirePropertiesAccess(uint256 tokenId, PropertyType propertyType)
	// 	internal
	// 	view
	// {
	// 	LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

	// 	if (
	// 		propertyType == PropertyType.Meem ||
	// 		propertyType == PropertyType.Child
	// 	) {
	// 		LibERC721.requireOwnsToken(tokenId);
	// 	} else if (
	// 		propertyType == PropertyType.Meem ||
	// 		propertyType == PropertyType.Child
	// 	) {
	// 		LibAccessControl.requireRole(s.ADMIN_ROLE);
	// 	} else {
	// 		revert(Error.InvalidPropertyType);
	// 	}
	// }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LibAppStorage} from '../storage/LibAppStorage.sol';
import {PropertyType, MeemProperties, MeemPermission, PermissionType} from '../interfaces/MeemStandard.sol';
import {LibERC721} from './LibERC721.sol';
import {LibProperties} from './LibProperties.sol';
import {LibSplits} from './LibSplits.sol';
import {Array} from '../utils/Array.sol';
import {Error} from './Errors.sol';
import {MeemBaseEvents, MeemEvents} from './Events.sol';

library LibPermissions {
	function lockPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);
		permissionNotLocked(props, permissionType);

		if (permissionType == PermissionType.Copy) {
			props.copyPermissionsLockedBy = msg.sender;
		} else if (permissionType == PermissionType.Remix) {
			props.remixPermissionsLockedBy = msg.sender;
		} else if (permissionType == PermissionType.Read) {
			props.readPermissionsLockedBy = msg.sender;
		} else {
			revert(Error.InvalidPermissionType);
		}
	}

	function setPermissions(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission[] memory permissions
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);

		// Check if there are any existing locked permissions and if so, verify they're the same as the new permissions
		validatePermissions(permissions, perms);

		if (permissionType == PermissionType.Copy) {
			delete props.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			delete props.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			delete props.readPermissions;
		} else {
			revert(Error.InvalidPermissionType);
		}

		for (uint256 i = 0; i < permissions.length; i++) {
			perms.push(permissions[i]);
		}

		emit MeemEvents.MeemPermissionsSet(
			tokenId,
			propertyType,
			permissionType,
			perms
		);
	}

	function lockMintPermissions() internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.baseProperties.mintPermissionsLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		s.baseProperties.mintPermissionsLockedBy = msg.sender;
	}

	function setMintPermissions(MeemPermission[] memory permissions) internal {
		LibAppStorage.AppStorage storage s = LibAppStorage.diamondStorage();

		if (s.baseProperties.mintPermissionsLockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		// Check if there are any existing locked permissions and if so, verify they're the same as the new permissions
		validatePermissions(permissions, s.baseProperties.mintPermissions);

		delete s.baseProperties.mintPermissions;

		for (uint256 i = 0; i < permissions.length; i++) {
			s.baseProperties.mintPermissions.push(permissions[i]);
		}

		emit MeemBaseEvents.MeemMintPermissionsSet(
			s.baseProperties.mintPermissions
		);
	}

	function addPermission(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		MeemPermission memory permission
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		perms.push(permission);

		emit MeemEvents.MeemPermissionsSet(
			tokenId,
			propertyType,
			permissionType,
			perms
		);
	}

	function removePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);

		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);
		if (perms[idx].lockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		if (idx >= perms.length) {
			revert(Error.IndexOutOfRange);
		}

		for (uint256 i = idx; i < perms.length - 1; i++) {
			perms[i] = perms[i + 1];
		}

		perms.pop();
		emit MeemEvents.MeemPermissionsSet(
			tokenId,
			propertyType,
			permissionType,
			perms
		);
	}

	function updatePermissionAt(
		uint256 tokenId,
		PropertyType propertyType,
		PermissionType permissionType,
		uint256 idx,
		MeemPermission memory permission
	) internal {
		LibERC721.requireOwnsToken(tokenId);
		MeemProperties storage props = LibProperties.getProperties(
			tokenId,
			propertyType
		);
		permissionNotLocked(props, permissionType);

		MeemPermission[] storage perms = getPermissions(props, permissionType);

		if (perms[idx].lockedBy != address(0)) {
			revert(Error.PropertyLocked);
		}

		perms[idx] = permission;
		emit MeemEvents.MeemPermissionsSet(
			tokenId,
			propertyType,
			permissionType,
			perms
		);
	}

	function validatePermissions(
		MeemPermission[] memory basePermissions,
		MeemPermission[] memory overridePermissions
	) internal pure {
		for (uint256 i = 0; i < overridePermissions.length; i++) {
			if (overridePermissions[i].lockedBy != address(0)) {
				// Find the permission in basePermissions
				bool wasFound = false;
				for (uint256 j = 0; j < basePermissions.length; j++) {
					if (
						basePermissions[j].lockedBy ==
						overridePermissions[i].lockedBy &&
						basePermissions[j].permission ==
						overridePermissions[i].permission &&
						basePermissions[j].numTokens ==
						overridePermissions[i].numTokens &&
						Array.isEqual(
							basePermissions[j].addresses,
							overridePermissions[i].addresses
						)
					) {
						wasFound = true;
						break;
					}
				}
				if (!wasFound) {
					revert(Error.MissingRequiredPermissions);
				}
			}
		}
	}

	function permissionNotLocked(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view {
		if (permissionType == PermissionType.Copy) {
			if (self.copyPermissionsLockedBy != address(0)) {
				revert(Error.PropertyLocked);
			}
		} else if (permissionType == PermissionType.Remix) {
			if (self.remixPermissionsLockedBy != address(0)) {
				revert(Error.PropertyLocked);
			}
		} else if (permissionType == PermissionType.Read) {
			if (self.readPermissionsLockedBy != address(0)) {
				revert(Error.PropertyLocked);
			}
		}
	}

	function getPermissions(
		MeemProperties storage self,
		PermissionType permissionType
	) internal view returns (MeemPermission[] storage) {
		if (permissionType == PermissionType.Copy) {
			return self.copyPermissions;
		} else if (permissionType == PermissionType.Remix) {
			return self.remixPermissions;
		} else if (permissionType == PermissionType.Read) {
			return self.readPermissions;
		}

		revert(Error.InvalidPermissionType);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// From Open Zeppelin contracts: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
	/**
	 * @dev Converts a `uint256` to its ASCII `string` representation.
	 */
	function strWithUint(string memory _str, uint256 value)
		internal
		pure
		returns (string memory)
	{
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
		bytes memory buffer;
		unchecked {
			if (value == 0) {
				return string(abi.encodePacked(_str, '0'));
			}
			uint256 temp = value;
			uint256 digits;
			while (temp != 0) {
				digits++;
				temp /= 10;
			}
			buffer = new bytes(digits);
			uint256 index = digits - 1;
			temp = value;
			while (temp != 0) {
				buffer[index--] = bytes1(uint8(48 + (temp % 10)));
				temp /= 10;
			}
		}
		return string(abi.encodePacked(_str, buffer));
	}

	function substring(
		string memory str,
		uint256 startIndex,
		uint256 numChars
	) internal pure returns (string memory) {
		bytes memory strBytes = bytes(str);
		bytes memory result = new bytes(numChars - startIndex);
		for (uint256 i = startIndex; i < numChars; i++) {
			result[i - startIndex] = strBytes[i];
		}
		return string(result);
	}

	function compareStrings(string memory a, string memory b)
		internal
		pure
		returns (bool)
	{
		return (keccak256(abi.encodePacked((a))) ==
			keccak256(abi.encodePacked((b))));
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}