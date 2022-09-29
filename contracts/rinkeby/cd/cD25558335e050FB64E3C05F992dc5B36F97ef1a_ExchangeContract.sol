pragma solidity ^0.8.0;

contract ExchangeContract {
    enum CurrencyType {
        USD,
        TWOKEY,
        BTC,
        ETH,
        DAI,
        USDT,
        TUSD,
        EUR,
        JPY,
        GBP
    }

    mapping(uint256 => CurrencyPrice) public priceByCurrencyType;

    struct Price {
        uint256 price;
        uint256 decimals;
    }

    struct CurrencyPrice {
        uint256 currencyInt;
        Price price;
    }

    function updatePrices(CurrencyPrice[] memory _array) public {
        for (uint256 i = 0; i < _array.length; i++) {
            priceByCurrencyType[_array[i].currencyInt].price = _array[i].price;
        }
    }
}