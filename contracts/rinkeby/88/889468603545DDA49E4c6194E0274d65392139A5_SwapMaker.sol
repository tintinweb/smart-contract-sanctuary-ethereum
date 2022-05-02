// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SwapMaker {

    address public exchange = 0xdD54D660178B28f6033a953b0E55073cFA7e3744;
    address public registry = 0x1E525EEAF261cA41b809884CBDE9DD9E1619573A;

    address public merkleValidator = 0x45B594792a5CDc008D0dE1C1d69FAA3D16B3DDc1;

    Exchange.Order maker;
    Exchange.Order taker;

    address public token;

     function initialize(address token_) external {
        exchange     = 0xdD54D660178B28f6033a953b0E55073cFA7e3744;

        bytes4 sig = 0x11223344;

        taker = Exchange.Order({
            exchange: exchange,
            maker: address(this),
            taker: address(0),
            makerRelayerFee: 0,
            takerRelayerFee: 0,
            makerProtocolFee: 0,
            takerProtocolFee: 0,
            feeRecipient: address (1),
            feeMethod: Exchange.FeeMethod.SplitFee,
            side: SaleKindInterface.Side.Sell,
            saleKind: SaleKindInterface.SaleKind.FixedPrice,
            target: merkleValidator,
            howToCall: AuthenticatedProxy.HowToCall.Call,
            calldata_: bytes(abi.encodePacked(sig)),
            replacementPattern: new bytes(0),
            staticTarget: address(0),
            staticExtradata: new bytes(0),
            paymentToken: address(0),
            basePrice: 0,
            extra: 0,
            listingTime: block.timestamp - 10,
            expirationTime: 0,
            salt: 40323182231327385725865299976982511354469782358155157811418526517446722954777
        });

        maker = Exchange.Order({
            exchange: exchange,
            maker: address(this),
            taker: address(0),
            makerRelayerFee: 0,
            takerRelayerFee: 0,
            makerProtocolFee: 0,
            takerProtocolFee: 0,
            feeRecipient: address (0),
            feeMethod: Exchange.FeeMethod.SplitFee,
            side: SaleKindInterface.Side.Buy,
            saleKind: SaleKindInterface.SaleKind.FixedPrice,
            target: merkleValidator,
            howToCall: AuthenticatedProxy.HowToCall.Call,
            calldata_: bytes(abi.encodePacked(sig)),
            replacementPattern: new bytes(0),
            staticTarget: address(0),
            staticExtradata: new bytes(0),
            paymentToken: address(0),
            basePrice: 0,
            extra: 0,
            listingTime: block.timestamp - 10,
            expirationTime: 0,
            salt: 40323182231327385725865299976982511354469782358155157811418526517446722954777
        });

        token = token_;

        WyvernProxyRegistry(registry).registerProxy();
    }

    function swap() external {

        address[14] memory adds = [ 
            maker.exchange, 
            maker.maker, 
            maker.taker, 
            maker.feeRecipient, 
            maker.target, 
            maker.staticTarget, 
            maker.paymentToken, 
            taker.exchange, 
            taker.maker, 
            taker.taker, 
            taker.feeRecipient, 
            taker.target, 
            taker.staticTarget, 
            taker.paymentToken
        ];

        uint[18] memory nums = [
            uint256(maker.makerRelayerFee),
            maker.takerRelayerFee,
            maker.makerProtocolFee,
            maker.takerProtocolFee,
            maker.basePrice,
            maker.extra,
            maker.listingTime,
            maker.expirationTime,
            maker.salt,
            taker.makerRelayerFee,
            taker.takerRelayerFee,
            taker.makerProtocolFee,
            taker.takerProtocolFee,
            taker.basePrice,
            taker.extra,
            taker.listingTime,
            taker.expirationTime,
            taker.salt
        ];

        uint8[8] memory methods = [
            uint8(maker.feeMethod),
            uint8(maker.side),
            uint8(maker.saleKind),
            uint8(maker.howToCall),
            uint8(taker.feeMethod),
            uint8(taker.side),
            uint8(taker.saleKind),
            uint8(taker.howToCall)
        ];

        bytes memory swapData = encodeFakeSwap(address(2), address(3), address(token), 22);
        // Buy order come first and sell later

        Exchange(exchange).atomicMatch_(adds, nums, methods, swapData, swapData, new bytes(0), new bytes(0), new bytes(0), new bytes(0), [uint8(0), 0], [bytes32(0),bytes32(0),bytes32(0),bytes32(0),bytes32(0)]);
    }

    // function canMatck() external view returns(bool) {

    //     address[14] memory adds = [ 
    //         maker.exchange, 
    //         maker.maker, 
    //         maker.taker, 
    //         maker.feeRecipient, 
    //         maker.target, 
    //         maker.staticTarget, 
    //         maker.paymentToken, 
    //         taker.exchange, 
    //         taker.maker, 
    //         taker.taker, 
    //         taker.feeRecipient, 
    //         taker.target, 
    //         taker.staticTarget, 
    //         taker.paymentToken
    //     ];

    //     uint[18] memory nums = [
    //         uint256(maker.makerRelayerFee),
    //         maker.takerRelayerFee,
    //         maker.makerProtocolFee,
    //         maker.takerProtocolFee,
    //         maker.basePrice,
    //         maker.extra,
    //         maker.listingTime,
    //         maker.expirationTime,
    //         maker.salt,
    //         taker.makerRelayerFee,
    //         taker.takerRelayerFee,
    //         taker.makerProtocolFee,
    //         taker.takerProtocolFee,
    //         taker.basePrice,
    //         taker.extra,
    //         taker.listingTime,
    //         taker.expirationTime,
    //         taker.salt
    //     ];

    //     uint8[8] memory methods = [
    //         uint8(maker.feeMethod),
    //         uint8(maker.side),
    //         uint8(maker.saleKind),
    //         uint8(maker.howToCall),
    //         uint8(taker.feeMethod),
    //         uint8(taker.side),
    //         uint8(taker.saleKind),
    //         uint8(taker.howToCall)
    //     ];


    //     return Exchange(exchange).ordersCanMatch_(adds, nums, methods, maker.calldata_, maker.calldata_, new bytes(0), new bytes(0), new bytes(0), new bytes(0));
    //}

    function encodeFakeSwap(address from, address to, address token , uint256 tokenId) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(IMerkleValidator.matchERC721UsingCriteria.selector, from, to, token, tokenId, bytes32(0), new bytes32[](0));
    }

    event De(uint val);

    fallback() external {
        // emit De(122);
    }

}

contract OrderMakerRinkeby {

    address public exchange = 0xdD54D660178B28f6033a953b0E55073cFA7e3744;
    address public maker;
    address public taker;
    address public feeRecipient;
    address public target;
    address public staticTarget;
    address public paymentToken;

    uint256 public makerRelayerFee;
    uint256 public takerRelayerFee;
    uint256 public makerProtocolFee;
    uint256 public takerProtocolFee;
    uint256 public basePrice;
    uint256 public extra;
    uint256 public listingTime;
    uint256 public expirationTime;
    uint256 public salt;

    constructor() {
        exchange     = 0xdD54D660178B28f6033a953b0E55073cFA7e3744;
        maker        = address(this);
        taker        = address(0);
        feeRecipient = 0x5b3256965e7C3cF26E11FCAf296DfC8807C01073;
        target       = 0x45B594792a5CDc008D0dE1C1d69FAA3D16B3DDc1;
        staticTarget = address(0);
        paymentToken = 0xc778417E063141139Fce010982780140Aa0cD5Ab;

        basePrice = 0.05 ether;
        takerRelayerFee = 250;

        salt = 40323182231327385725865299976982511354469782358155157811418526517446722954960;

    }

    function makeOrder() external {

        address[7] memory adds = [
            exchange,
            address(this),
            taker,
            feeRecipient,
            target,
            staticTarget,
            paymentToken
        ];

        uint256[9] memory nums = [
            makerRelayerFee,
            takerRelayerFee,
            makerProtocolFee,
            takerProtocolFee,
            basePrice,
            extra,
            block.timestamp,
            expirationTime,
            salt
        ];

        bytes memory calldata_ = "0xfb16a5950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000749c4dfe59667a22c7390ec808dd327ded6015f800000000000000000000000027af21619746a2abb01d3056f971cde9361459390000000000000000000000000000000000000000000000000000000000000aed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000";
        bytes memory replacementP = "0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        Exchange(exchange).approveOrder_(adds, nums, Exchange.FeeMethod.SplitFee, SaleKindInterface.Side.Buy, SaleKindInterface.SaleKind.FixedPrice, AuthenticatedProxy.HowToCall.DelegateCall, calldata_, replacementP, new bytes(0), true);
    }

    function validateOrder() external view returns (bool) {
        address[7] memory adds = [
            exchange,
            address(this),
            taker,
            feeRecipient,
            target,
            staticTarget,
            paymentToken
        ];

        uint256[9] memory nums = [
            makerRelayerFee,
            takerRelayerFee,
            makerProtocolFee,
            takerProtocolFee,
            basePrice,
            extra,
            block.timestamp,
            expirationTime,
            salt
        ];

        bytes memory calldata_ = "0xfb16a5950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000749c4dfe59667a22c7390ec808dd327ded6015f800000000000000000000000027af21619746a2abb01d3056f971cde9361459390000000000000000000000000000000000000000000000000000000000000aed000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c00000000000000000000000000000000000000000000000000000000000000000";
        bytes memory replacementP = "0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

        Exchange(exchange).validateOrderParameters_(adds, nums, Exchange.FeeMethod.SplitFee, SaleKindInterface.Side.Buy, SaleKindInterface.SaleKind.FixedPrice, AuthenticatedProxy.HowToCall.DelegateCall, calldata_, replacementP, new bytes(0));

    }


    function setExchange(address add_) external {
        exchange = add_;
    }

    function setMaker(address add_) external {
        maker = add_;
    }

    function setTaker(address add_) external {
        taker = add_;
    }

    function setFeeRecipient(address add_) external {
        feeRecipient = add_;
    }

    function setTarget(address add_) external {
        target = add_;
    }

    function setStaticTarget(address add_) external {
        staticTarget = add_;
    }

    function setPaymentToken(address add_) external {
        paymentToken = add_;
    }

    function setMakerRelayerFee(uint256 num_) external {
        makerRelayerFee = num_;
    }

    function setTakerRelayerFee(uint256 num_) external {
        takerRelayerFee = num_;
    }

    function setMakerProtocolFee(uint256 num_) external {
        makerProtocolFee = num_;
    }

    function setTakerProtocolFee(uint256 num_) external {
        takerProtocolFee = num_;
    }

    function setBasePrice(uint256 num_) external {
        basePrice = num_;
    }

    function setExtra(uint256 num_) external {
        extra = num_;
    }

    function setExpirationTime(uint256 num_) external {
        expirationTime = num_;
    }

    function setSalt(uint256 num_) external {
        salt = num_;
    }


}

interface Exchange {

    /* Fee method: protocol fee or split fee. */
    enum FeeMethod { ProtocolFee, SplitFee }


    /* An ECDSA signature. */
    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
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
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes calldata_;
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
        /* NOTE: uint nonce is an additional component of the order but is read from storage */
    }

    function approveOrder_ ( address[7] calldata addrs, uint[9] calldata uints, FeeMethod feeMethod, SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, AuthenticatedProxy.HowToCall howToCall, bytes calldata calldatas, bytes calldata replacementPattern, bytes calldata staticExtradata, bool orderbookInclusionDesired) external;
    function hashOrder_( address[7] calldata addrs, uint[9] calldata uints, FeeMethod feeMethod, SaleKindInterface.Side side, SaleKindInterface.SaleKind saleKind, AuthenticatedProxy.HowToCall howToCall, bytes calldata calldata_, bytes calldata replacementPattern, bytes calldata staticExtradata) external view returns (bytes32);
    function validateOrderParameters_ (address[7] calldata addrs,uint[9] calldata uints,FeeMethod feeMethod,SaleKindInterface.Side side,SaleKindInterface.SaleKind saleKind,AuthenticatedProxy.HowToCall howToCall,bytes calldata calldatas,bytes calldata replacementPattern,bytes calldata staticExtradata) view external returns (bool);
    function atomicMatch_( address[14] calldata addrs, uint[18] calldata uints, uint8[8] calldata feeMethodsSidesKindsHowToCalls, bytes calldata calldataBuy, bytes calldata calldataSell, bytes calldata replacementPatternBuy, bytes calldata replacementPatternSell, bytes calldata staticExtradataBuy, bytes calldata staticExtradataSell, uint8[2] calldata vs, bytes32[5] calldata rssMetadata) external payable;
    function ordersCanMatch_( address[14] calldata addrs, uint[18] calldata uints, uint8[8] calldata feeMethodsSidesKindsHowToCalls, bytes calldata calldataBuy, bytes calldata calldataSell, bytes calldata replacementPatternBuy, bytes calldata replacementPatternSell, bytes calldata staticExtradataBuy, bytes calldata staticExtradataSell) external view returns (bool);
}

library SaleKindInterface {

    /**
     * Side: buy or sell.
     */
    enum Side { Buy, Sell }

    /**
     * Currently supported kinds of sale: fixed price, Dutch auction.
     * English auctions cannot be supported without stronger escrow guarantees.
     * Future interesting options: Vickrey auction, nonlinear Dutch auctions.
     */
    enum SaleKind { FixedPrice, DutchAuction }

}

interface AuthenticatedProxy {

    enum HowToCall { Call, DelegateCall }

}

interface WyvernProxyRegistry {
    function registerProxy() external returns (address);
}

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IMerkleValidator {

    /// @dev Match an ERC721 order, ensuring that the supplied proof demonstrates inclusion of the tokenId in the associated merkle root.
    /// @param from The account to transfer the ERC721 token from — this token must first be approved on the seller's AuthenticatedProxy contract.
    /// @param to The account to transfer the ERC721 token to.
    /// @param token The ERC721 token to transfer.
    /// @param tokenId The ERC721 tokenId to transfer.
    /// @param root A merkle root derived from each valid tokenId — set to 0 to indicate a collection-level or tokenId-specific order.
    /// @param proof A proof that the supplied tokenId is contained within the associated merkle root. Must be length 0 if root is not set.
    /// @return A boolean indicating a successful match and transfer.
    function matchERC721UsingCriteria(
        address from,
        address to,
        IERC721 token,
        uint256 tokenId,
        bytes32 root,
        bytes32[] calldata proof
    ) external returns (bool);
}