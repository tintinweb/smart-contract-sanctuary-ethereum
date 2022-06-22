// Get fund from users
// Withdraw funds
// set mimnimum funding value in USD

//SPDX-License-Identifier: MIT

/*STYLE GUIDE*/
//1.pragma
pragma solidity ^0.8.7;

//2.import
import "./PriceConverter.sol";

//3. error code (don't use require! the string needs to be saved in storage, use error code instead)
error FundMe__NotOwner();
error FundMe__NotEnoughMoney();
error FundMe__CallFailure();

//4. Interfaces, Contracts

//the below is NatSpac
/** @title A contract for crowd funding
 * @author Dong Hun Kim
 * @notice This constract is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
  //1) Type Declarations
  using PriceConverter for uint256;

  //2) State Variables (important for optimization) SLOAD, SSTORE takes so much gas
  //public variables cost most
  uint256 public constant minimumUsd = 1 * 1e18; //need to convert into ETH, need to interact with real word(external world)
  //we need blockchain oracle for connected to external world!
  address[] private s_funders;
  //s_ for storage value
  mapping(address => uint256) private s_addressToAmountFunded; //record of how much amount the address sent

  address private immutable i_owner;

  AggregatorV3Interface private s_priceFeed;

  //3) events

  //4) modifier
  modifier onlyOwner() {
    // require(msg.sender == owner, "Sender is not owner!"); //it is the same with below
    if (msg.sender != i_owner) revert FundMe__NotOwner();
    //underbar means do the rest
    _;
  }

  //5) all other functions
  //order : constructor, receive, fallback, exteranl, public, internal, private, view/pure

  //prcefeed differs for network
  constructor(address priceFeedAddress) {
    //whoever deployed the project
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    i_owner = msg.sender;
  }

  fallback() external payable {
    fund();
  }

  receive() external payable {
    fund();
  }

  //payable keyword allows access to VALUE
  //the below is NatSpac
  /**
   * @notice This function add funds
   * @dev This implements price feeds as our library
   */
  function fund() public payable {
    //we are allowed to do this due to having used using PriceConverter library
    if (msg.value.getConversionRate(s_priceFeed) < minimumUsd)
      revert FundMe__NotEnoughMoney();
    // require(
    //   msg.value.getConversionRate(s_priceFeed) >= minimumUsd,
    //   "Didn't sent enough"
    // );
    //setting minimum ETH paying value to 1eth
    // require(getCon versionRate(msg.value)>=minimumUsd, "Didn't sent enough"); //1e18 = 1 * 10 ** 18 == 1eth (value in WEI)
    //revert means canceling the transaction that was done just before and returns the gas payed in advance
    //the decimal point is not specified 30000000000000 is actually 3000.0000000000ETH
    s_funders.push(msg.sender); //record sender address
    s_addressToAmountFunded[msg.sender] = msg.value;
  }

  //onlyOwner is like a decorator
  function withdraw() public payable onlyOwner {
    for (
      uint256 funderIndex = 0;
      funderIndex < s_funders.length;
      funderIndex++
    ) {
      address funder = s_funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0); //0 means no objects in it

    //payable(address) makes an address payable
    //transfer(X) means give X to that address
    // payable(msg.sender).transfer(address(this).balance)

    //send returns a boolean onSuccess or on failure
    // bool sendSuccess = payable(msg.sender).send(address(this).balance);
    // require(sendSuccess, "Send failed"); //this makes revert enabled! the previous instruction is revoked

    //call is the recommended way to send tokens!
    (bool callSucess, ) = payable(msg.sender).call{
      value: address(this).balance
    }(""); //in call parantheses we input a function, can be left empty with "
    if (!callSucess) revert FundMe__CallFailure();
    // require(callSucess, "Call failed");
  }

  function cheaperWithdraw() public payable onlyOwner {
    //moving to memory can save a ton of gas
    address[] memory funders = s_funders;
    //mappings can't be in memory
    uint256 fundersCount = funders.length;
    for (uint256 funderIndex = 0; funderIndex < fundersCount; funderIndex++) {
      address funder = funders[funderIndex];
      s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
    (bool success, ) = i_owner.call{value: address(this).balance}("");
    require(success);
  }

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

//creating a library
//SPDX-License-Identifier: MIT

//to use PriceConverter you must only test on Injected Web3 since this does not exist in Virtual Machine
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.0;

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    public
    view
    returns (uint256)
  {
    //ABI
    //Address 	0x8A753747A1Fa494EC906cE90E9f37563A8AF630e //docs.chain.link
    (, int256 price, , , ) = priceFeed.latestRoundData(); //sort of destructuring, we extract price from it
    return uint256(price * 1e10);
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    //finds eth worth in usd
    uint256 ethPrice = getPrice(priceFeed); //has additional 18 decimal points
    uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
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