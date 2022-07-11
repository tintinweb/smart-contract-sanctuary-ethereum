// THIS IS THE PATTERN YOU SHOULD FOLLOW WHEN WRITING YOUR CONTRACT:

// 1. PRAGMA
// 2. IMPORTS
// 3. ERRORS
// 4. CONTRACT, LIBRARIES, INTERFACES
// 5. EVENTS, MODIFIERS
// 6. FUNCTIONS ORDER:

    ///A. Constructor
    ///B. Receive
    ///C. Fallback
    ///D. External
    ///E. Public
    ///F. Internal
    ///G. Private
    ///H. View / Pure


// SPDX-License-Identifier: MIT
// 1. PRAGMA
pragma solidity ^0.8.7;
// 2. IMPORTS
import "./ConversionRate.sol";
// 3. ERRORS
error FundMe__Not_Owner_FBI_OPEN_UP();
error Less_Than_Minimum_Amount();
// 4. CONTRACT, LIBRARIES, INTERFACES
contract FundMe {

    using ConversionRate for uint256;


    address payable private immutable i_owner;

    AggregatorV3Interface internal s_priceFeed;

    uint256 public constant MINIMUM_AMOUNT_USD = 50;

    mapping(address => uint256) internal s_amountToFunders;
    
    address[] internal s_funders;

// 5. EVENTS, MODIFIERS
    modifier isOwner(){
    // require(msg.sender == i_owner, "FBI OPEN UP");

    /// Other method is by using error,
        if (msg.sender != i_owner) revert FundMe__Not_Owner_FBI_OPEN_UP();
        _;
    }

    modifier checkMinimumAmount(){
        if(msg.value < MINIMUM_AMOUNT_USD) revert Less_Than_Minimum_Amount();
        _;
    }

// 6. FUNCTIONS ORDER:


///A.  Constructor
    constructor(address s_priceFeedAddress){
        i_owner = payable(msg.sender);
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

       /// For our 'test' we are turning off our 'recieve' and 'fallback' functions.

///B.  Receive

    // receive() external payable {
    //     fund();
    // }

///C.  Fallback    

    // fallback() external payable {
    //     fund();
    // }


///D.  External
    // Not present in the contract.

///E.  Public

    function fund() public payable checkMinimumAmount {
        s_amountToFunders[msg.sender] = (msg.value);
        s_funders.push(msg.sender);
    }


    function withdraw() public payable isOwner {
    for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++){

        address funder = s_funders[funderIndex];
        // lets make our mapping to 0,
         s_amountToFunders[funder] = 0;
        }

        // lets make our s_funders array to 0,
         s_funders = new address[](0);

        // lets withdraw,

        // Method # 1  "transfer"
        // payable(msg.sender).transfer(address(this).balance);

        // Method # 2  "send"
        // bool transferSuccess = payable(msg.sender).send(address(this).balance);
        // require(transferSuccess, "Transfer Failed");

        // Method # 3  "call"
        (bool transferSuccess,) = i_owner.call{value: (address(this).balance)}("");
        require(transferSuccess, "Transfer Failed");
    }

    function cheaperWithdraw() public payable isOwner {
        address[] memory funders = s_funders;

        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){

            address funder = funders[funderIndex];
            s_amountToFunders[funder] = 0;
        }

        s_funders = new address[](0);

        (bool transferSuccess, ) =  i_owner.call{value: address(this).balance}("");
        require(transferSuccess, "Transfer Failed");
    }

///F.  Internal
    // Not present in the contract.


///G.  Private
    // Not present in the contract.   


///H.  View / Pure

    /// We make these functions because it is easy for other users to interact with our contract.

    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }

    function getAmountToFunders(address funder) public view returns(uint256) {
        return s_amountToFunders[funder];
    }

    function getFunders(uint256 funderIndex) public view returns(address) {
        return s_funders[funderIndex];
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ConversionRate {
    
    function ethToUsd(AggregatorV3Interface priceFeedAddress) internal view returns(uint256) {
        // Address eth/usd  Rinkeby: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // ABI
        //AggregatorV3Interface currentPrice = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (, int256 answer,,,) = priceFeedAddress.latestRoundData();     
        // this will give us eth price in USD
        return uint256(answer * 1e10);
    }

    // function getVersion() internal view returns(uint256) {
    //     AggregatorV3Interface currentPrice = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //     return currentPrice.version();
    // }

    function conversionOfEth(uint256 _ethAmount, AggregatorV3Interface priceFeedAddress) internal view returns(uint256) {
        uint256 ethPrice = ethToUsd(priceFeedAddress);
        uint256 amountInUsd = (ethPrice * _ethAmount) / 1e18;
        return amountInUsd;

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