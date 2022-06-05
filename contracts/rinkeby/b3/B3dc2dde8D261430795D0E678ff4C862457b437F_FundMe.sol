// SPDX-License-Identifier: MIT
//Best-practice 1- pragma
pragma solidity ^0.8.8;

/* This Contract Task:
    - Get fund from users(Set a minimum funding value in USD(using chinlink price feed))
    - Withraw funds(only contract creator)
    
*/
//Best-practice 2- import
import "./PriceConverter.sol";

//Best-practice 3- errors (precede with contract-name: ContractName_Errors())
//new custom error feature that save a lot of gaz instead of require
error FundMe_NotOwner();
error FundMe_NotEnoughFund();
error FundMe_CallFailed();

//Best-practice 4- Interfaces: None

//Best-practice 5- Libraries: None

//Best-practice 6- Contract
//NetSpec: important for readability, information sharing and documentation
/** @title A contract for crowd funding
 *   @author George Francis Mbongning T.
 *   @notice This contract is a demo sample funding contract
 *   @dev this implements chainlink price feeds as our library
 */
contract FundMe {
    //Best-practice 1- Type Declarations
    using PriceConverter for uint256;

    //Best-practice 2- State Variables

    uint256 public constant MINIMUM_USD = 50 * 1e18;
    //make it constant for gaz efficiency since we never change its value. 1e18 == 1 * 10 ** 18

    address[] private s_funders; //help us keep tract of all our wonderfull donatorsn//can be private and we callgetter
    mapping(address => uint256) private s_addressToAmountFunded; //keep tract of amount for each donator//can also be private

    address public immutable i_owner; //i_owner  of this contract(Who deploy this contract) we can make it private 12:06
    ///@notice memory variable, constant variable and immutable variable are not store in storage
    //since we declare it an initialize it in the constructor(once).never to be modified
    //we make it immutable for gaz efficiency: resume: constant and immutable
    AggregatorV3Interface private s_priceFeed;

    //Best-practice 3- Events: none for now

    //Best-practice 4- Modifiers
    modifier onlyOwner() {
        //we now have custom error in solidity that save a lot of gaz as to compare to require
        //require(msg.sender == i_owner,"Sender is not the owner");
        if (msg.sender != i_owner) {
            revert FundMe_NotOwner();
        }
        _; //this means verify it first then do the rest of the code
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * @notice This function receives fund from users and fund this contract
     * @dev this implements chainlink price feeds as our library
     */

    function fund() public payable {
        //We want to be able to set a minimum amount to send(in usd)
        //require(msg.value.getConversionRate() >= MINIMUM_USD, 'Not enough fund'); //1e18 == 1 * 10 ** 18 == 1000000000000000000 == 1 Eth
        if (!(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD)) {
            revert FundMe_NotEnoughFund();
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        //resetting the mapping datastructure
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //resetting the array
        s_funders = new address[](0); //new array with 0 element

        //Now we want to withdraw the fund 3 ways for doing this (transfer, send,call)
        //in solidity to withdraw native token you need a payable address:
        // msg.sender = type  address while payable(msg.sender) = type payable address

        /*
        //1. transfer (if failed it will error and revert gas 2300)
        payable(msg.sender).transfer(address(this).balance);
        //2.send (if failed it doesnt revert, return a bool gas 2300)
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess,"Send failed");//if it fails then this help us  revert
        */
        //3.call   (very powerful discovert later) return a boolean and data(payload)
        //as of now this is the recommended way of sending eth or your blockchain native token
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //require(callSuccess,"Call failed");//help revert
        if (!callSuccess) {
            revert FundMe_CallFailed();
        }
    }

    function cheaperWithdraw() public payable onlyOwner {
        //we want to take the storage data to memory so reading and writing will cost less gas
        address[] memory funders = s_funders; //mappings can't be in memory,sorry
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        //require(callSuccess,"Call failed");//help revert
        if (!callSuccess) {
            revert FundMe_CallFailed();
        }
    }

    //What happens if someone sends this contract ETH or native token without calling fund function
    //We have two special function in solidity: receive() and fallback()

    //Ether or native blockchain token is send to contract
    // is msg.data empty?
    //     |.      |.
    //.    yes     no
    //.    |.      |
    // receive()?  fallback()
    //.  |.     |
    //  yes.    no.
    //.  |.      |
    //receive().  fallack()

    //View/Pure functions
    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/*
Librairy can send eth, never start with contract, you cant declare state variale
-All the function are internal
*/
//importing from npm package
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    //This function help us get eth price in usd:its interact with other(outside contract)
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // we need the ABI and Adress of the contract to interact with.
        //the address is here: https://docs.chain.link/docs/ethereum-addresses/
        //look for eth/usd
        //Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        //ABI: look up the interface exposing allthe function compile it to get abi
        //ABI: AggregatorV3Interface

        /*A contract at this address will contain all the function from the interface*/
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //ETH in terms of USD decimal(8)
        return uint256(price * 1e10); //we receive 8 decimal price and add 10 zeros to match msg.value unit
    }

    //This function convert the msg.value eth amount(wei)n to its dollar counterpart
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; //we divide by 1e18 to have a result with 1e18 since both values multiplied have each 18 decimal
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