// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./order/OrderConsideration.sol";

/**
 * @title Granite
 * @notice Granite is a generalized ERC20-ERC721 trading platform. It
 *         provides method for executing ERC721 order using ERC20 tokens.
 */
contract Granite is OrderConsideration {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "../order/interfaces/IOrderConsideration.sol";
import "../order/lib/OrderFulfiller.sol";

/**
 * @title OrderConsideration
 * @custom:version 1.0
 * @notice OrderConsideration is the main contract of the platform. It
 *         provides method for executing ERC721 order using ERC20 tokens
 *         and supporting functions to get additional data.
 */
contract OrderConsideration is IOrderConsideration, OrderFulfiller {
    /**
     * @notice Fulfill an order offering an ERC721 item by
     *         ERC20 tokens. For an order to be eligible for
     *         fulfillment via this method, all fields of order
     *         struct must be validated.
     *
     * @param order Order struct that contains all necessary data to fulfill the order.
     *              Note that the offerer and the fulfiller must first approve
     *              this contract before any tokens can be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(Order calldata order)
        external
        returns (bool fulfilled)
    {
        // Validate and fulfill the basic order, and then return the result.
        return _validateAndFulfillOrder(order);
    }

    /**
     * @notice Retrieve EIP712 domain separator hash for this contract.
     *
     * @return domainHash The domain separator hash for this contract.
     */
    function getDomainSeparator() external view returns (bytes32 domainHash) {
        //Return EIP712 domain separator hash for this contract.
        return DOMAIN_SEPARATOR;
    }

    /**
     * @notice Retrieve the order hash for a given order parameters.
     *
     * @param orderParameters The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(BasicOrderParameters calldata orderParameters)
        external
        pure
        returns (bytes32 orderHash)
    {
        //Return the order hash for a given order parameters.
        return _hash(orderParameters);
    }

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash.
     *
     * @return orderStatus A struct indicating order status. It contains such fields:
     *                     isValidated - a boolean indicating whether the order in
     *                     has been validated. isCancelled - a boolean indicating whether
     *                     the order has been cancelled. isFulfilled - a boolean indicating
     *                     whether the order has been fulfilled.
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (OrderStatus memory orderStatus)
    {
        // Return the order status using the order hash.
        return _getOrderStatus(orderHash);
    }

    /**
     * @notice Retrieve an address of service that gets royaltie for each order execution.
     *
     * @return addr An address of service.
     */
    function getServiceAddress() external view returns (address addr) {
        //Return service address.
        return _getServiceAddress();
    }

    /**
     * @notice Set new address of service that gets royaltie for each order execution.
     *         Only owner of this contract is able to call this function.
     *
     * @param newServiceAddress New address for service.
     */
    function setServiceAddress(address newServiceAddress) external onlyOwner {
        //Set new address for service.
        _setServiceAddress(newServiceAddress);
    }

    /**
     * @notice Retrieve the percentage of order's ERC20 amount
     *         that service gets after order execution as royaltie.
     *
     * @return percentage Percentage amount.
     */
    function getServiceFeePercentage()
        external
        view
        returns (uint8 percentage)
    {
        // Get service fee percentage.
        return _getServiceFeePercentage();
    }

    /**
     * @notice Set new percentage that service will get from order execution.
     *         Only owner of this contract is able to call this function.
     *
     * @param newFeePercentage New fee percentage.
     */
    function setServiceFeePercentage(uint8 newFeePercentage)
        external
        onlyOwner
    {
        // Set new service fee percentage.
        _setServiceFeePercentage(newFeePercentage);
    }

    /**
     * @notice Calculate royalties amount of given amount.
     *
     * @param amount Given amount that is used to calculate royalties amount.
     *
     * @return royaltiesAmount Calculated royalties.
     */
    function calculateRoyalties(uint amount)
        external
        view
        returns (uint royaltiesAmount)
    {
        // Return calculated amount of royalties.
        return _calculateRoyalties(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./OrderBase.sol";
import "./OrderValidator.sol";
import "./TransferExecutor.sol";

/**
 * @title BasicOrderFulfiller
 * @notice BasicOrderFulfiller contains functionality for fulfilling "basic"
 *         orders.
 */
contract OrderFulfiller is TransferExecutor, OrderValidator {
    /**
     * @dev Internal function to fulfill and validate an order offering an ERC721 item by
     *      ERC20 tokens. For an order to be eligible for
     *      fulfillment via this method, all fields of order
     *      struct must be validated.
     *
     * @param order Order struct that contains all necessary data to fulfill the order.
     *              Note that the offerer and the fulfiller must first approve
     *              this contract before any tokens can be transferred.
     *
     * @return  A boolean indicating whether the order has been
     *          successfully fulfilled.
     */
    function _validateAndFulfillOrder(Order calldata order)
        internal
        nonReentrant
        returns (bool)
    {
        bool orderIsFulfilled;

        BasicOrderParameters calldata orderArgs = order.basicOrderParameters;
        ConsiderationItem calldata consideration = orderArgs.considerationItem;
        OfferItem calldata offer = orderArgs.offerItem;

        _verifyTime(
            orderArgs.orderStartTime,
            orderArgs.orderEndTime,
            orderArgs.offerTime
        );

        _verifyOrderSellerAndRecipient(
            consideration.recipient,
            orderArgs.seller
        );

        _verifyZeroAddress(
            consideration.considerationToken,
            "Consideration Token"
        );
        _verifyZeroAddress(offer.offerToken, "Offerer Token");

        bytes32 orderHash = _hash(orderArgs);

        _validateOrderAndUpdateStatus(
            orderHash,
            offer.offerer,
            order.signature
        );

        if (orderArgs.orderType == OrderType.ERC721_TO_ERC20) {
            _validateAndTransferERC721(
                consideration.considerationToken,
                msg.sender,
                offer.offerer,
                consideration.considerationIdentifier,
                consideration.considerationAmount
            );

            _validateAndTransferERC20(
                offer.offerToken,
                offer.offerer,
                msg.sender,
                offer.offerAmount
            );
        } else {
            revert InvalidOrderType();
        }

        emit OrderFulfilled(
            orderHash,
            order.signature,
            orderArgs.seller,
            offer.offerer,
            consideration.considerationToken,
            consideration.considerationIdentifier,
            offer.offerToken,
            offer.offerAmount
        );
        return orderIsFulfilled;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/OrderStructs.sol";

/**
 * @title IOrderConsideration
 * @custom:version 1.0
 * @notice OrderConsideration is the main contract of the platform. It
 *         provides method for executing ERC721 order using ERC20 tokens
 *         and supporting functions to get additional data.
 *
 * @dev OrderConsideration Interface contains all external function interfaces for
 *      Consideration.
 */
interface IOrderConsideration {
    /**
     * @notice Fulfill an order offering an ERC721 item by
     *         ERC20 tokens. For an order to be eligible for
     *         fulfillment via this method, all fields of order
     *         struct must be validated.
     *
     * @param order Order struct that contains all necessary data to fulfill the order.
     *              Note that the offerer and the fulfiller must first approve
     *              this contract before any tokens can be transferred.
     *
     * @return fulfilled A boolean indicating whether the order has been
     *                   successfully fulfilled.
     */
    function fulfillBasicOrder(Order calldata order)
        external
        returns (bool fulfilled);

    /**
     * @notice Retrieve EIP712 domain separator hash for this contract.
     *
     * @return domainHash The domain separator hash for this contract.
     */
    function getDomainSeparator() external view returns (bytes32 domainHash);

    /**
     * @notice Retrieve the order hash for a given order parameters.
     *
     * @param orderParameters The components of the order.
     *
     * @return orderHash The order hash.
     */
    function getOrderHash(BasicOrderParameters calldata orderParameters)
        external
        pure
        returns (bytes32);

    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash.
     *
     * @return orderStatus A struct indicating order status. It contains such fields:
     *                     isValidated - a boolean indicating whether the order in
     *                     has been validated. isCancelled - a boolean indicating whether
     *                     the order has been cancelled. isFulfilled - a boolean indicating
     *                     whether the order has been fulfilled.
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (OrderStatus memory orderStatus);

    /**
     * @notice Retrieve an address of service that gets royaltie for each order execution.
     *
     * @return addr An address of service.
     */
    function getServiceAddress() external view returns (address addr);

    /**
     * @notice Set new address of service that gets royaltie for each order execution.
     *         Only owner of this contract is able to call this function.
     *
     * @param newServiceAddress New address for service.
     */
    function setServiceAddress(address newServiceAddress) external;

    /**
     * @notice Retrieve the percentage of order's ERC20 amount
     *         that service gets after order execution as royaltie.
     *
     * @return percentage Percentage amount.
     */
    function getServiceFeePercentage() external view returns (uint8 percentage);

    /**
     * @notice Set new percentage that service will get from order execution.
     *         Only owner of this contract is able to call this function.
     *
     * @param newFeePercentage New fee percentage.
     */
    function setServiceFeePercentage(uint8 newFeePercentage) external;

    /**
     * @notice Calculate royalties amount of given amount.
     *
     * @param amount Given amount that is used to calculate royalties amount.
     *
     * @return royaltiesAmount Calculated royalties.
     */
    function calculateRoyalties(uint amount)
        external
        view
        returns (uint royaltiesAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./TransferValidator.sol";
import "./TransferRoyalties.sol";
import "../../helpers/TokenTransferrer.sol";

/**
 * @title TransferExecutor
 * @notice TransferExecutor contains functions related to processing and validationg
 *         transfer executions (i.e. transferring items such as ERC721 tokens and ERC20).
 */
contract TransferExecutor is
    TokenTransferrer,
    TransferRoyalties,
    TransferValidator
{
    /**
     * @dev Internal function to validate and perform transfer of a single ERC721
     *      token from a given originator to a given recipient. Sufficient approvals
     *      must be set on this contract itself.
     *
     * @param token  The ERC721 token to transfer.
     * @param from   The originator of the transfer.
     * @param to     The recipient of the transfer.
     * @param id     The tokenId to transfer.
     * @param amount The "amount" (this value must be equal to one).
     */
    function _validateAndTransferERC721(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) internal {
        _validateERC721Amount(amount);
        _validateAddress(token);

        _performERC721Transfer(token, from, to, id);
    }

    /**
     * @dev Internal function to validate and perform transfer of ERC20
     *      tokens from a given originator to a given recipient. Sufficient approvals
     *      must be set on this contract itself.
     *
     * @param token  The ERC20 token to transfer.
     * @param from   The originator of the transfer.
     * @param to     The recipient of the transfer.
     * @param amount The amount to transfer.
     */
    function _validateAndTransferERC20(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint royaltiesAmount = _calculateRoyalties(amount);

        _validateERC20Amount(amount, royaltiesAmount);
        _validateAddress(token);

        //send royalties
        _performERC20Transfer(
            token,
            from,
            _getServiceAddress(),
            royaltiesAmount
        );

        uint amountToMainRecipient = amount - royaltiesAmount;
        //send amount to the seller
        _performERC20Transfer(token, from, to, amountToMainRecipient);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Verifiers.sol";

/**
 * @title OrderValidator
 * @notice OrderValidator contains functionality related to validating order
 *         and updating its status.
 */
contract OrderValidator is Verifiers {
    // Track status of each order (validated, cancelled, and  fulfilled).
    mapping(bytes32 => OrderStatus) internal _orderStatuses;

    /**
     * @dev Internal function to verify and update the status of a basic order.
     *
     * @param orderHash The hash of the order.
     * @param offerer   The offerer/buyer of the order.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _validateOrderAndUpdateStatus(
        bytes32 orderHash,
        address offerer,
        bytes calldata signature
    ) internal {
        OrderStatus storage orderStatus = _orderStatuses[orderHash];

        _verifyOrderStatus(_orderStatuses[orderHash]);

        if (!orderStatus.isValidated)
            _verifySignature(orderHash, offerer, signature);

        orderStatus.isValidated = true;
        orderStatus.isCancelled = false;
        orderStatus.isFulfilled = true;

        emit OrderValidated(orderHash, msg.sender, offerer);
    }

    /**
     * @dev Internal view function to retrieve order status by its hash.
     *
     * @param orderHash The hash of the order.
     *
     * @return Order status struct.
     */
    function _getOrderStatus(bytes32 orderHash)
        internal
        view
        returns (OrderStatus memory)
    {
        return _orderStatuses[orderHash];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../../constants/Constants.sol";
import "../structs/OrderStructs.sol";
import "../interfaces/OrderEventsAndErrors.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OrderBase
 * @notice OrderBase contains all storage, constants, and constructor
 *         logic.
 */
contract OrderBase is EIP712, ReentrancyGuard, Ownable, OrderEventsAndErrors {
    // Declare constants of derived required EIP712 typehashes.
    bytes32 internal constant CONSIDERATION_ITEM_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "ConsiderationItem(",
                "address recipient,",
                "address considerationToken,",
                "uint256 considerationIdentifier,",
                "uint256 considerationAmount",
                ")"
            )
        );

    bytes32 internal constant OFFER_ITEM_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "OfferItem(",
                "address offerer,",
                "address offerToken,",
                "uint256 offerIdentifier,",
                "uint256 offerAmount",
                ")"
            )
        );

    bytes32 internal constant BASICORDER_PARAMETERS_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "BasicOrderParameters(",
                "address seller,",
                "ConsiderationItem considerationItem,",
                "OfferItem offerItem,",
                "uint8 orderType,",
                "uint256 orderStartTime,",
                "uint256 orderEndTime,",
                "uint256 offerTime,",
                "uint256 salt",
                ")",
                "ConsiderationItem(",
                "address recipient,",
                "address considerationToken,",
                "uint256 considerationIdentifier,",
                "uint256 considerationAmount",
                ")",
                "OfferItem(",
                "address offerer,",
                "address offerToken,",
                "uint256 offerIdentifier,",
                "uint256 offerAmount",
                ")"
            )
        );

    // Precompute domain separator and address of this contract on deployment.
    bytes32 internal immutable DOMAIN_SEPARATOR;
    address internal immutable THIS_ADDRESS;

    /**
     * @dev Derive and set domain separator hash and contract address.
     */
    constructor() EIP712(EIP712_NAME, EIP712_VERSION) {
        DOMAIN_SEPARATOR = _domainSeparatorV4();
        THIS_ADDRESS = address(this);
    }

    /**
     * @dev Internal pure overloaded function to calculate the hash of the consideration item.
     *
     * @param considerationItem Consideration item.
     *
     * @return The consideration item hash.
     */
    function _hash(ConsiderationItem calldata considerationItem)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    CONSIDERATION_ITEM_TYPEHASH,
                    considerationItem.recipient,
                    considerationItem.considerationToken,
                    considerationItem.considerationIdentifier,
                    considerationItem.considerationAmount
                )
            );
    }

    /**
     * @dev Internal pure overloaded function to calculate the hash of the offer item.
     *
     * @param offerItem Offer item.
     *
     * @return The offer item hash.
     */
    function _hash(OfferItem calldata offerItem)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    OFFER_ITEM_TYPEHASH,
                    offerItem.offerer,
                    offerItem.offerToken,
                    offerItem.offerIdentifier,
                    offerItem.offerAmount
                )
            );
    }

    /**
     * @dev Internal pure overloaded function to calculate the hash of the order components.
     *
     * @param order Order components.
     *
     * @return The order item hash.
     */
    function _hash(BasicOrderParameters calldata order)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    BASICORDER_PARAMETERS_TYPEHASH,
                    order.seller,
                    _hash(order.considerationItem),
                    _hash(order.offerItem),
                    order.orderType,
                    order.orderStartTime,
                    order.orderEndTime,
                    order.offerTime,
                    order.salt
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TokenTransferrer
 * @notice TokenTransferrer contains functions for directly transferring tokens.
 *         This contract has been moved outside of the order folder because it isn't
 *         attached to the order itself and all functions can be called by other contracts
 *         that don't relate to the order.
 */
contract TokenTransferrer {
    /**
     * @dev Internal function to transfer a single ERC721
     *      token from a given originator to a given recipient. Sufficient approvals
     *      must be set on this contract itself.
     *
     * @param token  The ERC721 token to transfer.
     * @param from   The originator of the transfer.
     * @param to     The recipient of the transfer.
     * @param id     The tokenId to transfer.
     */
    function _performERC721Transfer(
        address token,
        address from,
        address to,
        uint256 id
    ) internal {
        IERC721(token).transferFrom(from, to, id);
    }

    /**
     * @dev Internal function to transfer ERC20
     *      tokens from a given originator to a given recipient. Sufficient approvals
     *      must be set on this contract itself.
     *
     * @param token  The ERC20 token to transfer.
     * @param from   The originator of the transfer.
     * @param to     The recipient of the transfer.
     * @param amount The amount to transfer.
     */
    function _performERC20Transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(token).transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../interfaces/TransferEventsAndErrors.sol";
import "../structs/OrderStructs.sol";

/**
 * @title TransferValidator
 * @notice TransferValidator contains functions for validation transfer parameters.
 */
contract TransferValidator is TransferEventsAndErrors {
    /**
     * @dev Internal pure function to validate ERC721 amount.
     *      This value must be equal to one.
     *
     * @param amount The "amount" (this value must be equal to one).
     */
    function _validateERC721Amount(uint256 amount) internal pure {
        if (amount != 1) {
            revert InvalidERC721TransferAmount(amount);
        }
    }

    /**
     * @dev Internal pure function to validate ERC20 amount. The full amount
     *      of transferring, tokens must be greater than the royalties that
     *      the service gets as commission.
     *
     * @param amount          The amount.
     * @param royaltiesAmount The royalties amount.
     */
    function _validateERC20Amount(uint256 amount, uint256 royaltiesAmount)
        internal
        pure
    {
        if (amount <= royaltiesAmount) {
            revert InvalidERC20TransferAmount(amount);
        }
    }

    /**
     * @dev Internal view function to validate that transferring tokens
     *      contain code inside. If not, it is impossible to call a transfer.
     *
     * @param token The address of the token.
     */
    function _validateAddress(address token) internal view {
        if (token.code.length == 0) {
            revert NoContract(token);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title TransferRoyalties
 * @notice TransferRoyalties contains functions to operate with royalties logic.
 */
contract TransferRoyalties {
    // Service address that gets royalties after each order execution.
    address private SERVICE_ADDRESS;
    // Percentage of the order amount that service takes after each order execution.
    uint8 private SERVICE_FEE_PERCENTAGE;

    /**
     * @dev Set service address and service fee percentage.
     */
    constructor() {
        SERVICE_ADDRESS = address(this);
        SERVICE_FEE_PERCENTAGE = 2;
    }

    /**
     * @notice Internal view function to retrieve an address of
     *         service that gets royaltie for each order execution.
     *
     * @return An address of service.
     */
    function _getServiceAddress() internal view returns (address) {
        return SERVICE_ADDRESS;
    }

    /**
     * @notice Internal view function to retrieve the percentage of order's
     *         ERC20 amount that service gets after order execution as royaltie.
     *
     * @return Percentage amount.
     */
    function _getServiceFeePercentage() internal view returns (uint8) {
        return SERVICE_FEE_PERCENTAGE;
    }

    /**
     * @notice Internal function to set new address of service that gets royaltie for
     *         each order execution. Only owner of this contract is able to call this function.
     *
     * @param newServiceAddress New address for service.
     */
    function _setServiceAddress(address newServiceAddress) internal {
        SERVICE_ADDRESS = newServiceAddress;
    }

    /**
     * @notice Internal function to s et new percentage that service will get from
     *         order execution. Only owner of this contract is able to call this function.
     *
     * @param newFeePercentage New fee percentage.
     */
    function _setServiceFeePercentage(uint8 newFeePercentage) internal {
        SERVICE_FEE_PERCENTAGE = newFeePercentage;
    }

    /**
     * @notice Internal view function to calculate royalties amount of given amount.
     *
     * @param amount Given amount that is used to calculate royalties amount.
     *
     * @return Calculated royalties.
     */
    function _calculateRoyalties(uint256 amount)
        internal
        view
        returns (uint256)
    {
        return (amount * SERVICE_FEE_PERCENTAGE) / 100;
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
pragma solidity ^0.8.17;

import "../enums/OrderEnums.sol";

/**
 * @dev Full order structure.
 */
struct Order {
    BasicOrderParameters basicOrderParameters;
    bytes signature;
}

/**
 * @dev The full set of basic order components. OrderType is enum
 *      where 0 means ERC721 <=> ERC20. Salt is random number to
 *      make each order unique. Other fields are clear or described
 *      below.
 */

struct BasicOrderParameters {
    address seller;
    ConsiderationItem considerationItem;
    OfferItem offerItem;
    OrderType orderType;
    uint256 orderStartTime;
    uint256 orderEndTime;
    uint256 offerTime;
    uint256 salt;
}

/**
 * @dev An item that has to be sold (i.e. ERC721). Recipient: address that
 *      will get a token after execution. ConsiderationToken: token address
 *      that will be sold. ConsiderationIdentifier: token unique id.
 *      ConsiderationAmount: tokens amount.
 */
struct ConsiderationItem {
    address payable recipient;
    address considerationToken;
    uint256 considerationIdentifier;
    uint256 considerationAmount;
}

/**
 * @dev Tokens that are offered for consideration item (i.e. ERC20).
 *      Offerer: address that will send tokens to the seller.
 *      OfferToken: token address that is offered.
 *      OfferIdentifier: token unique id (For ERC-20 it must be 0).
 *      OfferAmount: tokens amount.
 */
struct OfferItem {
    address payable offerer;
    address offerToken;
    uint256 offerIdentifier;
    uint256 offerAmount;
}

/**
 * @dev Order status struct. Orders can be validated, specifically
 *      cancelled, and fulfilled
 */
struct OrderStatus {
    bool isValidated;
    bool isCancelled;
    bool isFulfilled;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title TransferEventsAndErrors
 * @notice TransferEventsAndErrors contains all events and errors.
 */
interface TransferEventsAndErrors {
    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      ERC721 token amount.
     *
     * @param amount ERC721 token amount.
     */
    error InvalidERC721TransferAmount(uint amount);

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      ERC20 token amount.
     *
     * @param amount ERC20 token amount.
     */
    error InvalidERC20TransferAmount(uint amount);

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      transferring tokens without code.
     *
     * @param account Token address.
     */
    error NoContract(address account);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,
    // 1: ERC20 items
    ERC20,
    // 2: ERC721 items
    ERC721,
    // 3: ERC1155 items
    ERC1155
}

enum OrderType {
    // 0: provide ERC721 item to receive offered ERC20 item
    ERC721_TO_ERC20
    // 1: provide ERC1155 item to receive offered ERC20 item
    //ERC1155_TO_ERC20
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./OrderBase.sol";

/**
 * @title Verifiers
 * @notice Verifiers contains functions for performing verifications.
 */
contract Verifiers is OrderBase {
    /**
     * @dev Internal view function to verify the signature of an order.
     *
     * @param signer    The signer/buyer for the order.
     * @param orderHash The order hash.
     * @param signature A signature from the offerer indicating that the order
     *                  has been approved.
     */
    function _verifySignature(
        bytes32 orderHash,
        address signer,
        bytes calldata signature
    ) internal view {
        bytes32 digest = _hashTypedDataV4(orderHash);

        if (ECDSA.recover(digest, signature) != signer)
            revert InvalidOrderSignature();
    }

    /**
     * @dev Internal view function to ensure that the current time falls within
     *      an order's valid timespan.
     *
     * @param orderStartTime The time at which the order becomes active.
     * @param orderEndTime   The time at which the order becomes inactive.
     * @param offerTime      The time at which buyer made an offer.
     */
    function _verifyTime(
        uint256 orderStartTime,
        uint256 orderEndTime,
        uint256 offerTime
    ) internal view {
        if (orderStartTime >= orderEndTime || orderStartTime > block.timestamp)
            revert InvalidOrderTime();

        if (offerTime < orderStartTime || offerTime > orderEndTime)
            revert InvalidOfferTime();
    }

    /**
     * @dev Internal pure function to validate that an order status is fillable
     *      and not cancelled.
     *
     * @param orderStatus The status of the order, including whether it has
     *                    been cancelled and fulfilled.
     */
    function _verifyOrderStatus(OrderStatus memory orderStatus) internal pure {
        if (orderStatus.isFulfilled) revert OrderIsAlreadyFulfilled();
        else if (orderStatus.isCancelled) revert OrderIsCancelled();
    }

    /**
     * @dev Internal view function to validate that the seller and recipient are valid
     *      and satisfied all conditions.
     *
     * @param mainRecipient The recipient who will get ERC721 token.
     * @param seller        The seller who sells ERC721 token.
     *
     */
    function _verifyOrderSellerAndRecipient(
        address mainRecipient,
        address seller
    ) internal view {
        _verifyZeroAddress(mainRecipient, "Main recipient");
        _verifyZeroAddress(seller, "Seller");

        if (mainRecipient == seller)
            revert InvalidRecipient(
                "The recipient must differ from the seller"
            );

        if (seller != msg.sender)
            revert InvalidRecipient(
                "The seller must be the same as the msg.sender"
            );
    }

    /**
     * @dev Internal view function to check whether the address
     *      is zero address or no.
     *
     * @param addr        The address that will be checked.
     * @param addressName The address name that will be shown in the
     *                    description if an error is thrown.
     *
     */
    function _verifyZeroAddress(address addr, string memory addressName)
        internal
        pure
    {
        if (addr == address(0)) revert ZeroAddress(addressName);
    }

    /**
     * @dev Internal pure function to check that token amount
     *      is greater than zero.
     *
     * @param tokenAmount Token amount.
     */
    function _verifyTokenAmounts(uint256 tokenAmount) internal pure {
        if (tokenAmount <= 0) revert InvalidTokenAmount();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// Constants for EIP712 domain separator.
string constant EIP712_NAME = "Granite";
string constant EIP712_VERSION = "1";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title OrderEventsAndErrors
 * @notice OrderEventsAndErrors contains all events and errors.
 */
interface OrderEventsAndErrors {
    /**
     * @dev Emit an event whenever an order is successfully fulfilled.
     *
     * @param orderHash           The hash of the fulfilled order.
     * @param orderSignature      The signature of the fulfilled order.
     * @param seller              The sseller of the fulfilled order.
     * @param buyer               The buyer of the fulfilled order.
     * @param ERC721Token         The buyer received ERC721 token address.
     * @param ERC721Id            ERC721 token id.
     * @param ERC20Token          The seller received ERC20 token address.
     * @param ERC20ReceivedAmount The seller received amount of the ERC20 token.
     */
    event OrderFulfilled(
        bytes32 orderHash,
        bytes orderSignature,
        address indexed seller,
        address indexed buyer,
        address ERC721Token,
        uint ERC721Id,
        address ERC20Token,
        uint ERC20ReceivedAmount
    );

    /**
     * @dev Emit an event whenever an order is validated.
     *
     * @param orderHash The hash of the validated order.
     * @param seller    The seller address of the validated order.
     * @param buyer     The buyer address of the validated order.
     */
    event OrderValidated(
        bytes32 orderHash,
        address indexed seller,
        address indexed buyer
    );

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      invalid signature.
     */
    error InvalidOrderSignature();

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      already been fully filled.
     */
    error OrderIsAlreadyFulfilled();

    /**
     * @dev Revert with an error when attempting to fill an order that has been
     *      expired.
     */
    error OrderIsExpired();

    /**
     * @dev Revert with an error when attempting to fill an order that has been
     *      cancelled.
     */
    error OrderIsCancelled();

    /**
     * @dev Revert with an error when attempting to fill an order
     *      with incorrect order start time and order end time.
     */
    error InvalidOrderTime();

    /**
     * @dev Revert with an error when attempting to fill an order where
     *      offer time is outside the specified start time and end time.
     */
    error InvalidOfferTime();

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      at least one zero address.
     *
     * @param msg Address name that has zero address.
     */
    error ZeroAddress(string msg);

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      an invalid recipient.
     *
     * @param msg Message that describes why recipient is invalid.
     */
    error InvalidRecipient(string msg);

    /**
     * @dev Revert with an error when attempting to fill an order that has
     *      an amount less or equal to zero.
     */
    error InvalidTokenAmount();

    /**
     * @dev Revert with an error when attempting to fill an order with
     *      an invalid order type. Check order types in enum folder.
     */
    error InvalidOrderType();
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}