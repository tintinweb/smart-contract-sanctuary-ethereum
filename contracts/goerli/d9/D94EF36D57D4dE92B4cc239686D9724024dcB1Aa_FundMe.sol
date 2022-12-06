// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;
import "AggregatorV3Interface.sol";

contract FundMe{

    mapping(address => uint256)public fundedamount;
    address public owner;
    address[]public funders;
    constructor(){
        owner = msg.sender;
    }

    function fund()public payable {
        uint256 minimum = 5;
        require(convert(msg.value) >= minimum,"You need to spend morre ETH.....");
        fundedamount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getPrice() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 answer,,,)= priceFeed.latestRoundData();
        return uint256(answer);

    }//119783000000 = 1,197.83000000

    function convert(uint256 amount)public view returns(uint256){
        uint256 ether1 = getPrice();
        return (ether1 * amount)/100000000;
    }// 1210.61560000

    modifier OnlyOwner {
        require(msg.sender == owner);
        _;
    }
    function Withdraw()public OnlyOwner payable{       
        payable(msg.sender).transfer(address(this).balance);
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            fundedamount[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT
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