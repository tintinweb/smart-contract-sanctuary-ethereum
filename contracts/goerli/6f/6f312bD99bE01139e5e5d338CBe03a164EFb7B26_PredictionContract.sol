// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PriceFeed.sol";

error Prediction__Limit_Exceeded();
error Prediction__Not_Enough_Amount();
error Prediction__Refund_Error();

contract PredictionContract is AutomationCompatibleInterface {
    // create all the contest - done
    // add predict function for each contest - done
    // set difference from predicted value - done
    // set results for each contests

    // STRUCTS

    struct Contest {
        uint256 id;
        address priceFeedAddress;
    }

    struct Prediction {
        int256 predictedValue;
        uint256 predictedAt;
        uint256 difference;
        address user;
        uint256 amount;
    }

    // STATE VARIABLES
    Contest[] private s_contests;
    uint256 private s_lastTimeStamp;
    address[] private s_priceFeedAddresses;
    uint256 private immutable i_entranceFee;
    uint256 private immutable i_interval;
    mapping(uint256 => Prediction[]) private s_PredictionsOf;
    mapping(uint256 => uint256[]) private s_RewardArrayOf;
    mapping(uint256 => address[]) private s_WinnersOf;
    IERC20 Token;
    address private s_tokenAddress;

    // EVENTS

    event NewPrediction(
        int256 predictedValue,
        uint256 predictedAt,
        uint256 difference,
        address user
    );
    event ContestCompleted(uint256 contestId);
    event ContestCancelled(uint256 contestId);

    // FUNCTIONS

    constructor(
        address[] memory addresses,
        uint256 entranceFee,
        uint256 interval,
        address _s_tokenAddress
    ) {
        s_lastTimeStamp = block.timestamp;
        i_entranceFee = entranceFee;
        s_priceFeedAddresses = addresses;
        i_interval = interval;
        Token = IERC20(_s_tokenAddress);
        s_tokenAddress = _s_tokenAddress;
        createContest();
    }

    function createContest() internal {
        for (uint256 i = 0; i < s_priceFeedAddresses.length; i++) {
            s_contests.push(Contest(i + 1, s_priceFeedAddresses[i]));
        }
    }

    function predict(uint256 contestId, int256 _predictedValue) public payable {
        if (s_PredictionsOf[contestId - 1].length > 100) {
            revert Prediction__Limit_Exceeded();
        }
        if (Token.balanceOf(msg.sender) < 1) {
            revert Prediction__Not_Enough_Amount();
        }
        Token.transferFrom(msg.sender, address(this), 1 ether);
        s_PredictionsOf[contestId - 1].push(
            Prediction(_predictedValue, block.timestamp, 0, msg.sender, i_entranceFee)
        );
        emit NewPrediction(_predictedValue, block.timestamp, 0, msg.sender);
    }

    function setRewardArray(uint256 contestId) public {
        uint256 amountForDistribution = (s_PredictionsOf[contestId - 1].length *
            i_entranceFee *
            8) / 10;
        for (uint256 i = 0; i < s_PredictionsOf[contestId - 1].length; i++) {
            if (i == 0) {
                s_RewardArrayOf[contestId - 1].push((amountForDistribution * 5) / 10);
            } else {
                s_RewardArrayOf[contestId - 1].push(
                    (s_RewardArrayOf[contestId - 1][i - 1] * 5) / 10
                );
            }
        }
    }

    function setDifference(uint256 contestId) public payable {
        if (s_PredictionsOf[contestId - 1].length < 2) {
            for (uint256 i = 0; i < s_PredictionsOf[contestId - 1].length; i++) {
                Token.transfer(s_PredictionsOf[contestId - 1][i].user, 1 ether);
            }
            delete s_PredictionsOf[contestId - 1];
            delete s_RewardArrayOf[contestId - 1];
            emit ContestCancelled(contestId);
        }
        (int256 price, uint8 decimal) = PriceFeed.getUSDPrice(
            AggregatorV3Interface(s_contests[contestId - 1].priceFeedAddress)
        ); /*AggregatorV3Interface(s_contests[contestId - 1].priceFeedAddress)*/
        setRewardArray(contestId);
        delete s_WinnersOf[contestId - 1];
        for (uint256 i = 0; i < s_PredictionsOf[contestId - 1].length; i++) {
            int256 value = int256(s_PredictionsOf[contestId - 1][i].predictedValue) *
                int256(10**decimal);
            if (value < price) {
                s_PredictionsOf[contestId - 1][i].difference = uint256(price - value);
            } else {
                s_PredictionsOf[contestId - 1][i].difference = uint256(value - price);
            }
        }
    }

    function getResult(uint256 contestId) public payable {
        setDifference(contestId);
        Prediction memory data;
        for (uint256 i = 0; i < s_PredictionsOf[contestId - 1].length; i++) {
            for (uint256 j = 0; j < s_PredictionsOf[contestId - 1].length - i - 1; j++) {
                if (
                    s_PredictionsOf[contestId - 1][j].difference >
                    s_PredictionsOf[contestId - 1][j + 1].difference ||
                    (s_PredictionsOf[contestId - 1][j].difference ==
                        s_PredictionsOf[contestId - 1][j + 1].difference &&
                        s_PredictionsOf[contestId - 1][j].predictedAt >
                        s_PredictionsOf[contestId - 1][j + 1].predictedAt)
                ) {
                    data = s_PredictionsOf[contestId - 1][j];
                    s_PredictionsOf[contestId - 1][j] = s_PredictionsOf[contestId - 1][j + 1];
                    s_PredictionsOf[contestId - 1][j + 1] = data;
                }
            }
        }
        for (uint256 i = 0; i < s_PredictionsOf[contestId - 1].length; i++) {
            s_WinnersOf[contestId - 1].push(s_PredictionsOf[contestId - 1][i].user);
            Token.transfer(
                s_PredictionsOf[contestId - 1][i].user,
                s_RewardArrayOf[contestId - 1][i]
            );
        }
        delete s_PredictionsOf[contestId - 1];
        delete s_RewardArrayOf[contestId - 1];
        emit ContestCompleted(contestId);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = ((block.timestamp - s_lastTimeStamp) > i_interval);
    }

    function performUpkeep(
        bytes memory /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (((block.timestamp - s_lastTimeStamp) > i_interval) && upkeepNeeded) {
            s_lastTimeStamp = block.timestamp;
            for (uint256 i = 0; i < s_contests.length; i++) {
                getResult(i + 1);
            }
        }
    }

    function getContest(uint256 contestId) public view returns (Contest memory) {
        return s_contests[contestId - 1];
    }

    function getNumOfContests() public view returns (uint256) {
        return s_contests.length;
    }

    function getContests() public view returns (Contest[] memory) {
        return s_contests;
    }

    function getPredictions(uint256 contestId) public view returns (Prediction[] memory) {
        return s_PredictionsOf[contestId - 1];
    }

    function getLatestTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    function getEntranceFee() public view returns (uint256) {
        return i_entranceFee;
    }

    function getRewardArray(uint256 contestId) public view returns (uint256[] memory) {
        return s_RewardArrayOf[contestId - 1];
    }

    function getTotalBalance(uint256 contestId) public view returns (uint256) {
        return s_PredictionsOf[contestId - 1].length * i_entranceFee;
    }

    function getLatestPrice(uint256 contestId) public view returns (int256, uint8) {
        (int256 price, uint8 decimal) = PriceFeed.getUSDPrice(
            AggregatorV3Interface(s_contests[contestId - 1].priceFeedAddress)
        );
        return (price, decimal);
    }

    function getWinners(uint256 contestId) public view returns (address[] memory) {
        return s_WinnersOf[contestId - 1];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceFeed {
    function getUSDPrice(AggregatorV3Interface priceFeed) internal view returns (int256, uint8) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        uint8 decimal = priceFeed.decimals();
        return (price, decimal);
    }

    // function getConversionRate(uint256 amount) internal pure returns (int256) {
    //     int256 ethPrice = getUSDPrice();
    //     int256 totalAmount = (ethPrice * int256(amount)) / 1e18;
    //     return totalAmount;
    // }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

interface AutomationCompatibleInterface {
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