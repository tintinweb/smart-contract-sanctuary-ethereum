// SPDX-License-Identifier: MIT

// Smart contract that lets anyone deposit ETH into the contract
// Only the owner of the contract can withdraw the ETH
pragma solidity ^0.8.17;

// Get the latest ETH/USD price from chainlink price feed

// IMPORTANT: This contract has been updated to use the Goerli testnet
// Please see: https://docs.chain.link/docs/get-the-latest-price/
// For more information

// Import from the [npm] package
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
    // safe math library check uint256 for integer overflows
    // using SafeMathChainlink for uint256;

    //mapping to store which address depositeded how much ETH
    mapping(address => uint256) public addressToAmountFunded;
    // array of addresses who deposited
    address[] public funders;
    //address of the owner (who deployed the contract)
    address public owner;

    AggregatorV3Interface public priceFeed;

    // the first person to deploy the contract is
    // the owner
    //Note: Dennis 11-17-22 removed the keyword [public] to use in solc 8.17
    constructor(address _PriceFeed) {
        priceFeed = AggregatorV3Interface(_PriceFeed);
        owner = msg.sender;
    }

    function fund() public payable {
        uint256 minimumUSD = 50 * 10**18;

        require(
            getConversionRate(msg.value) >= minimumUSD,
            "Not Enough ETH sent!!"
        );

        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);
    }

    //function to get the version of the chainlink pricefeed
    function getVersion() public view returns (uint256) {
        // Need Adress of where the AggregatorV3Interface is Located !!
        // Goto the docs.chainlink.org [ethereum addresses]. I.E. Price Feed Contract Addresses
        // For Me its the Goerli Testnet Price Feed ETH/USD  [0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e]
        // This tells us we have a [Contract] at the [Adress] below that contains all the [methods] defined in the [Interface!!!!!!!!!]

        // Note: Price Feed Contract Address [0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e] on the Goerli TestNet.
        //       This can be found at docs.chainlink.org [ethereum addresses]. I.E. Price Feed Contract Addresses

        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );

        return priceFeed.version();
    }

    // Get Price of ETH in US Dollars. Multiply by 10000000000 to put in 18 Digit WEI format.
    // Note: Price Feed Contract Address [0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e] on the Goerli TestNet.
    //       This can be found at docs.chainlink.org [ethereum addresses]. I.E. Price Feed Contract Addresses
    function getPrice() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // );

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit (WEI .. format)
        return uint256(answer * 10000000000);
    }

    // Input is the number of ETH. Output is the [number of ETH input] * Price of ETH in USD !!
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    //modifier: https://medium.com/coinmonks/solidity-tutorial-all-about-modifiers-a86cf81c14cb
    modifier onlyOwner() {
        //is the message sender owner of the contract?
        require(msg.sender == owner);

        _;
    }

    // onlyOwner modifer will first check the condition inside it
    // and [(this)] refers to the contract that is executing !!
    // if true, withdraw function will be executed
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance); // 11-17-22 Had to cast to [payable] for version 8.17

        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //funders array will be initialized to 0
        funders = new address[](0);
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }
}