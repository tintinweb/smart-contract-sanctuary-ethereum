// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {IERC165} from "@openzeppelin/[email protected]/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/[email protected]/token/ERC721/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin/[email protected]/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC1155} from "@openzeppelin/[email protected]/token/ERC1155/IERC1155.sol";

contract GMCafe is IERC165, IERC721, IERC721Metadata {

	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return interfaceId == 0x01ffc9a7 // ERC165
			|| interfaceId == 0x80ac58cd // ERC721
			|| interfaceId == 0x5b5e139f;// ERC721Metadata
	}

	error NullAddress();
	error ExpectedMoos();
	error InvalidMoo(uint256 moo);
	error InvalidApproval();
	error NotAllowed(uint256 moo);
	error InvalidReceiver();
	error InvalidLockState();
	error InsufficientPowers(uint256 mask);

	event MooLocked(uint256 moo);
	event MooUnlocked(uint256 moo);
	event MooUnlockAttempt(uint256 moo, address indexed from);

	uint256 private constant MOO_COUNT = 333;
	uint256 private constant CLAIM_DELAY = 90 days;
	uint256 private constant POWER_ADMIN	= 0x1;
	uint256 private constant POWER_METADATA = 0x2;

	//address private constant OPENSEA = 0x495f947276749Ce646f68AC8c248420045cb7b5e; // mainnet
	address private constant OPENSEA = 0x8d2372F1689B3cf8367E650814038E9473041Dbe; // rinkeby

	struct MooData {
		address owner; 
		uint8 lockStyle;  // 0 not-locked / 1-toggle / 2-pass+fee
		uint32 transfers; // transfer count
		uint32 block0;    // last transfer
	}

	struct Unlock {
		bytes32 hash;  // hash of your password
		uint256 price; // recovery price you set
	}

	string _tokenURIPrefix;
	string _tokenURISuffix = ".json";
	uint256 _claimableTime;
	bool _tokenURLSearch = true;
	bool _migrationLoaded;
	uint256 _migrated;

	mapping (uint256 => uint256) private _migration; //   old -> new
	mapping (address => uint256) private _balances;  // owner -> #moo
	mapping (uint256 => MooData) private _moos;      //   moo -> data:[..., owner]
	mapping (uint256 => Unlock)  private _unlocks;   //   moo -> [hash, price] 

	mapping (address => uint256) private _powers;
	mapping (address => mapping(address => bool)) private _operatorApprovals;
	mapping (uint256 => address) private _tokenApprovals;

	modifier requireValidMoo(uint256 moo) {
		if (moo == 0 || moo > MOO_COUNT) revert InvalidMoo(moo);
		_;
	}

	modifier requirePowers(uint256 mask) {
		if ((_powers[msg.sender] & mask) != mask) revert InsufficientPowers(mask);
		_;
	}

	function _requireApproval(address owner, uint256 moo) private view {
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender) && getApproved(moo) != msg.sender) {
			revert NotAllowed(moo);
		}
	}

	constructor() {
		_claimableTime = block.timestamp + CLAIM_DELAY;
		_powers[address(msg.sender)] = POWER_ADMIN | POWER_METADATA;
	}

	function debugOSToken(uint256 index) public pure returns (uint256) {
		return _oldToken(index);
	}
	function debugMigration(uint256 token) public view returns (uint256) {
		return _migration[token];
	}
	function debugPower(address sender) public view returns (bool admin, bool metadata) { 
		uint256 power = _powers[sender];
		admin    = (power & POWER_ADMIN) != 0;
		metadata = (power & POWER_METADATA) != 0;
	}
	function debugURIParts() public view returns (string memory prefix, string memory suffix, bool search) {
		prefix = _tokenURIPrefix;
		suffix = _tokenURISuffix;
		search = _tokenURLSearch;
	}

	function _oldToken(uint256 i) private pure returns (uint256) {
		return 0xB3457C2065FD1F384E9F05495251F2894D1659B6000000000000000000000001 | (i << 40);
	}
	function loadMigration(bytes calldata data) requirePowers(POWER_ADMIN) public {
		require(!_migrationLoaded, "migration already loaded");
		_migrationLoaded = true;
		uint256 ptr;
		uint256 end;
		assembly {
			ptr := data.offset
			end := add(ptr, data.length)
		}
		uint256 moo;
		while (ptr < end) {
			uint256 temp;
			assembly {
				moo := add(moo, 1)
				temp := calldataload(ptr)
				ptr := add(ptr, 2)
			}
			_migration[_oldToken(temp >> 240)] = moo;
		}
	}
	function timeUntilClaimable() public view returns (uint256) {
		return block.timestamp > _claimableTime ? 0 : _claimableTime - block.timestamp;
	}	
	function claimUnmigratedMoos(uint256 limit) requirePowers(POWER_ADMIN) public {
		if (limit == 0) revert ExpectedMoos();
		require(_migrated < MOO_COUNT, "all minted");
		require(block.timestamp > _claimableTime, "not yet");
		uint256 i;
		uint256 n;
		while (i < MOO_COUNT) {
			uint256 token = _oldToken(++i);
			uint256 moo = _migration[token];
			if (moo == 0) continue;
			delete _migration[token];
			_mint(moo);
			if (++n == limit) break;
		}
		_addMinted(n);
	}

	function updatePower(address sender, uint256 powers) requirePowers(POWER_ADMIN) public {
		_powers[sender] = powers;
	}
	function withdraw() requirePowers(POWER_ADMIN) public {
		payable(msg.sender).transfer(address(this).balance);
	}

	function name() public pure returns (string memory) {
		return "GMCafe";
	}

	function symbol() public pure returns (string memory) {
		return "MOO";
	}

	function totalSupply() external view returns (uint256) {
		return _migrated;
	}

	function setTokenURIPrefix(string calldata s) requirePowers(POWER_METADATA) public {
		_tokenURIPrefix = s;
	}
	function setTokenURISuffix(string calldata s) requirePowers(POWER_METADATA) public {
		_tokenURISuffix = s;
	}
	function enableTokenURISearch(bool b) requirePowers(POWER_METADATA) public {
		_tokenURLSearch = b;
	}

	function tokenURI(uint256 moo) requireValidMoo(moo) public view returns (string memory uri) {
		bytes memory suffix = bytes(_tokenURISuffix);
		uri = _tokenURIPrefix;
		uint256 dst;
		assembly {
			dst := add(uri, mload(uri))
			mstore(0x40, add(mload(0x40), add(mload(suffix), 73))) // 3 + 6 + 64
		}
		dst = _appendIntHex(dst, moo, 3);
		dst = _appendBytes(dst, suffix); 
		if (_tokenURLSearch) {
			MooData storage data = _moos[moo];			
			uint256 slot;
			assembly {
				slot := sload(data.slot)
			}
			dst = _appendBytes(dst, "?data="); 
			dst = _appendIntHex(dst, slot >> 128, 32);
			dst = _appendIntHex(dst, slot, 32);
			/*
			if (data.owner != address(0)) {
				dst = _appendBytes(dst, "?l="); 
				dst = _appendIntHex(dst, data.lockStyle, 1);
				dst = _appendBytes(dst, "&b=");
				dst = _appendIntHex(dst, data.block0, 8);
				dst = _appendBytes(dst, "&n=");
				dst = _appendIntHex(dst, data.transfers, 8);
				dst = _appendBytes(dst, "&a=");
				uint256 owner = uint160(data.owner);
				dst = _appendIntHex(dst, owner >> 128, 8);
				dst = _appendIntHex(dst, owner, 32);
			} else {
				dst = _appendBytes(dst, "?free");
			}
			*/
		}
		assembly {
			mstore(uri, sub(dst, uri))
		}
	}
	function _appendBytes(uint256 ptr, bytes memory data) private pure returns (uint256 dst) {
		uint256 src;
		assembly {
			src := data
			dst := add(ptr, mload(data))
		}
		while (ptr < dst) {
			assembly {
				ptr := add(ptr, 32)
				src := add(src, 32)
				mstore(ptr, mload(src))
			}
		}
	}
	function _appendIntHex(uint256 ptr, uint256 value, uint256 nibbles) private pure returns (uint256 dst) {
		dst = ptr + nibbles;
		uint256 mask = type(uint256).max << (nibbles << 3);
		uint256 buf;
		while (nibbles > 0) {
			uint256 x = (value >> (--nibbles << 2)) & 15;
			buf = (buf << 8) | (x < 10 ? 48 + x : 55 + x);
		}
		assembly {
			mstore(dst, or(and(mload(dst), mask), buf))
		}
	}


	function balanceOf(address owner) public view returns (uint256) {
		if (owner == address(0)) revert NullAddress();
		return _balances[owner];
	}
	function ownerOf(uint256 moo) public view returns (address) {
		return _moos[moo].owner;
	}
	function dumpMoos() public view returns (uint256[] memory ret) {
		ret = new uint256[](MOO_COUNT);
		uint256 ptr;
		assembly {
			ptr := ret
		}
		uint256 moo;
		while (moo < MOO_COUNT) {
			MooData storage data = _moos[++moo];
			if (data.owner == address(0)) continue;
			assembly {
				ptr := add(ptr, 32)
				mstore(ptr, or(sload(data.slot), shl(240, moo)))
			}
		}
		assembly {
			mstore(ret, shr(5, sub(ptr, ret))) // truncate
		}
	}

	function isLocked(uint256 moo) public view returns (bool) {
		return _moos[moo].lockStyle != 0;
	}
	function getUnlockPrice(uint256 moo) public view returns (uint256) {
		return _unlocks[moo].price;
	}	
	function lockMoo(uint256 moo) public { 
		MooData storage ref = _moos[moo];		
		if (ref.lockStyle != 0) revert InvalidLockState(); // already locked
		_requireApproval(ref.owner, moo);
		ref.lockStyle = 1;
		emit MooLocked(moo);
	}
	function lockMoo(uint256 moo, bytes32 hash, uint256 price) public {
		MooData storage ref = _moos[moo];		
		if (ref.lockStyle != 0) revert InvalidLockState(); // already locked
		_requireApproval(ref.owner, moo);
		ref.lockStyle = 2;
		_unlocks[moo] = Unlock({hash: hash, price: price});
		emit MooLocked(moo);
	}
	function unlockMoo(uint256 moo) payable public { 
		MooData storage ref = _moos[moo];
		if (ref.lockStyle == 0) revert InvalidLockState(); // not locked
		_requireApproval(ref.owner, moo); 
		if (ref.lockStyle == 2) { // secure lock
			if (_unlocks[moo].price > msg.value) revert InvalidLockState(); 
			delete _unlocks[moo];
		}
		ref.lockStyle = 0;
		emit MooUnlocked(moo);
	}
	function unlockMoo(uint256 moo, string memory password) public {
		MooData storage ref = _moos[moo];		
		if (ref.lockStyle != 2) revert InvalidLockState(); // not secure locked
		_requireApproval(ref.owner, moo); 
		bytes32 hash = keccak256(abi.encodePacked(password));
		if (_unlocks[moo].hash != hash) {
			emit MooUnlockAttempt(moo, msg.sender);
		} else {
			ref.lockStyle = 0;
			delete _unlocks[moo];
			emit MooUnlocked(moo);
		}
	}
	
	// minting
	function _mint(uint256 moo) private {
		_moos[moo] = MooData({
			owner: msg.sender, 
			block0: uint32(block.number), 
			lockStyle: 0,
			transfers: 0
		});
		emit Transfer(address(0), msg.sender, moo); 
	}
	function _addMinted(uint256 n) private {
		_balances[msg.sender] += n;
		_migrated += n;
	}

	function checkMigration(uint256[] memory tokens) public view {
		uint256 n = tokens.length;
		if (n == 0) revert ExpectedMoos();
		if (!IERC1155(OPENSEA).isApprovedForAll(msg.sender, address(this))) revert InvalidApproval();
		uint256 lower;
		uint256 upper;
		for (uint256 i; i < n; i++) {
			uint256 token = tokens[i];
			uint256 moo = _migration[token];
			if (moo == 0) revert InvalidMoo(token); // already migrated 
			uint256 mask = 1 << ((moo - 1) & 0xFF);
			if (moo > 256) {
				if (upper & mask != 0) revert InvalidMoo(moo); // duplicate
				upper |= mask;
			} else {
				if (lower & mask != 0) revert InvalidMoo(moo); // duplicate
				lower |= mask;
			}
			if (IERC1155(OPENSEA).balanceOf(msg.sender, token) == 0) revert NotAllowed(token); 
		}
	}

	function migrate(uint256[] memory tokens) public {
		uint256 n = tokens.length;
		if (n == 0) revert ExpectedMoos();
		address[] memory owners = new address[](n);
		for (uint256 i; i < n; i++) {
			owners[i] = msg.sender;
		}
		uint256[] memory balances = IERC1155(OPENSEA).balanceOfBatch(owners, tokens);
		for (uint256 i; i < n; i++) {
			uint256 token = tokens[i];
			if (balances[i] == 0) revert NotAllowed(token); // not directly owned
			uint256 moo = _migration[token];
			if (moo == 0) revert InvalidMoo(token); // already migrated (or duplicate)
			delete _migration[token];
			_mint(moo); 
		}
		IERC1155(OPENSEA).safeBatchTransferFrom(msg.sender, address(0xDEAD), tokens, balances, '');
		_addMinted(n);
	}

	// transfer
	function safeTransferFrom(address from, address to, uint256 moo) public {
		safeTransferFrom(from, to, moo, '');
	}
	function safeTransferFrom(address from, address to, uint256 moo, bytes memory data) public {
		transferFrom(from, to, moo);
		if (to.code.length != 0) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, moo, data) returns (bytes4 ret) {
				if (ret != IERC721Receiver(to).onERC721Received.selector) {
					revert InvalidReceiver();
				}
			} catch (bytes memory reason) {
				if (reason.length == 0) {
					revert InvalidReceiver();
				} else {
					assembly {
						revert(add(reason, 32), mload(reason))
					}
				}
			}
		}
	}
	function transferFrom(address from, address to, uint256 moo) public {
		if (to == address(0)) revert NullAddress();
		if (to == from) revert InvalidReceiver();
		MooData storage ref = _moos[moo];
		if (ref.owner != from) revert InvalidMoo(moo); // moo is not owned by from
		if (ref.lockStyle != 0) revert InvalidLockState();
		_requireApproval(from, moo);
		_balances[from]--;
		_balances[to]++;
		delete _tokenApprovals[moo]; // clear token approval
		ref.owner = to;
		ref.block0 = uint32(block.number);
		ref.transfers++;
		emit Transfer(from, to, moo);
	}

	// operator approvals
	function isApprovedForAll(address owner, address operator) public view returns (bool) {
		return _operatorApprovals[owner][operator];
	}
	function setApprovalForAll(address operator, bool approved) public {
		if (operator == msg.sender) revert InvalidApproval();
		_operatorApprovals[msg.sender][operator] = approved;
		emit ApprovalForAll(msg.sender, operator, approved);
	}

	// token approvals
	function getApproved(uint256 moo) requireValidMoo(moo) public view returns (address) {
		return _tokenApprovals[moo];
	}
	function approve(address to, uint256 moo) public {
		address owner = _moos[moo].owner;
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) revert NotAllowed(moo);
		_tokenApprovals[moo] = to;
		emit Approval(owner, to, moo);
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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