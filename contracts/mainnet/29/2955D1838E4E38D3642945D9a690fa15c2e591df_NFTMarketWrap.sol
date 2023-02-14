// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

enum FeeMethod { ProtocolFee, SplitFee }

enum HowToCall { Call, DelegateCall }

enum Side { Buy, Sell }

enum SaleKind { FixedPrice, DutchAuction }

/* An ECDSA signature. */ 
struct Sig {
    /* v parameter */
    uint8 v;
    /* r parameter */
    bytes32 r;
    /* s parameter */
    bytes32 s;
}

struct ArgBytes {
        
    bytes calldataBeta1;
        
    bytes replacementPattern1;
            
    bytes staticExtradata1;

    bytes calldataBeta2;
        
    bytes replacementPattern2;
            
    bytes staticExtradata2;
}

struct Order {
    /* Exchange address, intended as a versioning mechanism. */
    address exchange;
    /* Order maker address. */
    address maker;
    /* Order taker address, if specified. */
    address taker;
    /* Maker relayer fee of the order, unused for taker order. */
    uint makerRelayerFee;
    /* Taker relayer fee of the order, or maximum taker fee for a taker order. */
    uint takerRelayerFee;
    /* Maker protocol fee of the order, unused for taker order. */
    uint makerProtocolFee;
    /* Taker protocol fee of the order, or maximum taker fee for a taker order. */
    uint takerProtocolFee;
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
    bytes calldataBeta;
    /* Calldata replacement pattern, or an empty byte array for no replacement. */
    bytes replacementPattern;
    /* Static call target, zero-address for no static call. */
    address staticTarget;
    /* Static call extra data. */
    bytes staticExtradata;
    /* Token used to pay for the order, or the zero-address as a sentinel value for Ether. */
    address paymentToken;
    /* Base price of the order (in paymentTokens). */
    uint basePrice;
    /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
    uint extra;
    /* Listing timestamp. */
    uint listingTime;
    /* Expiration timestamp - 0 for no expiry. */
    uint expirationTime;
    /* Order salt, used to prevent duplicate hashes. */
    uint salt;
}

interface Exchange {    

     function atomicMatch_(
        address[15] calldata addrs,
        uint[18] calldata uints,
        uint8[8] calldata feeMethodsSidesKindsHowToCalls,
        bytes calldata calldataBuy,
        bytes calldata calldataSell,
        bytes calldata replacementPatternBuy,
        bytes calldata replacementPatternSell,
        bytes calldata staticExtradataBuy,
        bytes calldata staticExtradataSell,
        uint8[2] calldata vs,
        bytes32[5] calldata rssMetadata
    )
        external
        payable;       
}

contract NFTMarketWrap {
    
    Exchange public exchange;

    constructor(Exchange _exchange) {
        exchange = _exchange;
    }

    function _getAddrs(Order calldata buy, Order calldata sell, address _sender) internal pure returns (address[15] memory) {
        address[15] memory _addrs = [
            buy.exchange,
            buy.maker,
            buy.taker,
            buy.feeRecipient,
            buy.target,
            buy.staticTarget,
            buy.paymentToken,
            sell.exchange,
            sell.maker,
            sell.taker,
            sell.feeRecipient,
            sell.target,
            sell.staticTarget,
            sell.paymentToken,
            _sender
        ];

        return _addrs;
    }
    function _getUint(Order calldata buy, Order calldata sell ) internal pure returns (uint[18] memory) {
        uint[18] memory _uints = [
            buy.makerRelayerFee,
            buy.takerRelayerFee,
            buy.makerProtocolFee,
            buy.takerProtocolFee,
            buy.basePrice,
            buy.extra,
            buy.listingTime,
            buy.expirationTime,
            buy.salt,

            sell.makerRelayerFee,
            sell.takerRelayerFee,
            sell.makerProtocolFee,
            sell.takerProtocolFee,
            sell.basePrice,
            sell.extra,
            sell.listingTime,
            sell.expirationTime,
            sell.salt
        ];

        return _uints;
    }
    function _getEnum(Order calldata buy, Order calldata sell ) internal pure returns (uint8[8] memory) {
        uint8[8] memory _enum = [
            uint8(buy.feeMethod),
            uint8(buy.side),
            uint8(buy.saleKind),
            uint8(buy.howToCall),

            uint8(sell.feeMethod),
            uint8(sell.side),
            uint8(sell.saleKind),
            uint8(sell.howToCall)
        ];

        return _enum;
    }
    function _getVS(Sig calldata buySig, Sig calldata sellSig ) internal pure returns (uint8[2] memory) {
        uint8[2] memory _vs = [
            buySig.v,
            sellSig.v
        ];
        return _vs;
    }
    function _getMetadata(Sig calldata buySig, Sig calldata sellSig, bytes32 metadata) internal pure returns (bytes32[5] memory) {
        bytes32[5] memory _rssMetadata = [
            buySig.r,
            buySig.s,
            sellSig.r,
            sellSig.s,
            metadata
        ];
        return _rssMetadata;
    }
    function _getBytes(Order calldata buy, Order calldata sell ) internal pure returns (ArgBytes memory) {
        ArgBytes memory arg = ArgBytes(
            buy.calldataBeta,
            buy.replacementPattern,
            buy.staticExtradata,
            sell.calldataBeta,
            sell.replacementPattern,
            sell.staticExtradata
        );
        return arg;
    }

    function atomicMatchWrap (
        Order[] calldata buys,
        Sig[] calldata buySigs,
        Order[] calldata sells,
        Sig[] calldata sellSigs,
        bytes32 rssMetadata,
        uint256[] calldata values
    )
        public
        payable
    {
        uint256 totalSells = sells.length;
        
        require(totalSells == buys.length, "sells count and buys count must be equal");
        require(totalSells == values.length, "sells count and values count must be equal");

        require(totalSells > 1, "pls call exchange contract directly.");
        
        uint256 totalValue = 0;
        for( uint256 j = 0; j < totalSells; j++ ) {
            totalValue += values[j];
        }

        require(msg.value == totalValue, "msg.value count and totalValue must be equal");
        
        for ( uint256 i = 0; i < totalSells; i++ ) {

            ArgBytes memory arg = _getBytes(buys[i], sells[i]);

            exchange.atomicMatch_{value: values[i]} (
                _getAddrs(buys[i], sells[i], msg.sender),
                _getUint(buys[i], sells[i]),
                _getEnum(buys[i], sells[i]),
                arg.calldataBeta1,
                arg.calldataBeta2,
                arg.replacementPattern1,
                arg.replacementPattern2,
                arg.staticExtradata1,
                arg.staticExtradata2,
                _getVS(buySigs[i], sellSigs[i]),
                _getMetadata(buySigs[i], sellSigs[i], rssMetadata)
            ); 
        }
    }

    
}