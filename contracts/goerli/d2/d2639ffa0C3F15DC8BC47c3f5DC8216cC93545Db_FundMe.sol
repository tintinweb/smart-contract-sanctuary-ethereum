// SPDX-License-Identifier: MIT
// pragma
pragma solidity ^0.8.7;

//imports
import '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import './PriceConvertor.sol';

// custom errors  -- more gas efficient
error FundMe__NotOwner();
// change require ===> revert with error objects ( more gas efficient)

// use constant & immutbale keywords to make contracts more gas efficient

// interfaces, libraries, contracts...


/// @title A contract for crowd funding
/// @author P.C
/// @notice this contract is to demo a sample funding contract
/// @dev this implements price feeds as our library
contract FundMe{
    // type declaracitons
    using PriceConvertor for uint;

    // state variables
    uint public constant MINIMUM_USD = 50 * 1e18; // gas efficient
    address private immutable i_owner; // gas efficient
    address[] private s_funders;
    mapping(address => uint) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    //modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    // functions
    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // what happens if someone sends ether to this conrtact without calling the fund function,
    // or accidently call some function that doesn't exist but still trigger some code

    // receive()
    receive() external  payable {
        fund();
    }
    // fallback()
    fallback() external payable {
        fund();
    }

    function fund() public payable {
        require(msg.value.getConvertionRate(s_priceFeed) > MINIMUM_USD, "didn't send enough money");
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }


    function withdraw() public payable onlyOwner {
        for(uint funderIndex=0; funderIndex<s_funders.length;funderIndex++){
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);
        // actually send ether
        // transfer, throw an error if failed
        // payable(msg.sender).transfer(address(this).balance);
        // send, return a boolean
        // bool sendSuccess = payable (msg.sender).send(address(this).balance);
        // require(sendSuccess,"send failed");
        // call, return a boolean and data
        (bool callSuccess , ) = payable (msg.sender).call{value:address(this).balance}("");
        require(callSuccess, "call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        //  mapping can't be in the memory, sorry!!
        for(uint i = 0; i < funders.length ; i++){
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess , ) = payable (msg.sender).call{value:address(this).balance}("");
        require(callSuccess, 'call failed') ;
    }

    // view / pure

    function getOwner() public view returns(address){
        return i_owner;
    }
    function getFunder(uint index) public view returns(address){
        return s_funders[index];
    }
    function getAddressToAmountFunded(address funder) public view returns(uint){
        return s_addressToAmountFunded[funder];
    }
    function getPriceFeed() public view returns(AggregatorV3Interface){
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library PriceConvertor {

    function getPrice(AggregatorV3Interface priceFeed) internal  view returns(uint ){
        // ABI
        // address 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
        // eg. answer = 3000.00000000   (eth -- USD)s
        return uint(answer*1e10);
    }

    function getConvertionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal  view returns(uint){
        uint ethPrice = getPrice(priceFeed);
        uint ethAmountInUsd = (ethPrice* ethAmount) / 1e18;
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