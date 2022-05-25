// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/*
	pay_gem = token we are paying for the transaction ($PXP, an ERC20)
	buy_gem = token we are buying (ERC1155)
*/ 
contract EventfulMarket {
	event LogItemUpdate(uint256 id); 

	event LogTrade(
		uint256 pay_amount,
		address indexed pay_gem,
		uint256 buy_amount,
		address indexed buy_gem,
		uint256 token_id
	);

	event LogMake(
		bytes32 indexed id,
		bytes32 indexed pair, 
		address indexed maker, 
		IERC20 pay_gem,
		IERC1155 buy_gem,
		uint128 pay_amt,
		uint128 buy_amt,
		uint64 timestamp,
		uint256 token_id
	); 

	event LogBump(
		bytes32 id,
		bytes32 indexed pair,
		address indexed maker,
		IERC20 pay_gem,
		IERC1155 buy_gem,
		uint128 pay_amt,
		uint128 buy_amt,
		uint64 timestamp,
		uint256 token_id
	); 

	event LogTake(
		bytes32 id,
		bytes32 indexed pair,
		address indexed maker,
		address  indexed  taker,
		IERC20 pay_gem,
		IERC1155 buy_gem,
		uint128 take_amt,
		uint128 give_amt,
		uint64 timestamp,
		uint256 token_id
	);

	event LogKill(
		bytes32 indexed id,
		bytes32 indexed pair,
		address indexed maker,
		IERC20 pay_gem,
		IERC1155 buy_gem,
		uint128 pay_amt,
		uint128 buy_amt,
		uint64 timestamp,
		uint256 token_id
	);
}

contract OrderBook is EventfulMarket, IERC1155Receiver, Ownable, ReentrancyGuard  {
	uint256 public last_offer_id;
	bool locked; 
	address public payGemAddress; // Address of the ERC20 to accept as payment. 

	mapping (uint => OfferInfo) public offers;

	mapping (address => bool) public whitelistedNft;	

	struct OfferInfo {
		uint256 pay_amt; 
		IERC20 pay_gem;
		uint256 buy_amt;
		IERC1155 buy_gem;
		address owner; 
		uint64 timestamp;
		uint256 token_id; 
	}

	/** 
	* @notice modifier to make sure that the offer is active. 
	*/
	modifier canBuy(uint256 id) {
		require(isActive(id), "Not an active id");
		_;
	}

	/** 
	* @notice modifier to make sure that the offer can be canceled
	*/
	modifier canCancel(uint256 id) {
		require(isActive(id), "Order is not active");
		require(getOwner(id) == msg.sender, "Owner id is not message sender");
		_;
	}

	/** 
	* @notice modifier to make sure that the offer is active. 
	* @dev we check this by the timestamp. An offer that hasn't been 
	* created or has already been purchased will return a timestamp of 0. 
	* @return active boolean of is the offer active. 
	*/
	function isActive(uint256 id) public view returns (bool active) {
		return offers[id].timestamp > 0;
	}

	/** 
	* @notice gets the owner of the offer
	* @param id id of the offer
	* @return owner address of the owner
	*/
	function getOwner(uint256 id) public view returns (address owner) {
		return offers[id].owner;
	}

	/** 
	* @notice gets the offer struct 
	* @param id id of the offer
	* @return OfferInfo struct
	*/
	function getOffer(uint256 id) public view returns (uint256, IERC20, uint256, IERC1155) {
		OfferInfo memory thisOffer = offers[id];
		return (thisOffer.pay_amt, thisOffer.pay_gem,
				thisOffer.buy_amt, thisOffer.buy_gem);
	}

	/* 
		Public entrypoints
	 */ 
	 
	/**
	 * @dev Accept given quantity of an offer. Transfers funds 
	 * from caller to offer maker, and from market to caller. 
	 * @param id offer id
	 * @param quantity quantity to purchase
	 * @return bool of purchase success
	 */ 
    function buy(uint id, uint quantity)
        public
        canBuy(id)
        nonReentrant
        returns (bool)
    {
        OfferInfo storage thisOffer = offers[id];
        uint spend = (quantity * thisOffer.pay_amt) / thisOffer.buy_amt;
        require(uint128(spend) == spend, "Spend is not equal.");
        require(uint128(quantity) == quantity, "Quantity is not equal.");
		if (quantity == 0 || spend == 0) {
            return false;
        }

        offers[id].pay_amt = thisOffer.pay_amt - spend; 
        offers[id].buy_amt = thisOffer.buy_amt - quantity;

		IERC1155(thisOffer.buy_gem).safeTransferFrom(
			address(this), 
			msg.sender, 
			thisOffer.token_id, 
			quantity, 
			""
		);

		IERC20(thisOffer.pay_gem).transferFrom(msg.sender, thisOffer.owner, spend);

        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            keccak256(abi.encodePacked(thisOffer.pay_gem, thisOffer.buy_gem)),
            thisOffer.owner,
            msg.sender,
            thisOffer.pay_gem,
            thisOffer.buy_gem,
            uint128(quantity),
            uint128(spend),
            uint64(block.timestamp),
			thisOffer.token_id
        );
        emit LogTrade(
			quantity, 
			address(thisOffer.pay_gem), 
			spend, 
			address(thisOffer.buy_gem), 
			thisOffer.token_id
		);

        if (offers[id].pay_amt == 0) {
          delete offers[id];
        }

        return true;
    }

	/** 
	* @notice kills a particular offer
	* @param id offer to kill 
	*/
	function kill(uint256 id) public {
		require(cancel(id));
	}

	/**
	 * @notice Makes a new available offer on the marketplace
	 * @param pay_gem Token required to pay for the offer. 
	 * @param buy_gem ERC1155 for sale
	 * @param pay_amt amount of pay_gem token required
	 * @param buy_amt amount of the ERC1155 for sale
	 * @param token_id id of the ERC1155
	 * @return id offer identifier
	 */ 
	function make(
		IERC20 pay_gem,
		IERC1155 buy_gem,
		uint128 pay_amt,
		uint128 buy_amt,
		uint256 token_id
	) public returns (bytes32 id)
	{
		return bytes32(offer(pay_amt, pay_gem, buy_amt, buy_gem, token_id));
	}

	/**
	 * @notice Makes a new available offer on the marketplace
	 * @param pay_gem Token required to pay for the offer. 
	 * @param buy_gem ERC1155 for sale
	 * @param pay_amt amount of pay_gem token required
	 * @param buy_amt amount of the ERC1155 for sale
	 * @param token_id id of the ERC1155
	 * @return id offer identifier
	 */ 
    function offer(uint256 pay_amt, IERC20 pay_gem, uint256 buy_amt, IERC1155 buy_gem, uint256 token_id)
        public
        nonReentrant
        returns (uint id)
    {
		require(address(pay_gem) == payGemAddress, "Wrong pay_gem specified"); 
		require(whitelistedNft[address(buy_gem)] == true, "Not a whitelisted 1155");
        require(uint256(pay_amt) == pay_amt);
        require(uint256(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(buy_amt > 0);

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
		info.token_id = token_id;
        info.owner = msg.sender;
        info.timestamp = uint64(block.timestamp);
        id = _nextId();
        offers[id] = info;

		IERC1155(buy_gem).safeTransferFrom(
			msg.sender, 
			address(this), 
			token_id, 
			buy_amt, 
			""
		);

        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(block.timestamp),
			token_id
        );
    }

	/**
	 * @notice Cancels an offer id.
	 * @param id identifier of the offer to cancel.
	 * @return success cancelation success status.
	 */ 
    function cancel(uint id)
        public
        canCancel(id)
        nonReentrant
        returns (bool success)
    {
        // read-only offer. Modify an offer by directly accessing offers[id]
        OfferInfo memory thisOffer = offers[id];
        delete offers[id];

		IERC1155(thisOffer.buy_gem).safeTransferFrom(
			address(this), 
			msg.sender, 
			thisOffer.token_id, 
			thisOffer.buy_amt, 
			""
		);
		
        emit LogItemUpdate(id);
        emit LogKill(
            bytes32(id),
            keccak256(abi.encodePacked(thisOffer.pay_gem, thisOffer.buy_gem)),
            thisOffer.owner,
            thisOffer.pay_gem,
            thisOffer.buy_gem,
            uint128(thisOffer.pay_amt),
            uint128(thisOffer.buy_amt),
            uint64(block.timestamp),
			thisOffer.token_id
        );

        success = true;
    }

	/**
	 * @notice Accept the specific offer and purchase. 
	 * @param id identifier of the offer. 
	 * @param maxTakeAmount maximum amount of the ERC1155 to purchase. 
	 */ 
	function take(bytes32 id, uint128 maxTakeAmount)
        public
    {
        require(buy(uint256(id), maxTakeAmount));
    }

	/** 
	 * @dev computes the id for the next offer 
	 * @return offer id 
	 */
	function _nextId() internal returns (uint256) {
		last_offer_id++; return last_offer_id;
	}

	/** Whitelisting */

	/** 
	 * @notice Whitelists a specific 1155 address for our marketplace whitelist. 
	 * @param _addr address to whitelist. 
	 */
	function whitelistNft(address _addr) external onlyOwner {
		whitelistedNft[_addr] = true;
	}

	/** 
	 * @notice Removes a specific 1155 address for our marketplace whitelist. 
	 * @param _addr address to renmove from whitelist. 
	 */
	function removeNftFromWhitelist(address _addr) external onlyOwner {
		whitelistedNft[_addr] = false;
	}

	/** 
	 * @notice Whether an 1155 is whitelisted or not
	 * @param _addr address to see whitelist status for
	 * @return bool whitelist status
	 */
	function isWhitelistedNft(address _addr) external view returns (bool) {
		return whitelistedNft[_addr];
	}

	/** 
	 * @notice Sets the ERC20 pay_gem address
	 * @dev this will most likely always be PXP
	 * @param _addr address of the ERC20 to set as pay gem
	 */
	function setPayGemAddress(address _addr) external onlyOwner {
		payGemAddress = _addr; 
	}

	/** IERC1155Receiver */

    function onERC1155Received(
		address, address, uint256, uint256, bytes memory
	) public virtual override(IERC1155Receiver) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
		address, address, uint256[] memory, uint256[] memory, bytes memory
	) public virtual override(IERC1155Receiver) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

	function supportsInterface(
		bytes4 interfaceId
	) external view override(IERC165) returns (bool) {
		return this.supportsInterface(interfaceId);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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