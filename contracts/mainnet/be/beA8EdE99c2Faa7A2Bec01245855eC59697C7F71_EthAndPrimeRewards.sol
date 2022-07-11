// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./PrimeRewards.sol";

/// @title The EthAndPrimeRewards staking contract
/// @notice Staking contract for The Core. It allows for a fixed ETH
/// rewards distributed evenly across all staked tokens per second.
contract EthAndPrimeRewards is PrimeRewards {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Info of each Deposit.
    /// `rewardDebt` The amount of ETH not entitled to the user.
    struct EthDepositInfo {
        int256 rewardDebt;
    }

    /// @notice Info of each ethPool. EthPoolInfo is independent of PoolInfo.
    /// Contains the start and end timestamps of the rewards
    struct EthPoolInfo {
        uint256 accEthPerShare; // in wei
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
    }

    /// @notice Info of each ethPool.
    EthPoolInfo[] public ethPoolInfo;

    /// @notice Eth amount distributed for given period. ethAmountPerSecond = ethAmount / (ethEndTimestamp - ethStartTimestamp)
    uint256 public ethStartTimestamp; // staking start timestamp.
    uint256 public ethEndTimestamp; // staking end timestamp.
    uint256 public ethAmount; // the amount of ETH to give out as rewards.
    uint256 public ethAmountPerSecond; // the amount of ETH to give out as rewards per second.
    uint256 public constant ethAmountPerSecondPrecision = 1e18; // ethAmountPerSecond is carried around with extra precision to reduce rounding errors

    /// @dev Total allocation points. Must be the sum of all allocation points in all ethPools.
    uint256 public ethTotalAllocPoint;

    /// @notice Deposit info of each user that stakes nft sets.
    // ethPoolID(per set) => user address => deposit info
    mapping(uint256 => mapping(address => EthDepositInfo))
        public ethDepositInfo;

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha)
        PrimeRewards(_prime, _parallelAlpha)
    {}

    /// @notice Add a new tokenIds ethPool. Can only be called by the owner.
    /// DO NOT add the same token id more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new ethPool.
    /// @param _tokenIds TokenIds for a ParallelAlpha ERC1155 tokens.
    function addPool(uint256 _allocPoint, uint256[] memory _tokenIds)
        public
        override
        onlyOwner
    {
        // Update all ethPools cause allocpoints
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        ethTotalAllocPoint += _allocPoint;
        ethPoolInfo.push(
            EthPoolInfo({
                accEthPerShare: 0,
                allocPoint: _allocPoint,
                lastRewardTimestamp: Math.max(
                    block.timestamp,
                    ethStartTimestamp
                )
            })
        );

        PrimeRewards.addPool(_allocPoint, _tokenIds);
        emit LogPoolSetAllocPoint(
            ethPoolInfo.length - 1,
            _allocPoint,
            ethTotalAllocPoint,
            ID_ETH
        );
    }

    // Set remaining eth to distribute between ethEndTimestamp-ethStartTimestamp

    /// @notice Set new cycle/period to distribute rewards between endTimestamp-startTimestamp
    /// evenly per second. ethAmountPerSecond = msg.value / _ethEndTimestamp - _ethStartTimestamp
    /// @param _ethStartTimestamp Timestamp for staking period to start at
    /// @param _ethEndTimestamp Timestamp for staking period to end at
    function setEthPerSecond(
        uint256 _ethStartTimestamp,
        uint256 _ethEndTimestamp
    ) external payable onlyOwner {
        require(
            _ethStartTimestamp < _ethEndTimestamp,
            "endTimestamp cant be less than startTimestamp"
        );
        require(
            block.timestamp < ethStartTimestamp ||
                ethEndTimestamp < block.timestamp,
            "Only updates after ethEndTimestamp or before ethStartTimestamp"
        );
        // Update all ethPools before proceeding, ensure rewards calculated up to this timestamp
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
            ethPoolInfo[i].lastRewardTimestamp = _ethStartTimestamp;
        }
        ethAmount = msg.value;
        ethStartTimestamp = _ethStartTimestamp;
        ethEndTimestamp = _ethEndTimestamp;
        ethAmountPerSecond =
            (msg.value * ethAmountPerSecondPrecision) /
            (_ethEndTimestamp - _ethStartTimestamp);
        emit LogSetPerSecond(
            msg.value,
            _ethStartTimestamp,
            _ethEndTimestamp,
            ID_ETH
        );
    }

    /// @notice Update ethEndTimestamp, only possible to call this when staking for
    /// a period has already begun and new ethEndTimestamp can't be in the past
    /// @param _ethEndTimestamp New timestamp for staking period to end at
    function setEthEndTimestamp(uint256 _ethEndTimestamp) external onlyOwner {
        require(
            ethStartTimestamp < block.timestamp,
            "staking have not started yet"
        );
        require(block.timestamp < _ethEndTimestamp, "invalid end timestamp");
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }

        // Update ethAmountPerSecond based on the new ethEndTimestamp
        ethStartTimestamp = block.timestamp;
        ethEndTimestamp = _ethEndTimestamp;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - ethStartTimestamp);
        emit EndTimestampUpdated(_ethEndTimestamp, ID_ETH);
    }

    /// @notice Function for 'Top Ups', adds additional ETH to distribute for remaining time
    /// in the period.
    function addEthAmount() external payable onlyOwner {
        require(
            ethStartTimestamp < block.timestamp &&
                block.timestamp < ethEndTimestamp,
            "Only topups inside a period"
        );
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        // Top up current cycle's ETH
        ethAmount += msg.value;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - block.timestamp);
        emit RewardIncrease(msg.value, ID_ETH);
    }

    /// @notice Function for 'Top Downs', removes additional ETH to distribute for remaining time
    /// in the period.
    /// @param _removeEthAmount Amount of ETH to remove from the remaining reward pool
    function removeEthAmount(uint256 _removeEthAmount) external onlyOwner {
        require(
            ethStartTimestamp < block.timestamp &&
                block.timestamp < ethEndTimestamp,
            "Only topdowns inside a period"
        );
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        // Top up current cycle's ETH
        _removeEthAmount = Math.min(_removeEthAmount, ethAmount);
        ethAmount -= _removeEthAmount;
        ethAmountPerSecond =
            (ethAmount * ethAmountPerSecondPrecision) /
            (ethEndTimestamp - block.timestamp);

        (bool sent, ) = msg.sender.call{ value: _removeEthAmount }("");
        require(sent, "Failed to send Ether");

        emit RewardDecrease(_removeEthAmount, ID_ETH);
    }

    /// @notice Update the given ethPool's ETH allocation point.  Can only be called by the owner.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _allocPoint New AP of the ethPool.
    function setEthPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
    {
        // Update all ethPools
        for (uint256 i = 0; i < ethPoolInfo.length; ++i) {
            updateEthPool(i);
        }
        ethTotalAllocPoint =
            ethTotalAllocPoint -
            ethPoolInfo[_pid].allocPoint +
            _allocPoint;
        ethPoolInfo[_pid].allocPoint = _allocPoint;
        emit LogPoolSetAllocPoint(
            _pid,
            _allocPoint,
            ethTotalAllocPoint,
            ID_ETH
        );
    }

    /// @notice View function to see pending ETH on frontend.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _user Address of user.
    /// @return pending ETH reward for a given user.
    function pendingEth(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        DepositInfo storage deposit_ = depositInfo[_pid][_user];
        EthPoolInfo memory ethPool = ethPoolInfo[_pid];
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][_user];
        uint256 accEthPerShare = ethPool.accEthPerShare;
        uint256 totalSupply = pool.totalSupply;

        if (
            ethStartTimestamp <= block.timestamp &&
            ethPool.lastRewardTimestamp < block.timestamp &&
            totalSupply > 0
        ) {
            uint256 updateToTimestamp = Math.min(
                block.timestamp,
                ethEndTimestamp
            );
            uint256 secondsStaked = updateToTimestamp -
                ethPool.lastRewardTimestamp;
            uint256 ethReward = (secondsStaked *
                ethAmountPerSecond *
                ethPool.allocPoint) / ethTotalAllocPoint;
            accEthPerShare += ethReward / totalSupply;
        }
        pending =
            ((deposit_.amount * accEthPerShare).toInt256() -
                ethDeposit.rewardDebt).toUint256() /
            ethAmountPerSecondPrecision;
    }

    /// @notice Update reward variables for all ethPools. Be careful of gas spending!
    /// @param _pids Pool IDs of all to be updated. Make sure to update all active ethPools.
    function massUpdateEthPools(uint256[] calldata _pids) external {
        uint256 len = _pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updateEthPool(_pids[i]);
        }
    }

    /// @notice Update reward variables of the given ethPool.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    function updateEthPool(uint256 _pid) public {
        PoolInfo memory pool = poolInfo[_pid];
        EthPoolInfo storage ethPool = ethPoolInfo[_pid];
        uint256 totalSupply = pool.totalSupply;
        if (
            ethStartTimestamp > block.timestamp ||
            ethPool.lastRewardTimestamp >= block.timestamp ||
            (ethStartTimestamp == 0 && ethEndTimestamp == 0)
        ) {
            return;
        }

        uint256 updateToTimestamp = Math.min(block.timestamp, ethEndTimestamp);
        uint256 secondsStaked = updateToTimestamp - ethPool.lastRewardTimestamp;
        uint256 ethReward = (secondsStaked *
            ethAmountPerSecond *
            ethPool.allocPoint) / ethTotalAllocPoint;
        ethAmount -= ethReward / ethAmountPerSecondPrecision;
        if (totalSupply > 0) {
            ethPool.accEthPerShare += ethReward / totalSupply;
        }
        ethPool.lastRewardTimestamp = updateToTimestamp;
        emit LogUpdatePool(
            _pid,
            ethPool.lastRewardTimestamp,
            totalSupply,
            ethPool.accEthPerShare,
            ID_ETH
        );
    }

    /// @notice Deposit tokens for ETH & PRIME allocation.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount Amount of tokens to deposit for _pid.
    function deposit(uint256 _pid, uint256 _amount) public virtual override {
        require(_amount > 0, "Specify valid token amount to deposit");
        updateEthPool(_pid);
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt += (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.deposit(_pid, _amount);
    }

    /// @notice Withdraw tokens.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount amounts to withdraw from the pool
    function withdraw(uint256 _pid, uint256 _amount) public virtual override {
        updateEthPool(_pid);
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt -= (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.withdraw(_pid, _amount);
    }

    /// @notice Claim accumulated eth rewards.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    function claimEth(uint256 _pid) public {
        updateEthPool(_pid);
        DepositInfo storage deposit_ = depositInfo[_pid][msg.sender];
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        int256 accumulatedEth = (deposit_.amount *
            ethPoolInfo[_pid].accEthPerShare).toInt256();
        uint256 _pendingEth = (accumulatedEth - ethDeposit.rewardDebt)
            .toUint256() / ethAmountPerSecondPrecision;

        // Effects
        ethDeposit.rewardDebt = accumulatedEth;

        // Interactions
        if (_pendingEth != 0) {
            (bool sent, ) = msg.sender.call{ value: _pendingEth }("");
            require(sent, "Failed to send Ether");
        }

        emit Claim(msg.sender, _pid, _pendingEth, ID_ETH);
    }

    /// @notice ClaimPrime and ClaimETH a pool
    /// @param _pid Pool IDs of all to be claimed
    function claimEthAndPrime(uint256 _pid) public virtual {
        PrimeRewards.claimPrime(_pid);
        claimEth(_pid);
    }

    /// @notice ClaimPrime multiple ethPools
    /// @param _pids Pool IDs of all to be claimed
    function claimPools(uint256[] calldata _pids) external virtual {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimEthAndPrime(_pids[i]);
        }
    }

    /// @notice Withdraw and claim prime rewards, update eth reward dept so that user can claim eth after.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw.
    function withdrawAndClaimPrime(uint256 _pid, uint256 _amount)
        public
        virtual
        override
    {
        updateEthPool(_pid);
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt -= (_amount * ethPoolInfo[_pid].accEthPerShare)
            .toInt256();

        PrimeRewards.withdrawAndClaimPrime(_pid, _amount);
    }

    /// @notice Withdraw and claim prime & eth rewards.
    /// @param _pid The index of the ethPool. See `ethPoolInfo`.
    /// @param _amount tokens amount to withdraw.
    function withdrawAndClaimEthAndPrime(uint256 _pid, uint256 _amount)
        external
        virtual
    {
        // Claim ETH
        updateEthPool(_pid);
        DepositInfo storage deposit_ = depositInfo[_pid][msg.sender];
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        int256 accumulatedEth = (deposit_.amount *
            ethPoolInfo[_pid].accEthPerShare).toInt256();
        uint256 _pendingEth = (accumulatedEth - ethDeposit.rewardDebt)
            .toUint256() / ethAmountPerSecondPrecision;

        // Effects
        ethDeposit.rewardDebt =
            accumulatedEth -
            (_amount * ethPoolInfo[_pid].accEthPerShare).toInt256();

        if (_pendingEth != 0) {
            (bool sent, ) = msg.sender.call{ value: _pendingEth }("");
            require(sent, "Error sending eth");
        }

        // Withdraw and claim PRIME
        PrimeRewards.withdrawAndClaimPrime(_pid, _amount);
        emit Claim(msg.sender, _pid, _pendingEth, ID_ETH);
    }

    /// @notice Withdraw and forgo rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) public virtual override {
        EthDepositInfo storage ethDeposit = ethDepositInfo[_pid][msg.sender];

        // Effects
        ethDeposit.rewardDebt = 0;

        PrimeRewards.emergencyWithdraw(_pid);
    }

    /// @notice Sweep function to transfer ETH out of contract.
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepETH(address payable to, uint256 amount) public onlyOwner {
        (bool sent, ) = to.call{ value: amount }("");
        require(sent, "Failed to send Ether");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/// @title The PrimeRewards staking contract
/// @notice Staking for PrimeKey, PrimeSets, CatalystDrive. It allows for a fixed PRIME token
/// rewards distributed evenly across all staked tokens per second.
contract PrimeRewards is Ownable, ERC1155Holder {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    /// @notice Info of each Deposit.
    /// `amount` Number of nft sets the user has provided.
    /// `rewardDebt` The amount of PRIME the user is not eligible for either from
    ///  having already harvesting or from not staking in the past.
    struct DepositInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    /// @notice Info of each pool.
    /// Contains the weighted allocation of the reward pool
    /// as well as the ParallelAlpha tokenIds required to stake in the pool
    struct PoolInfo {
        uint256 accPrimePerShare;
        uint256 allocPoint;
        uint256 lastRewardTimestamp;
        uint256[] tokenIds;
        uint256 totalSupply;
    }

    /// @notice Address of PRIME contract.
    IERC20 public PRIME;

    /// @notice Address of Parallel Alpha erc1155
    IERC1155 public immutable parallelAlpha;

    /// @notice Info of each pool.
    PoolInfo[] public poolInfo;

    /// @notice Deposit info of each user that stakes nft sets.
    // poolID(per set) => user address => deposit info
    mapping(uint256 => mapping(address => DepositInfo)) public depositInfo;

    /// @notice Prime amount distributed for given period. primeAmountPerSecond = primeAmount / (endTimestamp - startTimestamp)
    uint256 public startTimestamp; // caching start timestamp.
    uint256 public endTimestamp; // caching end timestamp.
    uint256 public primeAmount; // the amount of PRIME to give out as rewards.
    uint256 public primeAmountPerSecond; // the amount of PRIME to give out as rewards per second.
    uint256 public constant primeAmountPerSecondPrecision = 1e18; // primeAmountPerSecond is carried around with extra precision to reduce rounding errors

    uint256 public primeUpdateCutoff = 1667304000;

    /// @dev Limit number of pools added
    uint256 public maxNumPools = 500;

    /// @dev Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    /// @dev Deposits can be paused
    bool public depositsPaused;

    /// @dev Constants passed into event data
    uint256 public constant ID_PRIME = 0;
    uint256 public constant ID_ETH = 1;

    /// @dev internal lock for receiving ERC1155 tokens. Only allow during deposit calls
    bool public onReceiveLocked = true;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event Claim(
        address indexed user,
        uint256 indexed pid,
        uint256 amount,
        uint256 indexed currencyId
    );
    event LogPoolAddition(uint256 indexed pid, uint256[] tokenIds);

    event EndTimestampUpdated(uint256 endTimestamp, uint256 indexed currencyID);
    event RewardIncrease(uint256 amount, uint256 indexed currencyID);
    event RewardDecrease(uint256 amount, uint256 indexed currencyID);

    event DepositsPaused(bool depositsPaused);
    event LogPoolSetAllocPoint(
        uint256 indexed pid,
        uint256 allocPoint,
        uint256 totalAllocPoint,
        uint256 indexed currencyId
    );
    event LogUpdatePool(
        uint256 indexed pid,
        uint256 lastRewardTimestamp,
        uint256 supply,
        uint256 accPerShare,
        uint256 indexed currencyId
    );
    event LogSetPerSecond(
        uint256 amount,
        uint256 startTimestamp,
        uint256 endTimestamp,
        uint256 indexed currencyId
    );

    /// @param _prime The PRIME token contract address.
    /// @param _parallelAlpha The Parallel Alpha contract address.
    constructor(IERC20 _prime, IERC1155 _parallelAlpha) {
        parallelAlpha = _parallelAlpha;
        PRIME = _prime;
    }

    /// @notice Sets new prime token address
    /// @param _prime The PRIME token contract address.
    function setPrimeTokenAddress(IERC20 _prime) external onlyOwner {
        require(
            block.timestamp < primeUpdateCutoff,
            "PRIME address update window has has passed"
        );
        PRIME = _prime;
    }

    /// @notice Sets new max number of pools. New max cannot be less than
    /// current number of pools.
    /// @param _maxNumPools The new max number of pools.
    function setMaxNumPools(uint256 _maxNumPools) external onlyOwner {
        require(
            _maxNumPools >= poolLength(),
            "Can't set maxNumPools less than poolLength"
        );
        maxNumPools = _maxNumPools;
    }

    /// @notice Returns the number of pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    /// @param _pid Pool to get IDs for
    function getPoolTokenIds(uint256 _pid)
        external
        view
        returns (uint256[] memory)
    {
        return poolInfo[_pid].tokenIds;
    }

    function updateAllPools() internal {
        uint256 len = poolLength();
        for (uint256 i = 0; i < len; ++i) {
            updatePool(i);
        }
    }

    /// @notice Add a new set of tokenIds as a new pool. Can only be called by the owner.
    /// DO NOT add the same token id more than once. Rewards will be messed up if you do.
    /// @param _allocPoint AP of the new pool.
    /// @param _tokenIds TokenIds for ParallelAlpha ERC1155, set of tokenIds for pool.
    function addPool(uint256 _allocPoint, uint256[] memory _tokenIds)
        public
        virtual
        onlyOwner
    {
        require(poolInfo.length < maxNumPools, "Max num pools reached");
        require(_tokenIds.length > 0, "TokenIds cannot be empty");
        require(_allocPoint > 0, "Allocation point cannot be 0 or negative");
        // Update all Pools cause allocpoints
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
        }
        totalAllocPoint += _allocPoint;
        poolInfo.push(
            PoolInfo({
                accPrimePerShare: 0,
                allocPoint: _allocPoint,
                lastRewardTimestamp: Math.max(block.timestamp, startTimestamp),
                tokenIds: _tokenIds,
                totalSupply: 0
            })
        );
        emit LogPoolAddition(poolInfo.length - 1, _tokenIds);
        emit LogPoolSetAllocPoint(
            poolInfo.length - 1,
            _allocPoint,
            totalAllocPoint,
            ID_PRIME
        );
    }

    /// @notice Set new cycle/period to distribute rewards between endTimestamp-startTimestamp
    /// evenly per second. primeAmountPerSecond = _primeAmount / _endTimestamp - _startTimestamp
    /// @param _startTimestamp Timestamp for staking period to start at
    /// @param _endTimestamp Timestamp for staking period to end at
    /// @param _primeAmount Amount of Prime to distribute evenly across whole period
    function setPrimePerSecond(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _primeAmount
    ) external onlyOwner {
        require(
            _startTimestamp < _endTimestamp,
            "Endtimestamp cant be less than Starttimestamp"
        );
        require(
            block.timestamp < startTimestamp || endTimestamp < block.timestamp,
            "Only updates after endTimestamp or before startTimestamp"
        );

        // Update all pools before proceeding, ensure rewards calculated up to this timestamp
        for (uint256 i = 0; i < poolInfo.length; ++i) {
            updatePool(i);
            poolInfo[i].lastRewardTimestamp = _startTimestamp;
        }
        primeAmount = _primeAmount;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        primeAmountPerSecond =
            (_primeAmount * primeAmountPerSecondPrecision) /
            (_endTimestamp - _startTimestamp);
        emit LogSetPerSecond(
            _primeAmount,
            _startTimestamp,
            _endTimestamp,
            ID_PRIME
        );
    }

    /// @notice Update endTimestamp, only possible to call this when staking for
    /// a period has already begun and new endTimestamp can't be in the past
    /// @param _endTimestamp New timestamp for staking period to end at
    function setEndTimestamp(uint256 _endTimestamp) external onlyOwner {
        require(
            startTimestamp < block.timestamp,
            "caching have not started yet"
        );
        require(block.timestamp < _endTimestamp, "invalid end timestamp");
        updateAllPools();

        // Update primeAmountPerSecond based on the new endTimestamp
        startTimestamp = block.timestamp;
        endTimestamp = _endTimestamp;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - startTimestamp);
        emit EndTimestampUpdated(_endTimestamp, ID_PRIME);
    }

    /// @notice Function for 'Top Ups', adds additional prime to distribute for remaining time
    /// in the period.
    /// @param _addPrimeAmount Amount of Prime to add to the remaining reward pool
    function addPrimeAmount(uint256 _addPrimeAmount) external onlyOwner {
        require(
            startTimestamp < block.timestamp && block.timestamp < endTimestamp,
            "Only topups inside a period"
        );
        // Update all pools
        updateAllPools();
        // Top up current cycle's PRIME
        primeAmount += _addPrimeAmount;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - block.timestamp);
        emit RewardIncrease(_addPrimeAmount, ID_PRIME);
    }

    /// @notice Function for 'Top Downs', removes additional prime to distribute for remaining time
    /// in the period.
    /// @param _removePrimeAmount Amount of Prime to remove from the remaining reward pool
    function removePrimeAmount(uint256 _removePrimeAmount) external onlyOwner {
        require(
            startTimestamp < block.timestamp && block.timestamp < endTimestamp,
            "Only topdowns inside a period"
        );

        // Update all pools
        updateAllPools();

        // Top up current cycle's PRIME
        // Using min to make sure the admin is able to reduce the primeAmount to zero
        _removePrimeAmount = Math.min(_removePrimeAmount, primeAmount);
        primeAmount -= _removePrimeAmount;
        primeAmountPerSecond =
            (primeAmount * primeAmountPerSecondPrecision) /
            (endTimestamp - block.timestamp);
        emit RewardDecrease(_removePrimeAmount, ID_PRIME);
    }

    /// @notice Update the given pool's PRIME allocation point. Can only be called by the owner.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _allocPoint New AP of the pool.
    function setPoolAllocPoint(uint256 _pid, uint256 _allocPoint)
        external
        onlyOwner
    {
        // Update all pools
        updateAllPools();
        totalAllocPoint =
            totalAllocPoint -
            poolInfo[_pid].allocPoint +
            _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        emit LogPoolSetAllocPoint(_pid, _allocPoint, totalAllocPoint, ID_PRIME);
    }

    /// @notice Enable/disable deposits for pools. Can only be called by the owner.
    /// @param _depositsPaused boolean value to set
    function setDepositsPaused(bool _depositsPaused) external onlyOwner {
        depositsPaused = _depositsPaused;
        emit DepositsPaused(depositsPaused);
    }

    /// @notice View function to see deposit amounts for pools on frontend.
    /// @param _pids List of pool index ids. See `poolInfo`.
    /// @param _addresses List of user addresses.
    /// @return amounts List of deposit amounts.
    function getPoolDepositAmounts(
        uint256[] calldata _pids,
        address[] calldata _addresses
    ) external view returns (uint256[] memory) {
        require(
            _pids.length == _addresses.length,
            "pids and addresses length miss-match"
        );

        uint256[] memory amounts = new uint256[](_pids.length);
        for (uint256 i = 0; i < _pids.length; ++i) {
            amounts[i] = depositInfo[_pids[i]][_addresses[i]].amount;
        }

        return amounts;
    }

    /// @notice View function to see pending PRIME on frontend.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _user Address of user.
    /// @return pending PRIME reward for a given user.
    function pendingPrime(uint256 _pid, address _user)
        external
        view
        returns (uint256 pending)
    {
        PoolInfo memory pool = poolInfo[_pid];
        DepositInfo storage _deposit = depositInfo[_pid][_user];
        uint256 accPrimePerShare = pool.accPrimePerShare;
        uint256 totalSupply = pool.totalSupply;

        if (
            startTimestamp <= block.timestamp &&
            pool.lastRewardTimestamp < block.timestamp &&
            totalSupply > 0
        ) {
            uint256 updateToTimestamp = Math.min(block.timestamp, endTimestamp);
            uint256 secondsStaked = updateToTimestamp -
                pool.lastRewardTimestamp;
            uint256 primeReward = (secondsStaked *
                primeAmountPerSecond *
                pool.allocPoint) / totalAllocPoint;
            accPrimePerShare += primeReward / totalSupply;
        }
        pending =
            ((_deposit.amount * accPrimePerShare).toInt256() -
                _deposit.rewardDebt).toUint256() /
            primeAmountPerSecondPrecision;
    }

    /// @notice Update reward variables for all pools. Be careful of gas spending!
    /// @param _pids Pool IDs of all to be updated. Make sure to update all active pools.
    function massUpdatePools(uint256[] calldata _pids) external {
        uint256 len = _pids.length;
        for (uint256 i = 0; i < len; ++i) {
            updatePool(_pids[i]);
        }
    }

    /// @notice Update reward variables of the given pool.
    /// @param _pid The index of the pool. See `poolInfo`.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (
            startTimestamp > block.timestamp ||
            pool.lastRewardTimestamp >= block.timestamp ||
            (startTimestamp == 0 && endTimestamp == 0)
        ) {
            return;
        }

        uint256 updateToTimestamp = Math.min(block.timestamp, endTimestamp);
        uint256 totalSupply = pool.totalSupply;
        uint256 secondsStaked = updateToTimestamp - pool.lastRewardTimestamp;
        uint256 primeReward = (secondsStaked *
            primeAmountPerSecond *
            pool.allocPoint) / totalAllocPoint;
        primeAmount -= primeReward / primeAmountPerSecondPrecision;
        if (totalSupply > 0) {
            pool.accPrimePerShare += primeReward / totalSupply;
        }
        pool.lastRewardTimestamp = updateToTimestamp;
        emit LogUpdatePool(
            _pid,
            pool.lastRewardTimestamp,
            totalSupply,
            pool.accPrimePerShare,
            ID_PRIME
        );
    }

    /// @notice Deposit for PRIME allocation.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of 'tokenIds sets' to deposit for _pid.
    function deposit(uint256 _pid, uint256 _amount) public virtual {
        require(!depositsPaused, "Deposits are paused");
        require(_amount > 0, "Specify valid tokenId set amount to deposit");
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply += _amount;
        _deposit.amount += _amount;
        _deposit.rewardDebt += (_amount * poolInfo[_pid].accPrimePerShare)
            .toInt256();

        onReceiveLocked = false;
        parallelAlpha.safeBatchTransferFrom(
            msg.sender,
            address(this),
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );
        onReceiveLocked = true;

        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw from pool
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw from the pool
    function withdraw(uint256 _pid, uint256 _amount) public virtual {
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= _amount;
        _deposit.rewardDebt -= (_amount * poolInfo[_pid].accPrimePerShare)
            .toInt256();
        _deposit.amount -= _amount;

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Claim accumulated PRIME rewards.
    /// @param _pid The index of the pool. See `poolInfo`.
    function claimPrime(uint256 _pid) public {
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];
        int256 accumulatedPrime = (_deposit.amount *
            poolInfo[_pid].accPrimePerShare).toInt256();
        uint256 _pendingPrime = (accumulatedPrime - _deposit.rewardDebt)
            .toUint256() / primeAmountPerSecondPrecision;

        // Effects
        _deposit.rewardDebt = accumulatedPrime;

        // Interactions
        if (_pendingPrime != 0) {
            PRIME.safeTransfer(msg.sender, _pendingPrime);
        }

        emit Claim(msg.sender, _pid, _pendingPrime, ID_PRIME);
    }

    /// @notice claimPrime multiple pools
    /// @param _pids Pool IDs of all to be claimed
    function claimPrimePools(uint256[] calldata _pids) external virtual {
        for (uint256 i = 0; i < _pids.length; ++i) {
            claimPrime(_pids[i]);
        }
    }

    /// @notice Withdraw and claim PRIME rewards.
    /// @param _pid The index of the pool. See `poolInfo`.
    /// @param _amount Amount of tokenId sets to withdraw.
    function withdrawAndClaimPrime(uint256 _pid, uint256 _amount)
        public
        virtual
    {
        updatePool(_pid);
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];
        int256 accumulatedPrime = (_deposit.amount *
            poolInfo[_pid].accPrimePerShare).toInt256();
        uint256 _pendingPrime = (accumulatedPrime - _deposit.rewardDebt)
            .toUint256() / primeAmountPerSecondPrecision;

        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = _amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= _amount;
        _deposit.rewardDebt =
            accumulatedPrime -
            (_amount * poolInfo[_pid].accPrimePerShare).toInt256();
        _deposit.amount -= _amount;

        if (_pendingPrime != 0) {
            PRIME.safeTransfer(msg.sender, _pendingPrime);
        }

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit Withdraw(msg.sender, _pid, _amount);
        emit Claim(msg.sender, _pid, _pendingPrime, ID_PRIME);
    }

    /// @notice Withdraw and forgo rewards. EMERGENCY ONLY.
    /// @param _pid The index of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) public virtual {
        DepositInfo storage _deposit = depositInfo[_pid][msg.sender];

        uint256 amount = _deposit.amount;
        // Create amounts array for tokenIds BatchTransfer
        uint256[] memory amounts = new uint256[](
            poolInfo[_pid].tokenIds.length
        );
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = amount;
        }

        // Effects
        poolInfo[_pid].totalSupply -= amount;
        _deposit.rewardDebt = 0;
        _deposit.amount = 0;

        parallelAlpha.safeBatchTransferFrom(
            address(this),
            msg.sender,
            poolInfo[_pid].tokenIds,
            amounts,
            bytes("")
        );

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice Sweep function to transfer erc20 tokens out of contract
    /// Only callable by owner.
    /// @param erc20 Token to transfer out
    /// @param to address to sweep to
    /// @param amount Amount to withdraw
    function sweepERC20(
        IERC20 erc20,
        address to,
        uint256 amount
    ) external onlyOwner {
        erc20.transfer(to, amount);
    }

    /// @notice Disable renounceOwnership. Only callable by owner.
    function renounceOwnership() public virtual override onlyOwner {
        revert("Ownership cannot be renounced");
    }

    /// @notice Revert for calls outside of deposit method
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(onReceiveLocked == false, "onReceive is locked");
        return this.onERC1155Received.selector;
    }

    /// @notice Revert for calls outside of deposit method
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        require(onReceiveLocked == false, "onReceive is locked");
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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