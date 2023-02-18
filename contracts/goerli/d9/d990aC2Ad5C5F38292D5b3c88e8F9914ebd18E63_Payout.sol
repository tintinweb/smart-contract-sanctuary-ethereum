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