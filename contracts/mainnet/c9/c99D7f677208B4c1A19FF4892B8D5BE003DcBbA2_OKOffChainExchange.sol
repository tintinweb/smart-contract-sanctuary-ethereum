// SPDX-License-Identifier: MIT
pragma solidity 0.4.26;

import "./OKRoyaltyFeeManager.sol";
import "./interfaces/SafeMath.sol";
import "./interfaces/MyTools.sol";
import "./interfaces/ArrayUtils.sol";
import "./interfaces/SaleKindInterface.sol";
import "./TransferNFTManager.sol";
import "./base/TokenRecipient.sol";
import "./base/Proxy.sol";
import "./base/ReentrancyGuarded.sol";
import "./base/ProxyRegistry.sol";
import "./base/OwnedUpgradeabilityStorage.sol";
import "./base/AuthenticatedProxy.sol";

/**
 * @title ExchangeCore
 * @author Project Wyvern Developers
 */
contract ExchangeCore is ReentrancyGuarded, Ownable {
    /* The token used to pay exchange fees.
        版税支付的token
    */
    ERC20 public exchangeToken;

    /* User registry. */
    ProxyRegistry public registry;

    /* Token transfer proxy. */
    TokenTransferProxy public tokenTransferProxy;

    /* Cancelled / finalized orders, by hash. */
    mapping(bytes32 => bool) public cancelledOrFinalized;

    /* Orders verified by on-chain approval (alternative to ECDSA signatures so that smart contracts can place orders directly). */
    mapping(bytes32 => bool) public approvedOrders;

    OKRoyaltyFeeManager public okRoyaltyFeeManager;

    /* For split fee orders, minimum required protocol maker fee, in basis points. Paid to owner (who can change it). */
    uint256 public minimumMakerProtocolFee = 0;

    /* For split fee orders, minimum required protocol taker fee, in basis points. Paid to owner (who can change it). */
    uint256 public minimumTakerProtocolFee = 0;

    /* Recipient of protocol fees. */
    //协议费（版税）的接收地址
    address public protocolFeeRecipient;

    /* Fee method: protocol fee or split fee. */
    enum FeeMethod {
        ProtocolFee,
        SplitFee
    }

    /* Inverse basis point. */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    struct TempData {
        address nftOwner;
        address buyerAddress;
        address nftContract;
        uint256 transferTokenIdSell;
        uint256 transferTokenIdBuy;
        bytes functionName;
        bytes result;
        bytes calldataValue;
        uint256 tokenId;
        uint256 sellAmount;
        uint256 buyAmount;
    }

    TempData tempData;

    using SafeMath for uint256;

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
        SaleKindInterface.Side side;
        /* Kind of sale. */
        SaleKindInterface.SaleKind saleKind;
        /* Target. */
        address target;
        /* HowToCall. */
        AuthenticatedProxy.HowToCall howToCall;
        /* Calldata. */
        bytes calldata;
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
        /* Auction extra parameter - minimum bid increment for English auctions, starting/ending price difference. */
        uint256 extra;
        /* Listing timestamp. */
        uint256 listingTime;
        /* Expiration timestamp - 0 for no expiry. */
        uint256 expirationTime;
        /* Order salt, used to prevent duplicate hashes. */
        uint256 salt;
    }

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
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        address target
    );
    event OrderApprovedPartTwo(
        bytes32 indexed hash,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
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

    function setupCopyrightMap(OKRoyaltyFeeManager feeManager)
        public
        onlyOwner
    {
        okRoyaltyFeeManager = feeManager;
    }

    /**
     * @dev Change the minimum maker fee paid to the protocol (owner only)
     * @param newMinimumMakerProtocolFee New fee to set in basis points
     */
    function changeMinimumMakerProtocolFee(uint256 newMinimumMakerProtocolFee)
        public
        onlyOwner
    {
        minimumMakerProtocolFee = newMinimumMakerProtocolFee;
    }

    /**
     * @dev Change the minimum taker fee paid to the protocol (owner only)
     * @param newMinimumTakerProtocolFee New fee to set in basis points
     */
    function changeMinimumTakerProtocolFee(uint256 newMinimumTakerProtocolFee)
        public
        onlyOwner
    {
        minimumTakerProtocolFee = newMinimumTakerProtocolFee;
    }

    /**
     * @dev Change the protocol fee recipient (owner only)
     * @param newProtocolFeeRecipient New protocol fee recipient address
     */
    function changeProtocolFeeRecipient(address newProtocolFeeRecipient)
        public
        onlyOwner
    {
        protocolFeeRecipient = newProtocolFeeRecipient;
    }

    /**
     * @dev Transfer tokens
     * @param token Token to transfer
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function transferTokens(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            require(tokenTransferProxy.transferFrom(token, from, to, amount));
        }
    }

    /**
     * @dev Charge a fee in protocol tokens
     * @param from Address to charge fees
     * @param to Address to receive fees
     * @param amount Amount of protocol tokens to charge
     */
    function chargeProtocolFee(
        address from,
        address to,
        uint256 amount
    ) internal {
        transferTokens(exchangeToken, from, to, amount);
    }

    /**
     * @dev Execute a STATICCALL (introduced with Ethereum Metropolis, non-state-modifying external call)
     * @param target Contract to call
     * @param calldata Calldata (appended to extradata)
     * @param extradata Base data for STATICCALL (probably function selector and argument encoding)
     * @return The result of the call (success or failure)
     */
    function staticCall(
        address target,
        bytes memory calldata,
        bytes memory extradata
    ) public view returns (bool result) {
        bytes memory combined = new bytes(calldata.length + extradata.length);
        uint256 index;
        assembly {
            index := add(combined, 0x20)
        }
        index = ArrayUtils.unsafeWriteBytes(index, extradata);
        ArrayUtils.unsafeWriteBytes(index, calldata);
        assembly {
            result := staticcall(
                gas,
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
     * Calculate size of an order struct when tightly packed
     *
     * @param order Order to calculate size of
     * @return Size in bytes
     */
    function sizeOf(Order memory order) internal pure returns (uint256) {
        return ((0x14 * 7) +
            (0x20 * 9) +
            4 +
            order.calldata.length +
            order.replacementPattern.length +
            order.staticExtradata.length);
    }

    /**
     * @dev Hash an order, returning the canonical order hash, without the message prefix
     * @param order Order to hash
     * @return Hash of order
     */
    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 hash)
    {
        /* Unfortunately abi.encodePacked doesn't work here, stack size constraints. */
        uint256 size = sizeOf(order);
        bytes memory array = new bytes(size);
        uint256 index;
        assembly {
            index := add(array, 0x20)
        }
        index = ArrayUtils.unsafeWriteAddress(index, order.exchange);
        index = ArrayUtils.unsafeWriteAddress(index, order.maker);
        index = ArrayUtils.unsafeWriteAddress(index, order.taker);
        index = ArrayUtils.unsafeWriteUint(index, order.makerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerRelayerFee);
        index = ArrayUtils.unsafeWriteUint(index, order.makerProtocolFee);
        index = ArrayUtils.unsafeWriteUint(index, order.takerProtocolFee);
        index = ArrayUtils.unsafeWriteAddress(index, order.feeRecipient);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.feeMethod));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.side));
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.saleKind));
        index = ArrayUtils.unsafeWriteAddress(index, order.target);
        index = ArrayUtils.unsafeWriteUint8(index, uint8(order.howToCall));
        index = ArrayUtils.unsafeWriteBytes(index, order.calldata);
        index = ArrayUtils.unsafeWriteBytes(index, order.replacementPattern);
        index = ArrayUtils.unsafeWriteAddress(index, order.staticTarget);
        index = ArrayUtils.unsafeWriteBytes(index, order.staticExtradata);
        index = ArrayUtils.unsafeWriteAddress(index, order.paymentToken);
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

    /**
     * @dev Hash an order, returning the hash that a client must sign, including the standard message prefix
     * @param order Order to hash
     * @return Hash of message prefix and order hash per Ethereum format
     */
    function hashToSign(Order memory order) internal pure returns (bytes32) {
        return keccak256("\x19Ethereum Signed Message:\n32", hashOrder(order));
    }

    /**
     * @dev Assert an order is valid and return its hash
     * @param order Order to validate
     * @param sig ECDSA signature
     */
    function requireValidOrder(Order memory order, Sig memory sig)
        internal
        view
        returns (bytes32)
    {
        bytes32 hash = hashToSign(order);
        require(validateOrder(hash, order, sig));
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

        /* Order must possess valid sale kind parameter combination. */
        if (
            !SaleKindInterface.validateParameters(
                order.saleKind,
                order.expirationTime
            )
        ) {
            return false;
        }

        /* If using the split fee method, order must have sufficient protocol fees. */
        if (
            order.feeMethod == FeeMethod.SplitFee &&
            (order.makerProtocolFee < minimumMakerProtocolFee ||
                order.takerProtocolFee < minimumTakerProtocolFee)
        ) {
            return false;
        }

        //这里验证支付token是否合法 TODO

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

        /* Order authentication. Order must be either:
        /* (a) previously approved */
        if (approvedOrders[hash]) {
            return true;
        }

        /* or (b) ECDSA-signed by maker. */
        if (ecrecover(hash, sig.v, sig.r, sig.s) == order.maker) {
            return true;
        }

        return false;
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
        require(msg.sender == order.maker);

        /* Calculate order hash. */
        bytes32 hash = hashToSign(order);

        /* Assert order has not already been approved. */
        require(!approvedOrders[hash]);

        /* EFFECTS */

        /* Mark order as approved. */
        approvedOrders[hash] = true;

        /* Log approval event. Must be split in two due to Solidity stack size limitations. */
        {
            emit OrderApprovedPartOne(
                hash,
                order.exchange,
                order.maker,
                order.taker,
                order.makerRelayerFee,
                order.takerRelayerFee,
                order.makerProtocolFee,
                order.takerProtocolFee,
                order.feeRecipient,
                order.feeMethod,
                order.side,
                order.saleKind,
                order.target
            );
        }
        {
            emit OrderApprovedPartTwo(
                hash,
                order.howToCall,
                order.calldata,
                order.replacementPattern,
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
     * @param sig ECDSA signature
     */
    function cancelOrder(Order memory order, Sig memory sig) internal {
        /* CHECKS */

        /* Calculate order hash. */
        bytes32 hash = requireValidOrder(order, sig);

        /* Assert sender is authorized to cancel order. */
        require(msg.sender == order.maker);

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
        require(buyPrice >= sellPrice);

        /* Maker/taker priority. */
        return sell.feeRecipient != address(0) ? sellPrice : buyPrice;
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
            require(msg.value == 0);
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

        /* (卖家挂单买家吃单)Determine maker/taker and charge fees accordingly.只要sell一方的recipient 不为0 就是卖家挂单 买家吃单 */
        if (sell.feeRecipient != address(0)) {
            /* Sell-side order is maker. */

            /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
            require(sell.takerRelayerFee <= buy.takerRelayerFee);

            tempData.calldataValue = sell.calldata;
            tempData.result = MyTools.getSlice(69, 100, tempData.calldataValue);
            tempData.tokenId = MyTools.bytesToUint(tempData.result);
            //版税
            (
                address royaltyFeeRecipient,
                uint256 royaltyFeeAmount
            ) = okRoyaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(
                    sell.target,
                    tempData.tokenId,
                    price
                );

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* Assert taker fee is less than or equal to maximum fee specified by buyer. */
                require(sell.takerProtocolFee <= buy.takerProtocolFee);

                //有版税先收版税 (卖家挂单买家吃单) 剩下的应收再去处理手续费 这里要判断是否使用主链币
                if (price > 0 && sell.paymentToken == address(0)) {
                    receiveAmount = receiveAmount.sub(royaltyFeeAmount);

                    royaltyFeeRecipient.transfer(royaltyFeeAmount);
                }
                //ERC20 收版税 (卖家挂单买家吃单) 卖家直接出版税给版税所有者
                if (price > 0 && sell.paymentToken != address(0)) {
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        royaltyFeeRecipient,
                        royaltyFeeAmount
                    );
                }

                /* Maker fees are deducted from the token amount that the maker receives. Taker fees are extra tokens that must be paid by the taker. */
                //卖家挂单 买家吃单的场景下 sell.makerRelayerFee必然有值
                if (sell.makerRelayerFee > 0) {
                    //uint makerRelayerFee = SafeMath.div(SafeMath.mul(sell.makerRelayerFee, price), INVERSE_BASIS_POINT);
                    uint256 makerRelayerFee = sell
                        .makerRelayerFee
                        .mul(price)
                        .div(INVERSE_BASIS_POINT);
                    if (sell.paymentToken == address(0)) {
                        //receiveAmount = SafeMath.sub(receiveAmount, makerRelayerFee);
                        receiveAmount = receiveAmount.sub(makerRelayerFee);
                        //此时的taker是买家，msg.sender是买家
                        sell.feeRecipient.transfer(makerRelayerFee);
                    } else {
                        //如果挂单者是卖家，向卖家收2.5%的手续费
                        //function transferTokens(address token, address from, address to, uint amount)
                        //手续费
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            sell.feeRecipient,
                            makerRelayerFee
                        );
                    }
                }

                if (sell.takerRelayerFee > 0) {
                    //uint takerRelayerFee = SafeMath.div(SafeMath.mul(sell.takerRelayerFee, price), INVERSE_BASIS_POINT);
                    uint256 takerRelayerFee = sell
                        .takerRelayerFee
                        .mul(price)
                        .div(INVERSE_BASIS_POINT);

                    if (sell.paymentToken == address(0)) {
                        //requiredAmount = SafeMath.add(requiredAmount, takerRelayerFee);
                        requiredAmount = requiredAmount.add(takerRelayerFee);
                        //此时的taker是卖家，msg.sender是卖家
                        sell.feeRecipient.transfer(takerRelayerFee);
                    } else {
                        //如果挂单者是买家，向买家收2.5%的手续费
                        //function transferTokens(address token, address from, address to, uint amount)
                        transferTokens(
                            sell.paymentToken,
                            buy.maker,
                            sell.feeRecipient,
                            takerRelayerFee
                        );
                    }
                }

                //协议费
                if (sell.makerProtocolFee > 0) {
                    //uint makerProtocolFee = SafeMath.div(SafeMath.mul(sell.makerProtocolFee, price), INVERSE_BASIS_POINT);
                    uint256 makerProtocolFee = sell
                        .makerProtocolFee
                        .mul(price)
                        .div(INVERSE_BASIS_POINT);

                    if (sell.paymentToken == address(0)) {
                        //买家吃单，卖家的应收金额 = 应收金额 - 版税
                        //receiveAmount = SafeMath.sub(receiveAmount, makerProtocolFee);
                        receiveAmount = receiveAmount.sub(makerProtocolFee);

                        protocolFeeRecipient.transfer(makerProtocolFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            sell.maker,
                            protocolFeeRecipient,
                            makerProtocolFee
                        );
                    }
                }

                if (sell.takerProtocolFee > 0) {
                    uint256 takerProtocolFee = SafeMath.div(
                        SafeMath.mul(sell.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    if (sell.paymentToken == address(0)) {
                        //卖家接单，应付金额 = 应付金额 + 版税 （版税在payCopyRight划走，最后计算出一个 应付金额）
                        //requiredAmount = SafeMath.add(requiredAmount, takerProtocolFee);
                        requiredAmount = requiredAmount.add(takerProtocolFee);
                        protocolFeeRecipient.transfer(takerProtocolFee);
                    } else {
                        transferTokens(
                            sell.paymentToken,
                            buy.maker,
                            protocolFeeRecipient,
                            takerProtocolFee
                        );
                    }
                }
            } else {
                /* Charge maker fee to seller. */
                chargeProtocolFee(
                    sell.maker,
                    sell.feeRecipient,
                    sell.makerRelayerFee
                );

                /* Charge taker fee to buyer. */
                chargeProtocolFee(
                    buy.maker,
                    sell.feeRecipient,
                    sell.takerRelayerFee
                );
            }
        } else {
            /* Buy-side order is maker. */
            //（买家出价 卖家接单） 因为卖家一开始已经收到了20代币，所以这里都是卖家直接给手续费或者版税

            /* Assert taker fee is less than or equal to maximum fee specified by seller. */
            require(buy.takerRelayerFee <= sell.takerRelayerFee);

            if (sell.feeMethod == FeeMethod.SplitFee) {
                /* The Exchange does not escrow Ether, so direct Ether can only be used to with sell-side maker / buy-side taker orders. */
                require(sell.paymentToken != address(0));

                /* Assert taker fee is less than or equal to maximum fee specified by seller. */
                require(buy.takerProtocolFee <= sell.takerProtocolFee);

                //版税
                (royaltyFeeRecipient, royaltyFeeAmount) = okRoyaltyFeeManager
                    .calculateRoyaltyFeeAndGetRecipient(
                        sell.target,
                        tempData.tokenId,
                        price
                    );

                //ERC20 收版税 (卖家挂单买家吃单) 卖家直接出版税给版税所有者
                if (price > 0 && sell.paymentToken != address(0)) {
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        royaltyFeeRecipient,
                        royaltyFeeAmount
                    );
                }

                //(买家出价 卖家接单)不会大于0
                if (buy.makerRelayerFee > 0) {
                    makerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.makerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    //makerRelayerFee = buy.makerRelayerFee.mul(price).div(INVERSE_BASIS_POINT);
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        buy.feeRecipient,
                        makerRelayerFee
                    );
                }

                //(买家出价 卖家接单)此时有值
                if (buy.takerRelayerFee > 0) {
                    takerRelayerFee = SafeMath.div(
                        SafeMath.mul(buy.takerRelayerFee, price),
                        INVERSE_BASIS_POINT
                    );
                    //takerRelayerFee = buy.takerRelayerFee.mul(price).div(INVERSE_BASIS_POINT);
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        buy.feeRecipient,
                        takerRelayerFee
                    );
                }

                if (buy.makerProtocolFee > 0) {
                    makerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.makerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    //makerProtocolFee = buy.makerProtocolFee.mul(price).div(INVERSE_BASIS_POINT);
                    transferTokens(
                        sell.paymentToken,
                        buy.maker,
                        protocolFeeRecipient,
                        makerProtocolFee
                    );
                }

                if (buy.takerProtocolFee > 0) {
                    takerProtocolFee = SafeMath.div(
                        SafeMath.mul(buy.takerProtocolFee, price),
                        INVERSE_BASIS_POINT
                    );
                    //takerProtocolFee = buy.takerProtocolFee.mul(price).div(INVERSE_BASIS_POINT);
                    transferTokens(
                        sell.paymentToken,
                        sell.maker,
                        protocolFeeRecipient,
                        takerProtocolFee
                    );
                }
            } else {
                /* Charge maker fee to buyer. */
                chargeProtocolFee(
                    buy.maker,
                    buy.feeRecipient,
                    buy.makerRelayerFee
                );

                /* Charge taker fee to seller. */
                chargeProtocolFee(
                    sell.maker,
                    buy.feeRecipient,
                    buy.takerRelayerFee
                );
            }
        }

        if (sell.paymentToken == address(0)) {
            /* Special-case Ether, order must be matched by buyer. */
            require(msg.value >= requiredAmount);
            sell.maker.transfer(receiveAmount);
            /* Allow overshoot for variable-price auctions, refund difference. */
            //uint diff = SafeMath.sub(msg.value, requiredAmount);
            uint256 diff = msg.value.sub(requiredAmount);
            if (diff > 0) {
                buy.maker.transfer(diff);
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
            /* Must use same fee method. */
            (buy.feeMethod == sell.feeMethod) &&
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

    TransferNFTManager public transferManager;

    function setTransferManager(TransferNFTManager _transferManager)
        public
        onlyOwner
    {
        transferManager = _transferManager;
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

        if (buy.maker == msg.sender) {
            require(validateOrderParameters(buy));
        } else {
            buyHash = requireValidOrder(buy, buySig);
        }

        /* Ensure sell order validity and calculate hash if necessary. */
        bytes32 sellHash;
        if (sell.maker == msg.sender) {
            require(validateOrderParameters(sell));
        } else {
            sellHash = requireValidOrder(sell, sellSig);
        }

        /* Must be matchable. */
        require(ordersCanMatch(buy, sell));

        /* Target must exist (prevent malicious selfdestructs just prior to order settlement). */
        uint256 size;
        address target = sell.target;
        assembly {
            size := extcodesize(target)
        }
        require(size > 0);

        /* Must match calldata after replacement, if specified. */
        if (buy.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                buy.calldata,
                sell.calldata,
                buy.replacementPattern
            );
        }
        if (sell.replacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                sell.calldata,
                buy.calldata,
                sell.replacementPattern
            );
        }

        require(ArrayUtils.arrayEq(buy.calldata, sell.calldata));

        /* Retrieve delegateProxy contract. */
        OwnableDelegateProxy delegateProxy = registry.proxies(sell.maker);

        /* EFFECTS */

        /* Mark previously signed or approved orders as finalized. */
        if (msg.sender != buy.maker) {
            cancelledOrFinalized[buyHash] = true;
        }
        if (msg.sender != sell.maker) {
            cancelledOrFinalized[sellHash] = true;
        }

        /* INTERACTIONS */

        /* Execute funds transfer and pay fees. */
        uint256 price = executeFundsTransfer(buy, sell);

        require(uint256(sell.howToCall)==0,"DelegateCall mode is not supported");

        /* Execute specified call through proxy. */
        //require(proxy.proxy(sell.target, sell.howToCall, sell.calldata));
        //这里可以再扩展一层，用于address[4]指定一个扩展合约
        if (delegateProxy != address(0)) {
            require(
                delegateProxy.implementation() ==
                    registry.delegateProxyImplementation()
            );

            AuthenticatedProxy proxy = AuthenticatedProxy(delegateProxy);

            require(proxy.proxy(sell.target, sell.howToCall, sell.calldata));
        } else {
            //safeTransferFrom from  to tokenId
            //verify from
            tempData.functionName = MyTools.getSlice(1, 4, sell.calldata);
            tempData.result = MyTools.getSlice(5, 36, sell.calldata);
            tempData.result = MyTools.getSlice(13, 32, tempData.result);
            tempData.nftOwner = MyTools.bytesToAddress(tempData.result);
            require(
                sell.maker == tempData.nftOwner,
                "the sell's maker is not nftOwner!"
            );

            //verify tokenId
            tempData.result = MyTools.getSlice(69, 100, sell.calldata);
            tempData.result = MyTools.getSlice(13, 32, tempData.result);
            tempData.transferTokenIdSell = MyTools.bytesToUint(tempData.result);

            tempData.result = MyTools.getSlice(69, 100, buy.calldata);
            tempData.result = MyTools.getSlice(13, 32, tempData.result);
            tempData.transferTokenIdBuy = MyTools.bytesToUint(tempData.result);

            require(
                tempData.transferTokenIdBuy == tempData.transferTokenIdSell,
                "the target tokenId is not match!"
            );

            //require(sell.target==nftContract,"the nftContract is not target!");
            if (sell.calldata.length > 100) {
                tempData.result = MyTools.getSlice(101, 132, sell.calldata);
                tempData.sellAmount = MyTools.bytesToUint(tempData.result);

                tempData.result = MyTools.getSlice(101, 132, buy.calldata);
                tempData.buyAmount = MyTools.bytesToUint(tempData.result);
                require(
                    tempData.sellAmount == tempData.buyAmount,
                    "buy amount and sell amount not match!"
                );
            }
            bool callResult = transferManager.proxy(
                sell.target,
                uint256(sell.howToCall),
                sell.calldata
            );
            require(callResult, "nft transfer failed");
        }

        /* Static calls are intentionally done after the effectful call so they can check resulting state. */

        /* Handle buy-side static call if specified. */
        if (buy.staticTarget != address(0)) {
            require(
                staticCall(buy.staticTarget, sell.calldata, buy.staticExtradata)
            );
        }

        /* Handle sell-side static call if specified. */
        if (sell.staticTarget != address(0)) {
            require(
                staticCall(
                    sell.staticTarget,
                    sell.calldata,
                    sell.staticExtradata
                )
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
}

contract Exchange is ExchangeCore {
    /**
     * @dev Call guardedArrayReplace - library function exposed for testing.
     */
    function guardedArrayReplace(
        bytes array,
        bytes desired,
        bytes mask
    ) public pure returns (bytes) {
        ArrayUtils.guardedArrayReplace(array, desired, mask);
        return array;
    }

    /**
     * @dev Call calculateFinalPrice - library function exposed for testing.
     */
    function calculateFinalPrice(
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        uint256 basePrice,
        uint256 extra,
        uint256 listingTime,
        uint256 expirationTime
    ) public view returns (uint256) {
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
     * @dev Call hashOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashOrder_(
        address[7] addrs,
        uint256[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata
    ) public pure returns (bytes32) {
        return
            hashOrder(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    calldata,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    ERC20(addrs[6]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                )
            );
    }

    /**
     * @dev Call hashToSign - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function hashToSign_(
        address[7] addrs,
        uint256[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata
    ) public pure returns (bytes32) {
        return
            hashToSign(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    calldata,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    ERC20(addrs[6]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                )
            );
    }

    /**
     * @dev Call validateOrderParameters - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrderParameters_(
        address[7] addrs,
        uint256[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata
    ) public view returns (bool) {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[3],
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            calldata,
            replacementPattern,
            addrs[5],
            staticExtradata,
            ERC20(addrs[6]),
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return validateOrderParameters(order);
    }

    /**
     * @dev Call validateOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function validateOrder_(
        address[7] addrs,
        uint256[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns (bool) {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[3],
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            calldata,
            replacementPattern,
            addrs[5],
            staticExtradata,
            ERC20(addrs[6]),
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return validateOrder(hashToSign(order), order, Sig(v, r, s));
    }

    /**
     * @dev Call approveOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function approveOrder_(
        address[7] addrs,
        uint256[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        bool orderbookInclusionDesired
    ) public {
        Order memory order = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[3],
            feeMethod,
            side,
            saleKind,
            addrs[4],
            howToCall,
            calldata,
            replacementPattern,
            addrs[5],
            staticExtradata,
            ERC20(addrs[6]),
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        return approveOrder(order, orderbookInclusionDesired);
    }

    /**
     * @dev Call cancelOrder - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function cancelOrder_(
        address[7] addrs,
        uint256[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        return
            cancelOrder(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    calldata,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    ERC20(addrs[6]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                Sig(v, r, s)
            );
    }

    /**
     * @dev Call calculateCurrentPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateCurrentPrice_(
        address[7] addrs,
        uint256[9] uints,
        FeeMethod feeMethod,
        SaleKindInterface.Side side,
        SaleKindInterface.SaleKind saleKind,
        AuthenticatedProxy.HowToCall howToCall,
        bytes calldata,
        bytes replacementPattern,
        bytes staticExtradata
    ) public view returns (uint256) {
        return
            calculateCurrentPrice(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    feeMethod,
                    side,
                    saleKind,
                    addrs[4],
                    howToCall,
                    calldata,
                    replacementPattern,
                    addrs[5],
                    staticExtradata,
                    ERC20(addrs[6]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                )
            );
    }

    /**
     * @dev Call ordersCanMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function ordersCanMatch_(
        address[14] addrs,
        uint256[18] uints,
        uint8[8] feeMethodsSidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell
    ) public view returns (bool) {
        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[3],
            FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]),
            addrs[4],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]),
            calldataBuy,
            replacementPatternBuy,
            addrs[5],
            staticExtradataBuy,
            ERC20(addrs[6]),
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        Order memory sell = Order(
            addrs[7],
            addrs[8],
            addrs[9],
            uints[9],
            uints[10],
            uints[11],
            uints[12],
            addrs[10],
            FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]),
            addrs[11],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]),
            calldataSell,
            replacementPatternSell,
            addrs[12],
            staticExtradataSell,
            ERC20(addrs[13]),
            uints[13],
            uints[14],
            uints[15],
            uints[16],
            uints[17]
        );
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
        bytes buyCalldata,
        bytes buyReplacementPattern,
        bytes sellCalldata,
        bytes sellReplacementPattern
    ) public pure returns (bool) {
        if (buyReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                buyCalldata,
                sellCalldata,
                buyReplacementPattern
            );
        }
        if (sellReplacementPattern.length > 0) {
            ArrayUtils.guardedArrayReplace(
                sellCalldata,
                buyCalldata,
                sellReplacementPattern
            );
        }
        return ArrayUtils.arrayEq(buyCalldata, sellCalldata);
    }

    /**
     * @dev Call calculateMatchPrice - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function calculateMatchPrice_(
        address[14] addrs,
        uint256[18] uints,
        uint8[8] feeMethodsSidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell
    ) public view returns (uint256) {
        Order memory buy = Order(
            addrs[0],
            addrs[1],
            addrs[2],
            uints[0],
            uints[1],
            uints[2],
            uints[3],
            addrs[3],
            FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[2]),
            addrs[4],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[3]),
            calldataBuy,
            replacementPatternBuy,
            addrs[5],
            staticExtradataBuy,
            ERC20(addrs[6]),
            uints[4],
            uints[5],
            uints[6],
            uints[7],
            uints[8]
        );
        Order memory sell = Order(
            addrs[7],
            addrs[8],
            addrs[9],
            uints[9],
            uints[10],
            uints[11],
            uints[12],
            addrs[10],
            FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
            SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]),
            SaleKindInterface.SaleKind(feeMethodsSidesKindsHowToCalls[6]),
            addrs[11],
            AuthenticatedProxy.HowToCall(feeMethodsSidesKindsHowToCalls[7]),
            calldataSell,
            replacementPatternSell,
            addrs[12],
            staticExtradataSell,
            ERC20(addrs[13]),
            uints[13],
            uints[14],
            uints[15],
            uints[16],
            uints[17]
        );
        return calculateMatchPrice(buy, sell);
    }

    /**
     * @dev Call atomicMatch - Solidity ABI encoding limitation workaround, hopefully temporary.
     */
    function atomicMatch_(
        address[14] addrs,
        uint256[18] uints,
        uint8[8] feeMethodsSidesKindsHowToCalls,
        bytes calldataBuy,
        bytes calldataSell,
        bytes replacementPatternBuy,
        bytes replacementPatternSell,
        bytes staticExtradataBuy,
        bytes staticExtradataSell,
        uint8[2] vs,
        bytes32[5] rssMetadata
    ) public payable {
        return
            atomicMatch(
                Order(
                    addrs[0],
                    addrs[1],
                    addrs[2],
                    uints[0],
                    uints[1],
                    uints[2],
                    uints[3],
                    addrs[3],
                    FeeMethod(feeMethodsSidesKindsHowToCalls[0]),
                    SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[1]),
                    SaleKindInterface.SaleKind(
                        feeMethodsSidesKindsHowToCalls[2]
                    ),
                    addrs[4],
                    AuthenticatedProxy.HowToCall(
                        feeMethodsSidesKindsHowToCalls[3]
                    ),
                    calldataBuy,
                    replacementPatternBuy,
                    addrs[5],
                    staticExtradataBuy,
                    ERC20(addrs[6]),
                    uints[4],
                    uints[5],
                    uints[6],
                    uints[7],
                    uints[8]
                ),
                Sig(vs[0], rssMetadata[0], rssMetadata[1]),
                Order(
                    addrs[7],
                    addrs[8],
                    addrs[9],
                    uints[9],
                    uints[10],
                    uints[11],
                    uints[12],
                    addrs[10],
                    FeeMethod(feeMethodsSidesKindsHowToCalls[4]),
                    SaleKindInterface.Side(feeMethodsSidesKindsHowToCalls[5]),
                    SaleKindInterface.SaleKind(
                        feeMethodsSidesKindsHowToCalls[6]
                    ),
                    addrs[11],
                    AuthenticatedProxy.HowToCall(
                        feeMethodsSidesKindsHowToCalls[7]
                    ),
                    calldataSell,
                    replacementPatternSell,
                    addrs[12],
                    staticExtradataSell,
                    ERC20(addrs[13]),
                    uints[13],
                    uints[14],
                    uints[15],
                    uints[16],
                    uints[17]
                ),
                Sig(vs[1], rssMetadata[2], rssMetadata[3]),
                rssMetadata[4]
            );
    }

    function validateErc(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address maker
    ) public pure returns (bool) {
        if (ecrecover(hash, v, r, s) == maker) {
            return true;
        }
    }
}

contract OKOffChainExchange is Exchange {
    string public constant name = "OKEX OffChain Change";

    string public constant version = "0.1";

    string public constant codename = "Diego";

    function changeExchangeToken(ERC20 tokenAddress) public onlyOwner {
        exchangeToken = tokenAddress;
    }

    function changeCopyrightReceiver(address protocolFeeAddress)
        public
        onlyOwner
    {
        protocolFeeRecipient = protocolFeeAddress;
    }

    bool private onlyInitOnce;

    /**
     * @dev Initialize a WyvernExchange instance
     * @param registryAddress Address of the registry instance which this Exchange instance will use
     * @param tokenAddress Address of the token used for protocol fees
     */
    function init(
        ProxyRegistry registryAddress,
        TokenTransferProxy tokenTransferProxyAddress,
        ERC20 tokenAddress,
        address protocolFeeAddress
    ) public {
        require(!onlyInitOnce, "already initialized");
        onlyInitOnce = true;
        registry = registryAddress;
        tokenTransferProxy = tokenTransferProxyAddress;
        //用来支付版税的token地址 但是这里面跟着订单走(split模式) 只有protocol模式此token会起作用
        exchangeToken = tokenAddress;
        //协议费（版税）的接收地址
        protocolFeeRecipient = protocolFeeAddress;
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

//import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
//import {IERC165, IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {IERC2981} from "./interfaces/IERC2981.sol";
import {IERC165} from "./interfaces/IERC165.sol";
import {IRoyaltyFeeManager} from "./interfaces/IRoyaltyFeeManager.sol";
import "./OKRoyaltyFeeRegistry.sol";

/**
 * @title RoyaltyFeeManager
 * @notice It handles the logic to check and transfer royalty fees (if any).
 */
contract OKRoyaltyFeeManager is IRoyaltyFeeManager, Ownable {
    // https://eips.ethereum.org/EIPS/eip-2981
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    IRoyaltyFeeRegistry public royaltyFeeRegistry;

    /**
     * @notice Constructor
     * @param _royaltyFeeRegistry address of the RoyaltyFeeRegistry
     */
    constructor(address _royaltyFeeRegistry) {
        royaltyFeeRegistry = IRoyaltyFeeRegistry(_royaltyFeeRegistry);
    }

    function setRoyaltyFeeRegistry(address _royaltyFeeRegistry)
        public
        onlyOwner
    {
        royaltyFeeRegistry = IRoyaltyFeeRegistry(_royaltyFeeRegistry);
    }

    /**
     * @notice Calculate royalty fee and get recipient
     * @param collection address of the NFT contract
     * @param tokenId tokenId
     * @param amount amount to transfer
     */
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256) {
        // 1. Check if there is a royalty info in the system
        (address receiver, uint256 royaltyAmount) = royaltyFeeRegistry
            .royaltyInfo(collection, amount);

        // 2. If the receiver is address(0), fee is null, check if it supports the ERC2981 interface
        // 当支持 2981标准时，返回某个tokenId的版税，否则直接返回该NFT合约级别的版税
        if ((receiver == address(0)) || (royaltyAmount == 0)) {
            if (IERC165(collection).supportsInterface(INTERFACE_ID_ERC2981)) {
                (receiver, royaltyAmount) = IERC2981(collection).royaltyInfo(
                    tokenId,
                    amount
                );
            }
        }
        return (receiver, royaltyAmount);
    }
}

pragma solidity ^0.4.26;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }


}

pragma solidity ^0.4.26;

library MyTools {
    function getSlice(uint256 begin, uint256 end, bytes text) internal  pure returns (bytes) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = text[i+begin-1];
        }
        return a;
    }


    function bytesToUint(bytes memory b) internal  view returns (uint256){

        uint256 number;
        for(uint i= 0; i<b.length; i++){
            number = number + uint8(b[i])*(2**(8*(b.length-(i+1))));
        }
        return  number;
    }


    function bytesToAddress(bytes memory bys) internal view returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }

    }
}

pragma solidity ^0.4.26;

library ArrayUtils {

    /**
     * Replace bytes in an array with bytes in another array, guarded by a bitmask
     * Efficiency of this function is a bit unpredictable because of the EVM's word-specific model (arrays under 32 bytes will be slower)
     *
     * @dev Mask must be the size of the byte array. A nonzero byte means the byte array can be changed.
     * @param array The original array
     * @param desired The target array
     * @param mask The mask specifying which bits can be changed
     * @return The updated byte array (the parameter will be modified inplace)
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
    function unsafeWriteBytes(uint index, bytes source)
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
        uint conv = uint(source) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
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

}

/*

  Abstract over fixed-price sales and Dutch auctions, with the intent of easily supporting additional methods of sale later.

  Separated into a library for convenience, all the functions are inlined.

*/

pragma solidity 0.4.26;

import "./SafeMath.sol";

/**
 * @title SaleKindInterface
 * @author Project Wyvern Developers
 */
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

    /**
     * @dev Check whether the parameters of a sale are valid
     * @param saleKind Kind of sale
     * @param expirationTime Order expiration time
     * @return Whether the parameters were valid
     */
    function validateParameters(SaleKind saleKind, uint expirationTime)
        pure
        internal
        returns (bool)
    {
        /* Auctions must have a set expiration date. */
        return (saleKind == SaleKind.FixedPrice || expirationTime > 0);
    }

    /**
     * @dev Return whether or not an order can be settled
     * @dev Precondition: parameters have passed validateParameters
     * @param listingTime Order listing time
     * @param expirationTime Order expiration time
     */
    function canSettleOrder(uint listingTime, uint expirationTime)
        view
        internal
        returns (bool)
    {
        return (listingTime < now) && (expirationTime == 0 || now < expirationTime);
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
    function calculateFinalPrice(Side side, SaleKind saleKind, uint basePrice, uint extra, uint listingTime, uint expirationTime)
        view
        internal
        returns (uint finalPrice)
    {
        if (saleKind == SaleKind.FixedPrice) {
            return basePrice;
        } else if (saleKind == SaleKind.DutchAuction) {
            uint diff = SafeMath.div(SafeMath.mul(extra, SafeMath.sub(now, listingTime)), SafeMath.sub(expirationTime, listingTime));
            if (side == Side.Sell) {
                /* Sell-side - start price: basePrice. End price: basePrice - extra. */
                return SafeMath.sub(basePrice, diff);
            } else {
                /* Buy-side - start price: basePrice. End price: basePrice + extra. */
                return SafeMath.add(basePrice, diff);
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

import "./interfaces/IERC721.sol";
import "./interfaces/Ownable.sol";

/**
 * @title TransferManagerERC721
 * @notice It allows the transfer of ERC721 tokens.
 */
contract TransferNFTManager is Ownable {
    address public OK_EXCHANGE;

    /**
     * @notice Constructor
     * @param _exchange address of the LooksRare exchange
     */
    constructor(address _exchange) {
        OK_EXCHANGE = _exchange;
    }


    function setExchangeAddr(
        address _exchange
    ) public onlyOwner {
        OK_EXCHANGE = _exchange;
    }

    function proxy(
        address dest,
        uint256 howToCall,
        bytes calldataValue
    ) public returns (bool result) {
        require(msg.sender == OK_EXCHANGE, "Transfer: Only OK Exchange");
        if (howToCall == 0) {
            result = dest.call(calldataValue);
        } else if (howToCall == 1) {
            result = dest.delegatecall(calldataValue);
        }
        return result;
    }

    /**
     * @notice Transfer ERC721 token
     * @param collection address of the collection
     * @param from address of the sender
     * @param to address of the recipient
     * @param tokenId tokenId
     * @dev For ERC721, amount is not used
     */
    function transferNonFungibleToken(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        uint256
    ) external {
        require(msg.sender == OK_EXCHANGE, "Transfer: Only OK Exchange");
        // https://docs.openzeppelin.com/contracts/2.x/api/token/erc721#IERC721-safeTransferFrom
        IERC721(collection).safeTransferFrom(from, to, tokenId);
    }
}

pragma solidity ^0.4.26;


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)
    public view returns (uint256);

    function transferFrom(address from, address to, uint256 value)
    public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract TokenRecipient {
    event ReceivedEther(address indexed sender, uint amount);
    event ReceivedTokens(address indexed from, uint256 value, address indexed token, bytes extraData);

    /**
     * @dev Receive tokens and generate a log event
     * @param from Address from which to transfer tokens
     * @param value Amount of tokens to transfer
     * @param token Address of token
     * @param extraData Additional data to log
     */
    function receiveApproval(address from, uint256 value, address token, bytes extraData) public {
        ERC20 t = ERC20(token);
        require(t.transferFrom(from, this, value));
        emit ReceivedTokens(from, value, token, extraData);
    }

    /**
     * @dev Receive Ether and generate a log event
     */
    function () payable public {
        emit ReceivedEther(msg.sender, msg.value);
    }
}

pragma solidity ^0.4.26;

contract Proxy {

    /**
    * @dev Tells the address of the implementation where every call will be delegated.
    * @return address of the implementation to which it will be delegated
    */
    function implementation() public view returns (address);

    /**
    * @dev Tells the type of proxy (EIP 897)
    * @return Type of proxy, 2 for upgradeable proxy
    */
    function proxyType() public pure returns (uint256 proxyTypeId);

    /**
    * @dev Fallback function allowing to perform a delegatecall to the given implementation.
    * This function will return whatever the implementation call returns
    */
    function () payable public {
        address _impl = implementation();
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

pragma solidity ^0.4.26;

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

pragma solidity ^0.4.26;

import "../interfaces/Ownable.sol";
import "./OwnedUpgradeabilityStorage.sol";

contract ProxyRegistry is Ownable {

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

    /**
     * Start the process to enable access for specified contract. Subject to delay period.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function startGrantAuthentication (address addr)
    public
    onlyOwner
    {
        require(!contracts[addr] && pending[addr] == 0);
        pending[addr] = now;
    }

    /**
     * End the process to nable access for specified contract after delay period has passed.
     *
     * @dev ProxyRegistry owner only
     * @param addr Address to which to grant permissions
     */
    function endGrantAuthentication (address addr)
    public
    onlyOwner
    {
        require(!contracts[addr] && pending[addr] != 0 && ((pending[addr] + DELAY_PERIOD) < now));
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
    public
    onlyOwner
    {
        contracts[addr] = false;
    }

    /**
     * Register a proxy contract with this registry
     *
     * @dev Must be called by the user which the proxy is for, creates a new AuthenticatedProxy
     * @return New AuthenticatedProxy contract
     */
    function registerProxy()
    public
    returns (OwnableDelegateProxy proxy)
    {
        require(proxies[msg.sender] == address(0));
        proxy = new OwnableDelegateProxy(msg.sender, delegateProxyImplementation, abi.encodeWithSignature("initialize(address,address)", msg.sender, address(this)));
        proxies[msg.sender] = proxy;
        return proxy;
    }

}

pragma solidity ^0.4.26;

import "./Proxy.sol";

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

    /**
    * @dev Tells the address of the current implementation
    * @return address of the current implementation
    */
    function implementation() public view returns (address) {
        return _implementation;
    }

    /**
    * @dev Tells the proxy type (EIP 897)
    * @return Proxy type, 2 for forwarding proxy
    */
    function proxyType() public pure returns (uint256 proxyTypeId) {
        return 2;
    }
}


contract OwnedUpgradeabilityProxy is Proxy, OwnedUpgradeabilityStorage {
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
    * @dev Upgrades the implementation address
    * @param implementation representing the address of the new implementation to be set
    */
    function _upgradeTo(address implementation) internal {
        require(_implementation != implementation);
        _implementation = implementation;
        emit Upgraded(implementation);
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner());
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
        require(newOwner != address(0));
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address implementation) public onlyProxyOwner {
        _upgradeTo(implementation);
    }

    /**
     * @dev Allows the upgradeability owner to upgrade the current implementation of the proxy
     * and delegatecall the new implementation for initialization.
     * @param implementation representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address implementation, bytes data) payable public onlyProxyOwner {
        upgradeTo(implementation);
        require(address(this).delegatecall(data));
    }
}


contract OwnableDelegateProxy is OwnedUpgradeabilityProxy {

    constructor(address owner, address initialImplementation, bytes calldata)
    public
    {
        setUpgradeabilityOwner(owner);
        _upgradeTo(initialImplementation);
        require(initialImplementation.delegatecall(calldata));
    }

}

pragma solidity ^0.4.26;

import "./TokenRecipient.sol";
import "./OwnedUpgradeabilityStorage.sol";
import "./ProxyRegistry.sol";


contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {

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
    public
    {
        require(!initialized);
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     *
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke)
    public
    {
        require(msg.sender == user);
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     *
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param calldata Calldata to send
     * @return Result of the call (success or failure)
     */
    function proxy(address dest, HowToCall howToCall, bytes calldata)
    public
    returns (bool result)
    {
        require(msg.sender == user || (!revoked && registry.contracts(msg.sender)));
        if (howToCall == HowToCall.Call) {
            result = dest.call(calldata);
        } else if (howToCall == HowToCall.DelegateCall) {
            result = dest.delegatecall(calldata);
        }
        return result;
    }

    /**
     * Execute a message call and assert success
     *
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param calldata Calldata to send
     */
    function proxyAssert(address dest, HowToCall howToCall, bytes calldata)
    public
    {
        require(proxy(dest, howToCall, calldata));
    }

}

contract TokenTransferProxy {

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
        require(registry.contracts(msg.sender));
        return ERC20(token).transferFrom(from, to, amount);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC2981.sol)

pragma solidity ^0.4.26;

//import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.4.26;

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
pragma solidity ^0.4.26;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;
pragma experimental ABIEncoderV2;

import "./interfaces/Ownable.sol";
import {IRoyaltyFeeRegistry} from "./interfaces/IRoyaltyFeeRegistry.sol";
import "./interfaces/ArrayUtils.sol";

/**
 * @title RoyaltyFeeRegistry
 * @notice It is a royalty fee registry for the LooksRare exchange.
 */
contract OKRoyaltyFeeRegistry is IRoyaltyFeeRegistry, Ownable {
    struct FeeInfo {
        address setter;
        address receiver;
        uint256 fee;
    }

    bytes32 DOMAIN_SEPARATOR;

    // Limit (if enforced for fee royalty in percentage (10,000 = 100%)
    uint256 public royaltyFeeLimit;

    mapping(address => FeeInfo) private _royaltyFeeInfoCollection;

    // whitelist to set sale
    mapping(address => bool) public whitelist;

    event SetWhitelist(address _member, bool _isAdded);

    function setWhitelist(address _member, bool _status) external onlyOwner {
        whitelist[_member] = _status;
        emit SetWhitelist(_member, _status);
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender], "the caller isn't in the whitelist");
        _;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    //这里需要把要签名的数据结构化
    /* An order on the exchange. */
    struct RoyaltyFee {
        address collection;
        address setter;
        address receiver;
        uint256 fee;
        string nonce;
        string lengthStr;
        bytes32 hash;
    }

    function sizeOf(RoyaltyFee memory royaltyFee)
        internal
        pure
        returns (uint256)
    {
        return ((0x14 * 4) + (0x20 * 2));
    }

    function strConcat(string _a, string _b) public pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }

    function _toBytes(address a) public pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            mstore(
                add(m, 20),
                xor(0x140000000000000000000000000000000000000000, a)
            )
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function bytesConcat(bytes _a, bytes _b) public pure returns (bytes) {
        bytes memory _ba = _a;
        bytes memory _bb = _b;
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        //return string(ret);
        return bret;
    }

    function toBytes(bytes32 _data) public pure returns (bytes) {
        return abi.encodePacked(_data);
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(uint256 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes32 value) public pure returns (string memory) {
        return toString(abi.encodePacked(value));
    }

    function toString(bytes memory data) public pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function toStringNoPre(address account)
        public
        pure
        returns (string memory)
    {
        return toStringNOPre(abi.encodePacked(account));
    }

    function toStringNOPre(bytes memory data)
        public
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(data.length * 2);

        for (uint256 i = 0; i < data.length; i++) {
            str[i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[1 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }

    bytes32 aHash;

    event ResultHash(bytes32 rHash);

    address serverAddress;

    function setServerAddress(address _serverAddress) public onlyWhitelist {
        serverAddress = _serverAddress;
    }

    //这里的v用 不带0x的地址 长度用40可以做到hash一致
    function updateRoyaltyFeeByThirdParty(RoyaltyFee royaltyFee, Sig sig)
        public
        returns (bytes32)
    {
        // Note: we need to use `encodePacked` here instead of `encode`.

        //string memory collectionStr = string(abi.encodePacked(collection));
        bytes memory a = abi.encodePacked(royaltyFee.collection);
        string memory aStr = toStringNOPre(a);

        bytes memory b = abi.encodePacked(royaltyFee.setter);
        string memory bStr = toStringNOPre(b);

        string memory abStr = strConcat(aStr, bStr);

        bytes memory c = abi.encodePacked(royaltyFee.receiver);
        string memory cStr = toStringNOPre(c);

        string memory abcStr = strConcat(abStr, cStr);
        string memory abcStrNonce = strConcat(abcStr, royaltyFee.nonce);

        aHash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                royaltyFee.lengthStr,
                abcStrNonce
            )
        );

        require(aHash == royaltyFee.hash, "hash error");
        require(
            ecrecover(aHash, sig.v, sig.r, sig.s) == serverAddress,
            "sign error"
        );
        //require(cHash == hash,"hash error");
        emit ResultHash(aHash);

        require(
            royaltyFee.fee <= royaltyFeeLimit,
            "Registry: Royalty fee too high"
        );
        _royaltyFeeInfoCollection[royaltyFee.collection] = FeeInfo({
            setter: royaltyFee.setter,
            receiver: royaltyFee.receiver,
            fee: royaltyFee.fee
        });

        emit RoyaltyFeeUpdate(
            royaltyFee.collection,
            royaltyFee.setter,
            royaltyFee.receiver,
            royaltyFee.fee
        );

        return (aHash);
    }

    function stringToBytes32(string memory source)
        public
        constant
        returns (bytes32 result)
    {
        assembly {
            result := mload(add(source, 32))
        }
    }

    event NewRoyaltyFeeLimit(uint256 royaltyFeeLimit);
    event RoyaltyFeeUpdate(
        address indexed collection,
        address indexed setter,
        address indexed receiver,
        uint256 fee
    );

    /**
     * @notice Constructor
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    constructor(uint256 _royaltyFeeLimit) {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;
    }

    /**
     * @notice Update royalty info for collection
     * @param _royaltyFeeLimit new royalty fee limit (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit)
        external
        onlyWhitelist
    {
        require(_royaltyFeeLimit <= 9500, "Owner: Royalty fee limit too high");
        royaltyFeeLimit = _royaltyFeeLimit;

        emit NewRoyaltyFeeLimit(_royaltyFeeLimit);
    }

    /**
     * @notice Update royalty info for collection
     * @param collection address of the NFT contract
     * @param setter address that sets the receiver
     * @param receiver receiver for the royalty fee
     * @param fee fee (500 = 5%, 1,000 = 10%)
     */
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external onlyWhitelist {
        require(fee <= royaltyFeeLimit, "Registry: Royalty fee too high");
        _royaltyFeeInfoCollection[collection] = FeeInfo({
            setter: setter,
            receiver: receiver,
            fee: fee
        });

        emit RoyaltyFeeUpdate(collection, setter, receiver, fee);
    }

    /**
     * @notice Calculate royalty info for a collection address and a sale gross amount
     * @param collection collection address
     * @param amount amount
     * @return receiver address and amount received by royalty recipient
     */
    function royaltyInfo(address collection, uint256 amount)
        external
        view
        returns (address, uint256)
    {
        return (
            _royaltyFeeInfoCollection[collection].receiver,
            (amount * _royaltyFeeInfoCollection[collection].fee) / 10000
        );
    }

    /**
     * @notice View royalty info for a collection address
     * @param collection collection address
     */
    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            _royaltyFeeInfoCollection[collection].setter,
            _royaltyFeeInfoCollection[collection].receiver,
            _royaltyFeeInfoCollection[collection].fee
        );
    }
}

pragma solidity ^0.4.26;

contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

interface IRoyaltyFeeRegistry {
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 amount) external view returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
    external
    view
    returns (
        address,
        address,
        uint256
    );
}

pragma solidity ^0.4.26;
import "./IERC165.sol";


contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;

    function approve(address to, uint256 tokenId) public;

    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;

    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}