// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "AggregatorV3Interface.sol";

/**
 * @dev Contract module which can create prediction instance and let users post their own prediction
 * for ETH/USD future price. Settlement is made based on Chainlink price Oracle.
 */

contract PredictionPool is Ownable {

    bool public isActive;
    uint256 public fee;
    mapping(uint256 => mapping(address => uint256)) public predictions;
    mapping(uint256 => address[]) public participants;
    mapping(uint256 => mapping(address => bool)) public hasParticipated;
    mapping(uint256 => mapping(address => bool)) public winners;
    AggregatorV3Interface internal ethUsdPriceFeed;

    /**
     * @dev struct containing all the prediction info
     */
    struct predictionSpec {
        uint256 commitment;
        uint256 startStamp;
        uint256 lockStamp;
        uint256 endStamp;
        bool settlement;
        uint256 winnersCount;
        uint256 instanceValue;
        uint256 closingPrice;
        address creator;
    }

    /**
     * @dev array of predictionSpec
     */
    predictionSpec[] public predictionsSpec;

    /**
     * @dev requires pool to be active
     */
    modifier onlyActive {
        require(isActive == true);
        _;
    }

    constructor(address _priceFeed) public {
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeed);
        fee = 100;
    }

    /**
     * @dev lets admin open the pool
     */
    function openPredictionPool() public onlyOwner {
        isActive = true;
    }

    /**
     * @dev lets admin close the pool
     */
    function closePredictionPool() public onlyOwner {
        isActive = false;
    }

    /**
     * @dev sets pool fee that's deducted from final settlement
     */
    function setPoolFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    /**
     * @dev lets any user create a prediction instance (payable)
     */
    function createInstance(uint256 _commitment, uint256 _start, uint256 _lock, uint256 _end) public payable onlyActive {
        require(msg.value >= 0.005 ether, "You must spend 0.005 ETH to create a custom instance");
        predictionSpec memory newPredictionSpec = predictionSpec({
        commitment : _commitment,
        startStamp : _start,
        lockStamp : _lock,
        endStamp : _end,
        settlement : false,
        winnersCount : 0,
        instanceValue : 0,
        closingPrice : 0,
        creator : msg.sender
        });
        predictionsSpec.push(newPredictionSpec);
    }

    /**
     * @dev registers prediction of users
     */
    function registerPrediction(uint256 _instance, uint256 _prediction) public payable onlyActive {
        require(block.timestamp >= predictionsSpec[_instance].startStamp, "Prediction has not started yet for this instance!");
        require(block.timestamp <= predictionsSpec[_instance].lockStamp, "Prediction has ended for this instance!");
        require(msg.value == predictionsSpec[_instance].commitment, "You must commit the exact ETH amount to enter!");
        predictions[_instance][msg.sender] = _prediction;
        if (hasParticipated[_instance][msg.sender] != true) {
            participants[_instance].push(msg.sender);
        } else {
            hasParticipated[_instance][msg.sender] = true;
        }
        predictionsSpec[_instance].instanceValue += msg.value;
    }

    /**
     * @dev gets ETH/USD price from Chainlink price oracle
     */
    function getClosingPrice() internal returns (uint256) {
        (, int256 price,,,) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(10 ** 18 / price);
        return adjustedPrice;
    }

    /**
     * @dev settles any instance if timestamp respected
     */
    function settleInstance(uint256 _instance) public onlyActive {
        require(block.timestamp >= predictionsSpec[_instance].endStamp, "Prediction has not ended yet for this instance!");
        require(predictionsSpec[_instance].settlement == false, "This instance has already been settled!");
        uint256 closingPrice = getClosingPrice();
        predictionsSpec[_instance].closingPrice = closingPrice;
        uint256 closestPrediction = getClosestPrediction(_instance, closingPrice);
        getWinnersFromClosest(_instance, closestPrediction);
        predictionsSpec[_instance].settlement = true;
        compensateCaller(_instance, msg.sender);
    }

    /**
     * @dev gets closest prediction from all participants based on price oracle
     */
    function getClosestPrediction(uint256 _instance, uint256 _closingPrice) internal returns (uint256) {
        require(participants[_instance].length > 0, "Looks no one has joined the instance ...");
        uint256 maxDelta = type(uint256).max;
        uint256 absoluteDelta;
        uint256 closestPrediction = maxDelta;

        for (uint256 participantIndex = 0; participantIndex < participants[_instance].length; participantIndex++) {

            address participantAddress = participants[_instance][participantIndex];
            uint256 participantPrediction = predictions[_instance][participantAddress];
            int256 delta = (int(participantPrediction) - int(_closingPrice));

            if (delta >= 0) {
                absoluteDelta = uint(delta);
            } else {
                absoluteDelta = uint(- 1 * delta);
            }

            if (absoluteDelta < maxDelta) {
                closestPrediction = participantPrediction;
                maxDelta = absoluteDelta;
            }
        }

        return closestPrediction;

    }

    /**
     * @dev gets winner(s) based on closestPrediction
     */
    function getWinnersFromClosest(uint256 _instance, uint256 _closestPrediction) internal {

        for (uint256 participantIndex = 0; participantIndex < participants[_instance].length; participantIndex++) {
            address participantAddress = participants[_instance][participantIndex];
            uint256 participantPrediction = predictions[_instance][participantAddress];
            if (participantPrediction == _closestPrediction) {
                winners[_instance][participantAddress] = true;
                predictionsSpec[_instance].winnersCount += 1;
            }
        }
    }

    /**
     * @dev incentives function caller
     */
    function compensateCaller(uint256 _instance, address _caller) internal {
        payable(_caller).transfer(0.005 ether);
    }

    /**
     * @dev pays winners if they claim their gain
     */
    function claimReward(uint256 _instance) public {
        require(block.timestamp >= predictionsSpec[_instance].endStamp, "Rewards cannot be claimed yet!");
        require(winners[_instance][msg.sender] == true, "Looks you are not a winner of this instance!");
        uint256 valueToBeShared = (10000 - fee) * predictionsSpec[_instance].instanceValue / 10000;
        uint256 amountPerAddress = valueToBeShared / predictionsSpec[_instance].winnersCount;
        payable(msg.sender).transfer(amountPerAddress);
        winners[_instance][msg.sender] = false;
    }


    function instanceView(uint256 _instance) public view returns (predictionSpec memory) {
        return predictionsSpec[_instance];
    }

    function instanceViewAll() public view returns (predictionSpec[] memory) {
        return predictionsSpec;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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