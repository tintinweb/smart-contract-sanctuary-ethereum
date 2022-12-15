pragma solidity ^0.8.15;

import "./Positions.sol";
import "@dex/structs/Match.sol";
import "@dex/structs/Decimals.sol";
import {PriceData} from "@dex/oracles/interfaces/IOracle.sol";

library PnLMath {
    function pnl(
        Match storage m,
        uint256 tokenId,
        uint256 timestamp,
        uint256 exitPrice,
        Decimals calldata decimals
    ) external view returns (int256) {
        require(timestamp > m.start, "engine/wrong_timestamp");
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            "engine/invalid-tokenId"
        );
        return
            _pnl(
                timestamp - m.start,
                m.entryPrice,
                exitPrice,
                m.frPerHour,
                m.amount,
                tokenId == m.maker,
                m.pos == POS_SHORT,
                decimals
            );
    }

    function _pnl(
        uint256 deltaT,
        uint256 entryPrice,
        uint256 exitPrice,
        uint256 frPerHour,
        uint256 amount,
        bool isMaker,
        bool isShort,
        Decimals calldata decimals
    ) public pure returns (int256 res) {
        int256 deltaP = int256(exitPrice) - int256(entryPrice);

        int256 gl = (((isShort) ? -deltaP : deltaP) *
            int256(amount * 10**decimals.collateral)) /
            int256(10**(uint256(decimals.amount + decimals.oracle)));

        res =
            gl +
            ((isMaker) ? int256(1) : int256(-1)) *
            int256(_accruedFR(deltaT, frPerHour, amount, exitPrice, decimals));
    }

    function accruedFR(
        Match storage m,
        PriceData memory priceData,
        Decimals calldata decimals
    ) external view returns (uint256) {
        return
            _accruedFR(
                priceData.timestamp - m.start,
                m.frPerHour,
                m.amount,
                priceData.price,
                decimals
            );
    }

    function _accruedFR(
        uint256 deltaT,
        uint256 frPerHour,
        uint256 amount,
        uint256 price,
        Decimals calldata decimals
    ) public pure returns (uint256) {
        return
            (deltaT * frPerHour * amount * price) /
            (3600 *
                10 **
                    (decimals.fr +
                        decimals.amount +
                        decimals.oracle -
                        decimals.collateral));
    }
}

pragma solidity ^0.8.15;

int8 constant POS_SHORT = -1;
int8 constant POS_NEUTRAL = 0;
int8 constant POS_LONG = 1;

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