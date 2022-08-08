// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PriceConverter.sol";

// use declared error instead of error message string to save gas
error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author Joaquin Davila
 * @notice This is a contract to demo a sample funding contract
 * @dev This implements price feeds as our library
 */

// Contracts can hold funds just lik wallets
contract FundMe {
    // apply functions of PriceConverter.sol to uint256 variables
    using PriceConverter for uint256;

    // use "constant" on variables that are set once to save gas during deployment and calls
    uint256 public constant MINIMUM_USD = 50 * 1e18;

    address[] public fundersArray;
    mapping(address => uint256) public addressToAmountMapping;

    // "immutable" variables are set once not in the line they are declared
    address public immutable i_owner;

    AggregatorV3Interface public priceFeed;

    modifier onlyOwner() {
        //require only owner of the contract to use withdraw func
        //require(msg.sender == i_owner, "Sender is not owner!"); --> old way uses "require"
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        } // --> revert is same as require without the condition
        //execute rest of the func
        _;
    }

    //constructor is the func that is immediately called in the contract
    constructor(address priceFeedAddress) {
        // "msg.sender" is available inside functions but not in the global scope
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // fund() function will be called if no CALLDATA
    receive() external payable {
        fund();
    }

    // fund() function will be called if CALLDATA is unknown
    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // How to send ETH to this contract?

        // Use "msg.value" to access value we are sending
        // "require" will revert to orig state and return un-used gas at the point where revert is triggered

        // msg.value is the first parameter when callinG getConversionRate()
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        );

        fundersArray.push(msg.sender);
        addressToAmountMapping[msg.sender] += msg.value;
    }

    //uses onlyOwner modifier on the function
    function withdraw() public onlyOwner {
        for (uint256 index = 0; index < fundersArray.length; index++) {
            address funder = fundersArray[index];
            addressToAmountMapping[funder] = 0;
        }

        //reset the array
        fundersArray = new address[](0);

        /**3 Ways to Send ETH from a Contract**/
        //TRANSFER
        //payable(msg.sender).transfer(address(this).balance);
        //msg.sender is of type address
        //need to typecast to "payable address" using "payable(msg.sender)
        //"address(this)" is the address of the whole contract
        //".balance" used to access native blockchain currency (ETH)

        //SEND
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess,"Send failed");

        //CALL
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
        //low level command that can call any function in Ethereum without the ABI
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Import contract from a public Github repo (npm package)
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// libraries are like contracts but cannot have state variables and can't send ETH
// all functions in libraries are internal
library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH price in terms of USD (with 8 decimal places)
        // 300000000000 --> 3000.00000000

        // Convert to 18 decimal places to match WEI
        return uint256(price * 1e10);
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
        // Convert to 18 decimal places from 36
        return ((ethAmount * getPrice(priceFeed)) / 1e18);
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