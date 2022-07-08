//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
import "./PriceConverter.sol";
error NotOnwer();

contract FundMe {
    //all function we need
    using PriceConverter for uint256;
    //constatnt lowers the gas
    uint256 public constant MIN_USD = 50 * 1e18;

    //we also want to keep an array of funbder s
    address[] public funders;
    mapping(address => uint256) public addressToAmountFunded;
    address public immutable onwer;
    AggregatorV3Interface public priceFeedAddress;

    constructor(address priceFeed) {
        //we can set up the contract the way we want it to be, have it set up the onwer of the contract
        onwer = msg.sender; //msg.sender is whoever dploted the contract (constructor)
        priceFeedAddress = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        //we want to tag a function as payable if we want it to be able to recieve funds
        //want tp set min fund
        //how we we send eth to this contract
        //to get how much value someone is sending we can do msg.value

        //to requires a min amount we can do
        require(
            msg.value.getConversionRate(priceFeedAddress) >= MIN_USD, //since getConversionRate is a now a lib for integer now
            "Did not send enough"
        ); //1e18 wei is 1 eth
        //revert with the error message will revert the gas fees

        //what if we want to have require to usd ? msg.value is wei
        //we have to use decentralized blockchain oracle to get the usd value...
        //smart contracts can not interact with external systems, we not want to get
        //data from a centrtalized node, so we need an oracle decentralized oracle network(chainlink
        //we are going to use chainlink data feeds . we want to convert wei to usd !

        funders.push(msg.sender); //msg.sender is a global var is addresss of whoever calls the function
        addressToAmountFunded[msg.sender] = msg.value.getConversionRate(
            priceFeedAddress
        );
    }

    function withdraw() public onlyOnwer {
        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            addressToAmountFunded[funder] = 0;
        }
        //reset array
        funders = new address[](0); //with 0 objects in it
        //withdraw funds

        //there are three diff ways
        //transfer, send , call
        //rememebr that msg.sender is the address that call and initiate a function
        //we want ot transfer funds to whoever is calling this function
        // payable(msg.sender).transfer(address(this).balance);
        // //this represents this whole contract  --> it trasnfers the balance at this address to the person that called this function
        // bool sendSucess = payable(msg.sender).send(address(this).balance);
        // require(sendSucess, "send Failed"); //needs this call to revert , otherwise you lost the funds

        //call
        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "call failed");
        //we don't want anybody to withdraw, we want ppl who can withdraw to withdraw
        //we want this function to be only called by the onwer of the contract
    }

    modifier onlyOnwer() {
        //require(msg.sender == onwer, "sender is not he onwer");
        if (msg.sender != onwer) {
            revert NotOnwer();
        }
        _;
        //underscore means what ever is under the code , position of the underscore matters!
    }

    //check the example for why --> if someone accidentally send money without pressing the buton
    //it will still call the fund function and store the user in the mapping we havew

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//this is a libaray for uint256
//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/* 
lib is really similar to a library 
*/
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeedAddress)
        internal
        view
        returns (uint256)
    {
        //we are interacting with a contract outside our projevt
        //need address of contract and ABI of contract
        //address : 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //what about ABI? how can we import? use interface --> it defines all the ways we can interact with a contrac t
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        //eth in terms of USD, msg.value has 18 decmiamls
        return uint256(price * 1e10); //we times by 10 becuase there are 8 decmials in price initally , basically converting it to wei
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeedAddress
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeedAddress);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }

    //what happens if someone sends this contrract eth without calling fund function?
    //we want actions to triggert a function

    //recieve and fallback function '
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