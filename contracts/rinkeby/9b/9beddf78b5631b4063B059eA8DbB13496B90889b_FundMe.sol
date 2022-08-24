// SPDX-License-Identifier: MIT
pragma solidity >0.6.6;
import "AggregatorV3Interface.sol";


contract FundMe{

    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public{
        // this is the orice address of the contract on the rinkbey network
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    function fund() public payable {
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH");
        addressToAmountFunded[msg.sender] += msg.value;
        // this will push the address to the funders array
        funders.push(msg.sender);
    }



    function getVersion() public view returns(uint256){
        // this is the address of the contract on the rinkbey network
        return priceFeed.version();
    }

     function getPrice() public view returns(uint256){
        
          (,int256 answer,,,
        ) = priceFeed.latestRoundData();
        
        // we have to convert the answer from a int256 to a uint256
        // remember it is in 10**8 of the real price
        return uint256(answer*10000000000);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        // this is the address of the contract on the rinkbey network
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount )/1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10 ** 18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10 ** 18;
        return (minimumUSD * precision)/price;
    }

    // 
    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner of this contract");
        // run the rest of this code
        _;
    }

    function withdraw() payable onlyOwner public{
        // this line below says who ever call this function msg.sender
        // transfer them .transfer
        // add the balance in this contract address(this).balance
        // the require will make sure it is only withdrawn by the owner
        payable(msg.sender).transfer(address(this).balance);
        // reset add the funds in the addresstoamountto zero
        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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