// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// OZ dependencies
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC165, IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// libraries and validation code constants
import { OrderTypes } from "./libraries/OrderTypes.sol";
import "./ValidationCodeConstants.sol";

// Exchange
import { BondSwapMarketplace } from "./BondsMarketplace.sol";
import { ICurrencyManager } from "./interfaces/ICurrencyManager.sol";
import { BondContractSettings } from "./libraries/BondConfig.sol";
import { IBondContract } from "./interfaces/IBondContract.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";

/**
 * @title OrderValidator
 * @notice This contract is used to check the validity of a maker order.
 *         It performs checks for:
 *         1. Nonce-related issues (e.g., nonce executed or cancelled)
 *         2. Amount-related issues (e.g. order amount being 0)
 *         3. Signature-related issues
 *         4. Whitelist-related issues (i.e., currency or strategy not whitelisted)
 *         5. Fee-related issues (e.g., minPercentageToAsk too high due to changes in royalties)
 *         6. Timestamp-related issues (e.g., order expired)
 *         7. Transfer-related issues for ERC20/ERC721 (approvals and balances)
 */
contract OrderValidator {
	using BondContractSettings for BondContractSettings.BondContractConfig;
	using OrderTypes for OrderTypes.MakerOrder;

	// Number of distinct criteria groups checked to evaluate the validity
	uint256 public constant CRITERIA_GROUPS = 7;

	// ERC721 interfaceID
	bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;

	// EIP1271 magic value
	bytes4 public constant MAGIC_VALUE_EIP1271 = 0x1626ba7e;

	// Domain separator from Exchange
	bytes32 public immutable _DOMAIN_SEPARATOR;

	// Currency Manager
	ICurrencyManager public immutable currencyManager;

	// Exchange
	BondSwapMarketplace public immutable bondswapExchange;

	/**
	 * @notice Constructor
	 * @param _bondswapExchange address of the BondSwap exchange (v1)
	 */
	constructor(address _bondswapExchange) {
		bondswapExchange = BondSwapMarketplace(_bondswapExchange);
		_DOMAIN_SEPARATOR = BondSwapMarketplace(_bondswapExchange).DOMAIN_SEPARATOR();

		currencyManager = BondSwapMarketplace(_bondswapExchange).currencyManager();
	}

	/**
	 * @notice Check the validities for an array of maker orders
	 * @param makerOrders Array of maker order structs
	 * @return validationCodes Array of validation code arrays for the maker orders
	 */
	function checkMultipleOrderValidities(
		OrderTypes.MakerOrder[] calldata makerOrders
	) public view returns (uint256[][] memory validationCodes) {
		validationCodes = new uint256[][](makerOrders.length);

		for (uint256 i; i < makerOrders.length; ) {
			validationCodes[i] = checkOrderValidity(makerOrders[i]);
			unchecked {
				++i;
			}
		}
	}

	/**
	 * @notice Check the validity of a maker order
	 * @param makerOrder Maker order struct
	 * @return validationCodes Array of validations code for each group
	 */
	function checkOrderValidity(
		OrderTypes.MakerOrder calldata makerOrder
	) public view returns (uint256[] memory validationCodes) {
		validationCodes = new uint256[](CRITERIA_GROUPS);
		validationCodes[0] = checkValidityNonces(makerOrder);
		validationCodes[1] = checkValidateBondContract(makerOrder.bondContract);
		validationCodes[2] = checkValiditySignature(makerOrder);
		validationCodes[3] = checkValidityWhitelists(makerOrder);
		validationCodes[4] = checkValidityMinPercentageToAsk(makerOrder);
		validationCodes[5] = checkValidityTimestamps(makerOrder);
		validationCodes[6] = checkValidityApprovalsAndBalances(makerOrder);
	}

	/**
	 * @notice Check the validity for user nonces
	 * @param makerOrder Maker order struct
	 * @return validationCode Validation code
	 */
	function checkValidityNonces(
		OrderTypes.MakerOrder calldata makerOrder
	) public view returns (uint256 validationCode) {
		if (bondswapExchange.isUserOrderNonceExecutedOrCancelled(makerOrder.signer, makerOrder.nonce))
			return NONCE_EXECUTED_OR_CANCELLED;
		if (makerOrder.nonce < bondswapExchange.userMinOrderNonce(makerOrder.signer))
			return NONCE_BELOW_MIN_ORDER_NONCE;
	}

	/**
	 * @notice Check the validity of a signature
	 * @param makerOrder Maker order struct
	 * @return validationCode Validation code
	 */
	function checkValiditySignature(
		OrderTypes.MakerOrder calldata makerOrder
	) public view returns (uint256 validationCode) {
		if (makerOrder.signer == address(0)) return MAKER_SIGNER_IS_NULL_SIGNER;

		bytes32 digest = keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEPARATOR, makerOrder.hash()));

		if (!Address.isContract(makerOrder.signer)) {
			return _validateEOA(digest, makerOrder.signer, makerOrder.v, makerOrder.r, makerOrder.s);
		} else {
			return _validateERC1271(digest, makerOrder.signer, makerOrder.v, makerOrder.r, makerOrder.s);
		}
	}

	/**
	 * @notice Check the validity for currency whitelists
	 * @param makerOrder Maker order struct
	 * @return validationCode Validation code
	 */
	function checkValidityWhitelists(
		OrderTypes.MakerOrder calldata makerOrder
	) public view returns (uint256 validationCode) {
		// Verify whether the currency is whitelisted
		if (!currencyManager.isCurrencyWhitelisted(makerOrder.currency)) return CURRENCY_NOT_WHITELISTED;
	}

	/**
	 * @notice Check whether a collection origin is from BondSwap
	 * @param bondContract bondContract
	 * @return (whether bondContract is valid/verified to be from BondSwap)
	 */
	function checkValidateBondContract(address bondContract) public view returns (uint256) {
		(, , , address bondToken, , , , ) = IBondContract(bondContract).settings();

		address[] memory contracts = IRegistry(bondswapExchange.bondsRegistry()).getBondContracts(bondToken);
		for (uint256 i = 0; i < contracts.length; i++) {
			if (contracts[i] == bondContract) {
				return ORDER_EXPECTED_TO_BE_VALID;
			}
		}
		return BOND_CONTRACT_INVALID_ORIGIN;
	}

	/**
	 * @notice Check the validity of min percentage to ask
	 * @param makerOrder Maker order struct
	 * @return validationCode Validation code
	 */
	function checkValidityMinPercentageToAsk(
		OrderTypes.MakerOrder calldata makerOrder
	) public view returns (uint256 validationCode) {
		// Return if order is bid since there is no protection for minPercentageToAsk
		if (!makerOrder.isOrderAsk) return ORDER_EXPECTED_TO_BE_VALID;

		uint256 minNetPriceToAsk = (makerOrder.minPercentageToAsk * makerOrder.price);

		uint256 finalSellerAmount = makerOrder.price;
		uint256 protocolFee = (makerOrder.price * bondswapExchange.protocolFee()) / 10000;
		finalSellerAmount -= protocolFee;

		if ((finalSellerAmount * 10000) < minNetPriceToAsk) return MIN_NET_RATIO_ABOVE_PROTOCOL_FEE;
	}

	/**
	 * @notice Check the validity of order timestamps
	 * @param makerOrder Maker order struct
	 * @return validationCode Validation code
	 */
	function checkValidityTimestamps(
		OrderTypes.MakerOrder calldata makerOrder
	) public view returns (uint256 validationCode) {
		if (makerOrder.startTime > block.timestamp) return TOO_EARLY_TO_EXECUTE_ORDER;
		if (makerOrder.endTime < block.timestamp) return TOO_LATE_TO_EXECUTE_ORDER;
	}

	/**
	 * @notice Check the validity of approvals and balances
	 * @param makerOrder Maker order struct
	 * @return validationCode Validation code
	 */
	function checkValidityApprovalsAndBalances(
		OrderTypes.MakerOrder calldata makerOrder
	) public view returns (uint256 validationCode) {
		if (makerOrder.isOrderAsk) {
			return _validateBondApprovals(makerOrder.bondContract, makerOrder.signer, makerOrder.tokenId);
		} else {
			return _validateERC20(makerOrder.currency, makerOrder.signer, makerOrder.price);
		}
	}

	/**
	 * @notice Check the validity of ERC20 approvals and balances that are required to process the maker bid order
	 * @param currency Currency address
	 * @param user User address
	 * @param price Price (defined by the maker order)
	 */
	function _validateERC20(
		address currency,
		address user,
		uint256 price
	) internal view returns (uint256 validationCode) {
		if (IERC20(currency).balanceOf(user) < price) return ERC20_BALANCE_INFERIOR_TO_PRICE;
		if (IERC20(currency).allowance(user, address(bondswapExchange)) < price)
			return ERC20_APPROVAL_INFERIOR_TO_PRICE;
	}

	/**
	 * @notice Check the validity of Bonds approvals and balances required to process the maker ask order
	 * @param bondContract BondContract address
	 * @param user User address
	 * @param tokenId TokenId
	 */
	function _validateBondApprovals(
		address bondContract,
		address user,
		uint256 tokenId
	) internal view returns (uint256 validationCode) {
		// 1. Verify tokenId is owned by user and catch revertion if Bond ownerOf fails
		(bool success, bytes memory data) = bondContract.staticcall(
			abi.encodeWithSelector(IERC721.ownerOf.selector, tokenId)
		);

		if (!success) return ERC721_TOKEN_ID_DOES_NOT_EXIST;
		if (abi.decode(data, (address)) != user) return ERC721_TOKEN_ID_NOT_IN_BALANCE;

		// 2. Verify if BondContract is approved by BondSwap Exchange
		(success, data) = bondContract.staticcall(
			abi.encodeWithSelector(IERC721.isApprovedForAll.selector, user, address(bondswapExchange))
		);

		bool isApprovedAll;
		if (success) {
			isApprovedAll = abi.decode(data, (bool));
		}

		if (!isApprovedAll) {
			// 3. If collection is not approved by BondSwap Exchange, try to see if it is approved individually
			(success, data) = bondContract.staticcall(abi.encodeWithSelector(IERC721.getApproved.selector, tokenId));

			address approvedAddress;
			if (success) {
				approvedAddress = abi.decode(data, (address));
			}

			if (approvedAddress != address(bondswapExchange)) return ERC721_NO_APPROVAL_FOR_ALL_OR_TOKEN_ID;
		}
	}

	/**
	 * @notice Check the validity of EOA maker order
	 * @param digest Digest
	 * @param targetSigner Expected signer address to confirm message validity
	 * @param v V parameter (27 or 28)
	 * @param r R parameter
	 * @param s S parameter
	 */
	function _validateEOA(
		bytes32 digest,
		address targetSigner,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal pure returns (uint256 validationCode) {
		if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0)
			return INVALID_S_PARAMETER_EOA;

		if (v != 27 && v != 28) return INVALID_V_PARAMETER_EOA;

		address signer = ecrecover(digest, v, r, s);
		if (signer == address(0)) return NULL_SIGNER_EOA;
		if (signer != targetSigner) return WRONG_SIGNER_EOA;
	}

	/**
	 * @notice Check the validity for EIP1271 maker order
	 * @param digest Digest
	 * @param targetSigner Expected signer address to confirm message validity
	 * @param v V parameter (27 or 28)
	 * @param r R parameter
	 * @param s S parameter
	 */
	function _validateERC1271(
		bytes32 digest,
		address targetSigner,
		uint8 v,
		bytes32 r,
		bytes32 s
	) internal view returns (uint256 validationCode) {
		(bool success, bytes memory data) = targetSigner.staticcall(
			abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, abi.encodePacked(r, s, v))
		);

		if (!success) return MISSING_IS_VALID_SIGNATURE_FUNCTION_EIP1271;
		bytes4 magicValue = abi.decode(data, (bytes4));

		if (magicValue != MAGIC_VALUE_EIP1271) return SIGNATURE_INVALID_EIP1271;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: UNLICENSED
// Created by BondSwap https://bondswap.org

pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ICurrencyManager } from "./interfaces/ICurrencyManager.sol";
import { IBondswapExchange } from "./interfaces/IBondSwapExchange.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { IBondContract } from "./interfaces/IBondContract.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";

import { OrderTypes } from "./libraries/OrderTypes.sol";
import { BondContractSettings } from "./libraries/BondConfig.sol";

import { SignatureChecker } from "./libraries/SignatureChecker.sol";

contract BondSwapMarketplace is IBondswapExchange, ReentrancyGuard, Ownable {
	using SafeERC20 for IERC20;

	using OrderTypes for OrderTypes.MakerOrder;
	using OrderTypes for OrderTypes.TakerOrder;
	using BondContractSettings for BondContractSettings.BondContractConfig;

	address public immutable WETH;
	bytes32 public immutable DOMAIN_SEPARATOR;

	uint256 public protocolFee;
	address public protocolFeeRecipient;
	ICurrencyManager public currencyManager;
	IRegistry public bondsRegistry;

	mapping(address => uint256) public userMinOrderNonce;
	mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;

	event CancelAllOrders(address indexed user, uint256 newMinNonce);
	event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
	event NewCurrencyManager(address indexed currencyManager);
	event NewBondsRegistry(address indexed bondsRegistry);
	event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
	event NewProtocolFee(uint256 newFee);

	event TakerAsk(
		bytes32 orderHash, // bid hash of the maker order
		uint256 orderNonce, // user order nonce
		address indexed taker, // sender address for the taker ask order
		address indexed maker, // maker address of the initial bid order
		address currency, // currency address
		address bondContract, // bondContract address
		uint256 tokenId, // tokenId transferred
		uint256 price // final transacted price
	);

	event TakerBid(
		bytes32 orderHash, // ask hash of the maker order
		uint256 orderNonce, // user order nonce
		address indexed taker, // sender address for the taker bid order
		address indexed maker, // maker address of the initial ask order
		address currency, // currency address
		address bondContract, // bondContract address
		uint256 tokenId, // tokenId transferred
		uint256 price // final transacted price
	);

	/**
	 * @notice Constructor
	 * @param _currencyManager currency manager address
	 * @param _WETH wrapped ether address (for other chains, use wrapped native asset)
	 * @param _protocolFeeRecipient protocol fee recipient
	 * @param _protocolFee protocol fee
	 */
	constructor(
		address _currencyManager,
		address _bondsRegistry,
		address _WETH,
		address _protocolFeeRecipient,
		uint256 _protocolFee
	) {
		// Calculate the domain separator
		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
				0xe13814be1494ac697820045213a238b3656a84d59ef31122c42a65695b0b16a0, // keccak256("BondSwapExchange")
				0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
				block.chainid,
				address(this)
			)
		);

		currencyManager = ICurrencyManager(_currencyManager);
		bondsRegistry = IRegistry(_bondsRegistry);
		WETH = _WETH;
		protocolFeeRecipient = _protocolFeeRecipient;
		protocolFee = _protocolFee;
	}

	/**
	 * @notice Cancel all pending orders for a sender
	 * @param minNonce minimum user nonce
	 */
	function cancelAllOrdersForSender(uint256 minNonce) external {
		require(minNonce > userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
		require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cancel: Cannot cancel more orders");
		userMinOrderNonce[msg.sender] = minNonce;

		emit CancelAllOrders(msg.sender, minNonce);
	}

	/**
	 * @notice Cancel maker orders
	 * @param orderNonces array of order nonces
	 */
	function cancelMultipleMakerOrders(uint256[] calldata orderNonces) external {
		require(orderNonces.length > 0, "Cancel: Cannot be empty");

		for (uint256 i = 0; i < orderNonces.length; i++) {
			require(orderNonces[i] >= userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
			_isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
		}

		emit CancelMultipleOrders(msg.sender, orderNonces);
	}

	/**
	 * @notice Match ask with a taker bid order using ETH
	 * @param takerBid taker bid order
	 * @param makerAsk maker ask order
	 */
	function matchAskWithTakerBidUsingETHAndWETH(
		OrderTypes.TakerOrder calldata takerBid,
		OrderTypes.MakerOrder calldata makerAsk
	) external payable override nonReentrant {
		require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
		require(makerAsk.currency == WETH, "Order: Currency must be WETH");
		require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

		// If not enough ETH to cover the price, use WETH
		if (takerBid.price > msg.value) {
			IERC20(WETH).safeTransferFrom(msg.sender, address(this), (takerBid.price - msg.value));
		} else {
			require(takerBid.price == msg.value, "Order: Msg.value too high");
		}

		// Verify whether bond have enough reward tokens left
		require(
			isAboveMinRequiredRewardToken(makerAsk.bondContract, takerBid.tokenId, takerBid.minRewardToken),
			"BondContract: Not enough tokens left"
		);

		// Wrap ETH sent to this contract
		IWETH(WETH).deposit{ value: msg.value }();

		// Check the maker ask order
		bytes32 askHash = makerAsk.hash();
		_validateOrder(makerAsk, askHash);

		// Retrieve execution parameters
		(bool isExecutionValid, uint256 tokenId) = canExecuteTakerBid(takerBid, makerAsk);

		require(isExecutionValid, "Order: Execution invalid");

		// Update maker ask order status to true (prevents replay)
		_isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

		_transferFeesAndFundsWithWETH(makerAsk.signer, takerBid.price, makerAsk.minPercentageToAsk);

		IERC721(makerAsk.bondContract).safeTransferFrom(makerAsk.signer, takerBid.taker, tokenId);

		emit TakerBid(
			askHash,
			makerAsk.nonce,
			takerBid.taker,
			makerAsk.signer,
			makerAsk.currency,
			makerAsk.bondContract,
			tokenId,
			takerBid.price
		);
	}

	/**
	 * @notice Match a takerBid with a matchAsk
	 * @param takerBid taker bid order
	 * @param makerAsk maker ask order
	 */
	function matchAskWithTakerBid(
		OrderTypes.TakerOrder calldata takerBid,
		OrderTypes.MakerOrder calldata makerAsk
	) external override nonReentrant {
		require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
		require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

		// Verify whether bond have enough reward tokens left
		require(
			isAboveMinRequiredRewardToken(makerAsk.bondContract, takerBid.tokenId, takerBid.minRewardToken),
			"BondContract: Not enough tokens left"
		);

		// Check the maker ask order
		bytes32 askHash = makerAsk.hash();
		_validateOrder(makerAsk, askHash);

		(bool isExecutionValid, uint256 tokenId) = canExecuteTakerBid(takerBid, makerAsk);

		require(isExecutionValid, "Order: Execution invalid");

		// Update maker ask order status to true (prevents replay)
		_isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

		_transferFeesAndFunds(
			makerAsk.currency,
			msg.sender,
			makerAsk.signer,
			takerBid.price,
			makerAsk.minPercentageToAsk
		);

		IERC721(makerAsk.bondContract).safeTransferFrom(makerAsk.signer, takerBid.taker, tokenId);

		emit TakerBid(
			askHash,
			makerAsk.nonce,
			takerBid.taker,
			makerAsk.signer,
			makerAsk.currency,
			makerAsk.bondContract,
			tokenId,
			takerBid.price
		);
	}

	/**
	 * @notice Match a takerAsk with a makerBid
	 * @param takerAsk taker ask order
	 * @param makerBid maker bid order
	 */
	function matchBidWithTakerAsk(
		OrderTypes.TakerOrder calldata takerAsk,
		OrderTypes.MakerOrder calldata makerBid
	) external override nonReentrant {
		require((!makerBid.isOrderAsk) && (takerAsk.isOrderAsk), "Order: Wrong sides");
		require(msg.sender == takerAsk.taker, "Order: Taker must be the sender");

		// Verify whether bond have enough reward tokens left
		require(
			isAboveMinRequiredRewardToken(makerBid.bondContract, makerBid.tokenId, makerBid.minRewardToken),
			"BondContract: Not enough tokens left"
		);

		// Check the maker bid order
		bytes32 bidHash = makerBid.hash();
		_validateOrder(makerBid, bidHash);

		(bool isExecutionValid, uint256 tokenId) = canExecuteTakerAsk(takerAsk, makerBid);

		require(isExecutionValid, "Order: Execution invalid");

		// Update maker bid order status to true (prevents replay)
		_isUserOrderNonceExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

		IERC721(makerBid.bondContract).safeTransferFrom(msg.sender, makerBid.signer, tokenId);

		_transferFeesAndFunds(
			makerBid.currency,
			makerBid.signer,
			takerAsk.taker,
			takerAsk.price,
			takerAsk.minPercentageToAsk
		);

		emit TakerAsk(
			bidHash,
			makerBid.nonce,
			takerAsk.taker,
			makerBid.signer,
			makerBid.currency,
			makerBid.bondContract,
			tokenId,
			takerAsk.price
		);
	}

	/**
	 * @notice Update currency manager
	 * @param _currencyManager new currency manager address
	 */
	function updateCurrencyManager(address _currencyManager) external onlyOwner {
		require(_currencyManager != address(0), "Owner: Cannot be null address");
		currencyManager = ICurrencyManager(_currencyManager);
		emit NewCurrencyManager(_currencyManager);
	}

	/**
	 * @notice Update bonds registry
	 * @param _bondsRegistry new bonds registry address
	 */
	function updateBondsRegistry(address _bondsRegistry) external onlyOwner {
		require(_bondsRegistry != address(0), "Owner: Cannot be null address");
		bondsRegistry = IRegistry(_bondsRegistry);
		emit NewBondsRegistry(_bondsRegistry);
	}

	/**
	 * @notice Update protocol fee and recipient
	 * @param _protocolFeeRecipient new recipient for protocol fees
	 */
	function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
		protocolFeeRecipient = _protocolFeeRecipient;
		emit NewProtocolFeeRecipient(_protocolFeeRecipient);
	}

	/**
	 * @notice Update protocol fee
	 * @param _protocolFee new protocol fee
	 */
	function updateProtocolFee(uint256 _protocolFee) external onlyOwner {
		protocolFee = _protocolFee;
		emit NewProtocolFee(_protocolFee);
	}

	/**
	 * @notice Check whether user order nonce is executed or cancelled
	 * @param user address of user
	 * @param orderNonce nonce of the order
	 */
	function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
		return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
	}

	/**
	 * @notice Transfer fees and funds to protocol, and seller
	 * @param currency currency being used for the purchase (e.g., WETH/USDC)
	 * @param from sender of the funds
	 * @param to seller's recipient
	 * @param amount amount being transferred (in currency)
	 * @param minPercentageToAsk minimum percentage of the gross amount that goes to ask
	 */
	function _transferFeesAndFunds(
		address currency,
		address from,
		address to,
		uint256 amount,
		uint256 minPercentageToAsk
	) internal {
		// Initialize the final amount that is transferred to seller
		uint256 finalSellerAmount = amount;

		// 1. Protocol fee
		{
			uint256 protocolFeeAmount = _calculateProtocolFee(amount);

			// Check if the protocol fee is different than 0 for this strategy
			if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
				IERC20(currency).safeTransferFrom(from, protocolFeeRecipient, protocolFeeAmount);
				finalSellerAmount -= protocolFeeAmount;
			}
		}

		require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "Fees: Higher than expected");

		// 3. Transfer final amount (post-fees) to seller
		{
			IERC20(currency).safeTransferFrom(from, to, finalSellerAmount);
		}
	}

	/**
	 * @notice Transfer fees and funds to protocol, and seller
	 * @param to seller's recipient
	 * @param amount amount being transferred (in currency)
	 * @param minPercentageToAsk minimum percentage of the gross amount that goes to ask
	 */
	function _transferFeesAndFundsWithWETH(address to, uint256 amount, uint256 minPercentageToAsk) internal {
		// Initialize the final amount that is transferred to seller
		uint256 finalSellerAmount = amount;

		// 1. Protocol fee
		{
			uint256 protocolFeeAmount = _calculateProtocolFee(amount);

			// Check if the protocol fee is different than 0 for this strategy
			if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
				IERC20(WETH).safeTransfer(protocolFeeRecipient, protocolFeeAmount);
				finalSellerAmount -= protocolFeeAmount;
			}
		}

		require((finalSellerAmount * 10000) >= (minPercentageToAsk * amount), "Fees: Higher than expected");

		// 3. Transfer final amount (post-fees) to seller
		{
			IERC20(WETH).safeTransfer(to, finalSellerAmount);
		}
	}

	/**
	 * @notice Calculate protocol fee
	 * @param amount amount to transfer
	 */
	function _calculateProtocolFee(uint256 amount) internal view returns (uint256) {
		return (protocolFee * amount) / 10000;
	}

	/**
	 * @notice Verify the validity of the maker order
	 * @param makerOrder maker order
	 * @param orderHash computed hash for the order
	 */
	function _validateOrder(OrderTypes.MakerOrder calldata makerOrder, bytes32 orderHash) internal view {
		// Verify whether order nonce has expired
		require(
			(!_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.nonce]) &&
				(makerOrder.nonce >= userMinOrderNonce[makerOrder.signer]),
			"Order: Matching order expired"
		);

		// Verify the signer is not address(0)
		require(makerOrder.signer != address(0), "Order: Invalid signer");

		// Verify the validity of the signature
		require(
			SignatureChecker.verify(
				orderHash,
				makerOrder.signer,
				makerOrder.v,
				makerOrder.r,
				makerOrder.s,
				DOMAIN_SEPARATOR
			),
			"Signature: Invalid"
		);

		// Verify whether the currency is whitelisted
		require(currencyManager.isCurrencyWhitelisted(makerOrder.currency), "Currency: Not whitelisted");

		// Verify whether bond contract was created by BondSwap
		require(validateBondContract(makerOrder.bondContract), "BondContract: Not listed");
	}

	/**
	 * @notice Check whether a taker ask order can be executed against a maker bid
	 * @param takerAsk taker ask order
	 * @param makerBid maker bid order
	 * @return (whether can be executed, tokenId to execute, amount of tokens to execute)
	 */
	function canExecuteTakerAsk(
		OrderTypes.TakerOrder calldata takerAsk,
		OrderTypes.MakerOrder calldata makerBid
	) internal view returns (bool, uint256) {
		return (
			((makerBid.price == takerAsk.price) &&
				(makerBid.tokenId == takerAsk.tokenId) &&
				(makerBid.startTime <= block.timestamp) &&
				(makerBid.endTime >= block.timestamp)),
			makerBid.tokenId
		);
	}

	/**
	 * @notice Check whether a collection origin is from BondSwap
	 * @param bondContract bondContract
	 * @return (whether bondContract is valid/verified to be from BondSwap)
	 */

	function validateBondContract(address bondContract) internal view returns (bool) {
		(, , , address bondToken, , , , ) = IBondContract(bondContract).settings();

		address[] memory contracts = bondsRegistry.getBondContracts(bondToken);
		for (uint256 i = 0; i < contracts.length; i++) {
			if (contracts[i] == bondContract) {
				return true;
			}
		}
		return false;
	}

	/**
	 * @notice Check if there is enough reward token left in the bond
	 * @param bondContract bondContract
	 * @param bondID token ID (bond ID)
	 * @param minReward minimum reward tokens
	 * @return (whether enough of reward tokens left)
	 */

	function isAboveMinRequiredRewardToken(
		address bondContract,
		uint256 bondID,
		uint256 minReward
	) internal view returns (bool) {
		BondContractSettings.Bond memory bond = IBondContract(bondContract).bonds(bondID);

		return bond.left >= minReward;
	}

	/**
	 * @notice Check whether a taker bid order can be executed against a maker ask
	 * @param takerBid taker bid order
	 * @param makerAsk maker ask order
	 * @return (whether can be executed, tokenId to execute)
	 */
	function canExecuteTakerBid(
		OrderTypes.TakerOrder calldata takerBid,
		OrderTypes.MakerOrder calldata makerAsk
	) internal view returns (bool, uint256) {
		return (
			((makerAsk.price == takerBid.price) &&
				(makerAsk.tokenId == takerBid.tokenId) &&
				(makerAsk.startTime <= block.timestamp) &&
				(makerAsk.endTime >= block.timestamp)),
			makerAsk.tokenId
		);
	}
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

import { BondContractSettings } from "../libraries/BondConfig.sol";

interface IBondContract {
	function settings()
		external
		view
		returns (string memory, uint256, address, address, uint8, uint256, address, uint256);

	function bonds(uint256 bondID) external view returns (BondContractSettings.Bond memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IBondswapExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external;

    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrencyManager {
    function addCurrency(address currency) external;

    function removeCurrency(address currency) external;

    function isCurrencyWhitelisted(address currency)
        external
        view
        returns (bool);

    function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256);

    function viewCountWhitelistedCurrencies() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.15;

interface IRegistry {
    function getBondContracts(
        address _token
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library BondContractSettings {
	struct BondContractConfig {
		string uri;
		uint256 protocolFee; // 5 digit representation,  5000 = 50%, 700 = 7%, 50 = 0.5% etc
		address protocolFeeAddress; // protocol fee address
		address bondToken; // token that we buy bonds for
		uint8 bondTokenDecimals; // decimals for this token
		uint256 bondContractVersion; // implementation contract version
		address bondCreator; // address that created bonds/have permission to create new bond classes
		uint256 bondSymbolNumber; // used in ERC721 bond symbol
	}

	struct Bond {
		uint256 bondTermsID; // bond ID
		uint256 payout; //  all tokens to be paid (this value is NOT updated when claimed)
		uint256 left; // how many tokes left to be claimed
		uint256 vestingEnd; // vest ending timestamp
		uint256 lastClaimed; // last claim timestamp
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the BondSwap exchange.
 */
library OrderTypes {
	// keccak256("MakerOrder(bool isOrderAsk,address signer,address bondContract,uint256 price,uint256 tokenId,address currency,uint256 nonce,uint256 startTime,uint256 endTime,uint256 minPercentageToAsk,uint256 minRewardToken,bytes params)")
	bytes32 internal constant MAKER_ORDER_HASH = 0xb2b62835b49da011c2344b046129b628de40af51cb4c4fbd62eb9394783c8edb;

	struct MakerOrder {
		bool isOrderAsk; // true --> ask / false --> bid
		address signer; // signer of the maker order
		address bondContract; // bond contract address
		uint256 price; // price (used as )
		uint256 tokenId; // id of the token
		address currency; // currency (e.g., WETH)
		uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
		uint256 startTime; // startTime in timestamp
		uint256 endTime; // endTime in timestamp
		uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
		uint256 minRewardToken; // protection against bond claim front running
		bytes params; // additional parameters
		uint8 v; // v: parameter (27 or 28)
		bytes32 r; // r: parameter
		bytes32 s; // s: parameter
	}

	struct TakerOrder {
		bool isOrderAsk; // true --> ask / false --> bid
		address taker; // msg.sender
		uint256 price; // final price for the purchase
		uint256 tokenId;
		uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
		uint256 minRewardToken; // protection against bond claim front running
		bytes params; // other params (e.g., tokenId)
	}

	function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encode(
					MAKER_ORDER_HASH,
					makerOrder.isOrderAsk,
					makerOrder.signer,
					makerOrder.bondContract,
					makerOrder.price,
					makerOrder.tokenId,
					makerOrder.currency,
					makerOrder.nonce,
					makerOrder.startTime,
					makerOrder.endTime,
					makerOrder.minPercentageToAsk,
					makerOrder.minRewardToken,
					keccak256(makerOrder.params)
				)
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
    /**
     * @notice Recovers the signer of a signature (for EOA)
     * @param hash the hash containing the signed mesage
     * @param v parameter (27 or 28). This prevents maleability since the public key recovery equation has two possible solutions.
     * @param r parameter
     * @param s parameter
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Signature: Invalid s parameter"
        );

        require(v == 27 || v == 28, "Signature: Invalid v parameter");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed mesage
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @param domainSeparator paramer to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
            return
                IERC1271(signer).isValidSignature(
                    digest,
                    abi.encodePacked(r, s, v)
                ) == 0x1626ba7e;
        } else {
            return recover(digest, v, r, s) == signer;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

uint256 constant ORDER_EXPECTED_TO_BE_VALID = 0;
uint256 constant NONCE_EXECUTED_OR_CANCELLED = 101;
uint256 constant NONCE_BELOW_MIN_ORDER_NONCE = 102;
uint256 constant MAKER_SIGNER_IS_NULL_SIGNER = 301;
uint256 constant INVALID_S_PARAMETER_EOA = 302;
uint256 constant INVALID_V_PARAMETER_EOA = 303;
uint256 constant NULL_SIGNER_EOA = 304;
uint256 constant WRONG_SIGNER_EOA = 305;
uint256 constant SIGNATURE_INVALID_EIP1271 = 311;
uint256 constant MISSING_IS_VALID_SIGNATURE_FUNCTION_EIP1271 = 312;
uint256 constant CURRENCY_NOT_WHITELISTED = 401;
uint256 constant MIN_NET_RATIO_ABOVE_PROTOCOL_FEE = 501;
uint256 constant TOO_EARLY_TO_EXECUTE_ORDER = 601;
uint256 constant TOO_LATE_TO_EXECUTE_ORDER = 602;
uint256 constant ERC20_BALANCE_INFERIOR_TO_PRICE = 711;
uint256 constant ERC20_APPROVAL_INFERIOR_TO_PRICE = 712;
uint256 constant ERC721_TOKEN_ID_DOES_NOT_EXIST = 721;
uint256 constant ERC721_TOKEN_ID_NOT_IN_BALANCE = 722;
uint256 constant ERC721_NO_APPROVAL_FOR_ALL_OR_TOKEN_ID = 723;
uint256 constant BOND_CONTRACT_INVALID_ORIGIN = 801;