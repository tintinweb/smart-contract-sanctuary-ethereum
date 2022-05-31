/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

pragma solidity 0.8.10;
pragma abicoder v2;

contract Oracle {

    mapping(string => uint256) public pricesMapping;

    function getRawPrice(string memory symbol) internal view returns(uint256) {
        uint256 price = 1e9;
        if (keccak256(abi.encodePacked(symbol)) != keccak256(abi.encodePacked("USD"))) {
            price = pricesMapping[symbol];
        }
        return price;
    }

    function getPriceDataBulk(string[] calldata baseSymbols, string[] calldata quoteSymbols) external view returns (uint256[] memory) {
        require(baseSymbols.length == quoteSymbols.length, "BAD_INPUT_LENGTH");
        uint256 len = baseSymbols.length;
        uint256[] memory results = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            results[i] = (getRawPrice(baseSymbols[i]) * 1e18) / getRawPrice(quoteSymbols[i]);
        }
        return results;
    }

    function relaySingle(string memory symbol, uint256 price) internal {
        pricesMapping[symbol] = price;
    }

    function relayMultiple(string[] memory symbols, uint256[] memory prices) public {
        require(symbols.length == prices.length, "BAD_INPUT_LENGTH");
        uint256 len = symbols.length;
        for (uint256 i = 0; i < len; i++) {
            relaySingle(symbols[i], prices[i]);
        }
    }
}