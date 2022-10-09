// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// Using error is more gas efficient compared to using `require` with a string
error FundMe__NotOwner();

/**
 * @title A contract for crowd funding
 * @author BowTiedApu
 * @notice This contract is to demo a sample funding contract purely for learning purposes
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    /**
     * Some more information on keywords:
     * constant - can never be changed after compilation.
     * immutable - can be set within the constructor
     *
     * Both constant and immutable does not reserve a storage spot for variables market constant or immutable
     */
    address public immutable i_owner;

    // This won't change after compile time, so we can mark this as `constant`, which will also optimize our gas usage
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    /**
     * Whenever we have these global variables i.e. uint256 favoriteNumber;
     * These are stuck in storage. Each slot is 32 bytes long, and represents the bytes version of the object
     * Storage is a gian array/list of all variables we create, and associated with this contract.
     * A dynamic value like mappings or dynamic arrays are stored using a hashin function.
     * For arrays, a sequential storage spot is taken up for the length of the array. For mappings, a sequential sotrage
     * spot is taken up, but left blank.
     * Constant variables are part of the contract's bytecode, and is not stored in strage; it's just a pointer to a value
     * Memory variables are deleted after the function has finished running.
     *
     * Anytime we read or write to or form storage, we spend a ton of gas. We can see this when using opcodes.
     * Gas is calculated using opcodes, and to learn more, check out https://github.com/crytic/evm-opcodes
     * Prepend "s_" to show that a variable is storage variable
     */

    AggregatorV3Interface public priceFeed;

    /**
     * A modifier is a keyword to modify a function definition.
     */
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        /**
         *  The underscore indicates we should continue with the rest of our code.
         * Order matters here, this means any require statements or "if" statements should occur before.
         * We do not want to call the rest of our code, only for the if and require checks to start and revert all the work our code already did.
         */
        _;
    }

    /**
     * `fallback` and `receive` are two special functions
     * A given contract can have at most one `receive` function without the `function` keyword.
     * It can't have args, can't return anything, and msust be external and payable. However, it can be virtual and have modifiers
     *
     * The point of receive
     */

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * @notice funds the contract
     */
    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    /**
     * @notice withdraws from the contract, but only the owner can withdraw
     */
    function withdraw() public onlyOwner {
        /**
         * This reads and writes to storage frequently. Every single time, we keep doing a
         * comparison with what is in storage, which is expensive.
         */
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        /**
         * For more info, look at https://solidity-by-example.org/sending-ether
         * There are some issues with using transfer.
         * transfer throws an error. Meaning if we try to transfer and we fail, it'll throw an error AND revert.
         * send returns a bool. Meaning if we try to send and we fail, we'll only get a boolean. We will NOT revert.
         * call returns 2 variables; a boolean and a bytes object. Call is a lower level command, and we can use it to call any function.
         *
         * Here are a few examples
         * transfer --> payable(msg.sender).transfer(address(this).balance)
         * send     --> payable(msg.sender).send(address(this).balance)
         * call     --> payable(msg.sender).call{value: adddress(this).balance}("")
         *
         * If transfer fails, it will automatically revert.
         * If send fails, we wouldn't revert the txn, so we want to add a require statement so that we revert.
         * If call returns a value, its stored in the bytes object, which is an array. If it fails, we need to use require as well to revert successfully
         */
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    /**
     * getPrice returns the current price from a given price feed.
     * This is set to view since it does *not* modify any state.
     *
     * If this was public, we would need to deploy this again
     */
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Goerli ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/

        (, int256 answer, , , ) = priceFeed.latestRoundData();

        /**
         * Recall that in Solidity, we do *NOT* deal with decimals.
         * We need to understand how to convert correctly.
         * We could express 10000000000 as 1e10, which is 1**10.
         * For more info on how to convert, check out eth-converter.com
         * Keep in mind that if we just return "answer * 1e10", we will return
         * int256, where the expectation is to return uint256. To change types, we
         * must type cast as follows:
         */
        return uint256(answer * 10000000000);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // If ETH is 1500 USD, then this ethPrice would tack on another 18 zeros, so
        // 1500_000000000000000000 which is the ETH/USD price
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // 1000000000000000000 == 1e18
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
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