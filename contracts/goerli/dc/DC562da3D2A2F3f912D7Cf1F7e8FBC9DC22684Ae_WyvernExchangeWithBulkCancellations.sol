// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "./exchange/Exchange.sol";

/**
 * @title WyvernExchange
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract WyvernExchangeWithBulkCancellations is Exchange {
    // string public constant CODENAME = "Bulk Smash";

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     */
    constructor (ProxyRegistry registryAddress, TokenTransferProxy tokenTransferProxyAddress) {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
    }
}

/*
  
  Exchange contract. This is an outer contract with public or convenience functions and includes no state-modifying functions.
 
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./ExchangeCore.sol";

/**
 * @title Exchange
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract Exchange is ExchangeCore {
    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) external view returns (uint256) {
        return
            SaleKindInterface.calculateFinalPrice(
                side,
                saleKind,
                basePrice,
                extra,
                listingTime,
                expirationTime
            );
    }

    /**
     * @dev Hash an order, returning the canonical EIP-712 order hash without the domain separator
     * @param order Order to hash
     * @return hash Hash of order
     */
    function hashOrder_(
        Order calldata order
    ) external view returns (bytes32) {
        return
            hashOrder(
                order,
                nonces[order.maker]
            );
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign_(
        Order calldata order
    ) external view returns (bytes32) {
        return
            hashToSign(
                order,
                nonces[order.maker]
            );
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     * @return if order parameters are valid or not
     */
    function validateOrderParameters_(
        Order calldata order
    ) external view returns (bool) {
        return validateOrderParameters(order);
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param order Order to validate
     * @param v v of ECDSA signature
     * @param r r of ECDSA signature
     * @param s s of ECDSA signature
     */
    function validateOrder_(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        return
            validateOrder(
                hashToSign(order, nonces[order.maker]),
                order,
                Sig(v, r, s)
            );
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder_(
        Order calldata order,
        bool orderbookInclusionDesired
    ) external {
        return approveOrder(order, orderbookInclusionDesired);
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param v v of the signature
     * @param r r of the siganture
     * @param s s of the signature
     */
    function cancelOrder_(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        return cancelOrder(order, Sig(v, r, s), nonces[order.maker]);
    }

    /**
     * @dev Call cancelOrder, supplying a specific nonce — enables cancelling orders
            that were signed with nonces greater than the current nonce.
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param v v of the signature
     * @param r r of the siganture
     * @param s s of the signature
     * @param nonce Nonce to cancel
     */
    function cancelOrderWithNonce_(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce
    ) external {
        return cancelOrder(order, Sig(v, r, s), nonce);
    }

    /**
     * @dev Calculate the current price of an order
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice_(
        Order calldata order
    ) external view returns (uint256) {
        return
            calculateCurrentPrice(order);
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch_(
        Order calldata buy,
        Order calldata sell
    ) external view returns (bool) {
        return ordersCanMatch(buy, sell);
    }

    /**
     * @dev Return whether or not two orders' calldata specifications can match
     * @param buyCalldata Buy-side order calldata
     * @param buyReplacementPattern Buy-side order calldata replacement mask
     * @param sellCalldata Sell-side order calldata
     * @param sellReplacementPattern Sell-side order calldata replacement mask
     * @return Whether the orders' calldata can be matched
     */
    function orderCalldataCanMatch(
        bytes calldata buyCalldata,
        bytes calldata buyReplacementPattern,
        bytes calldata sellCalldata,
        bytes calldata sellReplacementPattern
    ) external pure returns (bool) {
        bytes memory _buyCalldata = buyCalldata;
        bytes memory _sellCalldata = sellCalldata;
        if (buyReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                _buyCalldata,
                _sellCalldata,
                buyReplacementPattern
            );
        }
        if (sellReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                _sellCalldata,
                _buyCalldata,
                sellReplacementPattern
            );
        }
        return ArrayUtils.arrayEq(_buyCalldata, _sellCalldata);
    }

    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice_(
        Order calldata buy,
        Order calldata sell
    ) external view returns (uint256) {
        return calculateMatchPrice(buy, sell);
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @param vs vs of orders
     * @param rssMetadata rss of Orders
     */
    function atomicMatch_(
        Order calldata buy,
        Order calldata sell,
        uint8[2] calldata vs,
        bytes32[5] calldata rssMetadata
    ) external payable {
        return
            atomicMatch(
                buy,
                Sig(vs[0], rssMetadata[0], rssMetadata[1]),
                sell,
                Sig(vs[1], rssMetadata[2], rssMetadata[3]),
                rssMetadata[4]
            );
    }

    /**
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     The updated byte array (the parameter will be modified inplace)
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) public pure returns (bytes memory) {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }
}

/*

  Decentralized digital asset exchange. Supports any digital asset that can be represented on the Ethereum blockchain (i.e. - transferred in an Ethereum transaction or sequence of transactions).

  Let us suppose two agents interacting with a distributed ledger have utility functions preferencing certain states of that ledger over others.
  Aiming to maximize their utility, these agents may construct with their utility functions along with the present ledger state a mapping of state transitions (transactions) to marginal utilities.
  Any composite state transition with positive marginal utility for and enactable by the combined permissions of both agents thus is a mutually desirable trade, and the trustless 
  code execution provided by a distributed ledger renders the requisite atomicity trivial.

  Relative to this model, this instantiation makes two concessions to practicality:
  - State transition preferences are not matched directly but instead intermediated by a standard of tokenized value.
  - A small fee can be charged in WYV for order settlement in an amount configurable by the frontend hosting the orderbook.

  Solidity presently possesses neither a first-class functional typesystem nor runtime reflection (ABI encoding in Solidity), so we must be a bit clever in implementation and work at a lower level of abstraction than would be ideal.

  We elect to utilize the following structure for the initial version of the protocol:
  - Buy-side and sell-side orders each provide calldata (bytes) - for a sell-side order, the state transition for sale, for a buy-side order, the state transition to be bought.
    Along with the calldata, orders provide `replacementPattern`: a bytemask indicating which bytes of the calldata can be changed (e.g. NFT destination address).
    When a buy-side and sell-side order are matched, the desired calldatas are unified, masked with the bytemasks, and checked for agreement.
    This alone is enough to implement common simple state transitions, such as "transfer my CryptoKitty to any address" or "buy any of this kind of nonfungible token".
  - Orders (of either side) can optionally specify a static (no state modification) callback function, which receives configurable data along with the actual calldata as a parameter.
    Although it requires some encoding acrobatics, this allows for arbitrary transaction validation functions.
    For example, a buy-sider order could express the intent to buy any CryptoKitty with a particular set of characteristics (checked in the static call),
    or a sell-side order could express the intent to sell any of three ENS names, but not two others.
    Use of the EVM's STATICCALL opcode, added in Ethereum Metropolis, allows the static calldata to be safely specified separately and thus this kind of matching to happen correctly
    - that is to say, wherever the two (transaction => bool) functions intersect.

  Future protocol versions may improve upon this structure in capability or usability according to protocol user feedback demand, with upgrades enacted by the Wyvern DAO.
 
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../registry/ProxyRegistry.sol";
import "../registry/TokenTransferProxy.sol";
import "../registry/AuthenticatedProxy.sol";
import "../common/ArrayUtils.sol";
import "../common/ReentrancyGuarded.sol";
import "../common/meta-transactions/ContextMixin.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";
import "./SaleKindInterface.sol";
import { Errors } from "../libraries/Errors.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ExchangeCore
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract ExchangeCore is
    ReentrancyGuarded,
    Ownable,
    ContextMixin,
    NativeMetaTransaction
{
    /* User registry. */
    ProxyRegistry public registry;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    // Note: the domain separator is derived and verified in the constructor. */
    bytes32 public DOMAIN_SEPARATOR;

    string public constant NAME = "Wyvern Exchange Contract";
    string public constant VERSION = "2.3.1";

    // NOTE: these hashes are derived and verified in the constructor.
    bytes32 private constant _EIP_712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _NAME_HASH =
        0x9a2ed463836165738cfa54208ff6e7847fd08cbaac309aac057086cb0a144d13;
    bytes32 private constant _VERSION_HASH =
        0xa8b0a8837a56ea69398e77c1bedb65d43e1b4f9aecb58f24aaef3c7279227fd1;
    bytes32 private constant _ORDER_TYPEHASH =
        0x1f2ea8eb0d151b283bbdafa24fdb870619cadf006c2b53f22aa3a56c05756f8e;

    bytes4 private constant _EIP_1271_MAGIC_VALUE = 0x1626ba7e;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    /* Note that the maker's nonce at the time of approval **plus one** is stored in the mapping. */
    mapping(bytes32 => uint256) private _approvedOrdersByNonce;

    /* Track per-maker nonces that can be incremented by the maker to cancel orders in bulk. */
    // The current nonce for the maker represents the only valid nonce that can be signed by the maker
    // If a signature was signed with a nonce that's different from the one stored in nonces, it
    // will fail validation.
    mapping(address => uint256) public nonces;

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    /* An order on the exchange. */
    struct Order {
        /* Exchange address, intended as a versioning mechanism. */
        address exchange;
        /* Order maker address. */
        address maker;
        /* Order taker address, if specified. */
        address taker;
        /* Maker relayer fee of the order, unused for taker order. */
        uint256 makerRelayerFee;
        /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
        uint256 takerRelayerFee;
        /* Taker Cashback of the order. */
        uint256 takerCashbackFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Side (buy/sell). */
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes data;
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Extra data for NFT royalty details. */
        bytes royaltyData;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
        /* NOTE: uint nonce is an additional component of the order but is read from storage */
    }

    event OrderApprovedPartOne(
        bytes32 indexed hash,
        address exchange,
        address indexed maker,
        address taker,
        uint256 makerRelayerFee,
        uint256 takerRelayerFee,
        address indexed feeRecipient,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        address target
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        AuthenticatedProxy.HowToCall howToCall,
        bytes data,
        bytes replacementPattern,
        bytes royaltyData,
        address staticTarget,
        bytes staticExtradata,
        address paymentToken,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime,
        uint256 salt,
        bool orderbookInclusionDesired
    );
    event OrderCancelled(bytes32 indexed hash);
    event OrdersMatched(
        bytes32 buyHash,
        bytes32 sellHash,
        address indexed maker,
        address indexed taker,
        uint256 price,
        bytes32 indexed metadata
    );
    event NonceIncremented(address indexed maker, uint256 newNonce);

    constructor() {
        DOMAIN_SEPARATOR = _deriveDomainSeparator();
        require(
            keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            ) == _EIP_712_DOMAIN_TYPEHASH,
            Errors.DOMAIN_HASH_DID_NOT_MATCH
        );
        require(
            keccak256(bytes(NAME)) == _NAME_HASH,
            Errors.NAME_HASH_DID_NOT_MATCH
        );
        require(
            keccak256(bytes(VERSION)) == _VERSION_HASH,
            Errors.VERSION_HASH_DID_NOT_MATCH
        );
        require(
            keccak256(
                "Order(address exchange,address maker,address taker,uint256 makerRelayerFee,uint256 takerRelayerFee,uint256 takerCashbackFee,address feeRecipient,uint8 side,uint8 saleKind,address target,uint8 howToCall,bytes data,bytes replacementPattern,bytes royaltyData,address staticTarget,bytes staticExtradata,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt,uint256 nonce)"
            ) == _ORDER_TYPEHASH,
            Errors.ORDER_HASH_DID_NOT_MATCH
        );
        _initializeEIP712();
    }

    /**
     * Increment a particular maker's nonce, thereby invalidating all orders that were not signed
     * with the original nonce.
     */
    function incrementNonce() external {
        uint256 newNonce = ++nonces[_msgSender()];
        emit NonceIncremented(_msgSender(), newNonce);
    }

    /**
     * @dev Return blockchain's chainID.
     * @return ChainID for current blockchain.
     */
    function getChainID() public view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param data Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return result The result of the call (success or failure)
     */
    function staticCall(
        address target,
        bytes memory data,
        bytes memory extradata
    ) public view returns (bool result) {
        bytes memory combined = new bytes(data.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, data);
        assembly {
            result := staticcall(
                gas(),
                target,
                add(combined, 0x20),
                mload(combined),
                mload(0x40),
                0
            )
        }
        return result;
    }

    /**
     * @dev Determine if an order has been approved. Note that the order may not still
     * be valid in cases where the maker's nonce has been incremented.
     * @param hash Hash of the order
     * @return approved whether or not the order was approved.
     */
    function approvedOrders(bytes32 hash) public view returns (bool approved) {
        return _approvedOrdersByNonce[hash] != 0;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of tokens to transfer
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (from == address(this)) {
                IERC20(token).transfer(to, amount);
            } else {
                require(
                    tokenTransferProxy.transferFrom(token, from, to, amount),
                    Errors.TRANSFER_NOT_SUCCESSFUL
                );
            }
        }
    }

    /**
     * @dev Hash an order, returning the canonical EIP-712 order hash without the domain separator
     * @param order Order to hash
     * @param nonce maker nonce to hash
     * @return hash Hash of order
     */
    function hashOrder(Order memory order, uint256 nonce)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work for entire object, stack size constraints. */
        bytes memory part1 = abi.encode(
            _ORDER_TYPEHASH,
            order.exchange,
            order.maker,
            order.taker,
            order.makerRelayerFee,
            order.takerRelayerFee
        );

        bytes memory part2 = abi.encode(
            order.takerCashbackFee,
            order.feeRecipient,
            order.side,
            order.saleKind,
            order.target
        );

        bytes memory part3 = abi.encode(
            order.howToCall,
            keccak256(order.data),
            keccak256(order.replacementPattern),
            keccak256(order.royaltyData),
            order.staticTarget,
            keccak256(order.staticExtradata),
            order.paymentToken,
            order.basePrice
        );

        bytes memory part4 = abi.encode(
            order.extra,
            order.listingTime,
            order.expirationTime,
            order.salt,
            nonce
        );

        hash = keccak256(abi.encodePacked(part1, part2, part3, part4));
        return hash;
    }

    /**
     * @dev Hash an order, returning the hash that a client must sign via EIP-712 including the message prefix
     * @param order Order to hash
     * @param nonce Nonce to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order, uint256 nonce)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    hashOrder(order, nonce)
                )
            );
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param nonce Nonce to validate
     * @param sig ECDSA signature
     */
    function requireValidOrder(
        Order memory order,
        Sig memory sig,
        uint256 nonce
    ) internal view returns (bytes32) {
        bytes32 hash = hashToSign(order, nonce);
        require(validateOrder(hash, order, sig), Errors.INVALID_ORDER);
        return hash;
    }

    /**
     * @dev Validate order parameters (does *not* check signature validity)
     * @param order Order to validate
     */
    function validateOrderParameters(Order memory order)
        internal
        view
        returns (bool)
    {
        /* Order must be targeted at this protocol version (this Exchange contract). */
        if (order.exchange != address(this)) {
            return false;
        }

        /* Order must have a maker. */
        if (order.maker == address(0)) {
            return false;
        }

        /* Order must possess valid sale kind parameter combination. */
        if (
            !SaleKindInterface.validateParameters(
                order.saleKind,
                order.expirationTime
            )
        ) {
            return false;
        }

        return true;
    }

    /**
     * @dev Validate a provided previously approved / signed order, hash, and signature.
     * @param hash Order hash (already calculated, passed to avoid recalculation)
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function validateOrder(
        bytes32 hash,
        Order memory order,
        Sig memory sig
    ) internal view returns (bool) {
        /* Not done in an if-conditional to prevent unnecessary ecrecover evaluation, which seems to happen even though it should short-circuit. */

        /* Order must have valid parameters. */
        if (!validateOrderParameters(order)) {
            return false;
        }

        /* Order must have not been canceled or already filled. */
        if (cancelledOrFinalized[hash]) {
            return false;
        }

        /* Return true if order has been previously approved with the current nonce */
        uint256 approvedOrderNoncePlusOne = _approvedOrdersByNonce[hash];
        if (approvedOrderNoncePlusOne != 0) {
            return approvedOrderNoncePlusOne == nonces[order.maker] + 1;
        }

        /* Prevent signature malleability and non-standard v values. */
        if (
            uint256(sig.s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            return false;
        }
        if (sig.v != 27 && sig.v != 28) {
            return false;
        }

        /* recover via ECDSA, signed by maker (already verified as non-zero). */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        /* fallback — attempt EIP-1271 isValidSignature check. */
        return _tryContractSignature(order.maker, hash, sig);
    }

    function _tryContractSignature(
        address orderMaker,
        bytes32 hash,
        Sig memory sig
    ) internal view returns (bool) {
        bytes memory isValidSignatureData = abi.encodeWithSelector(
            _EIP_1271_MAGIC_VALUE,
            hash,
            abi.encodePacked(sig.r, sig.s, sig.v)
        );

        bytes4 result;

        // NOTE: solidity 0.4.x does not support STATICCALL outside of assembly
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

        return result == _EIP_1271_MAGIC_VALUE;
    }

    /**
     * @dev Approve an order and optionally mark it for orderbook inclusion. Must be called by the maker of the order
     * @param order Order to approve
     * @param orderbookInclusionDesired Whether orderbook providers should include the order in their orderbooks
     */
    function approveOrder(Order memory order, bool orderbookInclusionDesired)
        internal
    {
        /* CHECKS */

        /* Assert sender is authorized to approve order. */
        require(_msgSender() == order.maker, Errors.CALLER_IS_NOT_MAKER);

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order, nonces[order.maker]);

        /* Assert order has not already been approved. */
        require(
            _approvedOrdersByNonce[hash] == 0,
            Errors.ORDER_ALREADY_APPROVED
        );

        /* EFFECTS */

        /* Mark order as approved. */
        _approvedOrdersByNonce[hash] = nonces[order.maker] + 1;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(
                hash,
                order.exchange,
                order.maker,
                order.taker,
                order.makerRelayerFee,
                order.takerRelayerFee,
                order.feeRecipient,
                order.side,
                order.saleKind,
                order.target
            );
        }
        {
            emit OrderApprovedPartTwo(
                hash,
                order.howToCall,
                order.data,
                order.replacementPattern,
                order.royaltyData,
                order.staticTarget,
                order.staticExtradata,
                order.paymentToken,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime,
                order.salt,
                orderbookInclusionDesired
            );
        }
    }

    /**
     * @dev Cancel an order, preventing it from being matched. Must be called by the maker of the order
     * @param order Order to cancel
     * @param nonce Nonce to cancel
     * @param sig ECDSA signature
     */
    function cancelOrder(
        Order memory order,
        Sig memory sig,
        uint256 nonce
    ) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig, nonce);

        /* Assert sender is authorized to cancel order. */
        require(_msgSender() == order.maker, Errors.CALLER_IS_NOT_MAKER);

        /* EFFECTS */

        /* Mark order as cancelled, preventing it from being matched. */
        cancelledOrFinalized[hash] = true;

        /* Log cancel event. */
        emit OrderCancelled(hash);
    }

    /**
     * @dev Calculate the current price of an order (convenience function)
     * @param order Order to calculate the price of
     * @return The current price of the order
     */
    function calculateCurrentPrice(Order memory order)
        internal
        view
        returns (uint256)
    {
        return
            SaleKindInterface.calculateFinalPrice(
                order.side,
                order.saleKind,
                order.basePrice,
                order.extra,
                order.listingTime,
                order.expirationTime
            );
    }

    /**
     * @dev Calculate the price two orders would match at, if in fact they would match (otherwise fail)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Match price
     */
    function calculateMatchPrice(Order memory buy, Order memory sell)
        internal
        view
        returns (uint256)
    {
        /* Calculate sell price. */
        uint256 sellPrice = SaleKindInterface.calculateFinalPrice(
            sell.side,
            sell.saleKind,
            sell.basePrice,
            sell.extra,
            sell.listingTime,
            sell.expirationTime
        );

        /* Calculate buy price. */
        uint256 buyPrice = SaleKindInterface.calculateFinalPrice(
            buy.side,
            buy.saleKind,
            buy.basePrice,
            buy.extra,
            buy.listingTime,
            buy.expirationTime
        );

        /* Require price cross. */
        require(buyPrice >= sellPrice, Errors.INVALID_PRICE);

        /* Maker/taker priority. */
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

    /**
     * @dev Calculates and transfer the royality 
     * @param sell Sell-side order
     * @return Royality amount
     */
    function transferRoyalty(Order memory sell, uint256 price) internal returns (uint256) {
        if (sell.royaltyData.length > 0) {
            /* Retrieving NFT details */
            /* Retreives the position for nftAddress and tokenID position from the royaltyData */
            (uint256[] memory nftPosition, uint256[] memory tokenPosition) = abi
                .decode(sell.royaltyData, (uint256[], uint256[]));
            require(
                nftPosition.length == tokenPosition.length,
                Errors.ROYALTY_DATA_LENGTH_NOT_EQUAL
            );
            // Arrays to store NFTAddress and TokenIDs
            address[] memory nftAddresses = new address[](nftPosition.length);
            uint256[] memory tokenIDs = new uint256[](tokenPosition.length);

            for (uint256 i = 0; i < nftPosition.length; i++) {
                uint256 n = nftPosition[i] / 2 - 1;
                uint256 t = tokenPosition[i] / 2 - 1;
                bytes memory nft = new bytes(32);
                bytes memory token = new bytes(32);
                for (uint256 j = 0; j < 32; j++) {
                    nft[j] = sell.data[n];
                    token[j] = sell.data[t];
                    n++;
                    t++;
                }
                // If salekind is English Auction then NFTAddress can be retrieved from the sell object, else we need to decode it from data.
                if (
                    sell.saleKind == SaleKindInterface.SaleKind.EnglishAuction
                ) {
                    nftAddresses[i] = sell.target;
                } else {
                    address nftAddress = abi.decode(nft, (address));
                    nftAddresses[i] = nftAddress;
                }
                uint256 tokenID = abi.decode(token, (uint256));
                tokenIDs[i] = tokenID;
            }
            uint256 totalRoyalty = 0;
            uint256 sellPrice = price / nftAddresses.length;
            for (uint256 i = 0; i < nftAddresses.length; i++) {
                // checks if NFT supports EIP-2981 or not
                if (
                    IERC165(nftAddresses[i]).supportsInterface(
                        type(IERC2981).interfaceId
                    )
                ) {
                    (address reciever, uint256 royaltyAmount) = IERC2981(
                        nftAddresses[i]
                    ).royaltyInfo(tokenIDs[i], sellPrice);
                    totalRoyalty += royaltyAmount;
                    if(sell.paymentToken == address(0)){
                        (bool success, ) = payable(reciever).call{value: royaltyAmount}("");
                        require(success, Errors.ROYALTY_TRANSFER_FAILED);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            reciever,
                            royaltyAmount
                        );
                    }
                }
            }
            return totalRoyalty;
        }
        return 0;
    }

    /**
     * @dev Execute all ERC20 token / Ether transfers associated with an order match (fees and buyer => seller transfer)
     * @param buy Buy-side order
     * @param sell Sell-side order
     */
    function executeFundsTransfer(Order memory buy, Order memory sell)
        internal
        returns (uint256)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0, Errors.VALUE_IS_NOT_ZERO);
        }

        /* Calculate match price. */
        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        uint256 totalFees = 0;

        uint256 cashback = (sell.takerCashbackFee * price) /
            INVERSE_BASIS_POINT;

        /* transfer royalty to the maker */
        receiveAmount -= transferRoyalty(sell, price);

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {
            /* Sell-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(
                sell.takerRelayerFee <= buy.takerRelayerFee,
                Errors.INVALID_BUY_TAKER_RELAYER_FEE
            );

            /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */

            if (sell.makerRelayerFee > 0) {
                uint256 makerRelayerFee = (sell.makerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += makerRelayerFee;
                // if payment token is ether then the recieve amount is updated. If payment token is any other Token then we transfer the fees directly to this contract.
                if (sell.paymentToken == address(0)) {
                    receiveAmount = receiveAmount - makerRelayerFee;
                } else {
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        address(this),
                        makerRelayerFee
                    );
                }
            }

            if (sell.takerRelayerFee > 0) {
                uint256 takerRelayerFee = (sell.takerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += takerRelayerFee;
                // if payment token is ether then the recieve amount is updated. If payment token is any other Token then we transfer the fees directly to this contract.
                if (sell.paymentToken == address(0)) {
                    requiredAmount = requiredAmount + takerRelayerFee;
                } else {
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        address(this),
                        takerRelayerFee
                    );
                }
            }
        } else {
            /* Buy-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(
                buy.takerRelayerFee <= sell.takerRelayerFee,
                Errors.INVALID_SELL_TAKER_RELAYER_FEE
            );
            /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
            require(
                sell.paymentToken != address(0),
                Errors.INVALID_SELL_PAYMENT_TOKEN
            );

            if (buy.makerRelayerFee > 0) {
                uint256 makerRelayerFee = (buy.makerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += makerRelayerFee;
                transferTokens(
                    sell.paymentToken,
                    buy.maker,
                    address(this),
                    makerRelayerFee
                );
            }

            if (buy.takerRelayerFee > 0) {
                uint256 takerRelayerFee = (buy.takerRelayerFee * price) /
                    INVERSE_BASIS_POINT;
                totalFees += takerRelayerFee;
                transferTokens(
                    sell.paymentToken,
                    sell.maker,
                    address(this),
                    takerRelayerFee
                );
            }
        }
        // Checks if the order is eligible for cashback or not.
        if (cashback > 0) {
            require(cashback <= totalFees, Errors.INVALID_CASHBACK_AMOUNT);
            // cashback is given from the totalfees so we are deducting the cashback from the totalFees.
            totalFees -= cashback;
            if (sell.paymentToken != address(0)) {
                transferTokens(
                    sell.paymentToken,
                    address(this),
                    buy.maker,
                    cashback
                );
            } else {
                (bool success, ) = payable(buy.maker).call{value: cashback}("");
                require(success, Errors.CASHBACK_FAILED);
            }
        }

        // transfers the totalFees to the feeRecipient 
        if (sell.paymentToken != address(0)) {
            if (sell.feeRecipient != address(0)) {
                transferTokens(
                    sell.paymentToken,
                    address(this),
                    sell.feeRecipient,
                    totalFees
                );
            } else {
                transferTokens(
                    sell.paymentToken,
                    address(this),
                    buy.feeRecipient,
                    totalFees
                );
            }
        } else {
            if (sell.feeRecipient != address(0)) {
                (bool success, ) = payable(sell.feeRecipient).call{
                    value: totalFees
                }("");
                require(success, Errors.FEE_FAILED);
            } else {
                (bool success, ) = payable(buy.feeRecipient).call{
                    value: totalFees
                }("");
                require(success, Errors.FEE_FAILED);
            }
        }
        // transfer the ether to the seller.
            if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount, Errors.NOT_ENOUGH_VALUE);
            (bool success, ) = payable(sell.maker).call{value: receiveAmount}("");
            require(success, Errors.ETHER_TRANSFER_NOT_SUCCESSFUL);
            /* Allow overshoot for variable-price auctions, refund difference. */
            uint256 diff = msg.value - requiredAmount;
            if (diff > 0) {
                (bool ret, ) = payable(buy.maker).call{value: diff}("");
                require(ret, Errors.ETHER_TRANSFER_NOT_SUCCESSFUL);
            }
        }

        /* This contract should never hold Ether, however, we cannot assert this, since it is impossible to prevent anyone from sending Ether e.g. with selfdestruct. */

        return price;
    }

    /**
     * @dev Return whether or not two orders can be matched with each other by basic parameters (does not check order signatures / calldata or perform static calls)
     * @param buy Buy-side order
     * @param sell Sell-side order
     * @return Whether or not the two orders can be matched
     */
    function ordersCanMatch(Order memory buy, Order memory sell)
        internal
        view
        returns (bool)
    {
        return (/* Must be opposite-side. */
        (buy.side == SaleKindInterface.Side.Buy &&
            sell.side == SaleKindInterface.Side.Sell) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.feeRecipient == address(0) &&
                buy.feeRecipient != address(0)) ||
                (sell.feeRecipient != address(0) &&
                    buy.feeRecipient == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(
                buy.listingTime,
                buy.expirationTime
            ) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(
                sell.listingTime,
                sell.expirationTime
            ));
    }

    /**
     * @dev Atomically match two orders, ensuring validity of the match, and execute all associated state transitions. Protected against reentrancy by a contract-global lock.
     * @param buy Buy-side order
     * @param buySig Buy-side order signature
     * @param sell Sell-side order
     * @param sellSig Sell-side order signature
     */
    function atomicMatch(
        Order memory buy,
        Sig memory buySig,
        Order memory sell,
        Sig memory sellSig,
        bytes32 metadata
    ) internal reentrancyGuard {
        /* CHECKS */

        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == _msgSender()) {
            require(
                validateOrderParameters(buy),
                Errors.INVALID_ORDER_PARAMETERS_BUY_ORDER
            );
        } else {
            buyHash = _requireValidOrderWithNonce(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == _msgSender()) {
            require(
                validateOrderParameters(sell),
                Errors.INVALID_ORDER_PARAMETERS_SELL_ORDER
            );
        } else {
            sellHash = _requireValidOrderWithNonce(sell, sellSig);
        }

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell), Errors.ORDERS_NOT_MATCHABLE);

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        require(sell.target.code.length > 0, Errors.TARGET_NOT_CONTRACT);

        /* Must match calldata after replacement, if specified. */
        if (buy.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                buy.data,
                sell.data,
                buy.replacementPattern
            );
        }
        if (sell.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                sell.data,
                buy.data,
                sell.replacementPattern
            );
        }
        require(
            ArrayUtils.arrayEq(buy.data, sell.data),
            Errors.DATA_NOT_MATCHED
        );

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        /* Proxy must exist. */
        require(
            address(delegateProxy) != address(0),
            Errors.PROXY_NOT_REGISTERED
        );

        /* Assert implementation. */
        require(
            delegateProxy.implementation() ==
                registry.delegateProxyImplementation(),
            Errors.INVALID_IMPLEMENTATION
        );

        /* Access the passthrough AuthenticatedProxy. */
        AuthenticatedProxy proxy = AuthenticatedProxy(address(delegateProxy));

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (_msgSender() != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (_msgSender() != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);

        /* Execute specified call through proxy. */
        require(
            proxy.proxy(sell.target, sell.howToCall, sell.data),
            Errors.PROXY_CALL_FAILED
        );

        /* Static calls are intentionally done after the effectful call so they can check resulting state. */

        /* Handle buy-side static call if specified. */
        if (buy.staticTarget != address(0)) {
            require(
                staticCall(buy.staticTarget, sell.data, buy.staticExtradata),
                Errors.BUY_STATIC_CALL_FAILED
            );
        }

        /* Handle sell-side static call if specified. */
        if (sell.staticTarget != address(0)) {
            require(
                staticCall(sell.staticTarget, sell.data, sell.staticExtradata),
                Errors.SELL_STATIC_CALL_FAILED
            );
        }

        /* Log match event. */
        emit OrdersMatched(
            buyHash,
            sellHash,
            sell.feeRecipient != address(0) ? sell.maker : buy.maker,
            sell.feeRecipient != address(0) ? buy.maker : sell.maker,
            price,
            metadata
        );
    }

    function _requireValidOrderWithNonce(Order memory order, Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        return requireValidOrder(order, sig, nonces[order.maker]);
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * @dev Derive the domain separator for EIP-712 signatures.
     * @return The domain separator.
     */
    function _deriveDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP_712_DOMAIN_TYPEHASH, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                    _NAME_HASH, // keccak256("Wyvern Exchange Contract")
                    _VERSION_HASH, // keccak256(bytes("2.3.1"))
                    getChainID(),
                    address(this)
                )
            );
    }
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

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.  
  
  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./OwnableDelegateProxy.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";

/**
 * @title ProxyRegistry
 * @author Wyvern Protocol Developers
 */
contract ProxyRegistry is ContextMixin, Ownable, NativeMetaTransaction {

    /* DelegateProxy implementation contract. Must be initialized. */
    address public delegateProxyImplementation;

    /* Authenticated proxies by user. */
    mapping(address => OwnableDelegateProxy) public proxies;

    /* Contracts pending access. */
    mapping(address => uint) public pending;

    /* Contracts allowed to call those proxies. */
    mapping(address => bool) public contracts;

    /* Delay period for adding an authenticated contract.
       This mitigates a particular class of potential attack on the Wyvern DAO (which owns this registry) - if at any point the value of assets held by proxy contracts exceeded the value of half the WYV supply (votes in the DAO),
       a malicious but rational attacker could buy half the Wyvern and grant themselves access to all the proxy contracts. A delay period renders this attack nonthreatening - given two weeks, if that happened, users would have
       plenty of time to notice and transfer their assets.
    */
    uint public DELAY_PERIOD = 2 weeks;


    constructor() {
        _initializeEIP712();
    }

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication (address addr)
        external
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0, "Contract is already allowed in registry, or pending");
        pending[addr] = block.timestamp;
    }

    /**
     * End the process to enable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication (address addr)
        external
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < block.timestamp), "Contract is no longer pending or has already been approved by registry");
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */    
    function revokeAuthentication (address addr)
        external
        onlyOwner
    {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy()
        external
        returns (OwnableDelegateProxy proxy)
    {
        return registerProxyFor(_msgSender());
    }

    /**
     * Register a proxy contract with this registry, overriding any existing proxy
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyOverride()
        external
        returns (OwnableDelegateProxy proxy)
    {
        proxy = new OwnableDelegateProxy(_msgSender(), delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", _msgSender(), address(this)));
        proxies[_msgSender()] = proxy;
        return proxy;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Can be called by any user
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxyFor(address user)
        public
        returns (OwnableDelegateProxy proxy)
    {
        require(proxies[user] == OwnableDelegateProxy(payable(0)), "User already has a proxy");
        proxy = new OwnableDelegateProxy(user, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", user, address(this)));
        proxies[user] = proxy;
        return proxy;
    }

    /**
     * Transfer access
     */
    function transferAccessTo(address from, address to)
        external
    {
        OwnableDelegateProxy proxy = proxies[from];

        /* CHECKS */
        require(OwnableDelegateProxy(payable(_msgSender())) == proxy, "Proxy transfer can only be called by the proxy");
        require(proxies[to] == OwnableDelegateProxy(payable(0)), "Proxy transfer has existing proxy as destination");

        /* EFFECTS */
        delete proxies[from];
        proxies[to] = proxy;
    }

    function _msgSender() internal view override returns (address sender) {
        return ContextMixin.msgSender();
    }
}

/*

  Token transfer proxy. Uses the authentication table of a ProxyRegistry contract to grant ERC20 `transferFrom` access.
  This means that users only need to authorize the proxy contract once for all future protocol versions.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./ProxyRegistry.sol";

contract TokenTransferProxy is Context {

    /* Authentication registry. */
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     *
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(address token, address from, address to, uint amount)
    public
    returns (bool)
    {
        require(registry.contracts(_msgSender()), "Callers ProxyRegistry should be true");
        return IERC20(token).transferFrom(from, to, amount);
    }

}

/* 

  Proxy contract to hold access to assets on behalf of a user (e.g. ERC20 approve) and execute calls under particular conditions.

*/

// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "./ProxyRegistry.sol";
import "./proxy/OwnedUpgradeabilityStorage.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";
import "../common/meta-transactions/ContextMixin.sol";

/**
 * @title AuthenticatedProxy
 * @author Wyvern Protocol Developers
 */
contract AuthenticatedProxy is
    ContextMixin,
    OwnedUpgradeabilityStorage,
    NativeMetaTransaction {

    /* Whether initialized. */
    bool initialized = false;

    /* Address which owns this proxy. */
    address public user;

    /* Associated registry with contract authentication information. */
    ProxyRegistry public registry;

    /* Whether access has been revoked. */
    bool public revoked;

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall { Call, DelegateCall }

    /* Event fired when the proxy access is revoked or unrevoked. */
    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     *
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize (address addrUser, ProxyRegistry addrRegistry)
        external
    {
        require(!initialized, "Authenticated proxy already initialized");
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
        _initializeEIP712();
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke)
        external
    {
        require(_msgSender() == user, "Authenticated proxy can only be revoked by its user");
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param data Calldata to send
     * @return result Result of the call (success or failure)
     */
    function proxy(address dest, HowToCall howToCall, bytes memory data)
        public
        returns (bool result)
    {
        require(_msgSender() == user || (!revoked && registry.contracts(_msgSender())), "Authenticated proxy can only be called by its user, or by a contract authorized by the registry as long as the user has not revoked access");
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     * 
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param data Calldata to send
     */
    function proxyAssert(address dest, HowToCall howToCall, bytes memory data)
        external
    {
        require(proxy(dest, howToCall, data), "Proxy assertion failed");
    }

    function _msgSender() internal view returns (address sender) {
        return ContextMixin.msgSender();
    }
}

/*

  Various functions for manipulating arrays in Solidity.
  This library is completely inlined and does not need to be deployed or linked.

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

/**
 * @title ArrayUtils
 * @author Project Wyvern Developers
 */
library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     The updated byte array (the parameter will be modified inplace)
     */
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        internal
        pure
    {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint words = array.length / 0x20;
        uint index = words * 0x20;
        assert(index / 0x20 == words);
        uint i;

        for (i = 0; i < words; i++) {
            /* Conceptually: array[i] = (!mask[i] && array[i]) || (mask[i] && desired[i]), bitwise in word chunks. */
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            /* This overlaps with bytes already set but is still more efficient than iterating through each of the remaining bytes individually. */
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(add(array, commonIndex), or(and(not(maskValue), mload(add(array, commonIndex))), and(maskValue, mload(add(desired, commonIndex)))))
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
               (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] = ((mask[i] ^ 0xff) & array[i]) | (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(a) == keccak256(b);
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint index, bytes memory source)
        internal
        pure
        returns (uint)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for { } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location
     *
     * @param index Memory location
     * @param source Address to write
     * @return End memory index
     */
    function unsafeWriteAddress(uint index, address source)
        internal
        pure
        returns (uint)
    {
        uint conv = uint256(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    /**
     * Unsafe write address into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteAddressWord(uint index, address source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint into a memory location
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint(uint index, uint source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location
     *
     * @param index Memory location
     * @param source uint8 to write
     * @return End memory index
     */
    function unsafeWriteUint8(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    /**
     * Unsafe write uint8 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteUint8Word(uint index, uint8 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    /**
     * Unsafe write bytes32 into a memory location using entire word
     *
     * @param index Memory location
     * @param source uint to write
     * @return End memory index
     */
    function unsafeWriteBytes32(uint index, bytes32 source)
        internal
        pure
        returns (uint)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }
}

/*

  Simple contract extension to provide a contract-global reentrancy guard on functions.

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

/**
 * @title ReentrancyGuarded
 * @author JungleNFT Developers
 */
contract ReentrancyGuarded {

    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx =
        MetaTransaction({
        nonce: nonces[userAddress],
        from: userAddress,
        functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] += 1;

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) =
        address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
    public
    pure
    returns (bytes32)
    {
        return
        keccak256(
            abi.encode(
                META_TRANSACTION_TYPEHASH,
                metaTx.nonce,
                metaTx.from,
                keccak256(metaTx.functionSignature)
            )
        );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
        signer ==
        ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );
    }
}

/*

  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.

  Separated into a library for convenience, all the functions are inlined.

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;


/**
 * @title SaleKindInterface
 * @author Project Wyvern Developers
 */
library SaleKindInterface {
    /**
     * Side: buy or sell.
     */
    enum Side {
        Buy,
        Sell
    }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind {
        FixedPrice,
        DutchAuction,
        EnglishAuction
    }

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint256 expirationTime)
        internal
        pure
        returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || saleKind == SaleKind.EnglishAuction || expirationTime > 0);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint256 listingTime, uint256 expirationTime)
        internal
        view
        returns (bool)
    {
        uint256 currentTime = block.timestamp;
        return
            (listingTime < currentTime) &&
            (expirationTime == 0 || currentTime < expirationTime);
    }

    /**
     * @dev Calculate the settlement price of an order
     * @dev Precondition: parameters have passed validateParameters.
     * @param side Order side
     * @param saleKind Method of sale
     * @param basePrice Order base price
     * @param extra Order extra price data
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function calculateFinalPrice(
        Side side,
        SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) internal view returns (uint256 finalPrice) {
        if (saleKind == SaleKind.FixedPrice || saleKind == SaleKind.EnglishAuction) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint256 diff = (extra * (block.timestamp - listingTime))/(expirationTime- listingTime);
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return basePrice - diff;
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return basePrice + diff;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

/**
 * @title Errors library
 * @author Jungle
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 */
library Errors {
  string public constant DOMAIN_HASH_DID_NOT_MATCH = "1"; // Encoded domain hash and EIP_712 domain hash didn't match
  string public constant NAME_HASH_DID_NOT_MATCH  = "2"; // Encoded name hash and name hash didn't match
  string public constant VERSION_HASH_DID_NOT_MATCH  = "3"; // Encoded version hash and version hash didn't  match
  string public constant ORDER_HASH_DID_NOT_MATCH  = "4"; // Encoded order hash and order hash didn't  match
  string public constant TRANSFER_NOT_SUCCESSFUL  = "5"; // Token transfer is not successful
  string public constant INVALID_ORDER  = "6"; // Order is invalid
  string public constant CALLER_IS_NOT_MAKER  = "7"; // Order.maker is not the msg.sender
  string public constant ORDER_ALREADY_APPROVED  = "8"; // Order is already approved
  string public constant INVALID_PRICE  = "9"; // Buy price is not greater than or equal to sell price
  string public constant VALUE_IS_NOT_ZERO  = "10"; // msg.value is not equal to zero
  string public constant INVALID_BUY_TAKER_PROTOCOL_FEE  = "11"; // takerProtocolFee in buy order is not greater than or equal to takerProtocolFee in sell order
  string public constant INVALID_BUY_TAKER_RELAYER_FEE  = "12"; // takerRelayerFee in buy order is not greater than or equal to takerRelayerFee in sell order
  string public constant INVALID_SELL_TAKER_RELAYER_FEE  = "13"; // takerRelayerFee in sell order is not greater than or equal to takerRelayerFee in buy order
  string public constant INVALID_SELL_TAKER_PROTOCOL_FEE  = "14"; // takerProtocolFee in sell order is not greater than or equal to takerProtocolFee in buy order
  string public constant INVALID_SELL_PAYMENT_TOKEN  = "15"; // Payment Token in sell order is Zero address
  string public constant NOT_ENOUGH_VALUE  = "16"; // msg.value is not greater than or equal to required amount
  string public constant INVALID_ORDER_PARAMETERS_BUY_ORDER  = "17"; // Invalid order parameters in buy order
  string public constant INVALID_ORDER_PARAMETERS_SELL_ORDER  = "18"; // Invalid order parameters in sell order
  string public constant ORDERS_NOT_MATCHABLE  = "19"; // Buy order and sell order doesn't match
  string public constant TARGET_NOT_CONTRACT  = "20"; // Is not a contract
  string public constant DATA_NOT_MATCHED  = "21"; // Buy data and sell data are not matched 
  string public constant PROXY_NOT_REGISTERED = "22"; // Address of Delegate proxy is Zero address
  string public constant INVALID_IMPLEMENTATION = "23"; // Implementation address in delegate proxy and implementation address in proxy registry contract are not same 
  string public constant PROXY_CALL_FAILED = "24"; // call to proxy function in authenticated proxy failed
  string public constant BUY_STATIC_CALL_FAILED = "25"; // Static call to static target address in buy order failed
  string public constant SELL_STATIC_CALL_FAILED = "26"; // Static call to static target address in sell order failed
  string public constant CASHBACK_FAILED = "27"; // Failed to get cashback
  string public constant FEE_FAILED = "28"; // Failed to send fee
  string public constant ROYALTY_DATA_LENGTH_NOT_EQUAL = "29"; //Royalty data length must be equal
  string public constant INVALID_CASHBACK_AMOUNT = "30"; // cashbask amount invalid
  string public constant ROYALTY_TRANSFER_FAILED = "31"; //Royalty transfer failed
  string public constant ETHER_TRANSFER_NOT_SUCCESSFUL  = "32"; // Ether transfer is not successful
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
// OpenZeppelin Contracts v4.4.1 (utils/ContextMetaTx.sol)

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

/*

  OwnableDelegateProxy

*/
// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "./proxy/OwnedUpgradeabilityProxy.sol";

/**
 * @title OwnableDelegateProxy
 * @author Wyvern Protocol Developers
 */
contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes memory data)
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success,) = initialImplementation.delegatecall(data);
        require(success, "OwnableDelegateProxy failed implementation");
    }

}

// SPDX-License-Identifier: None
pragma solidity 0.8.12;

import "../../common/meta-transactions/ContextMixin.sol";
import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";
/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
contract OwnedUpgradeabilityProxy 
is Proxy,
 OwnedUpgradeabilityStorage,
 ContextMixin
 {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() override public view returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return proxyTypeId Proxy type, 2 for forwarding proxy
     */
    function proxyType() override public pure returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param implementationAddress representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementationAddress) internal {
        require(_implementation != implementationAddress, "Proxy already uses this implementation");
        _implementation = implementationAddress;
        emit Upgraded(implementationAddress);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(_msgSender() == proxyOwner(), "Only the proxy owner can call this method");
        _;
    }

    /**
     * @dev Tells the address of the proxy owner
     * @return the address of the proxy owner
     */
    function proxyOwner() public view returns (address) {
        return upgradeabilityOwner();
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), "New owner cannot be the null address");
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementationAddress representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementationAddress) public onlyProxyOwner {
        _upgradeTo(implementationAddress);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementationAddress representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementationAddress, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(implementationAddress);
        (bool success,) = address(this).delegatecall(data);
        require(success, "Call failed after proxy upgrade");
    }

    function _msgSender() internal view returns (address sender) {
        return ContextMixin.msgSender();
    }

}

// SPDX-License-Identifier: None


pragma solidity 0.8.12;

/**
 * @title Proxy
 * @dev Gives the possibility to delegate any call to a foreign implementation.
 */
abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() virtual public view returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return proxyTypeId Type of proxy, 2 for upgradeable proxy
     */
    function proxyType() virtual external pure returns (uint256 proxyTypeId);

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback () external payable {
        address _impl = implementation();
        require(_impl != address(0), "Proxy implementation required");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
    receive() external payable {}
}

// SPDX-License-Identifier: None

pragma solidity 0.8.12;

/**
 * @title OwnedUpgradeabilityStorage
 * @dev This contract keeps track of the upgradeability owner
 */
contract OwnedUpgradeabilityStorage {

    // Current implementation
    address internal _implementation;

    // Owner of the contract
    address private _upgradeabilityOwner;

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function upgradeabilityOwner() public view returns (address) {
        return _upgradeabilityOwner;
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newUpgradeabilityOwner) internal {
        _upgradeabilityOwner = newUpgradeabilityOwner;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_NAME = "JUNGLE META-TX";

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712() internal initializer {
        _setDomainSeperator();
    }

    function _setDomainSeperator() internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(ERC712_NAME)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
    {
        return
        keccak256(
            abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}