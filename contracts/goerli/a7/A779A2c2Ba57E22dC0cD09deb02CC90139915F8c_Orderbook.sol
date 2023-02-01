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
    address owner;

    uint256 makerOrderIDCount;
    uint256 takerOrderIDCount;
    mapping(bytes32 => uint256) public feedBidLiquidity;
    mapping(uint256 => HDGXStructs.MakerOrder) public makerOrdersByID;
    mapping(uint256 => HDGXStructs.TakerOrder) public takerOrdersByID;
    mapping(bytes32 => HDGXStructs.MakerOrder[]) public makerOrdersByFeedID;
    mapping(uint256 => bool) public makerOrderIDMatched;
    mapping(uint256 => bool) public makerOrderCanceled;
    mapping(uint256 => bool) public takerOrderIDSettled;
    mapping(uint256 => HDGXStructs.SettleOrder) public takerSettleOrder;
    mapping(uint256 => uint256) public makers_taker_ID;
    mapping(address => HDGXStructs.MakerOrder[]) public userMakerOrders;
    mapping(address => HDGXStructs.TakerOrder[]) public userTakerOrders;
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
        userMakerOrders[sender].push(newOrder);

        // Iterate through position's legs.
        for (uint256 x = 0; x < legs.length; x++) {
            // Require lower-bound < upper-bound threshold.
            require(
                legs[x].threshold.lowerBound < legs[x].threshold.upperBound,
                "05"
            );
            makerOrdersByFeedID[legs[x].feedID].push(newOrder);

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
        userTakerOrders[sender].push(newTakerOrder);

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
                maker_orders[i] = userMakerOrders[user][i];
            }
        } else if (_orderType == 2) {
            for (uint256 i = 0; i < userTakerOrders[user].length; i++) {
                taker_orders[i] = userTakerOrders[user][i];
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
                makerOrderIDMatched[makerOrdersByFeedID[feedID][i].order_ID] ==
                false &&
                makerOrderCanceled[makerOrdersByFeedID[feedID][i].order_ID] ==
                false
            ) {
                return_array[count] = makerOrdersByFeedID[feedID][i];
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