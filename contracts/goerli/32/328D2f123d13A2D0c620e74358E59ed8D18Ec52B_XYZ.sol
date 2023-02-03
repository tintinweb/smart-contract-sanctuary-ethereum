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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
  DESIGN NOTES:
  Token ids are a concatenation of:
 * tasker: hex address of the creator of the token. 160 bits
 * index: Index for this token (the regular ID), up to 2^56 - 1. 56 bits

*/

/**
 * @title TaskIdentifiers
 * support for authentication and metadata for task ids
 */
library CompleteRequestIdentifiers {
    using SafeMath for uint256;

    uint8 constant ADDRESS_BITS = 160;
    uint8 constant TASKID_BITS = 56;
    uint8 constant REQUEST_TIME_BITS = 40;

    uint256 constant TASKID_BITS_MASK = (uint256(1) << TASKID_BITS) - 1;

    uint256 constant ASKTIME_MASK = (uint256(1) << REQUEST_TIME_BITS) - 1;

    function taskId(uint256 _id) internal pure returns (uint256) {
        return (_id >> REQUEST_TIME_BITS) & TASKID_BITS_MASK;
    }

    function requestCompleteTasker(uint256 _id) internal pure returns (address) {
        return address(uint160(_id >> (TASKID_BITS + REQUEST_TIME_BITS)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./CompleteRequestIdentifiers.sol";

contract XYZ is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    using CompleteRequestIdentifiers for uint256;

    Counters.Counter public _taskIdCounter;

    IERC20 usdt;

    uint256 public usdtBalance;

    event CreateTask(address principal, uint256 taskId, Task);
    event CompletedTask(address principal, address tasker, Task);
    event DeleteTask(address principal, uint256 taskId);
    event CompleteTaskRequestEvent(address tasker, address principal, uint256 taskId, uint256 requestId, Task);

    struct Task {
        uint256 reward;
        uint256 expiredTime;
        uint256 requestQuantity;
        address principal;
        string taskName;
        string description;
    }

    struct CompleteTaskRequest {
        uint256 taskId;
        address tasker;
        bool isAccepted;
        string proofLink;
    }
    //taskId => Task
    mapping(uint256 => Task) allTasks;
    //requestId => CompleteTaskRequest
    mapping(uint256 => CompleteTaskRequest) completeTaskRequests;

    constructor(address _usdtAddress) {
        usdt = IERC20(_usdtAddress);
    }

    /***************************
     * Principal function here *
     ***************************/

    /**
     * @dev createTask : Principal can create Task.
     * @param _taskName : task name
     * @param _description : description for this task.
     * @param _reward : amount of task reward
     * @param _expiredTime : task expired time, the task can be deleted when it was expired.
     */
    function createTask(string calldata _taskName, string calldata _description, uint256 _reward, uint256 _expiredTime) external {
        require(tx.origin == msg.sender, "EOA account only.");
        require(_expiredTime > block.timestamp, "expiredTime incorrect.");
        uint256 taskId = _taskIdCounter.current();
        _taskIdCounter.increment();
        Task storage task = allTasks[taskId];
        task.reward = _reward;
        task.principal = msg.sender;
        task.taskName = _taskName;
        task.description = _description;
        task.expiredTime = _expiredTime;
        emit CreateTask(msg.sender, taskId, task);
        usdtBalance += _reward;
        usdt.transferFrom(msg.sender, address(this), _reward);
    }

    /**
     * @dev queryTask : for front-end query Task.
     * @param _taskIds : tasks Id array.
     */
    function queryTask(uint256[] memory _taskIds) external view returns (Task[] memory) {
        uint256 taskIdsLength = _taskIds.length;
        Task[] memory tasks = new Task[](taskIdsLength);
        for (uint256 i = 0; i < taskIdsLength; i++) {
            tasks[i] = allTasks[_taskIds[i]];
        }
        return tasks;
    }

    /**
     * @dev deleteTask : only the principal can delete their own Task.
     * @param _taskId : task Id
     */
    function deleteTask(uint256 _taskId) public {
        Task memory beforeDeleteTask = allTasks[_taskId];
        require(beforeDeleteTask.principal == msg.sender, "only owner can delete.");
        require(block.timestamp > beforeDeleteTask.expiredTime, "task is not expired.");
        delete allTasks[_taskId];
        emit DeleteTask(msg.sender, _taskId);
        usdtBalance -= beforeDeleteTask.reward;
        usdt.transfer(msg.sender, beforeDeleteTask.reward);
    }

    /**
     * @dev deleteManyTask : only the principal can delete their own tasks by one tx.
     * @param _taskIds : tasks Id array.
     */
    function deleteManyTask(uint256[] memory _taskIds) external {
        uint256 arrLength = _taskIds.length;
        for (uint256 i = 0; i < arrLength; i++) {
            deleteTask(_taskIds[i]);
        }
    }

    /**
     * @dev approveCompleteTask : only the principal can approve complete task,
     *      and auto send usdt award to tasker.
     * @param _taskId : task Id
     * @param _requestId : requestId is CompleteRequest id.
     * @param _tasker : tasker who receive reward.
     */
    function approveCompleteTask(uint256 _taskId, uint256 _requestId, address _tasker) external {
        Task memory beforeDeleteTask = allTasks[_taskId];
        require(beforeDeleteTask.principal == msg.sender, "only owner can approve.");
        require(_requestId.taskId() == _taskId, "taskId or requestId not correct.");
        require(_requestId.requestCompleteTasker() == _tasker, "tasker not correct.");
        CompleteTaskRequest storage completeTaskRequest = completeTaskRequests[_requestId];
        completeTaskRequest.isAccepted = true;
        emit CompletedTask(msg.sender, _tasker, beforeDeleteTask);
        delete allTasks[_taskId];
        usdtBalance -= beforeDeleteTask.reward;
        usdt.transfer(_tasker, beforeDeleteTask.reward.mul(97).div(100)); //3% for protocal fee.
    }

    /***************************
     * Tasker function here *
     ***************************/

    /**
     * @dev completeTask :
     * @param _principal : principal's account address
     * @param _taskId : task Id
     * @param _requestId : request Id
     * @param _proofLink : the tasker proof they completed the task's image or video link.
     */
    function completeTask(address _principal, uint256 _taskId, uint256 _requestId, string calldata _proofLink) external {
        require(tx.origin == msg.sender, "EOA account only.");
        require(_requestId.taskId() == _taskId, "not correct taskId.");
        require(_requestId.requestCompleteTasker() == msg.sender, "not correct tasker.");
        require(completeTaskRequests[_requestId].tasker == address(0), "request is exist.");
        Task storage task = allTasks[_taskId];
        require(task.principal == _principal, "not correct principal.");
        require(task.expiredTime > block.timestamp, "task is expired.");
        task.requestQuantity += 1;
        CompleteTaskRequest memory completeTaskRequest;
        completeTaskRequest.taskId = _taskId;
        completeTaskRequest.proofLink = _proofLink;
        completeTaskRequest.tasker = msg.sender;
        completeTaskRequests[_requestId] = completeTaskRequest;
        emit CompleteTaskRequestEvent(msg.sender, _principal, _taskId, _requestId, task);
    }

    /**
     * @dev queryCompleteRequests : only the principal & tasker can query their own requests.
     */
    function queryCompleteRequests(uint256[] calldata _requestIds) external view returns (CompleteTaskRequest[] memory returnCompleteTaskRequests) {
        returnCompleteTaskRequests = new CompleteTaskRequest[](_requestIds.length);
        for (uint256 i = 0; i < _requestIds.length; i++) {
            CompleteTaskRequest memory completeTaskRequest = completeTaskRequests[_requestIds[i]];
            require(completeTaskRequest.tasker == msg.sender || allTasks[completeTaskRequest.taskId].principal == msg.sender, "only the principal & tasker can query.");
            returnCompleteTaskRequests[i] = completeTaskRequest;
        }
        return returnCompleteTaskRequests;
    }

    /***************************
     * Manager function here *
     ***************************/

    //withdraw
    function withdraw() external onlyOwner {
        uint256 realUSDTBalance = usdt.balanceOf(address(this));
        usdt.transfer(msg.sender, realUSDTBalance.sub(usdtBalance));
    }
}