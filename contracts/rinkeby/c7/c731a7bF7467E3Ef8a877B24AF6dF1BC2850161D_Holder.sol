// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./HolderState.sol";


contract Holder is IERC721Receiver, HolderState
{
	function onERC721Received(address, address, uint256, bytes memory) 
	virtual override public returns(bytes4)
	{
		return this.onERC721Received.selector;
	}
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
pragma solidity >=0.8.0 <=0.9.0;

import "./domain/ExchangeState.sol";
import "../access/ProxyAccess.sol";

abstract contract HolderState is ProxyAccess {
	mapping (bytes32 => ExchangeState.AssetType) public assetTypes;

	bytes32 public constant EXCHANGE_ROLE = keccak256("EXCHANGE_ROLE");

	/**
		@dev Set asset token type, which type it's pin on market
		@notice This action MUST be call anytime when an asset token pin on market.
	 */
	function set(bytes32 key, ExchangeState.AssetType assetType) external onlyAccess(EXCHANGE_ROLE)
	{
		assetTypes[key] = assetType;
	}

	/**
		@dev Get the state of asset type from holder
	 */
	function get(bytes32 key) external view returns(ExchangeState.AssetType)
	{
		return assetTypes[key];
	}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;



contract ExchangeState {
	enum SellState {Unavailable, Available}
	enum AssetType {NULL, Sell, Auction}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";


abstract contract ProxyAccess is Ownable {
	mapping(bytes32 => mapping(address => bool)) private _accesses;

	event GrantAccess(bytes32 role, address op);
	event RevokeAccess(bytes32 role, address op);


	modifier onlyAccess(bytes32 role) {
		require(hasAccess(role), "ProxyAccess: caller not have access");
		_;
	}


	function grantAccess(bytes32 role, address operator) external onlyOwner {
		_grantAccess(role, operator);
	}

	function revokeAccess(bytes32 role, address op) external onlyOwner {
		delete _accesses[role][op];
		emit RevokeAccess(role, op);
	}

	function hasAccess(bytes32 role) public view returns(bool) {
		return _accesses[role][_msgSender()] == true;
	}


	function _grantAccess(bytes32 role, address op) internal {
		_accesses[role][op] = true;
		emit GrantAccess(role, op);
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