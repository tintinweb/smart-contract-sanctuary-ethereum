// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
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
    address public owner;
    AggregatorV3Interface priceFeed;

    constructor(address _priceFeed) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    mapping(address => uint256) public addressToAmountFunded;

    function fund() public payable {
        uint256 minimumFunded = 0 * 10**18;
        require(getConvertedAmount(msg.value) >= minimumFunded, "spend more!");
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function getInfo() public view returns (uint256, uint8) {
        return (priceFeed.version(), priceFeed.decimals());
    }

    // get price
    function getConversionRate() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
        // 304454914274 with 8 decimal places
    }

    // get conversion rate
    // check if the amount of ETH sent is greater of eql to $50
    // if not return (or reject)
    function getConvertedAmount(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethRate = getConversionRate();
        uint256 ethToUsd = (ethRate * ethAmount) / 1000000000000000000;
        return ethToUsd;
        // 0.000003048805068040 = 1 Gwei
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "can't make a withdrawl");
        _;
    }

    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}