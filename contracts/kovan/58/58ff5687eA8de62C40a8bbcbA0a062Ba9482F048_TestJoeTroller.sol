// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract TestJoeTroller {
    address[] markets;

    event MarketListed(address jToken);
    event MarketDelisted(address jToken);

    function addMarket(address _market) external {
        markets.push(_market);
        emit MarketListed(_market);
    }

    function popMarket() external {
        address removedMarket = markets[markets.length - 1];
        markets.pop(); // delete the last item
        emit MarketDelisted(removedMarket);
    }

    function getAllMarkets() public view returns (address[] memory) {
        return markets;
    }

    function setMarkets(address[] memory newMarkets) public {
        markets = newMarkets;
    }
}