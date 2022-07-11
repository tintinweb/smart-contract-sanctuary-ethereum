// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;

    AggregatorV3Interface public priceFeed;

    address public immutable i_owner;
    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress); 
    }

    function fund() public payable {
        // Want to be able to set a minimum fund amount in USD

        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough!"); // msg.value will have 18 decimal places
        funders.push(msg.sender);  // msg.sender gives the address of the sender of the message 
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {  // starting index,ending index, step amount
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] =0;
        } 
        //reset the array
        funders = new address[](0);

        //withdraw the funds

        //transfer
        payable(msg.sender).transfer(address(this /* whole contract */ ).balance);   //transfer returns error
        /* msg.sender is address
        payable(msg.sender) is payable address */
        // send
        bool sendSuccess = payable(msg.sender).send(address(this ).balance); // send returns boolean
        require(sendSuccess,"Send failed");
        //call
        (bool  callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");   //call returns bool and a bytes object
        require(callSuccess,"call failed");
        
    }

    modifier onlyOwner{
        // require(msg.sender == i_owner , "Sender is not owner");
        if(msg.sender != i_owner){ revert NotOwner();}
        _;
    }
    
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
 
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        //ABI
        // Address of chain link contract to get price from 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e  (Rinkeby) 
        (, int price,,,) = priceFeed.latestRoundData();
        // Eth in terms of USD

        return uint (price * 1e10);  // typecasting to uint bcoz msg.value will be uint  //  1e10 is done as msg.value is of 18 decimal places and latestRoundData returns value in 8 decimal places
    }


    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
         
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