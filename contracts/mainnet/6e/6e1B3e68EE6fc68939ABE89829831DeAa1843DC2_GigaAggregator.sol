// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.15;

import {
	ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
	Configuration,
	EscapeHatch,
	IERC20,
	SafeERC20
} from "./lib/Configuration.sol";
import {
	TokenTransferProxy
} from "../marketplace/proxy/TokenTransferProxy.sol";
import {
	NativeTransfer
} from "./../marketplace/libraries/NativeTransfer.sol";

/**
	Thrown if an Ether payment to the aggregator does not match the provided 
	message value.

	@param paymentAmount The payment amount to match with the message value.
	@param messageValue The message value to match.
*/
error ExpectedValueDiffers (
	uint256 paymentAmount,
	uint256 messageValue
);

/// Thrown if purchases in the aggregator are paused.
error Paused ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Aggregator
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract implements a multi-market aggregator for GigaMart.

	@custom:version 1.1
	@custom:date December 14th, 2022.
*/
contract GigaAggregator is Configuration, ReentrancyGuard {
	using SafeERC20 for IERC20;
	using NativeTransfer for address;

	/// A name used for this contract.
	string public constant name = "GigaAggregator v1.1";

	/// Track the slot for a supported exchange.
	uint256 private constant SUPPORTED_EXCHANGES_SLOT = 4;

	/**
		A convenience struct to contain information regarding total payment amounts 
		accross all orders.

		@param asset The address of a payment token.
		@param amount The amount of asset being paid.
	*/
	struct Payment {
		address asset;
		uint256 amount;
	}

	/// Store an immutable reference to a token transfer proxy.
	TokenTransferProxy public immutable TOKEN_TRANSFER_PROXY;

	/**
		Construct a new GigaMart aggregator.

		@param _exchanges An array of exchange addresses to mark as supported.
		@param _tokens An array of payment tokens to approve to `_transferProxies`.
		@param _transferProxies An array of addresses to set approval for on behalf 
			of this contract.
		@param _tokenTransferProxy The address of a token transfer proxy.
		@param _governance The address of a caller which has rights to manage 
			payment tokens.
		@param _rescuer An address that can pause or unpause the contract and 
			rescue assets.
	*/
	constructor(
		address[] memory _exchanges,
		address[] memory _tokens,
		address[] memory _transferProxies,
		TokenTransferProxy _tokenTransferProxy,
		address _governance,
		address _rescuer
	) Configuration(
		_exchanges,
		_tokens,
		_transferProxies,
		_governance,
		_rescuer
	) {
		TOKEN_TRANSFER_PROXY = _tokenTransferProxy;
	}

	/// Add a payable receive function so that the aggregator can receive Ether.
	receive () external payable { }

	/**
		Reads balances of this contract on payment assets.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.
		@param _balances An array for accumulating the balance of this contract for 
			each asset.
	*/
	function _readBalances (
		Payment[] calldata _payments,
		uint256[] memory _balances
	) private view {
		for (uint256 i; i < _payments.length; ) {

			/*
				Determine the balance of this aggregator contract in either Ether or 
				ERC-20 token, depending on the payment asset.
			*/
			_balances[i] = _payments[i].asset == address(0)
				? address(this).balance - msg.value
				: IERC20(_payments[i].asset).balanceOf(address(this));
			unchecked {
				++i;
			}
		}
	}

	/**
		This function transfers ERC-20 tokens to this aggregator contract which 
		later will be used for executing purchases from cart. The function also 
		verifies native payment.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.

		@custom:throws ExpectedValueDiffers if the message value does not match a 
			provided Ether payment amount.
	*/
	function _gatherPayments (
		Payment[] calldata _payments
	) private {
		for (uint256 i; i < _payments.length; ) {

			// Revert if there is a mismatched Ether balance.
			bool native = _payments[i].asset == address(0);
			if (native && _payments[i].amount != msg.value) {
				revert ExpectedValueDiffers(_payments[i].amount, msg.value);
			}

			// Transfer ERC-20 tokens.
			if (!native) {
				TOKEN_TRANSFER_PROXY.transferERC20(
					_payments[i].asset,
					msg.sender,
					address(this),
					_payments[i].amount
				);	
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Parse the cart and call targeted exchanges.

		@param _cart The cart to fulfill item purchase calls from.
	*/
	function _buy (
		bytes calldata _cart
	) private {

		// An offset to the start of the cart full of calls.
		uint256 offset = 0x64;
		while (offset < _cart.length) {
			assembly {

				// Retrieve the length of this call.
				let length := calldataload(add(offset, 0x20))

				// Retrieve the exchange for fulfilling purchase of this call.
				let exchange := calldataload(offset)
				
				// Store the exchange and a mapping slot into memory.
				mstore(0x00, exchange)
				mstore(0x20, SUPPORTED_EXCHANGES_SLOT)

				/*
					Hash the exchange and its storage slot, then load the resulting 
					address of the storage slot into memory. If the exchange is 
					supported, continue.
				*/
				if sload(keccak256(0x00, 0x40)) {
					
					// Load the free memory pointer.
					let ptr := mload(0x40)

					// Copy the call into memory.
					calldatacopy(ptr, add(offset, 0x60), length)

					// Pop the result of the call from the stack, ignoring it.
					pop(
						
						// Perform the call from the cart.
						call(
							gas(),
							exchange,
							calldataload(add(offset, 0x40)),
							ptr,
							length,
							0,
							0
						)
					)
				}

				// Iterate to the next call in the cart.
				offset := add(offset, add(length, 0x60))
			}
		}
	}

	/**
		Return unused payment assets back to the message sender.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.
		@param _balances An array containing the balances of payment assets in this 
			contract.
	*/
	function _returnLeftovers (
		Payment[] calldata _payments,
		uint256[] memory _balances
	) private {
		uint256 current;
		for (uint256 i; i < _balances.length; ) {
			unchecked {

				// Attempt to return Ether.
				if (_payments[i].asset == address(0)) {
					current = address(this).balance;
					if (current > _balances[i]) {
						msg.sender.transferEth(current - _balances[i]);
					}

				// Otherwise, attempt to return an ERC-20 token.
				} else {
					current = IERC20(_payments[i].asset).balanceOf(
						address(this)
					);
					if (current > _balances[i]) {
						IERC20(_payments[i].asset).safeTransfer(
							msg.sender,
							current - _balances[i]
						);
					}
				}
				++i;
			}
		}
	}

	/**
		Parse the incoming cart, verify payments status, gracefuly execute orders, 
		and return payments for failed orders.

		@param _cart A bytes array containing encoded calls to exchanges with the 
			exchange, call length, and Ether value as a prefix to each call. For 
			example:
			cart = encode(
				exchange, length, value, call,
				...
				exchange(n), length(n), value(n), call(n)
			)
			... where n is an index of a call.

		@param _payments An array containing information about token addresses and 
			the total token amounts needed to purchase all orders in the cart.

		@custom:throws Paused if purchases on the aggregator have been paused.
	*/
	function purchase (
		bytes calldata _cart,
		Payment[] calldata _payments
	) external payable nonReentrant {
		if (_status == EscapeHatch.Status.Paused) {
			revert Paused();
		}

		// Accumulate the balance of this contract for each payment asset.
		uint256[] memory balances = new uint256[](_payments.length);
		_readBalances(_payments, balances);
		
		// Gather payment assets to the aggregator.
		_gatherPayments(_payments);

		// Perform the asset purchase.
		_buy(_cart);

		// Return leftover balances.
		_returnLeftovers(_payments, balances);
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
	EscapeHatch,
	IERC20,
	SafeERC20
} from "./EscapeHatch.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title GigaMart Aggregator Configuration
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract contains configuration controls for the GigaMart aggregator.

	@custom:date December 4th, 2022.
*/
abstract contract Configuration is EscapeHatch {

	/// The identifier for the right to adjust the aggregator configuration.
	bytes32 private constant AGGREGATOR_CONFIG = keccak256("AGGREGATOR_CONFIG");

	/// A mapping to track flags for supported exchange addresses.
	mapping ( address => bool ) public supportedExchanges;

	/**
		Construct an instance of the GigaMart aggregator configuration.

		@param _exchanges An array of exchange addresses to mark as supported.
		@param _tokens An array of payment tokens to approve to `_transferProxies`.
		@param _transferProxies An array of addresses to set approval for on behalf 
			of this contract.
		@param _governance The address of a caller which has rights to manage 
			payment tokens.
		@param _rescuer An address that can pause or unpause the contract and 
			rescue assets.
	*/
	constructor (
		address[] memory _exchanges,
		address[] memory _tokens,
		address[] memory _transferProxies,
		address _governance,
		address _rescuer
	) EscapeHatch(_rescuer) {

		// Immediately flag any provided exchanges as supported.
		for (uint256 i; i < _exchanges.length; ) {
			supportedExchanges[_exchanges[i]] = true;
			unchecked {
				++i;
			}
		}

		// Approve any provided tokens for use on the exchanges.
		for (uint256 j; j < _transferProxies.length; ) {
			for (uint256 k; k < _tokens.length; ) {
				IERC20(_tokens[k]).approve(
					_transferProxies[j],
					type(uint256).max
				);
				unchecked {
					++k;
				}
			}
			unchecked {
				++j;
			}
		}

		// Set the permit of the aggregator configurator.
		setPermit(_governance, UNIVERSAL, AGGREGATOR_CONFIG, type(uint256).max);
	}

	/**
		Set approval on the given array `_tokens` of payment tokens to each 
		transfer proxy in `_transferProxies`.

		@param _tokens An array of payment tokens to approve `transferProxies` to 
			spend.
		@param _transferProxies An array of addresses to set approvals for on 
			behalf of this contract.
	*/
	function addPaymentTokens (
		address[] calldata _tokens,
		address[] calldata _transferProxies
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		for (uint256 i; i < _transferProxies.length; ) {
			for (uint256 j; j < _tokens.length; ) {

				// Approve each token on each proxy.
				IERC20(_tokens[j]).approve(
					_transferProxies[i],
					type(uint256).max
				);
				unchecked {
					++j;
				}
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Revoke approval on the given array `_tokens` of payment tokens from each 
		transfer proxy in `_transferProxies`.

		@param _tokens An array of payment tokens to revoke approval of 
			`transferProxies` to spend.
		@param _transferProxies An array of addresses to revoke approvals from on 
			behalf of this contract.
	*/
	function removePaymentTokens (
		address[] calldata _tokens,
		address[] calldata _transferProxies
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		for (uint256 i; i < _transferProxies.length; ) {
			for (uint256 j; j < _tokens.length; ) {

				// Revoke approval for each token on each proxy.
				IERC20(_tokens[j]).approve(_transferProxies[i], 0);
				unchecked {
					++j;
				}
			}
			unchecked {
				++i;
			}
		}
	}

	/**
		Include `_exchange` for order aggregation.

		@param _exchange The address of an exchange to authorize as a supported 
			target.
	*/
	function addExchange (
		address _exchange
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		supportedExchanges[_exchange] = true;
	}

	/**
		Exclude `_exchange` from order aggregation.

		@param _exchange The address of an exchange to invalidate as a supported 
			target.
	*/
	function removeExchange (
		address _exchange
	) external hasValidPermit(UNIVERSAL, AGGREGATOR_CONFIG) {
		supportedExchanges[_exchange] = false;
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

import {
	IERC721
} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
	IERC1155
} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {
	IERC20,
	SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
	PermitControl
} from "../../access/PermitControl.sol";

/**
	Thrown in the event that attempting to rescue an asset from the contract 
	fails.

	@param index The index of the asset whose rescue failed.
*/
error RescueFailed (uint256 index);

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Escape Hatch
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract contains logic for pausing contract operations during updates 
	and a backup mechanism for user assets restoration.

	@custom:date December 4th, 2022.
*/
abstract contract EscapeHatch is PermitControl {
	using SafeERC20 for IERC20;

	/// The public identifier for the right to rescue assets.
	bytes32 internal constant ASSET_RESCUER = keccak256("ASSET_RESCUER");

	/**
		An enum type representing the status of the contract being escaped.

		@param None A default value used to avoid setting storage unnecessarily.
		@param Unpaused The contract is unpaused.
		@param Paused The contract is paused.
	*/
	enum Status {
		None,
		Unpaused,
		Paused
	}

	/**
		An enum type representing the type of asset this contract may be dealing 
		with.

		@param Native The type for Ether.
		@param ERC20 The type for an ERC-20 token.
		@param ERC721 The type for an ERC-721 token.
		@param ERC1155 The type for an ERC-1155 token.
	*/
	enum AssetType {
		Native,
		ERC20,
		ERC721,
		ERC1155
	}

	/**
		A struct containing information about a particular asset transfer.

		@param assetType The type of the asset involved.
		@param asset The address of the asset.
		@param id The ID of the asset.
		@param amount The amount of asset being transferred.
		@param to The destination address where the asset is being sent.
	*/
	struct Asset {
		AssetType assetType;
		address asset;
		uint256 id;
		uint256 amount;
		address to;
	}

	/// A flag to track whether or not the contract is paused.
	Status internal _status = Status.Unpaused;

	/**
		Construct a new instance of an escape hatch, which supports pausing and the 
		rescue of trapped assets.

		@param _rescuer The address of the rescuer caller that can pause, unpause, 
			and rescue assets.
	*/
	constructor (
		address _rescuer
	) {

		// Set the permit for the rescuer.
		setPermit(_rescuer, UNIVERSAL, ASSET_RESCUER, type(uint256).max);
	}

	/// An administrative function to pause the contract.
	function pause () external hasValidPermit(UNIVERSAL, ASSET_RESCUER) {
		_status = Status.Paused;
	}

	/// An administrative function to resume the contract.
	function unpause () external hasValidPermit(UNIVERSAL, ASSET_RESCUER) {
		_status = Status.Unpaused;
	}

	/**
		An admin function used in emergency situations to transfer assets from this 
		contract if they get stuck.

		@param _assets An array of `Asset` structs to attempt transfers.

		@custom:throws RescueFailed if an Ether asset could not be rescued.
	*/
	function rescueAssets (
		Asset[] calldata _assets
	) external hasValidPermit(UNIVERSAL, ASSET_RESCUER) {
		for (uint256 i; i < _assets.length; ) {

			// If the asset is Ether, attempt a rescue; skip on reversion.
			if (_assets[i].assetType == AssetType.Native) {
				(bool result, ) = _assets[i].to.call{ value: _assets[i].amount }("");
				if (!result) {
					revert RescueFailed(i);
				}
				unchecked {
					++i;
				}
				continue;
			}

			// Attempt to rescue ERC-20 items.
			if (_assets[i].assetType == AssetType.ERC20) {
				IERC20(_assets[i].asset).safeTransfer(
					_assets[i].to,
					_assets[i].amount
				);
			}

			// Attempt to rescue ERC-721 items.
			if (_assets[i].assetType == AssetType.ERC721) {
				IERC721(_assets[i].asset).transferFrom(
					address(this),
					_assets[i].to,
					_assets[i].id
				);
			}

			// Attempt to rescue ERC-1155 items.
			if (_assets[i].assetType == AssetType.ERC1155) {
				IERC1155(_assets[i].asset).safeTransferFrom(
					address(this),
					_assets[i].to,
					_assets[i].id,
					_assets[i].amount,
					""
				);
			}
			unchecked {
				++i;
			}
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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