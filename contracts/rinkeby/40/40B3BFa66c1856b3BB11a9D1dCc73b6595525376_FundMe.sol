// SPDX-License-Identifier: MIT

// 1.pragma
pragma solidity ^0.8.0;
// 2.import
import "./PriceConverter.sol";
// Withdraw Funds
// Set a minimum funding value in USD

// trick to reduce the gas cost in creating contract
// 1. constant
// 2. immutable
// 3. updating require statement by replacing it with error
// 4.
// using on variables that only if we only setting our variables once

// cost in creating the contract: 859,817
// 840269 gas: using constant
// 816786 gas: using constant and immutable

// why immutable and constant can reduce gas cost?
// because instead of storing those variables inside of a storage slot,
// we store it directly into the bytecode of the contract
// we
// 3.error code
error Fundme__NotOwner();

// 4. Interface, Libraries, Contracts

/**
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implementation price feeds as our library
 */
contract FundMe {
    // Type declaration
    using PriceConverter for uint256;

    // State varialbe
    uint256 public constant MNIMUM_USD = 50 * 1e18; // 1 * 10 ** 18

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;
    // setup the owner of the contract
    address private immutable i_owner;

    // modifier only owner
    // modifier: a keyword that we can add right in the function declaration to
    // modify the function with that functionality

    // What happens if someone sends this contract ETH without calling the fund function?

    // receive()
    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender is not owner");
        if (msg.sender != i_owner) {
            revert Fundme__NotOwner();
        }
        _;
        // _; meaning doing the rest of the code
    }

    // order of function
    // constructor
    // receive function()
    // fallback function()
    // external
    // public
    // internal
    // private

    constructor(address s_priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(s_priceFeedAddress);
    }

    receive() external payable {
        fund();
    }

    // fallback()

    fallback() external payable {
        fund();
    }

    function fund() public payable {
        // payable: mark the function can send ETH or whatever native blockchain token
        require(
            msg.value.getConversionRate(s_priceFeed) >= MNIMUM_USD,
            "You need to spend more ETH"
        ); //1e18 = 1 * 10 ** 18 wei
        // what is reverting?
        // revert mean undo any action before, and send remaining gas back
        // requier statement: when you need something in your contract to happen, and you want the whole transaction to fail if that doesn't happen
        // to get the ETH or blockchainnative token value of a transaction, use the msg.value
        s_funders.push(msg.sender);
        // msg.sender stand for the address call the function
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            s_addressToAmountFunded[s_funders[funderIndex]] = 0;
        }
        s_funders = new address[](0);
        // way to send eth or asset back to whom calling this function:
        // msg.sender = address
        // payable(msg.sender) = payable address (only payable address can send eth or asset)
        // 1. transfer: auto revert when the transfer fail
        // payable(msg.sender).transfer(address(this).balance);
        // 2. send: can only revert if we add the require statement
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "failed to send");
        // 3. call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "failed to call");
    }

    function cheaperWithdraw() public payable onlyOwner {
        // Copy the funders array to a temp array
        address[] memory funders = s_funders;
        // Note: mapping can't be in the memory
        for (uint256 i = 0; i < funders.length; i++) {
            s_addressToAmountFunded[funders[i]] = 0;
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

/*
    1. Enums
    2. Events
    3. Try / Catch
    4. Function Selectors
    5. abi.encode / decode
    6. Hashing
    7. Yul / Assembly 

    */
/*
 variable storage
    -   memory variable, constant variable and immutable variable dont go in storage
    -   sstore and sload is extremely expensive  
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // to interact with other contract outside we need: ABI and Address of the contract
        // Address: 0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // ABI

        // hard coded
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        // );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // ETH in terms of USD
        // 3000.00000000
        return uint256(price * 1e10); // 1 ** 10
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUSD;
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