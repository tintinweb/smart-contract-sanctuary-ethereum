/**
 *Submitted for verification at Etherscan.io on 2022-06-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract PriceTracker {

    event PriceChanged(string coin, int256 price);
    event PriceRejected(string coin, int256 value);

    mapping(string => int256) public prices;


    function set(string memory coin, int256 price) public {

        if( prices[coin] == 0 ) {
            emit PriceChanged(coin, price);
            prices[coin] = price;  
            return;
        }
        int256 percent = percentDifference( prices[coin], price );
        int absPercent = percent > 0 ? percent: - percent;

        if( absPercent >= 2) {
            emit PriceChanged(coin, price);
            prices[coin] = price;  
        } else {
            emit PriceRejected(coin, price);
        }
    }

    function get(string memory coin) public view returns (int256) {
        return prices[coin];
    }

    function percentDifference(int256 x, int256 y) private pure returns (int256) {
        int256 diff = x - y;
        return  diff * 100 / x ;
    }

}