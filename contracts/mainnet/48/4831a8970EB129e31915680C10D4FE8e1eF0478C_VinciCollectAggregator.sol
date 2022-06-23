// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/SimpleReadAccessController.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {SignedSafeMath} from '../dependencies/openzeppelin/contracts/utils/math/SignedSafeMath.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/utils/math/SafeMath.sol';
import "./VinciCollectPriceCumulative.sol";

contract CollectAggregator is AggregatorV2V3Interface, SimpleReadAccessController {
    struct Round {
      int256 answer;
      uint64 startedAt;
      uint64 updatedAt;
      uint32 answeredInRound;
    }

    uint32 internal latestRoundId;
    mapping(uint32 => Round) internal rounds;

    uint8 public override decimals;
    string public override description;

    int256 immutable public minSubmissionValue;
    int256 immutable public maxSubmissionValue;

    uint256 constant public override version = 3;

    uint32 constant private ROUND_MAX = 2**32-1;
    // An error specific to the Aggregator V3 Interface, to prevent possible
    // confusion around accidentally reading unset values as reported values.
    string constant private V3_NO_DATA_ERROR = "No data present";

    address private _operator;
    address private _collector;
    uint64 private timeInterval;

    int256 priceCumulative;
    uint64 latestTimeAt;

    /**
    * @notice set up the aggregator with initial configuration
    * @param _timeout is the number of seconds after the previous round that are
    * allowed to lapse before allowing an oracle to skip an unfinished round
    * @param _minSubmissionValue is an immutable check for a lower bound of what
    * submission values are accepted from an oracle
    * @param _maxSubmissionValue is an immutable check for an upper bound of what
    * submission values are accepted from an oracle
    * @param _decimals represents the number of decimals to offset the answer by
    * @param _description a short description of what is being reported
    */
    constructor(
      uint32 _timeout,
      int256 _minSubmissionValue,
      int256 _maxSubmissionValue,
      uint8 _decimals,
      uint64 _timeInterval,
      string memory _description
    ) {
      minSubmissionValue = _minSubmissionValue;
      maxSubmissionValue = _maxSubmissionValue;
      decimals = _decimals;
      description = _description;
      timeInterval = _timeInterval;
      rounds[0].updatedAt = uint64(block.timestamp - (uint256(_timeout)));
    }

    function computeAmountOut() private view returns (int256 amountOut, int256 currentPriceCumulative, uint64 currentTime) {
      require(_collector != address(0), "Please set the collector first");

      (currentPriceCumulative, currentTime) = CollectInterface(_collector).getPriceCumulative();
      int256 timeElapsed = int256(SafeMath.sub(currentTime, latestTimeAt));
      int256 priceDifference = SignedSafeMath.sub(currentPriceCumulative, priceCumulative);
      amountOut = SignedSafeMath.div(priceDifference, timeElapsed);
    }

    /**
      * Receive the response in the form of uint256
      */ 
    function submit(int256 _data) public onlyOwner
    {
      require(_data >= minSubmissionValue, "value below minSubmissionValue");
      require(_data <= maxSubmissionValue, "value above maxSubmissionValue");

      uint64 startedAt = uint64(block.timestamp); 
      updateRoundAnswer(latestRoundId + 1, startedAt, _data);
    }

    function submitWithTWAP() public
    {
      int256 data;
      (data, priceCumulative, latestTimeAt)= computeAmountOut();
      updateRoundAnswer(latestRoundId + 1, uint64(block.timestamp), data);
    }

    function setCollector(address _address) public onlyOwner {
      _collector = _address;
    }

    function getCollector() public view returns (address) {
      return _collector;
    }

    function setTimesInterval(uint64 _timeInterval) public onlyOwner {
      timeInterval = _timeInterval;
    }

    function getTimesInterval() public view returns (uint64) {
      return timeInterval;
    }

    /**
    * @notice get the most recently reported answer
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestAnswer()
      public
      view
      virtual
      override
      returns (int256)
    {
      return rounds[latestRoundId].answer;
    }

    /**
    * @notice get the most recent updated at timestamp
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestTimestamp()
      public
      view
      virtual
      override
      returns (uint256)
    {
      return rounds[latestRoundId].updatedAt;
    }

    /**
    * @notice get the ID of the last updated round
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestRound()
      public
      view
      virtual
      override
      returns (uint256)
    {
      return latestRoundId;
    }

    /**
    * @notice get past rounds answers
    * @param _roundId the round number to retrieve the answer for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getAnswer(uint256 _roundId)
      public
      view
      virtual
      override
      returns (int256)
    {
      if (validRoundId(_roundId)) {
        return rounds[uint32(_roundId)].answer;
      }
      return 0;
    }

    /**
    * @notice get timestamp when an answer was last updated
    * @param _roundId the round number to retrieve the updated timestamp for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getTimestamp(uint256 _roundId)
      public
      view
      virtual
      override
      returns (uint256)
    {
      if (validRoundId(_roundId)) {
        return rounds[uint32(_roundId)].updatedAt;
      }
      return 0;
    }

    /**
    * @notice get data about a round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values.
    * @param _roundId the round ID to retrieve the round data for
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answeredInRound is equal to roundId when the round didn't time out
    * and was completed regularly.
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet received
    * maxSubmissions) answer and updatedAt may change between queries.
    */
    function getRoundData(uint80 _roundId)
      public
      view
      virtual
      override
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      )
    {
      Round memory r = rounds[uint32(_roundId)];

      require(r.answeredInRound > 0 && validRoundId(_roundId), V3_NO_DATA_ERROR);

      return (
        _roundId,
        r.answer,
        r.startedAt,
        r.updatedAt,
        r.answeredInRound
      );
    }

    /**
    * @notice get data about the latest round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values. Consumers are encouraged to
    * use this more fully featured method over the "legacy" latestRound/
    * latestAnswer/latestTimestamp functions. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values.
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answeredInRound is equal to roundId when the round didn't time
    * out and was completed regularly.
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
    * received maxSubmissions) answer and updatedAt may change between queries.
    */
    function latestRoundData()
      public
      view
      virtual
      override
      returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
    {
      return getRoundData(latestRoundId);
    }

    function updateRoundAnswer(uint32 _roundId, uint64 _startedAt, int256 _newAnswer)
      internal
    {
      require(timeInterval <= SafeMath.sub(_startedAt, latestTimestamp()), "No repeated feeding during the minimum interval");

      rounds[_roundId].answer = _newAnswer;
      rounds[_roundId].startedAt = _startedAt;
      rounds[_roundId].updatedAt = uint64(block.timestamp);
      rounds[_roundId].answeredInRound = _roundId;
      latestRoundId = _roundId;

      emit AnswerUpdated(_newAnswer, _roundId, block.timestamp);
    }

    function validRoundId(uint256 _roundId)
      private
      pure
      returns (bool)
    {
      return _roundId <= ROUND_MAX;
    }
}


contract VinciCollectAggregator is CollectAggregator {
    /**
    * @notice set up the aggregator with initial configuration
    * @param _timeout is the number of seconds after the previous round that are
    * allowed to lapse before allowing an oracle to skip an unfinished round
    * @param _minSubmissionValue is an immutable check for a lower bound of what
    * submission values are accepted from an oracle
    * @param _maxSubmissionValue is an immutable check for an upper bound of what
    * submission values are accepted from an oracle
    * @param _decimals represents the number of decimals to offset the answer by
    * @param _description a short description of what is being reported
    */
    constructor(
      uint32 _timeout,
      int256 _minSubmissionValue,
      int256 _maxSubmissionValue,
      uint8 _decimals,
      uint64 _timeInterval,
      string memory _description
    ) CollectAggregator(
      _timeout,
      _minSubmissionValue,
      _maxSubmissionValue,
      _decimals,
      _timeInterval,
      _description
    ){}

    /**
    * @notice get data about a round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values.
    * @param _roundId the round ID to retrieve the round data for
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answerInRound is equal to roundId when the round didn't time out
    * and was completed regularly.
    * @dev overridden funcion to add the checkAccess() modifier
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
    * received maxSubmissions) answer and updatedAt may change between queries.
    */
    function getRoundData(uint80 _roundId)
      public
      view
      override
      checkAccess()
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      )
    {
      return super.getRoundData(_roundId);
    }

    /**
    * @notice get data about the latest round. Consumers are encouraged to check
    * that they're receiving fresh data by inspecting the updatedAt and
    * answeredInRound return values. Consumers are encouraged to
    * use this more fully featured method over the "legacy" latestAnswer
    * functions. Consumers are encouraged to check that they're receiving fresh
    * data by inspecting the updatedAt and answeredInRound return values.
    * @return roundId is the round ID for which data was retrieved
    * @return answer is the answer for the given round
    * @return startedAt is the timestamp when the round was started. This is 0
    * if the round hasn't been started yet.
    * @return updatedAt is the timestamp when the round last was updated (i.e.
    * answer was last computed)
    * @return answeredInRound is the round ID of the round in which the answer
    * was computed. answeredInRound may be smaller than roundId when the round
    * timed out. answerInRound is equal to roundId when the round didn't time out
    * and was completed regularly.
    * @dev overridden funcion to add the checkAccess() modifier
    * @dev Note that for in-progress rounds (i.e. rounds that haven't yet
    * received maxSubmissions) answer and updatedAt may change between queries.
    */
    function latestRoundData()
      public
      view
      override
      checkAccess()
      returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
      )
    {
      return super.latestRoundData();
    }

    /**
    * @notice get the most recently reported answer
    * @dev overridden funcion to add the checkAccess() modifier
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestAnswer()
      public
      view
      override
      checkAccess()
      returns (int256)
    {
      return super.latestAnswer();
    }

    /**
    * @notice get the most recently reported round ID
    * @dev overridden funcion to add the checkAccess() modifier
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestRound()
      public
      view
      override
      checkAccess()
      returns (uint256)
    {
      return super.latestRound();
    }

    /**
    * @notice get the most recent updated at timestamp
    * @dev overridden funcion to add the checkAccess() modifier
    *
    * @dev #[deprecated] Use latestRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended latestRoundData
    * instead which includes better verification information.
    */
    function latestTimestamp()
      public
      view
      override
      checkAccess()
      returns (uint256)
    {

      return super.latestTimestamp();
    }

    /**
    * @notice get past rounds answers
    * @dev overridden funcion to add the checkAccess() modifier
    * @param _roundId the round number to retrieve the answer for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getAnswer(uint256 _roundId)
      public
      view
      override
      checkAccess()
      returns (int256)
    {
      return super.getAnswer(_roundId);
    }

    /**
    * @notice get timestamp when an answer was last updated
    * @dev overridden funcion to add the checkAccess() modifier
    * @param _roundId the round number to retrieve the updated timestamp for
    *
    * @dev #[deprecated] Use getRoundData instead. This does not error if no
    * answer has been reached, it will simply return 0. Either wait to point to
    * an already answered Aggregator or use the recommended getRoundData
    * instead which includes better verification information.
    */
    function getTimestamp(uint256 _roundId)
      public
      view
      override
      checkAccess()
      returns (uint256)
    {
      return super.getTimestamp(_roundId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleWriteAccessController.sol";

/**
 * @title SimpleReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that off-chain actors can always read
 * any contract storage regardless of on-chain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev SimpleReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * SimpleWriteAccessController for that.
 */
contract SimpleReadAccessController is SimpleWriteAccessController {
  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(address _user, bytes memory _calldata) public view virtual override returns (bool) {
    return super.hasAccess(_user, _calldata) || _user == tx.origin;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {SignedSafeMath} from '../dependencies/openzeppelin/contracts/utils/math/SignedSafeMath.sol';
import {SafeMath} from '../dependencies/openzeppelin/contracts/utils/math/SafeMath.sol';
import {Operatable} from './Operatable.sol';
import {CollectInterface} from '../interface/CollectInterface.sol';

contract VinciCollectPriceCumulative is CollectInterface, Operatable {
    
    int256 priceCumulative;
    uint64 latestUpdatedAt;

    uint8 public decimals;
    string public description;

    int256 immutable public minSubmissionValue;
    int256 immutable public maxSubmissionValue;

    uint256 constant public version = 1;
    address private _operator;

    /**
    * @notice set up the aggregator with initial configuration
    * @param _timeout is the number of seconds after the previous round that are
    * allowed to lapse before allowing an oracle to skip an unfinished round
    * @param _minSubmissionValue is an immutable check for a lower bound of what
    * submission values are accepted from an oracle
    * @param _maxSubmissionValue is an immutable check for an upper bound of what
    * submission values are accepted from an oracle
    * @param _decimals represents the number of decimals to offset the answer by
    * @param _description a short description of what is being reported
    */
    constructor(
      uint32 _timeout,
      int256 _minSubmissionValue,
      int256 _maxSubmissionValue,
      uint8 _decimals,
      string memory _description
    ) {
      minSubmissionValue = _minSubmissionValue;
      maxSubmissionValue = _maxSubmissionValue;
      decimals = _decimals;
      description = _description;
      latestUpdatedAt = uint64(block.timestamp - (uint256(_timeout)));
    }

    function computeAmountOut(int256 _price, uint64 _startedAt) internal view returns (int256 priceCumulativeOut) {
      int256 timeElapsed = int256(SafeMath.sub(_startedAt, latestUpdatedAt));
      priceCumulativeOut = SignedSafeMath.mul(_price, timeElapsed);
      priceCumulativeOut = SignedSafeMath.add(priceCumulativeOut, priceCumulative);
    }

    /**
      * Receive the response in the form of uint256
      */ 
    function updatePriceCumulative(int256 _data) public onlyOperator {
      require(_data >= minSubmissionValue, "value below minSubmissionValue");
      require(_data <= maxSubmissionValue, "value above maxSubmissionValue");

      uint64 startedAt = uint64(block.timestamp);
      priceCumulative = computeAmountOut(_data, startedAt);
      latestUpdatedAt = startedAt;
    }

    function getPriceCumulative() public view override returns (int256, uint64) {
      return (priceCumulative, latestUpdatedAt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";
import "./interfaces/AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, ConfirmedOwner {
  bool public checkEnabled;
  mapping(address => bool) internal accessList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  constructor() ConfirmedOwner(msg.sender) {
    checkEnabled = true;
  }

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(address _user, bytes memory) public view virtual override returns (bool) {
    return accessList[_user] || !checkEnabled;
  }

  /**
   * @notice Adds an address to the access list
   * @param _user The address to add
   */
  function addAccess(address _user) external onlyOwner {
    if (!accessList[_user]) {
      accessList[_user] = true;

      emit AddedAccess(_user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param _user The address to remove
   */
  function removeAccess(address _user) external onlyOwner {
    if (accessList[_user]) {
      accessList[_user] = false;

      emit RemovedAccess(_user);
    }
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck() external onlyOwner {
    if (!checkEnabled) {
      checkEnabled = true;

      emit CheckAccessEnabled();
    }
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck() external onlyOwner {
    if (checkEnabled) {
      checkEnabled = false;

      emit CheckAccessDisabled();
    }
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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
// OpenZeppelin Contracts v4.4.0 (access/Operatable.sol)

pragma solidity ^0.8.0;

import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an operator) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the operator account will be the one that deploys the contract. This
 * can later be changed with {transferOperationRight}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOperator`, which can be applied to your functions to restrict their use to
 * the operator.
 */
abstract contract Operatable is Ownable {
    address private _operator;

    event OperationRightTransferred(address indexed previousOperator, address indexed newOperator);

    /**
     * @dev Initializes the contract setting the deployer as the initial operator.
     */
    constructor() Ownable () {
        _transferOperationRight(_msgSender());
    }

    /**
     * @dev Returns the address of the current operator.
     */
    function operator() public view virtual returns (address) {
        return _operator;
    }

    /**
     * @dev Throws if called by any account other than the operator.
     */
    modifier onlyOperator() {
        require(operator() == _msgSender(), "Operatable: caller is not the operator");
        _;
    }

    /**
     * @dev Leaves the contract without operator. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing operation Rights will leave the contract without an operator,
     * thereby removing any functionality that is only available to the operator.
     */
    function renounceOperationRight() public virtual onlyOwner {
        _transferOperationRight(address(0));
    }

    /**
     * @dev Transfers operation right of the contract to a new account (`newOperator`).
     * Can only be called by the current owner.
     */
    function transferOperationRight(address newOperator) public virtual onlyOwner {
        require(newOperator != address(0), "Operatable: new owner is the zero address");
        _transferOperationRight(newOperator);
    }

    /**
     * @dev Transfers operation right of the contract to a new account (`newOperator`).
     * Internal function without access restriction.
     */
    function _transferOperationRight(address newOperator) internal virtual {
        address oldOperator = _operator;
        _operator = newOperator;
        emit OperationRightTransferred(oldOperator, newOperator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CollectInterface {
  function getPriceCumulative() external view returns (int256, uint64);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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