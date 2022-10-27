// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

import "./exchange/Exchange.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title WyvernExchange
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract WyvernExchangeWithBulkCancellations is Exchange, UUPSUpgradeable {
    // string public constant CODENAME = "Bulk Smash";

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     */
    function initialize(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        address _contractOwner
    ) external initializer {
        require(_contractOwner != address(0), "Invalid owner");
        __ExchangeCore_init_();
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        _transferOwnership(_contractOwner);
    }

    //Only owner function for upgrading proxy.
    function _authorizeUpgrade(address) internal override onlyOwner {}
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
        SaleKindLibrary.Side side,
        SaleKindLibrary.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) external view returns (uint256) {
        return
            SaleKindLibrary.calculateFinalPrice(
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
    ) external pure returns (bytes memory) {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../registry/ProxyRegistry.sol";
import "../registry/TokenTransferProxy.sol";
import "../registry/AuthenticatedProxy.sol";
import "../common/ArrayUtils.sol";
import "../common/meta-transactions/ContextMixin.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";
import "./SaleKindLibrary.sol";
import { Errors } from "../libraries/Errors.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title ExchangeCore
 * @author Project Wyvern Developers, JungleNFT Developers
 */
contract ExchangeCore is
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable,
    ContextMixin,
    NativeMetaTransaction
{

    using SafeERC20Upgradeable for IERC20Upgradeable;

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
        SaleKindLibrary.Side side;
        /* Kind of sale. */
        SaleKindLibrary.SaleKind saleKind;
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
        SaleKindLibrary.Side side,
        SaleKindLibrary.SaleKind saleKind,
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
    event TokenTransferProxyUpdated(address tokenTransferProxy);
    event ProxyRegistryUpdated(address proxyRegistry);

    function __ExchangeCore_init_() internal {
        __ReentrancyGuard_init();
        __Ownable_init();
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
     * @dev Sets the tokenTrannsferProxy address.
     * @param _tokenTransferProxy the tokenTransferProxy address.
     */
    function setTokenTransferProxy(TokenTransferProxy _tokenTransferProxy) external onlyOwner {
        require(address(_tokenTransferProxy) != address(0), Errors.INVALID_IMPLEMENTATION);
        tokenTransferProxy = _tokenTransferProxy;
        emit TokenTransferProxyUpdated(address(_tokenTransferProxy));
    }

    /**
     * @dev Sets the proxyRegistry address.
     * @param _proxyRegistry the proxyRegistry address.
     */
    function setProxyRegistry(ProxyRegistry _proxyRegistry) external onlyOwner {
        require(address(_proxyRegistry) != address(0), Errors.INVALID_IMPLEMENTATION);
        registry = _proxyRegistry;
        emit ProxyRegistryUpdated(address(_proxyRegistry));
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
    function approvedOrders(bytes32 hash) external view returns (bool approved) {
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
                IERC20Upgradeable(token).safeTransfer(to, amount);
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
            !SaleKindLibrary.validateParameters(
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
            SaleKindLibrary.calculateFinalPrice(
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
        uint256 sellPrice = SaleKindLibrary.calculateFinalPrice(
            sell.side,
            sell.saleKind,
            sell.basePrice,
            sell.extra,
            sell.listingTime,
            sell.expirationTime
        );

        /* Calculate buy price. */
        uint256 buyPrice = SaleKindLibrary.calculateFinalPrice(
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
                    sell.saleKind == SaleKindLibrary.SaleKind.EnglishAuction
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
                    IERC165Upgradeable(nftAddresses[i]).supportsInterface(
                        type(IERC2981Upgradeable).interfaceId
                    )
                ) {
                    (address reciever, uint256 royaltyAmount) = IERC2981Upgradeable(
                        nftAddresses[i]
                    ).royaltyInfo(tokenIDs[i], sellPrice);
                    totalRoyalty += royaltyAmount;
                    if(reciever != address(0) && royaltyAmount > 0){
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
            }
            return totalRoyalty;
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
        (buy.side == SaleKindLibrary.Side.Buy &&
            sell.side == SaleKindLibrary.Side.Sell) &&
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
            SaleKindLibrary.canSettleOrder(
                buy.listingTime,
                buy.expirationTime
            ) &&
            /* Sell-side order must be settleable. */
            SaleKindLibrary.canSettleOrder(
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
    ) internal nonReentrant {
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

/*

  Proxy registry; keeps a mapping of AuthenticatedProxy contracts and mapping of contracts authorized to access them.  
  
  Abstracted away from the Exchange (a) to reduce Exchange attack surface and (b) so that the Exchange contract can be upgraded without users needing to transfer assets to new proxies.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./OwnableDelegateProxy.sol";
import "../common/meta-transactions/NativeMetaTransaction.sol";

/**
 * @title ProxyRegistry
 * @author Wyvern Protocol Developers
 */
contract ProxyRegistry is ContextMixin, OwnableUpgradeable, NativeMetaTransaction, ReentrancyGuardUpgradeable {

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
    uint public delayPeriod;

    function __ProxyRegistry_init() internal initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _initializeEIP712();
        delayPeriod = 2 days;
    }
    
    /**
     * Sets the delay period. Can be zero if decided by owner.
     *
     * @dev ProxyRegistry owner only
     * @param _delayPeriod new delay period in seconds
     */
    function setDelayPeriod (uint256 _delayPeriod)
        external
        onlyOwner
    {
        delayPeriod = _delayPeriod;
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
        require(addr != address(0), "Input address cannot be zero address");
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
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + delayPeriod) < block.timestamp), "Contract is no longer pending or has already been approved by registry");
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * End the process to decline access for specified contract.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to decline permissions
     */
    function declineGrantAuthentication (address addr)
        external
        onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0, "Contract is no longer pending or has already been approved by registry");
        pending[addr] = 0;
        contracts[addr] = false;
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
        external nonReentrant
        returns (OwnableDelegateProxy proxy)
    {
        proxy = new OwnableDelegateProxy(_msgSender(), delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", _msgSender(), address(this)));
        proxies[_msgSender()] = proxy;
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
        require(dest != address(0), "dest cannot be zero address");
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
        if (array.length % 0x20 > 0) {
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

  Token transfer proxy. Uses the authentication table of a ProxyRegistry contract to grant ERC20 `transferFrom` access.
  This means that users only need to authorize the proxy contract once for all future protocol versions.

*/
// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./ProxyRegistry.sol";

contract TokenTransferProxy is ContextUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;

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
    external
    returns (bool)
    {
        require(registry.contracts(_msgSender()), "Callers ProxyRegistry should be true");
        IERC20Upgradeable(token).safeTransferFrom(from, to, amount);
        return true;
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

/*

  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.

  Separated into a library for convenience, all the functions are inlined.

*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;


/**
 * @title SaleKindLibrary
 * @author Project Wyvern Developers
 */
library SaleKindLibrary {
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
        return (saleKind == SaleKind.FixedPrice ||
                saleKind == SaleKind.EnglishAuction ||
               (saleKind == SaleKind.DutchAuction && expirationTime > 0));
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
        require(canSettleOrder(listingTime, expirationTime), "Invalid timestamps.");
        if (saleKind == SaleKind.DutchAuction) {
            uint256 diff = (extra * (block.timestamp - listingTime))/(expirationTime- listingTime);
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return basePrice - diff;
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return basePrice + diff;
            }
        }
        return basePrice;
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
    mapping(address => uint256) private metaNonces;

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
        require(userAddress != address(0), "UserAddress cannot be zero address");
        MetaTransaction memory metaTx =
        MetaTransaction({
        nonce: metaNonces[userAddress],
        from: userAddress,
        functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        metaNonces[userAddress] += 1;

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
        nonce = metaNonces[user];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
      require(owner != address(0), "Owner cannot be a zero address");
      require(initialImplementation != address(0), " cannot be a zero address"); 
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
    function proxyType() override external pure returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param implementationAddress representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementationAddress) internal {
        require(_implementation != implementationAddress, "Proxy already uses this implementation");
        require(implementationAddress != address(0), "Implementation address cannot be zero address");
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
    function transferProxyOwnership(address newOwner) external onlyProxyOwner {
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
    function upgradeToAndCall(address implementationAddress, bytes memory data) external payable onlyProxyOwner {
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
        require(newUpgradeabilityOwner != address(0), "New UpgradeabilityOwner cannot be zero address");
        _upgradeabilityOwner = newUpgradeabilityOwner;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC20PermitUpgradeable {
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}