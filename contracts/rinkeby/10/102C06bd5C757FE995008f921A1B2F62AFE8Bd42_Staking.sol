/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeBEP20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

contract Staking is Ownable {
    using SafeBEP20 for IBEP20;
    using SafeMath for uint256;

    enum PoolType {
        Deposit,
        Loan
    }

    enum TransactionType {
        Staking,
        Borrow
    }

    struct UserInfo {
        TransactionType transactionType;
        uint256 amount;
        uint256 time;
        uint256 paidOut;
    }

    /*
     * TODO: Store only essential tokenInfo.
     * Get other info from the token contract
     */
    struct TokenInfo {
        IBEP20 token;
        uint256 decimals;
        string name;
        string symbol;
        uint256 toUSDT;
        IBEP20 rToken;
        uint256 rDecimals;
        string rName;
        string rSymbol;
        uint256 rToUSDT;
    }

    struct PoolInfo {
        string poolName;
        TokenInfo tokenInfo;
        uint256 APY;
        uint256 duration;
        uint256 startTime;
        uint256 endTime;
        uint256 limitPerUser;
        uint256 balance;
        uint256 capacity;
        bool paused;
        bool quarterlyPayout;
        uint256 uniqueUsers;
    }

    PoolInfo[] public poolInfo;
    mapping(uint256 => PoolType) public poolType;
    mapping(uint256 => uint256) public poolLoanedBalance;
    mapping(uint256 => mapping(address => bool)) public isAPoolUser;
    mapping(uint256 => mapping(address => bool)) public isWhitelisted;

    mapping(uint256 => mapping(address => UserInfo[])) public userInfo;
    mapping(uint256 => mapping(address => uint256)) public totalAmountInvolved;

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage stakes = userInfo[_pid][msg.sender];

        require(!pool.paused, "pool_paused");
        require(
            block.timestamp >= pool.startTime &&
                block.timestamp <= pool.endTime,
            "pool_inactive"
        );
        require(_amount <= pool.limitPerUser, "amount exceeds limit per stake");
        require(
            pool.balance + _amount <= pool.capacity,
            "pool_capacity_reached"
        );

        pool.tokenInfo.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        stakes.push(
            UserInfo({
                transactionType: TransactionType.Staking,
                amount: _amount,
                time: block.timestamp,
                paidOut: 0
            })
        );

        totalAmountInvolved[_pid][msg.sender] = totalAmountInvolved[_pid][
            msg.sender
        ].add(_amount);

        pool.balance = pool.balance.add(_amount);

        if (!isAPoolUser[_pid][msg.sender]) {
            pool.uniqueUsers = pool.uniqueUsers.add(1);
        }

        isAPoolUser[_pid][msg.sender] = true;

        emit Deposited(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _index) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage stakes = userInfo[_pid][msg.sender];

        require(
            stakes[_index].transactionType == TransactionType.Staking,
            "transactionType not Staking"
        );

        if (poolType[_pid] == PoolType.Deposit) {
            require(
                block.timestamp >= stakes[_index].time + pool.duration,
                "too early"
            );
        }

        harvestRewards(_pid, _index, block.timestamp - stakes[_index].time);

        uint256 convertedAmount = stakes[_index]
            .amount
            .mul(10**pool.tokenInfo.rDecimals)
            .mul(pool.tokenInfo.toUSDT)
            .div((10**pool.tokenInfo.decimals).mul(pool.tokenInfo.rToUSDT));

        pool.tokenInfo.rToken.safeTransfer(msg.sender, convertedAmount);

        totalAmountInvolved[_pid][msg.sender] = totalAmountInvolved[_pid][
            msg.sender
        ].sub(stakes[_index].amount);

        pool.balance = pool.balance.sub(stakes[_index].amount);

        emit Withdrawn(msg.sender, _pid, stakes[_index].amount);

        stakes[_index] = stakes[stakes.length - 1];

        stakes.pop();

        if (stakes.length == 0) {
            isAPoolUser[_pid][msg.sender] = false;
            pool.uniqueUsers = pool.uniqueUsers.sub(1);
        }
    }

    function harvestRewards(
        uint256 _pid,
        uint256 _index,
        uint256 _forDuration
    ) private {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo[] storage stakes = userInfo[_pid][msg.sender];

        if (poolType[_pid] == PoolType.Deposit) {
            if (_forDuration > pool.duration) {
                _forDuration = pool.duration;
            }
        }

        uint256 reward;
        if (poolType[_pid] == PoolType.Loan) {
            (uint256 utilisation, uint256 precision) = getPoolUtilisation(_pid);

            reward = (
                stakes[_index].amount.mul(pool.APY).mul(utilisation).mul(
                    _forDuration
                )
            ).div(precision * 100 * 86400 * 365);
        } else {
            reward = (stakes[_index].amount.mul(pool.APY).mul(_forDuration))
                .div(100 * 86400 * 365);
        }

        // ** Conversion should not be necessary if the data is duplicated
        reward = reward
            .mul(10**pool.tokenInfo.rDecimals)
            .mul(pool.tokenInfo.toUSDT)
            .div((10**pool.tokenInfo.decimals).mul(pool.tokenInfo.rToUSDT));

        // NOTE/TODO Here it is assumed the token price remains the same.
        // If the token price does update however, the below lines need to be updated accordingly
        uint256 claimableRewards = reward.sub(stakes[_index].paidOut);

        pool.tokenInfo.rToken.safeTransfer(msg.sender, claimableRewards);

        // pool.balance = pool.balance.sub(claimableRewards);

        stakes[_index].paidOut = stakes[_index].paidOut.add(claimableRewards);

        emit RewardHarvested(msg.sender, _pid, claimableRewards);
    }

    function borrow(uint256 _pid, uint256 _amount) public {
        require(poolType[_pid] == PoolType.Loan, "poolType_not_Loan");
        require(isWhitelisted[_pid][msg.sender], "not_whitelisted");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage loans = userInfo[_pid][msg.sender];

        require(!pool.paused, "pool_paused");
        require(
            block.timestamp >= pool.startTime &&
                block.timestamp <= pool.endTime,
            "pool_inactive"
        );
        require(
            poolLoanedBalance[_pid] + _amount <= pool.capacity,
            "exceeds pool capacity"
        );

        pool.tokenInfo.token.safeTransfer(msg.sender, _amount);

        loans.push(
            UserInfo({
                transactionType: TransactionType.Borrow,
                amount: _amount,
                time: block.timestamp,
                paidOut: 0
            })
        );

        totalAmountInvolved[_pid][msg.sender] = totalAmountInvolved[_pid][
            msg.sender
        ].add(_amount);

        poolLoanedBalance[_pid] = poolLoanedBalance[_pid].add(_amount);

        if (!isAPoolUser[_pid][msg.sender]) {
            pool.uniqueUsers = pool.uniqueUsers.add(1);
        }

        isAPoolUser[_pid][msg.sender] = true;

        emit Borrowed(msg.sender, _pid, _amount);
    }

    function repay(uint256 _pid, uint256 _index) public {
        require(poolType[_pid] == PoolType.Loan, "poolType_not_Loan");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo[] storage loans = userInfo[_pid][msg.sender];

        require(
            loans[_index].transactionType == TransactionType.Borrow,
            "transactionType not Borrow"
        );

        uint256 interest = calculateInterest(msg.sender, _pid, _index);

        pool.tokenInfo.token.safeTransferFrom(
            address(msg.sender),
            address(this),
            loans[_index].amount + interest
        );

        totalAmountInvolved[_pid][msg.sender] = totalAmountInvolved[_pid][
            msg.sender
        ].sub(loans[_index].amount);

        poolLoanedBalance[_pid] = poolLoanedBalance[_pid].sub(
            loans[_index].amount
        );

        emit Repaid(msg.sender, _pid, loans[_index].amount);

        loans[_index] = loans[loans.length - 1];

        loans.pop();

        if (loans.length == 0) {
            isAPoolUser[_pid][msg.sender] = false;
            pool.uniqueUsers = pool.uniqueUsers.sub(1);
        }
    }

    function calculateInterest(
        address _user,
        uint256 _pid,
        uint256 _index
    ) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo[] memory loans = userInfo[_pid][_user];

        (uint256 utilisation, uint256 precision) = getPoolUtilisation(_pid);

        return
            (
                loans[_index]
                    .amount
                    .mul(pool.APY)
                    .mul(utilisation > precision ? precision : utilisation)
                    .mul(block.timestamp.sub(loans[_index].time))
            ).div(precision * 100 * 86400 * 365);
    }

    function getPoolUtilisation(uint256 _pid)
        public
        view
        returns (uint256, uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        uint256 precision = 1e4;
        return (
            poolLoanedBalance[_pid].mul(precision).div(pool.balance),
            precision
        );
    }

    function claimQuarterlyPayout(uint256 _pid, uint256 _index) external {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo[] memory stakes = userInfo[_pid][msg.sender];

        require(pool.quarterlyPayout, "quarterlyPayout disabled for pool");
        require(poolType[_pid] == PoolType.Deposit, "poolType not Deposit");

        uint256 timeDiff = block.timestamp - stakes[_index].time;
        if (timeDiff > pool.duration) {
            timeDiff = pool.duration;
        }

        /*
         * TODO
         * Replace "3 minutes" throughout the code with "90 days" for quarter year calculation
         * before depolying on mainnet
         */

        uint256 quartersPassed = (timeDiff).div(3 minutes);

        require(quartersPassed > 0, "too early");

        harvestRewards(_pid, _index, quartersPassed.mul(3 minutes));
    }

    function whitelist(
        uint256 _pid,
        address _user,
        bool _status
    ) external onlyOwner {
        PoolType _poolType = poolType[_pid];

        require(_poolType == PoolType.Loan, "poolType_not_Loan");

        isWhitelisted[_pid][_user] = _status;

        emit Whitelisted(_user, _pid, _status);
    }

    function createPool(PoolInfo memory _poolInfo, PoolType _poolType)
        external
        onlyOwner
    {
        require(
            _poolInfo.startTime < _poolInfo.endTime,
            "startTime should be before endTime"
        );

        _poolInfo.balance = 0;
        _poolInfo.uniqueUsers = 0;

        poolType[poolInfo.length] = _poolType;
        poolInfo.push(_poolInfo);
    }

    function editPool(uint256 _pid, PoolInfo memory _newPoolInfo)
        external
        onlyOwner
    {
        PoolInfo memory pool = poolInfo[_pid];

        // Perserve some info
        _newPoolInfo.balance = pool.balance;
        _newPoolInfo.uniqueUsers = pool.uniqueUsers;
        _newPoolInfo.tokenInfo.token = pool.tokenInfo.token;
        // , poolType

        // Update the rest
        poolInfo[_pid] = _newPoolInfo;
    }

    function setPoolPaused(uint256 _pid, bool _newStatus) external onlyOwner {
        poolInfo[_pid].paused = _newStatus;
    }

    function totalPools() external view returns (uint256) {
        return poolInfo.length;
    }

    function getPoolInfo(uint256 _from, uint256 _to)
        external
        view
        returns (PoolInfo[] memory)
    {
        PoolInfo[] memory tPoolInfo = new PoolInfo[](_to - _from + 1);

        uint256 j = 0;
        for (uint256 i = _from; i <= _to; i++) {
            tPoolInfo[j++] = poolInfo[i];
        }

        return tPoolInfo;
    }

    function totalStakesOfUser(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].length;
    }

    function getUserStakes(
        uint256 _pid,
        address _user,
        uint256 _from,
        uint256 _to
    ) external view returns (UserInfo[] memory) {
        UserInfo[] memory tUserInfo = new UserInfo[](_to - _from + 1);

        uint256 j = 0;
        for (uint256 i = _from; i <= _to; i++) {
            tUserInfo[j++] = userInfo[_pid][_user][i];
        }

        return tUserInfo;
    }

    function recoverBEP20(address _token, uint256 _amount) external onlyOwner {
        IBEP20(_token).safeTransfer(owner(), _amount);
        emit Recovered(_token, _amount);
    }

    receive() external payable {
        emit ReceivedBNB(msg.sender, msg.value);
    }

    // Events
    event Deposited(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardHarvested(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event Whitelisted(address indexed user, uint256 indexed pid, bool status);
    event Borrowed(address indexed user, uint256 indexed pid, uint256 amount);
    event Repaid(address indexed user, uint256 indexed pid, uint256 amount);

    event Recovered(address token, uint256 amount);
    event ReceivedBNB(address, uint256);
}