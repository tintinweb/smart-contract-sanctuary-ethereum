// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./RecrowBase.sol";

/**
 * @title Recrow
 * @notice A general-purpose escrow protocol
 */
contract Recrow is RecrowBase {
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets domain variables and trusted forwarder.
     * @param name The human-readable name of the signing domain.
     * @param version The current major version of the signing domain.
     * @param trustedForwarder The Recrow TrustedForwarder address.
     */
    constructor(
        string memory name,
        string memory version,
        address trustedForwarder
    ) RecrowBase(name, version, trustedForwarder) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/OrderLib.sol";
import "./extensions/RecrowEscrow.sol";
import "./extensions/RecrowTxValidatable.sol";

/**
 * @title RecrowBase
 * @notice Recrow central contract, handling external user-facing operations.
 */
abstract contract RecrowBase is
    ERC2771Context,
    ReentrancyGuard,
    RecrowEscrow,
    RecrowTxValidatable
{
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error OrderTypeMismatch();
    error InvalidTimeLimit();
    error InvalidOrdersLength();
    error TakerMakerMismatch();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets domain variables and trusted forwarder.
     * @param name The human-readable name of the signing domain.
     * @param version The current major version of the signing domain.
     * @param trustedForwarder The Recrow TrustedForwarder address.
     */
    constructor(
        string memory name,
        string memory version,
        address trustedForwarder
    ) EIP712(name, version) ERC2771Context(trustedForwarder) {}

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Start an escrow order and deposit assets.
     * @dev Assets will held in escrow until the order is finalized or canceled.
     * @param order OrderData to create.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function createOrder(
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external payable nonReentrant {
        _validateFull(
            OrderLib.CREATE_ORDER_TYPE,
            order,
            signatureLeft,
            signatureRight
        );
        _createOrder(order);
    }

    /**
     * @notice Update an escrow order by cancelling the previous order and
     * creating a new one.
     * @dev Orders must be from the same parties (taker & maker).
     * @param orders An array containing 2 orders (old & new).
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function updateOrder(
        OrderLib.OrderData[] calldata orders,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external payable nonReentrant {
        if (orders.length != 2) {
            revert InvalidOrdersLength();
        } else if (
            orders[0].taker != orders[1].taker ||
            orders[0].maker != orders[1].maker
        ) {
            revert TakerMakerMismatch();
        }
        _validateOrder(OrderLib.UPDATE_ORDER_TYPE, orders[0]);
        _validateOrder(OrderLib.UPDATE_ORDER_TYPE, orders[1]);
        (
            bool isMakerSigValid,
            string memory makerSigErrorMessage
        ) = _validateSig(orders, orders[1].maker, signatureLeft);
        if (!isMakerSigValid) {
            revert(makerSigErrorMessage);
        }
        (
            bool isTakerSigValid,
            string memory takerSigErrorMessage
        ) = _validateSig(orders, orders[1].taker, signatureRight);
        if (!isTakerSigValid) {
            revert(takerSigErrorMessage);
        }
        _cancelOrder(orders[0]);
        _createOrder(orders[1]);
    }

    /**
     * @notice Cancel an escrow order, returning the deposit to taker.
     * @dev If an order has yet to be finalized after expiry `order.end`, only
     * require taker signature to cancel.
     * @param order OrderData to cancel.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function cancelOrder(
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external nonReentrant {
        if (order.end < block.timestamp) {
            _validateOrderAndSig(
                OrderLib.CANCEL_ORDER_TYPE,
                order,
                order.taker,
                signatureRight
            );
        } else {
            _validateFull(
                OrderLib.CANCEL_ORDER_TYPE,
                order,
                signatureLeft,
                signatureRight
            );
        }
        _cancelOrder(order);
    }

    /**
     * @notice Finalize an escrow order, allowing the deposit and goods to be sent.
     * @dev The designated arbitrator can finalize without requiring maker sig.
     * @param order OrderData to finalize.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     */
    function finalizeOrder(
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) external payable nonReentrant {
        _validateFull(
            OrderLib.FINALIZE_ORDER_TYPE,
            order,
            signatureLeft,
            signatureRight
        );
        uint256 makeAssetsLength = order.makeAssets.length;
        if (makeAssetsLength > 0) {
            for (uint256 i = 0; i <= makeAssetsLength - 1; ) {
                _transfer(
                    order.makeAssets[i],
                    order.maker,
                    order.makeAssets[i].recipient
                );

                unchecked {
                    i++;
                }
            }
        }
        uint256 extraAssetsLength = order.extraAssets.length;
        if (extraAssetsLength > 0) {
            for (uint256 i = 0; i <= extraAssetsLength - 1; ) {
                _transfer(
                    order.extraAssets[i],
                    order.maker,
                    order.extraAssets[i].recipient
                );

                unchecked {
                    i++;
                }
            }
        }
        bytes32 orderId = OrderLib.hashKey(order);
        _pay(orderId, order.takeAssets);
    }

    /**
     * @notice Get the current protocol version
     * @return The protocol version
     */
    function getVersion() external pure returns (bytes4) {
        return OrderLib.VERSION;
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Create an order, transferring assets to Recrow.
     * @param order OrderData to create.
     */
    function _createOrder(OrderLib.OrderData calldata order) internal {
        bytes32 orderId = OrderLib.hashKey(order);
        _createDeposit(orderId, order.taker, order.takeAssets);
    }

    /**
     * @notice Cancel an order, returning assets to taker.
     * @param order OrderData to cancel.
     */
    function _cancelOrder(OrderLib.OrderData calldata order) internal {
        bytes32 orderId = OrderLib.hashKey(order);
        _withdraw(orderId, order.taker, order.takeAssets);
    }

    /*//////////////////////////////////////////////////////////////
                            CONTEXT OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice ERC2771Context _msgSender() override
     */
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return super._msgSender();
    }

    /**
     * @notice ERC2771Context _msgData() override
     */
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes memory)
    {
        return super._msgData();
    }

    /*//////////////////////////////////////////////////////////////
                           VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Validate order and signatures.
     * @param orderType type of order to perform.
     * @param order OrderData to validate.
     * @param signatureLeft The signature of the maker.
     * @param signatureRight The signature of the taker.
     * @return True if validation succeed.
     */
    function _validateFull(
        bytes4 orderType,
        OrderLib.OrderData calldata order,
        bytes calldata signatureLeft,
        bytes calldata signatureRight
    ) internal view returns (bool) {
        _validateOrder(orderType, order);
        (
            bool isMakerSigValid,
            string memory makerSigErrorMessage
        ) = _validateSig(order, order.maker, signatureLeft);
        if (!isMakerSigValid) {
            revert(makerSigErrorMessage);
        }
        (
            bool isTakerSigValid,
            string memory takerSigErrorMessage
        ) = _validateSig(order, order.taker, signatureRight);
        if (!isTakerSigValid && orderType != OrderLib.FINALIZE_ORDER_TYPE) {
            revert(takerSigErrorMessage);
        } else if (
            !isTakerSigValid && orderType == OrderLib.FINALIZE_ORDER_TYPE
        ) {
            (
                bool isArbitratorSigValid,
                string memory arbitratorSigErrorMessage
            ) = _validateSig(order, order.arbitrator, signatureRight);
            if (!isArbitratorSigValid) {
                revert(arbitratorSigErrorMessage);
            }
        }
        return true;
    }

    /**
     * @notice Validate order and its signature.
     * @param orderType type of order to perform.
     * @param order OrderData to validate.
     * @param signature The signature of the order.
     * @return True if validation succeed.
     */
    function _validateOrderAndSig(
        bytes4 orderType,
        OrderLib.OrderData calldata order,
        address signer,
        bytes calldata signature
    ) internal view returns (bool) {
        _validateOrder(orderType, order);

        (bool isSigValid, string memory sigErrorMessage) = _validateSig(
            order,
            signer,
            signature
        );
        if (!isSigValid) {
            revert(sigErrorMessage);
        }
        return true;
    }

    /**
     * @notice Validate an order.
     * @param orderType type of order to perform.
     * @param order OrderData to validate.
     * @return True if validation succeed.
     */
    function _validateOrder(bytes4 orderType, OrderLib.OrderData calldata order)
        private
        view
        returns (bool)
    {
        // We don't need to validate `start` or `end` when cancelling order
        bool isTargetOrderType = orderType != OrderLib.CANCEL_ORDER_TYPE;
        if (order.orderType != orderType) {
            revert OrderTypeMismatch();
        } else if (
            isTargetOrderType &&
            (order.start > block.timestamp || order.end < block.timestamp)
        ) {
            revert InvalidTimeLimit();
        }
        return OrderLib.validate(order);
    }

    /**
     * @notice Validate a signature.
     * @param order OrderData to check against the signature.
     * @param signer The signer of the signature.
     * @param signature The signature.
     * @return isValid True if validation succeed.
     * @return errorMessage The revert message if isValid is `false`.
     */
    function _validateSig(
        OrderLib.OrderData calldata order,
        address signer,
        bytes calldata signature
    ) private view returns (bool, string memory) {
        bytes32 hash = OrderLib.hash(order);
        (bool isValid, string memory errorMessage) = _validateTx(
            signer,
            hash,
            signature
        );
        return (isValid, errorMessage);
    }

    /**
     * @notice Validate a signature.
     * @param orders OrderData to check against the signature.
     * @param signer The signer of the signature.
     * @param signature The signature.
     * @return isValid True if validation succeed.
     * @return errorMessage The revert message if isValid is `false`.
     */
    function _validateSig(
        OrderLib.OrderData[] calldata orders,
        address signer,
        bytes calldata signature
    ) private view returns (bool, string memory) {
        bytes32 hash = OrderLib.hash(orders);
        (bool isValid, string memory errorMessage) = _validateTx(
            signer,
            hash,
            signature
        );
        return (isValid, errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title RecrowTxValidatable
 * @notice Manages tx signature validation
 */
abstract contract RecrowTxValidatable is Context, EIP712 {
    using SignatureChecker for address;

    /*//////////////////////////////////////////////////////////////
                            VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if a signature is valid for a given signer and data hash.
     * @dev If signer is `_msgSender`, signature is not required.
     * @param signer The signer of the signature.
     * @param hash The data hash.
     * @param signature The signature.
     * @return bool True if validation succeed.
     * @return string The revert message if validation failed.
     */
    function _validateTx(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool, string memory) {
        if (signature.length == 0) {
            address sender = _msgSender();
            if (signer != sender) {
                return (false, "SenderMismatch");
            }
        } else {
            if (
                !signer.isValidSignatureNow(_hashTypedDataV4(hash), signature)
            ) {
                return (false, "InvalidSignature");
            }
        }
        return (true, "");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./AssetLib.sol";

/**
 * @title OrderLib
 * @notice Library for handling Order data structure
 */
library OrderLib {
    /*//////////////////////////////////////////////////////////////
                            ORDER CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Bytes4 representations of the protocol version.
    bytes4 public constant VERSION = bytes4(keccak256("V1"));

    /// @notice Bytes4 representations of allowed operations.
    bytes4 public constant CREATE_ORDER_TYPE = bytes4(keccak256("CREATE"));
    bytes4 public constant UPDATE_ORDER_TYPE = bytes4(keccak256("UPDATE"));
    bytes4 public constant CANCEL_ORDER_TYPE = bytes4(keccak256("CANCEL"));
    bytes4 public constant FINALIZE_ORDER_TYPE = bytes4(keccak256("FINALIZE"));

    /// @notice OrderData typehash for EIP712 compatibility.
    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "OrderData(address maker,address taker,address arbitrator,AssetData[] makeAssets,AssetData[] takeAssets,AssetData[] extraAssets,bytes32 message,uint256 salt,uint256 start,uint256 end,bytes4 orderType,bytes4 version)AssetData(AssetType assetType,uint256 value,address recipient)AssetType(bytes4 assetClass,bytes data)"
        );

    /// @notice OrdersData typehash for EIP712 compatibility.
    bytes32 public constant ORDERS_TYPEHASH =
        keccak256(
            "OrdersData(OrderData[] orders)AssetData(AssetType assetType,uint256 value,address recipient)AssetType(bytes4 assetClass,bytes data)OrderData(address maker,address taker,address arbitrator,AssetData[] makeAssets,AssetData[] takeAssets,AssetData[] extraAssets,bytes32 message,uint256 salt,uint256 start,uint256 end,bytes4 orderType,bytes4 version)"
        );

    /*//////////////////////////////////////////////////////////////
                          ORDER DATA STRUCTURE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding the specification of an escrow order.
    struct OrderData {
        // Address that delivers the goods/services.
        address maker;
        // Address that deposits the payment assets.
        address taker;
        // Address given the right to arbitrate in case of dispute.
        address arbitrator;
        // Assets that will be delivered at the end of escrow.
        AssetLib.AssetData[] makeAssets;
        // Assets that will be deposited at the start of escrow.
        AssetLib.AssetData[] takeAssets;
        // Extra (bonus) assets that will be delivered at the end of escrow.
        AssetLib.AssetData[] extraAssets;
        // Hash of the request message content.
        bytes32 message;
        // Number to provide uniqueness to the order.
        uint256 salt;
        // The start time of an order.
        uint256 start;
        // The expiry time of an order.
        uint256 end;
        // Type of order to execute.
        bytes4 orderType;
        // Current protocol version.
        bytes4 version;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidMaker();
    error InvalidTaker();
    error InvalidTakeAssets();
    error InvalidStart();
    error InvalidEnd();
    error InvalidOrderType();
    error InvalidVersion();

    /*//////////////////////////////////////////////////////////////
                             HASH FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Hash OrderData to generate unique order id.
     * @param order OrderData of the order.
     * @return hash of the order.
     */
    function hashKey(OrderData calldata order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    order.maker,
                    order.taker,
                    order.takeAssets,
                    order.message,
                    order.salt,
                    order.start,
                    order.end,
                    order.arbitrator,
                    order.version
                )
            );
    }

    /**
     * @notice EIP712-compatible hash of OrderData.
     * @param order OrderData of the order.
     * @return hash of the order.
     */
    function hash(OrderData calldata order) internal pure returns (bytes32) {
        // Split to avoid stack too deep error
        return
            keccak256(
                bytes.concat(
                    abi.encode(
                        ORDER_TYPEHASH,
                        order.maker,
                        order.taker,
                        order.arbitrator,
                        AssetLib.packAssets(order.makeAssets),
                        AssetLib.packAssets(order.takeAssets),
                        AssetLib.packAssets(order.extraAssets)
                    ),
                    abi.encodePacked(
                        order.message,
                        order.salt,
                        order.start,
                        order.end,
                        bytes32(order.orderType),
                        bytes32(order.version)
                    )
                )
            );
    }

    /**
     * @notice EIP712-compatible hash of OrdersData.
     * @param orders OrdersData orders.
     * @return hash of the orders.
     */
    function hash(OrderData[] calldata orders) internal pure returns (bytes32) {
        return
            keccak256(abi.encode(ORDERS_TYPEHASH, OrderLib.packOrders(orders)));
    }

    /**
     * @notice EIP712-compatible hash packing of OrderData.
     * @param orders OrderData orders to pack.
     * @return hash of the orders.
     */
    function packOrders(OrderData[] calldata orders)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory orderHashes = new bytes32[](orders.length);
        for (uint256 i = 0; i < orders.length; i++) {
            orderHashes[i] = hash(orders[i]);
        }
        return keccak256(abi.encodePacked(orderHashes));
    }

    /*//////////////////////////////////////////////////////////////
                            VALIDATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check validity of an order.
     * @param order OrderData order to check.
     * @return True if order is valid.
     */
    function validate(OrderData calldata order) internal pure returns (bool) {
        if (order.maker == address(0)) {
            revert InvalidMaker();
        } else if (order.taker == address(0)) {
            revert InvalidTaker();
        } else if (order.takeAssets.length == 0) {
            revert InvalidTakeAssets();
        } else if (order.start == 0) {
            revert InvalidStart();
        } else if (order.end == 0) {
            revert InvalidEnd();
        } else if (
            !(order.orderType == CREATE_ORDER_TYPE ||
                order.orderType == UPDATE_ORDER_TYPE ||
                order.orderType == CANCEL_ORDER_TYPE ||
                order.orderType == FINALIZE_ORDER_TYPE)
        ) {
            revert InvalidOrderType();
        } else if (order.version != VERSION) {
            revert InvalidVersion();
        }

        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libraries/AssetLib.sol";
import "./RecrowTransfer.sol";

/**
 * @title RecrowEscrow
 * @notice Manages escrow logic
 */
abstract contract RecrowEscrow is RecrowTransfer {
    /*//////////////////////////////////////////////////////////////
                             ESCROW STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps order ids to their deposit existence.
    mapping(bytes32 => bool) private _deposits;
    /// @notice Maps order ids to their completion status.
    mapping(bytes32 => bool) private _completed;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposited(
        bytes32 indexed id,
        address indexed payee,
        AssetLib.AssetData[] assets
    );
    event Paid(bytes32 indexed id, AssetLib.AssetData[] assets);
    event Withdrawn(
        bytes32 indexed id,
        address indexed payee,
        AssetLib.AssetData[] assets
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error DepositDoesNotExist();
    error DepositAlreadyExist();
    error EscrowCompleted();
    error ValueMismatch();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check if order already exists.
     * @param id Hash id of the order.
     */
    modifier whenEscrowDeposited(bytes32 id) {
        if (!getDeposit(id)) revert DepositDoesNotExist();
        _;
    }

    /**
     * @notice Check if order is already completed.
     * @param id Hash id of the order.
     */
    modifier whenNotEscrowCompleted(bytes32 id) {
        if (getCompleted(id)) revert EscrowCompleted();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Check completion status of an order.
     * @param id Hash id of the order.
     * @return True if order is already completed, false if not.
     */
    function getCompleted(bytes32 id) public view returns (bool) {
        return _completed[id];
    }

    /**
     * @notice Check existence of an order.
     * @param id Hash id of the order.
     * @return True if order exists, false if not.
     */
    function getDeposit(bytes32 id) public view returns (bool) {
        return _deposits[id];
    }

    /*//////////////////////////////////////////////////////////////
                            ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Record and transfer assets to the escrow.
     * @dev Will revert if assets is empty.
     * @param id Hash id of the order.
     * @param payee Address that deposits the assets.
     * @param assets Assets that will be deposited.
     */
    function _createDeposit(
        bytes32 id,
        address payee,
        AssetLib.AssetData[] calldata assets
    ) internal whenNotEscrowCompleted(id) {
        if (getDeposit(id)) revert DepositAlreadyExist();
        _setDeposit(id, true);

        // Guard against msg.value being reused across multiple assets
        uint256 ethValue;
        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i <= assetsLength - 1; ) {
            if (assets[i].assetType.assetClass == AssetLib.ETH_ASSET_CLASS) {
                ethValue += assets[i].value;
            }
            _transfer(assets[i], payee, address(this));

            unchecked {
                i++;
            }
        }
        if (ethValue != msg.value) {
            revert ValueMismatch();
        }
        emit Deposited(id, payee, assets);
    }

    /**
     * @notice Transfer the escrowed assets to their recipient.
     * @dev Will revert if assets is empty.
     * @param id Hash id of the order.
     * @param assets Assets that will be transferred.
     */
    function _pay(bytes32 id, AssetLib.AssetData[] calldata assets)
        internal
        whenEscrowDeposited(id)
        whenNotEscrowCompleted(id)
    {
        _setCompleted(id, true);

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i <= assetsLength - 1; ) {
            _transfer(assets[i], address(this), assets[i].recipient);

            unchecked {
                i++;
            }
        }
        emit Paid(id, assets);
    }

    /**
     * @notice Transfer the escrowed assets back to taker.
     * @dev Will revert if assets is empty.
     * @param id Hash id of the order.
     * @param assets Assets that will be transferred.
     */
    function _withdraw(
        bytes32 id,
        address payee,
        AssetLib.AssetData[] calldata assets
    ) internal whenEscrowDeposited(id) whenNotEscrowCompleted(id) {
        _setCompleted(id, true);

        uint256 assetsLength = assets.length;
        for (uint256 i = 0; i <= assetsLength - 1; ) {
            _transfer(assets[i], address(this), payee);

            unchecked {
                i++;
            }
        }
        emit Withdrawn(id, payee, assets);
    }

    /**
     * @notice Set order deposit status.
     * @param id Hash id of the order.
     * @param status Boolean value of the deposit status.
     */
    function _setDeposit(bytes32 id, bool status) internal {
        _deposits[id] = status;
    }

    /**
     * @notice Set order completion status.
     * @param id Hash id of the order.
     * @param status Boolean value of the completion status.
     */
    function _setCompleted(bytes32 id, bool status) internal {
        _completed[id] = status;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
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
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title AssetLib
 * @notice Library for handling Asset data structure
 */
library AssetLib {
    /*//////////////////////////////////////////////////////////////
                        ASSET CLASS CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Bytes4 representations of allowed asset (token) classes.
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 public constant PROXY_ASSET_CLASS = bytes4(keccak256("PROXY"));

    /// @notice Asset typehash for EIP712 compatibility.
    bytes32 public constant ASSET_TYPE_TYPEHASH =
        keccak256("AssetType(bytes4 assetClass,bytes data)");
    bytes32 public constant ASSET_TYPEHASH =
        keccak256(
            "AssetData(AssetType assetType,uint256 value,address recipient)AssetType(bytes4 assetClass,bytes data)"
        );

    /*//////////////////////////////////////////////////////////////
                          ASSET DATA STRUCTURE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding the asset's class and details
    struct AssetType {
        // Asset (token) classification
        bytes4 assetClass;
        // Additional asset information (ex: contract address, tokenId)
        bytes data;
    }

    /// @notice Struct holding the data for an asset transfer
    struct AssetData {
        // Specification of the asset
        AssetType assetType;
        // Amount of asset to transfer
        uint256 value;
        // Transfer reecipient of the asset
        address recipient;
    }

    /*//////////////////////////////////////////////////////////////
                            DECODE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Decode additional data associated with the asset.
     * @param assetType AssetType of the asset.
     */
    function decodeAssetTypeData(AssetType memory assetType)
        internal
        pure
        returns (address, uint256)
    {
        if (
            assetType.assetClass == AssetLib.ERC721_ASSET_CLASS ||
            assetType.assetClass == AssetLib.ERC1155_ASSET_CLASS
        ) {
            (address token, uint256 tokenId) = abi.decode(
                assetType.data,
                (address, uint256)
            );
            return (token, tokenId);
        } else if (assetType.assetClass == AssetLib.ERC20_ASSET_CLASS) {
            address token = abi.decode(assetType.data, (address));
            return (token, 0);
        } else if (assetType.assetClass == AssetLib.PROXY_ASSET_CLASS) {
            address proxy = abi.decode(assetType.data, (address));
            return (proxy, 0);
        }
        return (address(0), 0);
    }

    /*//////////////////////////////////////////////////////////////
                             HASH FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice EIP712-compatible hash of AssetType.
     * @param assetType AssetType of the asset.
     * @return hash of the assetType.
     */
    function hash(AssetType calldata assetType)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPE_TYPEHASH,
                    assetType.assetClass,
                    keccak256(assetType.data)
                )
            );
    }

    /**
     * @notice EIP712-compatible hash of AssetData.
     * @param asset AssetData of the asset.
     * @return hash of the asset.
     */
    function hash(AssetData calldata asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPEHASH,
                    hash(asset.assetType),
                    asset.value,
                    asset.recipient
                )
            );
    }

    /**
     * @notice EIP712-compatible hash packing of AssetData.
     * @param assets AssetData assets to pack.
     * @return hash of the assets.
     */
    function packAssets(AssetData[] calldata assets)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory assetHashes = new bytes32[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            assetHashes[i] = hash(assets[i]);
        }
        return keccak256(abi.encodePacked(assetHashes));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interfaces/ITransferProxy.sol";
import "../libraries/AssetLib.sol";

/**
 * @title RecrowTransfer
 * @notice Manages asset transfer logic
 */
abstract contract RecrowTransfer is ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transferred(AssetLib.AssetData asset, address from, address to);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAmount();
    error InvalidAssetClass();
    error InsufficientETH();
    error CannotSendETH();

    /*//////////////////////////////////////////////////////////////
                            TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer an asset according to their class.
     * @dev Will revert if `assetClass` is not allowed.
     * @param asset The asset that will be transferred.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     */
    function _transfer(
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) internal {
        if (asset.assetType.assetClass == AssetLib.ETH_ASSET_CLASS) {
            _ethTransfer(from, to, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.ERC20_ASSET_CLASS) {
            (address token, ) = AssetLib.decodeAssetTypeData(asset.assetType);
            _erc20safeTransferFrom(token, from, to, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId) = AssetLib.decodeAssetTypeData(
                asset.assetType
            );
            if (asset.value != 1) revert InvalidAmount();
            _erc721safeTransferFrom(token, from, to, tokenId);
        } else if (asset.assetType.assetClass == AssetLib.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId) = AssetLib.decodeAssetTypeData(
                asset.assetType
            );
            _erc1155safeTransferFrom(token, from, to, tokenId, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.PROXY_ASSET_CLASS) {
            (address proxy, ) = AssetLib.decodeAssetTypeData(asset.assetType);
            _transferProxyTransfer(proxy, asset, from, to);
        } else {
            revert InvalidAssetClass();
        }

        emit Transferred(asset, from, to);
    }

    /**
     * @notice Transfers ETH.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param value Amount of ETH to send.
     */
    function _ethTransfer(
        address from,
        address to,
        uint256 value
    ) private {
        if (from != address(this)) {
            if (msg.value < value) revert InsufficientETH();
        }
        if (to != address(this)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{ value: value }("");
            if (!success) revert CannotSendETH();
        }
    }

    /**
     * @notice Transfers ERC20.
     * @param token Address of the ERC20 token.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param value Amount of ERC20 to send.
     */
    function _erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        if (from == address(this)) {
            IERC20(token).safeTransfer(to, value);
        } else {
            IERC20(token).safeTransferFrom(from, to, value);
        }
    }

    /**
     * @notice Transfers ERC721.
     * @param token Address of the token.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param tokenId Token id of the ERC721 token.
     */
    function _erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) private {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Transfers ERC1155.
     * @param token Address of the token.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param id Token id of the ERC1155 token.
     * @param value Amount of ERC1155 to send.
     */
    function _erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) private {
        IERC1155(token).safeTransferFrom(from, to, id, value, "");
    }

    /**
     * @notice Transfers asset via a proxy.
     * @param proxy Address of the proxy.
     * @param asset The asset that will be transferred.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     */
    function _transferProxyTransfer(
        address proxy,
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) private {
        ITransferProxy(proxy).transfer(asset, from, to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../libraries/AssetLib.sol";

/**
 * @title TransferProxy Interface
 * @notice Interface for Recrow-compatible transfer proxy contracts
 */
interface ITransferProxy {
    function transfer(
        AssetLib.AssetData calldata asset,
        address from,
        address to
    ) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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