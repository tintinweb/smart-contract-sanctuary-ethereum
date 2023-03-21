// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
	IAssetHandler,
	Marketplace
} from "./lib/Marketplace.sol";

import {
	Order,
	Execution,
	Fulfillment
} from "./lib/Order.sol";

import "hardhat/console.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Exchange
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	@custom:contributor throw; <@0xthrpw>
	
	GigaMart is a new NFT platform built for the world by the SuperVerse DAO. 
	This is the first iteration of the exchange and is based on a delegated user 
	proxy architecture.
*/
contract GigaMart is ReentrancyGuard, Marketplace {

	/**
		Construct a new instance of the GigaMart exchange.

		@param _assetHandler The address of the existing manager contract.
		@param _validator The address of a privileged validator for permitting 
			collection administrators to control their royalty fees.
		@param _protocolFeeRecipient The address which receives fees from the 
			exchange.
		@param _protocolFeePercent The percent of fees taken by 
			`_protocolFeeRecipient` in basis points (1/100th %; i.e. 200 = 2%).
	*/
	constructor (
		IAssetHandler _assetHandler,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) Marketplace (
		_assetHandler,
		_validator,
		_protocolFeeRecipient,
		_protocolFeePercent
	) {}

	/**
		Allow the caller to cancel an order so long as they are the maker of the 
		order.

		@param _order The `Order` data to cancel.
	*/
	function cancelOrder (
		Order calldata _order
	) external {
		_cancelOrder(_order); 
	}

	/**
		Allow the caller to cancel a set of particular orders so long as they are 
		the maker of each order.

		@param _orders An array of `Order` data to cancel.
	*/
	function cancelOrders (
		Order[] calldata _orders
	) external {
		for (uint256 i; i < _orders.length; ) {
			_cancelOrder(_orders[i]);
			unchecked {
				++i;
			}
		}
	}

	/**
		Allow the caller to cancel all of their orders created with a nonce lower 
		than the new `_minNonce`.

		@param _minNonce The new nonce to use in mass-cancelation.

		@custom:throws NonceLowerThanCurrent if the provided nonce is not less than 
			the current nonce.
	*/
	function cancelAllOrders (
		uint256 _minNonce
	) external {
		_setNonce(_minNonce);
	}

	function exchangeSingleItem (
		Order calldata _order,
		bytes calldata _signature,
		address _fulfiller,
		Fulfillment calldata _fulfillment
	) external payable nonReentrant {
		_execute(_order, _signature, _fulfiller, _fulfillment);
	}

	function exchangeMultipleItems (
		Execution[] calldata _executions,
		bytes[] calldata _signatures,
		address _fulfiller,
		Fulfillment[] calldata _fulfillments
	) external payable nonReentrant {
		console.log("HERE");
		for (uint256 i; i < _executions.length;) {
			console.log("HERE");
			_execute_unsafe(
				_executions[i].toOrder(),
				_signatures[i],
				_fulfiller,
				_fulfillments[_executions[i].fillerIndex]
			);
			unchecked {
				++i;
			}
		}
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	Order,
	Trade,
	DutchAuction,
	CollectionOffer,
	Fulfillment,
	_deriveOrder
} from "./Order.sol";

import {
	ORDER_IS_OPEN,
	ORDER_IS_PARTIALLY_FILLED,
	ORDER_IS_FULFILLED,
	ORDER_IS_CANCELLED
} from "./OrderConstants.sol";

import {
	IAssetHandler,
	OrderFulfiller
} from "./OrderFulfiller.sol";

import {
	OrderVerifier
} from "./OrderVerifier.sol";

import {
	RoyaltyManager
} from "./RoyaltyManager.sol";

import {
	_getUserNonce,
	_setUserNonce,
	_getOrderStatus,
	_setOrderStatus
} from "./Storage.sol";

import {
	CalldataPointer,
	MemoryPointer,
	CALLDATA_START,
	ONE_WORD,
	FREE_MEMORY_POINTER,
	ECDSA_MAX_LENGTH,
	PREFIX,
	_freeMemoryPointer,
	_recover,
	_recoverContractSignature
} from "./Helpers.sol";

error InvalidMaker ();
error InvalidNonce ();
error InvalidAmount ();
error InvalidFulfiller ();
error InvalidSaleKind ();
error FulfillmentFailed ();
error InvalidOrderPeriod ();
error InvalidPaymentToken ();
error OrderTakerNotMatched ();
error OrderValidationFailed ();
error OrderAlreadyFulfilled ();
error OrderAlreadyCancelled ();
import "hardhat/console.sol";
contract Marketplace is OrderFulfiller, OrderVerifier, RoyaltyManager {

	/**
		Emitted when an order is canceled.

		@param maker The order maker's address.
		@param hash The hash of the order.
	*/
	event OrderCancelled (
		address indexed maker,
		bytes32 hash
	);

	/**
		Emitted when a user cancels all of their orders. All orders with a nonce 
		less than `minNonce` will be canceled.

		@param sender The caller who is canceling their orders.
		@param minNonce The new nonce to use in mass-cancelation.
	*/
	event AllOrdersCancelled (
		address indexed sender,
		uint256 minNonce
	);

	constructor(
		IAssetHandler _assetHandler,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) OrderFulfiller (
		_assetHandler
	) RoyaltyManager (
		_validator,
		_protocolFeeRecipient,
		_protocolFeePercent
	){}


	function _validateOrder(
		bytes32 hash,
		address _maker,
		bytes calldata _signature
	) internal view returns (bool) {

		// Verify order is still live.
		uint256 status = _getOrderStatus(hash);
		
		if (status == ORDER_IS_CANCELLED) {
			return false;
		}
		if (status == ORDER_IS_FULFILLED) {
			return false;
		}

		if (status == ORDER_IS_PARTIALLY_FILLED) {
			return true;
		}
		
		// Calculate digest before recovering signer's address.
		bytes32 digest = keccak256(
			abi.encodePacked(
				PREFIX,
				_deriveDomainSeparator(),
				_signature.length > ECDSA_MAX_LENGTH ?
					_computeBulkOrderProof(_signature, hash) :
					hash
			)
		);
		if (_maker == _recover(digest, _signature)) {
			return true;
		}

		if (_maker.code.length > 0) {
			return _recoverContractSignature(
				_maker,
				hash,
				_signature
			);
		} 

		return false;
	}

	function _execute (
		Order calldata _order,
		bytes calldata _signature,
		address _fulfiller,
		Fulfillment calldata _fulfillment
	) internal {

		// Prevent the item from being sent to the zero address.
		if (_fulfiller == address(0)) {
			revert InvalidFulfiller();
		}
		
		Order memory order = _deriveOrder(FREE_MEMORY_POINTER);

		CalldataPointer cdPtr = _order.calldataPointer();

		order.allocateOrderType(cdPtr);

		order.allocateTradeParameters(cdPtr);

		if (!order.validateMaker(cdPtr, _fulfiller)) {
			revert InvalidMaker();
		}

		if (!order.validateNonce(cdPtr, order.maker)) {
			revert InvalidNonce();
		}

		if (!order.validateOrderPeriod(cdPtr)) {
			revert InvalidOrderPeriod();
		}

		uint64 saleKind = order.saleKind();
		if (!order.validatePaymentType(cdPtr, saleKind, order.paymentType())) {
			revert InvalidPaymentToken();
		}

		if (!order.validateAssetType(cdPtr, order.assetType())) {
			revert InvalidAmount();
		}

		(bytes32 hash, bool valid) = order.validateSaleKind(
			FREE_MEMORY_POINTER,
			cdPtr,
			saleKind
		);

		MemoryPointer memPtr = _freeMemoryPointer();
		if (!valid) {
			revert InvalidSaleKind();
		}

		if (!_validateOrder(hash, order.maker, _signature)) {
			revert OrderValidationFailed();
		}

		if (order.taker != address(0) && order.taker != _fulfiller) {
			revert OrderTakerNotMatched();
		}

		if (!_fulfill(memPtr, saleKind, hash, order, _fulfiller, _fulfillment)) {
			revert FulfillmentFailed();
		}
	}

	function _execute_unsafe (
		Order calldata _order,
		bytes calldata _signature,
		address _fulfiller,
		Fulfillment calldata _fulfillment
	) internal {

		// Prevent the item from being sent to the zero address.
		if (_fulfiller == address(0)) {
			revert InvalidFulfiller();
		}
		
		Order memory order = _deriveOrder(FREE_MEMORY_POINTER);

		CalldataPointer cdPtr = _order.calldataPointer();

		order.allocateOrderType(cdPtr);

		order.allocateTradeParameters(cdPtr);

		if (!order.validateMaker(cdPtr, _fulfiller)) {
			_emitOrderResult(
				bytes1(0x01),
				_order.hash(),
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		if (!order.validateNonce(cdPtr, order.maker)) {
			_emitOrderResult(
				(0x02),
				_order.hash(),
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		if (!order.validateOrderPeriod(cdPtr)) {
			_emitOrderResult(
				bytes1(0x03),
				_order.hash(),
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		uint64 saleKind = order.saleKind();
		if (!order.validatePaymentType(cdPtr, saleKind, order.paymentType())) {
			_emitOrderResult(
				bytes1(0x04),
				_order.hash(),
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		if (!order.validateAssetType(cdPtr, order.assetType())) {
			_emitOrderResult(
				bytes1(0x05),
				_order.hash(),
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		(bytes32 hash, bool valid) = order.validateSaleKind(
			FREE_MEMORY_POINTER,
			cdPtr,
			saleKind
		);

		MemoryPointer memPtr = _freeMemoryPointer();
		if (!valid) {
			_emitOrderResult(
				bytes1(0x06),
				hash,
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		if (!_validateOrder(hash, order.maker, _signature)) {
			_emitOrderResult(
				bytes1(0x07),
				hash,
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		if (order.taker != address(0) && order.taker != _fulfiller) {
			_emitOrderResult(
				bytes1(0x08),
				hash,
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}

		if (!_fulfill(memPtr, saleKind, hash, order, _fulfiller, _fulfillment)) {
			_emitOrderResult(
				bytes1(0x09),
				hash,
				0,
				0,
				order.toTrade(),
				_fulfiller
			);
		}
	}


	/**
		Cancel an order, preventing it from being matched. An order must be 
		canceled by its maker.
		
		@param _order The `Order` to cancel.

		@custom:throws OrderAlreadyCancelled if the order has already been 
			individually canceled, or mass-canceled.
		@custom:throws OrderAlreadyFulfilled if the order has already been 
			fulfilled.
		@custom:throws OrderValidationFailed if the caller is not the maker of 
			the order.
	*/
	function _cancelOrder (Order calldata _order) internal {

		// Calculate the order hash.
		bytes32 hash = _order.hash();

		// Verify order is still live.
		uint256 status = _getOrderStatus(hash);
		if (
			status == ORDER_IS_CANCELLED || 
			_order.nonce < _getUserNonce(msg.sender)
		) {
			revert OrderAlreadyCancelled();
		}
		if (status == ORDER_IS_FULFILLED) {
			revert OrderAlreadyFulfilled();
		}

		// Verify the order is being canceled by its maker.
		if (_order.maker != msg.sender) {
			revert OrderValidationFailed();
		}

		// Cancel the order and log the event.
		_setOrderStatus(hash, ORDER_IS_CANCELLED);
		emit OrderCancelled(
			_order.maker,
			hash
		);
	}

	function _setNonce (uint256 _newNonce) internal {
		
		if ( _newNonce <= _getUserNonce(msg.sender) ) {
			revert InvalidNonce();
		}
		_setUserNonce(_newNonce);

		emit AllOrdersCancelled(msg.sender, _newNonce);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	MemoryPointer,
	CalldataPointer,
	ONE_WORD,
	TWO_WORDS,
	THREE_WORDS,
	HASH_OF_ZERO_BYTES,
	PREFIX,
	ZERO_MEMORY_SLOT
} from "./Helpers.sol";

import {
	_getUserNonce
} from "./Storage.sol";

import {
	FIXED_PRICE,
	DECREASING_PRICE,
	OFFER,
	COLLECTION_OFFER,
	ORDER_SIZE,
	ORDER_TYPEHASH,
	ERC20_PAYMENT,
	ETH_PAYMENT,
	ASSET_ERC721,
	ASSET_ERC1155,
	TYPEHASH_AND_ORDER_SIZE,
	COLLECTION_OFFER_SIZE,
	DECREASING_PRICE_ORDER_SIZE,
	ORDER_NONCE,
	ORDER_LISTING_TIME,
	ORDER_EXPIRATION_TIME,
	ORDER_MAKER,
	ORDER_ROYALTY,
	ORDER_BASE_PRICE,
	ORDER_TYPE,
	ORDER_COLLECTION,
	ORDER_ID,
	ORDER_AMOUNT,
	ORDER_PAYMENT_TOKEN,
	ORDER_TAKER,
	ORDER_RESOLVE_DATA,
	ORDER_RESOLVE_DATA_LENGTH,
	ORDER_PRICE_DECREASE_FLOOR,
	ORDER_PRICE_DECREASE_END_TIME,
	ORDER_DECREASE_FLOOR_MEMORY,
	ORDER_PRICE_DECREASE_END_TIME_MEMORY
} from "./OrderConstants.sol";
import "hardhat/console.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Entities Library
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for managing supported order entities.
*/

struct Fulfillment {
    bool strict;
    uint256 amount;
    uint256 id;
    bytes32[] proofs;
}

struct Execution {
	uint256 fillerIndex;
	uint256 nonce; 
	uint256 listingTime;
	uint256 expirationTime;
	address maker; 
	address taker;
	uint256 royalty; 
	address paymentToken;
	uint256 basePrice; 
	uint256 orderType; 
	address collection; 
	uint256 id;
	uint256 amount;
	bytes resolveData;
}

struct Order {
	uint256 nonce;
	uint256 listingTime;
	uint256 expirationTime;
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
	bytes resolveData;
}

struct Trade {
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
}

struct DutchAuction {
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
	uint256 floor;
	uint256 endTime;
}

struct CollectionOffer {
	address maker;
	address taker;
	uint256 royalty;
	address paymentToken;
	uint256 basePrice;
	uint256 orderType;
	address collection;
	uint256 id;
	uint256 amount;
	bytes32 rootHash;
}


function _deriveOrder(
	MemoryPointer _memPtr
) pure returns(Order memory order) {
	assembly {
		mstore(
			_memPtr,
			ORDER_TYPEHASH
		)
		order := add(_memPtr, ONE_WORD)
	}
}

using OrderLib for Order global;
using OrderLib for Execution global;
using OrderLib for Trade global;
using OrderLib for CollectionOffer global;
using OrderLib for DutchAuction global;

library OrderLib {

	function calldataPointer(
		Order calldata _order
	) internal pure returns (CalldataPointer cdPtr) {
		assembly {
			cdPtr := _order
		}
	}

	function memoryPointer(
		Order memory _order
	) internal pure returns (MemoryPointer memPtr) {
		assembly {
			memPtr := _order
		}
	}

	function toOrder (
		Execution calldata _execution
	) internal pure returns (Order calldata order) {
		assembly {
			order := add(_execution, ONE_WORD)
		}
	}

	function toTrade(
		Order memory _order
	) internal pure returns (Trade memory trade) {
		assembly {
			trade := add(_order, THREE_WORDS)
		}
	}

	function toTrade(
		DutchAuction memory _auction
	) internal pure returns (Trade memory trade) {
		assembly {
			trade := _auction
		}
	}

	function toTrade(
		CollectionOffer memory _offer
	) internal pure returns (Trade memory trade) {
		assembly {
			trade := _offer
		}
	}

	function toDutchAuction(
		Order memory _order
	) internal pure returns (DutchAuction memory auction) {
		assembly {
			auction := add(_order, THREE_WORDS)
		}
	}

	function toCollectionOffer(
		Order memory _order
	) internal pure returns (CollectionOffer memory offer) {
		assembly {
			offer := add(_order, THREE_WORDS)
		}
	}

	function validateMaker(
		Order memory _order,
		CalldataPointer _cdPtr,
		address _fulfiller
	)  internal view returns (bool) {
		address maker;
		assembly {
			maker := calldataload(
				add(_cdPtr, ORDER_MAKER)
			)
		}
		/*
			Verify that the order maker is not the `_fulfiller`, nor the msg.sender, nor 
			the zero address.
		*/
		if (
				maker == _fulfiller ||
				maker == msg.sender ||
				maker == address(0)
			) {
				return false;
		}
		assembly {
			mstore(
				add(_order, ORDER_MAKER),
				maker
			)
		}
		return true;
	}

	function validateNonce(
		Order memory _order,
		CalldataPointer _cdPtr,
		address _maker
	) internal view  returns (bool) {
		uint256 nonce;
		assembly {
			nonce := calldataload(
				add(_cdPtr, ORDER_NONCE)
			)
		}
		// Verify that the order was not createed with an expired nonce.
		if (nonce < _getUserNonce(_maker)) {
			return false;
		}
		assembly {
			mstore(
				add(_order, ORDER_NONCE),
				nonce
			)
		}
		return true;
	}

	function allocateOrderType(
		Order memory _order,
		CalldataPointer _cdPtr
	) internal pure {
		assembly {
			mstore(
				add(_order, ORDER_TYPE),
				calldataload(
					add(_cdPtr, ORDER_TYPE)
				)
			)
		}
	}

	/**
		Return whether or not an order can be settled, verifying that the current
		block time is between order's initial listing and expiration time.

		@param _listingTime The starting time of the order being listed.
		@param _expirationTime The ending time where the order expires.
	*/
	function _canSettleOrder (
		uint256 _listingTime,
		uint256 _expirationTime
	) private view returns (bool) {
		return
			(_listingTime < block.timestamp) &&
			(_expirationTime == 0 || block.timestamp < _expirationTime);
	}

	function validateOrderPeriod(
		Order memory _order,
		CalldataPointer _cdPtr
	) internal view  returns (bool) {
		uint256 listingTime;
		uint256 expirationTime;
		assembly {
			listingTime := calldataload(
				add(_cdPtr, ORDER_LISTING_TIME)
			)
			expirationTime := calldataload(
				add(_cdPtr, ORDER_EXPIRATION_TIME)
			)
		}
		if (!_canSettleOrder(listingTime, expirationTime)) {
			return false;
		}
		assembly {
			mstore(
				add(_order, ORDER_LISTING_TIME),
				listingTime
			)
			mstore(
				add(_order, ORDER_EXPIRATION_TIME),
				expirationTime
			)
		}
		return true;
	}

	function allocateTradeParameters (
		Order memory _order,
		CalldataPointer _cdPtr
	) internal pure {
		assembly {
			mstore(
				add(_order, ORDER_TAKER),
				calldataload(
					add(_cdPtr, ORDER_TAKER)
				)
			)
			mstore(
				add(_order, ORDER_ROYALTY),
				calldataload(
					add(_cdPtr, ORDER_ROYALTY)
				)
			)
			mstore(
				add(_order, ORDER_BASE_PRICE),
				calldataload(
					add(_cdPtr, ORDER_BASE_PRICE)
				)
			)
			mstore(
				add(_order, ORDER_COLLECTION),
				calldataload(
					add(_cdPtr, ORDER_COLLECTION)
				)
			)
			mstore(
				add(_order, ORDER_ID),
				calldataload(
					add(_cdPtr, ORDER_ID)
				)
			)
		}
	}

	function paymentType (
		Order memory _order
	) internal pure returns (uint64){
		return uint64(_order.orderType >> 192);
	}

	function fulfillmentType (
		Order memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 128);
	}

	function assetType (
		Order memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 64);
	}

	function saleKind (
		Order memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType);
	}

	function paymentType (
		Trade memory _order
	) internal pure returns (uint64){
		return uint64(_order.orderType >> 192);
	}

	function fulfillmentType (
		Trade memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 128);
	}

	function assetType (
		Trade memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 64);
	}

	function saleKind (
		Trade memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType);
	}

	function paymentType (
		DutchAuction memory _order
	) internal pure returns (uint64){
		return uint64(_order.orderType >> 192);
	}

	function fulfillmentType (
		DutchAuction memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 128);
	}

	function assetType (
		DutchAuction memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 64);
	}

	function saleKind (
		DutchAuction memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType);
	}

	function paymentType (
		CollectionOffer memory _order
	) internal pure returns (uint64){
		return uint64(_order.orderType >> 192);
	}

	function fulfillmentType (
		CollectionOffer memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 128);
	}

	function assetType (
		CollectionOffer memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType >> 64);
	}

	function saleKind (
		CollectionOffer memory _order
	) internal pure returns (uint64) {
		return uint64(_order.orderType);
	}

	function validatePaymentType(
		Order memory _order,
		CalldataPointer _cdPtr,
		uint64 _saleKind,
		uint64 _paymentType
	) internal pure returns (bool) {
		// Load payment token address in memory
		// and verify that it is not a zero address.
		if (_paymentType == ERC20_PAYMENT) {
			address paymentToken;
			assembly {
				paymentToken := calldataload(
					add(_cdPtr, ORDER_PAYMENT_TOKEN)
				)
			}
			if (paymentToken == address(0)) {
				return false;
			}
			assembly{
				mstore(
					add(_order, ORDER_PAYMENT_TOKEN),
					paymentToken
				)
			}
			return true;
		}
	
		// Verify that it is a zero address.
		if (_paymentType == ETH_PAYMENT) {
			address paymentToken;
			assembly {
				paymentToken := calldataload(
					add(_cdPtr, ORDER_PAYMENT_TOKEN)
				)
			}
			if (
				paymentToken != address (0) ||
				_saleKind > 1
			) {
				return false;
			}
			assembly{
				mstore(
					add(_order, ORDER_PAYMENT_TOKEN),
					paymentToken
				)
			}
			return true;
		}
		// Return false if loaded tpye didn't match any actual type.
		return false;
	}

	function validateAssetType ( 
		Order memory _order,
		CalldataPointer _cdPtr,
		uint64 _assetType
	) internal pure returns (bool){
		if (_assetType == ASSET_ERC1155) {
			uint256 amount;
			assembly {
				amount := calldataload(
					add(_cdPtr, ORDER_AMOUNT)
				)
			}
			if (amount == 0) {
				return false;
			}
			assembly{
				mstore(
					add(_order, ORDER_AMOUNT),
					amount
				)
			}
			return true;
		}
		if (_assetType == ASSET_ERC721) {
			uint256 amount;
			assembly {
				amount := calldataload(
					add(_cdPtr, ORDER_AMOUNT)
				)
			}
			if (amount != 0) {
				return false;
			}
			assembly{
				mstore(
					add(_order, ORDER_AMOUNT),
					amount
				)
			}
			return true;
		}
		return false;
	}

	function validateSaleKind (
		Order memory _order,
		MemoryPointer _memPtr,
		CalldataPointer _cdPtr,
		uint64 _saleKind
	) internal pure returns (bytes32 hash_, bool) {
		uint256 length;
		// Fixed price order strategy.
		if (_saleKind == FIXED_PRICE || _saleKind == OFFER) {
			assembly {
				length := calldataload(
					add(_cdPtr, ORDER_RESOLVE_DATA_LENGTH)
				)
			}
			if (length != 0) {
				return (hash_, false);
			}
			assembly {
				mstore(
					add(_order, ORDER_RESOLVE_DATA),
					HASH_OF_ZERO_BYTES
				)
				hash_ := keccak256(
					_memPtr,
					TYPEHASH_AND_ORDER_SIZE
				)
				mstore(0x40, add(_order, ORDER_SIZE))
			}
			return (hash_, true);
		}
		// Decreasing price listing strategy.
		if (_saleKind == DECREASING_PRICE) {
			assembly {
				length := calldataload(
					add(_cdPtr, ORDER_RESOLVE_DATA_LENGTH)
				)
			}
			if (length != TWO_WORDS) {
				return (hash_, false);
			}
			uint256 floor;
			uint256 endTime;
			assembly {
				floor := calldataload(add(_cdPtr, ORDER_PRICE_DECREASE_FLOOR))
				endTime := calldataload(add(_cdPtr, ORDER_PRICE_DECREASE_END_TIME))
				mstore(0, floor)
				mstore(ONE_WORD, endTime)
				mstore(
					add(_order, ORDER_RESOLVE_DATA),
					keccak256(0, TWO_WORDS)
				)
				hash_ := keccak256(
					_memPtr,
					TYPEHASH_AND_ORDER_SIZE
				)
				mstore(
					add(_order, ORDER_DECREASE_FLOOR_MEMORY),
					floor
				)
				mstore(
					add(_order, ORDER_PRICE_DECREASE_END_TIME_MEMORY),
					endTime
				)
				mstore(0x40, add(_order, DECREASING_PRICE_ORDER_SIZE))
			}
			return (hash_, true);
		}
		
		// Collection offer strategy.
		if (_saleKind == COLLECTION_OFFER) {
			if (_order.id != 0) {
					return (hash_, false);
				}
			assembly {
				length := calldataload(
					add(_cdPtr, ORDER_RESOLVE_DATA_LENGTH)
				)
			}
			if (length > ONE_WORD) {
				return (hash_, false);
			}
			if ( length != 0) {
				bytes32 rootHash;
				assembly{
					rootHash := calldataload(add(_cdPtr, ORDER_PRICE_DECREASE_FLOOR))
					mstore(
						0,
						rootHash
					)
					mstore(
						add(_order, ORDER_RESOLVE_DATA),
						keccak256(0, ONE_WORD)
					)
					hash_ := keccak256(
						_memPtr,
						TYPEHASH_AND_ORDER_SIZE
					)
					mstore(
						add(_order, ORDER_RESOLVE_DATA),
						rootHash
					)
					mstore(0x40, add(_order, COLLECTION_OFFER_SIZE))
				}
			} else {
				assembly{
					mstore(
						add(_order, ORDER_RESOLVE_DATA),
						HASH_OF_ZERO_BYTES
					)
					hash_ := keccak256(
						_memPtr,
						TYPEHASH_AND_ORDER_SIZE
					)
					mstore(0x40, add(_order,COLLECTION_OFFER_SIZE))
				}
			}
			return (hash_, true);
		}
		// Did not match any kind of sale.
		return (hash_, false);
	}

	function hash(
		Order calldata _order
	) internal pure returns (bytes32) {
		return keccak256(
			abi.encode(
				ORDER_TYPEHASH,
				_order.nonce,
				_order.listingTime,
				_order.expirationTime,
				_order.maker,
				_order.taker,
				_order.royalty,
				_order.paymentToken,
				_order.basePrice,
				_order.orderType,
				_order.collection,
				_order.id,
				_order.amount,
				keccak256(_order.resolveData)
			)
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

uint64 constant FIXED_PRICE = 0;
uint64 constant DECREASING_PRICE = 1;
uint64 constant OFFER = 2;
uint64 constant COLLECTION_OFFER = 3;

uint64 constant ASSET_ERC721 = 0;
uint64 constant ASSET_ERC1155 = 1;

uint64 constant STRICT = 0;
uint64 constant PARTIAL = 1;

uint64 constant ETH_PAYMENT = 0;
uint64 constant ERC20_PAYMENT = 1;

uint256 constant TYPEHASH_AND_ORDER_SIZE = 0x1c0;
uint256 constant ORDER_SIZE = 0x180;
uint256 constant COLLECTION_OFFER_SIZE = 0x1a0;
uint256 constant DECREASING_PRICE_ORDER_SIZE = 0x1c0;

uint256 constant ORDER_NONCE = 0x0;
uint256 constant ORDER_LISTING_TIME = 0x20;
uint256 constant ORDER_EXPIRATION_TIME = 0x40;
uint256 constant ORDER_MAKER = 0x60;
uint256 constant ORDER_TAKER = 0x80;
uint256 constant ORDER_ROYALTY = 0xa0;
uint256 constant ORDER_PAYMENT_TOKEN = 0xc0;
uint256 constant ORDER_BASE_PRICE = 0xe0;
uint256 constant ORDER_TYPE = 0x100;
uint256 constant ORDER_COLLECTION = 0x120;
uint256 constant ORDER_ID = 0x140;
uint256 constant ORDER_AMOUNT = 0x160;
uint256 constant ORDER_RESOLVE_DATA = 0x180;
uint256 constant ORDER_RESOLVE_DATA_LENGTH = 0x1a0;
uint256 constant ORDER_COLECTION_OFFER_ROOTHASH = 0x1c0;
uint256 constant ORDER_COLECTION_OFFER_ROOTHASH_MEMORY = 0x180;
uint256 constant ORDER_PRICE_DECREASE_FLOOR = 0x1c0;
uint256 constant ORDER_DECREASE_FLOOR_MEMORY = 0x180;
uint256 constant ORDER_PRICE_DECREASE_END_TIME = 0x1e0;
uint256 constant ORDER_PRICE_DECREASE_END_TIME_MEMORY = 0x1a0;
uint256 constant TRADE_MAKER = 0;
uint256 constant TRADE_COLLECTION = 0xc0;
uint256 constant TRADE_ID = 0xe0;
uint256 constant TRADE_AMOUNT = 0x100;
uint256 constant TRADE_PAYMENT_TOKEN = 0x60;


uint256 constant ORDER_IS_OPEN = 0;
uint256 constant ORDER_IS_PARTIALLY_FILLED = 1;
uint256 constant ORDER_IS_FULFILLED = 2;
uint256 constant ORDER_IS_CANCELLED = 3;

bytes32 constant ORDER_TYPEHASH =
		0x68d866f4b3d9454104b120166fed55c32dec7cdc4364d96d3c35fd74f499a546;

uint256 constant MAX_BULK_ORDER_HEIGHT = 10;

bytes32 constant BULK_ORDER_HEIGHT_ONE_TYPEHASH =
    0xcd0511c3edba288c7b7022a4e9d1309409d7c3dc815549ad502ae3c83153ec8d;

bytes32 constant BULK_ORDER_HEIGHT_TWO_TYPEHASH =
    0x9beb8a38951a872487aa75e49e0e6f218b38eae90fe3657ec10cd87fd1aca5f6;

bytes32 constant BULK_ORDER_HEIGHT_THREE_TYPEHASH =
    0x1907e099cd0b102d6d866a233966dace07bb7555aaaebc8389f11be90fc095c4;

bytes32 constant BULK_ORDER_HEIGHT_FOUR_TYPEHASH =
    0x89ee6c2dd775f15a95d29597ba9ce62100b4dd0bd6b6b2eefcfa4d2bd80af43b;

bytes32 constant BULK_ORDER_HEIGHT_FIVE_TYPEHASH =
    0x21f4c248b5e14bf8fd8d4ce2a90d95af66ada155282e47b9a2fe531c1ac8bf46;

bytes32 constant BULK_ORDER_HEIGHT_SIX_TYPEHASH =
    0x7974a224dd38aa4de830ad422e8b8b87952eb0c7ecdc515455b2d6b93856431f;

bytes32 constant BULK_ORDER_HEIGHT_SEVEN_TYPEHASH =
    0x8786a4d3c6831f1b8000b3fdbe170ebdd58e9ebf3533a5e18b41d7d4a8ef6a2d;

bytes32 constant BULK_ORDER_HEIGHT_EIGHT_TYPEHASH =
    0x525015a897b863903af7bd14d2d1c20bb2b74c85c251887728c8d87a277919d5;

bytes32 constant BULK_ORDER_HEIGHT_NINE_TYPEHASH =
    0x6f0940942471b62e57a516ba875d9e2f380ac3f44782f7a1aa1efd749b236128;

bytes32 constant BULK_ORDER_HEIGHT_TEN_TYPEHASH =
    0x49df94d1aa107700bd757da74f9ff6bd21ae6cedb7b5679fc606558a953e4700;

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	MemoryPointer,
	STRUCT_LENGTH_ONE,
	ERC20_ASSET_TYPE,
	ERC721_ASSET_TYPE,
	ERC1155_ASSET_TYPE,
	TRANSFER_ASSET_SELECTOR,
	TRANSFER_ASSETS_SELECTOR,
	PRECISION,
	_transferEth,
	_verifyProof
} from "./Helpers.sol";

import {
	Fulfillment,
	Order,
	Trade,
	CollectionOffer,
	DutchAuction
} from "./Order.sol";

import {
	FIXED_PRICE,
	DECREASING_PRICE,
	OFFER,
	COLLECTION_OFFER,
	STRICT,
	PARTIAL,
	ASSET_ERC721,
	ASSET_ERC1155,
	ETH_PAYMENT,
	ERC20_PAYMENT,
	TRADE_MAKER,
	TRADE_COLLECTION,
	TRADE_ID,
	TRADE_AMOUNT,
	TRADE_PAYMENT_TOKEN,
	ORDER_IS_PARTIALLY_FILLED,
	ORDER_IS_FULFILLED
} from "./OrderConstants.sol";

import {
	_getProtocolFee,
	_getRoyalty,
	_getOrderFillAmount,
	_setOrderFillAmount,
	_setOrderStatus
} from "./Storage.sol";

import {
	Asset,
	AssetType,
	IAssetHandler
} from "../../manager/interfaces/IGigaMartManager.sol";

error NotEnoughValueSent();
error PaymentFailed();
import "hardhat/console.sol";
/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM


*/
contract OrderFulfiller {

	/**
		Emitted at each attempt of exchanging an item.

		@param order The hash of the order.
		@param maker The order maker's address.
		@param taker The order taker's address.
		@param data An array of bytes that contains the success status, order sale kind, price, 
			payment token, target, and transfer data.
	*/
	event OrderResult (
		bytes32 order,
		address indexed maker,
		address indexed taker,
		bytes data
	);

    IAssetHandler internal immutable _ASSET_HANDLER;

    constructor (
        IAssetHandler _assetHandler
    ){
        _ASSET_HANDLER = _assetHandler;
    }

	function _emitOrderResult(
		bytes1 _code,
		bytes32 _hash,
		uint256 _price,
		uint256 _amount,
		Trade memory _trade,
		address _taker
	) internal {
		// Condense order settlement status for event emission.
		bytes memory settledParameters = abi.encodePacked(
			_code,
			_trade.saleKind(),
			_price,
			_trade.paymentToken,
			_trade.collection,
			bytes4(0),
			_trade.maker,
			_taker,
			_trade.id,
			_amount
		);

		// Emit an event with the results of this order.
		emit OrderResult(
			_hash,
			_trade.maker,
			_taker,
			settledParameters
		);
	}

	function _emitOrderResultSuccess(
		bytes32 _hash,
		uint256 _price,
		uint256 _amount,
		Trade memory _trade,
		address _taker
	) private {
		// Condense order settlement status for event emission.
		bytes memory settledParameters = abi.encodePacked(
			bytes1(0xFF),
			_trade.saleKind(),
			_price,
			_trade.paymentToken,
			_trade.collection,
			bytes4(0),
			_trade.maker,
			_taker,
			_trade.id,
			_amount
		);

		// Emit an event with the results of this order.
		emit OrderResult(
			_hash,
			_trade.maker,
			_taker,
			settledParameters
		);
	}

	function _pay(
		Trade memory _trade,
		uint256 _price,
		address _recipient,
		address _buyer
	) private{
		if (_price > 0) {
			uint64 paymentType = _trade.paymentType();
			if (paymentType == ETH_PAYMENT) {
				if (msg.value < _price) {
					revert NotEnoughValueSent();
				}
				uint256 receiveAmount = _price;
				uint256 config = _getProtocolFee();
				if (uint96(config) != 0) {
					uint256 fee = (_price * uint96(config)) / PRECISION;
					_transferEth(address(uint160(config >> 96)), fee);
					receiveAmount -= fee;
				}
				config = _getRoyalty(_trade.collection, _trade.royalty);
				if (uint96(config) != 0) {
					uint256 fee = (_price * uint96(config)) / PRECISION;
					_transferEth(address(uint160(config >> 96)), fee);
					receiveAmount -= fee;
				}
				// Transfer the remainder of the payment to the item seller.
				_transferEth(_recipient, receiveAmount);
			}
			if (paymentType == ERC20_PAYMENT) {
				_ASSET_HANDLER.transferAsset(
					Asset({
						assetType: AssetType.ERC20,
						collection: _trade.paymentToken,
						from: _buyer,
						to: _recipient,
						id: 0,
						amount: _price
					})
				);
			}
		}
	}

	function _transferItem (
		MemoryPointer _memPtr,
		Trade memory _trade,
		bytes32 _hash,
		uint256 _id,
		uint64 _fulfillmentType,
		address _seller,
		address _recipient,
		Fulfillment calldata _fulfillment
	) private returns (bool result, uint256 price, uint256 amount) {
		IAssetHandler handler = _ASSET_HANDLER;
		Asset memory asset;
		assembly {
			mstore(
				_memPtr,
				TRANSFER_ASSET_SELECTOR
			)
			asset := add(_memPtr, 0x4)
			mstore(
				add(asset, 0x20),
				mload(add(_trade, TRADE_COLLECTION))
			)
			mstore(
				add(asset, 0x40),
				_seller
			)
			mstore(
				add(asset, 0x60),
				_recipient
			)
			mstore(
				add(asset, 0x80),
				_id
			)
		}
		if (_trade.assetType() == ASSET_ERC721) {
			price = _trade.basePrice;
			amount = 1;
			assembly {
				mstore(
					asset,
					ERC721_ASSET_TYPE
				)
				mstore(
					add(asset, 0xa0),
					0
				) 
			}
			_setOrderStatus(_hash, ORDER_IS_FULFILLED);
		}
		if (_trade.assetType() == ASSET_ERC1155) {
			if (_fulfillment.amount > _trade.amount) {
				return (false, 0, 0);
			}
			amount = _fulfillment.amount;
			if (_fulfillmentType == PARTIAL) {
				uint256 filledAmount =_getOrderFillAmount(_hash);
				uint256 leftover =_trade.amount - filledAmount;

				if (_fulfillment.strict) {
					if ( leftover < amount) {
						return (false, 0, 0);
					}
				} else {
					if ( leftover < amount) {
						amount = leftover;
					}
				}
				_setOrderFillAmount(
					_hash,
					filledAmount + amount < _trade.amount ?
					ORDER_IS_PARTIALLY_FILLED :
					ORDER_IS_FULFILLED
				);
			}
			assembly {
				mstore(
					asset,
					ERC1155_ASSET_TYPE
				)
				mstore(
					add(asset, 0xa0),
					amount
				)
			}
			price = amount * _trade.basePrice / _trade.amount;
		}
		assembly {
			result := call(
				gas(),
				handler,
				0,
				_memPtr,
				0xe4,
				0, 0
			)
		}
	}

	function _fulfillListing (
		MemoryPointer _memPtr,
		Trade memory _trade,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _itemRecipient,
		Fulfillment calldata _fulfillment
	) private returns (bool) {
		(bool result, uint256 basePrice, uint256 amount) = _transferItem(
			_memPtr,
			_trade,
			_hash,
			_trade.id,
			_fulfillmentType,
			_trade.maker,
			_itemRecipient,
			_fulfillment
		);

		if (!result) {
			return false;
		}

		_pay(
			_trade,
			basePrice,
			_trade.maker,
			msg.sender
		);

		_emitOrderResultSuccess(
			_hash,
			basePrice,
			amount,
			_trade,
			_itemRecipient
		);

		return true;
	}

	function _fulfillOffer (
		MemoryPointer _memPtr,
		Trade memory _trade,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _paymentRecipient,
		Fulfillment calldata _fulfillment
	) private returns (bool) {
		(bool result, uint256 basePrice, uint256 amount) = _transferItem(
			_memPtr,
			_trade,
			_hash,
			_trade.id,
			_fulfillmentType,
			msg.sender,
			_trade.maker,
			_fulfillment
		);

		if (!result) {
			return false;
		}

		_pay(
			_trade,
			basePrice,
			_paymentRecipient,
			_trade.maker
		);
		
		_emitOrderResultSuccess(
			_hash,
			basePrice,
			amount,
			_trade,
			_paymentRecipient
		);

		return true;
	}

	function _verifyTokenId (
		CollectionOffer memory _offer,
		Fulfillment calldata _fulfillment
	) private view returns (bool) {
		if (_offer.rootHash != 0){
			console.logBytes32(_offer.rootHash);
			return _verifyProof(
				_fulfillment.id,
				_offer.rootHash,
				_fulfillment.proofs
			);
		}
		return true;
	}

	function _fulfillCollectionOffer (
		MemoryPointer _memPtr,
		CollectionOffer memory _offer,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _paymentRecipient,
		Fulfillment calldata _fulfillment
	) private returns (bool) {
		
		if (!_verifyTokenId(
				_offer,
				_fulfillment
			)
		) {
			return false;
		}

		(bool result, uint256 basePrice, uint256 amount) = _transferItem(
			_memPtr,
			_offer.toTrade(),
			_hash,
			_fulfillment.id,
			_fulfillmentType,
			msg.sender,
			_offer.maker,
			_fulfillment
		);

		if (!result) {
			return false;
		}

		_pay(
			_offer.toTrade(),
			basePrice,
			_paymentRecipient,
			_offer.maker
		);

		_emitOrderResultSuccess(
			_hash,
			basePrice,
			amount,
			_offer.toTrade(),
			_paymentRecipient
		);

		return true;
	}

	function _priceDecay (
		uint256 _price,
		uint256 _amount,
		uint256 _listingTime,
		DutchAuction memory _auction
	) private view returns (uint256) {
		/*
				If the timestamp at which price decrease concludes has been exceeded,
				the item listing price maintains its configured floor price.
			*/
			console.log(_amount, _price, _auction.floor, _auction.endTime);
			if (block.timestamp >= _auction.endTime) {
				return _auction.floor;
			}

			/*
				Calculate the portion of the decreasing total price that has not yet
				decayed.
			*/
			uint undecayed =

				// The total decayable portion of the price.
				(_price / _amount - _auction.floor) *

				// The duration in seconds of the time remaining until total decay.
				(_auction.endTime - block.timestamp) /

				/*
					The duration in seconds between the order listing time and the time
					of total decay.
				*/
				(_auction.endTime - _listingTime);

			// Return the current price as the floor price plus the undecayed portion.
			console.log(_auction.floor + undecayed);
			return (_auction.floor + undecayed) * _amount;
	}

	function _fulfillDutchAuction (
		MemoryPointer _memPtr,
		DutchAuction memory _auction,
		bytes32 _hash,
		uint64 _fulfillmentType,
		address _itemRecipient,
		uint256 _listingTime,
		Fulfillment calldata _fulfillment
	) private returns (bool) {

		(bool result, uint256 basePrice, uint256 amount) = _transferItem(
			_memPtr,
			_auction.toTrade(),
			_hash,
			_auction.id,
			_fulfillmentType,
			_auction.maker,
			_itemRecipient,
			_fulfillment
		);
		if (!result) {
			return false;
		}
		uint256 price = _priceDecay(
			basePrice,
			amount,
			_listingTime,
			_auction
		);
		_pay(
			_auction.toTrade(),
			price,
			_auction.maker,
			msg.sender
		);

		_emitOrderResultSuccess(
			_hash,
			price,
			amount,
			_auction.toTrade(),
			_itemRecipient
		);

		return true;
	}

	function _fulfill(
		MemoryPointer _memPtr,
		uint64 _saleKind,
		bytes32 _hash,
		Order memory _order,
		address _fulfiller,
		Fulfillment calldata _fulfillment
	) internal returns (bool){
		if ( _saleKind == FIXED_PRICE) {
			return _fulfillListing(
				_memPtr,
				_order.toTrade(),
				_hash,
				_order.fulfillmentType(),
				_fulfiller,
				_fulfillment
			);
		}
		if ( _saleKind == OFFER) {
			return _fulfillOffer(
				_memPtr,
				_order.toTrade(),
				_hash,
				_order.fulfillmentType(),
				_fulfiller,
				_fulfillment
			);
		}
		if ( _saleKind == COLLECTION_OFFER) {
			return _fulfillCollectionOffer(
				_memPtr,
				_order.toCollectionOffer(),
				_hash,
				_order.fulfillmentType(),
				_fulfiller,
				_fulfillment
			);
		}
		if ( _saleKind == DECREASING_PRICE) {
			return _fulfillDutchAuction(
				_memPtr,
				_order.toDutchAuction(),
				_hash,
				_order.fulfillmentType(),
				_fulfiller,
				_order.listingTime,
				_fulfillment
			);
		}
		return false;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	RoyaltyManager
} from "./RoyaltyManager.sol";

import "hardhat/console.sol";
/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM


*/
contract OrderVerifier {
    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	BaseFeeManager
} from "./BaseFeeManager.sol";

import {
	DomainAndTypehashes
} from "./DomainAndTypehashes.sol";

import {
	FREE_MEMORY_POINTER,
	_freeMemoryPointer,
	_recover
} from "./Helpers.sol";

import {
	_getValidatorAddress,
	_setValidatorAddress,
	_getRoyalty,
	_setRoyalty,
	_getRoyaltyIndex
} from "./Storage.sol";

/// Thrown if attempting to set the validator address to zero.
error ValidatorAddressCannotBeZero ();

/// Thrown if the signature provided by the validator is expired.
error SignatureExpired ();

/// Thrown if the signature provided by the validator is invalid.
error BadSignature ();

/// Thrown if attempting to recover a signature of invalid length.
error InvalidSignatureLength ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Royalty Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing an EIP-712 signature-based approach for on-chain 
	direct royalty payments with royalty management as gated by an off-chain 
	validator.

	This approach to royalty management is a point of centralization on GigaMart. 
	The validator key gives its controller the ability to arbitrarily change 
	collection royalty fees.

	This approach is justified based on the fact that it allows GigaMart to offer 
	a gas-optimized middle ground where royalty fees are paid out directly to 
	collection owners while still allowing an arbitrary number of collection 
	administrators to manage collection royalty fees based on off-chain role 
	management semantics.
*/
contract RoyaltyManager is DomainAndTypehashes, BaseFeeManager {

	/// The public identifier for the right to change the validator address.
	bytes32 public constant VALIDATOR_SETTER = keccak256("VALIDATOR_SETTER");

	/// The EIP-712 typehash of a royalty update.
	bytes32 public constant ROYALTY_TYPEHASH =
		keccak256(
			"Royalty(address setter,address collection,uint256 deadline,uint256 newRoyalties)"
		);

	/**
		Emitted after altering the royalty fee of a collection.

		@param setter The address which altered the royalty fee.
		@param collection The collection which had its royalty fee altered.
		@param oldRoyalties The old royalty fee of the collection.
		@param newRoyalties The new royalty fee of the collection.
	*/
	event RoyaltyChanged (
		address indexed setter,
		address indexed collection,
		uint256 oldRoyalties,
		uint256 newRoyalties
	);

	/**
		Construct a new instance of the GigaMart royalty fee manager.

		@param _validator The address to use as the royalty change validation 
			signer.
		@param _protocolFeeRecipient The address which receives protocol fees.
		@param _protocolFeePercent The percent in basis points of the protocol fee.
	*/
	constructor (
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) BaseFeeManager(_protocolFeeRecipient, _protocolFeePercent) {
		_setValidatorAddress(_validator);
	}

	/**
		Returns the current royalty fees of a collection.

		@param _collection The collection to return the royalty fees for.

		@return _ A tuple pairing the address of a collection fee recipient with 
			the actual royalty fee.
	*/
	function currentRoyalties (
		address _collection
	) external view returns (address, uint256) {
		uint256 fee = _getRoyalty(
			_collection,
			_getRoyaltyIndex(
				_collection
			)
		);

		// The fee is a packed address-fee pair into a single 256 bit integer.
		return (address(uint160(fee >> 96)), uint256(uint96(fee)));
	}

	/**
		Change the `validator` address.

		@param _validator The new `validator` address to set.

		@custom:throws ValidatorAddressCannotBeZero if attempting to set the 
			`validator` address to the zero address.
	*/
	function changeValidator (
		address _validator
	) external hasValidPermit(UNIVERSAL, VALIDATOR_SETTER) {
		if (_validator == address(0)) {
			revert ValidatorAddressCannotBeZero();
		}
		_setValidatorAddress(_validator);
	}

	/**
		Generate a hash from the royalty changing parameters.
		
		@param _setter The caller setting the royalty changes.
		@param _collection The address of the collection for which royalties will 
			be altered.
		@param _deadline The time when the `_setter` loses the right to alter 
			royalties.
		@param _newRoyalties The new royalty information to set.

		@return _ The hash of the royalty parameters for checking signature 
			validation.
	*/
	function _hash (
		address _setter,
		address _collection,
		uint256 _deadline,
		uint256 _newRoyalties
	) internal view returns (bytes32) {
		return keccak256(
			abi.encodePacked(
				"\x19\x01",
				_deriveDomainSeparator(),
				keccak256(
					abi.encode(
						ROYALTY_TYPEHASH,
						_setter,
						_collection,
						_deadline,
						_newRoyalties
					)
				)
			)
		);
	}

	function indices (address _collection) public view returns(uint256) {
		return _getRoyaltyIndex(_collection);
	}
 
	/**
		Update the royalty mapping for a collection with a new royalty.

		@param _collection The address of the collection for which `_newRoyalties` 
			are set.
		@param _deadline The time until which the `_signature` is valid.
		@param _newRoyalties The updated royalties to set.
		@param _signature A signature signed by the `validator`.

		@custom:throws BadSignature if the signature submitted for setting 
			royalties is invalid.
		@custom:throws SignatureExpired if the signature is expired.
	*/
	function setRoyalties (
		address _collection,
		uint256 _deadline,
		uint256 _newRoyalties,
		bytes calldata _signature
	) external {

		// Verify that the signature was signed by the royalty validator.
		if (
			_recover(
				_hash(msg.sender, _collection, _deadline, _newRoyalties),
				_signature
			) != _getValidatorAddress()
		) {
			revert BadSignature();
		}

		// Verify that the signature has not expired.
		if (_deadline < block.timestamp) {
			revert SignatureExpired();
		}
		
		/*
			Increment the current royalty index for the collection and update its 
			royalty information.
		*/
		uint256 oldRoyalties = _getRoyalty(
			_collection,
			_getRoyaltyIndex(
				_collection
			)
		);
		_setRoyalty(
			_collection,
			_newRoyalties
		);

		// Emit an event notifying about the royalty change.
		emit RoyaltyChanged(msg.sender, _collection, oldRoyalties, _newRoyalties);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	MemoryPointer,
	CalldataPointer,
	ONE_WORD,
	TWO_WORDS,
	ZERO_MEMORY_SLOT
} from "./Helpers.sol";
/*
	Storage slots, getters and setters
 */
	// slot 0 is taken by ReentrancyGuard _status 
	// slot 1 is taken by Ownable _owner
	// slot 2 is taken by PermitControl permissions
	// slot 3 is taken by PermitControl managerRight
uint256 constant ORDER_STATUS_SLOT = 4;
function _getOrderStatus(
	bytes32 _hash
) view returns(uint256 status) {
	assembly{
		mstore(ZERO_MEMORY_SLOT, _hash)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ORDER_STATUS_SLOT)
		status := sload(
			keccak256(ZERO_MEMORY_SLOT, 0x40)
		)
	}
}
function _setOrderStatus(
	bytes32 _hash,
	uint256 _status
) {
	assembly{
		mstore(ZERO_MEMORY_SLOT, _hash)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ORDER_STATUS_SLOT)
		sstore(
			keccak256(ZERO_MEMORY_SLOT, 0x40),
			_status
		)
	}
}

uint256 constant PROTOCOL_FEE_SLOT = 5;
function _getProtocolFee () view returns (uint256 protocolFee) {
	assembly{
		protocolFee := sload(PROTOCOL_FEE_SLOT)
	}
}
function _setProtocolFee (uint256 protocolFee) {
	assembly {
		sstore(PROTOCOL_FEE_SLOT, protocolFee)
	}
} 

uint256 constant ROYALTIES_SLOT = 6;
function _getRoyalty(
	address _collection,
	uint256 _index
) view returns (uint256 royalty) {
	assembly {
		mstore(ZERO_MEMORY_SLOT, _collection)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ROYALTIES_SLOT)
		let nestedHash := keccak256(ZERO_MEMORY_SLOT, 0x40)
		mstore(ZERO_MEMORY_SLOT, _index)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), nestedHash)
		royalty := sload(
			keccak256(ZERO_MEMORY_SLOT, 0x40)
		)
	}
}
function _setRoyalty(
	address _collection,
	uint256 _newRoyalty
) {
	assembly{
		// calculate royalty index slot for collection
		mstore(ZERO_MEMORY_SLOT, _collection)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ROYALTY_INDICES_SLOT)
		let indexSlot := keccak256(ZERO_MEMORY_SLOT, 0x40)
		// increment index
		let index := add(sload(indexSlot), 1)
		// store new index value
		sstore(indexSlot, index)
		// rewrite index storage slot with royalties slot
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ROYALTIES_SLOT)
		// calculate nested mapping hash
		let nestedHash := keccak256(ZERO_MEMORY_SLOT, 0x40)
		// use new index and nested mapping hash to calculate new royalties slot
		mstore(ZERO_MEMORY_SLOT, index)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), nestedHash)
		// store new royalties
		sstore(
			keccak256(ZERO_MEMORY_SLOT, 0x40),
			_newRoyalty
		)
	}
}

uint256 constant ROYALTY_INDICES_SLOT = 7;
function _getRoyaltyIndex(
	address _collection
) view returns (uint256 index) {
	assembly {
		mstore(ZERO_MEMORY_SLOT, _collection)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ROYALTY_INDICES_SLOT)
		index := sload(
			keccak256(ZERO_MEMORY_SLOT, 0x40)
		)
	}
}

uint256 constant VALIDATOR_SLOT = 8;
function _getValidatorAddress () view returns (address validatorAddress) {
	assembly{
		validatorAddress := sload(VALIDATOR_SLOT)
	}
}
function _setValidatorAddress (address _validatorAddress) {
	assembly {
		sstore(VALIDATOR_SLOT, _validatorAddress)
	}
} 

uint256 constant USER_NONCE_SLOT = 9;
function _getUserNonce (
	address user
) view returns(uint256 nonce) {
	assembly {
		mstore(ZERO_MEMORY_SLOT, user)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), USER_NONCE_SLOT)
		nonce := sload(
			keccak256(ZERO_MEMORY_SLOT, 0x40)
		)
	}
}
function _setUserNonce (
	uint256 _newNonce
) {
	assembly{
		mstore(ZERO_MEMORY_SLOT, caller())
		mstore(add(ZERO_MEMORY_SLOT, 0x20), USER_NONCE_SLOT)
		sstore(
			keccak256(ZERO_MEMORY_SLOT, 0x40),
			_newNonce
		)
	}
}

uint256 constant ORDER_FILL_AMOUNT_SLOT = 10;
function _getOrderFillAmount(
	bytes32 _hash
) view returns(uint256 amount) {
	assembly{
		mstore(ZERO_MEMORY_SLOT, _hash)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ORDER_FILL_AMOUNT_SLOT)
		amount := sload(
			keccak256(ZERO_MEMORY_SLOT, 0x40)
		)
	}
}
function _setOrderFillAmount(
	bytes32 _hash,
	uint256 _amount
) {
	assembly{
		mstore(ZERO_MEMORY_SLOT, _hash)
		mstore(add(ZERO_MEMORY_SLOT, 0x20), ORDER_FILL_AMOUNT_SLOT)
		sstore(
			keccak256(ZERO_MEMORY_SLOT, 0x40),
			_amount
		)
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

type CalldataPointer is uint256;
type MemoryPointer is uint256;

MemoryPointer constant FREE_MEMORY_POINTER = MemoryPointer.wrap(0x80);

uint256 constant ZERO_MEMORY_SLOT = 0x0;
uint256 constant CALLDATA_START = 0x04;
uint256 constant ONE_WORD = 0x20;
uint256 constant TWO_WORDS = 0x40;
uint256 constant THREE_WORDS = 0x60;
uint256 constant ONE_WORD_SHIFT = 0x5;
uint256 constant PROOF_KEY = 0x3;
uint256 constant PROOF_KEY_SHIFT = 0xe8;
uint256 constant ECDSA_MAX_LENGTH = 65;
bytes2 constant PREFIX = 0x1901;
bytes4 constant TRANSFER_ASSET_SELECTOR = 0x65a3ba36;
bytes4 constant TRANSFER_ASSETS_SELECTOR = 0x9c14b95b;
uint256 constant STRUCT_LENGTH_ONE = 1;
uint256 constant ERC20_ASSET_TYPE = 0;
uint256 constant ERC721_ASSET_TYPE = 1;
uint256 constant ERC1155_ASSET_TYPE = 2;
uint256 constant PRECISION = 10_000;

function _freeMemoryPointer () pure returns(MemoryPointer memPtr) {
	assembly{
		memPtr := mload(0x40)
	}
}

bytes32 constant HASH_OF_ZERO_BYTES=
    0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
uint256 constant LUCKY_NUMBER = 13;

/**
	Recover the address which signed `_hash` with signature `_signature`.

	@param _digest A hash signed by an address.
	@param _signature The signature of the hash.

	@return _ The address which signed `_hash` with signature `_signature.

	@custom:throws InvalidSignatureLength if the signature length is not valid.
*/
function _recover (
	bytes32 _digest,
	bytes calldata _signature
) pure returns (address) {

	// Divide the signature into r, s and v variables.
	bytes32 r;
	bytes32 s;
	uint8 v;
	assembly {
		r := calldataload(_signature.offset)
		s := calldataload(add(_signature.offset, 0x20))
		v := byte(0, calldataload(add(_signature.offset, 0x40)))
	}
	// Return the recovered address.
	return ecrecover(_digest, v, r, s);
}

// The selector for EIP-1271 contract-based signatures.
bytes4 constant EIP_1271_SELECTOR = bytes4(
	keccak256("isValidSignature(bytes32,bytes)")
);

/**
	A helper function to validate an EIP-1271 contract signature.

	@param _orderMaker The smart contract maker of the order.
	@param _hash The hash of the order.
	@param _signature The signature of the order to validate.

	@return _ Whether or not `_signature` is a valid signature of `_hash` by the 
		`_orderMaker` smart contract.
*/
function _recoverContractSignature (
	address _orderMaker,
	bytes32 _hash,
	bytes calldata _signature
) view returns (bool) {
	bytes32 r;
	bytes32 s;
	uint8 v;
	assembly {
		r := calldataload(_signature.offset)
		s := calldataload(add(_signature.offset, 0x20))
		v := byte(0, calldataload(add(_signature.offset, 0x40)))
	}
	bytes memory isValidSignatureData = abi.encodeWithSelector(
		EIP_1271_SELECTOR,
		_hash,
		abi.encodePacked(r, s, v)
	);

	/*
		Call the `_orderMaker` smart contract and check for the specific magic 
		EIP-1271 result.
	*/
	bytes4 result;
	assembly {
		let success := staticcall(
			
			// Forward all available gas.
			gas(),
			_orderMaker,
	
			// The calldata offset comes after length.
			add(isValidSignatureData, 0x20),

			// Load calldata length.
			mload(isValidSignatureData), // load calldata length

			// Do not use memory for return data.
			0,
			0
		)

		/*
			If the call failed, copy return data to memory and pass through revert 
			data.
		*/
		if iszero(success) {
			returndatacopy(0, 0, returndatasize())
			revert(0, returndatasize())
		}

		/*
			If the return data is the expected size, copy it to memory and load it 
			to our `result` on the stack.
		*/
		if eq(returndatasize(), 0x20) {
			returndatacopy(0, 0, 0x20)
			result := mload(0)
		}
	}

	// If the collected result is the expected selector, the signature is valid.
	return result == EIP_1271_SELECTOR;
}

/**
	A helper function for wrapping a low-level Ether transfer call with modern 
	error reversion.

	@param _to The address to send Ether to.
	@param _value The value of Ether to send to `_to`.

	@custom:throws TransferFailed if the transfer of Ether fails.
*/
function _transferEth (
	address _to,
	uint _value
) {
	(bool success, ) = _to.call{ value: _value }("");
	if (!success) {
		revert("ETH transfer failed.");
	}
}

function _verifyProof(
	uint256 leaf,
	bytes32 root,
	bytes32[] calldata proofs
) pure returns (bool valid) {
	assembly {
		mstore(0, leaf)
		let hash := keccak256(0, ONE_WORD)
		let data := add(proofs.offset, ONE_WORD)

		for {
			// Left shift by 5 is equivalent to multiplying by 0x20.
			let end := add(data, shl(ONE_WORD_SHIFT, calldataload(proofs.offset)))
		} lt(data, end) {
			// Increment by one word at a time.
			data := add(data, ONE_WORD)
		} {
			// Get the proof.
			let proof := calldataload(data)

			// Store lesser value in the zero slot
			let ptr := shl(ONE_WORD_SHIFT, gt(hash, proof))
			mstore(ptr, hash)
			mstore(xor(ptr, ONE_WORD), proof)

			// Calculate the hash.
			hash := keccak256(0, TWO_WORDS)
		}

		// Compare the final hash to the supplied root.
		valid := eq(hash, root)
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@custom:date January 28th, 2023.
*/

struct Asset {
	AssetType assetType;
	address collection;
	address from;
	address to;
	uint256 id;
	uint256 amount;
}

struct Transfer {
	AssetType assetType;
	address collection;
	address to;
	uint256 id;
	uint256 amount;
}

enum AssetType {
	ERC20,
	ERC721,
	ERC1155
}

interface IAssetHandler {

	function transferAssets (
		Asset[] calldata _assets
	) external;

	function transferAsset(
		Asset calldata _asset
	) external;

	function transferMultipleItems (
		Transfer[] calldata _transfers
	) external;

	function transferERC20 (
		address _token,
		address _from,
		address _to,
		uint256 _amount
	) external;

}
/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@custom:date January 28th, 2023.
*/
interface IRegistry {

	/**
		Allow the `ProxyRegistry` owner to begin the process of enabling access to
		the registry for the unauthenticated address `_unauthenticated`. Once the
		grant authentication process has begun, it is subject to the `DELAY_PERIOD`
		before the authentication process may conclude. Once concluded, the new
		address `_unauthenticated` will have access to the registry.

		@param _unauthenticated The new address to grant access to the registry.

		@custom:throws AlreadyAuthorized if the address beginning authentication is 
			already an authorized caller.
		@custom:throws AlreadyPendingAuthentication if the address beginning 
			authentication is already pending.
	*/
	function startGrantAuthentication (
		address _unauthenticated
	) external;

	/**
		Allow the `ProxyRegistry` owner to end the process of enabling access to the
		registry for the unauthenticated address `_unauthenticated`. If the required
		`DELAY_PERIOD` has passed, then the new address `_unauthenticated` will have
		access to the registry.

		@param _unauthenticated The new address to grant access to the registry.

		@custom:throws AlreadyAuthorized if the address beginning authentication is
			already an authorized caller.
		@custom:throws AddressHasntStartedAuth if the address attempting to end 
			authentication has not yet started it.
		@custom:throws AddressHasntClearedTimelock if the address attempting to end 
			authentication has not yet incurred a sufficient delay.
	*/
	function endGrantAuthentication(
		address _unauthenticated
	) external;

	/**
		Allow the owner of the `ProxyRegistry` to immediately revoke authorization
		to call proxies from the specified address.

		@param _caller The address to revoke authentication from.
	*/
	function revokeAuthentication (
		address _caller
	) external;
}

interface IGigaMartManager is IRegistry, IAssetHandler{}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	PermitControl
} from "../../access/PermitControl.sol";

import {
	_getProtocolFee,
	_setProtocolFee
} from "./Storage.sol";

/// Thrown if attempting to set the protocol fee to zero.
error ProtocolFeeRecipientCannotBeZero();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Base Fee Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing platform fee management capabilities to GigaMart.
*/
contract BaseFeeManager is PermitControl {

	/// The public identifier for the right to update the fee configuration.
	bytes32 public constant FEE_CONFIG = keccak256("FEE_CONFIG");

	/**
		Emmited when protocol fee config is altered.

		@param oldProtocolFeeRecipient The previous recipient address of protocol 
			fees.
		@param newProtocolFeeRecipient The new recipient address of protocol fees.
		@param oldProtocolFeePercent The previous amount of protocol fees.
		@param newProtocolFeePercent The new amount of protocol fees. 
	*/
	event ProtocolFeeChanged (
		address oldProtocolFeeRecipient,
		address newProtocolFeeRecipient,
		uint256 oldProtocolFeePercent,
		uint256 newProtocolFeePercent
	);

	/**
		Construct a new instance of the GigaMart fee manager.

		@param _protocolFeeRecipient The address that receives the protocol fee.
		@param _protocolFeePercent The percentage of the protocol fee in basis 
			points, i.e. 200 = 2%.
	*/
	constructor (
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) {
		unchecked {
			uint256 newProtocolFee =
				(uint256(uint160(_protocolFeeRecipient)) << 96) +
				uint256(_protocolFeePercent);
			_setProtocolFee(newProtocolFee);
		}
	}

	/**
		Returns current protocol fee config.
	*/
	function currentProtocolFee() public view returns (address, uint256) {
		uint256 fee = _getProtocolFee();
		return (address(uint160(fee >> 96)), uint256(uint96(fee)));
	}

	/**
		Changes the the fee details of the protocol.

		@param _newProtocolFeeRecipient The address of the new protocol fee 
			recipient.
		@param _newProtocolFeePercent The new amount of the protocol fees in basis 
			points, i.e. 200 = 2%.

		@custom:throws ProtocolFeeRecipientCannotBeZero if attempting to set the 
			recipient of the protocol fees to the zero address.
	*/
	function changeProtocolFees (
		address _newProtocolFeeRecipient,
		uint256 _newProtocolFeePercent
	) external hasValidPermit(UNIVERSAL, FEE_CONFIG) {
		if (_newProtocolFeeRecipient == address(0)) {
			revert ProtocolFeeRecipientCannotBeZero();
		}

		// Update the protocol fee.
		uint256 oldProtocolFee = _getProtocolFee();
		unchecked {
			uint256 newprotocolFee =
				(uint256(uint160(_newProtocolFeeRecipient)) << 96) +
				uint256(_newProtocolFeePercent);
			_setProtocolFee(newprotocolFee);
		}

		// Emit an event notifying about the update.
		emit ProtocolFeeChanged(
			address(uint160(oldProtocolFee >> 96)),
			_newProtocolFeeRecipient,
			uint256(uint96(oldProtocolFee)),
			_newProtocolFeePercent
		);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {
	ONE_WORD,
	TWO_WORDS,
	ONE_WORD_SHIFT,
	PROOF_KEY,
	PROOF_KEY_SHIFT,
	ECDSA_MAX_LENGTH
} from "./Helpers.sol";

import {
	MAX_BULK_ORDER_HEIGHT,
	ORDER_TYPEHASH,
	BULK_ORDER_HEIGHT_ONE_TYPEHASH,
	BULK_ORDER_HEIGHT_TWO_TYPEHASH,
	BULK_ORDER_HEIGHT_THREE_TYPEHASH,
	BULK_ORDER_HEIGHT_FOUR_TYPEHASH,
	BULK_ORDER_HEIGHT_FIVE_TYPEHASH,
	BULK_ORDER_HEIGHT_SIX_TYPEHASH,
	BULK_ORDER_HEIGHT_SEVEN_TYPEHASH,
	BULK_ORDER_HEIGHT_EIGHT_TYPEHASH,
	BULK_ORDER_HEIGHT_NINE_TYPEHASH,
	BULK_ORDER_HEIGHT_TEN_TYPEHASH
} from "./OrderConstants.sol";

error MaxBulkOrderHeightExceeded(uint256);

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title EIP-712 Domain Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing EIP-712 signature-services.
*/
contract DomainAndTypehashes {

	/**
		The typehash of the EIP-712 domain, used in dynamically deriving a domain 
		separator.
	*/
	/**
		The typehash of the EIP-712 domain, used in dynamically deriving a domain 
		separator.
	*/
	bytes32 private constant _EIP712_DOMAIN_TYPEHASH = keccak256(
		"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
	);

	/// A name used in the domain separator.
	string public constant name = "GigaMart";

	/// The immutable chain ID detected during construction.
	uint256 internal immutable _CHAIN_ID;

	/// The immutable chain ID created during construction.
	bytes32 private immutable _DOMAIN_SEPARATOR;

	/**
		Construct a new EIP-712 domain instance.
	*/
	constructor () {
		uint chainId;
		assembly {
			chainId := chainid()
		}
		_CHAIN_ID = chainId;
		_DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				_EIP712_DOMAIN_TYPEHASH,
				keccak256(bytes(name)),
				keccak256(bytes(version())),
				chainId,
				address(this)
			)
		);
	}

	/**
		Return the version of this EIP-712 domain.

		@return _ The version of this EIP-712 domain.
	*/
	function version () public pure returns (string memory) {
		return "1";
	}

	/**
		Dynamically derive an EIP-712 domain separator.

		@return _ A constructed domain separator.
	*/
	function _deriveDomainSeparator () internal view returns (bytes32) {
		uint chainId;
		assembly {
			chainId := chainid()
		}
		return chainId == _CHAIN_ID
			? _DOMAIN_SEPARATOR
			: keccak256(
				abi.encode(
					_EIP712_DOMAIN_TYPEHASH,
					keccak256(bytes(name)),
					keccak256(bytes(version())),
					chainId,
					address(this)
				)
			);
	}

	    function _computeBulkOrderProof(
        bytes calldata proofAndSignature,
        bytes32 leaf
    ) internal pure returns (bytes32 bulkOrderHash) {
        // Declare arguments for the root hash and the height of the proof.
        bytes32 root;
        uint256 height;
		
        // Utilize assembly to efficiently derive the root hash using the proof.
        assembly {
            // Retrieve the length of the proof, key, and signature combined.
            let fullLength := proofAndSignature.length

            // If proofAndSignature has odd length, it is a compact signature
            // with 64 bytes.
            let signatureLength := sub(ECDSA_MAX_LENGTH, and(fullLength, 1))

            // Derive height (or depth of tree) with signature and proof length.
            height := shr(ONE_WORD_SHIFT, sub(fullLength, signatureLength))

            // Derive the pointer for the key using the signature length.
            let keyPtr := add(proofAndSignature.offset, signatureLength)
		
            // Retrieve the three-byte key using the derived pointer.
            let key := shr(PROOF_KEY_SHIFT, calldataload(keyPtr))
	
            /// Retrieve pointer to first proof element by applying a constant
            // for the key size to the derived key pointer.
            let proof := add(keyPtr, PROOF_KEY)
			
           // Compute level 1.
            let scratchPtr1 := shl(ONE_WORD_SHIFT, and(key, 1))
            mstore(scratchPtr1, leaf)
            mstore(xor(scratchPtr1, ONE_WORD), calldataload(proof))

            // Compute remaining proofs.
            for {
                let i := 1
            } lt(i, height) {
                i := add(i, 1)
            } {
                proof := add(proof, ONE_WORD)
                let scratchPtr := shl(ONE_WORD_SHIFT, and(shr(i, key), 1))
                mstore(scratchPtr, keccak256(0, TWO_WORDS))
                mstore(xor(scratchPtr, ONE_WORD), calldataload(proof))
            }

            // Compute root hash.
            root := keccak256(0, TWO_WORDS)
        }
        // Retrieve appropriate typehash constant based on height.
        bytes32 rootTypeHash = _deriveBulkOrderTypehash(height);

        // Use the typehash and the root hash to derive final bulk order hash.
        assembly {
            mstore(0, rootTypeHash)
            mstore(ONE_WORD, root)
            bulkOrderHash := keccak256(0, TWO_WORDS)
        }
    }

	function _deriveBulkOrderTypehash (
		uint256 height
	) internal pure returns (bytes32 typehash) {
		if ( height > MAX_BULK_ORDER_HEIGHT ) {
			revert MaxBulkOrderHeightExceeded(height);
		}
		assembly {
			switch height
				case 1 {
					typehash := BULK_ORDER_HEIGHT_ONE_TYPEHASH
				}
				case 2 {
					typehash := BULK_ORDER_HEIGHT_TWO_TYPEHASH
				}
				case 3 {
					typehash := BULK_ORDER_HEIGHT_THREE_TYPEHASH
				}
				case 4 {
					typehash := BULK_ORDER_HEIGHT_FOUR_TYPEHASH
				}
				case 5 {
					typehash := BULK_ORDER_HEIGHT_FIVE_TYPEHASH
				}
				case 6 {
					typehash := BULK_ORDER_HEIGHT_SIX_TYPEHASH
				}
				case 7 {
					typehash := BULK_ORDER_HEIGHT_SEVEN_TYPEHASH
				}
				case 8 {
					typehash := BULK_ORDER_HEIGHT_EIGHT_TYPEHASH
				}
				case 9 {
					typehash := BULK_ORDER_HEIGHT_NINE_TYPEHASH
				}
				case 10 {
					typehash := BULK_ORDER_HEIGHT_TEN_TYPEHASH
				}
				default {
					typehash := ORDER_TYPEHASH
				}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title An advanced permission-management contract.
	@author Tim Clancy <@_Enoch>

	This contract allows for a contract owner to delegate specific rights to
	external addresses. Additionally, these rights can be gated behind certain
	sets of circumstances and granted expiration times. This is useful for some
	more finely-grained access control in contracts.

	The owner of this contract is always a fully-permissioned super-administrator.

	@custom:date August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
	using Address for address;

	/// A special reserved constant for representing no rights.
	bytes32 public constant ZERO_RIGHT = hex"00000000000000000000000000000000";

	/// A special constant specifying the unique, universal-rights circumstance.
	bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

	/**
		A special constant specifying the unique manager right. This right allows an
		address to freely-manipulate the `managedRight` mapping.
	*/
	bytes32 public constant MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

	/**
		A mapping of per-address permissions to the circumstances, represented as
		an additional layer of generic bytes32 data, under which the addresses have
		various permits. A permit in this sense is represented by a per-circumstance
		mapping which couples some right, represented as a generic bytes32, to an
		expiration time wherein the right may no longer be exercised. An expiration
		time of 0 indicates that there is in fact no permit for the specified
		address to exercise the specified right under the specified circumstance.

		@dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
		max-integer circumstance. Perpetual rights may be given an expiry time of
		max-integer.
	*/
	mapping ( address => mapping ( bytes32 => mapping ( bytes32 => uint256 ))) 
		public permissions;

	/**
		An additional mapping of managed rights to manager rights. This mapping
		represents the administrator relationship that various rights have with one
		another. An address with a manager right may freely set permits for that
		manager right's managed rights. Each right may be managed by only one other
		right.
	*/
	mapping ( bytes32 => bytes32 ) public managerRight;

	/**
		An event emitted when an address has a permit updated. This event captures,
		through its various parameter combinations, the cases of granting a permit,
		updating the expiration time of a permit, or revoking a permit.

		@param updater The address which has updated the permit.
		@param updatee The address whose permit was updated.
		@param circumstance The circumstance wherein the permit was updated.
		@param role The role which was updated.
		@param expirationTime The time when the permit expires.
	*/
	event PermitUpdated (
		address indexed updater,
		address indexed updatee,
		bytes32 circumstance,
		bytes32 indexed role,
		uint256 expirationTime
	);

	/**
		An event emitted when a management relationship in `managerRight` is
		updated. This event captures adding and revoking management permissions via
		observing the update history of the `managerRight` value.

		@param manager The address of the manager performing this update.
		@param managedRight The right which had its manager updated.
		@param managerRight The new manager right which was updated to.
	*/
	event ManagementUpdated (
		address indexed manager,
		bytes32 indexed managedRight,
		bytes32 indexed managerRight
	);

	/**
		A modifier which allows only the super-administrative owner or addresses
		with a specified valid right to perform a call.

		@param _circumstance The circumstance under which to check for the validity
			of the specified `right`.
		@param _right The right to validate for the calling address. It must be
			non-expired and exist within the specified `_circumstance`.
	*/
	modifier hasValidPermit (
		bytes32 _circumstance,
		bytes32 _right
	) {
		require(
			_msgSender() == owner() || hasRight(_msgSender(), _circumstance, _right),
			"P1"
		);
		_;
	}

	/**
		Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
		specified `_managedRight`.

		@param _managedRight The right which is to have its manager set to
			`_managerRight`.
		@param _managerRight The right whose `UNIVERSAL` holders may manage
			`_managedRight`.
	*/
	function setManagerRight (
		bytes32 _managedRight,
		bytes32 _managerRight
	) external virtual hasValidPermit(UNIVERSAL, MANAGER) {
		require(_managedRight != ZERO_RIGHT, "P3");
		managerRight[_managedRight] = _managerRight;
		emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
	}

	/**
		Set the permit to a specific address under some circumstances. A permit may
		only be set by the super-administrative contract owner or an address holding
		some delegated management permit.

		@param _address The address to assign the specified `_right` to.
		@param _circumstance The circumstance in which the `_right` is valid.
		@param _right The specific right to assign.
		@param _expirationTime The time when the `_right` expires for the provided
			`_circumstance`.
	*/
	function setPermit (
		address _address,
		bytes32 _circumstance,
		bytes32 _right,
		uint256 _expirationTime
	) public virtual hasValidPermit(UNIVERSAL, managerRight[_right]) {
		require(_right != ZERO_RIGHT, "P2");
		permissions[_address][_circumstance][_right] = _expirationTime;
		emit PermitUpdated(
			_msgSender(),
			_address,
			_circumstance,
			_right,
			_expirationTime
		);
	}

	/**
		Determine whether or not an address has some rights under the given
		circumstance, and if they do have the right, until when.

		@param _address The address to check for the specified `_right`.
		@param _circumstance The circumstance to check the specified `_right` for.
		@param _right The right to check for validity.

		@return The timestamp in seconds when the `_right` expires. If the timestamp
			is zero, we can assume that the user never had the right.
	*/
	function hasRightUntil (
		address _address,
		bytes32 _circumstance,
		bytes32 _right
	) public view returns (uint256) {
		return permissions[_address][_circumstance][_right];
	}

	/**
		Determine whether or not an address has some rights under the given
		circumstance,

		@param _address The address to check for the specified `_right`.
		@param _circumstance The circumstance to check the specified `_right` for.
		@param _right The right to check for validity.

		@return true or false, whether user has rights and time is valid.
	*/
	function hasRight (
		address _address,
		bytes32 _circumstance,
		bytes32 _right
	) public view returns (bool) {
		return permissions[_address][_circumstance][_right] > block.timestamp;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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