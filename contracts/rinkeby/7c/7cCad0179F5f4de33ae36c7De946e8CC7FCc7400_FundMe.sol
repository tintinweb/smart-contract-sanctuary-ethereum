//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;
    mapping(address => uint256) private s_funderToEA;
    address[] private s_funders;

    address private immutable i_owner;
    uint256 public constant USD_MIN = 11 * 1e18;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    
//fund function
    function fund() public payable{
    //   what `1 eth is equal to in gwei
    //    1e18 == 1 * 10 ** 18 == 1000000000000000000
     

        require(msg.value.getConversionRate(s_priceFeed) >= USD_MIN, "not so fast");
        s_funders.push(msg.sender);
        s_funderToEA[msg.sender] += msg.value;
    }

//withdraw function
    function withdraw() public onlyOwner {
        
        for(
            uint256 funderIndex = 0; 
            funderIndex < s_funders.length; 
            funderIndex++
            ){
            address funder = s_funders[funderIndex];
            s_funderToEA[funder] = 0;
        }

        s_funders = new address[](0);

        //transer
        // payable(msg.sender).transfer(address(this).balance)
        //send
        bool didSucceed = payable(msg.sender).send(address(this).balance);
        require(didSucceed, "oops, that didnt work");
        //call
        (bool callTransaction, ) = payable(msg.sender).call{value:address(this).balance}("");
        require(callTransaction, "oops again");
    }
//cheaper Withdraw function
    function cheaperWithdraw () public payable onlyOwner{
        address[] memory funders = s_funders;

        for(uint256 fundersI; fundersI < funders.length; fundersI++){
            address funder = funders[fundersI];
            s_funderToEA[funder] = 0;
        }
    }

    modifier onlyOwner () {
        // require(msg.sender == owner, "you are not authorized");
        if(msg.sender != i_owner){
            revert NotOwner();
        }
        _;
    }

    function get_owner() public view returns (address) {
        return i_owner;
    }

    function get_funder(uint256 index) public view returns ( address) {
        return s_funders[index];
    }

    function get_funderToEA(address funder) public view returns(uint256){
        return s_funderToEA[funder];
    }
    
    function get_priceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }

}

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//cannot create any State variables and cannot send or store ETH.
library PriceConverter {

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
        //we need
        //address of contract 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //ABI
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        (, int256 price,,,) = priceFeed.latestRoundData();
        // ^will return
        //price of ETH in USD
        //will return as a number with no decimal 
        return uint256(price * 1e10);

    }



    function getConversionRate (uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256){
        //eth = .5
        //usd minimum = $11
        //is .5 eth === $11
        uint256 ethPrice = getPrice(priceFeed);
       
        uint256 currentPrice = ( ethPrice * ethAmount) / 1e18;
        return currentPrice;
    }
}