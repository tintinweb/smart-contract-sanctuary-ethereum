pragma solidity ^0.8.15;

import "@dex/structs/Order.sol";
import "@dex/structs/Match.sol";
import "@dex/structs/Decimals.sol";

import {PriceData} from "@dex/oracles/interfaces/IOracle.sol";

library FeesMath {
    function makerFees(
        Order storage o,
        PriceData memory p,
        Decimals memory d,
        int256 premium,
        uint256 premiumFeePerc
    ) external view returns (uint256) {
        int256 fees = (int256(premiumFeePerc) *
            computePremium(o, p, d, premium)) / int256(10**(d.percent));
        return fees > 0 ? uint256(fees) : uint256(-fees);
    }

    function computePremium(
        Order storage o,
        PriceData memory p,
        Decimals memory d,
        int256 premium
    ) public view returns (int256) {
        return
            (premium * int256(o.amount) * int256(p.price)) /
            int256(10**(d.premium + d.amount + d.oracle - d.collateral));
    }

    function traderFees(
        Order storage o,
        PriceData memory p,
        Decimals memory d,
        uint256 traderFeesPerc
    ) external view returns (uint256) {
        return
            (traderFeesPerc * o.amount * p.price) /
            10**(d.percent + d.amount + d.oracle - d.collateral);
    }
}

pragma solidity ^0.8.13;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;


struct Decimals {
    uint8 amount;
    uint8 premium;
    uint8 fr;
    uint8 percent;
    uint8 oracle;
    uint8 collateral;
    uint8 leverage;
}

pragma solidity ^0.8.15;

struct Match {
    uint256 maker; // maker vault token-id
    uint256 trader; // trader vault token-id
    uint256 amount;
    int256 premium; // In percent of the amount
    uint256 frPerHour;
    int8 pos; // If maker is short = true
    uint256 start; // timestamp of the match starting
    uint256 entryPrice;
    uint256 collateralM; // Maker  collateral
    uint256 collateralT; // Trader collateral
    uint256 fmfrPerHour; // The fair market funding rate when the match was done
}

pragma solidity ^0.8.15;

struct Order {
    address owner; // trader address
    uint256 tokenId;
    uint256 matchId; // trader selected matchid
    uint256 amount;
    uint256 collateral;
    uint256 collateralAdd;
    bool canceled;
    int8 pos;
    // NOTE: Used to apply the check for the Oracle Latency Protection
    uint256 timestamp;
    // NOTE: In this case, we give trader the max full control on the price for matching: no assumption it is symmetric and we do not compute any percentage so introducing some approximations, the trader writes the desired prices
    uint256 slippageMinPrice;
    uint256 slippageMaxPrice;
    uint256 maxTimestamp;
}