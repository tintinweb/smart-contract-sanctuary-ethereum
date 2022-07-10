// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/[email protected]/access/Ownable.sol";
import {IERC165} from "@openzeppelin/[email protected]/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/[email protected]/token/ERC721/IERC721.sol";
import {ENS} from "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import {IAddrResolver} from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddrResolver.sol";
import {IAddressResolver} from "@ensdomains/ens-contracts/contracts/resolvers/profiles/IAddressResolver.sol";

contract ENSNFT is Ownable, IAddrResolver, IAddressResolver {

	function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
		return interfaceId == type(IERC165).interfaceId 
			|| interfaceId == type(IAddrResolver).interfaceId
			|| interfaceId == type(IAddressResolver).interfaceId;
	}

	error AlreadyEnabled();

	ENS constant _ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
	IERC721 public _nft; 
	string public _name;
	bytes32 public _node;
	mapping (bytes32 => uint256) _nodes;

	constructor(string memory name, address nft) {
		_name = name;
		_node = _namehash(name);
		_nft = IERC721(nft);
	}
	function destroy() public onlyOwner {
		selfdestruct(payable(msg.sender));
	}

	function isENSApproved() public view returns (bool) {
		return _ens.isApprovedForAll(_ens.owner(_node), address(this));
	}

	// note: it's impossible to enable token = 0xFF...FF = ~0
	function isEnabled(uint256 token) public view returns (bool) {
		return _isSubnodeSetup(_namehash(nameFromToken(token)));
	}
	function enable(uint256 token) public {
		if (!_setupSubnodeForToken(token)) revert AlreadyEnabled();
	}
	function batchEnable(uint256[] calldata tokens) public {
		 unchecked {
			uint256 any;
			for (uint256 i; i < tokens.length; i++) {
				if (_setupSubnodeForToken(tokens[i])) {
					any = 1;
				}
			}
			if (any == 0) revert AlreadyEnabled();
		}		
	}

	// subnodes
	function _isSubnodeSetup(bytes32 node) private view returns (bool) {
		return _nodes[node] != 0 
			&& _ens.owner(node) == address(this) 
			&& _ens.resolver(node) == address(this);
	}
	function _setupSubnodeForToken(uint256 token) private returns (bool) {
		string memory name = nameFromToken(token);
		bytes32 node = _namehash(name);
		if (_isSubnodeSetup(node)) return false;
		uint256 len = _lengthBase10(token);
		assembly {
			mstore(name, len) // truncate
		}
		_ens.setSubnodeRecord(_node, _labelhash(name, 0, len), address(this), address(this), 0);
		_nodes[node] = ~token;
		return true;
	}
	function _lengthBase10(uint256 token) private pure returns (uint256 len) {
		unchecked {
			len = 1;
			while (token >= 10) {
				token /= 10;
				len++;
			} 
		}
	}
	function nameFromToken(uint256 token) public view returns (string memory) {
		unchecked {
			bytes memory name = bytes(_name);
			uint256 len = _lengthBase10(token) + 1; // "123" + "."
			bytes memory buf = new bytes(len + name.length);
			assembly {
				for {
					let src := name
					let end := add(src, mload(src))
					let dst := add(buf, len)
				} lt(src, end) {} {
					src := add(src, 32)
					dst := add(dst, 32)
					mstore(dst, mload(src))
				}
				mstore(buf, add(len, mload(name)))
			}
			buf[--len] = '.';
			while (len > 0) {
				buf[--len] = bytes1(uint8(48 + (token % 10)));
				token /= 10;
			}
			return string(buf);
		}
	}
	function nodeFromToken(uint256 token) public view returns (bytes32) {
		return _namehash(nameFromToken(token));
	}

	// ens resolver
	function addr(bytes32 node) public view returns (address payable ret) {
		uint256 token = _nodes[node];
		if (token != 0) {
			return payable(_nft.ownerOf(~token));
		}
	}
	function addr(bytes32 node, uint256 coinType) public view returns(bytes memory ret) {
		if (coinType == 60) { // ETH
			return abi.encodePacked(addr(node));
		}
	}

	// ens helpers
	function _namehash(string memory domain) private pure returns (bytes32 node) {
		unchecked {
			uint256 i = bytes(domain).length;
			uint256 e = i;
			node = bytes32(0);
			while (i > 0) {
				if (bytes(domain)[--i] == '.') {
					node = keccak256(abi.encodePacked(node, _labelhash(domain, i + 1, e)));
					e = i;
				}
			}
			node = keccak256(abi.encodePacked(node, _labelhash(domain, i, e)));
		}
	}
	function _labelhash(string memory domain, uint start, uint end) private pure returns (bytes32 hash) {
		assembly ("memory-safe") {
			hash := keccak256(add(add(domain, 0x20), start), sub(end, start))
		}
	}

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the new (multicoin) addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

/**
 * Interface for the legacy (ETH-only) addr function.
 */
interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

pragma solidity >=0.8.4;

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
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