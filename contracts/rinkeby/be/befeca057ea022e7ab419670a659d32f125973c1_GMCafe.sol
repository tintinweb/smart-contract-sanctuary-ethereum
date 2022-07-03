// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {IERC165} from "@openzeppelin/[email protected]/interfaces/IERC165.sol";
import {IERC721} from "@openzeppelin/[email protected]/interfaces/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/[email protected]/interfaces/IERC721Receiver.sol";
import {IERC721Metadata} from "@openzeppelin/[email protected]/interfaces/IERC721Metadata.sol";
import {IERC1155} from "@openzeppelin/[email protected]/interfaces/IERC1155.sol";

contract GMCafe is IERC165, IERC721, IERC721Metadata {

	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return interfaceId == 0x01ffc9a7 // ERC165
			|| interfaceId == 0x80ac58cd // ERC721
			|| interfaceId == 0x5b5e139f;// ERC721Metadata
	}

	error NullAddress();
	error InvalidMoo();
	error InvalidApproval();
	error InvalidReceiver();
	error InvalidLockState();
	error InsufficientPowers(uint256 mask);
	error AlreadyLoaded();

	event MooLocked(uint256 moo);
	event MooUnlocked(uint256 moo);
	event MooUnlockAttempt(uint256 moo, address indexed from);

	uint256 private constant MOO_COUNT = 333;
	uint256 private constant POWER_ADMIN = 0x1;
	uint256 private constant POWER_RESET = 0x2;
	bytes32 private constant DEFAULT_PASSWORD = keccak256(abi.encodePacked("moo"));

	struct MooData {
		address owner; 
		bool locked; // if locked
		uint40 transfers; // transfer count
		uint32 block0; // last transfer
		uint16 moo; // token (constant)
	}

	string _tokenURIPrefix;
	string _tokenURISuffix = ".json";
	bool _tokenURLSearch = true;
	bool _migrationLoaded;
	uint256 _migrated;

	mapping (uint256 => uint256) private _migration; //   old -> new
	mapping (address => uint256) private _balances;  // owner -> #moo
	mapping (uint256 => MooData) private _moos;    //   moo -> data:[..., owner]
	mapping (uint256 => bytes32) private _hashes;    //   moo -> hash 

	mapping (address => uint256) private _powers;
	mapping (address => mapping(address => bool)) private _operatorApprovals;
	mapping (uint256 => address) private _tokenApprovals;

	modifier requireValidMoo(uint256 moo) {
		if (moo == 0 || moo > MOO_COUNT) revert InvalidMoo();
		_;
	}

	modifier requirePower(uint256 mask) {
		if ((_powers[msg.sender] & mask) != mask) revert InsufficientPowers(mask);
		_;
	}

	constructor() {
        // debugging
		_powers[address(msg.sender)] = POWER_ADMIN | POWER_RESET;
		_mint(1);
		_balances[msg.sender] = 1;
	}

	function debugOSToken(uint256 index) public pure returns (uint256) {
		return _oldToken(index);
	}
	function debugMigration(uint256 token) public view returns (uint256) {
		return _migration[token];
	}
	function debugPower(address sender) public view returns (bool admin, bool reset) {
		uint256 power = _powers[sender];
		admin = (power & POWER_ADMIN) != 0;
		reset = (power & POWER_RESET) != 0;
	}

	function _oldToken(uint256 i) private pure returns (uint256) {
		return 0xB3457C2065FD1F384E9F05495251F2894D1659B6000000000000000000000001 | (i << 40);
	}
	function loadMigration(bytes calldata data) requirePower(POWER_ADMIN) public {
		if (_migrationLoaded) revert AlreadyLoaded();
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
				ptr := add(ptr, 2)
				temp := calldataload(ptr)
			}
			_migration[_oldToken(temp & 0xFFFF)] = moo;
		}
	}

	function updatePower(address sender, uint256 powers) requirePower(POWER_ADMIN) public {
		_powers[sender] = powers;
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

	function setTokenURIPrefix(string calldata s) requirePower(POWER_ADMIN) public {
		_tokenURIPrefix = s;
	}
	function setTokenURISuffix(string calldata s) requirePower(POWER_ADMIN) public {
		_tokenURISuffix = s;
	}
	function enableTokenURISearch(bool b) requirePower(POWER_ADMIN) public {
		_tokenURLSearch = b;
	}

	function tokenURI(uint256 moo) requireValidMoo(moo) public view returns (string memory uri) {
		uint256 dst;
		uri = _tokenURIPrefix;
		assembly {
			dst := add(uri, mload(uri))
			mstore(0x40, add(mload(0x40), 64))
		}
		dst = _appendIntHex(dst, moo, 3);
		dst = _appendBytes(dst, bytes(_tokenURISuffix)); 
		if (_tokenURLSearch) {
			MooData memory ref = _moos[moo];
			if (ref.owner != address(0)) {
				dst = _appendBytes(dst, "?l="); 
				dst = _appendIntHex(dst, ref.locked ? 1 : 0, 1);
				dst = _appendBytes(dst, "&b=");
				dst = _appendIntHex(dst, ref.block0, 8);
			} else {
				dst = _appendBytes(dst, "?u=1");
			}
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

	function dumpMoos() public view returns (uint256[] memory ret) {
		ret = new uint256[](MOO_COUNT);
		uint256 ptr;
		assembly {
			ptr := ret
		}
		uint256 moo;
		while (moo < MOO_COUNT) {
			MooData memory data = _moos[++moo];
			if (data.owner == address(0)) continue;
			assembly {
				ptr := add(ptr, 32)
				mstore(ptr, mload(data))
			}
		}
		assembly {
			mstore(ret, shr(5, sub(ptr, ret))) // truncate
		}
	}

	function _requireApproval(address owner, uint256 moo) private view {
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender) && getApproved(moo) != msg.sender) {
			revert InvalidApproval();
		}
	}

	function isLocked(uint256 moo) public view returns (bool) {
		return _hashes[moo] != 0;
	}
	function lockMoo(uint256 moo) public {
		lockMoo(moo, DEFAULT_PASSWORD);
	}
	function lockMoo(uint256 moo, bytes32 hash) public {
		if (hash == 0) revert InvalidLockState(); // invalid lock code
		MooData storage ref = _moos[moo];		
		if (ref.locked) revert InvalidLockState(); // already locked
		_requireApproval(ref.owner, moo);
		ref.locked = true;
		_hashes[moo] = hash;
		emit MooLocked(moo);
	}
	function unlockMoo(uint256 moo, string calldata password) public {
		MooData storage ref = _moos[moo];		
		if (!ref.locked) revert InvalidLockState(); // not locked
		_requireApproval(ref.owner, moo); 
		bytes32 hash = keccak256(abi.encodePacked(password));
		if (_hashes[moo] != hash) {
			emit MooUnlockAttempt(moo, msg.sender);
		} else {
			ref.locked = false;
			_hashes[moo] = 0;
			emit MooUnlocked(moo);
		}
	}
	function resetPassword(uint256 moo) requirePower(POWER_RESET) public {
		if (!_moos[moo].locked) revert InvalidLockState();
		_hashes[moo] = DEFAULT_PASSWORD;
	}

	// minting
	function _mint(uint256 moo) private {
		_moos[moo] = MooData({
			owner: msg.sender, 
			block0: uint32(block.number), 
			moo: uint16(moo),
			locked: false,
			transfers: 0
		});
		emit Transfer(address(0), msg.sender, moo); 
	}
	function migrate(uint256[] memory tokens) public {
		uint256 n = tokens.length;
		if (n == 0) revert InvalidMoo(); // no tokens
		uint256[] memory values = new uint256[](n);
		for (uint256 i; i < n; i++) {
			uint256 token = tokens[i];
			uint256 moo = _migration[token];
			if (moo == 0) revert InvalidMoo(); // already migrated or duplicate
			_migration[token] = 0;
			_mint(moo); 
			values[i] = 1;
		}
		IERC1155(0x495f947276749Ce646f68AC8c248420045cb7b5e).safeBatchTransferFrom(msg.sender, address(0xDEAD), tokens, values, '');
		_balances[msg.sender] += n;
		_migrated += n;
	}

	function claimUnmigratedMoos() requirePower(POWER_ADMIN) public {
		uint256 i;
		uint256 n;
		while (i < MOO_COUNT) {
			uint256 token = _oldToken(++i);
			uint256 moo = _migration[token];
			if (moo == 0) continue;
			_migration[token] = 0;
			_mint(moo);
			n++;
		}
		_balances[msg.sender] += n;
		_migrated += n;
	}

	function balanceOf(address owner) public view returns (uint256) {
		if (owner == address(0)) revert NullAddress();
		return _balances[owner];
	}
	function ownerOf(uint256 moo) public view returns (address) {
		return _moos[moo].owner;
	}
	
	// transfer
	function safeTransferFrom(address from, address to, uint256 moo) public {
		safeTransferFrom(from, to, moo, '');
	}
	function safeTransferFrom(address from, address to, uint256 moo, bytes memory data) public {
		transferFrom(from, to, moo);
		if (to.code.length != 0) {
			try IERC721Receiver(to).onERC721Received(msg.sender, from, moo, data) returns (bytes4 ret) {
				require(ret == IERC721Receiver(to).onERC721Received.selector);
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
		if (ref.owner != from) revert InvalidMoo(); // moo is not owned by from
		if (ref.locked) revert InvalidLockState();
		_requireApproval(from, moo);
		_balances[from]--;
		_balances[to]++;
		_tokenApprovals[moo] = address(0);
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
		if (owner != msg.sender && !isApprovedForAll(owner, msg.sender)) revert InvalidApproval();
		_tokenApprovals[moo] = to;
		emit Approval(owner, to, moo);
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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