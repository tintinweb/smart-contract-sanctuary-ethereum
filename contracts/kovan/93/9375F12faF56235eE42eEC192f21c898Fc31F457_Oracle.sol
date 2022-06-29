/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;

contract Oracle {
    event PriceUpdate(
        string symbol,
        uint64 rate,
        uint64 resolveTime
    );

    struct PriceResult {
        uint256 rate; // base/quote exchange rate, multiplied by 1e18.
        uint256 lastUpdatedBase; // UNIX epoch of the last time when base price gets updated.
        uint256 lastUpdatedQuote; // UNIX epoch of the last time when quote price gets updated.
    }

    struct Price {
        uint64 rate; // USD-rate, multiplied by 1e9.
        uint64 resolveTime; // UNIX epoch when data is last resolved.
    }

    /// Mapping from token symbol to ref data
    mapping(string => Price) public refs;

    constructor() {}

    function setPrice(
        string[] memory symbols,
        uint64[] memory rates,
        uint64[] memory resolveTimes
    ) external {
        uint256 len = symbols.length;
        require(rates.length == len, "BADRATESLENGTH");
        require(resolveTimes.length == len, "BADRESOLVETIMESLENGTH");
        for (uint256 idx = 0; idx < len; idx++) {
            refs[symbols[idx]] = Price({
                rate: rates[idx],
                resolveTime: resolveTimes[idx]
            });
            emit PriceUpdate(
                symbols[idx],
                rates[idx],
                resolveTimes[idx]
            );
        }
    }

    function getPrice(string memory base, string memory quote)
        public
        view
        returns (PriceResult memory)
    {
        (uint256 baseRate, uint256 baseLastUpdate) = _getPrice(base);
        (uint256 quoteRate, uint256 quoteLastUpdate) = _getPrice(quote);
        return
            PriceResult({
                rate: (baseRate * 1e18) / quoteRate,
                lastUpdatedBase: baseLastUpdate,
                lastUpdatedQuote: quoteLastUpdate
            });
    }

    function _getPrice(string memory symbol)
        internal
        view
        returns (uint256 rate, uint256 lastUpdate)
    {
        if (keccak256(bytes(symbol)) == keccak256(bytes("USD"))) {
            return (1e9, block.timestamp);
        }
        Price storage price = refs[symbol];
        require(price.resolveTime > 0, "PRICENOTAVAILABLE");
        return (uint256(price.rate), uint256(price.resolveTime));
    }
}