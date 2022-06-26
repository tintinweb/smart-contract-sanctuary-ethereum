//Get $$$ from users
//Withdraw $$$
// Set minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

//ERROR CODES
error FundMe__NotOwner();
error FundMe__NotEnoughFunds();
error FundMe__WithdrawFail();

/** @title A contract for crowd funding
 *  @author env
 *  @notice This contract is a demo/sample of a funding contract
 *  @dev This implements price feeds as our library
 */
contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;
    //State variables
    uint256 public constant MINIMUM_USD = 10 * 1e16;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    address private immutable i_owner;
    AggregatorV3Interface public s_priceFeed;
    //Events
    //Modifiers

    modifier onlyOwner() {
        //require(msg.sender == owner, "Sender is not Owner");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    // Functions
    //// Constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    //recive() each time reive any transantion its trigret
    receive() external payable {
        fund();
    }

    //fallback() calldata with data
    fallback() external payable {
        fund();
    }

    /**
     *  @notice This function funds this contract
     *  @dev This implements price feeds as our library
     */
    function fund() public payable {
        //1. Send ETH to this contract
        //set a minimum value to send
        // require(
        //     msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
        //     "Did not send enoungh $$$"
        // ); // 1e18 == 1*10^18 == value in wei to 1 ETH
        if (msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) {
            revert FundMe__NotEnoughFunds();
        }
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function Withdraw() public onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array
        s_funders = new address[](0);

        // transfer --> 2300 gass, throws error
        //        payable(msg.sender).transfer(address(this).balance);
        // send --> 2300 gass, returns boolean
        //        bool state = payable(msg.sender).send(address(this).balance);
        //        require(state,"Send FAIL");
        //call --> forward all gass, returns boolean
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) {
            revert FundMe__WithdrawFail();
        }
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;

        for (uint256 i = 0; i < funders.length; i++) {
            address funder = funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if (!callSuccess) {
            revert FundMe__WithdrawFail();
        }
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 i) public view returns (address) {
        return s_funders[i];
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH/USD

        return uint256(price * 1e10); //1*10^10
    }

    // function getVersion() internal view returns (uint256) {
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
    //     );
    //     return priceFeed.version();
    // }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
    }
}