// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./UmpireModel.sol";
import "./UmpireFormulaResolver.sol";
import "./UmpireActionInterface.sol";
import "./AbstractUmpireFormulaResolver.sol";

// @todo natspec
contract UmpireRegistry is KeeperCompatibleInterface, Ownable {
    uint public s_counterJobs = 0;
    uint8 public s_minimumMinutesBeforeTimeout = 2;
    uint8 public s_minimumMinutesBetweenActivationAndTimeout = 1;
    uint8 public s_minimumMinutesActivationOffset = 1;
    mapping(uint => address) public s_inputFeeds;
    mapping(uint => UmpireJob) public s_jobs;
    mapping(address => uint[]) public s_jobsByOwner;
    AbstractUmpireFormulaResolver public i_resolver;

    event UmpireJobCreated(uint indexed jobId, address indexed jobOwner, address action);
    event UmpireJobCompleted(uint indexed jobId, address indexed jobOwner, address action, UmpireJobStatus jobStatus);

    constructor (address _resolver) {
        i_resolver = AbstractUmpireFormulaResolver(_resolver);
    }

    function createJobFromNodes(
        string memory _name,
        PostfixNode[] memory _postfixNodesLeft,
        UmpireComparator _comparator,
        PostfixNode[] memory _postfixNodesRight,
        address[] memory _dataFeeds,
        uint _activationDate,
        uint _timeoutDate,
        address _action
    ) external returns (uint jobId) {
        require(_timeoutDate > block.timestamp + (s_minimumMinutesBeforeTimeout * 60), "Timeout date farther into the future required");
        require(_timeoutDate >= _activationDate + (s_minimumMinutesBetweenActivationAndTimeout * 60), "A longer evaluation period required");
        require(Address.isContract(_action), "Action must be a contract");
        if (_activationDate > 0) {
            require(_activationDate >= block.timestamp + (s_minimumMinutesActivationOffset * 60), "Activation must be 0 or in the future");
        }
        jobId = s_counterJobs;
        s_counterJobs = s_counterJobs + 1;

        s_jobs[jobId].id = jobId;
        s_jobs[jobId].jobName = _name;
        s_jobs[jobId].owner = msg.sender;
        s_jobs[jobId].jobStatus = UmpireJobStatus.NEW;
        s_jobs[jobId].comparator = _comparator;
        s_jobs[jobId].createdAt = block.timestamp;
        s_jobs[jobId].activationDate = _activationDate;
        s_jobs[jobId].timeoutDate = _timeoutDate;
        s_jobs[jobId].action = _action;
        s_jobs[jobId].dataFeeds = _dataFeeds;

        for (uint i = 0; i < _postfixNodesLeft.length; i++) {
            s_jobs[jobId].formulaLeft.push(_postfixNodesLeft[i]);
        }

        for (uint i = 0; i < _postfixNodesRight.length; i++) {
            s_jobs[jobId].formulaRight.push(_postfixNodesRight[i]);
        }

        s_jobsByOwner[msg.sender].push(jobId);

        emit UmpireJobCreated(jobId, msg.sender, _action);

        return jobId;
    }

    function evaluateJob(uint _jobId) public view returns (bool, int, int) {
        if (_jobId > s_counterJobs) {
            return (false, 0, 0);
        }

        int[] memory variables = new int[](s_jobs[_jobId].dataFeeds.length);
        for (uint i; i < s_jobs[_jobId].dataFeeds.length; i++) {
            variables[i] = i_resolver.getFeedValue(s_jobs[_jobId].dataFeeds[i]);
        }

        int leftValue;
        int rightValue;
        bool reverted = false;
        try i_resolver.resolve(s_jobs[_jobId].formulaLeft, variables) returns (int _leftValue) {
            leftValue = _leftValue;
        } catch Error(string memory /*_err*/) {
            reverted = true;
        } catch (bytes memory /*_err*/) {
            reverted = true;
        }

        try i_resolver.resolve(s_jobs[_jobId].formulaRight, variables) returns (int _rightValue) {
            rightValue = _rightValue;
        } catch Error(string memory /*_err*/) {
            reverted = true;
        } catch (bytes memory /*_err*/) {
            reverted = true;
        }

        if (reverted) {
            return (false, 0, 0);
        }

        if (s_jobs[_jobId].comparator == UmpireComparator.EQUAL) {
            return (leftValue == rightValue, leftValue, rightValue);
        } else if (s_jobs[_jobId].comparator == UmpireComparator.NOT_EQUAL) {
            return (leftValue != rightValue, leftValue, rightValue);
        } else if (s_jobs[_jobId].comparator == UmpireComparator.GREATER_THAN) {
            return (leftValue > rightValue, leftValue, rightValue);
        } else if (s_jobs[_jobId].comparator == UmpireComparator.GREATER_THAN_EQUAL) {
            return (leftValue >= rightValue, leftValue, rightValue);
        } else if (s_jobs[_jobId].comparator == UmpireComparator.LESS_THAN) {
            return (leftValue < rightValue, leftValue, rightValue);
        } else if (s_jobs[_jobId].comparator == UmpireComparator.LESS_THAN_EQUAL) {
            return (leftValue <= rightValue, leftValue, rightValue);
        } else {
            revert("Unknown comparator");
        }
    }

    /**
     * @notice Checks if the contract requires work to be done
     */
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
        // @todo optimization: run performUpkeep with jobIds in checkData, so this should only return jobIds that require upkeep
        for (uint i; i < s_counterJobs; i++) {
            if (s_jobs[i].jobStatus != UmpireJobStatus.NEW) {
                continue;
            }

            if (block.timestamp > s_jobs[i].timeoutDate) {
                upkeepNeeded = true;
                break;
            }

            if (block.timestamp >= s_jobs[i].activationDate) {
                (bool evaluationResult,,) = evaluateJob(i);
                if (evaluationResult == true) {
                    upkeepNeeded = true;
                    break;
                }
            }
        }

        return (upkeepNeeded, "");
    }

    /**
     * @notice Performs the work on the contract, if instructed by :checkUpkeep():
     */
    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        // @todo evaluate each processed job again, revert if not needed for some/all
        require(upkeepNeeded, "Upkeep not needed");

        // @todo optimization: run only for each job from performData
        for (uint i; i < s_counterJobs; i++) {
            if (s_jobs[i].jobStatus != UmpireJobStatus.NEW) {
                continue;
            }

            if (block.timestamp > s_jobs[i].timeoutDate) {
                s_jobs[i].jobStatus = UmpireJobStatus.NEGATIVE;
                try UmpireActionInterface(s_jobs[i].action).negativeAction() {
                    emit UmpireJobCompleted(i, s_jobs[i].owner, s_jobs[i].action, UmpireJobStatus.NEGATIVE);
                } catch Error(string memory /*_err*/) {
                    s_jobs[i].jobStatus = UmpireJobStatus.REVERTED;
                } catch (bytes memory /*_err*/) {
                    s_jobs[i].jobStatus = UmpireJobStatus.REVERTED;
                }
                continue;
            }

            if (block.timestamp >= s_jobs[i].activationDate) {
                (
                bool evaluationResult,
                int leftValue,
                int rightValue
                ) = evaluateJob(i);
                if (evaluationResult == true) {
                    s_jobs[i].jobStatus = UmpireJobStatus.POSITIVE;
                    s_jobs[i].leftValue = leftValue;
                    s_jobs[i].rightValue = rightValue;
                    try UmpireActionInterface(s_jobs[i].action).positiveAction() {
                        emit UmpireJobCompleted(i, s_jobs[i].owner, s_jobs[i].action, UmpireJobStatus.POSITIVE);
                    } catch Error(string memory /*_err*/) {
                        s_jobs[i].jobStatus = UmpireJobStatus.REVERTED;
                    } catch (bytes memory /*_err*/) {
                        s_jobs[i].jobStatus = UmpireJobStatus.REVERTED;
                    }
                    continue;
                }
            }
        }
    }

    function updateTimeConstraints(
        uint8 _minimumMinutesBeforeTimeout,
        uint8 _minimumMinutesBetweenActivationAndTimeout,
        uint8 _minimumMinutesActivationOffset
    ) public onlyOwner {
        s_minimumMinutesBeforeTimeout = _minimumMinutesBeforeTimeout;
        s_minimumMinutesBetweenActivationAndTimeout = _minimumMinutesBetweenActivationAndTimeout;
        s_minimumMinutesActivationOffset = _minimumMinutesActivationOffset;
    }

    function getJobsByOwner(address _owner) public view returns (UmpireJob[] memory) {
        uint myJobsCount = s_jobsByOwner[_owner].length;
        if (myJobsCount == 0) {
            revert("You have no jobs");
        }

        UmpireJob[] memory jobs = new UmpireJob[](myJobsCount);

        for (uint i; i < myJobsCount; i++) {
            jobs[i] = s_jobs[s_jobsByOwner[_owner][i]];
        }

        return jobs;
    }

    function getMyJobs() public view returns (UmpireJob[] memory) {
        return getJobsByOwner(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum PostfixNodeType {
    VALUE,
    VARIABLE,
    OPERATOR
}

enum PostfixNodeOperator {
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    POW,
    LOG10,
    LOG2,
    LN,
    SQRT
}

struct PostfixNode {
    int value;
    PostfixNodeType nodeType;
    PostfixNodeOperator operator;
    uint8 variableIndex;
}

enum UmpireJobStatus {
    NEW,
    REVERTED,
    NEGATIVE,
    POSITIVE
}

enum UmpireComparator {
    EQUAL,
    NOT_EQUAL,
    GREATER_THAN,
    GREATER_THAN_EQUAL,
    LESS_THAN,
    LESS_THAN_EQUAL
}

struct UmpireJob {
    uint id;
    address owner;
    UmpireJobStatus jobStatus;
    PostfixNode[] formulaLeft;
    UmpireComparator comparator;
    PostfixNode[] formulaRight;
    address[] dataFeeds;
    uint createdAt;
    uint timeoutDate;
    uint activationDate;
    address action;
    int leftValue;
    int rightValue;
    string jobName;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UmpireModel.sol";
import "./AbstractUmpireFormulaResolver.sol";

// @todo natspec
contract UmpireFormulaResolver is AbstractUmpireFormulaResolver {
    function resolve(PostfixNode[] memory _postfixNodes, int[] memory _variables) public pure override returns (int) {
        require(_postfixNodes.length > 0, "Provide nodes");

        int[] memory stack = new int[](256);
        uint8 stackHeight;
        for (uint idx = 0; idx < _postfixNodes.length; idx++) {
            if (_postfixNodes[idx].nodeType == PostfixNodeType.VARIABLE) {
                _postfixNodes[idx].nodeType = PostfixNodeType.VALUE;
                _postfixNodes[idx].value = _variables[_postfixNodes[idx].variableIndex];
            }

            if (_postfixNodes[idx].nodeType == PostfixNodeType.VALUE) {
                stack[stackHeight] = _postfixNodes[idx].value;
                stackHeight++;
                continue;
            }

            if (_postfixNodes[idx].nodeType != PostfixNodeType.OPERATOR) {
                revert("Broken node");
            }

            if (_postfixNodes[idx].operator == PostfixNodeOperator.ADD) {
                if (stackHeight < 2) {
                    revert("Broken stack");
                }
                int result = stack[stackHeight - 2] + stack[stackHeight - 1];
                stack[stackHeight - 2] = result;
                stackHeight--;
            } else if (_postfixNodes[idx].operator == PostfixNodeOperator.SUB) {
                if (stackHeight < 2) {
                    revert("Broken stack");
                }
                int result = stack[stackHeight - 2] - stack[stackHeight - 1];
                stack[stackHeight - 2] = result;
                stackHeight--;
            } else if (_postfixNodes[idx].operator == PostfixNodeOperator.MUL) {
                if (stackHeight < 2) {
                    revert("Broken stack");
                }
                int result = stack[stackHeight - 2] * stack[stackHeight - 1];
                stack[stackHeight - 2] = result;
                stackHeight--;
            } else if (_postfixNodes[idx].operator == PostfixNodeOperator.DIV) {
                if (stackHeight < 2) {
                    revert("Broken stack");
                }
                if (stack[stackHeight - 1] == 0) {
                    revert("Division by 0");
                }
                int result = stack[stackHeight - 2] / stack[stackHeight - 1];
                stack[stackHeight - 2] = result;
                stackHeight--;
            } else {
                revert("Unknown operator");
            }
        }

        if (stackHeight != 1) {
            revert("Broken stack");
        }

        return stack[0];
    }

    // @dev supports up to 10 values and 10 variables
    // @dev formula format is postfix, variable and value indexes prefixed with X and V
    // @dev example formula: V0V1+
    function stringToNodes(string memory _formula, int[] memory _values) public pure returns (PostfixNode[] memory) {
        bytes memory chars = bytes(_formula);
        uint symbolCount = chars.length;
        for (uint idx = 0; idx < chars.length; idx++) {
            if (chars[idx] == 'V' || chars[idx] == 'X') {
                symbolCount--;
            }
        }

        bool isValue = false;
        bool isVariable = false;
        PostfixNode[] memory nodes = new PostfixNode[](symbolCount);
        uint8 nodeIdx = 0;

        for (uint idx = 0; idx < chars.length; idx++) {
            if (chars[idx] == 'V') {
                isValue = true;
                continue;
            }

            if (chars[idx] == 'X') {
                isVariable = true;
                continue;
            }

            if (isValue) {
                isValue = false;
                nodes[nodeIdx] = PostfixNode(_values[uint8(chars[idx]) - 48], PostfixNodeType.VALUE, PostfixNodeOperator.ADD, 0);
                nodeIdx++;
            } else if (isVariable) {
                isVariable = false;
                nodes[nodeIdx] = PostfixNode(0, PostfixNodeType.VARIABLE, PostfixNodeOperator.ADD, uint8(chars[idx]) - 48);
                nodeIdx++;
            } else if (chars[idx] == '+') {
                nodes[nodeIdx] = PostfixNode(0, PostfixNodeType.OPERATOR, PostfixNodeOperator.ADD, 0);
                nodeIdx++;
            } else {
                revert("Not implemented");
            }
        }

        return nodes;
    }

    function resolveFormula(string memory _formula, int[] memory _values, int[] memory _variables) public pure returns (int) {
        return resolve(stringToNodes(_formula, _values), _variables);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface UmpireActionInterface {
    function positiveAction() external;

    function negativeAction() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./UmpireModel.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract AbstractUmpireFormulaResolver {
    function resolve(PostfixNode[] memory _postfixNodes, int[] memory _variables) public pure virtual returns (int);
    function getFeedValue(address _priceFeed) public view virtual returns (int256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
        (
        ,
        int256 price,
        ,
        ,
        ) = priceFeed.latestRoundData();
        return price;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

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