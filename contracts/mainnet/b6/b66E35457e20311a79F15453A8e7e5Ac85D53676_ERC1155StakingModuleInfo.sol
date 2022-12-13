// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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

/*
ERC1155StakingModule

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/IStakingModule.sol";

/**
 * @title ERC721 staking module
 *
 * @notice this staking module allows users to deposit one or more ERC721
 * tokens in exchange for shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC1155StakingModule is IStakingModule {
	// constant
	uint256 public constant SHARES_PER_TOKEN = 10**18;
	mapping(uint256 => uint256) public sharePerTokenId;

	// members
	IERC1155 private immutable _token;
	address public immutable _factory;

	mapping(address => uint256) public userTotalBalance;
	mapping(address => mapping(uint256 => uint256)) public counts;
	mapping(uint256 => address) public owners;
	mapping(address => mapping(uint256 => uint256)) public tokenByOwner;
	mapping(uint256 => uint256) public tokenIndex;

	// newly defined
	uint256 private totalBalance;

	uint256[] public stakedTokenIds;

	event StakedERC1155(address user, address token, uint256[] tokenIds, uint256[] amounts, uint256 shares);

	// checksum
	bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

	/**
	 * @param token_ the token that will be rewarded
	 */
	constructor(address token_, address factory_) {
		require(
			IERC165(token_).supportsInterface(0xd9b67a26),
			"Interface ID not matched"
		);
		_token = IERC1155(token_);
		_factory = factory_;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function tokens()
		external
		view
		override
		returns (address[] memory tokens_)
	{
		tokens_ = new address[](1);
		tokens_[0] = address(_token);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function balances(address user)
		external
		view
		override
		returns (uint256[] memory balances_)
	{

		balances_ = new uint256[](1);
		balances_[0] = userTotalBalance[user];
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function factory() external view override returns (address) {
		return _factory;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function totals()
		external
		view
		override
		returns (uint256[] memory totals_)
	{
		totals_ = new uint256[](1);
		totals_[0] = totalBalance;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	// function stake(
	// 	address user,
	// 	uint256 amount,
	// 	bytes calldata data
	// ) external override onlyOwner returns (address, uint256) {
	// 	// validate
	// 	require(amount > 0, "Staking amount must be greater than 0");
	// 	require(amount <= _token.balanceOf(user), "Insufficient balance");
	// 	require(data.length == 32 * amount, "Invalid calldata");

	// 	uint256 count = counts[user];

	// 	// stake
	// 	for (uint256 i = 0; i < amount; i++) {
	// 		// get token id
	// 		uint256 id;
	// 		uint256 pos = 132 + 32 * i;
	// 		assembly {
	// 			id := calldataload(pos)
	// 		}

	// 		// ownership mappings
	// 		owners[id] = user;
	// 		uint256 len = count + i;
	// 		tokenByOwner[user][len] = id;
	// 		tokenIndex[id] = len;

	// 		// transfer to module
	// 		_token.transferFrom(user, address(this), id);
	// 	}

	// 	// update position
	// 	counts[user] = count + amount;

	// 	// emit
	// 	uint256 shares = amount * SHARES_PER_TOKEN;
	// 	emit Staked(user, address(_token), amount, shares);

	// 	return (user, shares);
	// }

	function stake(
		address user,
		uint256 amount,
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {
		require(data.length == 32, "Invalid calldata");

		uint256 tokenId;

		assembly {
			tokenId := calldataload(68)
		}

		uint256 shares = amount * sharePerTokenId[tokenId];

		emit Staked(user, address(_token), amount, shares);
		return (user, shares);
	}

	function _stake(
		address user, 
		uint256[] memory tokenIds, 
		uint256[] memory amounts
	) 
		internal returns (address, uint256) {

		uint256 shares;

		for (uint256 i = 0; i < tokenIds.length; i++) {
			require(amounts[i] > 0, "Staking amount must be greater than 0");
			counts[user][tokenIds[i]] = counts[user][tokenIds[i]] + amounts[i];
			userTotalBalance[user] = userTotalBalance[user] + amounts[i];
			
			shares = shares + amounts[i] * sharePerTokenId[tokenIds[i]];

			totalBalance = totalBalance + amounts[i];

			stakedTokenIds.push(tokenIds[i]);
		}

		emit StakedERC1155(user, address(_token), tokenIds, amounts, shares);

		return (user, shares);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	// function unstake(
	// 	address user,
	// 	uint256 amount,
	// 	bytes calldata data
	// ) external override onlyOwner returns (address, uint256) {
	// 	// validate
	// 	require(amount > 0, "Unstaking amount must be greater than 0");
	// 	uint256 count = counts[user];
	// 	require(amount <= count, "Insufficient staked balance");
	// 	require(data.length == 32 * amount, "Invalid calldata");

	// 	// unstake
	// 	for (uint256 i = 0; i < amount; i++) {
	// 		// get token id
	// 		uint256 id;
	// 		uint256 pos = 132 + 32 * i;
	// 		assembly {
	// 			id := calldataload(pos)
	// 		}

	// 		// ownership
	// 		require(owners[id] == user, "Only owner can unstake");
	// 		delete owners[id];

	// 		// clean up ownership mappings
	// 		uint256 lastIndex = count - 1 - i;
	// 		if (amount != count) {
	// 			// reindex on partial unstake
	// 			uint256 index = tokenIndex[id];
	// 			if (index != lastIndex) {
	// 				uint256 lastId = tokenByOwner[user][lastIndex];
	// 				tokenByOwner[user][index] = lastId;
	// 				tokenIndex[lastId] = index;
	// 			}
	// 		}
	// 		delete tokenByOwner[user][lastIndex];
	// 		delete tokenIndex[id];

	// 		// transfer to user
	// 		_token.safeTransferFrom(address(this), user, id);
	// 	}

	// 	// update position
	// 	counts[user] = count - amount;

	// 	// emit
	// 	uint256 shares = amount * SHARES_PER_TOKEN;
	// 	emit Unstaked(user, address(_token), amount, shares);

	// 	return (user, shares);
	// }

	function unstake(
		address user,
		uint256 amount,
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {

		require(data.length == 32, "Invalid calldata");

		uint256 tokenId;

		assembly {
			tokenId := calldataload(68)
		}

		require(amount > 0, "Unstaking amount must be greater than 0");
		require(counts[user][tokenId] >= amount, "Insufficient staked balance");

		counts[user][tokenId] = counts[user][tokenId] - amount;
		userTotalBalance[user] = userTotalBalance[user] - amount;

		// decrease total balance
		totalBalance = totalBalance - amount;

		_token.safeTransferFrom(address(this), user, tokenId, amount, "");

		uint256 shares = amount * sharePerTokenId[tokenId];

		emit Unstaked(user, address(_token), amount, shares);
		return (user, shares);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	// function claim(
	// 	address user,
	// 	uint256 amount,
	// 	bytes calldata
	// ) external override onlyOwner returns (address, uint256) {
	// 	// validate
	// 	require(amount > 0, "Claiming amount must be greater than 0");
	// 	require(amount <= counts[user], "Insufficient balance");

	// 	uint256 shares = amount * SHARES_PER_TOKEN;
	// 	emit Claimed(user, address(_token), amount, shares);
	// 	return (user, shares);
	// }

	function claim(
		address user, 
		uint256 amount, 
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {
		require(data.length == 32, "Invalid calldata");
		
		require(amount > 0, "Claiming amount must be greater than 0");
		uint256 tokenId;

		assembly {
			tokenId := calldataload(68)
		}

		require(amount <= counts[user][tokenId], "Insufficient balance");

		uint256 shares = amount * sharePerTokenId[tokenId];
		emit Claimed(user, address(_token), amount, shares);
		return (user, shares);
	}

	function getStakedTokenIds() public view returns (uint256[] memory) {
		return stakedTokenIds;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function update(address) external override {}

	/**
	 * @inheritdoc IStakingModule
	 */
	function clean() external override {}

	 /**
        ERC1155 receiver
     */
    function onERC1155Received(
		address _operator,
		address _from, 
		uint256 _id, 
		uint256 _amount, 
		bytes memory _data
	)
    public returns(bytes4)
    {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = _id;
        amounts[0] = _amount;

        require(
        ERC1155_BATCH_RECEIVED_VALUE == onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
        "NE20#28"
        );

        return ERC1155_RECEIVED_VALUE;
    }

    function onERC1155BatchReceived(
        address, // _operator,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory)
    public returns(bytes4)
    {
        _stake(_from, _ids, _amounts);
        return ERC1155_BATCH_RECEIVED_VALUE;
    }
}

/*
ERC721StakingModuleInfo

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import "../interfaces/IStakingModule.sol";
import "../ERC1155StakingModule.sol";

/**
 * @title ERC1155 staking module info library
 *
 * @notice this library provides read-only convenience functions to query
 * additional information about the ERC1155StakingModule contract.
 */
library ERC1155StakingModuleInfo {
    /**
     * @notice convenience function to get token metadata in a single call
     * @param module address of staking module
     * @return uri
     */
    function token(address module)
        public
        view
        returns (string memory)
    {
        IStakingModule m = IStakingModule(module);
        IERC1155MetadataURI tkn = IERC1155MetadataURI(m.tokens()[0]);
        if (!tkn.supportsInterface(0x0e89341c)) {
            return "";
        }
        return "";
    }

    /**
     * @notice quote the share value for an amount of tokens
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens. if zero, return entire share balance
     * @return number of shares
     */
    function shares(
        address module,
        address addr,
        uint256 amount
    ) public view returns (uint256) {
        ERC1155StakingModule m = ERC1155StakingModule(module);

        // return all user shares
        if (amount == 0) {
            return m.userTotalBalance(addr) * m.SHARES_PER_TOKEN();
        }

        require(amount <= m.userTotalBalance(addr), "smni1");
        return amount * m.SHARES_PER_TOKEN();
    }

    /**
     * @notice get shares per token
     * @param module address of staking module
     * @return current shares per token
     */
    function sharesPerToken(address module) public view returns (uint256) {
        ERC1155StakingModule m = ERC1155StakingModule(module);
        return m.SHARES_PER_TOKEN() * 1e18;
    }

    /**
     * @notice get staked token ids for user
     * @param module address of staking module
     * @param addr account address of interest
     * @param amount number of tokens to enumerate
     * @param start token index to start at
     * @return ids array of token ids
     */
    function tokenIds(
        address module,
        address addr,
        uint256 amount,
        uint256 start
    ) public view returns (uint256[] memory ids) {
        ERC1155StakingModule m = ERC1155StakingModule(module);
        uint256 sz = m.userTotalBalance(addr);
        require(start + amount <= sz, "smni2");

        if (amount == 0) {
            amount = sz - start;
        }

        ids = new uint256[](amount);

        for (uint256 i = 0; i < amount; i++) {
            ids[i] = m.tokenByOwner(addr, i + start);
        }
    }
}

/*
IEvents

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
 */

pragma solidity 0.8.4;

/**
 * @title GYSR event system
 *
 * @notice common interface to define GYSR event system
 */
interface IEvents {
    // staking
    event Staked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Unstaked(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event Claimed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );

    // rewards
    event RewardsDistributed(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 shares
    );
    event RewardsFunded(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );
    event RewardsUnlocked(address indexed token, uint256 shares);
    event RewardsExpired(
        address indexed token,
        uint256 amount,
        uint256 shares,
        uint256 timestamp
    );

    // gysr
    event GysrSpent(address indexed user, uint256 amount);
    event GysrVested(address indexed user, uint256 amount);
    event GysrWithdrawn(uint256 amount);
}

/*
IStakingModule

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IEvents.sol";

import "../OwnerController.sol";

/**
 * @title Staking module interface
 *
 * @notice this contract defines the common interface that any staking module
 * must implement to be compatible with the modular Pool architecture.
 */
abstract contract IStakingModule is OwnerController, IEvents {
    // constants
    uint256 public constant DECIMALS = 18;

    /**
     * @return array of staking tokens
     */
    function tokens() external view virtual returns (address[] memory);

    /**
     * @notice get balance of user
     * @param user address of user
     * @return balances of each staking token
     */
    function balances(address user)
        external
        view
        virtual
        returns (uint256[] memory);

    /**
     * @return address of module factory
     */
    function factory() external view virtual returns (address);

    /**
     * @notice get total staked amount
     * @return totals for each staking token
     */
    function totals() external view virtual returns (uint256[] memory);

    /**
     * @notice stake an amount of tokens for user
     * @param user address of user
     * @param amount number of tokens to stake
     * @param data additional data
     * @return address of staking account
     * @return number of shares minted for stake
     */
    function stake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice unstake an amount of tokens for user
     * @param user address of user
     * @param amount number of tokens to unstake
     * @param data additional data
     * @return address of staking account
     * @return number of shares burned for unstake
     */
    function unstake(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice quote the share value for an amount of tokens without unstaking
     * @param user address of user
     * @param amount number of tokens to claim with
     * @param data additional data
     * @return address of staking account
     * @return number of shares that the claim amount is worth
     */
    function claim(
        address user,
        uint256 amount,
        bytes calldata data
    ) external virtual returns (address, uint256);

    /**
     * @notice method called by anyone to update accounting
     * @param user address of user for update
     * @dev will only be called ad hoc and should not contain essential logic
     */
    function update(address user) external virtual;

    /**
     * @notice method called by owner to clean up and perform additional accounting
     * @dev will only be called ad hoc and should not contain any essential logic
     */
    function clean() external virtual;
}

/*
OwnerController

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

/**
 * @title Owner controller
 *
 * @notice this base contract implements an owner-controller access model.
 *
 * @dev the contract is an adapted version of the OpenZeppelin Ownable contract.
 * It allows the owner to designate an additional account as the controller to
 * perform restricted operations.
 *
 * Other changes include supporting role verification with a require method
 * in addition to the modifier option, and removing some unneeded functionality.
 *
 * Original contract here:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract OwnerController {
    address private _owner;
    address private _controller;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event ControlTransferred(
        address indexed previousController,
        address indexed newController
    );

    constructor() {
        _owner = msg.sender;
        _controller = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
        emit ControlTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the current controller.
     */
    function controller() public view returns (address) {
        return _controller;
    }

    /**
     * @dev Modifier that throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner can perform this action");
        _;
    }

    /**
     * @dev Modifier that throws if called by any account other than the controller.
     */
    modifier onlyController() {
        require(_controller == msg.sender, "Only controller can perform this action");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function requireOwner() internal view {
        require(_owner == msg.sender, "Only owner can perform this action");
    }

    /**
     * @dev Throws if called by any account other than the controller.
     */
    function requireController() internal view {
        require(_controller == msg.sender, "Only controller can perform this action");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`). This can
     * include renouncing ownership by transferring to the zero address.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual {
        requireOwner();
        require(newOwner != address(0), "New owner address can't be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers control of the contract to a new account (`newController`).
     * Can only be called by the owner.
     */
    function transferControl(address newController) public virtual {
        requireOwner();
        require(newController != address(0), "New controller address can't be zero");
        emit ControlTransferred(_controller, newController);
        _controller = newController;
    }
}