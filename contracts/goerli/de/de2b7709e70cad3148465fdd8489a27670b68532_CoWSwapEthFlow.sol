// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "./libraries/EthFlowOrder.sol";
import "./interfaces/ICoWSwapSettlement.sol";
import "./interfaces/ICoWSwapEthFlow.sol";
import "./interfaces/IWrappedNativeToken.sol";
import "./mixins/CoWSwapOnchainOrders.sol";
import "./vendored/GPv2EIP1271.sol";

/// @title CoW Swap ETH Flow
/// @author CoW Swap Developers
contract CoWSwapEthFlow is
    CoWSwapOnchainOrders,
    EIP1271Verifier,
    ICoWSwapEthFlow
{
    using EthFlowOrder for EthFlowOrder.Data;
    using GPv2Order for GPv2Order.Data;
    using GPv2Order for bytes;

    /// @dev The address of the CoW Swap settlement contract that will be used to settle orders created by this
    /// contract.
    ICoWSwapSettlement public immutable cowSwapSettlement;

    /// @dev The address of the contract representing the default native token in the current chain (e.g., WETH for
    /// Ethereum mainnet).
    IWrappedNativeToken public immutable wrappedNativeToken;

    /// @dev Each ETH flow order as described in [`EthFlowOrder.Data`] can be converted to a CoW Swap order. Distinct
    /// CoW Swap orders have non-colliding order hashes. This mapping associates some extra data to a specific CoW Swap
    /// order. This data is stored onchain and is used to verify the ownership and validity of an ETH flow order.
    /// An ETH flow order can be settled onchain only if converting it to a CoW Swap order and hashing yields valid
    /// onchain data.
    mapping(bytes32 => EthFlowOrder.OnchainData) public orders;

    /// @param _cowSwapSettlement The CoW Swap settlement contract.
    /// @param _wrappedNativeToken The default native token in the current chain (e.g., WETH on mainnet).
    constructor(
        ICoWSwapSettlement _cowSwapSettlement,
        IWrappedNativeToken _wrappedNativeToken
    ) CoWSwapOnchainOrders(address(_cowSwapSettlement)) {
        cowSwapSettlement = _cowSwapSettlement;
        wrappedNativeToken = _wrappedNativeToken;

        _wrappedNativeToken.approve(
            cowSwapSettlement.vaultRelayer(),
            type(uint256).max
        );
    }

    // The contract needs to be able to receive native tokens when unwrapping.
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @inheritdoc ICoWSwapEthFlow
    function wrapAll() external {
        wrap(address(this).balance);
    }

    /// @inheritdoc ICoWSwapEthFlow
    function wrap(uint256 amount) public {
        // The fallback implementation of the standard WETH9 contract just calls `deposit`. Using the fallback instead
        // of directly calling `deposit` is slightly cheaper in terms of gas.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(address(wrappedNativeToken)).call{
            value: amount
        }("");
        // The success value is intentionally disregarded. The callback of the standard WETH9 contract has no revert
        // path in the code, so it could only revert if the internal call runs out of gas. This is not considered a
        // security risk since a reverting internal call would just mean that calling this function has no effect.
        success;
    }

    /// @inheritdoc ICoWSwapEthFlow
    function unwrap(uint256 amount) external {
        wrappedNativeToken.withdraw(amount);
    }

    /// @inheritdoc ICoWSwapEthFlow
    function createOrder(EthFlowOrder.Data calldata order)
        external
        payable
        returns (bytes32 orderHash)
    {
        if (msg.value != order.sellAmount + order.feeAmount) {
            revert IncorrectEthAmount();
        }

        if (0 == order.sellAmount) {
            revert NotAllowedZeroSellAmount();
        }

        // solhint-disable-next-line not-rely-on-time
        if (order.validTo < block.timestamp) {
            revert OrderIsAlreadyExpired();
        }

        EthFlowOrder.OnchainData memory onchainData = EthFlowOrder.OnchainData(
            msg.sender,
            order.validTo
        );

        OnchainSignature memory signature = OnchainSignature(
            OnchainSigningScheme.Eip1271,
            abi.encodePacked(address(this))
        );

        // The data event field includes extra information needed to settle orders with the CoW Swap API.
        bytes memory data = abi.encodePacked(
            order.quoteId,
            onchainData.validTo
        );

        orderHash = broadcastOrder(
            onchainData.owner,
            order.toCoWSwapOrder(wrappedNativeToken),
            signature,
            data
        );

        if (orders[orderHash].owner != EthFlowOrder.NO_OWNER) {
            revert OrderIsAlreadyOwned(orderHash);
        }

        orders[orderHash] = onchainData;
    }

    /// @inheritdoc ICoWSwapEthFlow
    function invalidateOrdersIgnoringNotAllowed(
        EthFlowOrder.Data[] calldata orderArray
    ) external {
        for (uint256 i = 0; i < orderArray.length; i++) {
            _invalidateOrder(orderArray[i], false);
        }
    }

    /// @inheritdoc ICoWSwapEthFlow
    function invalidateOrder(EthFlowOrder.Data calldata order) public {
        _invalidateOrder(order, true);
    }

    /// @dev Performs the same tasks as `invalidateOrder` (see documentation in `ICoWSwapEthFlow`), but also allows the
    /// caller to ignore the revert condition `NotAllowedToInvalidateOrder`. Instead of reverting, it stops execution
    /// without causing any state change.
    ///
    /// @param order order to be invalidated.
    /// @param revertOnInvalidDeletion controls whether the function call should revert or just return.
    function _invalidateOrder(
        EthFlowOrder.Data calldata order,
        bool revertOnInvalidDeletion
    ) internal {
        GPv2Order.Data memory cowSwapOrder = order.toCoWSwapOrder(
            wrappedNativeToken
        );
        bytes32 orderHash = cowSwapOrder.hash(cowSwapDomainSeparator);

        EthFlowOrder.OnchainData memory orderData = orders[orderHash];

        // solhint-disable-next-line not-rely-on-time
        bool isTradable = orderData.validTo >= block.timestamp;
        if (
            orderData.owner == EthFlowOrder.INVALIDATED_OWNER ||
            orderData.owner == EthFlowOrder.NO_OWNER ||
            (isTradable && orderData.owner != msg.sender)
        ) {
            if (revertOnInvalidDeletion) {
                revert NotAllowedToInvalidateOrder(orderHash);
            } else {
                return;
            }
        }

        orders[orderHash].owner = EthFlowOrder.INVALIDATED_OWNER;

        bytes memory orderUid = new bytes(GPv2Order.UID_LENGTH);
        orderUid.packOrderUidParams(
            orderHash,
            address(this),
            cowSwapOrder.validTo
        );

        // solhint-disable-next-line not-rely-on-time
        if (isTradable) {
            // Order is valid but its owner decided to invalidate it.
            emit OrderInvalidation(orderUid);
        } else {
            // The order cannot be traded anymore, so this transaction is likely triggered to get back the ETH. We are
            // interested in knowing who is the source of the refund.
            emit OrderRefund(orderUid, msg.sender);
        }

        uint256 filledAmount = cowSwapSettlement.filledAmount(orderUid);

        // This comment argues that a CoW Swap trader does not pay more fees if a partially fillable order is
        // (partially) settled in multiple batches rather than in one single batch of the combined size.
        // This also means that we can refund the user assuming the worst case of settling the filled amount in a single
        // batch without risking giving out more funds than available in the contract because of rounding issues.
        // A CoW Swap trader is always charged exactly the amount of fees that is proportional to the filled amount
        // rounded down to the smaller integer. The code is here:
        // https://github.com/cowprotocol/contracts/blob/d4e0fcd58367907bf1aff54d182222eeaee793dd/src/contracts/GPv2Settlement.sol#L385-L387
        // We show that a trader pays less in fee to CoW Swap when settiling a partially fillable order in two
        // executions rather than a single one for the combined amount; by induction this proves our original statement.
        // Our previous statement is equivalent to `floor(a/c) + floor(b/c) ≤ floor((a+b)/c)`. Writing a and b in terms
        // of reminders (`a = ad*c+ar`, `b = bd*c+br`) the equation becomes `ad + bd ≤ ad + bd + floor((ar+br)/c)`,
        // which is immediately true.
        uint256 refundAmount;
        unchecked {
            // - Multiplication overflow: since this smart contract never invalidates orders on CoW Swap,
            //   `filledAmount <= sellAmount`. Also, `feeAmount + sellAmount` is an amount of native tokens that was
            //   originally sent by the user. As such, it cannot be larger than the amount of native tokens available,
            //   which is smaller than 2¹²⁸/10¹⁸ ≈ 10²⁰ in all networks supported by CoW Swap so far. Since both values
            //    are smaller than 2¹²⁸, their product does not overflow a uint256.
            // - Subtraction underflow: again `filledAmount ≤ sellAmount`, meaning:
            //   feeAmount * filledAmount / sellAmount ≤ feeAmount
            uint256 feeRefundAmount = cowSwapOrder.feeAmount -
                ((cowSwapOrder.feeAmount * filledAmount) /
                    cowSwapOrder.sellAmount);

            // - Subtraction underflow: as noted before, filledAmount ≤ sellAmount.
            // - Addition overflow: as noted before, the user already sent feeAmount + sellAmount native tokens, which
            //   did not overflow.
            refundAmount =
                cowSwapOrder.sellAmount -
                filledAmount +
                feeRefundAmount;
        }

        // If not enough native token is available in the contract, unwrap the needed amount.
        if (address(this).balance < refundAmount) {
            uint256 withdrawAmount;
            unchecked {
                withdrawAmount = refundAmount - address(this).balance;
            }
            wrappedNativeToken.withdraw(withdrawAmount);
        }

        // Using low level calls to perform the transfer avoids setting arbitrary limits to the amount of gas used in a
        // call. Reentrancy is avoided thanks to the `nonReentrant` function modifier.
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(orderData.owner).call{value: refundAmount}(
            ""
        );
        if (!success) {
            revert EthTransferFailed();
        }
    }

    /// @inheritdoc ICoWSwapEthFlow
    function isValidSignature(bytes32 orderHash, bytes memory)
        external
        view
        override(EIP1271Verifier, ICoWSwapEthFlow)
        returns (bytes4)
    {
        // Note: the signature parameter is ignored since all information needed to verify the validity of the order is
        // already available onchain.
        EthFlowOrder.OnchainData memory orderData = orders[orderHash];
        if (
            (orderData.owner != EthFlowOrder.NO_OWNER) &&
            (orderData.owner != EthFlowOrder.INVALIDATED_OWNER) &&
            // solhint-disable-next-line not-rely-on-time
            (orderData.validTo >= block.timestamp)
        ) {
            return GPv2EIP1271.MAGICVALUE;
        } else {
            return bytes4(type(uint32).max);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../libraries/EthFlowOrder.sol";

/// @title CoW Swap ETH Flow Event Interface
/// @author CoW Swap Developers
interface ICoWSwapEthFlowEvents {
    /// @dev Event emitted to notify that an order was refunded. Note that this event is not fired every time the order
    /// is invalidated (even though the user receives all unspent ETH back). This is because we want to differenciate
    /// the case where the user invalidates a valid order and when the user receives back the funds from an expired
    /// order.
    ///
    /// @param orderUid CoW Swap's unique order identifier of the order that has been invalidated (and refunded).
    /// @param refunder The address that triggered the order refund.
    event OrderRefund(bytes orderUid, address indexed refunder);
}

/// @title CoW Swap ETH Flow Interface
/// @author CoW Swap Developers
interface ICoWSwapEthFlow is ICoWSwapEthFlowEvents {
    /// @dev Error thrown when trying to create a new order whose order hash is the same as an order hash that was
    /// already assigned.
    error OrderIsAlreadyOwned(bytes32 orderHash);

    /// @dev Error thrown when trying to create an order that would be expired at the time of creation
    error OrderIsAlreadyExpired();

    /// @dev Error thrown when trying to create an order without sending the expected amount of ETH to this contract.
    error IncorrectEthAmount();

    /// @dev Error thrown when trying to create an order with a sell amount == 0
    error NotAllowedZeroSellAmount();

    /// @dev Error thrown if trying to invalidate an order while not allowed.
    error NotAllowedToInvalidateOrder(bytes32 orderHash);

    /// @dev Error thrown when unsuccessfully sending ETH to an address.
    error EthTransferFailed();

    /// @dev Function that creates and broadcasts an ETH flow order that sells native ETH. The order is paid for when
    /// the caller sends out the transaction. The caller takes ownership of the new order.
    ///
    /// @param order The data describing the order to be created. See [`EthFlowOrder.Data`] for extra information on
    /// each parameter.
    /// @return orderHash The hash of the CoW Swap order that is created to settle the new ETH order.
    function createOrder(EthFlowOrder.Data calldata order)
        external
        payable
        returns (bytes32 orderHash);

    /// @dev Marks existing ETH-flow orders as invalid and, for each order, refunds the ETH that hasn't been traded yet.
    /// The function call will not revert, if some orders are not refundable. It will silently ignore these orders.
    /// Note that some parameters of the orders are ignored, as for example the order expiration date and the quote id.
    ///
    /// @param orderArray Array of orders to be invalidated.
    function invalidateOrdersIgnoringNotAllowed(
        EthFlowOrder.Data[] calldata orderArray
    ) external;

    /// @dev Marks an existing ETH-flow order as invalid and refunds the ETH that hasn't been traded yet.
    /// Note that some parameters of the orders are ignored, as for example the order expiration date and the quote id.
    ///
    /// @param order Order to be invalidated.
    function invalidateOrder(EthFlowOrder.Data calldata order) external;

    /// @dev EIP1271-compliant onchain signature verification function.
    /// This function is used by the CoW Swap settlement contract to determine if an order that is signed with an
    /// EIP1271 signature is valid. As this contract has approved the vault relayer contract, a valid signature for an
    /// order means that the order can be traded on CoW Swap.
    ///
    /// @param orderHash Hash of the order to be signed. This is the EIP-712 signing hash for the specified order as
    /// defined in the CoW Swap settlement contract.
    /// @param signature Signature byte array. This parameter is unused since as all information needed to verify if an
    /// order is already available onchain.
    /// @return magicValue Either the EIP-1271 "magic value" indicating success (0x1626ba7e) or a different value
    /// indicating failure (0xffffffff).
    function isValidSignature(bytes32 orderHash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);

    /// @dev This function reads the  chain's native token balance of this contract (e.g., ETH for mainnet) and converts
    // the entire amount to its wrapped version (e.g., WETH).
    function wrapAll() external;

    /// @dev This function takes the specified amount of the chain's native token (e.g., ETH for mainnet) stored by this
    /// contract and converts it to its wrapped version (e.g., WETH).
    ///
    /// @param amount The amount of native tokens to convert to wrapped native tokens.
    function wrap(uint256 amount) external;

    /// @dev This function takes the specified amount of the chain's wrapped native token (e.g., WETH for mainnet)
    /// and converts it to its unwrapped version (e.g., ETH).
    ///
    /// @param amount The amount of wrapped native tokens to convert to native tokens.
    function unwrap(uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/GPv2Order.sol";

/// @title CoW Swap Onchain Order Creator Interface
/// @author CoW Swap Developers
interface ICoWSwapOnchainOrders {
    /// @dev List of signature schemes that are supported by this contract to create orders onchain.
    enum OnchainSigningScheme {
        Eip1271,
        PreSign
    }

    /// @dev Struct containing information on the signign scheme used plus the corresponding signature.
    struct OnchainSignature {
        /// @dev The signing scheme used by the signature data.
        OnchainSigningScheme scheme;
        /// @dev The data used as an order signature.
        bytes data;
    }

    /// @dev Event emitted to broadcast an order onchain.
    ///
    /// @param sender The user who triggered the creation of the order. Note that this address does *not* need to be
    /// the actual owner of the order and does not need to be related to the order or signature in any way.
    /// For example, if a smart contract creates orders on behalf of the user, then the sender would be the user who
    /// triggers the creation of the order, while the actual owner of the order would be the smart contract that
    /// creates it.
    /// @param order Information on the order that is created in this transacion. The order is expected to be a valid
    /// order for the CoW Swap settlement contract and contain all information needed to settle it in a batch.
    /// @param signature The signature that can be used to verify the newly created order. Note that it is always
    /// possible to recover the owner of the order from a valid signature.
    /// @param data Any extra data that should be passed along with the order. This will be used by the services that
    /// collects onchain orders and no specific encoding is enforced on this field. It is supposed to encode extra
    /// information that is not included in the order data so that it can be passed along when decoding an onchain
    /// order. As an example, a contract that creates orders on behalf of a user could set a different expiration date
    /// than the one specified in the order.
    event OrderPlacement(
        address indexed sender,
        GPv2Order.Data order,
        OnchainSignature signature,
        bytes data
    );

    /// @dev Event emitted to notify that an order was invalidated.
    ///
    /// @param orderUid CoW Swap's unique order identifier of the order that has been invalidated.
    event OrderInvalidation(bytes orderUid);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

/// @title CoW Swap Settlement Contract Interface
/// @author CoW Swap Developers
/// @dev This interface collects the functions of the CoW Swap settlement contract that are used by the ETH flow
/// contract.
interface ICoWSwapSettlement {
    /// @dev Map each user order by UID to the amount that has been filled so
    /// far. If this amount is larger than or equal to the amount traded in the
    /// order (amount sold for sell orders, amount bought for buy orders) then
    /// the order cannot be traded anymore. If the order is fill or kill, then
    /// this value is only used to determine whether the order has already been
    /// executed.
    /// @param orderUid The uinique identifier to use to retrieve the filled amount.
    function filledAmount(bytes memory orderUid) external returns (uint256);

    /// @dev The address of the vault relayer: the contract that handles withdrawing tokens from the user to the
    /// settlement contract. A user who wants to sell a token on CoW Swap must approve this contract to spend the token.
    function vaultRelayer() external returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/IERC20.sol";

/// @title CoW Swap Wrapped Native Token Interface
/// @author CoW Swap Developers
interface IWrappedNativeToken is IERC20 {
    /// @dev Deposit native token in exchange for wrapped netive tokens.
    function deposit() external payable;

    /// @dev Burn wrapped native tokens in exchange for native tokens.
    /// @param amount Amount of wrapped tokens to exchange for native tokens.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

/// @title CoW Swap EIP-712 Encoding Library
/// @author CoW Swap Developers
/// @dev The code in this contract was largely taken from:
/// <https://raw.githubusercontent.com/cowprotocol/contracts/v1.0.0/src/contracts/mixins/GPv2Signing.sol>
library CoWSwapEip712 {
    /// @dev The EIP-712 domain type hash used for computing the domain separator.
    bytes32 private constant DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 domain name used for computing the domain separator.
    bytes32 private constant DOMAIN_NAME = keccak256("Gnosis Protocol");

    /// @dev The EIP-712 domain version used for computing the domain separator.
    bytes32 private constant DOMAIN_VERSION = keccak256("v2");

    /// @dev Computes the EIP-712 domain separator of the CoW Swap settlement contract on the current network.
    ///
    /// @param cowSwapAddress The address of the CoW Swap settlement contract for which to compute the domain separator.
    /// Note that there are no checks to verify that the input address points to an actual contract.
    /// @return The domain separator of the settlement contract for the input address as computed by the settlement
    /// contract internally.
    function domainSeparator(address cowSwapAddress)
        internal
        view
        returns (bytes32)
    {
        // NOTE: Currently, the only way to get the chain ID in solidity is using assembly.
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        return
            keccak256(
                abi.encode(
                    DOMAIN_TYPE_HASH,
                    DOMAIN_NAME,
                    DOMAIN_VERSION,
                    chainId,
                    cowSwapAddress
                )
            );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/GPv2Order.sol";
import "../vendored/IERC20.sol";

/// @title CoW Swap ETH Flow Order Library
/// @author CoW Swap Developers
library EthFlowOrder {
    /// @dev Struct collecting all parameters of an ETH flow order that need to be stored onchain.
    struct OnchainData {
        /// @dev The address of the user whom the order belongs to.
        address owner;
        /// @dev The latest timestamp in seconds when the order can be settled.
        uint32 validTo;
    }

    /// @dev Data describing all parameters of an ETH flow order.
    struct Data {
        /// @dev The address of the token that should be bought for ETH. It follows the same format as in the CoW Swap
        /// contracts, meaning that the token GPv2Transfer.BUY_ETH_ADDRESS (0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        /// represents native ETH (and should most likely not be used in this context).
        IERC20 buyToken;
        /// @dev The address that should receive the proceeds from the order. Note that using the address
        /// GPv2Order.RECEIVER_SAME_AS_OWNER (i.e., the zero address) as the receiver is not allowed.
        address receiver;
        /// @dev The exact amount of ETH that should be sold in this order.
        uint256 sellAmount;
        /// @dev The minimum amount of buyToken that should be received to settle this order.
        uint256 buyAmount;
        /// @dev Extra data to include in the order. It is used by the CoW Swap infrastructure as extra information on
        /// the order and has no direct effect on on-chain execution.
        bytes32 appData;
        /// @dev The exact amount of ETH that should be paid by the user to the CoW Swap contract after the order is
        /// settled.
        uint256 feeAmount;
        /// @dev The latest timestamp in seconds when the order can be settled.
        uint32 validTo;
        /// @dev Flag indicating whether the order is fill-or-kill or can be filled partially.
        bool partiallyFillable;
        /// @dev quoteId The quote id obtained from the CoW Swap API to lock in the current price. It is not directly
        /// used by any onchain component but is part of the information emitted onchain on order creation and may be
        /// required for an order to be automatically picked up by the CoW Swap orderbook.
        int64 quoteId;
    }

    /// @dev An order that is owned by this address is an order that has not yet been assigned.
    address internal constant NO_OWNER = address(0);

    /// @dev An order that is owned by this address is an order that has been invalidated. Note that this address cannot
    /// be directly used to create orders.
    address internal constant INVALIDATED_OWNER = address(type(uint160).max);

    /// @dev Error returned if the receiver of the ETH flow order is unspecified (`GPv2Order.RECEIVER_SAME_AS_OWNER`).
    error ReceiverMustBeSet();

    /// @dev Transforms an ETH flow order into the CoW Swap order that can be settled by the ETH flow contract.
    ///
    /// @param order The ETH flow order to be converted.
    /// @param wrappedNativeToken The address of the wrapped native token for the current network (e.g., WETH for
    /// Ethereum mainet).
    /// @return The CoW Swap order data that represents the user order in the ETH flow contract.
    function toCoWSwapOrder(Data memory order, IERC20 wrappedNativeToken)
        internal
        pure
        returns (GPv2Order.Data memory)
    {
        if (order.receiver == GPv2Order.RECEIVER_SAME_AS_OWNER) {
            // The receiver field specified which address is going to receive the proceeds from the orders. If using
            // `RECEIVER_SAME_AS_OWNER`, then the receiver is implicitly assumed by the CoW Swap Protocol to be the
            // same as the order owner.
            // However, the owner of an ETH flow order is always the ETH flow smart contract, and any ERC20 tokens sent
            // to this contract would be lost.
            revert ReceiverMustBeSet();
        }

        // Note that not all fields from `order` are used in creating the corresponding CoW Swap order.
        // For example, validTo and quoteId are ignored.
        return
            GPv2Order.Data(
                wrappedNativeToken, // IERC20 sellToken
                order.buyToken, // IERC20 buyToken
                order.receiver, // address receiver
                order.sellAmount, // uint256 sellAmount
                order.buyAmount, // uint256 buyAmount
                // This CoW Swap order is not allowed to expire. If it expired, then any solver of CoW Swap contract
                // would be allowed to clear the `filledAmount` for this order using `freeFilledAmountStorage`, making
                // it impossible to detect if the order has been previously filled.
                // Note that order.validTo is disregarded in building the CoW Swap order.
                type(uint32).max, // uint32 validTo
                order.appData, // bytes32 appData
                order.feeAmount, // uint256 feeAmount
                // Only sell orders are allowed. In a buy order, any leftover ETH would stay in the ETH flow contract
                // and would need to be sent back to the user, whose extra gas cost is usually not worth it.
                GPv2Order.KIND_SELL, // bytes32 kind
                order.partiallyFillable, // bool partiallyFillable
                // We do not currently support interacting with the Balancer vault.
                GPv2Order.BALANCE_ERC20, // bytes32 sellTokenBalance
                GPv2Order.BALANCE_ERC20 // bytes32 buyTokenBalance
            );
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

import "../vendored/GPv2Order.sol";
import "../interfaces/ICoWSwapOnchainOrders.sol";
import "../libraries/CoWSwapEip712.sol";

/// @title CoW Swap Onchain Order Creator Event Emitter
/// @author CoW Swap Developers
contract CoWSwapOnchainOrders is ICoWSwapOnchainOrders {
    using GPv2Order for GPv2Order.Data;
    using GPv2Order for bytes;

    /// @dev The domain separator for the CoW Swap settlement contract.
    bytes32 internal immutable cowSwapDomainSeparator;

    /// @param settlementContractAddress The address of CoW Swap's settlement contract on the chain where this contract
    /// is deployed.
    constructor(address settlementContractAddress) {
        cowSwapDomainSeparator = CoWSwapEip712.domainSeparator(
            settlementContractAddress
        );
    }

    /// @dev Emits an event with all information needed to execute an order onchain and returns the corresponding order
    /// hash.
    ///
    /// See [`ICoWSwapOnchainOrders.OrderPlacement`] for details on the meaning of each parameter.
    /// @return The EIP-712 hash of the order data as computed by the CoW Swap settlement contract.
    function broadcastOrder(
        address sender,
        GPv2Order.Data memory order,
        OnchainSignature memory signature,
        bytes memory data
    ) internal returns (bytes32) {
        emit OrderPlacement(sender, order, signature, data);
        return order.hash(cowSwapDomainSeparator);
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.8;

// Vendored from GPv2 contracts v1.0.0, see:
// <https://raw.githubusercontent.com/cowprotocol/contracts/main/src/contracts/interfaces/GPv2EIP1271.sol>
// The following changes were made:
// - Bumped up Solidity version.

library GPv2EIP1271 {
    /// @dev Value returned by a call to `isValidSignature` if the signature
    /// was verified successfully. The value is defined in EIP-1271 as:
    /// bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant MAGICVALUE = 0x1626ba7e;
}

/// @title EIP1271 Interface
/// @dev Standardized interface for an implementation of smart contract
/// signatures as described in EIP-1271. The code that follows is identical to
/// the code in the standard with the exception of formatting and syntax
/// changes to adapt the code to our Solidity version.
interface EIP1271Verifier {
    /// @dev Should return whether the signature provided is valid for the
    /// provided data
    /// @param _hash      Hash of the data to be signed
    /// @param _signature Signature byte array associated with _data
    ///
    /// MUST return the bytes4 magic value 0x1626ba7e when function passes.
    /// MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for
    /// solc > 0.5)
    /// MUST allow external calls
    ///
    function isValidSignature(bytes32 _hash, bytes memory _signature)
        external
        view
        returns (bytes4 magicValue);
}

// SPDX-License-Identifier: LGPL-3.0-or-later

// Vendored from GPv2 contracts v1.0.0, see:
// <https://raw.githubusercontent.com/cowprotocol/contracts/v1.0.0/src/contracts/libraries/GPv2Order.sol>
// The following changes were made:
// - Bumped up Solidity version.
// - Vendored imports.

pragma solidity ^0.8;

import "./IERC20.sol";

/// @title Gnosis Protocol v2 Order Library
/// @author Gnosis Developers
library GPv2Order {
    /// @dev The complete data for a Gnosis Protocol order. This struct contains
    /// all order parameters that are signed for submitting to GP.
    struct Data {
        IERC20 sellToken;
        IERC20 buyToken;
        address receiver;
        uint256 sellAmount;
        uint256 buyAmount;
        uint32 validTo;
        bytes32 appData;
        uint256 feeAmount;
        bytes32 kind;
        bool partiallyFillable;
        bytes32 sellTokenBalance;
        bytes32 buyTokenBalance;
    }

    /// @dev The order EIP-712 type hash for the [`GPv2Order.Data`] struct.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256(
    ///     "Order(" +
    ///         "address sellToken," +
    ///         "address buyToken," +
    ///         "address receiver," +
    ///         "uint256 sellAmount," +
    ///         "uint256 buyAmount," +
    ///         "uint32 validTo," +
    ///         "bytes32 appData," +
    ///         "uint256 feeAmount," +
    ///         "string kind," +
    ///         "bool partiallyFillable" +
    ///         "string sellTokenBalance" +
    ///         "string buyTokenBalance" +
    ///     ")"
    /// )
    /// ```
    bytes32 internal constant TYPE_HASH =
        hex"d5a25ba2e97094ad7d83dc28a6572da797d6b3e7fc6663bd93efb789fc17e489";

    /// @dev The marker value for a sell order for computing the order struct
    /// hash. This allows the EIP-712 compatible wallets to display a
    /// descriptive string for the order kind (instead of 0 or 1).
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("sell")
    /// ```
    bytes32 internal constant KIND_SELL =
        hex"f3b277728b3fee749481eb3e0b3b48980dbbab78658fc419025cb16eee346775";

    /// @dev The OrderKind marker value for a buy order for computing the order
    /// struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("buy")
    /// ```
    bytes32 internal constant KIND_BUY =
        hex"6ed88e868af0a1983e3886d5f3e95a2fafbd6c3450bc229e27342283dc429ccc";

    /// @dev The TokenBalance marker value for using direct ERC20 balances for
    /// computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("erc20")
    /// ```
    bytes32 internal constant BALANCE_ERC20 =
        hex"5a28e9363bb942b639270062aa6bb295f434bcdfc42c97267bf003f272060dc9";

    /// @dev The TokenBalance marker value for using Balancer Vault external
    /// balances (in order to re-use Vault ERC20 approvals) for computing the
    /// order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("external")
    /// ```
    bytes32 internal constant BALANCE_EXTERNAL =
        hex"abee3b73373acd583a130924aad6dc38cfdc44ba0555ba94ce2ff63980ea0632";

    /// @dev The TokenBalance marker value for using Balancer Vault internal
    /// balances for computing the order struct hash.
    ///
    /// This value is pre-computed from the following expression:
    /// ```
    /// keccak256("internal")
    /// ```
    bytes32 internal constant BALANCE_INTERNAL =
        hex"4ac99ace14ee0a5ef932dc609df0943ab7ac16b7583634612f8dc35a4289a6ce";

    /// @dev Marker address used to indicate that the receiver of the trade
    /// proceeds should the owner of the order.
    ///
    /// This is chosen to be `address(0)` for gas efficiency as it is expected
    /// to be the most common case.
    address internal constant RECEIVER_SAME_AS_OWNER = address(0);

    /// @dev The byte length of an order unique identifier.
    uint256 internal constant UID_LENGTH = 56;

    /// @dev Returns the actual receiver for an order. This function checks
    /// whether or not the [`receiver`] field uses the marker value to indicate
    /// it is the same as the order owner.
    ///
    /// @return receiver The actual receiver of trade proceeds.
    function actualReceiver(Data memory order, address owner)
        internal
        pure
        returns (address receiver)
    {
        if (order.receiver == RECEIVER_SAME_AS_OWNER) {
            receiver = owner;
        } else {
            receiver = order.receiver;
        }
    }

    /// @dev Return the EIP-712 signing hash for the specified order.
    ///
    /// @param order The order to compute the EIP-712 signing hash for.
    /// @param domainSeparator The EIP-712 domain separator to use.
    /// @return orderDigest The 32 byte EIP-712 struct hash.
    function hash(Data memory order, bytes32 domainSeparator)
        internal
        pure
        returns (bytes32 orderDigest)
    {
        bytes32 structHash;

        // NOTE: Compute the EIP-712 order struct hash in place. As suggested
        // in the EIP proposal, noting that the order struct has 10 fields, and
        // including the type hash `(12 + 1) * 32 = 416` bytes to hash.
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#rationale-for-encodedata>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let dataStart := sub(order, 32)
            let temp := mload(dataStart)
            mstore(dataStart, TYPE_HASH)
            structHash := keccak256(dataStart, 416)
            mstore(dataStart, temp)
        }

        // NOTE: Now that we have the struct hash, compute the EIP-712 signing
        // hash using scratch memory past the free memory pointer. The signing
        // hash is computed from `"\x19\x01" || domainSeparator || structHash`.
        // <https://docs.soliditylang.org/en/v0.8.16/internals/layout_in_memory.html#layout-in-memory>
        // <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#specification>
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let freeMemoryPointer := mload(0x40)
            mstore(freeMemoryPointer, "\x19\x01")
            mstore(add(freeMemoryPointer, 2), domainSeparator)
            mstore(add(freeMemoryPointer, 34), structHash)
            orderDigest := keccak256(freeMemoryPointer, 66)
        }
    }

    /// @dev Packs order UID parameters into the specified memory location. The
    /// result is equivalent to `abi.encodePacked(...)` with the difference that
    /// it allows re-using the memory for packing the order UID.
    ///
    /// This function reverts if the order UID buffer is not the correct size.
    ///
    /// @param orderUid The buffer pack the order UID parameters into.
    /// @param orderDigest The EIP-712 struct digest derived from the order
    /// parameters.
    /// @param owner The address of the user who owns this order.
    /// @param validTo The epoch time at which the order will stop being valid.
    function packOrderUidParams(
        bytes memory orderUid,
        bytes32 orderDigest,
        address owner,
        uint32 validTo
    ) internal pure {
        require(orderUid.length == UID_LENGTH, "GPv2: uid buffer overflow");

        // NOTE: Write the order UID to the allocated memory buffer. The order
        // parameters are written to memory in **reverse order** as memory
        // operations write 32-bytes at a time and we want to use a packed
        // encoding. This means, for example, that after writing the value of
        // `owner` to bytes `20:52`, writing the `orderDigest` to bytes `0:32`
        // will **overwrite** bytes `20:32`. This is desirable as addresses are
        // only 20 bytes and `20:32` should be `0`s:
        //
        //        |           1111111111222222222233333333334444444444555555
        //   byte | 01234567890123456789012345678901234567890123456789012345
        // -------+---------------------------------------------------------
        //  field | [.........orderDigest..........][......owner.......][vT]
        // -------+---------------------------------------------------------
        // mstore |                         [000000000000000000000000000.vT]
        //        |                     [00000000000.......owner.......]
        //        | [.........orderDigest..........]
        //
        // Additionally, since Solidity `bytes memory` are length prefixed,
        // 32 needs to be added to all the offsets.
        //
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(orderUid, 56), validTo)
            mstore(add(orderUid, 52), owner)
            mstore(add(orderUid, 32), orderDigest)
        }
    }

    /// @dev Extracts specific order information from the standardized unique
    /// order id of the protocol.
    ///
    /// @param orderUid The unique identifier used to represent an order in
    /// the protocol. This uid is the packed concatenation of the order digest,
    /// the validTo order parameter and the address of the user who created the
    /// order. It is used by the user to interface with the contract directly,
    /// and not by calls that are triggered by the solvers.
    /// @return orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the user who owns this order.
    /// @return validTo The epoch time at which the order will stop being valid.
    function extractOrderUidParams(bytes calldata orderUid)
        internal
        pure
        returns (
            bytes32 orderDigest,
            address owner,
            uint32 validTo
        )
    {
        require(orderUid.length == UID_LENGTH, "GPv2: invalid uid");

        // Use assembly to efficiently decode packed calldata.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            orderDigest := calldataload(orderUid.offset)
            owner := shr(96, calldataload(add(orderUid.offset, 32)))
            validTo := shr(224, calldataload(add(orderUid.offset, 52)))
        }
    }
}

// SPDX-License-Identifier: MIT

// Vendored from OpenZeppelin Contracts v4.4.0, see:
// <https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.4.0/contracts/token/ERC20/IERC20.sol>

// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}