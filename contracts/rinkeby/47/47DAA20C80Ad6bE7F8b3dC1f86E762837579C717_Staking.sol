// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.15;

import "Ownable.sol";
import "IStaking.sol";
import "DataTypes.sol";
import "Utils.sol";
import "Treasury.sol";


contract Staking is IStaking, Ownable {
    using Utils for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant SECONDS_IN_DAY = 1 days;
    uint8 public constant MIN_PERIOD_IN_DAYS = 1;
    uint8 public constant MAX_PERIOD_IN_DAYS = 3;
    uint256 public constant ACCUMULATOR_BASE = 10**15;

    IERC20 public immutable reward;

    mapping(IERC20 => address) public treasuries; // underlying asset => treasury
    mapping(IERC20 => uint256) public totalVirtualAmount; // underlying asset => total virtual amount
    mapping(IERC20 => uint256) public totalLockedValue; // underlying asset => total Locked Value
    mapping(IERC20 => uint256) public globalInterestAccumulator; // underlying asset => global interest accumulator
    mapping(address => mapping(IERC20 => mapping(uint8 => DataTypes.StakingRecord[])))
    public staked; // user => asset => period => record
    mapping(address => uint256) public stakedCount;


    constructor(IERC20 _reward_contract_address) {
        reward = _reward_contract_address;
    }

    modifier checkAsset(IERC20 asset) {
        require(treasuries[asset] != address(0), "staking/asset-not-supported");
        _;
    }

    modifier checkPeriod(uint8 dayPeriod) {
        require(isSupportedPeriod(dayPeriod), "staking/period-not-supported");
        _;
    }

    function getTreasuryAddress(IERC20 asset)
        external
        view
        returns (address)
    {
        require(treasuries[asset] != address(0), "staking/asset-not-supported");
        return treasuries[asset];
    }

    function getStakingAddress() external view returns (address) {
        return address(this);
    }

    function createTreasury(IERC20 asset, uint256 withdrawFactor) external onlyOwner {
        require(treasuries[asset] == address(0), "staking/asset-exists");
        Treasury treasury = new Treasury(asset, reward, withdrawFactor);
        treasuries[asset] = address(treasury);
        emit TreasuryCreated(address(asset), address(treasury), withdrawFactor);
    }

    function isSupportedPeriod(uint8 _days) public pure returns (bool) {
        return _days >= MIN_PERIOD_IN_DAYS && _days <= MAX_PERIOD_IN_DAYS;
    }

    function calculateVirtualAmount(uint256 amount, uint8 period) public pure returns (uint256) {
        return (amount * (period + 50)) / 51;
    }

    function deposit(
        IERC20 asset,
        uint8 period,
        uint256 amount
    ) external checkAsset(asset) checkPeriod(period) {
        require(amount > 0, "staking/invalid-amount");
        asset.safeTransferFrom(msg.sender, address(this), amount);
        uint256 virtualAmount = calculateVirtualAmount(amount, period);
        _updateGlobalAccumulatorsWithdrawInterest(asset, virtualAmount);
        totalLockedValue[asset] = totalLockedValue[asset] + amount;
        staked[msg.sender][asset][period].push(
            DataTypes.StakingRecord(
                amount,
                block.timestamp + (period * SECONDS_IN_DAY),
                virtualAmount,
                globalInterestAccumulator[asset]
            )
        );
        stakedCount[msg.sender]++;
        emit Deposit(msg.sender, address(asset), period, amount);
    }

    function withdraw(
        IERC20 asset,
        uint8 period,
        uint256 index
    ) external checkAsset(asset) checkPeriod(period) {
        uint256 length = staked[msg.sender][asset][period].length;
        require(index < length, "staking/invalid-record-index");

        _updateGlobalAccumulatorsWithdrawInterest(asset, 0);

        uint256 interestAmount = calculateInterestAmount(msg.sender, asset, period, index);

        reward.safeTransferFrom(address(this), msg.sender, interestAmount);
        emit InterestClaimed(address(this), msg.sender, interestAmount);

        staked[msg.sender][asset][period][index].lastGlobalMultiplierValue = globalInterestAccumulator[asset];

        if (staked[msg.sender][asset][period][index].unlockTimestamp.hasExpired()) {
            _withdrawBase(asset, period, index);
        }
    }

    function calculateInterestAmount(
        address owner,
        IERC20 asset,
        uint8 period,
        uint256 index
    ) public view returns (uint256) {
        DataTypes.StakingRecord memory record = staked[owner][asset][period][index];
        return ((record.virtualAmount *
            (globalInterestAccumulator[asset] - record.lastGlobalMultiplierValue)) /
            ACCUMULATOR_BASE);
    }

    function withdrawAll(IERC20 asset) external checkAsset(asset) {
        _updateGlobalAccumulatorsWithdrawInterest(asset, 0);

        uint256 interestAmount = 0;
        for (uint8 periodIndex = MIN_PERIOD_IN_DAYS; periodIndex <= MAX_PERIOD_IN_DAYS; periodIndex++) {
            DataTypes.StakingRecord[] memory records = staked[msg.sender][asset][periodIndex];
            for (uint256 index = records.length; index > 0; index--) {
                interestAmount += calculateInterestAmount(
                    msg.sender,
                    asset,
                    periodIndex,
                    index - 1
                );
                
                staked[msg.sender][asset][periodIndex][index-1]
                    .lastGlobalMultiplierValue = globalInterestAccumulator[asset];

                if (records[index - 1].unlockTimestamp.hasExpired()) {
                    _withdrawBase(asset, periodIndex, index - 1);
                }
            }
        }

        require(interestAmount > 0, "staking/no-deposits");

        reward.safeTransferFrom(address(this), msg.sender, interestAmount);
        emit InterestClaimed(address(this), msg.sender, interestAmount);
    }

    function _withdrawBase(
        IERC20 asset,
        uint8 period,
        uint256 index
    ) internal {
        uint256 amount = staked[msg.sender][asset][period][index].amount;
        asset.safeTransfer(msg.sender, amount);

        uint256 virtualAmount = calculateVirtualAmount(amount, period);
        totalLockedValue[asset] = totalLockedValue[asset] - amount;
        totalVirtualAmount[asset] = totalVirtualAmount[asset] - virtualAmount;

        _remove(asset, period, index);
        stakedCount[msg.sender]--;
        emit Withdrawal(msg.sender, address(asset), period, amount);
    }

    function _remove(
        IERC20 asset,
        uint8 period,
        uint256 index
    ) internal {
        uint256 length = staked[msg.sender][asset][period].length;
        require(index < length, "staking/array-out-of-bounds");

        // remove element from array
        if (index != length - 1) {
            staked[msg.sender][asset][period][index] = staked[msg.sender][asset][period][
                length - 1
            ];
        }
        staked[msg.sender][asset][period].pop();
    }

    function _updateGlobalAccumulatorsWithdrawInterest(IERC20 asset, uint256 virtualAmount) internal {
        Treasury treasury = Treasury(treasuries[asset]);
        uint256 assetTotalVirtualAmount = totalVirtualAmount[asset];
        if (assetTotalVirtualAmount > 0) {
            // wait for accruing interest till staking contract is not empty
            uint256 interestAccrued = treasury.withdrawInterest();
            globalInterestAccumulator[asset] =
                globalInterestAccumulator[asset] +
                (interestAccrued * ACCUMULATOR_BASE) /
                assetTotalVirtualAmount;
        }
        totalVirtualAmount[asset] = assetTotalVirtualAmount + virtualAmount;
    }

    function withdrawFromTreasury(
        IERC20 asset,
        address recipient,
        uint256 amount
    ) external onlyOwner checkAsset(asset) {
        Treasury(treasuries[asset]).withdrawReward(recipient, amount);
    }

    function getAllUsersPositions(address user, IERC20 asset)
        external
        view
        checkAsset(asset)
        returns (DataTypes.StakingState[] memory data)
    {
        uint256 userStakedCount = stakedCount[user];
        data = new DataTypes.StakingState[](userStakedCount);

        if (userStakedCount == 0) {
            return data;
        }

        uint256 index = 0;
        for (uint8 period = 1; period <= 3; period++) {
            DataTypes.StakingRecord[] memory records = staked[user][asset][period];
            for (uint256 recordIndex = 0; recordIndex < records.length; recordIndex++) {
                DataTypes.StakingRecord memory record = records[recordIndex];
                uint256 rewardsAccrued = calculateInterestAmount(user, asset, period, recordIndex);
                data[index] = DataTypes.StakingState(
                    address(asset),
                    period,
                    uint32(record.unlockTimestamp - (period * SECONDS_IN_DAY)),
                    uint32(record.unlockTimestamp),
                    record.amount,
                    rewardsAccrued,
                    recordIndex
                );
                index++;
            }
        }

        return data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity >=0.8.0 <0.8.15;


interface IStaking {
    event Deposit(
        address indexed user,
        address indexed asset,
        uint8 indexed period,
        uint256 amount
    );

    event Withdrawal(
        address indexed user,
        address indexed asset,
        uint8 indexed period,
        uint256 amount
    );

    event InterestClaimed(
        address indexed user,
        address indexed wallet,
        uint256 amount
    );

    event TreasuryCreated(
        address indexed asset,
        address indexed treasury,
        uint256 withdrawFactor);

    event WalletCreated(
        address indexed user,
        address indexed wallet
    );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.15;

interface DataTypes {
    struct StakingRecord {
        uint256 amount;
        uint256 unlockTimestamp;
        uint256 virtualAmount;
        uint256 lastGlobalMultiplierValue;
    }

    struct VestingRecord {
        uint256 amount;
        uint256 unlockTimestamp;
    }

    struct VestingState {
        uint32 startTime;
        uint32 endTime;
        uint256 amount;
        uint256 index;
    }

    struct StakingState {
        address asset;
        uint8 period;
        uint32 startTime;
        uint32 endTime;
        uint256 amountStaked;
        uint256 amountClaimable;
        uint256 index;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.15;


library Utils {
    function hasExpired(uint256 timestamp) internal view returns (bool) {
        return block.timestamp >= timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.15;

import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";


contract Treasury is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant WITHDRAWAL_FACTOR_BASE = 10**9;

    IERC20 public immutable asset;
    IERC20 public immutable reward;

    uint256 public immutable withdrawalFactorPerBlock;
    uint256 public lastWithdrawalBlock;

    constructor(
        IERC20 _asset,
        IERC20 _reward,
        uint256 _withdrawalFactor
    ) {
        asset = _asset;
        reward = _reward;
        require(_withdrawalFactor < WITHDRAWAL_FACTOR_BASE, "treasury/incorrect-withdrawal-factor");
        withdrawalFactorPerBlock = _withdrawalFactor;
        lastWithdrawalBlock = block.number;
        // Ownership should be transfered to staking contract during deployment
    }

    function withdrawReward(address recipient, uint256 amount) external onlyOwner {
        uint256 balance = reward.balanceOf(address(this));
        require(amount <= balance, "treasury/invalid-balance");
        reward.safeTransfer(recipient, amount);
    }

    function withdrawInterest() external onlyOwner returns (uint256) {
        if (block.number == lastWithdrawalBlock) {
            return 0;
        }
        uint256 blocksPassed = block.number - lastWithdrawalBlock;
        uint256 interestFactor = withdrawalFactorPerBlock * blocksPassed;
        uint256 availableAmount = reward.balanceOf(address(this));
        uint256 amountToWithdraw = (availableAmount * interestFactor) / (WITHDRAWAL_FACTOR_BASE+interestFactor);
        reward.safeTransfer(msg.sender, amountToWithdraw);
        lastWithdrawalBlock = block.number;
        return amountToWithdraw;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.15;


interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external pure returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.8.15;

import "Address.sol";
import "IERC20.sol";


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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