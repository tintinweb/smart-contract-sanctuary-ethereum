// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./core/Executor.sol";

/// Thrown if the count of items in required argument arrays differ.
error ArgumentsLengthMismatched ();

/**
	Thrown during mass-cancelation if the provided nonce is lower than current 
	nonce.

	@param nonce The nonce used to indicate the current set of uncanceled user 
		orders.
*/
error NonceLowerThanCurrent (
	uint256 nonce
);

/// Thrown if attempting to send items to the zero address.
error InvalidRecipient ();

/**
	Thrown if attempting to execute an order that is not valid for fulfillment; 
	this prevents offers from being executed as if they were listings.
*/
error WrongOrderType ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Exchange
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	@custom:contributor throw; <@0xthrpw>
	
	GigaMart is a new NFT platform built for the world by the SuperVerse DAO. 
	This is the first iteration of the exchange and is based on a delegated user 
	proxy architecture.

	@custom:date December 4th, 2022.
*/
contract GigaMart is Executor, ReentrancyGuard {

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

	/**
		Construct a new instance of the GigaMart exchange.

		@param _registry The address of the existing proxy registry.
		@param _tokenTransferProxy The address of the token transfer proxy contract.
		@param _validator The address of a privileged validator for permitting 
			collection administrators to control their royalty fees.
		@param _protocolFeeRecipient The address which receives fees from the 
			exchange.
		@param _protocolFeePercent The percent of fees taken by 
			`_protocolFeeRecipient` in basis points (1/100th %; i.e. 200 = 2%).
	*/
	constructor (
		IProxyRegistry _registry,
		TokenTransferProxy _tokenTransferProxy,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) Executor(
		_registry,
		_tokenTransferProxy,
		_validator,
		_protocolFeeRecipient,
		_protocolFeePercent
	) { }

	/**
		Allow the caller to cancel an order so long as they are the maker of the 
		order.

		@param _order The `Order` data to cancel.
	*/
	function cancelOrder (
		Entities.Order calldata _order
	) external {
		_cancelOrder(_order);
	}

	/**
		Allow the caller to cancel a set of particular orders so long as they are 
		the maker of each order.

		@param _orders An array of `Order` data to cancel.
	*/
	function cancelOrders (
		Entities.Order[] calldata _orders
	) public {
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

		// Verify that the new nonce is not less than the current nonce.
		if (_minNonce < minOrderNonces[msg.sender]) {
			revert NonceLowerThanCurrent(minOrderNonces[msg.sender]);
		}

		// Set the new minimum nonce and emit an event.
		minOrderNonces[msg.sender] = _minNonce;
		emit AllOrdersCancelled(msg.sender, _minNonce);
	}

	/**
		Transfer multiple items using the user-proxy and executable bytecode.

		@param _targets The array of addresses which should be called with the 
			function calls encoded in `_data`.
		@param _data The array of encoded function calls performed against the 
			addresses in `_targets`.

		@custom:throws ArgumentsLengthMismatched if the `_targets` and `_data` 
			arrays are mismatched.
	*/
	function transferMultipleItems (
		address[] calldata _targets,
		bytes[] calldata _data
	) external {
		if (_targets.length != _data.length) {
			revert ArgumentsLengthMismatched();
		}
		_multiTransfer(_targets, _data);
	}

	/**
		Exchange a single ERC-721 or ERC-1155 item for Ether or ERC-20 tokens.

		@param _recipient The address which will receive the item.
		@param _order The `Order` to execute.
		@param _signature The signature provided for fulfilling the order.
		@param _tokenId The unique token ID of the item.
		@param _toInvalidate An optional array of `Order`s by the same caller to 
			cancel while fulfilling the exchange.

		@custom:throws InvalidRecipient if the item `_recipient` is the zero 
			address.
	*/
	function exchangeSingleItem (
		address _recipient,
		Entities.Order memory _order,
		Entities.Sig calldata _signature,
		uint256 _tokenId,
		Entities.Order[] calldata _toInvalidate
	) external payable nonReentrant {

		// Prevent the item from being sent to the zero address.
		if (_recipient == address(0)) {
			revert InvalidRecipient();
		}

		// Perform the exchange.
		_exchange(_recipient, _order, _signature, _tokenId);
		
		// Optionally invalidate other orders while performing this exchange.
		if (_toInvalidate.length > 0) {
			cancelOrders(_toInvalidate);
		}
	}

	/**
		Exchange multiple ERC-721 or ERC-1155 items for Ether or ERC-20 tokens.

		@param _recipient The address which will receive the items.
		@param _orders The array of orders that are being executed.
		@param _signatures The array of signatures provided for fulfilling the 
			orders.
		@param _toInvalidate An optional array of `Order`s by the same caller to 
			cancel while fulfilling the exchange.

		@custom:throws ArgumentsLengthMismatched if the `_orders` and `_signatures` 
			arrays are mismatched.
		@custom:throws InvalidRecipient if the item `_recipient` is the zero 
			address.
		@custom:throws WrongOrderType if attempting to fulfill an offer using this 
			function.
	*/
	function exchangeMultipleItems (
		address _recipient,
		Entities.Order[] memory _orders,
		Entities.Sig[] calldata _signatures,
		Entities.Order[] calldata _toInvalidate
	) external payable nonReentrant {
		if (_orders.length != _signatures.length) {
			revert ArgumentsLengthMismatched();
		}

		// Prevent the item from being sent to the zero address.
		if (_recipient == address(0)) {
			revert InvalidRecipient();
		}

		// Prepare an accumulator array for collecting payments.
		bytes memory payments = new bytes(32);
		for (uint256 i; i < _orders.length; ) {

			// Prevent offers from being fulfilled by this function.
			if (uint8(_orders[i].outline.saleKind) > 2) {
				revert WrongOrderType();
			}

			// Perform each exchange and accumulate payments.
			_exchangeUnchecked(_recipient, _orders[i], _signatures[i], payments);
			unchecked {
				i++;
			}
		}

		// Fulfill the accumulated payment.
		_pay(payments, msg.sender, address(tokenTransferProxy));

		// Optionally invalidate other orders after performing this exchange.
		if (_toInvalidate.length > 0) {
			cancelOrders(_toInvalidate);
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
pragma solidity ^0.8.15;

import {
	Entities,
	Sales,
	AuthenticatedProxy
} from "./Entities.sol";
import {
	RoyaltyManager
} from "./RoyaltyManager.sol";
import {
	NativeTransfer
} from "../libraries/NativeTransfer.sol";
import {
	OwnableDelegateProxy
} from "../proxy/OwnableDelegateProxy.sol";
import {
	TokenTransferProxy,
	IProxyRegistry,
	Address
} from "../proxy/TokenTransferProxy.sol";

/// Thrown if the user proxy does not exist (bytecode length is zero).
error UserProxyDoesNotExist ();

/**
	Thrown if the user-proxy implementation is pointing to an unexpected 
	implementation.
*/
error UnknownUserProxyImplementation ();

/// Thrown if a call to the user-proxy are fails.
error CallToProxyFailed ();

/**
	Thrown on order cancelation if the order already has been fulfilled or 
	canceled.
*/
error OrderIsAlreadyCancelled ();

/**
	Thrown when attempting order cancelation functions, if checks for msg.sender,
	order nonce or signatures are failed. 
*/
error CannotAuthenticateOrder ();

/**
	Thrown if order terms are invalid, expired, or the provided exchange address 
	does not match this contract.
*/
error InvalidOrder ();

/**
	Thrown if insufficient value is sent to fulfill an order price.
*/
error NotEnoughValueSent ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Executor
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	@custom:contributor throw; <@0xthrpw>
	
	This first iteration of the exchange executor is inspired by the old Wyvern 
	architecture `ExchangeCore`.

	@custom:version 1.1
	@custom:date December 14th, 2022.
*/
abstract contract Executor is RoyaltyManager {
	using Entities for Entities.Order;
	using NativeTransfer for address;

	/**
		A specific 13 second duration, slightly longer than the duration of one 
		block, so as to allow the successful execution of orders within a leeway of 
		approximately one block.
	*/
	uint256 private constant LUCKY_NUMBER = 13;

	/// The selector for EIP-1271 contract-based signatures.
	bytes4 internal constant EIP_1271_SELECTOR = bytes4(
		keccak256("isValidSignature(bytes32,bytes)")
	);

	/// A reference to the immutable proxy registry.
	IProxyRegistry public immutable registry;

	/// A global, shared token transfer proxy for fulfilling exchanges.
	TokenTransferProxy public immutable tokenTransferProxy;

	/**
		A mapping from each caller to the minimum nonce of their order books. When 
		a caller increments their nonce, all user offers with nonces below the 
		value in this mapping are canceled.
	*/
	mapping ( address => uint256 ) public minOrderNonces;

	/// A mapping of all orders which have been canceled or finalized.
	mapping ( bytes32 => bool ) public cancelledOrFinalized;

	/**
		Emitted when an order is canceled.

		@param maker The order maker's address.
		@param hash The hash of the order.
		@param data The parameters of the order concatenated together, e.g. 
			{collection address, encoded transfer function call}.
	*/
	event OrderCancelled (
		address indexed maker,
		bytes32 hash,
		bytes data
	);

	/**
		Emitted at each attempt of exchanging an item.

		@param order The hash of the order.
		@param maker The order maker's address.
		@param taker The order taker's address.
		@param data An array of bytes that contains the success status, order sale 
			kind, price, payment token, target, and transfer data.
	*/
	event OrderResult (
		bytes32 order,
		address indexed maker,
		address indexed taker,
		bytes data
	);

	/**
		Construct a new instance of the GigaMart order executor.

		@param _registry The address of the existing proxy registry.
		@param _tokenTransferProxy The address of the token transfer proxy contract.
		@param _validator The address of a privileged validator for permitting 
			collection administrators to control their royalty fees.
		@param _protocolFeeRecipient The address which receives fees from the 
			exchange.
		@param _protocolFeePercent The percent of fees taken by 
			`_protocolFeeRecipient` in basis points (1/100th %; i.e. 200 = 2%).
	*/
	constructor (
		IProxyRegistry _registry,
		TokenTransferProxy _tokenTransferProxy,
		address _validator,
		address _protocolFeeRecipient,
		uint96 _protocolFeePercent
	) RoyaltyManager(_validator, _protocolFeeRecipient, _protocolFeePercent) {
		tokenTransferProxy = _tokenTransferProxy;
		registry = _registry;
	}

	/**
		Hash an order and return the hash that a client must sign, including the 
		standard message prefix.

		@param _order The order to sign.

		@return _ The order hash that must be signed by the client.
	*/
	function _hashToSign (
		Entities.Order memory _order
	) private view returns (bytes32) {
		return keccak256(
			abi.encodePacked(
				"\x19\x01",
				_deriveDomainSeparator(),
				_order.hash()
			)
		);
	}

	/**
		Cancel an order, preventing it from being matched. An order must be 
		canceled by its maker.
		
		@param order The `Order` to cancel.

		@custom:throws OrderAlreadyCancelled if the order has already been 
			fulfilled, individually canceled, or mass-canceled.
		@custom:throws CannotAuthenticateOrder if the caller is not the maker of 
			the order.
	*/
	function _cancelOrder (
		Entities.Order calldata order
	) internal {

		// Calculate the order hash.
		bytes32 hash = _hashToSign(order);

		// Verify order is still live.
		if (
			cancelledOrFinalized[hash] ||	order.nonce < minOrderNonces[msg.sender]
		) {
			revert OrderIsAlreadyCancelled();
		}

		// Verify the order is being canceled by its maker.
		if (order.outline.maker != msg.sender) {
			revert CannotAuthenticateOrder();
		}

		// Cancel the order and log the event.
		cancelledOrFinalized[hash] = true;
		emit OrderCancelled(
			order.outline.maker,
			hash,
			abi.encode(order.outline.target, order.data)
		);
	}

	/**
		Transfer multiple items using the user-proxy and executable bytecode.

		@param _targets The array of addresses which should be called with the 
			function calls encoded in `_data`.
		@param _data The array of encoded function calls performed against the 
			addresses in `_targets`.

		@custom:throws UserProxyDoesNotExist if the targeted delegate proxy for the 
			user does not exist.
		@custom:throws UnknownUserProxyImplementation if the targeted delegate 
			proxy implementation is not as expected.
		@custom:throws CallToProxyFailed if an encoded call to the proxy fails.
	*/
	function _multiTransfer (
		address[] calldata _targets,
		bytes[] calldata _data
	) internal {

		// Store the registry object in memory to save gas.
		IProxyRegistry proxyRegistry = registry;

		// Retrieve the caller's delegate proxy, verifying that it exists.
		address delegateProxy = proxyRegistry.proxies(msg.sender);
		if (!Address.isContract(delegateProxy)) {
			revert UserProxyDoesNotExist();
		}

		// Verify that the implementation of the user's delegate proxy is expected.
		if (
			OwnableDelegateProxy(payable(delegateProxy)).implementation() !=
			proxyRegistry.delegateProxyImplementation()
		) {
			revert UnknownUserProxyImplementation();
		}

		// Access the passthrough `AuthenticatedProxy` to make transfer calls.
		AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));
		for (uint256 i; i < _targets.length; ) {

			// Perform each encoded call and verify that they succeeded.
			if (
				!proxy.call(
					_targets[i],
					AuthenticatedProxy.CallType.Call,
					_data[i]
				)
			) {
				revert CallToProxyFailed();
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Perform validation on the supplied `_taker` and `_order` address. This 
		validation ensures that the correct exchange is used and that the order 
		maker is neither the recipient, message sender, or zero address. This 
		validation also ensures that the salekind is sensible and matches the 
		provided order parameters.

		@param _taker The address of the order taker.
		@param _order The order to perform parameter validation against.

		@return _ Whether or not the specified `_order` is valid to be fulfilled by 
			the `_taker`.
	*/
	function _validateOrderParameters (
		address _taker,
		Entities.Order memory _order
	) private view returns (bool) {

		// Verify that the order is targeted at this exchange contract.
		if (_order.outline.exchange != address(this)) {
			return false;
		}

		/*
			Verify that the order maker is not the `_taker`, nor the msg.sender, nor 
			the zero address.
		*/
		if (
			_order.outline.maker == _taker ||
			_order.outline.maker == msg.sender ||
			_order.outline.maker == address(0)
		) {
			return false;
		}

		/*
			In a typical Wyvern order flow, this is the point where one would ensure 
			that the order target exists. This is done to prevent the low-hanging 
			attack of a malicious item collection self-destructing and rendering 
			orders worthless. This protection uses a not-insignificant amount of gas 
			and does not prevent against additional malicious attacks such as 
			front-running from an upgradeable contract. Given the number of other 
			possible rugpulls that an item collection could pull against its holders, 
			this seems like a reasonable trade-off.
		*/

		/*
			Allow the fulfillment of an order if the current block time is within the 
			listing and expiration time of that order, less a small gap to support 
			the case of immediate signature creation and fulfillment within a single 
			block.
		*/
		if (
			!Sales._canSettleOrder(
				_order.outline.listingTime - LUCKY_NUMBER,
				_order.outline.expirationTime
			)
		) {
			return false;
		}

		// Validate the call to ensure the correct function selector is being used.
		if (!_order.validateCall()) {
			return false;
		}

		// The order must possess a valid sale kind parameter.
		uint8 saleKind = uint8(_order.outline.saleKind);
		if (saleKind > 5) {
			return false;
		}

		// Reject item sales which are presented as buy-sided.
		if (saleKind < 3 && _order.outline.side == Sales.Side.Buy) {
			return false;
		}

		// Reject item offers which are presented as sell-sided.
		if (saleKind > 2 && _order.outline.side == Sales.Side.Sell) {
			return false;
		}

		/*
			There is no need to validate the `_taker` that may be later inserted into 
			the order call data for our `FixedPrice` or `DecreasingPrice` sale kinds. 
			In each of these cases, the message sender cannot achieve anything 
			malicious by attempting to modify the `_taker` which is later inserted 
			into the order.
		*/

		/*
			This sale kind is a `DirectListing`, which is meant to be a private 
			listing of an item fulfillable by a single specific taker. For this kind 
			of order, we validate that the `_taker` specified is the same as the 
			taker encoded in the order.
		*/
		if (saleKind == 2 && _taker != _order.outline.taker) {
			return false;
		}

		/*
			This sale kind is a `DirectOffer`, which is meant to be a private offer 
			fulfillable against only a single item by a single specific taker. In 
			other words, the offer does not follow the item if the item finds itself 
			in the hands of a new holder. For this kind of order, we validate that 
			the `_taker` is both the message sender and the taker encoded in the 
			order.
		*/
		if (
			saleKind == 3 &&
			(_order.outline.taker != msg.sender || _taker != _order.outline.taker)
		) {
			return false;
		}

		/*
			These two sale kinds correspond to `Offer` and `CollectionOffer`, each of 
			which are publically fulfillable by multiple potential takers. For 
			fulfilling these kinds of orders, the `_taker` specified must be the 
			message sender, lest an item holder be forced to accept an offer against 
			their will.
		*/
		if ((saleKind == 4 || saleKind == 5) && _taker != msg.sender) {
			return false;
		}

		// All is validated successfully.
		return true;
	}

	/**
		A helper function to validate an EIP-1271 contract signature.

		@param _orderMaker The smart contract maker of the order.
		@param _hash The hash of the order.
		@param _sig The signature of the order to validate.

		@return _ Whether or not `_sig` is a valid signature of `_hash` by the 
			`_orderMaker` smart contract.
	*/
	function _recoverContractSignature (
		address _orderMaker,
		bytes32 _hash,
		Entities.Sig memory _sig
	) private view returns (bool) {
		bytes memory isValidSignatureData = abi.encodeWithSelector(
			EIP_1271_SELECTOR,
			_hash,
			abi.encodePacked(_sig.r, _sig.s, _sig.v)
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
		Validate that a provided order `_hash` does not correspond to a finalized 
		order, was not created with an invalidated nonce, and was actually signed 
		by its maker `_maker` with signature `_sig`.

		@param _hash A hash of an `Order` to validate.
		@param _maker The address of the maker who signed the order `_hash`.
		@param _nonce A nonce in the order for checking validity in 
			mass-cancelation.
		@param _sig The ECDSA signature of the order `_hash`, which must have been 
			signed by the order `_maker`.

		@return _ Whether or not the specified order `_hash` is authenticated as 
			valid to continue fulfilling.
	*/
	function _authenticateOrder (
		bytes32 _hash,
		address _maker,
		uint256 _nonce,
		Entities.Sig calldata _sig
	) private view returns (bool) {

		// Verify that the order has not already been canceled or fulfilled.
		if (cancelledOrFinalized[_hash]) {
			return false;
		}

		// Verify that the order was not createed with an expired nonce.
		if (_nonce < minOrderNonces[_maker]) {
			return false;
		}

		/* EOA-only authentication: ECDSA-signed by maker. */
		// Verify that the order hash was actually signed by the provided `_maker`.
		if (ecrecover(_hash, _sig.v, _sig.r, _sig.s) == _maker) {
			return true;
		}

		/*
			If the `_maker` is a smart contract, recover an EIP-1271 contract 
			signature for attempted authentication.
		*/
		if (Address.isContract(_maker)) {
			return _recoverContractSignature(_maker, _hash, _sig);
		}

		/*
			The signature is not validated against either an EOA or smart contract 
			signer and is therefore not valid.
		*/
		return false;
	}

	/**
		Execute all ERC-20 token or Ether transfers associated with an order match, 
		paid for by the message sender.

		@param _order The order whose payment is being matched.
		@param _royaltyIndex Th

		@return _ The amount of payment required for order fulfillment in ERC-20 
			token or Ether.

		@custom:throws NotEnoughValueSent if message value is insufficient to cover 
			an Ether payment.
	*/
	function _pay (
		Entities.Order memory _order,
		uint256 _royaltyIndex
	) private returns (uint256) {

		/*
			If the order being fulfilled is an offer, the message sender is the party 
			selling an item. If the order being fulfilled is a listing, the message 
			sender is the party buying an item.
		*/
		(address seller, address buyer) = _order.outline.side == Sales.Side.Buy
			? (msg.sender, _order.outline.maker)
			: (_order.outline.maker, msg.sender);

		// Calculate a total price for fulfilling the order.
		uint256 requiredAmount = Sales._calculateFinalPrice(
			_order.outline.saleKind,
			_order.outline.basePrice,
			_order.extra,
			_order.outline.listingTime
		);

		// If the amount required for order fulfillment is not zero, then transfer.
		if (requiredAmount > 0) {

			/*
				Track the amount of payment that the seller will ultimately receive 
				after fees are deducted.
			*/
			uint256 receiveAmount = requiredAmount;

			// Handle a payment in ERC-20 token.
			if (_order.outline.paymentToken != address(0)) {

				// Store the token transfer proxy in memory to save gas.
				TokenTransferProxy proxy = tokenTransferProxy;

				/*
					Store fee configuration and charge platform fees. Platform fees are 
					configured in basis points.
				*/
				uint256 config = _protocolFee;
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the platform fee. Deduct the fee from the maker's receipt.
					*/
					proxy.transferERC20(
						_order.outline.paymentToken,
						buyer,
						address(uint160(config >> 96)),
						fee
					);
					receiveAmount -= fee;
				}

				// Charge creator royalty fees based on the royalty index.
				config = royalties[_order.outline.target][_royaltyIndex];
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the royalty fee. Deduct the fee from the maker's receipt.
					*/
					proxy.transferERC20(
						_order.outline.paymentToken,
						buyer,
						address(uint160(config >> 96)),
						fee
					);
					receiveAmount -= fee;
				}

				// Transfer the remainder of the payment to the item seller.
				proxy.transferERC20(
					_order.outline.paymentToken,
					buyer,
					seller,
					receiveAmount
				);

			// Handle a payment in Ether.
			} else {
				if (msg.value < requiredAmount) {
					revert NotEnoughValueSent();
				}

				/*
					Store fee configuration and charge platform fees. Platform fees are 
					configured in basis points.
				*/
				uint256 config = _protocolFee;
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the platform fee. Deduct the fee from the maker's receipt.
					*/
					address(uint160(config >> 96)).transferEth(fee);
					receiveAmount -= fee;
				}

				// Charge creator royalty fees based on the the royalty index.
				config = royalties[_order.outline.target][_royaltyIndex];
				if (uint96(config) != 0) {
					uint256 fee = (requiredAmount * uint96(config)) / 10_000;

					/*
						Extract the fee recipient address from the fee configuration and 
						transfer the royalty fee. Deduct the fee from the maker's receipt.
					*/
					address(uint160(config >> 96)).transferEth(fee);
					receiveAmount -= fee;
				}

				// Transfer the remainder of the payment to the item seller.
				seller.transferEth(receiveAmount);
			}
		}

		// Return the required payment amount.
		return requiredAmount;
	}

	/**
		Perform the exchange of an item for an ERC-20 token or Ether in fulfilling 
		the given `_order`.

		@param _taker The address of the caller who fulfills the order.
		@param _order The `Order` to execute.
		@param _signature The signature provided for fulfilling the order, signed 
			by the order maker.
		@param _tokenId The unique token ID of the item involved in the order.

		@custom:throws InvalidOrder if the order parameters cannot be validated.
		@custom:throws CannotAuthenticateOrder if the order parameters cannot be 
			authenticated.
		@custom:throws UserProxyDoesNotExist if the targeted delegate proxy for the 
			user does not exist.
		@custom:throws UnknownUserProxyImplementation if the targeted delegate 
			proxy implementation is not as expected.
		@custom:throws CallToProxyFailed if the encoded call to the proxy fails.
	*/
	function _exchange (
		address _taker,
		Entities.Order memory _order,
		Entities.Sig calldata _signature,
		uint256 _tokenId
	) internal {

		// Retrieve the order hash.
		bytes32 hash = _hashToSign(_order);

		// Validate the order.
		if (!_validateOrderParameters(_taker, _order)) {
			revert InvalidOrder();
		}

		// Authenticate the order.
		if (
			!_authenticateOrder(
				hash,
				_order.outline.maker,
				_order.nonce,
				_signature
			)
		) { 
			revert CannotAuthenticateOrder();
		}

		// Store the registry object in memory to save gas.
		IProxyRegistry proxyRegistry = registry;

		/*
			Retrieve the delegate proxy address and implementation contract address 
			of the side of the order exchanging their item for an ERC-20 token or 
			Ether.
		*/
		(address delegateProxy, address implementation) = proxyRegistry
			.userProxyConfig(
				_order.outline.side == Sales.Side.Buy
					? msg.sender
					: _order.outline.maker
			);

		// Verify that the user's delegate proxy exists.
		if (!Address.isContract(delegateProxy)) {
			revert UserProxyDoesNotExist();
		}

		// Verify that the implementation of the user's delegate proxy is expected.
		if (
			OwnableDelegateProxy(payable(delegateProxy)).implementation() !=
			implementation
		) {
			revert UnknownUserProxyImplementation();
		}

		// Access the passthrough `AuthenticatedProxy` to make transfer calls.
		AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

		// Populate the order call data depending on the sale type.
		_order.generateCall(_taker, _tokenId);

		/*
			Perform the encoded call against the delegate proxy and verify that it 
			succeeded.
		*/
		if (
			!proxy.call(
				_order.outline.target,
				AuthenticatedProxy.CallType.Call,
				_order.data
			)
		) {
			revert CallToProxyFailed();
		}

		/*
			Fulfill order payment and refund the message sender if needed. The first 
			element of the order extra field contains the royalty index corresponding 
			to the collection royalty fee that was created at the time of order 
			signing.
		*/
		uint256 price = _pay(_order, _order.extra[0]);
		if (msg.value > price) {
			msg.sender.transferEth(msg.value - price);
		}

		// Mark the order as finalized.
		cancelledOrFinalized[hash] = true;

		// Condense order settlement status for event emission.
		bytes memory settledParameters = abi.encodePacked(
			bytes1(0xFF),
			_order.outline.saleKind,
			price,
			_order.outline.paymentToken,
			_order.outline.target,
			_order.data
		);

		// Emit an event with the results of this order.
		emit OrderResult(
			hash,
			_order.outline.maker,
			_taker,
			settledParameters
		);
	}

	/**
		A helper function to emit an `OrderResult` event while avoiding a 
		stack-depth error.

		@param _recipient The address which will receive the item.
		@param _order The `Order` to execute.
		@param _hash The hash of the order.
		@param _code Error codes for the reason of order failure.
		@param _price The price at which the order was fulfilled.
	*/
	function _emitResult (
		address _recipient,
		Entities.Order memory _order,
		bytes32 _hash,
		bytes1 _code,
		uint256 _price
	) private {
		emit OrderResult(
			_hash,
			_order.outline.maker,
			_recipient,
			abi.encodePacked(
				_code,
				_order.outline.saleKind,
				_price,
				_order.outline.paymentToken,
				_order.outline.target,
				_order.data
			)
		);
	}

	/**
		Find similiar existing payment token addresses and increases their amount.
		If payment tokens are not found, create a new payment element.

		@param _payments An array to accumulate payment elements.
		@param _paymentToken The payment token used in fulfilling the order.
		@param _recipient The order maker.
		@param _price The price of fulfilling the order.
	*/
	function _insert (
		bytes memory _payments,
		address _paymentToken,
		uint256 _recipient,
		uint256 _price
	) private pure {
		assembly {

			// Iterate through the `_payments` array in chunks of size 0x60.
			let len := div(mload(add(_payments, 0x00)), 0x60)
			let found := false
			for {
				let i := 0
			} lt(i, len) {
				i := add(i, 1)
			} {

				/*
					Load the token at this position of the array. If it is equal to the 
					payment token, check the payment destination.
				*/
				let token := mload(add(_payments, add(mul(i, 0x60), 0x20)))
				if eq(token, _paymentToken) {
					let offset := add(_payments, add(mul(i, 0x60), 0x60))

					/*
						If the payment destination is the recipient, increase the amount 
						they are already being paid.
					*/
					let to := mload(add(_payments, add(mul(i, 0x60), 0x40)))
					if eq(to, _recipient) {
						let amount := mload(offset)
						mstore(offset, add(amount, _price))
						found := true
					}
				}
			}

			// If the payment recipient was not found, insert their payment.
			if eq(found, 0) {
				switch len

				/*
					In the event of the initial insert, we've already allocated 0x20 
					bytes and only need to allocate 0x40 more to fit our three payment 
					variables.
				*/
				case 0 {
					mstore(
						add(_payments, 0x00),
						add(mload(add(_payments, 0x00)), 0x40)
					)
				}

				// Increase the size of the array by 0x60.
				default {
					mstore(
						add(_payments, 0x00),
						add(mload(add(_payments, 0x00)), 0x60)
					)
				}

				// Store the payment token, recipient, and amount.
				let offset := add(_payments, mul(len, 0x60))
				mstore(add(offset, 0x20), _paymentToken)
				mstore(add(offset, 0x40), _recipient)
				mstore(add(offset, 0x60), _price)
			}
		}
	}

	/**
		Generates a unique payment token transfer calls and adds it to the 
		`_payments` array.

		@param _payments An array to accumulate payment elements.
		@param _paymentToken The payment token used in fulfilling the order.
		@param _royaltyIndex The index of the royalty for the item collection with 
			which royalty fees should be calculated.
		@param _recipient The order maker.
		@param _price The price of fulfilling the order.
		@param _collection The item collection address.
	*/
	function _addPayment (
		bytes memory _payments,
		address _paymentToken,
		uint256 _royaltyIndex,
		uint256 _recipient,
		uint256 _price,
		address _collection
	) private view {
		uint256 finalPrice = _price;

		// Insert the protocol fee.
		uint256 config = _protocolFee;
		if (uint96(config) != 0) {
			unchecked {
				uint256 fee = (_price * uint96(config)) / 10_000;
				config = (config >> 96);
				_insert(_payments, _paymentToken, config, fee);
				finalPrice -= fee;
			}
		}

		// Insert the royalty payment.
		config = royalties[_collection][_royaltyIndex];
		if (uint96(config) != 0) {
			unchecked {
				uint256 fee = (_price * uint96(config)) / 10_000;
				config = (config >> 96);
				_insert(_payments, _paymentToken, config, fee);
				finalPrice -= fee;
			}
		}

		// Insert the final payment to the end recipient into the payment array.
		_insert(_payments, _paymentToken, _recipient, finalPrice);
	}

	/**
		Executes orders in the context of fulfilling potentially-multiple item 
		listings. This function cannot be used for fulfilling offers. This function 
		accumulates payment information in `_payments` for single-shot processing.

		@param _recipient The address which will receive the item.
		@param _order The `Order` to execute.
		@param _signature The signature provided for fulfilling the order, signed 
			by the order maker.
		@param _payments An array for accumulating payment information.
	*/
	function _exchangeUnchecked (
		address _recipient,
		Entities.Order memory _order,
		Entities.Sig calldata _signature,
		bytes memory _payments
	) internal {

		// Retrieve the order hash.
		bytes32 hash = _hashToSign(_order);
		{

			// Validate the order.
			if (!_validateOrderParameters(_recipient, _order)) {
				_emitResult(_recipient, _order, hash, 0x11, 0);
				return;
			}

			// Authenticate the order.
			if (
				!_authenticateOrder(
					hash,
					_order.outline.maker,
					_order.nonce,
					_signature
				)
			) {
				_emitResult(_recipient, _order, hash, 0x12, 0);
				return;
			}

			// Store the registry object in memory to save gas.
			IProxyRegistry proxyRegistry = registry;

			/*
				Retrieve the delegate proxy address and implementation contract address 
				of the side of the order exchanging their item for an ERC-20 token or 
				Ether.
			*/
			(address delegateProxy, address implementation) = proxyRegistry
				.userProxyConfig(_order.outline.maker);

			// Verify that the user's delegate proxy exists.
			if (!Address.isContract(delegateProxy)) {
				_emitResult(_recipient, _order, hash, 0x43, 0);
				return;
			}

			// Verify the implementation of the user's delegate proxy is expected.
			if (
				OwnableDelegateProxy(payable(delegateProxy)).implementation() !=
				implementation
			) {
				_emitResult(_recipient, _order, hash, 0x44, 0);
				return;
			}

			// Access the passthrough `AuthenticatedProxy` to make transfer calls.
			AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

			// Populate the order call data depending on the sale type.
			_order.generateCall(_recipient, 0);

			/*
				Perform the encoded call against the delegate proxy and verify that it 
				succeeded.
			*/
			if (
				!proxy.call(
					_order.outline.target,
					AuthenticatedProxy.CallType.Call,
					_order.data
				)
			) {
				_emitResult(_recipient, _order, hash, 0x50, 0);
				return;
			}
		}
		{

			// Calculate a total price for fulfilling the order.
			uint256 price = Sales._calculateFinalPrice(
				_order.outline.saleKind,
				_order.outline.basePrice,
				_order.extra,
				_order.outline.listingTime
			);

			// Add the calculated price to the payments accumulator.
			_addPayment(
				_payments,
				_order.outline.paymentToken,
				_order.extra[0],
				uint256(uint160(_order.outline.maker)),
				price,
				_order.outline.target
			);

			// Mark the order as finalized and emit the final result.
			cancelledOrFinalized[hash] = true;
			_emitResult(_recipient, _order, hash, 0xFF, price);
		}
	}

	/**
		Execute all payments from the provided `_payments` array.

		@param _payments A bytes array of accumulated payment data, populated by 
			`_exchangeUnchecked` and `_addPayment`.
		@param _buyer The caller paying to fulfill these payments.
		@param _proxy The address of a token transfer proxy.
	*/
	function _pay (
		bytes memory _payments,
		address _buyer,
		address _proxy
	) internal {
		bytes4 sig = TokenTransferProxy.transferERC20.selector;
		uint256 ethPayment;
		assembly {

			/*
				Take the `_payments` and determine the length in discrete chunks of 
				size 0x60. Iterate through each chunk.
			*/
			let len := div(mload(add(_payments, 0x00)), 0x60)
			for {
				let i := 0
			} lt(i, len) {
				i := add(i, 1)
			} {

				// Extract the token, to, and amount tuples from the array chunks.
				let token := mload(add(_payments, add(mul(i, 0x60), 0x20)))
				let to := mload(add(_payments, add(mul(i, 0x60), 0x40)))
				let amount := mload(add(_payments, add(mul(i, 0x60), 0x60)))
				
				// Switch and handle the case of sending and accumulating Ether.
				switch token
				case 0 {
					ethPayment := add(ethPayment, amount)

					/*
						Attempt to pay `amount` Ether to the `to` destination, reverting if 
						unsuccessful.
					*/
					let result := call(gas(), to, amount, 0, 0, 0, 0)
					if iszero(result) {
						revert(0, 0)
					}
				}

				// Handle the case of ERC-20 token transfers.
				default {

					// Create a pointer at position 0x40.
					let data := mload(0x40)

					/*
						Create a valid `transferERC20` payload in data. TransferERC20 takes 
						as parameters `_token`, `_from`, `_to`, and `_amount`.
					*/
					mstore(data, sig)
					mstore(add(data, 0x04), token)
					mstore(add(data, 0x24), _buyer)
					mstore(add(data, 0x44), to)
					mstore(add(data, 0x64), amount)

					/*
						Attempt to execute the ERC-20 transfer, reverting upon failure. The 
						size of the data is 0x84.
					*/
					let result := call(gas(), _proxy, 0, data, 0x84, 0, 0)
					if iszero(result) {
						revert(0, 0)
					}
				}
			}
		}

		// Refund any excess Ether to the buyer.
		if (msg.value > ethPayment) {
			_buyer.transferEth(msg.value - ethPayment);
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "../libraries/Sales.sol";
import "../proxy/AuthenticatedProxy.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Entities Library
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for managing supported order entities and helper functions.

	@custom:date December 4th, 2022.
*/
library Entities {

	/// The function selector for an ERC-1155 transfer.
	bytes4 internal constant _ERC1155_TRANSFER_SELECTOR = 0xf242432a;

	/// The function selector for an ERC-721 transfer.
	bytes4 internal constant _ERC721_TRANSFER_SELECTOR = 0x23b872dd;

	/// The EIP-712 typehash of an order outline.
	bytes32 public constant OUTLINE_TYPEHASH =
		keccak256(
			"Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
		);

	/// The EIP-712 typehash of an order.
	bytes32 public constant ORDER_TYPEHASH =
		keccak256(
			"Order(uint256 nonce,Outline outline,uint256[] extra,bytes data)Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
		);

	/**
		A struct for supporting internal Order details in order to avoidd 
		stack-depth issues.

		@param basePrice The base price of the order in `paymentToken`. This is the 
			price of fulfillment for static sale kinds. This is the starting price 
			for `DecreasingPrice` sale kinds.
		@param listingTime The listing time of the order.
		@param expirationTime The expiration time of the order.
		@param exchange The address of the exchange contract, intended as a 
			versioning mechanism if the exchange is upgraded.
		@param maker The address of the order maker.
		@param side The sale side of the deal (Buy or Sell). This is a handy flag 
			for determining which delegate proxy to use depending for participants on 
			different ends of the order.
		@param taker The order taker address if one is specified. This 
			spepcification is only honored in `DirectListing` and `DirectOffer` sale 
			kinds; in other cases we write dynamic addresses.
		@param saleKind The kind of sale to fulfill in this order.
		@param target The target of the order. This should be the address of an 
			item collection to perform a transfer on.
		@param callType The type of proxy call to perform in fulfilling this order.
		@param paymentToken The address of an ERC-20 token used to pay for the 
			order, or the zero address to fulfill payment with Ether.
	*/
	struct Outline {
		uint256 basePrice;
		uint256 listingTime;
		uint256 expirationTime;
		address exchange;
		address maker;
		Sales.Side side;
		address taker;
		Sales.SaleKind saleKind;
		address target;
		AuthenticatedProxy.CallType callType;
		address paymentToken;
	}

	/**
		A struct for managing an order on the exchange.

		@param nonce The order nonce used to prevent duplicate order hashes.
		@param outline A struct of internal order details.
		@param extra An array of extra order information. The first element of this 
			array should be the index for on-chain royalties of the collection 
			involved in the order. In the event of a `DecreasingPrice` sale kind, the 
			second element should be the targeted floor price of the listing and the 
			third element should be the time at which the floor price is reached.
		@param data The call data of the order.
	*/
	struct Order {
		uint256 nonce;
		Outline outline;
		uint256[] extra;
		bytes data;
	}

	/**
		A struct for an ECDSA signature.

		@param v The v component of the signature.
		@param r The r component of the signature.
		@param s The s component of the signature.
	*/
	struct Sig {
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	/**
		A helper function to hash the outline of an `Order`.

		@param _outline The outline of an `Order` to hash.

		@return _ A hash of the order outline.
	*/
	function _hash (
		Outline memory _outline
	) private pure returns (bytes32) {
		return keccak256(
			abi.encode(
				OUTLINE_TYPEHASH,
				_outline.basePrice,
				_outline.listingTime,
				_outline.expirationTime,
				_outline.exchange,
				_outline.maker,
				_outline.side,
				_outline.taker,
				_outline.saleKind,
				_outline.target,
				_outline.callType,
				_outline.paymentToken
			)
		);
	}

	/**
		Hash an order and return the canonical order hash without a message prefix.

		@param _order The `Order` to hash.

		@return _ The hash of `_order`.
	*/
	function hash (
		Order memory _order
	) internal pure returns (bytes32) {
		return keccak256(
			abi.encode(
				ORDER_TYPEHASH,
				_order.nonce,
				_hash(_order.outline),
				keccak256(abi.encodePacked(_order.extra)),
				keccak256(_order.data)
			)
		);
	}

	/**
		Validate the selector of the call data of the provided `Order` `_order`. 
		This prevents callers from executing arbitrary functions; only attempted 
		transfers. The transfers may still be arbitrary and malicious, however.

		@param _order The `Order` to validate the call data selector for.

		@return _ Whether or not the call has been validated.
	*/
	function validateCall (
		Order memory _order
	) internal pure returns (bool) {
		bytes memory data = _order.data;

		/*
			Retrieve the selector and verify that it matches either of the ERC-721 or 
			ERC-1155 transfer functions.
		*/
		bytes4 selector;
		assembly {
			selector := mload(add(data, 0x20))
		}
		return
			selector == _ERC1155_TRANSFER_SELECTOR ||
			selector == _ERC721_TRANSFER_SELECTOR;
	}

	/**
		Populate the call data of the provided `Order` `_order` with the `_taker` 
		address and item `_tokenId` based on the kind of sale specified in the 
		`_order`.

		This function uses assembly to directly manipulate the order data. The 
		offsets are determined based on the length of the order data array and the 
		location of the call parameter being inserted.

		In both the ERC-721 `transferFrom` function and the ERC-1155 
		`safeTransferFrom` functions, the `_from` address is the first parameter, 
		the `_to` address is the second parameter and the `_tokenId` is the third 
		parameter.

		The length of the order data is always 0x20 and the function selector is 
		0x04. Therefore the first parameter begins at 0x24. The second parameter 
		lands at 0x44, and the third parameter lands at 0x64. Depending on the sale 
		kind of the order, this function inserts any required dynamic information 
		into the order data.

		@param _order The `Order` to populate call data for based on its sale kind.
		@param _taker The address of the caller who fulfills the order.
		@param _tokenId The token ID of the item involved in the `_order`.

		@param data The order call data with the new fields inserted as needed.
	*/
	function generateCall (
		Order memory _order,
		address _taker,
		uint256 _tokenId
	) internal pure returns (bytes memory data) {

		data = _order.data;
		uint8 saleKind = uint8(_order.outline.saleKind);
		assembly {
			switch saleKind

			/*
				In a `FixedPrice` order, insert the `taker` address as the `_to` 
				parameter in the transfer call.
			*/
			case 0 {
				mstore(add(data, 0x44), _taker)
			}

			/*
				In a `DecreasingPrice` order, insert the `taker` address as the `_to` 
				parameter in the transfer call.
			*/
			case 1 {
				mstore(add(data, 0x44), _taker)
			}

			/*
				In an `Offer` order, insert the `taker` address as the `_from` 
				parameter in the transfer call.
			*/
			case 4 {
				mstore(add(data, 0x24), _taker)
			}

			/*
				In a `CollectionOffer` order, insert the `taker` address as the 
				`_from` parameter and the `_tokenId` as the `_tokenId` parameter in the 
				transfer call.
			*/
			case 5 {
				mstore(add(data, 0x24), _taker)
				mstore(add(data, 0x64), _tokenId)
			}

			/*
				In the `DirectListing` and `DirectOffer` sale kinds, all elements of 
				the order are fully specified and no generation occurs.
			*/
			default {
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	BaseFeeManager
} from "./BaseFeeManager.sol";
import {
	EIP712
} from "../libraries/EIP712.sol";

/// Thrown if attempting to set the validator address to zero.
error ValidatorAddressCannotBeZero ();

/// Thrown if the signature provided by the validator is expired.
error SignatureExpired ();

/// Thrown if the signature provided by the validator is invalid.
error BadSignature ();

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

	@custom:date December 4th, 2022.
*/
abstract contract RoyaltyManager is EIP712, BaseFeeManager {

	/// The public identifier for the right to change the validator address.
	bytes32 public constant VALIDATOR_SETTER = keccak256("VALIDATOR_SETTER");

	/// The EIP-712 typehash of a royalty update.
	bytes32 public constant ROYALTY_TYPEHASH =
		keccak256(
			"Royalty(address setter,address collection,uint256 deadline,uint256 newRoyalties)"
		);

	/// The address of the off-chain validator.
	address internal validator;

	/**
		A double mapping of collection address to index to royalty percent. This 
		allows makers to securely sign their orders safe in the knowledge that 
		royalty fees cannot be altered from beneath them.
	*/
	mapping ( address => mapping ( uint256 => uint256 )) public royalties;
	
	/// A mapping of collection addresses to the current royalty index.
	mapping ( address => uint256 ) public indices;

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
		validator = _validator;
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
		uint256 fee = royalties[_collection][indices[_collection]];

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
		validator = _validator;
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
			) != validator
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
		uint256 oldRoyalties = royalties[_collection][indices[_collection]];
		indices[_collection]++;
		royalties[_collection][indices[_collection]] = _newRoyalties;

		// Emit an event notifying about the royalty change.
		emit RoyaltyChanged(msg.sender, _collection, oldRoyalties, _newRoyalties);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// Emitted in the event that transfer of Ether fails.
error TransferFailed ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Native Ether Transfer Library
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for safely conducting Ether transfers and verifying success.

	@custom:date December 4th, 2022.
*/
library NativeTransfer {

	/**
		A helper function for wrapping a low-level Ether transfer call with modern 
		error reversion.

		@param _to The address to send Ether to.
		@param _value The value of Ether to send to `_to`.

		@custom:throws TransferFailed if the transfer of Ether fails.
	*/
	function transferEth (
		address _to,
		uint _value
	) internal {
		(bool success, ) = _to.call{ value: _value }("");
		if (!success) {
			revert TransferFailed();
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DelegateProxy.sol";

/// Thrown if the initial delgate call from this proxy is not successful.
error InitialTargetCallFailed ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Ownable Delegate Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	A call-delegating proxy with an owner. This contract was originally developed 
	by Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract OwnableDelegateProxy is Ownable, DelegateProxy {

	/// Whether or not the proxy was initialized.
	bool public initialized;

	/**
		This is a storage escape slot to match `AuthenticatedProxy` storage.
		uint8(bool) + uint184 = 192 bits. This prevents target (160 bits) from
		being placed in this storage slot.
	*/
	uint184 private _escape;

	/// The address of the proxy's current target.
	address public target;

	/**
		Construct this delegate proxy with an owner, initial target, and an initial
		call sent to the target.

		@param _owner The address which should own this proxy.
		@param _target The initial target of this proxy.
		@param _data The initial call to delegate to `_target`.

		@custom:throws InitialTargetCallFailed if the proxy initialization call 
			fails.
	*/
	constructor (
		address _owner,
		address _target,
		bytes memory _data
	) {
	
		/*
			Do not perform a redundant ownership transfer if the deployer should remain as the owner of this contract.
		*/
		if (_owner != owner()) {
			transferOwnership(_owner);
		}
		target = _target;

		/**
			Immediately delegate a call to the initial implementation and require it 
			to succeed. This is often used to trigger some kind of initialization 
			function on the target.
		*/
		(bool success, ) = _target.delegatecall(_data);
		if (!success) {
			revert InitialTargetCallFailed();
		}
	}

	/**
		Return the current address where all calls to this proxy are delegated. If
		`proxyType()` returns `1`, ERC-897 dictates that this address MUST not
		change.

		@return _ The current address where calls to this proxy are delegated.
	*/
	function implementation () public view override returns (address) {
		return target;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IProxyRegistry.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Token Transfer Proxy
	@author Project Wyvern Developers
	@author Tim Clancy <@_Enoch>
	@custom:contributor Rostislav Khlebnikov <@catpic5buck>

	A token transfer proxy contract. This contract was originally developed by 
	Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract TokenTransferProxy {
	using SafeERC20 for IERC20;

	/// The address of the immutable authentication registry.
	IProxyRegistry public immutable registry;

	/**
		Construct a new instance of this token transfer proxy given the associated 
		registry.

		@param _registry The address of a proxy registry.
	*/
	constructor (
		address _registry
	) {
		registry = IProxyRegistry(_registry);
	}

	/**
		Perform a transfer on a targeted ERC-20 token, rejecting unauthorized callers.

		@param _token The address of the ERC-20 token to transfer.
		@param _from The address to transfer ERC-20 tokens from.
		@param _to The address to transfer ERC-20 tokens to.
		@param _amount The amount of ERC-20 tokens to transfer.

		@custom:throws NonAuthorizedCaller if the caller is not authorized to 
			perform the ERC-20 token transfer.
	*/
	function transferERC20 (
		address _token,
		address _from,
		address _to,
		uint _amount
	) public {
		if (!registry.authorizedCallers(msg.sender)) {
			revert NonAuthorizedCaller();
		}
		IERC20(_token).safeTransferFrom(_from, _to, _amount);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Sales Library
	@author Project Wyvern Developers
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A library for managing supported sale types and sale helper functions.

	@custom:date December 4th, 2022.
*/
library Sales {

	/**
		An enum to track the possible sides of an order to be fulfilled.

		@param Buy A buy order is one in which an offer was made to buy an item.
		@param Sell A sell order is one in which a listing was made to sell an item.
	*/
	enum Side {
		Buy,
		Sell
	}

	/**
		An enum to track the different types of order that can be fulfilled.

		@param FixedPrice A listing of an item for sale by a seller at a static 
			price.
		@param DecreasingPrice A listing of an item for sale by a seller at a price 
			that decreases linearly each second based on extra fields specified in an 
			order.
		@param DirectListing A listing of an item for sale by a seller at a static 
			price fulfillable only by a single buyer specified by the seller.
		@param DirectOffer An offer with a static price made by a buyer for an item 
			owned by a specific seller.
		@param Offer An offer with a static price made by a buyer for an item. The 
			offer is valid no matter who the holder of the item is.
		@param CollectionOffer An offer with a static price made by a buyer for any 
			item in a collection. Any item holder in the collection may fulfill the 
			offer.
	*/
	enum SaleKind {
		FixedPrice,
		DecreasingPrice,
		DirectListing,
		DirectOffer,
		Offer,
		CollectionOffer
	}

	/**
		Return whether or not an order can be settled, verifying that the current
		block time is between order's initial listing and expiration time.

		@param _listingTime The starting time of the order being listed.
		@param _expirationTime The ending time where the order expires.
	*/
	function _canSettleOrder (
		uint _listingTime,
		uint _expirationTime
	) internal view returns (bool) {
		return
			(_listingTime < block.timestamp) &&
			(_expirationTime == 0 || block.timestamp < _expirationTime);
	}

	/**
		Calculate the final settlement price of an order.

		@param _saleKind The sale kind of an order.
		@param _basePrice The base price of the order.
		@param _extra Any extra price or time data for the order; for
			decreasing-price orders, `_extra[1]` is the floor price where price decay
			stops and `_extra[2]` is the timestamp at which the floor price is
			reached.
		@param _listingTime The listing time of the order.

		@return _ The final price of fulfilling an order.
	*/
	function _calculateFinalPrice (
		SaleKind _saleKind,
		uint _basePrice,
		uint[] memory _extra,
		uint _listingTime
	) internal view returns (uint) {

		/*
			If the sale type is a decreasing-price Dutch auction, then the price
			decreases each minute across its configured price range.
		*/
		if (_saleKind == SaleKind.DecreasingPrice) {

			/*
				If the timestamp at which price decrease concludes has been exceeded,
				the item listing price maintains its configured floor price.
			*/
			if (block.timestamp >= _extra[2]) {
				return _extra[1];
			}

			/*
				Calculate the portion of the decreasing total price that has not yet
				decayed.
			*/
			uint undecayed =

				// The total decayable portion of the price.
				(_basePrice - _extra[1]) *

				// The duration in seconds of the time remaining until total decay.
				(_extra[2] - block.timestamp) /

				/*
					The duration in seconds between the order listing time and the time
					of total decay.
				*/
				(_extra[2] - _listingTime);

			// Return the current price as the floor price plus the undecayed portion.
			return _extra[1] + undecayed;

		// In all other types of order sale, the price is entirely static.
		} else {
			return _basePrice;
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IProxyRegistry.sol";

/**
	Thrown if attempting to initialize a proxy which has already been initialized.
*/
error ProxyAlreadyInitialized ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Authenticated Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@custom:contributor Rostislav Khlebnikov <@catpic5buck>

	An ownable call-delegating proxy which can receive tokens and only make calls 
	against contracts that have been approved by a `ProxyRegistry`. This contract 
	was originally developed by Project Wyvern. It has been modified to support a 
	more modern version of Solidity with associated best practices. The 
	documentation has also been improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
contract AuthenticatedProxy is Ownable {

	/**
		An enum for selecting the method by which we would like to perform a call 
		in the `proxy` function.
	*/
	enum CallType {
		Call,
		DelegateCall
	}

	/// Whether or not this proxy is initialized. It may only initialize once.
	bool public initialized = false;

	/// The associated `ProxyRegistry` contract with authentication information.
	address public registry;

	/// Whether or not access has been revoked.
	bool public revoked;

	/**
		An event fired when the proxy contract's access is revoked or unrevoked.

		@param revoked The status of the revocation call; true if access is 
			revoked and false if access is unrevoked.
	*/
	event Revoked (
		bool revoked
	);

	/**
		Initialize this authenticated proxy for its owner against a specified
		`ProxyRegistry`. The registry controls the eligible targets.

		@param _registry The registry to create this proxy against.
	*/
	function initialize (
		address _registry
	) external {
		if (initialized) {
			revert ProxyAlreadyInitialized();
		}
		initialized = true;
		registry = _registry;
	}

	/**
		Allow the owner of this proxy to set the revocation flag. This permits them
		to revoke access from the associated `ProxyRegistry` if needed.

		@param _revoke The revocation flag to set for this proxy.
	*/
	function setRevoke (
		bool _revoke
	) external onlyOwner {
		revoked = _revoke;
		emit Revoked(_revoke);
	}

	/**
		Trigger this proxy to call a specific address with the provided data. The
		proxy may perform a direct or a delegate call. This proxy can only be called
		by the owner, or on behalf of the owner by a caller authorized by the
		registry. Unless the user has revoked access to the registry, that is.

		@param _target The target address to make the call to.
		@param _type The type of call to make: direct or delegated.
		@param _data The call data to send to `_target`.

		@return _ Whether or not the call succeeded.

		@custom:throws NonAuthorizedCaller if the proxy caller is not the owner or 
			an authorized caller from the proxy registry.
	*/
	function call (
		address _target,
		CallType _type,
		bytes calldata _data
	) public returns (bool) {
		if (
			_msgSender() != owner() &&
			(revoked || !IProxyRegistry(registry).authorizedCallers(_msgSender()))
		) {
			revert NonAuthorizedCaller();
		}

		// The call is authorized to be performed, now select a type and return.
		if (_type == CallType.Call) {
			(bool success, ) = _target.call(_data);
			return success;
		} else if (_type == CallType.DelegateCall) {
			(bool success, ) = _target.delegatecall(_data);
			return success;
		}
		return false;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// Thrown if a caller is not authorized in the proxy registry.
error NonAuthorizedCaller ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Ownable Delegate Proxy
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	A proxy registry contract. This contract was originally developed 
	by Project Wyvern. It has been modified to support a more modern version of 
	Solidity with associated best practices. The documentation has also been 
	improved to provide more clarity.

	@custom:date December 4th, 2022.
*/
interface IProxyRegistry {

	/// Return the address of tje current valid implementation of delegate proxy.
	function delegateProxyImplementation () external view returns (address);

	/**
		Returns the address of a proxy which was registered for the user address 
		before listing items.

		@param _owner The address of items lister.
	*/
	function proxies (
		address _owner
	) external view returns (address);

	/**
		Returns true if the `_caller` to the proxy registry is eligible and 
		registered.

		@param _caller The address of the caller.
	*/
	function authorizedCallers (
		address _caller
	) external view returns (bool);

	/**
		Returns the address of the `_caller`'s proxy and current implementation 
		address.

		@param _caller The address of the caller.
	*/
	function userProxyConfig (
		address _caller
	) external view returns (address, address);

	/**
		Enables an address to register its own proxy contract with this registry.

		@return _ The new contract with its implementation.
	*/
	function registerProxy () external returns (address);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	PermitControl
} from "../../access/PermitControl.sol";

/// Thrown if attempting to set the protocol fee to zero.
error ProtocolFeeRecipientCannotBeZero();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Base Fee Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing platform fee management capabilities to GigaMart.

	@custom:date December 4th, 2022.
*/
abstract contract BaseFeeManager is PermitControl {

	/// The public identifier for the right to update the fee configuration.
	bytes32 public constant FEE_CONFIG = keccak256("FEE_CONFIG");

	/**
		In protocol fee configuration the recipient address takes the left 160 bits 
		and the fee percentage takes the right 96 bits.
	*/
	uint256 internal _protocolFee;

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
			_protocolFee =
				(uint256(uint160(_protocolFeeRecipient)) << 96) +
				uint256(_protocolFeePercent);
		}
	}

	/**
		Returns current protocol fee config.
	*/
	function currentProtocolFee() public view returns (address, uint256) {
		uint256 fee = _protocolFee;
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
		uint256 oldProtocolFee = _protocolFee;
		unchecked {
			_protocolFee =
				(uint256(uint160(_newProtocolFeeRecipient)) << 96) +
				uint256(_newProtocolFeePercent);
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
pragma solidity ^0.8.15;

/// Thrown if attempting to recover a signature of invalid length.
error InvalidSignatureLength ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title EIP-712 Domain Manager
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>

	A contract for providing EIP-712 signature-services.

	@custom:date December 4th, 2022.
*/
abstract contract EIP712 {

	/**
		The typehash of the EIP-712 domain, used in dynamically deriving a domain 
		separator.
	*/
	bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(
		"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
	);

	/// A name used in the domain separator.
	string public constant name = "GigaMart";

	/// The immutable chain ID detected during construction.
	uint256 private immutable CHAIN_ID;

	/// The immutable chain ID created during construction.
	bytes32 private immutable DOMAIN_SEPARATOR;

	/**
		Construct a new EIP-712 domain instance.
	*/
	constructor () {
		uint chainId;
		assembly {
			chainId := chainid()
		}
		CHAIN_ID = chainId;
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				EIP712_DOMAIN_TYPEHASH,
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
		return chainId == CHAIN_ID
			? DOMAIN_SEPARATOR
			: keccak256(
				abi.encode(
					EIP712_DOMAIN_TYPEHASH,
					keccak256(bytes(name)),
					keccak256(bytes(version())),
					chainId,
					address(this)
				)
			);
	}

	/**
		Recover the address which signed `_hash` with signature `_signature`.

		@param _hash A hash signed by an address.
		@param _signature The signature of the hash.

		@return _ The address which signed `_hash` with signature `_signature.

		@custom:throws InvalidSignatureLength if the signature length is not valid.
	*/
	function _recover (
		bytes32 _hash,
		bytes memory _signature
	) internal pure returns (address) {

		// Validate that the signature length is as expected.
		if (_signature.length != 65) {
			revert InvalidSignatureLength();
		}

		// Divide the signature into r, s and v variables.
		bytes32 r;
		bytes32 s;
		uint8 v;
		assembly {
			r := mload(add(_signature, 0x20))
			s := mload(add(_signature, 0x40))
			v := byte(0, mload(add(_signature, 0x60)))
		}

		// Return the recovered address.
		return ecrecover(_hash, v, r, s);
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
	mapping ( address => mapping( bytes32 => mapping( bytes32 => uint256 ))) 
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

/// Thrown if the proxy's implementation is not set.
error ImplementationIsNotSet ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Delegate Proxy
	@author Facu Spagnuolo, OpenZeppelin
	@author Protinam, Project Wyvern
	@author Tim Clancy <@_Enoch>

	A basic call-delegating proxy contract which is compliant with the current 
	draft version of ERC-897. This contract was originally developed by Project 
	Wyvern. It has been modified to support a more modern version of Solidity 
	with associated best practices. The documentation has also been improved to 
	provide more clarity.

	@custom:date December 4th, 2022.
*/
abstract contract DelegateProxy {

	/**
		This payable fallback function exists to automatically delegate all calls to
		this proxy to the contract specified from `implementation()`. Anything
		returned from the delegated call will also be returned here.

		@custom:throws ImplementationIsNotSet if the contract implementation is not 
			set.
	*/
	fallback () external payable virtual {
		address target = implementation();

		// Ensure that the proxy implementation has been set correctly.
		if (target == address(0)) {
			revert ImplementationIsNotSet();
		}

		// Perform the actual call delegation.
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(ptr, 0, size)
			switch result
			case 0 {
				revert(ptr, size)
			}
			default {
				return(ptr, size)
			}
		}
	}

	/**
		Return the current address where all calls to this proxy are delegated. If
		`proxyType()` returns `1`, ERC-897 dictates that this address MUST not
		change.

		@return _ The current address where calls to this proxy are delegated.
	*/
	function implementation () public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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