// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

contract Escrow is KeeperCompatibleInterface {
    // chainlink price feed
    AggregatorV3Interface internal priceFeed;

    // participants
    address public bull; // bets the price will be higher than anchor at expiration
    address public bear; // bets the price will be lower than anchor at expiration
    // parameters
    uint256 public anchorPrice; // anchor > expirationPrice --> bear and vice versa
    uint256 public wager; // the amount each party has to put up
    // timekeeping
    uint256 public initTimestamp; // timestamp the bet was initialized
    uint256 public activeTimestamp; // timestamp the bet was fully funded
    uint256 public paydayTimestamp; // payday / expiration time
    // TODO: account for one deposit made
    enum State {
        INITIALIZED,
        ACTIVE,
        COMPLETE
    } // contract state
    State public state;

    /** The constructor initializes the escrow betting contract
    address _assetPriceFeed - address of the chainlink datafeed
    int256 _anchorPrice - the high or low point
    uint256 _paydayTimestamp - payday / expiration time
    */
    constructor(
        address _assetPriceFeed,
        uint256 _wager,
        uint256 _anchorPrice,
        uint256 _paydayTimestamp
    ) {
        // TODO: add parameter checks
        initTimestamp = block.timestamp;
        priceFeed = AggregatorV3Interface(_assetPriceFeed);
        wager = _wager;
        anchorPrice = _anchorPrice;
        paydayTimestamp = _paydayTimestamp;
        state = State.INITIALIZED;
    }

    // TODO: refactor
    function bullDeposit() public payable {
        require(bull == address(0), "The bull deposit was already made.");
        require(msg.value == wager, "Must deposit wager ammount.");
        bull = msg.sender;
    }

    function bearDeposit() public payable {
        require(bear == address(0), "The bear deposit was already made.");
        require(msg.value == wager, "Must deposit wager ammount.");
        bear = msg.sender;
    }

    function showContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function sendWinnings(bool bullWins) private {
        if (bullWins) {
            payable(bull).transfer(address(this).balance);
        } else {
            payable(bear).transfer(address(this).balance);
        }
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = block.timestamp > paydayTimestamp;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (block.timestamp > paydayTimestamp) {
            if (getLatestPrice() >= int256(anchorPrice)) {
                // let's just say tie goes to the bulls
                sendWinnings(true);
            } else {
                sendWinnings(false);
            }
        }
    }

    // TODO: change state
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

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}