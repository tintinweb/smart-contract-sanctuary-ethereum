/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: AggregatorV3Interface

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// Part: SafeMath96

library SafeMath96 {
    function add(uint96 a, uint96 b) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint96 c = a - b;

        return c;
    }

    function mul(uint96 a, uint96 b) internal pure returns (uint96) {
        if (a == 0) {
            return 0;
        }

        uint96 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b > 0, "SafeMath: division by zero");
        uint96 c = a / b;

        return c;
    }

    function mod(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: FundMe.sol

contract FundMe {
    using SafeMath96 for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    //constructor(address _priceFeed) public {
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        //uint256 minimumUSD = 50 * 10**18;
        //uint256 price = getPrice();
        //uint256 precision = 1 * 10**18;
        uint256 minimumUSD = 50 * 10**8;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**8;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}