/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

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
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
    }

    modifier OnlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    enum FunderRank {
        Silver,
        Gold,
        Platinum,
        Diamond
    }

    mapping(address => uint256) amountFounded;
    address[] public funders;
    uint40 public funderAmount;

    struct s_funders {
        FunderRank _rank;
        uint8 _votingStrength;
        uint256 _contributed;
    }
    mapping(address => s_funders) public funder;

    function fund() public payable {
        uint256 minContributed = 50 * 10**18;
        require(getConversionRate(msg.value) >= minContributed);
        if (amountFounded[msg.sender] == 0) {
            funderAmount++;
            funders.push(msg.sender);
        }
        amountFounded[msg.sender] += msg.value;
        funder[msg.sender]._contributed += msg.value;
        if (amountFounded[msg.sender] >= 10 ether) {
            funder[msg.sender]._rank = FunderRank.Diamond;
            funder[msg.sender]._votingStrength = 10;
        } else if (
            amountFounded[msg.sender] < 10 ether &&
            amountFounded[msg.sender] >= 5 ether
        ) {
            funder[msg.sender]._rank = FunderRank.Platinum;
            funder[msg.sender]._votingStrength = 5;
        } else if (
            amountFounded[msg.sender] < 5 ether &&
            amountFounded[msg.sender] >= 1 ether
        ) {
            funder[msg.sender]._rank = FunderRank.Gold;
            funder[msg.sender]._votingStrength = 2;
        } else {
            funder[msg.sender]._rank = FunderRank.Silver;
            funder[msg.sender]._votingStrength = 1;
        }
        funder[msg.sender]._contributed += msg.value;
    }

    function withdraw() public payable OnlyOwner {
        owner.transfer(address(this).balance);
    }

    function getPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = ((ethAmount * ethPrice) / (10**18));
        return ethAmountInUsd;
    }

    function getEthAmount(uint256 dollarAmount) public view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmount = ((dollarAmount * 10**36) / ethPrice);
        return ethAmount;
    }
}