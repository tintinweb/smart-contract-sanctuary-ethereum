// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./core/Executor.sol";

/**
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/

/** Thrown if amounts of items in argument arrays differ. */
error ArgumentsLengthMissmatched();
/** Thrown if new provided nonce is lower than current. */
error NonceLowerThanCurrent(uint256);
/** Thrown if payment didn't go through. */
error PaymentError();
/** Thrown if wrong order type executed. */
error WrongOrderType();

/**
    @title GigaMart Exchange
    @author Rostislav Khlebnikov
    Contains:
        eip712, eip1271
        multipleOrders matching
        cancellation of single/multiple-selected/all orders
        fee management.
*/
contract GigaMart is Executor, ReentrancyGuard {

    /**
        Emitted when user cancels all orders untill `minNonce`.
        @param sender who cancels order.
        @param minNonce new nonce.
     */
    event AllOrdersCancelled(address indexed sender, uint256 minNonce);

    string public constant name = "GigaMart";

    /**
        @param _registry  existing registry address.
        @param _tokenTransferProxy address of transfer proxy contract.
     */
    constructor(
        IProxyRegistry _registry,
        TokenTransferProxy _tokenTransferProxy,
        address validator,
        address platformFeeRecipient,
        uint96 platformFeePercent,
        address protocolFeeRecipient,
        uint96 protocolFeePercent,
        uint8 gap,
        address[] memory feeFree
    )
        Executor(
            validator,
            platformFeeRecipient,
            platformFeePercent,
            protocolFeeRecipient,
            protocolFeePercent,
            gap,
            feeFree,
            name,
            Strings.toString(version())
        )
    {
        registry = _registry;
        tokenTransferProxy = _tokenTransferProxy;
    }

    function version() public pure override returns (uint256) {
        return 1;
    }

    /**
        Cancels orders. msg.sender must be equal to order.maker.
     */
    function cancelOrder(Entities.Order calldata order) external{
        _cancelOrder(order);
    }

    /**
        Cancels selected orders. msg.sender must be equal for each order.maker in `orders` array.
     */
    function cancelOrders(Entities.Order[] calldata orders) external{
        for (uint256 i; i < orders.length;) {
           _cancelOrder(orders[i]);
           unchecked {
            ++i;
           }
        }
    }

    /** 
        Cancels all orders, which are lower than new `minNonce`
     */
    function cancelAllOrders(uint256 minNonce) external {
        if(minNonce < minOrderNonces[msg.sender])
            revert NonceLowerThanCurrent(minOrderNonces[msg.sender]);
        minOrderNonces[msg.sender] = minNonce;
        emit AllOrdersCancelled(msg.sender, minNonce);
    }

    /**
        Transfers multiple items using user-proxy and executable bytecode.
        @param targets addresses of collections or contract, which should be called with encoded function calls in `data`.
        @param data encoded function calls performed against addresses in `targets`.
     */
    function transferMultipleItems(address[] calldata targets, bytes[] calldata data) external{
        if(targets.length != data.length)
            revert ArgumentsLengthMissmatched();
        _multiTransfer(targets, data);
    }

    /**
        Exchanges item for ERC20 or native currency specified in order struct.
        @param order order to execute.
        @param signature signature provided for the order.
        @param toInvalidate orders for the same item to cancel.
     */
    function exchangeSingleItem(
        Entities.Order memory order,
        Entities.Sig calldata signature,
        Entities.InvalidateOrder[] calldata toInvalidate
    ) external payable nonReentrant {
        if(order.outline.saleKind == Sales.SaleKind.CollectionOffer)
            revert WrongOrderType();
        _exchange(msg.sender, order, signature, 0);
        // invalidate cross orders, optional
        if(toInvalidate.length > 0)
            _cancelMultipleOrdersWithPermit(toInvalidate);
    }

    function exchangeSingleItem(
        address recipient,
        Entities.Order memory order,
        Entities.Sig calldata signature,
        Entities.InvalidateOrder[] calldata toInvalidate
    ) external payable nonReentrant {
        if(order.outline.saleKind == Sales.SaleKind.CollectionOffer)
            revert WrongOrderType();
        _exchange(
            recipient == address(0) ? msg.sender : recipient,
            order,
            signature,
            0
        );
        // invalidate cross orders, optional
        if(toInvalidate.length > 0)
            _cancelMultipleOrdersWithPermit(toInvalidate);
    }

    function exchangeSingleItem(
        Entities.Order memory order,
        Entities.Sig calldata signature,
        uint256 tokenId,
        Entities.InvalidateOrder[] calldata toInvalidate
    ) external payable nonReentrant {
        _exchange(msg.sender, order, signature, tokenId);
        // invalidate cross orders, optional
        if(toInvalidate.length > 0)
            _cancelMultipleOrdersWithPermit(toInvalidate);
    }

     function exchangeSingleItem(
        address recipient,
        Entities.Order memory order,
        Entities.Sig calldata signature,
        uint256 tokenId,
        Entities.InvalidateOrder[] calldata toInvalidate
    ) external payable nonReentrant {
        _exchange(
            recipient == address(0) ? msg.sender : recipient,
            order,
            signature,
            tokenId
        );
        // invalidate cross orders, optional
        if(toInvalidate.length > 0)
            _cancelMultipleOrdersWithPermit(toInvalidate);
    }

    function exchangeMultipleItems(
        Entities.Order[] memory orders,
        Entities.Sig[] calldata signatures,
        Entities.InvalidateOrder[] calldata toInvalidate
    ) external payable nonReentrant {
        if (orders.length != signatures.length) {
            revert ArgumentsLengthMissmatched();
        }
        bytes memory payments = new bytes(32);
        bool feeFree_ = feeFree[msg.sender];
        for (uint256 i; i < orders.length;){
            if (uint8(orders[i].outline.saleKind) > 2)
                revert WrongOrderType();
            _exchange_unsafe(msg.sender, orders[i], signatures[i], payments);
            unchecked {
                i++;
            }
        }
        _pay(payments, msg.sender, address(tokenTransferProxy), feeFree_);
        // invalidate cross orders, optional
        if(toInvalidate.length > 0)
            _cancelMultipleOrdersWithPermit(toInvalidate);
    }

    function exchangeMultipleItems(
        address recipient,
        Entities.Order[] memory orders,
        Entities.Sig[] calldata signatures,
        Entities.InvalidateOrder[] calldata toInvalidate
    ) external payable nonReentrant {
        if (orders.length != signatures.length) {
            revert ArgumentsLengthMissmatched();
        }
        bytes memory payments = new bytes(32);
        bool feeFree_ = feeFree[msg.sender];
        recipient = recipient == address(0) ? msg.sender : recipient;
        for (uint256 i; i < orders.length;){
            if (uint8(orders[i].outline.saleKind) > 2)
                revert WrongOrderType();
            _exchange_unsafe(
                recipient,
                orders[i],
                signatures[i],
                payments
            );
            unchecked {
                i++;
            }
        }
        _pay(payments, msg.sender, address(tokenTransferProxy), feeFree_);
        // invalidate cross orders, optional
        if(toInvalidate.length > 0)
            _cancelMultipleOrdersWithPermit(toInvalidate);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import {OwnableDelegateProxy} from "../proxy/OwnableMutableDelegateProxy.sol";
import {TokenTransferProxy, IProxyRegistry, Address} from "../proxy/TokenTransferProxy.sol";
import {Entities, Sales, AuthenticatedProxy} from "./Entities.sol";
import {NativeTransfer} from "../libraries/NativeTransfer.sol";
import {FeeManager} from "./FeeManager.sol";

/**
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/

/**  Thrown if bytecode length is zero at proxy address.*/
error UserProxyDoesNotExist();
/** Thrown if user-proxy implementation poiting to the deprecated implementation. */
error UnknownUserProxyImplementation();
/** Thrown on order cancellation, if order already has been cancelled. */
error OrderIsAlreadyCancelled();
/** Thrown at order cancellation functions, if checks for msg.sender, order nonce or signatures are failed. */
error CannotAuthenticateOrder();
/** Thrown at _validateOrderParameters() function, if terms are wrong or expired or provided exchange address is not matching this contract. */
error InvalidOrder();
/** Thrown if calls to user-proxy are failed.*/
error CallToProxyFailed();
/** Thrown at pay() function, if msg.value lower than expected sell order price. */
error NotEnoughValueSent();

/**
    @title modified ExchangeCore of ProjectWyvernV2
    @author Project Wyvern Developers
    @author Rostislav Khlebnikov
 */
abstract contract Executor is FeeManager {
    using Entities for Entities.Order;
    using NativeTransfer for address;

    bytes4 internal constant EIP_1271_SELECTOR = bytes4(keccak256("isValidSignature(bytes,bytes)"));

    /**  The public identifier for the right to set new fee manager address. */
    bytes32 public constant FEE_MANAGER_SETTER = keccak256("FEE_MANAGER_SETTER");

    /**  The public identifier for the right to set new fee manager address. */
    bytes32 public constant GAP_SETTER = keccak256("GAP_SETTER");

    /** Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /** Proxy registry. */
    IProxyRegistry public registry;

    /** Listing time gap, levels offchain and onchain time difference  */
    uint8 public gap;

    /** User's min nonces. All user offers with nonces below value, which is stored in the mapping, are cancelled. */
    mapping(address => uint256) public minOrderNonces;

    /** Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /**
        Emitted at order cancellation.
        @param maker who created the order.
        @param hash hash of the order.
        @param data parameters of the order concatenated toghether. e.g. {collection address, encoded transfer function call}
     */
    event OrderCancelled(
        address indexed maker,
        bytes32 hash,
        bytes data
    );

    /**
        Emitted when successfuly exchanged item.
        @param order hash of the order.
        @param seller address
        @param buyer address
        @param data contains sell.outline.saleKind, price, sell.outline.target, sell.data, error/success
     */
    event OrderResult(
        bytes32 order,
        address indexed seller,
        address indexed buyer,
        bytes data
    );

    constructor(
        address validator,
        address platformFeeRecipient,
        uint96 platformFeePercent,
        address protocolFeeRecipient,
        uint96 protocolFeePercent,
        uint8 _gap,
        address[] memory feeFree,
        string memory name,
        string memory version
    )
        FeeManager(
            validator,
            platformFeeRecipient,
            platformFeePercent,
            protocolFeeRecipient,
            protocolFeePercent,
            feeFree,
            name, 
            version
        )
    {
        gap = _gap;
    }

    /**
        @dev Changes gap.
        @param _gap New gap value.
     */
    function changeGap(uint8 _gap) external hasValidPermit(UNIVERSAL, GAP_SETTER) {
        gap = _gap;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function _hashToSign(Entities.Order memory order)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, order.hash())
            );
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     */
    function _cancelOrder(Entities.Order calldata order) internal {
        /** CHECKS */

        /** Calculate order hash. */
        bytes32 hash = _hashToSign(order);

        /** Assert order is not cancelled already. */
        if (
            cancelledOrFinalized[hash] ||
            order.nonce < minOrderNonces[msg.sender]
        ) revert OrderIsAlreadyCancelled();

        if (order.outline.maker != msg.sender) revert CannotAuthenticateOrder();

        /** EFFECTS */
        cancelledOrFinalized[hash] = true;

        /** Log cancel event. */
        emit OrderCancelled(
            order.outline.maker,
            hash,
            abi.encode(order.outline.target, order.data)
        );
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param invalidate Order to cancel
     */
    function _cancelOrderWithPermit(
        Entities.InvalidateOrder calldata invalidate
    ) internal {
        /** CHECKS */

        /** Calculate order hash. */
        bytes32 hash = _hashToSign(invalidate.order);

        /** Assert sender is authorized to cancel order. */
        if (!_authenticateOrder(hash, invalidate.order.outline.maker, invalidate.order.nonce, invalidate.sig))
            revert CannotAuthenticateOrder();

        /** EFFECTS */
        cancelledOrFinalized[hash] = true;

        /** Log cancel event. */
        emit OrderCancelled(
            invalidate.order.outline.maker,
            hash,
            abi.encode(invalidate.order.outline.target, invalidate.order.data)
        );
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param invalidations Orders to cancel
     */
    function _cancelMultipleOrdersWithPermit(
        Entities.InvalidateOrder[] calldata invalidations
    ) internal {
        for (uint256 i; i < invalidations.length;) {
            _cancelOrderWithPermit(invalidations[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
        @dev Transferring multiple items using preapproved user-proxy.
        @param targets array of collection addresses.
        @param data array of encoded transfer calls.
     */
    function _multiTransfer(address[] calldata targets, bytes[] calldata data)
        internal
    {
        /** Gas savings via store object in memory and avoid unnecessary extra sloads */
        IProxyRegistry proxyRegistry = registry;

        /** Retrieve delegateProxy contract. */
        address delegateProxy = proxyRegistry.proxies(msg.sender);
        if (!Address.isContract(delegateProxy)) revert UserProxyDoesNotExist();

        /** Assert implementation. */
        if (OwnableDelegateProxy(payable(delegateProxy)).implementation() != proxyRegistry.delegateProxyImplementation())
            revert UnknownUserProxyImplementation();

        /** Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

        for (uint256 i; i < targets.length;) {
            if (!proxy.call(targets[i], AuthenticatedProxy.CallType.Call, data[i])) 
                revert CallToProxyFailed();
            unchecked {
                ++i;
            }
        }
    }

    function _recoverContractSignature(
        address orderMaker,
        bytes32 hash,
        Entities.Sig memory sig
    ) private view returns (bool) {
        bytes memory isValidSignatureData = abi.encodeWithSelector(
            EIP_1271_SELECTOR,
            hash,
            abi.encodePacked(sig.r, sig.s, sig.v)
        );

        bytes4 result;

        assembly {
            let success := staticcall(
                // perform a staticcall
                gas(), // forward all available gas
                orderMaker, // call the order maker
                add(isValidSignatureData, 0x20), // calldata offset comes after length
                mload(isValidSignatureData), // load calldata length
                0, // do not use memory for return data
                0 // do not use memory for return data
            )

            if iszero(success) {
                // if the call fails
                returndatacopy(0, 0, returndatasize()) // copy returndata buffer to memory
                revert(0, returndatasize()) // revert + pass through revert data
            }

            if eq(returndatasize(), 0x20) {
                // if returndata == 32 (one word)
                returndatacopy(0, 0, 0x20) // copy return data to memory in scratch space
                result := mload(0) // load return data from memory to the stack
            }
        }

        return result == EIP_1271_SELECTOR;
    }

    function _validateOrderParameters(address recipient, Entities.Order memory order)
        private
        view
        returns (bool)
    {
        /** Order must be targeted at this platform version (this Exchange contract). */
        if (order.outline.exchange != address(this))
            return false;

        /** Order maker cannot initiate such transaction. */
        if (order.outline.maker == recipient || order.outline.maker == msg.sender)
            return false;

        /** Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        if (!Address.isContract(order.outline.target))
            return false;

        /** Order must possess valid sale kind parameter combination. */
        if (
            !Sales._canSettleOrder(
                order.outline.listingTime - gap, // allow listing happened within `gap` period
                order.outline.expirationTime
            )
        ) 
            return false;

        if (
            uint8(order.outline.saleKind) > 5 //unknown type of order
        ) 
            return false;
        /** Validate order.data selector and arguments */
        if(
            !order.validateCall()
        )
            return false;

        return true;
    }

    /**
     * @dev Validate a provided previously signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param maker order maker
     * @param sig ECDSA signature
     */
    function _authenticateOrder(
        bytes32 hash,
        address maker,
        uint256 nonce,
        Entities.Sig calldata sig
    ) private view returns (bool) {
        /** Order is cancelled or executed in the past.*/
       if (cancelledOrFinalized[hash])
        return false;

        /** Order min nonce must be valid */
        if (nonce < minOrderNonces[maker])
            return false;

        /** EOA-only authentication: ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == maker)
            return true;

        /** Contract-only authentication: EIP 1271. */
        if (Address.isContract(maker))
            return _recoverContractSignature(maker, hash, sig);

        return false;
    }

    /**
     * @dev Execute all ERC20 token / Native currency transfers associated with an order match (fees and buyer => seller transfer)
     * @param order Sell-side order
     */
    function _pay(
        Entities.Order memory order
    ) private returns (uint256) {
        (address seller, address buyer) = order.outline.side == Sales.Side.Buy ? (msg.sender, order.outline.maker) : (order.outline.maker, msg.sender);
        /** Calculate match price. */
        uint256 requiredAmount = Sales._calculateFinalPrice(
            order.outline.saleKind,
            order.outline.basePrice,
            order.extra,
            order.outline.listingTime);
        /** Dup required amount for substructing fees. */
        uint256 receiveAmount = requiredAmount;
        uint256 fee;
        /** Read fees and royalties for this collection. */
        uint256[] memory fees = getFees(order.outline.target);
        if (requiredAmount > 0) {
            /** If buying for ERC20. */
            if (order.outline.paymentToken != address(0)) {
                /** Gas savings via store object in memory and avoid unnecessary extra sloads */
                TokenTransferProxy proxy = tokenTransferProxy;
                for (uint256 i; i < fees.length;) {
                    fee = (requiredAmount * uint96(fees[i])) / 10_000;
                    if (fee != 0) {
                        proxy.transferERC20(
                            order.outline.paymentToken,
                            buyer,
                            address(uint160(fees[i] >> 96)),
                            fee
                        );
                        receiveAmount -= fee;
                    }
                    unchecked {
                        ++i;
                    }
                }

                proxy.transferERC20(
                    order.outline.paymentToken,
                    buyer,
                    seller,
                    receiveAmount
                );
            } else {
                /** If buying for native currency. */
                if (msg.value < requiredAmount) revert NotEnoughValueSent();
                /** transfer fees */
                for (uint256 i; i < fees.length;) {
                    fee = (requiredAmount * uint96(fees[i])) / 10_000;
                    if (fee != 0) {
                        address(uint160(fees[i] >> 96)).transferEth(fee);
                        receiveAmount -= fee;
                    }
                    unchecked {
                        ++i;
                    }
                }
                /** transfer payment. */
                seller.transferEth(receiveAmount);
            }
        }
        return requiredAmount;
    }

    function _insert(bytes memory payments, address paymentToken, address recipient, uint256 price) internal pure {
        assembly {
            let len := div(mload(add(payments, 0x00)), 0x60)
            let found := false
            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                let token := mload(add(payments, add(mul(i, 0x60), 0x20)))
                if eq(token, paymentToken) {
                    let offset := add(payments, add(mul(i, 0x60), 0x60))
                    let to := mload(add(payments, add(mul(i, 0x60), 0x40)))
                    if eq(to, recipient) {
                        let amount := mload(offset)
                        mstore(
                            offset,
                            add(amount, price)
                        )
                        found := true
                    }
                }
            }
            if eq(found, 0) {
                switch len
                    case 0 {
                        mstore(
                            add(payments, 0x00),
                            add(
                                mload(add(payments, 0x00)),
                                0x40
                            )
                        )
                    }
                default {
                    mstore(
                        add(payments, 0x00),
                        add(
                            mload(add(payments, 0x00)),
                            0x60
                        )
                    )
                }
                let offset := add(payments, mul(len, 0x60))
                mstore(
                    add(offset, 0x20),
                    paymentToken
                )
                mstore(
                    add(offset, 0x40),
                    recipient
                )
                mstore(
                    add(offset, 0x60),
                    price
                )
            }
        }
    }

    function _pay(bytes memory payments, address buyer, address proxy, bool feeFree) internal {
        bytes4 sig = TokenTransferProxy.transferERC20.selector;
        uint256 ethPayment;
        assembly{
            let len := div(mload(add(payments, 0x00)), 0x60)
            let sum := 0
            for { let i := 0 } lt(i, len) { i := add(i, 1) } {
                let token := mload(add(payments, add(mul(i, 0x60), 0x20)))
                let to := mload(add(payments, add(mul(i, 0x60), 0x40)))
                let amount := mload(add(payments, add(mul(i, 0x60), 0x60)))
                switch token
                    case 0 {
                        ethPayment := add(ethPayment, amount)
                        let result := call(
                            gas(),
                            to,
                            amount,
                            0, 0, 0, 0
                        )
                        if iszero(result) { revert (0, 0) }
                    }
                    default {
                        let data := mload(0x40)
                        mstore(data, sig)
                        mstore(add(data, 0x04), token)
                        mstore(add(data, 0x24), buyer)
                        mstore(add(data, 0x44), to)
                        mstore(add(data, 0x64), amount)
                        let result := call(
                            gas(),
                            proxy,
                            0,
                            data,
                            0x84,
                            0, 0
                        )
                        mstore(0x40, add(data,0x84))
                        if iszero(result) { revert (0, 0) }
                    }
            }
        }
        /** refund if needed */
        if (msg.value > ethPayment)
            buyer.transferEth(msg.value - ethPayment);
    }

    function _emitResult(address recipient, Entities.Order memory order, bytes32 hash, bytes1 code, uint256 price) private {
        emit OrderResult(
            hash,
            order.outline.maker,
            recipient,
            abi.encodePacked(
                order.outline.saleKind,
                price,
                order.outline.target,
                order.data,
                code
            )
        );
    }

    function _exchange_unsafe(
        address recipient,
        Entities.Order memory order,
        Entities.Sig calldata signature,
        bytes memory payments
    ) internal {
        /** CHECKS */
        /** Get sell order hash. */
        bytes32 hash = _hashToSign(order);
        {
            /** Validate the order. */
            if (!_validateOrderParameters(recipient, order)){
                _emitResult(recipient, order, hash, 0x11, 0);
                return;
            }
                
            /** Authenticate the order. */
            if (!_authenticateOrder(hash, order.outline.maker, order.nonce, signature)){
                _emitResult(recipient, order, hash, 0x12, 0);
                return;
            }

            /** Gas savings via store object in memory and avoid unnecessary extra sloads */
            IProxyRegistry proxyRegistry = registry;

            /** Retrieve delegateProxy contract. */
            address delegateProxy = proxyRegistry.proxies(order.outline.maker);

            /** Proxy must exist. */
            if (!Address.isContract(delegateProxy)){
                _emitResult(recipient, order, hash, 0x43, 0);
                return;
            }

            /** Assert implementation. */
            if (OwnableDelegateProxy(payable(delegateProxy)).implementation() != proxyRegistry.delegateProxyImplementation()){
                _emitResult(recipient, order, hash, 0x44, 0);
                return;
            }

            /** Access the passthrough AuthenticatedProxy. */
            AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

            /** INTERACTIONS */
            order.generateCall(recipient, 0);
        
            /** transfer asset through proxy. */
            if (!proxy.call(order.outline.target, order.outline.callType, order.data)){
                _emitResult(recipient, order, hash, 0x50, 0);
                return;
            }
        }
        {
            /**Form payments. */
            // calculate total price
            uint256 price = Sales._calculateFinalPrice(
                order.outline.saleKind,
                order.outline.basePrice,
                order.extra,
                order.outline.listingTime);
            _insert(
                payments,
                order.outline.paymentToken,
                order.outline.maker,
                price
            );

            /** Mark the order as finalized. */
            cancelledOrFinalized[hash] = true;
            _emitResult(recipient, order, hash, 0xFF, price);
        }
    }

    function _exchange(
        address recipient,
        Entities.Order memory order,
        Entities.Sig calldata signature,
        uint256 tokenId
    ) internal{
        /** CHECKS */
        /** Get sell order hash. */
        bytes32 hash = _hashToSign(order);

        /** Validate the order. */
        if (!_validateOrderParameters(recipient, order))
            revert InvalidOrder();

        /** Authenticate the order. */
        if (!_authenticateOrder(hash, order.outline.maker, order.nonce, signature))
            revert CannotAuthenticateOrder();

        /** Gas savings via store object in memory and avoid unnecessary extra sloads */
        IProxyRegistry proxyRegistry = registry;

        /** Retrieve delegateProxy contract. */
        address delegateProxy = proxyRegistry.proxies(order.outline.side == Sales.Side.Buy ? recipient : order.outline.maker);

        /** Proxy must exist. */
        if (!Address.isContract(delegateProxy)) revert UserProxyDoesNotExist();

        /** Assert implementation. */
        if (OwnableDelegateProxy(payable(delegateProxy)).implementation() != proxyRegistry.delegateProxyImplementation())
            revert UnknownUserProxyImplementation();

        /** Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(payable(delegateProxy));

        /** INTERACTIONS */
        order.generateCall(recipient, tokenId);
        
        /** transfer asset through proxy. */
        if (!proxy.call(order.outline.target, order.outline.callType, order.data))
            revert CallToProxyFailed();

        /** execute payment. */
        uint256 price = _pay(order);
        /** refund if needed */
        if (msg.value > price)
            msg.sender.transferEth(msg.value - price);

        /** EFFECTS */

        /** Mark previously signed orders as finalized. */
        cancelledOrFinalized[hash] = true;

        /** Log match */
        bytes memory settledParameters = abi.encodePacked(
            order.outline.saleKind,
            price,
            order.outline.target,
            order.data,
            bytes1(0xFF)
        );

        emit OrderResult(
            hash,
            order.outline.maker,
            recipient,
            settledParameters
        );
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";

error CantRetartgetImmutableProxy();
error RetargetToTheCurrentTarget();

/**
  @title A call-delegating proxy whose owner may mutate its target.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
contract OwnableMutableDelegateProxy is OwnableDelegateProxy {

  /// The ERC-897 proxy type: this proxy is mutable.
  uint256 public override constant proxyType = 2;

  /**
    This event is emitted each time the target of this proxy is changed.

    @param previousTarget The previous target of this proxy.
    @param newTarget The new target of this proxy.
  */
  event TargetChanged(address indexed previousTarget,
    address indexed newTarget);

  /**
    Construct this delegate proxy with an owner, initial target, and an initial
    call sent to the target.

    @param _owner The address which should own this proxy.
    @param _target The initial target of this proxy.
    @param _data The initial call to delegate to `_target`.
  */
  constructor (address _owner, address _target, bytes memory _data)
    OwnableDelegateProxy(_owner, _target, _data) { }

  /**
    Allows the owner of this proxy to change the proxy's current target.

    @param _target The new target of this proxy.
  */
  function changeTarget(address _target) public onlyOwner {
    if (proxyType != 2)
      revert CantRetartgetImmutableProxy();
    if (target == _target)
      revert RetargetToTheCurrentTarget();
    address oldTarget = target;
    target = _target;

    // Emit an event that this proxy's target has been changed.
    emit TargetChanged(oldTarget, _target);
  }

  /**
    Allows the owner of this proxy to change the proxy's current target and
    immediately delegate a call to the new target.

    @param _target The new target of this proxy.
    @param _data A call to delegate to `_target`.
  */
  function changeTargetAndCall(address _target, bytes calldata _data) external
    onlyOwner {
    changeTarget(_target);
    (bool success, ) = address(this).delegatecall(_data);
    require(success,
      "OwnableDelegateProxy: the call to the new target must succeed");
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import "../proxy/AuthenticatedProxy.sol";
import "../libraries/Sales.sol";

library Entities {

    bytes4 constant ERC1155_TRANSFER_SELECTOR = 0xf242432a;
    bytes4 constant ERC721_TRANSFER_SELECTOR = 0x23b872dd;

    /** EIP712 typehashes. */
    bytes32 public constant OUTLINE_TYPEHASH =
        keccak256(
            "Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
        );

    bytes32 public constant ORDER_TYPEHASH =
        keccak256(
            "Order(uint256 nonce,Outline outline,uint256[] extra,bytes data)Outline(uint256 basePrice,uint256 listingTime,uint256 expirationTime,address exchange,address maker,uint8 side,address taker,uint8 saleKind,address target,uint8 callType,address paymentToken)"
        );

    /** supporting struct for order to avoid stack too deep */
    struct Outline{
        /** Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /** Listing timestamp. */
        uint256 listingTime;
        /** Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /** Exchange address, intended as a versioning mechanism. */
        address exchange;
        /** Order maker address. */
        address maker;
        /** Displays side of the deal. { Buy, Sell} */
        Sales.Side side;
        /** Order taker address, if specified. */
        address taker;
        /** Kind of sale. {FixedPrice, DecreasingPrice, DirectListing, Offer, OfferBondedToNFT, CollectionOffer} */
        Sales.SaleKind saleKind;
        /** Target. */
        address target;
        /** Type of the call for user proxy. {Call, DelegateCall} */
        AuthenticatedProxy.CallType callType;
        /** Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
    }

    /** An order on the exchange. */
    struct Order {
        /** Order nonce, used to prevent duplicate hashes. */
        uint256 nonce;
        /** order essentials */
        Outline outline;
        /** For 'DecresingPrice' kind of offer this array should contain:
            ending price + ending time.
            For 'CollectionOffer' kind of offer this array should contain:
            count(limit) of desiring nft trades + tokenIds that are allowed to exchange
        */
        uint256[] extra;
        /** Calldata. */
        bytes data;
    }

    /** An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /** Order invalidation entity. */
    struct InvalidateOrder{
        Order order;
        Sig sig;
    }

        /**
     * @dev Hash an order, returning the canonical order hash, without the message prefix
     * @param order Order to hash
     * @return hash Hash of order
     */
    function hash(Order memory order)
        internal
        pure
        returns (bytes32){
        return keccak256(
            abi.encode(
                ORDER_TYPEHASH,
                order.nonce,
                hash(order.outline),
                keccak256(abi.encodePacked(order.extra)),
                keccak256(order.data)
            )
        );
    }
    function validateCall(Order memory order) internal pure returns (bool res){
        uint8 saleKind = uint8(order.outline.saleKind);
        bytes memory data = order.data;
        bytes4 selector;
        assembly {
            selector := mload(add(data, 0x20))
        }
        if (selector == ERC1155_TRANSFER_SELECTOR || selector == ERC721_TRANSFER_SELECTOR) {
            uint256 buffer;
            assembly{
                switch saleKind
                case 0 {
                    buffer := mload(add(data, 0x44))
                }
                case 1 {
                    buffer := mload(add(data, 0x44))
                }
                case 4 {
                    buffer := mload(add(data, 0x24))
                }
                case 5 {
                    buffer := add(mload(add(data, 0x24)), mload(add(data,0x64)))
                }
                default {}
            }
            res = buffer == 0;
        }
    }
    function generateCall(Order memory order, address to, uint256 tokenId) internal pure returns (bytes memory data) {
        data = order.data;
        uint8 saleKind = uint8(order.outline.saleKind);
        assembly {
            switch saleKind
            case 0 {
                mstore(add(data, 0x44), to)
            }
            case 1 {
                mstore(add(data, 0x44), to)
            }
            case 4 {
                mstore(add(data, 0x24), to)
            }
            case 5 {
                mstore(add(data, 0x24), to)
                mstore(add(data, 0x64), tokenId)
            }
            default{}
        }
    }
    function hash(Outline memory outline)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    OUTLINE_TYPEHASH,
                    outline.basePrice,
                    outline.listingTime,
                    outline.expirationTime,
                    outline.exchange,
                    outline.maker,
                    outline.side,
                    outline.taker,
                    outline.saleKind,
                    outline.target,
                    outline.callType,
                    outline.paymentToken
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import {BaseFeeManager} from "../../../shared/BaseFeeManager.sol";
import {Signature} from "../libraries/Signature.sol";
import {EIP712} from "../libraries/EIP712.sol";

error ValidatorAddressCannotBeZero();
error SignatureExpired();
error BadSignature();

abstract contract FeeManager is EIP712, BaseFeeManager {

    /** The public identifier for the right to change validator address. */
    bytes32 public constant VALIDATOR_SETTER = keccak256("VALIDATOR_SETTER");
    /** Royalty fee struct typehash. */
    bytes32 public constant ROYALTY_TYPEHASH = keccak256("Royalty(address setter,address collection,uint256 deadline,uint256[] newRoyalties)");

    /** The address of the validator. */
    address validator;

    /** collection address => royalty */
    mapping(address => uint256[]) public royalties;

    mapping(address => bool) public feeFree;

    /**
        Emmited when royalty for collection is changed.
        @param setter address which changed royalties.
        @param collection address of the collection, for which new royalties are set.
        @param newRoyalties array of new royalties, address and uint96 packed in 256 bits.
    */
    event RoyaltyChanged(
        address indexed setter,
        address indexed collection,
        uint256[] newRoyalties
    );

    /**
        Emmited when new royalties added to collection.
        @param setter address which added royalties.
        @param collection address of the collection, for which new royalties are added.
        @param newRoyalties array of new royalties, address and uint96 packed in 256 bits.
    */
    event RoyaltyAdded(
        address indexed setter,
        address indexed collection,
        uint256[] newRoyalties
    );

    /**
        @param platformFeeRecipient platform fee recipient address.
        @param platformFeePercent platform fee percent.
        @param protocolFeeRecipient protocol fee recipient address.
        @param protocolFeePercent protocol fee percent.
     */
    constructor(
        address _validator,
        address platformFeeRecipient,
        uint96 platformFeePercent,
        address protocolFeeRecipient,
        uint96 protocolFeePercent,
        address[] memory _feeFree,
        string memory name, 
        string memory version
    )
    BaseFeeManager(
        platformFeeRecipient,
        platformFeePercent,
        protocolFeeRecipient,
        protocolFeePercent
    )
    EIP712(name, version)
    {
        validator = _validator;
        for (uint256 i; i < _feeFree.length;){
            feeFree[_feeFree[i]] = true;
            unchecked{
                ++i;
            }
        }
    }

    /**
        Takes hash from parameters, before validating royalties change.
        @param setter msg.sender for royalty change.
        @param collection address of the collection for which royalties will be changed/added.
        @param deadline time until setter has rights to change royalties.
        @param newRoyalties royalties to be set/added.
     */
    function hash(
        address setter,
        address collection,
        uint256 deadline,
        uint256[] memory newRoyalties
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(
                    abi.encode(
                        ROYALTY_TYPEHASH,
                        setter,
                        collection,
                        deadline,
                        keccak256(abi.encodePacked(newRoyalties))))));
    }

    /**
        @dev Changes validator address.
        @param _validator new validator address.
     */
    function changeValidator(address _validator)
        external
        hasValidPermit(UNIVERSAL, VALIDATOR_SETTER)
    {
        if (_validator == address(0)) revert ValidatorAddressCannotBeZero();
        validator = _validator;
    }

    function excludeFromFees(address[] calldata _feeFree) external hasValidPermit(UNIVERSAL, FEE_CONFIG){
        for (uint256 i; i < _feeFree.length;){
            if(!feeFree[_feeFree[i]])
                feeFree[_feeFree[i]] = true;
            unchecked{
                ++i;
            }
        }
    }

    function chargeFees(address[] calldata toChargeFee) external hasValidPermit(UNIVERSAL, FEE_CONFIG){
        for (uint256 i; i < toChargeFee.length;){
            if(feeFree[toChargeFee[i]])
                feeFree[toChargeFee[i]] = false;
            unchecked{
                ++i;
            }
        }
    }

    /**
        @dev Rewrites mapping with new royalties.
        @param collection address of the collection, for which `newRoyalties` are set.
        @param deadline time until which `signature` is valid.
        @param newRoyalties royalties to be set.
        @param signature validator signature.
     */
    function setRoyalties(
        address collection,
        uint256 deadline,
        uint256[] memory newRoyalties,
        bytes calldata signature
    ) external {
        if (Signature.recover(hash(msg.sender, collection, deadline, newRoyalties), signature) != validator) revert BadSignature();
        if (deadline < block.timestamp) revert SignatureExpired();
        royalties[collection] = newRoyalties;
        emit RoyaltyChanged(msg.sender, collection, newRoyalties);
    }

    /**
        @dev Appends new royalties.
        @param collection address of the collection, for which `newRoyalties` are added.
        @param deadline time until which `signature` is valid.
        @param newRoyalties royalties to be added.
        @param signature validator signature.
     */
    function addRoyalties(
        address collection,
        uint256 deadline,
        uint256[] memory newRoyalties,
        bytes calldata signature
    ) external {
        if (Signature.recover(hash(msg.sender, collection, deadline, newRoyalties), signature) != validator) revert BadSignature();
        if (deadline < block.timestamp) revert SignatureExpired();
        for (uint256 i; i < newRoyalties.length;){
            royalties[collection].push(newRoyalties[i]);
            unchecked {
                ++i;
            }
        }
        emit RoyaltyAdded(msg.sender, collection, newRoyalties);
    }

    /**
        Returns royalty, platform and protocol fee configs.
        @param collection address to return fees for.
     */
    function getFees(address collection)
        public
        view
        returns (uint256[] memory)
    {
        uint256 platformFee_ = platformFee;
        uint256 protocolFee_ = protocolFee;
        if(!feeFree[msg.sender]){
            uint256 size;
            if(uint96(platformFee) != 0){
                unchecked {
                    size++;
                }
            }
            if(uint96(protocolFee) != 0){
                unchecked {
                    size++;
                }
            }
            if(size == 0)
                return royalties[collection];
            uint256 royaltyLength = royalties[collection].length;
            uint256[] memory fees = new uint256[](royaltyLength + size);
            if(uint96(platformFee) != 0)
                fees[0] = platformFee_;
            if(uint96(protocolFee) != 0)
                if(fees[0] == 0)
                    fees[0] = protocolFee_;
                else{
                    fees[1] = protocolFee_;
                }
            for (uint256 i = size; i < royaltyLength + size;){
                unchecked {
                    fees[i] = royalties[collection][i - size];
                    ++i;
                }
            }
            return fees;
        }
        return royalties[collection];
    }
}

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IProxyRegistry.sol";

contract TokenTransferProxy {
    using SafeERC20 for IERC20;

    /* Authentication registry. */
    IProxyRegistry public registry;

    /**
        @param _registry address of the proxy registry
     */
    constructor (address _registry){
        registry = IProxyRegistry(_registry);
    }

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferERC20(address token, address from, address to, uint amount)
        public
    {   
        if(!registry.authorizedCallers(msg.sender))
            revert NonAuthorizedCaller();
        IERC20(token).safeTransferFrom(from, to, amount);
    }   
}

pragma solidity ^0.8.11;

error TransferFailed();

/** 
    Library asserting native currency transfer was succesfull.
*/
library NativeTransfer {

    /**
        Wrapping low-level call with revert.
     */
    function transferEth(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        if(!success)
            revert TransferFailed();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DelegateProxy.sol";

error InitialTargetCallFailed();

/**
  @title A call-delegating proxy with an owner.
  @author Protinam, Project Wyvern
  @author Tim Clancy
  @author Rostislav Khlebnikov

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.

  July 19th, 2021.
*/
abstract contract OwnableDelegateProxy is Ownable, DelegateProxy {

  // Shows if user proxy was initialized
  bool public initialized;
  /// escape slot to match AuthenticatedProxy storage uint8(bool)+uint184 = 192 bits, so target (160 bits) can't be put in this storage slot
  uint184 internal escape;
  /// The address of the proxy's current target.
  address public target;

  /**
    Construct this delegate proxy with an owner, initial target, and an initial
    call sent to the target.

    @param _owner The address which should own this proxy.
    @param _target The initial target of this proxy.
    @param _data The initial call to delegate to `_target`.
  */
  constructor(address _owner, address _target, bytes memory _data) {

    // Do not perform a redundant ownership transfer if the deployer should
    // remain as the owner of this contract.
    if (_owner != owner()) {
      transferOwnership(_owner);
    }
    target = _target;

    // Immediately delegate a call to the initial implementation and require it
    // to succeed. This is often used to trigger some kind of initialization
    // function on the target.
    (bool success, ) = _target.delegatecall(_data);
    if (!success)
      revert InitialTargetCallFailed();
  }

  /**
    Return the current address where all calls to this proxy are delegated. If
    `proxyType()` returns `1`, ERC-897 dictates that this address MUST not
    change.

    @return The current address where calls to this proxy are delegated.
  */
  function implementation() public override view returns (address) {
    return target;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

error ImplementationIsNotSet();

/**
  @title A basic call-delegating proxy contract which is compliant with the
    current draft version of ERC-897.
  @author Facu Spagnuolo, OpenZeppelin
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by OpenZeppelin, then used by
  Project Wyvern (https://github.com/ProjectWyvern/) where it currently enjoys
  great success as a component of the OpenSea exchange system. It has been
  modified to support a more modern version of Solidity with associated best
  practices. The documentation has also been improved to provide more clarity.

  July 19th, 2021.
*/
abstract contract DelegateProxy {

  /**
    The ERC-897 specification seeks to standardize a system of proxy types.

    @return proxyTypeId The type of this proxy. A return value of `1` indicates that this is
      a strictly-forwarding proxy pointed to an unchanging address. A return
      value of `2` indicates that this proxy is upgradeable. The implementation
      address may change at any time based on some arbitrary external logic.
  */
  function proxyType() external virtual pure returns (uint256 proxyTypeId);

  /**
    Return the current address where all calls to this proxy are delegated. If
    `proxyType()` returns `1`, ERC-897 dictates that this address MUST not
    change.

    @return The current address where calls to this proxy are delegated.
  */
  function implementation() public virtual view returns (address);

  /**
    This payable fallback function exists to automatically delegate all calls to
    this proxy to the contract specified from `implementation()`. Anything
    returned from the delegated call will also be returned here.
  */
  fallback() external virtual payable {
    address target = implementation();
    if(target == address(0))
        revert ImplementationIsNotSet();

    // Perform the actual call delegation using Yul.
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      let result := delegatecall(gas(), target, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./TokenRecipient.sol";
import "../interfaces/IProxyRegistry.sol";

error ProxyAlreadyInitialized();
error ProxyMayInitializedOnce();
error AssertedCallDidntSucceed();

/**
  @title An ownable call-delegating proxy which can receive tokens and only make
    calls against contracts that have been approved by a `ProxyRegistry`.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the primary exchange contract for OpenSea. It has been modified
  to support a more modern version of Solidity with associated best practices.
  The documentation has also been improved to provide more clarity.
*/
contract AuthenticatedProxy is Ownable, TokenRecipient {

  /// Whether or not this proxy is initialized. It may only be initialized once.
  bool public initialized = false;

  /// The associated `ProxyRegistry` contract with authentication information.
  address public registry;

  /// Whether or not access has been revoked.
  bool public revoked;

  /**
    An enumerable type for selecting the method by which we would like to
    perform a call in the `proxy` function.

    @param Call This call type specifies that we perform a direct call.
    @param DelegateCall This call type can be used to automatically transfer
      multiple assets owned by the proxy contract with one order.
  */
  enum CallType {
    Call,
    DelegateCall
  }

  /**
    An event fired when the proxy contract's access is revoked or unrevoked.

    @param revoked The status of the revocation call; true if access is
    revoked and false if access is unrevoked.
  */
  event Revoked(bool revoked);

  /**
    Initialize this authenticated proxy for its owner against a specified
    `ProxyRegistry`. The registry controls the eligible targets.

    @param _registry The registry to create this proxy against.
  */
  function initialize(address _registry) external {
    if (initialized)
      revert ProxyMayInitializedOnce();
    initialized = true;
    registry = _registry;
  }

  /**
    Allow the owner of this proxy to set the revocation flag. This permits them
    to revoke access from the associated `ProxyRegistry` if needed.
  */
  function setRevoke(bool revoke) external onlyOwner {
    revoked = revoke;
    emit Revoked(revoke);
  }

  /**
    Trigger this proxy to call a specific address with the provided data. The
    proxy may perform a direct or a delegate call. This proxy can only be called
    by the owner, or on behalf of the owner by a caller authorized by the
    registry. Unless the user has revoked access to the registry, that is.

    @param _target The target address to make the call to.
    @param _type The type of call to make: direct or delegated.
    @param _data The call data to send to `_target`.
    @return Whether or not the call succeeded.
  */
  function call(address _target, CallType _type, bytes calldata _data) public
    returns (bool) {
    if(_msgSender() != owner()
      && (revoked || !IProxyRegistry(registry).authorizedCallers(_msgSender())))
      revert NonAuthorizedCaller();

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

  /**
    Trigger this proxy to call a specific address with the provided data and
    require success. Otherwise identical to `call()`.

    @param _target The target address to make the call to.
    @param _type The type of call to make: direct or delegated.
    @param _data The call data to send to `_target`.
  */
  function callAssert(address _target, CallType _type, bytes calldata _data)
    external {
    if (call(_target, _type, _data))
      revert AssertedCallDidntSucceed();
  }
}

/*
  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.
  Separated into a library for convenience, all the functions are inlined.
*/

pragma solidity ^0.8.11;

/**
 * @title SaleKindInterface
 * @author Project Wyvern Developers
 */
library Sales {

    /**
     * Side: buy or sell.
     */
    enum Side { Buy, Sell }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction, DecreasingPrice. 
     * English auctions cannot be supported without stronger escrow guarantees.
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
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function _canSettleOrder(uint listingTime, uint expirationTime)
        view
        internal
        returns (bool)
    {
        return (listingTime < block.timestamp) && (expirationTime == 0 || block.timestamp < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price and time data
     * @param listingTime Order listing time
     */
    function _calculateFinalPrice(SaleKind saleKind, uint basePrice, uint[] memory extra, uint listingTime)
        view
        internal
        returns (uint finalPrice)
    {
        if (saleKind == SaleKind.DecreasingPrice) {
            if(block.timestamp <= listingTime + 59) {
                return basePrice;
            }
            if(block.timestamp >= extra[1]) {
                return extra[0];
            }
            uint res = (basePrice - extra[0])*((extra[1] - block.timestamp) / 60)/((extra[1] - listingTime)/60); // priceMaxRange * minutesPassed / totalListingMinutes
            return extra[0] + res;
        } else {
            return basePrice;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.8;

error NonAuthorizedCaller();

/**
 * @title ProxyRegistry Interface
 * @author Rostislav Khlebnikov
 */
interface IProxyRegistry {

    /// returns address of  current valid implementation of delegate proxy.
    function delegateProxyImplementation() external view returns (address);

    /**
        Returns address of a proxy which was registered for the user address before listing NFTs.
        @param owner address of NFTs lister.
     */
    function proxies(address owner) external view returns (address);

    /**
        Returns true if `caller` to the proxy registry is eligible and registered.
        @param caller address of the caller.
     */
    function authorizedCallers(address caller) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error TransferFailed();

/**
  @title A contract which may receive Ether and tokens.
  @author Protinam, Project Wyvern
  @author Tim Clancy

  This contract was originally developed by Project Wyvern
  (https://github.com/ProjectWyvern/) where it currently enjoys great success as
  a component of the exchange used by OpenSea. It has been modified to support a
  more modern version of Solidity with associated best practices. The
  documentation has also been improved to provide more clarity.
*/
contract TokenRecipient is Context {

  /**
    An event emitted when this contract receives Ether.

    @param sender The sender of the received Ether.
    @param amount The amount of Ether received.
  */
  event ReceivedEther(address indexed sender, uint256 amount);

  /**
    An event emitted when this contract receives ERC-20 tokens.

    @param from The sender of the tokens.
    @param value The amount of token received.
    @param token The address of the token received.
    @param extraData Any extra data associated with the transfer.
  */
  event ReceivedTokens(address indexed from, uint256 value,
    address indexed token, bytes extraData);

  /**
    Receive tokens from address `_from` and emit an event.

    @param _from The address from which tokens are transferred.
    @param _value The amount of tokens to transfer.
    @param _token The address of the tokens to receive.
    @param _extraData Any additional data with this token receipt to emit.
  */
  function receiveApproval(address _from, uint256 _value, address _token,
    bytes calldata _extraData) external {
    bool transferSuccess = IERC20(_token).transferFrom(_from, address(this),
      _value);
    if (!transferSuccess)
      revert TransferFailed();
    emit ReceivedTokens(_from, _value, _token, _extraData);
  }

  /**
    Receive Ether and emit an event.
  */
  receive() external virtual payable {
    emit ReceivedEther(_msgSender(), msg.value);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import {PermitControl} from "../access/PermitControl.sol";

error PlatformFeeRecipientCannotBeZero();
error ProtocolFeeRecipientCannotBeZero();

abstract contract BaseFeeManager is PermitControl {

    /**  The public identifier for the right to set new items. */
    bytes32 public constant FEE_CONFIG = keccak256("FEE_CONFIG");

    /**
        Emmited when platform fee amount is changed.
        @param oldPlatformFeeRecipient previous recipient address of platform fees.
        @param newPlatformFeeRecipient new recipient address of platform fees.
        @param oldPlatformFeePercent previous amount of platform fees..
        @param newPlatformFeePercent new amount of platform fees. 
     */
    event PlatformFeeChanged(
        address oldPlatformFeeRecipient,
        address newPlatformFeeRecipient,
        uint256 oldPlatformFeePercent,
        uint256 newPlatformFeePercent
    );

    /**
        Emmited when protocol  fee config is changed.
        @param oldProtocolFeeRecipient previous recipient address of protocol fees.
        @param newProtocolFeeRecipient new recipient address of protocol fees.
        @param oldProtocolFeePercent previous amount of protocol fees..
        @param newProtocolFeePercent new amount of protocol fees. 
     */
    event ProtocolFeeChanged(
        address oldProtocolFeeRecipient,
        address newProtocolFeeRecipient,
        uint256 oldProtocolFeePercent,
        uint256 newProtocolFeePercent
    );

     /** Plaftorm fee configuration - recipient address take left 160 bit and fee percentage takes right 96 bits */
    uint256 platformFee;
    /** Protocol fee configuration - recipient address take left 160 bit and fee percentage takes right 96 bits */
    uint256 protocolFee;

    constructor(
        address platformFeeRecipient,
        uint96 platformFeePercent,
        address protocolFeeRecipient,
        uint96 protocolFeePercent
    ){
        unchecked {
            platformFee =
                (uint256(uint160(platformFeeRecipient)) << 96) +
                uint256(platformFeePercent);
            protocolFee =
                (uint256(uint160(protocolFeeRecipient)) << 96) +
                uint256(protocolFeePercent);
        }
    }

    /**
        @dev Changes amount of fees for the platform
        @param newPlatformFeeRecipient new platform fee recipient.
        @param newPlatformFeePercent new amount of fees in percent, e.g. 2% = 200.
     */
    function changePlatformFees(
        address newPlatformFeeRecipient,
        uint256 newPlatformFeePercent
    ) external hasValidPermit(UNIVERSAL, FEE_CONFIG) {
        if (newPlatformFeeRecipient == address(0))
            revert PlatformFeeRecipientCannotBeZero();

        uint256 oldPlatformFee = platformFee;
        unchecked {
            platformFee =
                (uint256(uint160(newPlatformFeeRecipient)) << 96) +
                uint256(newPlatformFeePercent);
        }
        emit PlatformFeeChanged(
            address(uint160(oldPlatformFee >> 96)),
            newPlatformFeeRecipient,
            uint256(uint96(oldPlatformFee)),
            newPlatformFeePercent
        );
    }

    /**
        @dev Changes amount of fees for the platform
        @param newProtocolFeeRecipient new protocol fee recipient.
        @param newProtocolFeePercent new amount of fees in percent, e.g. 2% = 200.
     */
    function changeProtocolFees(
        address newProtocolFeeRecipient,
        uint256 newProtocolFeePercent
    ) external hasValidPermit(UNIVERSAL, FEE_CONFIG) {
        if (newProtocolFeeRecipient == address(0))
            revert ProtocolFeeRecipientCannotBeZero();

        uint256 oldProtocolFee = platformFee;
        unchecked {
            protocolFee =
                (uint256(uint160(newProtocolFeeRecipient)) << 96) +
                uint256(newProtocolFeePercent);
        }

        emit ProtocolFeeChanged(
            address(uint160(oldProtocolFee >> 96)),
            newProtocolFeeRecipient,
            uint256(uint96(oldProtocolFee)),
            newProtocolFeePercent
        );
    }

    /**
        Returns current platform fee config.
     */
    function currentPlatformFee() public view returns (address, uint256) {
        uint256 fee = platformFee;
        return (address(uint160(fee >> 96)), uint256(uint96(fee)));
    }

    /**
        Returns current protocol fee config.
     */
    function currentProtocolFee() public view returns (address, uint256) {
        uint256 fee = protocolFee;
        return (address(uint160(fee >> 96)), uint256(uint96(fee)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

error InvalidSignatureLength();

library Signature {
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

    function unchecked_recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return ecrecover(hash, v, r, s);
    }

    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert InvalidSignatureLength();
        }
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return ecrecover(hash, v, r, s);
    }
}

pragma solidity ^0.8.8;

abstract contract EIP712 {

    struct EIP712Domain {
        string  name;
        string  version;
        uint256 chainId;
        address verifyingContract;
    }

    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 immutable public DOMAIN_SEPARATOR;
    
    constructor(string memory name, string memory version){
        uint chainId_;
        assembly{
            chainId_ := chainid()
        }
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name              : name,
            version           : version,
            chainId           : chainId_,
            verifyingContract : address(this)
        }));
    }

    function hash(EIP712Domain memory eip712Domain)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(eip712Domain.name)),
            keccak256(bytes(eip712Domain.version)),
            eip712Domain.chainId,
            eip712Domain.verifyingContract
        ));
    }

    function parseSignature(bytes memory signature)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return(v,r,s);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
  @title An advanced permission-management contract.
  @author Tim Clancy

  This contract allows for a contract owner to delegate specific rights to
  external addresses. Additionally, these rights can be gated behind certain
  sets of circumstances and granted expiration times. This is useful for some
  more finely-grained access control in contracts.

  The owner of this contract is always a fully-permissioned super-administrator.

  August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
  using Address for address;

  /// A special reserved constant for representing no rights.
  bytes32 public constant ZERO_RIGHT = hex"00000000000000000000000000000000";

  /// A special constant specifying the unique, universal-rights circumstance.
  bytes32 public constant UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

  /*
    A special constant specifying the unique manager right. This right allows an
    address to freely-manipulate the `managedRight` mapping.
  **/
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
  mapping( address => mapping( bytes32 => mapping( bytes32 => uint256 )))
    public permissions;

  /**
    An additional mapping of managed rights to manager rights. This mapping
    represents the administrator relationship that various rights have with one
    another. An address with a manager right may freely set permits for that
    manager right's managed rights. Each right may be managed by only one other
    right.
  */
  mapping( bytes32 => bytes32 ) public managerRight;

  /**
    An event emitted when an address has a permit updated. This event captures,
    through its various parameter combinations, the cases of granting a permit,
    updating the expiration time of a permit, or revoking a permit.

    @param updator The address which has updated the permit.
    @param updatee The address whose permit was updated.
    @param circumstance The circumstance wherein the permit was updated.
    @param role The role which was updated.
    @param expirationTime The time when the permit expires.
  */
  event PermitUpdated(
    address indexed updator,
    address indexed updatee,
    bytes32 circumstance,
    bytes32 indexed role,
    uint256 expirationTime
  );

//   /**
//     A version of PermitUpdated for work with setPermits() function.
    
//     @param updator The address which has updated the permit.
//     @param updatees The addresses whose permit were updated.
//     @param circumstances The circumstances wherein the permits were updated.
//     @param roles The roles which were updated.
//     @param expirationTimes The times when the permits expire.
//   */
//   event PermitsUpdated(
//     address indexed updator,
//     address[] indexed updatees,
//     bytes32[] circumstances,
//     bytes32[] indexed roles,
//     uint256[] expirationTimes
//   );

  /**
    An event emitted when a management relationship in `managerRight` is
    updated. This event captures adding and revoking management permissions via
    observing the update history of the `managerRight` value.

    @param manager The address of the manager performing this update.
    @param managedRight The right which had its manager updated.
    @param managerRight The new manager right which was updated to.
  */
  event ManagementUpdated(
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
  modifier hasValidPermit(
    bytes32 _circumstance,
    bytes32 _right
  ) {
    require(_msgSender() == owner()
      || hasRight(_msgSender(), _circumstance, _right),
      "P1");
    _;
  }

  /**
    Return a version number for this contract's interface.
  */
  function version() external virtual pure returns (uint256) {
    return 1;
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
  function hasRightUntil(
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
  function hasRight(
    address _address,
    bytes32 _circumstance,
    bytes32 _right
  ) public view returns (bool) {
    return permissions[_address][_circumstance][_right] > block.timestamp;
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
  function setPermit(
    address _address,
    bytes32 _circumstance,
    bytes32 _right,
    uint256 _expirationTime
  ) public virtual hasValidPermit(UNIVERSAL, managerRight[_right]) {
    require(_right != ZERO_RIGHT,
      "P2");
    permissions[_address][_circumstance][_right] = _expirationTime;
    emit PermitUpdated(_msgSender(), _address, _circumstance, _right,
      _expirationTime);
  }

//   /**
//     Version of setPermit() that works with multiple addresses in one transaction.

//     @param _addresses The array of addresses to assign the specified `_right` to.
//     @param _circumstances The array of circumstances in which the `_right` is 
//                           valid.
//     @param _rights The array of specific rights to assign.
//     @param _expirationTimes The array of times when the `_rights` expires for 
//                             the provided _circumstance`.
//   */
//   function setPermits(
//     address[] memory _addresses,
//     bytes32[] memory _circumstances, 
//     bytes32[] memory _rights, 
//     uint256[] memory _expirationTimes
//   ) public virtual {
//     require((_addresses.length == _circumstances.length)
//              && (_circumstances.length == _rights.length)
//              && (_rights.length == _expirationTimes.length),
//              "leghts of input arrays are not equal"
//     );
//     bytes32 lastRight;
//     for(uint i = 0; i < _rights.length; i++) {
//       if (lastRight != _rights[i] || (i == 0)) { 
//         require(_msgSender() == owner() || hasRight(_msgSender(), _circumstances[i], _rights[i]), "P1");
//         require(_rights[i] != ZERO_RIGHT, "P2");
//         lastRight = _rights[i];
//       }
//       permissions[_addresses[i]][_circumstances[i]][_rights[i]] = _expirationTimes[i];
//     }
//     emit PermitsUpdated(
//       _msgSender(), 
//       _addresses,
//       _circumstances,
//       _rights,
//       _expirationTimes
//     );
//   }

  /**
    Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
    specified `_managedRight`.

    @param _managedRight The right which is to have its manager set to
      `_managerRight`.
    @param _managerRight The right whose `UNIVERSAL` holders may manage
      `_managedRight`.
  */
  function setManagerRight(
    bytes32 _managedRight,
    bytes32 _managerRight
  ) external virtual hasValidPermit(UNIVERSAL, MANAGER) {
    require(_managedRight != ZERO_RIGHT,
      "P3");
    managerRight[_managedRight] = _managerRight;
    emit ManagementUpdated(_msgSender(), _managedRight, _managerRight);
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