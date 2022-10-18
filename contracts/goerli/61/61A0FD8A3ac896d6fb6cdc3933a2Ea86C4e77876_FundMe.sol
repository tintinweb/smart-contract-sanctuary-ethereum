// SPDX-License-Identifier: MIT
// Get fund from user
// withdraw funds
// set minimum funding value in USD

pragma solidity ^0.8.17;

import "./PriceConverter.sol";

    error NotOwner();

contract FundMe {

    using PriceConverter for uint256;

    //use constant if the variable is declared only once to save "gas"
    uint public constant MINIMUM_USD = 50 * 1e18; // 1 * 10 ** 18
    address[] public  funders;
    mapping(address => uint256) public addressToAmountFunded;

    address public immutable  i_owner;

    AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeed){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "Didn't send enough");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {

        for (uint funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        //reset the Array
        funders = new address[](0);

        //call - forward all gas or set gas , return bool

        (bool callSuccess,) = payable(msg.sender).call{value : address(this).balance}("");
        require(callSuccess, "Call Failed");

        // //transfer - throw error
        // payable (msg.sender).transfer(address(this).balance);

        // //send - return bool
        // bool sendSuccess = payable (msg.sender).send(address(this).balance);
        // require (sendSuccess , "Sending Failed");
    }

    modifier onlyOwner {

        //  require (msg.sender == i_owner, "Sender is not owner");

        if (msg.sender != i_owner) {
            revert NotOwner();
        }
        _;
    }

    //whenever a trancation toward the contract automatically route it to func()
    //example : directly send from wallet / calling the contract itself
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


//https://docs.chain.link/docs/data-feeds/price-feeds/api-reference/ chainlink  Data Feed API referrence

//import AggregatorV3 Interface from chainlink
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getVersion() internal view returns (uint) {

        //Goerli testnet contract Address for get price =  0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return priceFeed.version();
    }

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        //ABi
        //Goerli testnet contract Address for get price =  0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

       /* AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);*/
        (,int256 answer,,,) = priceFeed.latestRoundData(); //returned 4 arguement but we only take the 2nd arguement
        return uint256 (answer * 10000000000); //returned value in 1e8 and multiply it with **10 to meet 1e18
    }

    function getConversionRate(uint256 ethAmout , AggregatorV3Interface priceFeed) internal view returns (uint256) {
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice * ethAmout)/ 1e18;
        return ethAmountInUsd;

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