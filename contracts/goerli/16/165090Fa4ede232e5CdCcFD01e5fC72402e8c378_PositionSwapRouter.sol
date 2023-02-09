pragma solidity ^0.8.17;
import "./Orderbook.sol";
import "./HDGXStructs.sol";
import "./HedgeXv3.sol";

contract PositionSwapRouter {
    Orderbook public derivswapOrderbook;
    HedgeXv3 public drvs_vault;
    mapping(uint256 => bool) public makerForSale;
    mapping(uint256 => bool) public takerForSale;
    mapping(uint256 => PositionAsk) public makersAsk;
    mapping(uint256 => PositionAsk) public takersAsk;
    mapping(uint256 => PositionBid[]) public makersBids;
    mapping(uint256 => PositionBid[]) public takersBids;
    mapping(uint256 => PositionBid) public positionBidsByID;
    mapping(uint256 => PositionAsk) public positionAsksByID;
    mapping(uint256 => bool) public bidAccepted;
    mapping(uint256 => bool) public askAccepted;
    mapping(address=>PositionBid[]) public usersBids;
    mapping(address=>PositionAsk[]) public usersAsks;
    mapping(address=>TakeBid[]) public usersTakeBids;
    mapping(address=>TakeAsk[]) public usersTakeAsks;
    uint256 askID;
    uint256 bidID;

    struct PositionAsk {
        address user;
        uint256 positionAskID;
        bool underlyingIsMaker;
        uint256 underlyingOrderID;
        uint256 ethAmount;
        uint256 timestamp;
    }
    struct PositionBid {
        address user;
        uint256 positionBidID;
        bool underlyingIsMaker;
        uint256 underlyingOrderID;
        uint256 ethAmount;
        uint256 timestamp;
    }
    struct TakeAsk {
        address user;
        uint256 askID;
        uint256 timestamp;
    }
    struct TakeBid {
        address user;
        uint256 bidID;
        uint256 timestamp;
    }

    constructor(
        address payable _orderbookAddress,
        address payable _vaultAddress
    ) {
        derivswapOrderbook = Orderbook(_orderbookAddress);
        drvs_vault = HedgeXv3(_vaultAddress);
        askID = 0;
        bidID = 0;
    }

    function create_position_ask(
        uint256 _underliningOrderType,
        uint256 _underlyingOrderID,
        uint256 _ethAskAmt
    ) public {
        PositionAsk memory ask;
        if (_underliningOrderType == 0) {
            HDGXStructs.MakerOrder memory maker = fetch_orderbook_maker_order(
                _underlyingOrderID
            );
            require(maker.user == msg.sender, "Unauthorized.");
            require(
                makerForSale[maker.order_ID] == false,
                "Ask order already exists for this position. Please cancel exisiting ask orders on this position before attempting to create a new one."
            );
            bool matched = derivswapOrderbook.makerOrderIDMatched(
                maker.order_ID
            );
            require(
                matched == true,
                "You can't auction a maker order that has yet to be matched. Please refer to cancelOrder() on the vault contract instead."
            );
            ask = PositionAsk(
                msg.sender,
                askID + 1,
                true,
                maker.order_ID,
                _ethAskAmt,
                block.timestamp
            );
            makerForSale[_underlyingOrderID] = true;
            makersAsk[_underlyingOrderID] = ask;
        } else if (_underliningOrderType == 1) {
            HDGXStructs.TakerOrder memory taker = fetch_orderbook_taker_order(
                _underlyingOrderID
            );
            require(taker.user == msg.sender, "Unauthorized.");
            require(
                takerForSale[taker.order_ID] == false,
                "Ask order already exists for this position. Please cancel exisiting ask orders on this position before attempting to create a new one."
            );
            ask = PositionAsk(
                msg.sender,
                askID + 1,
                false,
                taker.order_ID,
                _ethAskAmt,
                block.timestamp
            );
            takerForSale[_underlyingOrderID] = true;
        } else {
            revert();
        }
        takersAsk[_underlyingOrderID] = ask;
        usersAsks[msg.sender].push(ask);
        positionAsksByID[askID + 1] = ask;
        askID++;
    }

    function create_position_bid(
        uint256 _underlyingOrderType,
        uint256 _underlyingOrderID
    ) public payable {
        require(msg.value != 0);
        PositionBid memory bid;
        if (_underlyingOrderType == 0) {
            HDGXStructs.MakerOrder memory maker = fetch_orderbook_maker_order(
                _underlyingOrderID
            );
            require(
                maker.user != msg.sender,
                "Cannot place an ask order on your own position."
            );
            bool canceled = derivswapOrderbook.makerOrderCanceled(
                _underlyingOrderID
            );
            bool matched = derivswapOrderbook.makerOrderIDMatched(
                _underlyingOrderID
            );
            require(
                (canceled == false && matched == true),
                "Maker order ineligible for bidding."
            );
            bid = PositionBid(
                msg.sender,
                bidID + 1,
                true,
                maker.order_ID,
                msg.value,
                block.timestamp
            );
            makersBids[maker.order_ID].push(bid);
        } else if (_underlyingOrderType == 1) {
            HDGXStructs.TakerOrder memory taker = fetch_orderbook_taker_order(
                _underlyingOrderID
            );
            require(
                taker.user != msg.sender,
                "Cannot place a bid order on your own position."
            );

            HDGXStructs.MakerOrder memory maker = fetch_orderbook_maker_order(
                taker.makerOrder_ID
            );
            require(
                block.timestamp < (taker.timeStampTaken + maker.lockUpPeriod),
                "This position has already reached expiry and can no longer be bid on."
            );
            bid = PositionBid(
                msg.sender,
                bidID + 1,
                false,
                taker.order_ID,
                msg.value,
                block.timestamp
            );
            takersBids[taker.order_ID].push(bid);
        } else {
            revert();
        }
        usersBids[msg.sender].push(bid);
        positionBidsByID[bidID + 1] = bid;
        bidID++;
    }

    function accept_position_bid(uint256 _bidID) public {
        PositionBid memory bid = positionBidsByID[_bidID];
        require(
            bidAccepted[bid.positionBidID] == false,
            "Bid has already been accepted."
        );
        require(msg.sender != bid.user);
        bool success = false;
        if (bid.underlyingIsMaker == true) {
            HDGXStructs.MakerOrder memory maker = fetch_orderbook_maker_order(
                bid.underlyingOrderID
            );
            uint256 makers_taker_ID = derivswapOrderbook.makers_taker_ID(
                maker.order_ID
            );
            HDGXStructs.TakerOrder memory taker = fetch_orderbook_taker_order(
                makers_taker_ID
            );
            require(
                maker.user == msg.sender,
                "You can't accept bids on a position you don't own."
            );
            require(
                derivswapOrderbook.takerOrderIDSettled(taker.order_ID) == false,
                "You can't accept bids on a position that has already been settled."
            );
            bytes memory data = abi.encode(
                true,
                bid.underlyingOrderID,
                bid.user
            );
            (success) = derivswapOrderbook.swap_router_bid_accepted(data);
        } else if (bid.underlyingIsMaker == false) {
            HDGXStructs.TakerOrder memory taker = fetch_orderbook_taker_order(
                bid.underlyingOrderID
            );
            require(
                taker.user == msg.sender,
                "You can't accept bids on a position you don't own."
            );
            require(
                derivswapOrderbook.takerOrderIDSettled(taker.order_ID) == false,
                "You can't accept bids on a position that has already been settled."
            );
            // ( success, seller) = derivswapOrderbook.swap_router_bid_accepted(false,bid.underlyingOrderID,bid.user);
            bytes memory data = abi.encode(
                false,
                bid.underlyingOrderID,
                bid.user
            );
            (success) = derivswapOrderbook.swap_router_bid_accepted(data);
        }
        if (success == true) {
            TakeBid memory take_bid = TakeBid(msg.sender, bid.positionBidID,block.timestamp);
            usersTakeBids[msg.sender].push(take_bid);
            bidAccepted[bid.positionBidID] = true;
            payable(msg.sender).transfer((((bid.ethAmount) * 997) / 1000));
        }
    }

    function accept_position_ask(uint256 _askID) public payable {
        PositionAsk memory ask = positionAsksByID[_askID];
        require(
            msg.value == ask.ethAmount,
            "Insufficent or incorrect amount required to assume this position."
        );
        require(ask.user != msg.sender);
        require(
            askAccepted[ask.positionAskID] == false,
            "Position ask has already been accepted and processed."
        );
        bool success;
        address seller;
        if (ask.underlyingIsMaker == true) {
            HDGXStructs.MakerOrder memory maker = fetch_orderbook_maker_order(
                ask.underlyingOrderID
            );
            bytes memory data = abi.encode(true, maker.order_ID, msg.sender);
            (success, seller) = derivswapOrderbook.swap_router_ask_accepted(
                data
            );
        } else if (ask.underlyingIsMaker == false) {
            HDGXStructs.TakerOrder memory taker = fetch_orderbook_taker_order(
                ask.underlyingOrderID
            );
            bytes memory data = abi.encode(false, taker.order_ID, msg.sender);
            (success, seller) = derivswapOrderbook.swap_router_ask_accepted(
                data
            );
        }
        if(success == true){
            TakeAsk memory take_ask = TakeAsk(msg.sender, ask.positionAskID,block.timestamp);
            usersTakeAsks[msg.sender].push(take_ask);
            askAccepted[ask.positionAskID] = true;
            payable(seller).transfer((((msg.value) * 997) / 1000));
        }
    }

    function fetch_orderbook_maker_order(uint256 _makerOrderID)
        internal
        view
        returns (HDGXStructs.MakerOrder memory maker)
    {
        (
            uint256 order_ID,
            address user,
            uint256 ethPosted,
            uint256 num_legs,
            uint256 lockUpPeriod,
            int64 ratio
        ) = derivswapOrderbook.makerOrdersByID(_makerOrderID);
        maker = HDGXStructs.MakerOrder(
            order_ID,
            user,
            ethPosted,
            num_legs,
            lockUpPeriod,
            ratio
        );
    }

    function fetch_orderbook_taker_order(uint256 _takerOrderID)
        internal
        view
        returns (HDGXStructs.TakerOrder memory taker)
    {
        (
            uint256 order_ID,
            address user,
            uint256 ethPosted,
            uint256 timeStampTaken,
            uint256 makerOrder_ID,
            bool outlook,
            int256 ratio
        ) = derivswapOrderbook.takerOrdersByID(_takerOrderID);
        taker = HDGXStructs.TakerOrder(
            order_ID,
            user,
            ethPosted,
            timeStampTaken,
            makerOrder_ID,
            outlook,
            ratio
        );
    }

    function user_lengths(uint _option) public view returns(uint256 length){
        if(_option == 1){
            length = usersBids[msg.sender].length;
        }
        if(_option==2){
            length = usersAsks[msg.sender].length;
        }
        if(_option == 3){
            length = usersTakeBids[msg.sender].length;

        }
        if(_option == 4){
            length = usersTakeAsks[msg.sender].length;
        }
    }

    function bid_lengths(uint256 _underlyingOrderID, uint _undelyingOrderType) public view returns(uint256 length){
        if(_undelyingOrderType==0){
            length = makersBids[_underlyingOrderID].length;
        }
        if(_undelyingOrderType==1){
            length = takersBids[_underlyingOrderID].length;
        }
    }

    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./HDGXStructs.sol";

library Settler {
    //Negate64 Odds Reversal Helper
    function negate64(int64 _i) public pure returns (uint64) {
        return uint64(-_i);
    }

    function settlement_evaluation(bytes calldata positionInfo)
        public
        pure
        returns (address payable temp_winner)
    {
        (
            HDGXStructs.Leg[] memory legs,
            HDGXStructs.ClosePrice[] memory close_prices,
            HDGXStructs.MakerOrder memory maker,
            HDGXStructs.TakerOrder memory taker
        ) = abi.decode(
                positionInfo,
                (
                    HDGXStructs.Leg[],
                    HDGXStructs.ClosePrice[],
                    HDGXStructs.MakerOrder,
                    HDGXStructs.TakerOrder
                )
            );

        if (maker.num_legs == 1) {
            if (close_prices[0].close_price.price > legs[0].priceTarget) {
                if (legs[0].outlook == true) {
                    temp_winner = payable(maker.user);
                } else if (legs[0].outlook == false) {
                    temp_winner = payable(taker.user);
                }
            } else if (
                close_prices[0].close_price.price < legs[0].priceTarget
            ) {
                if (legs[0].outlook == true) {
                    temp_winner = payable(taker.user);
                } else if (legs[0].outlook == false) {
                    temp_winner = payable(maker.user);
                }
            } else {
                // Handle Tie Scenario
            }
        }
        //Multi Leg Position Statement
        if (maker.num_legs > 1) {
            bool maker_won = true;
            for (uint256 z = 0; z < maker.num_legs; z++) {
                if (close_prices[z].close_price.price > legs[z].priceTarget) {
                    if (legs[z].outlook == true) {} else if (
                        legs[z].outlook == false
                    ) {
                        maker_won = false;
                    }
                } else if (
                    close_prices[z].close_price.price < legs[z].priceTarget
                ) {
                    if (legs[z].outlook == true) {
                        maker_won = false;
                    } else if (legs[z].outlook == false) {}
                } else {
                    // Handle Tie Scenario
                }
            }
            if (maker_won == false) {
                temp_winner = payable(taker.user);
            } else {
                temp_winner = payable(maker.user);
            }
        }
        return (temp_winner);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {

    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./HDGXStructs.sol";

library Probability {
  function orderbook_calculate_implied_probability(int64 ratio)
        public
        pure
        returns (
            uint256 implied_probability,
            uint256 implied_probability_opposite_side,
            uint256 implied_probability_opposite_side_with_vig,
            int256 opposite_odds256
        )
    {
        uint256 base = 100;
        uint256 vig = 500;
        require(ratio >= 100 || ratio <= -100);
        //100 with two decimal places .xx
        if (ratio > 0) {
            if (ratio > 700) {
                vig = 400;
            }
            if (ratio > 1000) {
                vig = 300;
            }
            if (ratio > 2000) {
                vig = 150;
            }
            if (ratio > 5000) {
                vig = 100;
            }

            uint256 winningAmount = (base * (uint64(ratio))) / 100;
            uint256 fullPayout = base + winningAmount;
            //Percentage form .xx decimal precision
            implied_probability = (base * 10000) / fullPayout;
            implied_probability_opposite_side = 10000 - implied_probability;
            implied_probability_opposite_side_with_vig = (implied_probability_opposite_side +
                vig);
            //.xxxxxx precision
            uint256 decimal_odds = (10000000000 /
                (implied_probability_opposite_side_with_vig));
            uint256 opposite_odds = uint256(
                100000000 / (decimal_odds - 1000000)
            );
            opposite_odds256 = -int256(opposite_odds);
            // return(int256())
        } else if (ratio < -100) {
            if (ratio < -700) {
                vig = 400;
            }
            if (ratio < -1000) {
                vig = 300;
            }
            if (ratio < -2000) {
                vig = 150;
            }
            if (ratio < -5000) {
                vig = 100;
            }
            //No precision
            uint256 winningAmount = ((base * 10000) / (uint64(-ratio))) / 100;
            uint256 fullPayout = base + winningAmount;
            implied_probability = (base * 10000) / fullPayout;
            implied_probability_opposite_side = 10000 - implied_probability;
            implied_probability_opposite_side_with_vig = (implied_probability_opposite_side +
                vig);
            uint256 decimal_odds = (10000000000 /
                (implied_probability_opposite_side_with_vig));

            uint256 opposite_odds = uint256((decimal_odds - 1000000)) / 10000;
            opposite_odds256 = int256(opposite_odds);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./HDGXStructs.sol";
import "./Settler.sol";
library Payout {
   function orderbook_calculate_payout(
        address winnerAddress,
        HDGXStructs.MakerOrder memory maker,
        HDGXStructs.TakerOrder memory taker
    ) public pure returns (HDGXStructs.Payout memory payout) {
        uint256 maker_rebate;
        uint256 winning_payout;
        uint256 protocol_profit;
        uint256 settler_fee;
        if (winnerAddress == maker.user) {
            // HDGXStructs.Payout memeory newPayout = new HDGXStructs.Payout(winnerAddress,())
            maker_rebate = 0;
            winning_payout =
                (((taker.ethPosted) * 900) / 1000) +
                maker.ethPosted;
            protocol_profit =
                (taker.ethPosted + maker.ethPosted) -
                winning_payout;
            settler_fee = (protocol_profit * 10) / 100;
            protocol_profit -= settler_fee;

            // Construct settle-order struct. Maker ->settler->winner payout
        } else if (winnerAddress == taker.user) {
            maker_rebate = (((maker.ethPosted) * 10) / 1000);
            if (maker.ratio > 0) {
                winning_payout =
                    ((taker.ethPosted * 100) / uint256(-taker.ratio)) +
                    taker.ethPosted;
            } else if (maker.ratio < 0) {
                winning_payout =
                    ((taker.ethPosted * uint256(taker.ratio)) / 100) +
                    taker.ethPosted;
            }
            protocol_profit =
                (maker.ethPosted + taker.ethPosted) -
                winning_payout;
            settler_fee = (protocol_profit * 10) / 100;
            protocol_profit -= settler_fee;
            protocol_profit -= maker_rebate;
        }
        return (
            HDGXStructs.Payout(
                winnerAddress,
                protocol_profit,
                winning_payout,
                maker_rebate,
                settler_fee
            )
        );
    }

     function orderbook_amtRequiredToTake(int64 ratio, uint256 ethPosted)
        public
        pure
        returns (uint256 amtRequired)
    {
        // Fetch maker-order.

        if (ratio < 0) {
            //i.e. maker ratio is -400, taker amt should be MakerOrder.ethPosted / (400/100)
            amtRequired = (ethPosted / Settler.negate64(ratio)) * 100;
        } else {
            //i.e. maker ratio is +400, taker amt should be MakerOrder.ethPosted / (400/100)
            amtRequired = (ethPosted * uint64(ratio)) / 100;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./HDGXStructs.sol";
import "./IPyth.sol";
import "./Settler.sol";
import "./Probability.sol";
import "./Payout.sol";

contract Orderbook {
    IPyth pyth;
    address public HedgeX_V2;
    address public owner;
    address public position_swap_router;
    uint256 makerOrderIDCount;
    uint256 takerOrderIDCount;
    mapping(bytes32 => uint256) public feedBidLiquidity;
    mapping(uint256 => HDGXStructs.MakerOrder) public makerOrdersByID;
    mapping(uint256 => HDGXStructs.TakerOrder) public takerOrdersByID;
    mapping(bytes32 => uint256[]) public makerOrdersByFeedID;
    mapping(uint256 => bool) public makerOrderIDMatched;
    mapping(uint256 => bool) public makerOrderCanceled;
    mapping(uint256 => bool) public takerOrderIDSettled;
    mapping(uint256 => HDGXStructs.SettleOrder) public takerSettleOrder;
    mapping(uint256 => uint256) public makers_taker_ID;
    mapping(address => uint256[]) public userMakerOrders;
    mapping(address => uint256[]) public userTakerOrders;
    mapping(address => uint256) public userSettlerFeesEarned;
    mapping(uint256 => HDGXStructs.ClosePrice[]) public makersClosingPrices;
    mapping(uint256 => HDGXStructs.LockPrice[]) public makersLockPrices;
    mapping(uint256 => HDGXStructs.Leg[]) public makersLegs;

    constructor(address _pyth) {
        owner = msg.sender;
        pyth = IPyth(_pyth);
        makerOrderIDCount = 0;
        takerOrderIDCount = 0;
    }

    modifier onlyVault() {
        require(msg.sender == HedgeX_V2);
        _;
    }

    function owner_set_hedgex(address HDGXV2) public {
        require(msg.sender == owner);
        HedgeX_V2 = HDGXV2;
    }

    function owner_set_position_swap_router(address _swapRouter) public{
        require(msg.sender == owner);
        position_swap_router = _swapRouter;
    }

    function orderbook_make_order(
        bytes calldata maker_info,
        bytes calldata legsEncoded
    )
        external
        onlyVault
        returns (
            address,
            uint256,
            uint256
        )
    {
        // Decode calldata info & calldata legs [].
        (
            address sender,
            uint256 valueSent,
            uint256 lockUpPeriod,
            int64 ratio
        ) = abi.decode(maker_info, (address, uint256, uint256, int64));

        HDGXStructs.Leg[] memory legs = abi.decode(
            legsEncoded,
            (HDGXStructs.Leg[])
        );

        // Construct maker-order struct.
        HDGXStructs.MakerOrder memory newOrder = HDGXStructs.MakerOrder(
            makerOrderIDCount + 1,
            sender,
            valueSent,
            legs.length,
            lockUpPeriod,
            ratio
        );
        makerOrdersByID[makerOrderIDCount + 1] = newOrder;
        userMakerOrders[sender].push(makerOrderIDCount + 1);

        // Iterate through position's legs.
        for (uint256 x = 0; x < legs.length; x++) {
            // Require lower-bound < upper-bound threshold.
            require(
                legs[x].threshold.lowerBound < legs[x].threshold.upperBound,
                "05"
            );
            makerOrdersByFeedID[legs[x].feedID].push(makerOrderIDCount + 1);

            // Increment liquidity per feed.
            feedBidLiquidity[legs[x].feedID] =
                feedBidLiquidity[legs[x].feedID] +
                valueSent;

            // Track maker order's legs.
            makersLegs[makerOrderIDCount + 1].push(legs[x]);
        }
        makerOrderIDCount++;
        return (sender, makerOrderIDCount + 1, valueSent);
    }

    function orderbook_take_order(
        bytes calldata takerOrderInfo,
        bytes[] calldata priceUpdateData
    )
        external
        onlyVault
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        // Decode calldata info & calldata updatedata.
        (address sender, uint256 valueSent, uint256 makerOrderID) = abi.decode(
            takerOrderInfo,
            (address, uint256, uint256)
        );

        // Fetch coorelated maker order to be matched.
        HDGXStructs.MakerOrder memory makerOrder = makerOrdersByID[
            makerOrderID
        ];

        // Valid price update data.
        require(priceUpdateData.length == makerOrder.num_legs, "06");

        // No wash trading.
        require(sender != makerOrdersByID[makerOrderID].user, "07");

        // Check to make sure order hasn't already been matched or canceled.
        require(
            (makerOrderIDMatched[makerOrderID] == false &&
                makerOrderCanceled[makerOrderID] == false),
            "08"
        );

        // Valid value sent required to match order.
        require(
            valueSent ==
                Payout.orderbook_amtRequiredToTake(
                    makerOrder.ratio,
                    makerOrder.ethPosted
                ),
            "10"
        );

        // Fetch pyth update fee & update all price feeds assosciated with maker order.
        uint256 pyth_fee = pyth.getUpdateFee(priceUpdateData.length);
        pyth.updatePriceFeeds{value: pyth_fee}(priceUpdateData);

        // Iterate maker position's legs
        for (uint256 i = 0; i < makerOrder.num_legs; i++) {
            // Fetch newest price of each leg.
            PythStructs.Price memory priceAssetUSD = pyth.getPrice(
                makersLegs[makerOrder.order_ID][i].feedID
            );

            // Require asset price is currently within take threshold established by the maker. (PriceThreshold.lowerBounds < Current price < PriceThreshold.upperBounds)
            require(
                (makersLegs[makerOrderID][i].threshold.lowerBound <
                    priceAssetUSD.price) &&
                    (priceAssetUSD.price <
                        makersLegs[makerOrderID][i].threshold.upperBound),
                "12"
            );

            // Store lock-prices @ order-take. (visual verification for maker once order has been matched.)
            makersLockPrices[makerOrder.order_ID].push(
                HDGXStructs.LockPrice(
                    makersLegs[makerOrder.order_ID][i].feedID,
                    priceAssetUSD
                )
            );
        }

        // Initialize taker-order struct.
        HDGXStructs.TakerOrder memory newTakerOrder;
        (, , , int256 opposite_odds256) = Probability
            .orderbook_calculate_implied_probability(makerOrder.ratio);
        if (makersLegs[makerOrder.order_ID].length > 1) {
            //Maker orders num_legs > 1, set outlook to false, any wrong outcome of maker order results in positive outcome for taker.
            newTakerOrder = HDGXStructs.TakerOrder(
                takerOrderIDCount + 1,
                sender,
                valueSent,
                block.timestamp,
                makerOrderID,
                false,
                opposite_odds256
            );
        } else if (makersLegs[makerOrder.order_ID].length == 1) {
            //else, negate outlook of maker
            newTakerOrder = HDGXStructs.TakerOrder(
                takerOrderIDCount + 1,
                sender,
                valueSent,
                block.timestamp,
                makerOrderID,
                !(makersLegs[makerOrderID][0].outlook),
                opposite_odds256
            );
        }
        takerOrdersByID[takerOrderIDCount + 1] = newTakerOrder;
        userTakerOrders[sender].push(takerOrderIDCount + 1);

        // Set maker order as matched & taken.
        makerOrderIDMatched[makerOrder.order_ID] = true;

        // Set assosciation between maker-order => taker-order.
        makers_taker_ID[makerOrderID] = takerOrderIDCount + 1;

        // Decrement open-bid liqudiity per feed.
        for (uint256 x = 0; x < makersLegs[makerOrderID].length; x++) {
            feedBidLiquidity[makersLegs[makerOrderID][x].feedID] =
                feedBidLiquidity[makersLegs[makerOrderID][x].feedID] -
                makerOrdersByID[makerOrderID].ethPosted;
        }
        takerOrderIDCount++;
        return (
            sender,
            makerOrder.order_ID,
            block.timestamp + makerOrder.lockUpPeriod,
            block.timestamp
        );
    }

    function orderbook_settle_order(
        bytes calldata settleInfo,
        bytes[] calldata priceUpdateData
    )
        external
        onlyVault
        returns (
            HDGXStructs.MakerOrder memory _maker,
            HDGXStructs.TakerOrder memory _taker,
            HDGXStructs.Payout memory _payout
        )
    {
        // Decode calldata settleInfo & calldata priceUpdateData.
        (address sender, uint256 takerOrder_ID) = abi.decode(
            settleInfo,
            (address, uint256)
        );

        HDGXStructs.TakerOrder memory taker = takerOrdersByID[takerOrder_ID];
        HDGXStructs.MakerOrder memory maker = makerOrdersByID[
            taker.makerOrder_ID
        ];

        require(
            block.timestamp > (taker.timeStampTaken + maker.lockUpPeriod),
            "13"
        );

        require(takerOrderIDSettled[takerOrder_ID] == false, "14");

        require(priceUpdateData.length == maker.num_legs, "15");

        uint256 pyth_fee = pyth.getUpdateFee(priceUpdateData.length);
        pyth.updatePriceFeeds{value: pyth_fee}(priceUpdateData);

        address payable winnerAddress;

        for (uint256 i = 0; i < maker.num_legs; i++) {
            PythStructs.Price memory closingPrice = pyth.getPrice(
                makersLegs[maker.order_ID][i].feedID
            );
            makersClosingPrices[maker.order_ID].push(
                HDGXStructs.ClosePrice(
                    makersLegs[maker.order_ID][i].feedID,
                    closingPrice
                )
            );
        }
        bytes memory encodedForSettler = abi.encode(
            makersLegs[maker.order_ID],
            makersClosingPrices[maker.order_ID],
            maker,
            taker
        );
        winnerAddress = Settler.settlement_evaluation(encodedForSettler);
        takerOrderIDSettled[takerOrder_ID] = true;
        HDGXStructs.Payout memory payout = Payout.orderbook_calculate_payout(
            winnerAddress,
            maker,
            taker
        );
        takerSettleOrder[taker.order_ID] = HDGXStructs.SettleOrder(
            maker.order_ID,
            taker.order_ID,
            maker.user,
            taker.user,
            winnerAddress,
            sender,
            payout.maker_rebate,
            payout.settler_fee,
            payout.winning_payout,
            block.timestamp
        );
        userSettlerFeesEarned[sender] += payout.settler_fee;
        return (maker, taker, payout);
    }

    function orderbook_cancel_order(uint256 _makerOrderID, address sender)
        external
        returns (bool success, uint256 amt)
    {
        require(
            (makerOrderCanceled[_makerOrderID] == false &&
                sender == makerOrdersByID[_makerOrderID].user)
        );
        makerOrderCanceled[_makerOrderID] = true;
        for (uint256 x = 0; x < makerOrdersByID[_makerOrderID].num_legs; x++) {
            feedBidLiquidity[makersLegs[_makerOrderID][x].feedID] =
                feedBidLiquidity[makersLegs[_makerOrderID][x].feedID] -
                (makerOrdersByID[_makerOrderID].ethPosted);
        }
        return (true, makerOrdersByID[_makerOrderID].ethPosted);
    }

    function amt_required_to_take(uint256 makerOrderID)
        public
        view
        returns (uint256)
    {
        uint256 amtRequired = Payout.orderbook_amtRequiredToTake(
            makerOrdersByID[makerOrderID].ratio,
            makerOrdersByID[makerOrderID].ethPosted
        );
        return amtRequired;
    }

    function pyth_update_fee(bytes[] calldata priceUpdateData)
        public
        view
        returns (uint256 fee)
    {
        // Call getupdateFee on Pyth contract.
        fee = pyth.getUpdateFee(priceUpdateData.length);
    }

    // Cancel maker-order. Returns stake to msg.sender w/ no penalty fee.
    function cancelMakerOrder(uint256 _makerOrderID, address sender)
        public
        returns (bool success, uint256 amt)
    {
        require(sender == makerOrdersByID[_makerOrderID].user);
        require(makerOrderCanceled[_makerOrderID] == false);
        makerOrderCanceled[_makerOrderID] = true;
        for (uint256 x = 0; x < makerOrdersByID[_makerOrderID].num_legs; x++) {
            feedBidLiquidity[makersLegs[_makerOrderID][x].feedID] =
                feedBidLiquidity[makersLegs[_makerOrderID][x].feedID] -
                (makerOrdersByID[_makerOrderID].ethPosted);
        }
        return (true, makerOrdersByID[_makerOrderID].ethPosted);
    }

    function calculate_taker_odds(uint256 maker_order_id) public view returns(int256 opposite_odds256){
        (
            ,
            ,
            ,
            opposite_odds256
        )  = Probability.orderbook_calculate_implied_probability(makerOrdersByID[maker_order_id].ratio);
    }

    function swap_router_bid_accepted(bytes calldata _data) external returns(bool success){
        (bool _underlyingIsMaker, uint256 _underlyingOrderID , address _takeOverUser) = abi.decode(_data,(bool,uint256,address));
        require(msg.sender == position_swap_router);
        if(_underlyingIsMaker == true){
            HDGXStructs.MakerOrder memory maker = makerOrdersByID[_underlyingOrderID];
            maker.user = _takeOverUser;
            makerOrdersByID[_underlyingOrderID] = maker;
            
        }
        else if (_underlyingIsMaker == false){
            HDGXStructs.TakerOrder memory taker = takerOrdersByID[_underlyingOrderID];
            taker.user = _takeOverUser;
            takerOrdersByID[_underlyingOrderID] = taker;
        }
        return(true);
    }

    function swap_router_ask_accepted(bytes calldata _data) external returns(bool, address){
        (bool _underlyingIsMaker, uint256 _underlyingOrderID , address _takeOverUser) = abi.decode(_data,(bool,uint256,address));
        require(msg.sender == position_swap_router);
        address seller;
        if(_underlyingIsMaker == true){
            HDGXStructs.MakerOrder memory maker = makerOrdersByID[_underlyingOrderID];
            seller = maker.user;
            maker.user = _takeOverUser;
            makerOrdersByID[_underlyingOrderID] = maker;
            
        }
        else if (_underlyingIsMaker == false){
            HDGXStructs.TakerOrder memory taker = takerOrdersByID[_underlyingOrderID];
            seller = taker.user;
            taker.user = _takeOverUser;
            takerOrdersByID[_underlyingOrderID] = taker;
        }
        return(true,seller);
    }

    function fetchUserOrders(address user, uint256 _orderType)
        public
        view
        returns (
            HDGXStructs.MakerOrder[] memory maker_orders_returned,
            HDGXStructs.TakerOrder[] memory taker_orders_returned
        )
    {
        HDGXStructs.MakerOrder[]
            memory maker_orders = new HDGXStructs.MakerOrder[](
                userMakerOrders[user].length
            );
        HDGXStructs.TakerOrder[]
            memory taker_orders = new HDGXStructs.TakerOrder[](
                userTakerOrders[user].length
            );

        if (_orderType == 1) {
            for (uint256 i = 0; i < userMakerOrders[user].length; i++) {
                HDGXStructs.MakerOrder memory maker = makerOrdersByID[userMakerOrders[user][i]];
                maker_orders[i] = maker;
            }
        } else if (_orderType == 2) {
            for (uint256 i = 0; i < userTakerOrders[user].length; i++) {
                HDGXStructs.TakerOrder memory taker = takerOrdersByID[userTakerOrders[user][i]];
                taker_orders[i] = taker;
            }
        }
        return(maker_orders,taker_orders);
    }

    function fetchFeedLiquidity(bytes32[] memory ids)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory volumes = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            volumes[i] = feedBidLiquidity[ids[i]];
        }
        return (volumes);
    }

    function fetchMakerOrdersByFeedID(bytes32 feedID)
        public
        view
        returns (HDGXStructs.MakerOrder[] memory)
    {
        HDGXStructs.MakerOrder[]
            memory return_array = new HDGXStructs.MakerOrder[](
                makerOrdersByFeedID[feedID].length
            );
        uint256 count = 0;
        for (uint256 i = 0; i < makerOrdersByFeedID[feedID].length; i++) {
            if (
                makerOrderIDMatched[makerOrdersByID[makerOrdersByFeedID[feedID][i]].order_ID] ==
                false &&
                makerOrderCanceled[makerOrdersByID[makerOrdersByFeedID[feedID][i]].order_ID] ==
                false
            ) {
                return_array[count] = makerOrdersByID[makerOrdersByFeedID[feedID][i]];
                count++;
            }
        }
        HDGXStructs.MakerOrder[]
            memory shortened_array = new HDGXStructs.MakerOrder[](count);
        for (uint256 x = 0; x < count; x++) {
            shortened_array[x] = return_array[x];
        }
        return (shortened_array);
    }

    function getUserOrdersLength(address _user, uint256 _orderType)
        public
        view
        returns (uint256)
    {
        if (_orderType == 1) {
            return userMakerOrders[_user].length;
        } else if (_orderType == 2) {
            return userTakerOrders[_user].length;
        } else {
            revert();
        }
    }

    function makerOrdersByFeedIDLength(bytes32 feedID)
        public
        view
        returns (uint256)
    {
        return makerOrdersByFeedID[feedID].length;
    }

    receive() external payable {
        // emit Received(msg.sender, msg.value);
    }
}

pragma solidity =0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.17;

import "./PythStructs.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth {
    /// @dev Emitted when an update for price feed with `id` is processed successfully.
    /// @param id The Pyth Price Feed ID.
    /// @param fresh True if the price update is more recent and stored.
    /// @param chainId ID of the source chain that the batch price update containing this price.
    /// This value comes from Wormhole, and you can find the corresponding chains at https://docs.wormholenetwork.com/wormhole/contracts.
    /// @param sequenceNumber Sequence number of the batch price update containing this price.
    /// @param lastPublishTime Publish time of the previously stored price.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, bool indexed fresh, uint16 chainId, uint64 sequenceNumber, uint lastPublishTime, uint publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    /// @param batchSize Number of prices within the batch price update.
    /// @param freshPricesInBatch Number of prices that were more recent and were stored.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber, uint batchSize, uint freshPricesInBatch);

    /// @dev Emitted when a call to `updatePriceFeeds` is processed successfully.
    /// @param sender Sender of the call (`msg.sender`).
    /// @param batchCount Number of batches that this function processed.
    /// @param fee Amount of paid fee for updating the prices.
    event UpdatePriceFeeds(address indexed sender, uint batchCount, uint fee);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(bytes[] calldata updateData, bytes32[] calldata priceIds, uint64[] calldata publishTimes) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateDataSize Number of price updates.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(uint updateDataSize) external view returns (uint feeAmount);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
import "./PythStructs.sol";
import "./HDGXStructs.sol";
import "./Orderbook.sol";
import "./IWETH9.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IHedgexLiqManager {
    function mintNewPosition(uint256 amount0ToAdd, uint256 amount1ToAdd)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    function decreaseLiquidityCurrentRange()
        external
        returns (uint256 amount0, uint256 amount1);
}

interface IEarnBox{
    function inject_profit() external payable;
}

contract HedgeXv3 {
    address public owner;
    uint256 public protocol_earnings;
    uint256 public eth_swapped_for_drvs;
    uint256 public earn_box_fees_injected;
    Orderbook public hdgx_orderbook;
    address public orderbook_address;
    ISwapRouter public immutable swapRouter;
    IERC20 public hdgx;
    IUniswapV3Factory public unifactory;
    address public hedgexLiqManagerAddress;
    IHedgexLiqManager public hedgexLiqManager;
    IEarnBox public earnBox;
    uint256 initialLiqThreshold = 1 * (10**17);
    bool public initialLiquidityPulled = false;
    bool public initialLiquidityProvided = false;
    address public pool_address;
    address public HEDGEX;
    address public WETH9;
    IWETH9 private weth;
    uint24 private constant poolFee = 3000;

    event NewMakerOrder(
        address _maker,
        uint256 _maker_order_ID,
        uint256 _amt,
        uint256 timestamp
    );
    event Taken(
        address _taker,
        uint256 _maker_order_ID,
        uint256 lockUpEnds,
        uint256 _timestamp
    );
    event Settled(
        address _settler,
        uint256 _taker_order_ID,
        uint256 _maker_order_ID,
        uint256 _winner_payout,
        uint256 _settler_fee,
        uint256 _maker_rebate,
        uint256 _protocol_p,
        uint256 _timestamp
    );
    event Received(address, uint256);
    event SwappedForHedgex(
        uint256 amtInput,
        uint256 amtOutput,
        uint256 timestamp
    );
    event SwapFailure(uint256 _timestamp);
    event InitialLiquidityProvided(
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    constructor(
        address _liquidityManager,
        address _hedgexTokenAddress,
        address payable _hdgx_orderbook,
        address _swapRouter,
        address _weth,
        address _uniFactory
    ) {
        unifactory = IUniswapV3Factory(_uniFactory);
        WETH9 = _weth;
        weth = IWETH9(WETH9);
        swapRouter = ISwapRouter(_swapRouter);
        hedgexLiqManagerAddress = _liquidityManager;
        hedgexLiqManager = IHedgexLiqManager(_liquidityManager);
        HEDGEX = _hedgexTokenAddress;
        pool_address = unifactory.getPool(_hedgexTokenAddress, WETH9, 3000);
        hdgx = IERC20(_hedgexTokenAddress);
        orderbook_address = _hdgx_orderbook;
        hdgx_orderbook = Orderbook(_hdgx_orderbook);
        owner = msg.sender;
        protocol_earnings = 0;
        eth_swapped_for_drvs = 0;
        earn_box_fees_injected = 0;
    }

    function owner_set_earn_box(address _earn_box) public{
        require(msg.sender==owner);
        earnBox = IEarnBox( _earn_box);
    }

    function protocol_claim_quarter_of_excess_profit() public{
        require(msg.sender==owner);
        uint256 protocol_earnings_total = protocol_earnings;
        protocol_earnings-=(((protocol_earnings - eth_swapped_for_drvs - earn_box_fees_injected) * 25) / 100);
        payable(owner).transfer(((protocol_earnings_total - eth_swapped_for_drvs - earn_box_fees_injected) * 25) / 100);
    }

    //Create maker order. Earn 1% of match fee for doing so.
    function makeOrder(
        uint256 lockUpPeriod,
        int64 ratio,
        HDGXStructs.Leg[] memory legs
    ) public payable {
        // Minimum lockup in seconds
        require(lockUpPeriod > 100, "E01");

        // Valid lock-up periods: (1 Hour, 1 Day, 1 Month)
        require(
            (lockUpPeriod == 101 ||
                lockUpPeriod == 86400 ||
                lockUpPeriod == 604800),
            "E02"
        );

        // Valid ratios -1250 -> +1250 !( -100 - +100 )
        require(ratio != 0, "E03");
        require((ratio >= 100 || ratio <= -100), "E04");

        // Encode info to be passed to orderbook
        bytes memory gameInfoEncoded = abi.encode(
            msg.sender,
            msg.value,
            lockUpPeriod,
            ratio
        );
        bytes memory legsEncoded = abi.encode(legs);

        // Create maker order on orderbook
        (address _sender, uint256 orderID, uint256 valueSent) = hdgx_orderbook
            .orderbook_make_order(gameInfoEncoded, legsEncoded);
        emit NewMakerOrder(_sender, orderID, valueSent, block.timestamp);
    }

    //Match an exisiting maker-order.
    function takeOrder(uint256 makerOrderID, bytes[] calldata priceUpdateData)
        public
        payable
    {
        // Fetch pyth update fee
        uint256 pyth_update_fee = hdgx_orderbook.pyth_update_fee(
            priceUpdateData
        );

        // Transfer pyth update fee to orderbook
        payable(orderbook_address).transfer(pyth_update_fee);

        // Encode info to be passed to orderbook
        bytes memory takerInfoEncoded = abi.encode(
            msg.sender,
            msg.value,
            makerOrderID
        );

        // Create taker order on orderbook
        (
            address sender,
            uint256 order_ID,
            uint256 expiry,
            uint256 time_taken
        ) = hdgx_orderbook.orderbook_take_order(
                takerInfoEncoded,
                priceUpdateData
            );
        emit Taken(sender, order_ID, expiry, time_taken);
    }

    //Settle order with expired lock-up period.
    function settleOrder(
        uint256 takerOrder_ID,
        bytes[] calldata priceUpdateData
    ) public {
        // Fetch pyth update fee, transfer eth fee to orderbook where update will occur.
        uint256 pyth_update_fee = hdgx_orderbook.pyth_update_fee(
            priceUpdateData
        );
        payable(orderbook_address).transfer(pyth_update_fee);

        // Encode calldata to pass to ordderbook
        bytes memory settleInfo = abi.encode(msg.sender, takerOrder_ID);

        // Place order on orderbook contract
        (
            HDGXStructs.MakerOrder memory maker,
            HDGXStructs.TakerOrder memory taker,
            HDGXStructs.Payout memory payout
        ) = hdgx_orderbook.orderbook_settle_order(settleInfo, priceUpdateData);

        // Update protocol earnings
        uint256 protocol_earnings_deducted = (payout.protocol_profit - (pyth_update_fee * maker.num_legs));
        protocol_earnings += protocol_earnings_deducted;
        // Pay out Winner's Total
        payable(payout.winnerAddress).transfer(
                payout.winning_payout
        );
        // Pay out Settler Fee
        payable(msg.sender).transfer(
           payout.settler_fee
        );
        // Pay out Maker Fee
        if(payout.maker_rebate != 0){
            payable(maker.user).transfer(
                payout.maker_rebate
            );
        }
        // LP Provide once protocol earnings >= initial threshold (public)
        if (initialLiquidityProvided == true) {
            if (hdgx.balanceOf(pool_address) > ((5 * (10**18)))) {
                //Uniswap V3 Swap ETH for HDGX. 1/4 of protocol's fee spent on buyback.
                swapExactInputSingle(
                  protocol_earnings_deducted / 4
                );
                eth_swapped_for_drvs+=(protocol_earnings_deducted / 4);
                

            } else {
                //Halve Liquidity once HDGX balance in pool is less than 5 Tokens.
                if (initialLiquidityPulled == false) {
                    halveLiquidity();
                }
            }
                //TODO: Earn box, inject protocol_earnings_deducted / 4
                earnBox.inject_profit{value:protocol_earnings_deducted / 4}();
                earn_box_fees_injected += (protocol_earnings_deducted / 4);
        }
        if (protocol_earnings >= initialLiqThreshold) {
            if (initialLiquidityProvided == false) {
                provideLiquidity();
            }
        }
        //Token Buyback Handler
       
        emit Settled(
            msg.sender,
            takerOrder_ID,
            taker.makerOrder_ID,
            payout.winning_payout,
            payout.settler_fee,
            payout.maker_rebate,
            protocol_earnings_deducted,
            block.timestamp
        );
    }

    function cancelOrder(uint256 _maker_order_id) public {
        (bool success, uint256 amt) = hdgx_orderbook.orderbook_cancel_order(
            _maker_order_id,
            msg.sender
        );
        if (success == true) {
            address payable payable_user = payable(msg.sender);
            payable_user.transfer(amt);
        } else {
            revert();
        }
    }

    // Public swap ETH->DRVS
    function swap_for_drvs(uint256 amountIn) public returns(uint256 amountOut) {
        amountOut = swapExactInputSingle(amountIn);
    }

    //Uniswap V3 Swap Exact Input Single, Internal DRVS Token Buyback Fuction
    function swapExactInputSingle(uint256 amountIn) internal returns (uint256) {
        // Wrap ether
        weth.deposit{value: amountIn}();

        // Grant approval to Uniswap V3 router
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

        // Uniswap V3 construct swap paramters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: HEDGEX,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // Uniswap V3 Router Swap
        uint256 amountOut = swapRouter.exactInputSingle(params);
        emit SwappedForHedgex(amountIn, amountOut, block.timestamp);
        return (amountOut);
    }

    //Uniswap V3 LP Position Halvening Event Function
    function halveLiquidity() internal {
        hedgexLiqManager
            .decreaseLiquidityCurrentRange();
        initialLiquidityPulled = true;
    }

    //Uniswap V3, Initial Liquidity Provide Function
    function provideLiquidity() internal {
        require(initialLiquidityProvided == false, "E17");
        require(protocol_earnings >= initialLiqThreshold, "E18");

        // Deposit and wrap ether
        weth.deposit{value: initialLiqThreshold}();

        // Grant approval to liquidity manager
        TransferHelper.safeApprove(
            WETH9,
            hedgexLiqManagerAddress,
            initialLiqThreshold
        );

        // Transfer WETH to Liquidity Manager to be provided as liquidity on Uniswap V3. Liquidity Manager holds supply of HDGX ERC-20.
        TransferHelper.safeTransferFrom(
            WETH9,
            address(this),
            hedgexLiqManagerAddress,
            initialLiqThreshold
        );

        // Mint LP position on Liquidity Manager.
        hedgexLiqManager.mintNewPosition((100 * (10**18)), initialLiqThreshold);
        initialLiquidityProvided = true;
        // emit InitialLiquidityProvided(tokenId,liquidity,amount0,amount1);
    }

    function ownerpull() public {
        require(msg.sender == owner);
        address payable _owner = payable(owner);
        _owner.transfer(address(this).balance);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
import "./PythStructs.sol";

contract HDGXStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Leg {
        bytes32 feedID;
        bool outlook;
        int64 priceTarget;
        PriceThreshold threshold;
    }
    struct LockPrice {
        bytes32 feedID;
        PythStructs.Price lock_price;
    }
    struct ClosePrice {
        bytes32 feedID;
        PythStructs.Price close_price;
    }
    struct MakerOrder {
        uint256 order_ID;
        address user;
        uint256 ethPosted;
        uint256 num_legs;
        uint256 lockUpPeriod;
        int64 ratio;
    }
    struct TakerOrder {
        uint256 order_ID;
        address user;
        uint256 ethPosted;
        uint256 timeStampTaken;
        uint256 makerOrder_ID;
        bool outlook;
        int256 ratio;
    }
    struct SettleOrder {
        uint256 makerOrderID;
        uint256 takerOrderID;
        address maker;
        address taker;
        address winner;
        address settler;
        uint256 makerFees;
        uint256 settlerFees;
        uint256 winnerPayout;
        uint256 timeStampSettled;
        // ClosePrice[] close_prices;
    }
    struct Payout {
        address winnerAddress;
        uint256 protocol_profit;
        uint256 winning_payout;
        uint256 maker_rebate;
        uint256 settler_fee;
    }
    struct PriceThreshold {
        int64 lowerBound;
        int64 upperBound;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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