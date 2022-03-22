// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./exchange/Exchange.sol";
import "./proxy/ProxyRegistry.sol";
import "./proxy/TokenTransferProxy.sol";

contract ForbitswapNFTSExchange is Exchange {
    string public constant name = "Forbitswap NFTS Exchange";
    string public constant version = "1.0";

    constructor(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        IERC20 tokenAddress,
        address protocolFeeAddress,
        uint8 chainId
    ) {
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        exchangeToken = tokenAddress;
        protocolFeeRecipient = protocolFeeAddress;
        DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: name,
            version: version,
            chainId: chainId,
            verifyingContract: address(this)
        }));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ExchangeCore.sol";
import "../../utils/libraries/Market.sol";

contract Exchange is ExchangeCore {
    function guardedArrayReplace(bytes memory array, bytes memory desired, bytes memory mask)
        public
        pure
        returns (bytes memory)
    {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }
    // function changeMinimumProtocolFee(uint256 newMinimumMakerProtocolFee, uint256 newMinimumTakerProtocolFee) public onlyOwner {
    //     minimumMakerProtocolFee = newMinimumMakerProtocolFee;
    //     minimumTakerProtocolFee = newMinimumTakerProtocolFee;
    // }

    // function changeProtocolFeeRecipient(address newProtocolFeeRecipient) public onlyOwner {
    //     protocolFeeRecipient = newProtocolFeeRecipient;
    // }

    function calculateFinalPrice(
        Market.Side side,
        Market.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    )
        public
        view
        returns (uint256)
    {
        return SaleKindInterface.calculateFinalPrice(side, saleKind, basePrice, extra, listingTime, expirationTime);
    }

    function hashToSign_(
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    )
        public
        view
        returns (bytes32)
    { 
        return hashToSign(
          Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8])
        );
    }

    function validateOrderParameters_ (
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    )
        view
        public
        returns (bool)
    {
        Market.Order memory order = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        return validateOrderParameters(
          order
        );
    }

    function validateOrder_ (
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32[2] memory rs
    )
        view
        public
        returns (bool)
    {
        Market.Order memory order = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        return validateOrder(
          hashToSign(order),
          order,
          Market.Sig(v, rs[0], rs[1])
        );
    }

    function approveOrder_ (
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        bool orderbookInclusionDesired
    ) 
        public
    {
        Market.Order memory order = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        return approveOrder(order, orderbookInclusionDesired);
    }

    function cancelOrder_(
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata,
        uint8 v,
        bytes32[2] memory rs
    )
        public
    {
        return cancelOrder(
          Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]),
          Market.Sig(v, rs[0], rs[1])
        );
    }

    function calculateCurrentPrice_(
        address[7] memory addrs,
        uint256[9] memory uints,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        Market.HowToCall howToCall,
        bytes calldata callData,
        bytes memory replacementPattern,
        bytes memory staticExtradata
    )
        public
        view
        returns (uint256)
    {
        return calculateCurrentPrice(
          Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], feeMethod, side, saleKind, addrs[4], howToCall, callData, replacementPattern, addrs[5], staticExtradata, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8])
        );
    }

    function ordersCanMatch_(
        address[14] memory addrs,
        uint[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell
    )
        public
        view
        returns (bool)
    {
        Market.Order memory buy = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[0]), Market.Side(feeMethodsSidesKindsHowToCalls[1]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], Market.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        Market.Order memory sell = Market.Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[4]), Market.Side(feeMethodsSidesKindsHowToCalls[5]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], Market.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, addrs[13], uints[13], uints[14], uints[15], uints[16], uints[17]);
        return ordersCanMatch(
          buy,
          sell
        );
    }

    function orderCalldataCanMatch(
        bytes memory buyCalldata,
        bytes memory buyReplacementPattern,
        bytes memory sellCalldata,
        bytes memory sellReplacementPattern
    )
        public
        pure
        returns (bool)
    {
        if (buyReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(buyCalldata, sellCalldata, buyReplacementPattern);
        }
        if (sellReplacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(sellCalldata, buyCalldata, sellReplacementPattern);
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    function calculateMatchPrice_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell
    )
        public
        view
        returns (uint256)
    {
        Market.Order memory buy = Market.Order(addrs[0], addrs[1], addrs[2], uints[0], uints[1], uints[2], uints[3], addrs[3], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[0]), Market.Side(feeMethodsSidesKindsHowToCalls[1]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[2]), addrs[4], Market.HowToCall(feeMethodsSidesKindsHowToCalls[3]), calldataBuy, replacementPatternBuy, addrs[5], staticExtradataBuy, addrs[6], uints[4], uints[5], uints[6], uints[7], uints[8]);
        Market.Order memory sell = Market.Order(addrs[7], addrs[8], addrs[9], uints[9], uints[10], uints[11], uints[12], addrs[10], Market.FeeMethod(feeMethodsSidesKindsHowToCalls[4]), Market.Side(feeMethodsSidesKindsHowToCalls[5]), Market.SaleKind(feeMethodsSidesKindsHowToCalls[6]), addrs[11], Market.HowToCall(feeMethodsSidesKindsHowToCalls[7]), calldataSell, replacementPatternSell, addrs[12], staticExtradataSell, addrs[13], uints[13], uints[14], uints[15], uints[16], uints[17]);
        return calculateMatchPrice(
          buy,
          sell
        );
    }

    /**
     * @dev Call atomicMatch - only accept transaction when buy order matching with sell order
     */
    function atomicMatch_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) public payable {
        return
            atomicMatch(
                Market.Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    Market.FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
                    Market.Side(feeMethodsSidesKindsHowToCalls[1]),
                    Market.SaleKind(feeMethodsSidesKindsHowToCalls[2]),
                    addrs[4],
                    Market.HowToCall(feeMethodsSidesKindsHowToCalls[3]),
                    calldataBuy,
                    replacementPatternBuy,
                    addrs[5],
                    staticExtradataBuy,
                    addrs[6],
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                Market.Sig(vs[0], rssMetadata[0], rssMetadata[1]),
                Market.Order(
                    addrs[7],
                    addrs[8],
                    addrs[9],
                    uints[9],
                    uints[10],
                    uints[11],
                    uints[12],
                    addrs[10],
                    Market.FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
                    Market.Side(feeMethodsSidesKindsHowToCalls[5]),
                    Market.SaleKind(feeMethodsSidesKindsHowToCalls[6]),
                    addrs[11],
                    Market.HowToCall(feeMethodsSidesKindsHowToCalls[7]),
                    calldataSell,
                    replacementPatternSell,
                    addrs[12],
                    staticExtradataSell,
                    addrs[13],
                    uints[13],
                    uints[14],
                    uints[15],
                    uints[16],
                    uints[17]
                ),
                Market.Sig(vs[1], rssMetadata[2], rssMetadata[3]),
                rssMetadata[4]
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "./OwnableDelegateProxy.sol";

contract ProxyRegistry is Ownable {
    address public delegateProxyImplementation;

    mapping(address => OwnableDelegateProxy) public proxies;
    mapping(address => uint256) public pending;
    mapping(address => bool) public contracts;

    uint256 public DELAY_PERIOD = 2 weeks;

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication(address addr) public onlyOwner {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = block.timestamp;
    }

    /**
     * End the process to enable access for specified contract after delay period has passed.
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication(address addr) public onlyOwner {
        require(
            !contracts[addr] &&
                pending[addr] != 0 &&
                ((pending[addr] + DELAY_PERIOD) < block.timestamp)
        );
        pending[addr] = 0;
        contracts[addr] = true;
    }

    /**
     * Revoke access for specified contract. Can be done instantly.
     * @dev ProxyRegistry owner only
     * @param addr Address of which to revoke permissions
     */
    function revokeAuthentication(address addr) public onlyOwner {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return proxy New AuthenticatedProxy contract
     */
    function registerProxy() public returns (OwnableDelegateProxy proxy) {
        require(address(proxies[_msgSender()]) == address(0));
        proxy = new OwnableDelegateProxy(
            _msgSender(),
            delegateProxyImplementation,
            abi.encodeWithSignature(
                "initialize(address,address)",
                _msgSender(),
                address(this)
            )
        );
        proxies[_msgSender()] = proxy;
        return proxy;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ProxyRegistry.sol";
import "../../token/ERC20/IERC20.sol";
import "../../utils/Context.sol";

contract TokenTransferProxy is Context {
    ProxyRegistry public registry;

    /**
     * Call ERC20 `transferFrom`
     * @dev Authenticated contract only
     * @param token ERC20 token address
     * @param from From address
     * @param to To address
     * @param amount Transfer amount
     */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(registry.contracts(_msgSender()));
        return IERC20(token).transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/IERC20.sol";
import "../../access/Ownable.sol";
import "../../utils/ReentrancyGuard.sol";
import "../../utils/EIP712.sol";
import "../../utils/libraries/Market.sol";
import "../../utils/libraries/SaleKindInterface.sol";
import "../../utils/libraries/ArrayUtils.sol";
import "../../utils/libraries/ECDSA.sol";
import "../../utils/math/SafeMath.sol";
import "../proxy/OwnableDelegateProxy.sol";
import "../proxy/ProxyRegistry.sol";
import "../proxy/TokenTransferProxy.sol";
import "../proxy/AuthenticatedProxy.sol";

contract ExchangeCore is ReentrancyGuard, Ownable, EIP712 {
    using SafeMath for uint256;

    bytes32 private constant _ORDER_TYPEHASH = keccak256("Order(address exchange,address maker,address taker,uint256 makerRelayerFee,uint256 takerRelayerFee,uint256 makerProtocolFee,uint256 takerProtocolFee,address feeRecipient,uint8 feeMethod,uint8 side,uint8 saleKind,address target,uint8 howToCall,bytes callData,bytes replacementPattern,address staticTarget,bytes staticExtradata,address paymentToken,uint256 basePrice,uint256 extra,uint256 listingTime,uint256 expirationTime,uint256 salt)");

    uint256 public constant INVERSE_BASIS_POINT = 10000;
    IERC20 public exchangeToken;
    ProxyRegistry public registry;
    TokenTransferProxy public tokenTransferProxy;

    mapping(bytes32 => bool) public cancelledOrFinalized;
    mapping(bytes32 => bool) public approvedOrders;

    uint256 public minimumMakerProtocolFee = 0;
    uint256 public minimumTakerProtocolFee = 0;
    address public protocolFeeRecipient;

    event OrderApprovedPartOne(
        bytes32 indexed hash,
        address exchange,
        address indexed maker,
        address taker,
        uint256 makerRelayerFee,
        uint256 takerRelayerFee,
        uint256 makerProtocolFee,
        uint256 takerProtocolFee,
        address indexed feeRecipient,
        Market.FeeMethod feeMethod,
        Market.Side side,
        Market.SaleKind saleKind,
        address target
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        Market.HowToCall howToCall,
        bytes callData,
        bytes replacementPattern,
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

    // function changeMinimumProtocolFee(uint256 newMinimumMakerProtocolFee, uint256 newMinimumTakerProtocolFee) public onlyOwner {
    //     minimumMakerProtocolFee = newMinimumMakerProtocolFee;
    //     minimumTakerProtocolFee = newMinimumTakerProtocolFee;
    // }

    // function changeProtocolFeeRecipient(address newProtocolFeeRecipient) public onlyOwner {
    //     protocolFeeRecipient = newProtocolFeeRecipient;
    // }

    function transferTokens(address token, address from, address to, uint256 amount) internal {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    function chargeProtocolFee(address from, address to, uint256 amount) internal {
        transferTokens(address(exchangeToken), from, to, amount);
    }

    function staticCall(address target, bytes memory callData, bytes memory extradata)
        public
        view
        returns (bool result)
    {
        bytes memory combined = new bytes(callData.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, callData);
        assembly {
            result := staticcall(gas(), target, add(combined, 0x20), mload(combined), mload(0x40), 0)
        }
        return result;
    }

    function hashOrder(Market.Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        uint256 size = 768;
        bytes memory array = new bytes(size);
        uint256 index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes32(index, _ORDER_TYPEHASH);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.maker);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddressWord(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.target);
        index = ArrayUtils.unsafeWriteUint8Word(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.callData));
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.replacementPattern));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes32(index, keccak256(order.staticExtradata));
        index = ArrayUtils.unsafeWriteAddressWord(index, order.paymentToken);
        index = ArrayUtils.unsafeWriteUint(index, order.basePrice);
        index = ArrayUtils.unsafeWriteUint(index, order.extra);
        index = ArrayUtils.unsafeWriteUint(index, order.listingTime);
        index = ArrayUtils.unsafeWriteUint(index, order.expirationTime);
        index = ArrayUtils.unsafeWriteUint(index, order.salt);
        assembly {
            hash := keccak256(add(array, 0x20), size)
        }
        return hash;
    }

    function hashToSign(Market.Order memory order)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hashOrder(order));
    }

    function requireValidOrder(Market.Order memory order, Market.Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig));
        return hash;
    }

    function validateOrderParameters(Market.Order memory order)
        internal
        view
        returns (bool)
    {
        if (order.exchange != address(this)) {
            return false;
        }

        if (!SaleKindInterface.validateParameters(order.saleKind, order.expirationTime)) {
            return false;
        }

        if (order.feeMethod == Market.FeeMethod.SplitFee &&
            (order.makerProtocolFee < minimumMakerProtocolFee ||
            order.takerProtocolFee < minimumTakerProtocolFee)) {
            return false;
        }

        return true;
    }

    function validateOrder(bytes32 hash, Market.Order memory order, Market.Sig memory sig) 
        internal
        view
        returns (bool)
    {
        if (!validateOrderParameters(order)) {
            return false;
        }

        if (cancelledOrFinalized[hash]) {
            return false;
        }
        
        if (approvedOrders[hash]) {
            return true;
        }

        if (ECDSA.recover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        return false;
    }

    function approveOrder(Market.Order memory order, bool orderbookInclusionDesired)
        internal
    {
        require(_msgSender() == order.maker);

        bytes32 hash = hashToSign(order);

        require(!approvedOrders[hash]);

        approvedOrders[hash] = true;
  
        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(hash, order.exchange, order.maker, order.taker, order.makerRelayerFee, order.takerRelayerFee, order.makerProtocolFee, order.takerProtocolFee, order.feeRecipient, order.feeMethod, order.side, order.saleKind, order.target);
        }
        {   
            emit OrderApprovedPartTwo(hash, order.howToCall, order.callData, order.replacementPattern, order.staticTarget, order.staticExtradata, order.paymentToken, order.basePrice, order.extra, order.listingTime, order.expirationTime, order.salt, orderbookInclusionDesired);
        }
    }

    function cancelOrder(Market.Order memory order, Market.Sig memory sig) 
        internal
    {
        bytes32 hash = requireValidOrder(order, sig);

        require(_msgSender() == order.maker);
  
        cancelledOrFinalized[hash] = true;

        emit OrderCancelled(hash);
    }

    function calculateCurrentPrice(Market.Order memory order)
        internal  
        view
        returns (uint256)
    {
        return SaleKindInterface.calculateFinalPrice(order.side, order.saleKind, order.basePrice, order.extra, order.listingTime, order.expirationTime);
    }

    function calculateMatchPrice(Market.Order memory buy, Market.Order memory sell)
        view
        internal
        returns (uint256)
    {
        uint256 sellPrice = SaleKindInterface.calculateFinalPrice(sell.side, sell.saleKind, sell.basePrice, sell.extra, sell.listingTime, sell.expirationTime);

        uint256 buyPrice = SaleKindInterface.calculateFinalPrice(buy.side, buy.saleKind, buy.basePrice, buy.extra, buy.listingTime, buy.expirationTime);

        require(buyPrice >= sellPrice);
        
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
    }

    function executeFundsTransfer(Market.Order memory buy, Market.Order memory sell)
        internal
        returns (uint256)
    {
        /* Only payable in the special case of unwrapped Ether. */
        if (sell.paymentToken != address(0)) {
            require(msg.value == 0);
        }

        uint256 price = calculateMatchPrice(buy, sell);

        /* If paying using a token (not Ether), transfer tokens. This is done prior to fee payments to that a seller will have tokens before being charged fees. */
        if (price > 0 && sell.paymentToken != address(0)) {
            transferTokens(sell.paymentToken, buy.maker, sell.maker, price);
        }

        /* Amount that will be received by seller (for Ether). */
        uint256 receiveAmount = price;

        /* Amount that must be sent by buyer (for Ether). */
        uint256 requiredAmount = price;

        /* Determine maker/taker and charge fees accordingly. */
        if (sell.feeRecipient != address(0)) {
      
            require(sell.takerRelayerFee <= buy.takerRelayerFee);

            if (sell.feeMethod == Market.FeeMethod.SplitFee) {
                require(sell.takerProtocolFee <= buy.takerProtocolFee);

                if (sell.makerRelayerFee > 0) {
                    uint256 makerRelayerFee = SafeMath.div(SafeMath.mul(sell.makerRelayerFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(receiveAmount, makerRelayerFee);
                        payable(address(sell.feeRecipient)).transfer(makerRelayerFee);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, sell.feeRecipient, makerRelayerFee);
                    }
                }

                if (sell.takerRelayerFee > 0) {
                    uint256 takerRelayerFee = SafeMath.div(SafeMath.mul(sell.takerRelayerFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(requiredAmount, takerRelayerFee);
                        payable(address(sell.feeRecipient)).transfer(takerRelayerFee);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, sell.feeRecipient, takerRelayerFee);
                    }
                }

                if (sell.makerProtocolFee > 0) {
                    uint256 makerProtocolFee = SafeMath.div(SafeMath.mul(sell.makerProtocolFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        receiveAmount = SafeMath.sub(receiveAmount, makerProtocolFee);
                        payable(address(protocolFeeRecipient)).transfer(makerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, makerProtocolFee);
                    }
                }

                if (sell.takerProtocolFee > 0) {
                    uint256 takerProtocolFee = SafeMath.div(SafeMath.mul(sell.takerProtocolFee, price), INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        requiredAmount = SafeMath.add(requiredAmount, takerProtocolFee);
                        payable(address(protocolFeeRecipient)).transfer(takerProtocolFee);
                    } else {
                        transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, takerProtocolFee);
                    }
                }

            } else {
                if (sell.makerRelayerFee > 0) {
                    chargeProtocolFee(sell.maker, sell.feeRecipient, sell.makerRelayerFee);
                }
                if (sell.takerRelayerFee > 0) {
                    chargeProtocolFee(buy.maker, sell.feeRecipient, sell.takerRelayerFee);
                }
            }
        } else {

            require(buy.takerRelayerFee <= sell.takerRelayerFee);

            if (sell.feeMethod == Market.FeeMethod.SplitFee) {
                /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
                require(sell.paymentToken != address(0));

                require(buy.takerProtocolFee <= sell.takerProtocolFee);

                if (buy.makerRelayerFee > 0) {
                    transferTokens(sell.paymentToken, buy.maker, buy.feeRecipient, SafeMath.div(SafeMath.mul(buy.makerRelayerFee, price), INVERSE_BASIS_POINT));
                }

                if (buy.takerRelayerFee > 0) {
                    transferTokens(sell.paymentToken, sell.maker, buy.feeRecipient, SafeMath.div(SafeMath.mul(buy.takerRelayerFee, price), INVERSE_BASIS_POINT));
                }

                if (buy.makerProtocolFee > 0) {
                    transferTokens(sell.paymentToken, buy.maker, protocolFeeRecipient, SafeMath.div(SafeMath.mul(buy.makerProtocolFee, price), INVERSE_BASIS_POINT));
                }

                if (buy.takerProtocolFee > 0) {
                    transferTokens(sell.paymentToken, sell.maker, protocolFeeRecipient, SafeMath.div(SafeMath.mul(buy.takerProtocolFee, price), INVERSE_BASIS_POINT));
                }

            } else {
                if (buy.makerRelayerFee > 0) {
                    chargeProtocolFee(buy.maker, buy.feeRecipient, buy.makerRelayerFee);
                }
                if (buy.takerRelayerFee > 0) {
                    chargeProtocolFee(sell.maker, buy.feeRecipient, buy.takerRelayerFee);
                }
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            payable(address(sell.maker)).transfer(receiveAmount);
            uint256 diff = SafeMath.sub(msg.value, requiredAmount);
            if (diff > 0) {
                payable(address(buy.maker)).transfer(diff);
            }
        }

        return price;
    }

    function ordersCanMatch(Market.Order memory buy, Market.Order memory sell)
        internal
        view
        returns (bool)
    {
        return (
            /* Must be opposite-side. */
            (buy.side == Market.Side.Buy && sell.side == Market.Side.Sell) &&     
            /* Must use same fee method. */
            (buy.feeMethod == sell.feeMethod) &&
            /* Must use same payment token. */
            (buy.paymentToken == sell.paymentToken) &&
            /* Must match maker/taker addresses. */
            (sell.taker == address(0) || sell.taker == buy.maker) &&
            (buy.taker == address(0) || buy.taker == sell.maker) &&
            /* One must be maker and the other must be taker (no bool XOR in Solidity). */
            ((sell.feeRecipient == address(0) && buy.feeRecipient != address(0)) || (sell.feeRecipient != address(0) && buy.feeRecipient == address(0))) &&
            /* Must match target. */
            (buy.target == sell.target) &&
            /* Must match howToCall. */
            (buy.howToCall == sell.howToCall) &&
            /* Buy-side order must be settleable. */
            SaleKindInterface.canSettleOrder(buy.listingTime, buy.expirationTime) &&
            /* Sell-side order must be settleable. */
            SaleKindInterface.canSettleOrder(sell.listingTime, sell.expirationTime)
        );
    }

    function atomicMatch(
        Market.Order memory buy,
        Market.Sig memory buySig,
        Market.Order memory sell,
        Market.Sig memory sellSig,
        bytes32 metadata
    )
        internal
        nonReentrant()
    {      
        /* Ensure buy order validity and calculate hash if necessary. */
        bytes32 buyHash;
        if (buy.maker == _msgSender()) {
            require(validateOrderParameters(buy));
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == _msgSender()) {
            require(validateOrderParameters(sell));
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }
        
        require(ordersCanMatch(buy, sell));

        uint256 size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0);
      
        if (buy.replacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(buy.callData, sell.callData, buy.replacementPattern);
        }
        if (sell.replacementPattern.length > 0) {
          ArrayUtils.guardedArrayReplace(sell.callData, buy.callData, sell.replacementPattern);
        }
        require(ArrayUtils.arrayEq(buy.callData, sell.callData));

        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        require(address(delegateProxy) != address(0));

        require(delegateProxy.implementation() == registry.delegateProxyImplementation());

        AuthenticatedProxy proxy = AuthenticatedProxy(payable(address(delegateProxy)));

        if (_msgSender() != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (_msgSender() != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        uint256 price = executeFundsTransfer(buy, sell);

        require(proxy.proxy(sell.target, sell.howToCall, sell.callData));

        if (buy.staticTarget != address(0)) {
            require(staticCall(buy.staticTarget, sell.callData, buy.staticExtradata));
        }

        if (sell.staticTarget != address(0)) {
            require(staticCall(sell.staticTarget, sell.callData, sell.staticExtradata));
        }

        emit OrdersMatched(
            buyHash,
            sellHash,
            sell.feeRecipient != address(0) ? sell.maker : buy.maker,
            sell.feeRecipient != address(0) ? buy.maker : sell.maker,
            price,
            metadata
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Market {
    /* Fee method: protocol fee or split fee. */
    enum FeeMethod {
        ProtocolFee,
        SplitFee
    }

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
        DutchAuction
    }

    /* Delegate call could be used to atomically transfer multiple assets owned by the proxy contract with one order. */
    enum HowToCall {
        Call,
        DelegateCall
    }

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
        /* Maker protocol fee of the order, unused for taker order. */
        uint256 makerProtocolFee;
        /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
        uint256 takerProtocolFee;
        /* Order fee recipient or zero address for taker order. */
        address feeRecipient;
        /* Fee method (protocol token or split fee). */
        FeeMethod feeMethod;
        /* Side (buy/sell). */
        Side side;
        /* Kind of sale. */
        SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        HowToCall howToCall;
        /* Calldata. */
        bytes callData;
        /* Calldata replacement pattern, or an empty byte array for no replacement. */
        bytes replacementPattern;
        /* Static call target, zero-address for no static call. */
        address staticTarget;
        /* Static call extra data. */
        bytes staticExtradata;
        /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
        address paymentToken;
        /* Base price of the order (in paymentTokens). */
        uint256 basePrice;
        /* Auction extra parameter 
        - minimum bid increment for English auctions, starting/ending price difference. */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 */

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract EIP712 {
  struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
  }

  bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
  );
  bytes32 public DOMAIN_SEPARATOR;

  function hash(EIP712Domain memory eip712Domain) internal pure returns (bytes32) {
    return keccak256(abi.encode(
      EIP712DOMAIN_TYPEHASH,
      keccak256(bytes(eip712Domain.name)),
      keccak256(bytes(eip712Domain.version)),
      eip712Domain.chainId,
      eip712Domain.verifyingContract
    ));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../math/SafeMath.sol";
import "./Market.sol";

library SaleKindInterface {
    using SafeMath for uint256;

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(
        Market.SaleKind saleKind,
        uint256 expirationTime
    ) internal pure returns (bool) {
        /* Auctions must have a set expiration date. */
        return (saleKind == Market.SaleKind.FixedPrice || expirationTime > 0);
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
        return
            (listingTime < block.timestamp) &&
            (expirationTime == 0 || block.timestamp < expirationTime);
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
        Market.Side side,
        Market.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    )
        internal
        view
        returns (uint256 finalPrice)
    {
        if (saleKind == Market.SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == Market.SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(block.timestamp, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Market.Side.Sell) {
                return SafeMath.sub(basePrice, diff);
            } else {
                return SafeMath.add(basePrice, diff);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly
// solhint-disable reason-string
// solhint-disable no-empty-blocks
library ArrayUtils {
    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     */
    function guardedArrayReplace(
        bytes memory array,
        bytes memory desired,
        bytes memory mask
    ) internal pure {
        require(array.length == desired.length);
        require(array.length == mask.length);

        uint256 words = array.length / 0x20;
        uint256 index = words * 0x20;
        assert(index / 0x20 == words);
        uint256 i;

        for (i = 0; i < words; i++) {
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        }

        /* Deal with the last section of the byte array. */
        if (words > 0) {
            i = words;
            assembly {
                let commonIndex := mul(0x20, add(1, i))
                let maskValue := mload(add(mask, commonIndex))
                mstore(
                    add(array, commonIndex),
                    or(
                        and(not(maskValue), mload(add(array, commonIndex))),
                        and(maskValue, mload(add(desired, commonIndex)))
                    )
                )
            }
        } else {
            /* If the byte array is shorter than a word, we must unfortunately do the whole thing bytewise.
            (bounds checks could still probably be optimized away in assembly, but this is a rare case) */
            for (i = index; i < array.length; i++) {
                array[i] =
                    ((mask[i] ^ 0xff) & array[i]) |
                    (mask[i] & desired[i]);
            }
        }
    }

    /**
     * Test if two arrays are equal
     * Source: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
     *
     * @dev Arrays must be of equal length, otherwise will return false
     * @param a First array
     * @param b Second array
     * @return Whether or not all bytes in the arrays are equal
     */
    function arrayEq(bytes memory a, bytes memory b)
        internal
        pure
        returns (bool)
    {
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                    // the next line is the loop condition:
                    // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /**
     * Unsafe write byte array into a memory location
     *
     * @param index Memory location
     * @param source Byte array to write
     * @return End memory index
     */
    function unsafeWriteBytes(uint256 index, bytes memory source)
        internal
        pure
        returns (uint256)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
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
    function unsafeWriteAddress(uint256 index, address source)
        internal
        pure
        returns (uint256)
    {
        uint256 conv = uint256(uint160(source)) << 0x60;
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
    function unsafeWriteAddressWord(uint256 index, address source)
        internal
        pure
        returns (uint256)
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
    function unsafeWriteUint(uint256 index, uint256 source)
        internal
        pure
        returns (uint256)
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
    function unsafeWriteUint8(uint256 index, uint8 source)
        internal
        pure
        returns (uint256)
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
    function unsafeWriteUint8Word(uint256 index, uint8 source)
        internal
        pure
        returns (uint256)
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
    function unsafeWriteBytes32(uint256 index, bytes32 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return recover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return recover(hash, r, vs);
        } else {
            revert("ECDSA: invalid signature length");
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(
                vs,
                0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            )
            v := add(shr(255, vs), 27)
        }
        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`, `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        external
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnedUpgradeabilityProxy.sol";

contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {
    constructor(
        address owner,
        address initialImplementation,
        bytes memory callData
    ) {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        (bool success, ) = initialImplementation.delegatecall(callData);
        require(success);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TokenRecipient.sol";
import "./OwnedUpgradeabilityStorage.sol";
import "./ProxyRegistry.sol";
import "../../utils/libraries/Market.sol";

contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {
    bool initialized = false;
    address public user;
    ProxyRegistry public registry;
    bool public revoked;

    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize(address addrUser, ProxyRegistry addrRegistry) public {
        require(!initialized);
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke) public {
        require(_msgSender() == user);
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param callData Calldata to send
     * @return result bool Result of the call (success or failure)
     */
    function proxy(
        address dest,
        Market.HowToCall howToCall,
        bytes memory callData
    ) public returns (bool result) {
        require(
            _msgSender() == user || (!revoked && registry.contracts(_msgSender()))
        );

        if (howToCall == Market.HowToCall.Call) {
            (result, ) = dest.call(callData);
        } else if (howToCall == Market.HowToCall.DelegateCall) {
            (result, ) = dest.delegatecall(callData);
        }
    }

    /**
     * Execute a message call and assert success
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param callData Calldata to send
     */
    function proxyAssert(
        address dest,
        Market.HowToCall howToCall,
        bytes memory callData
    ) public {
        require(proxy(dest, howToCall, callData));
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./Proxy.sol";
import "./OwnedUpgradeabilityStorage.sol";
import "../../utils/Context.sol";

contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage, Context {
    
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);
    event Upgraded(address indexed implementer);

    modifier onlyProxyOwner() {
        require(_msgSender() == proxyOwner());
        _;
    }

    /**
     * @dev Tells the address of the current implementation
     * @return address of the current implementation
     */
    function implementation() public view override returns (address) {
        return _implementation;
    }

    /**
     * @dev Tells the proxy type (EIP 897)
     * @return proxyTypeId (2 for forwarding proxy)
     */
    function proxyType() public pure override returns (uint256 proxyTypeId) {
        return 2;
    }

    /**
     * @dev Upgrades the implementation address
     * @param implementer representing the address of the new implementation to be set
     */
    function _upgradeTo(address implementer) internal {
        require(_implementation != implementer);
        _implementation = implementer;
        emit Upgraded(implementer);
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
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementer representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementer) public onlyProxyOwner {
        _upgradeTo(implementer);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementer representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementer, bytes memory data)
        public
        payable
        onlyProxyOwner
    {
        upgradeTo(implementer);
        (bool success, ) = address(this).delegatecall(data);
        require(success);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Proxy {
    /**
     * @dev Tells the address of the implementation where every call will be delegated.
     * @return address of the implementation to which it will be delegated
     */
    function implementation() public view virtual returns (address);

    /**
     * @dev Tells the type of proxy (EIP 897)
     * @return proxyTypeId (2 for upgradeable proxy)
     */
    function proxyType() public pure virtual returns (uint256);

    /**
     * @dev Receive function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    receive() external payable {}

    /**
     * @dev Receive function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        address _impl = implementation();
        require(_impl != address(0));

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnedUpgradeabilityStorage {
    address internal _implementation;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../token/ERC20/IERC20.sol";
import "../../utils/Context.sol";

contract TokenRecipient is Context {
    event ReceivedEther(address indexed sender, uint256 amount);
    event ReceivedTokens(
        address indexed from,
        uint256 value,
        address indexed token,
        bytes extraData
    );

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(
        address from,
        uint256 value,
        address token,
        bytes memory extraData
    ) public {
        IERC20 t = IERC20(token);
        require(t.transferFrom(from, address(this), value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    receive() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    fallback() external payable {
        emit ReceivedEther(_msgSender(), msg.value);
    }
}