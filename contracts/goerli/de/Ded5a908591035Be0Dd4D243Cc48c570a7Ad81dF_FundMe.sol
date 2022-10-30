//get funds from users
//withdraw funds
//set a mini funding value in usd


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";
contract FundMe {

    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 50 * 1e18; // usd with 18 decimals
    address[] public funders;
    mapping(address => uint256) public addressToAmountFounded;
    address public  /* immutable */ owner;

    AggregatorV3Interface public priceFeed;

    // priceFeed : contract address to get the price will be passed dynamically while deploying based on the chain that we deploy.
    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        //set min fund amount
        // require(getConversionRate(msg.value) >= minimumUSD , "didn't send enough funds!"); //1e18 = 1 * 10 **18 == 1000000000000000000 -> use without library
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "didn't send enough funds!.");

        funders.push(msg.sender); // push sender to funded array.
        addressToAmountFounded[msg.sender] = msg.value; // keeps track of how much amount sent for each address.
    }

    function withdraw() public onlyOwner {
         for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
             address funder = funders[funderIndex];
             addressToAmountFounded[funder] = 0;
         }
         //reset array 
         funders = new address[](0); //blank new array
         //withdraw 
         //three diff ways : transfer(throws error), send(return bool), call(return bool)

         // transfer : transfer automatically reverts if transfer failes and it uses 2300gas. IF used more txn fails
         //msg.sender = address
         //payable(msg.sender) = payable address
        //  payable(msg.sender).transfer(address(this).balance);

         //send : require is needed to check whether send is success or not. Send returns bool and it also uses 2300gas
        //  bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //  require(sendSuccess, "Send failed.");

         //call :
         (bool callSuccess,) = payable(msg.sender).call{value : address(this).balance}("");
         require(callSuccess, "Call failed.");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed to call this.");
        _;
    }

    //what happens if someone sends eth to this contract without calling fund function?
    //ex: direclty sending eth to the contract address - then fund() will not be executed so
    // solidity has some special functions like recieve and fallback - these are executed when funds are sent to the contract directly.

    receive() external payable{
        fund();
    }
    fallback() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
// A library is embedded into the contract if all library functions are internal.
// Otherwise the library must be deployed and then linked before the contract is deployed.

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData(); //as we only care  about price
        //will get price of eth in usd
        // price will have 8 decimal s but the value at msg.value has 18 decimals. So to equal them do power of to price with 10.
        // and typecast int256 to uint256
        return uint256(price * 1e10); // 1**10 = 10000000000
    }

    //not needed - sample one
    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 _ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);

        // 3000_000000000000000000 = ETH/USD price - 18 decimals -> ethPrice
        // 1_000000000000000000 -> _ethAmount
        // 3000.000000000000000000 -> ethAmopuntInUsd

        uint256 ethAmountInUsd = (ethPrice * _ethAmount) / 1e18;
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