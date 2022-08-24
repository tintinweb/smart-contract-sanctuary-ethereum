// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract FundMe {
    mapping(address => uint256) public addressToAmountFunded;
    address public owner;
    address[] public funders;

    constructor() public {
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUsd = 50 * 10**18;
        require(
            getConversion(msg.value) >= minimumUsd,
            "you need to spend kinda little more eth"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getversion() public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        return pricefeed.version();
    }

    function getprice() public view returns (uint256) {
        AggregatorV3Interface pricefeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = pricefeed.latestRoundData();
        return uint256(answer);
    }

    function getConversion(uint256 ethAmount) public view returns (uint256) {
        uint256 ethprice = getprice();
        uint256 ethAmountInUsd = (ethprice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 fundersindex = 0;
            fundersindex < funders.length;
            fundersindex++
        ) {
            address funder = funders[fundersindex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}