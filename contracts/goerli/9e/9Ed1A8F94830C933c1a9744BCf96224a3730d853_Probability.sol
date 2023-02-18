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