/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

pragma solidity ^0.8.0;

contract Oracle {

    struct PriceInfo {
        uint priceToETH;
        uint lastUpdate;
    }

    mapping (address => PriceInfo) priceInfo;
    address public feeder;
    uint constant internal ONE = 10 ** 18;
    uint randomNumber = 1314520;

    modifier onlyFeeder() {
        require(msg.sender == feeder, "OnlyFeeder");
        _;
    }

    constructor(address _feeder) {
        feeder = _feeder;
    }

    function getTokenPrice(address token) public view returns (uint, uint) {
        return (priceInfo[token].priceToETH, priceInfo[token].lastUpdate);
    }

    function setTokenPrice(address token, uint price) public onlyFeeder {
        priceInfo[token].priceToETH = price;
        priceInfo[token].lastUpdate = block.timestamp;
    }
}