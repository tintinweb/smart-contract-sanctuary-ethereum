// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;
//Imports
import "./PriceConverter.sol";
//import "hardhat/console.sol"; If u want to do the console.log in solid

//Errors
error FundMe__NotOwner();

/** @title A contract for crowd funding
 * @author ProtocolWhisper
 * @notice This constract is to demo a sample funcding contract
 * @dev  This implements pricefeeds as our library
 */
contract FundMe {
    //Typle Declarations
    using PriceConverter for uint256; //This means that te variable can acces to those functions

    //State Variables!
    uint256 public constant MINIMUN_USD = 50 * 10**18;
    address[] public s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;

    address private immutable i_owner;

    AggregatorV3Interface public s_priceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner,"Sender is not owner");
        //_;
        // This first otherwise it'll check at the last
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner(); //Following the styles of solidity docs
        }
        _;
    }

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    /**
     * @notice This function funds this contract
     */
    function fund() public payable {
        // Minimun in USD
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUN_USD,
            "Didn't send enough bro" //Since it's a library the msg.value is passed as an argument to the getConversionRate
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0; // U need the key value in this case the addy
        }
        //reset the array
        s_funders = new address[](0); // This means it's a new array with 0 elements in it
        //actually withdraw the funds

        (bool callSucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSucess, "Call Failed"); // How the fuck the call function works
    }

    function CheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // Mappings can't be in memory , sorry;
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool sucess, ) = i_owner.call{value: address(this).balance}("");
        require(sucess);
    }

    //Getters View/Pure
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        //ABI
        //Address of the contract 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        (, int256 price, , , ) = priceFeed.latestRoundData();

        //Eth in terms of usd
        //The result will have 8 decimals so since we want to all be in the same notation we will use
        return uint256(price * 1**10);
    }

    function getDecimals() public view returns (uint8) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        return priceFeed.decimals();
    }

    function getVersion() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        return priceFeed.version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface i_priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(i_priceFeed);
        uint256 ethAmountinUsd = (ethPrice * ethAmount) / 1**18;
        return ethAmountinUsd;
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