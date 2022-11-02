/**
 *Submitted for verification at Etherscan.io on 2022-11-02
*/

// File: frax/sfrxETHRateProvider.sol

/**
  *
  */

pragma solidity 0.7.6;


interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface sfrxETHInterface {
    function pricePerShare() external view returns (uint256);
}

contract sfrxETHRateProvider is IRateProvider {
    sfrxETHInterface public immutable sfrxETHToken;

    constructor (sfrxETHInterface _sfrxETHToken) {
        sfrxETHToken = _sfrxETHToken;
    }

    // Returns the ETH value of 1 rETH
    function getRate() external override view returns (uint256) {
        return sfrxETHToken.pricePerShare();
    }
}