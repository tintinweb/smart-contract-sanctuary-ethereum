// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;
/// @title Simple Staking
/// @author jawad-unmarshal
/// @notice Simple Staking and rewards program for any ERC20 compatible token

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/ERC20Utils.sol";

contract BasicStakingContract {
    struct UserStake {
        uint stakeAmount;
        uint stakeStartBlockNumber;
        address staker;
        uint claimed;
        bool stakeStatus;
    }

    IERC20 public stakingToken;
    address public contractOwner;
    uint public minimumStake;
    uint public payoutGap;
    mapping(address => UserStake) public stakeMap;
    mapping(address => uint) public withdrawPool;

    /// @notice Emitted at the end of a successful stake
    /// @dev Emitted anytime a stake is started
    /// @param staker The address of the user staking
    /// @param stakedAmount The total amount locked into the contract by the user
    event Stake(
        address indexed staker,
        uint256 stakedAmount
    );

    /// @notice Emitted whenever the user's claims are sent to the withdraw pool
    /// @dev Must be emitted after a successful claim including after an Unstake
    /// @param staker The address of the user staking
    /// @param claimedAmount The amount claimed and sent to the WithdrawPool
    event Claim(
        address indexed staker,
        uint256 claimedAmount
    );

    /// @notice Emitted after a successful unstake
    /// @dev Emitted when a user's StakeStatus is updated to False
    /// @param staker The address of the user staking
    /// @param stakedAmount The total amount locked into the contract by the user
    event Unstake(
        address indexed staker,
        uint256 stakedAmount
    );

    modifier onlyOwner() {
        require(
            msg.sender == contractOwner,
            "Must be contract owner to make call"
        );
        _;
    }

    modifier noActiveStake() {
        require(
            !_hasActiveStake(msg.sender),
            "Must not have active stake"
        );
        _;
    }
    modifier activeStake() {
        require(
            _hasActiveStake(msg.sender),
            "Must have an active stake"
        );
        _;
    }

    modifier hasMoneyInWithdrawPool() {
        require(
            withdrawPool[msg.sender] > 0,
            "Need to have non zero sum of money in withdrawal pool"
        );
        _;
    }

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _stakingToken the address of the token contract
    /// @param _minimumStake The minimum amount of tokens that need to be staked
    /// @param _payoutGap the number of blocks a stake must be present to earn 1 token from _stakingToken
    constructor(IERC20 _stakingToken, uint _minimumStake, uint _payoutGap)  {
        stakingToken = _stakingToken;
        minimumStake = _minimumStake;
        payoutGap = _payoutGap;
        contractOwner = msg.sender;
    }

    /// @notice Updates the Minimum Stake Amount
    /// @dev Only accessible to the contract's owner
    /// @param _stakeAmount The updated stake amount to qualify as minimum
    function setMinimumStake(uint256 _stakeAmount) external onlyOwner {
        minimumStake = _stakeAmount;
    }

    /// @notice Start a stake by depositing the required minimum tokens into the contract
    /// @dev modifier noActiveStake present to make sure user doesn't already have a stale present
    /// @param _stakeAmount the amount of tokens the user is willing to stake
    function stake(uint256 _stakeAmount) external payable noActiveStake {
        require(_stakeAmount >= minimumStake, "Staked amount too low");
        Erc20Utils.addTokensToContract(stakingToken, payable(msg.sender), _stakeAmount);
        UserStake memory _stake = UserStake(_stakeAmount, block.number, msg.sender, 0, true);
        stakeMap[msg.sender] = _stake;
        emit Stake(msg.sender, _stakeAmount);
    }

    /// @notice Claim Tokens earned as reward for staking
    /// @dev The function transfers the claimable tokens to the withdrawPool. withdrawFromPool will initiate the transfer
    function claim() external activeStake {
        uint claimableTokens = getClaimableToken(msg.sender);
        require(claimableTokens > 0, "0 claimable tokens present");
        UserStake storage _stake = stakeMap[msg.sender];
        _stake.claimed += claimableTokens;
        withdrawPool[msg.sender] += claimableTokens;
        emit Claim(msg.sender, claimableTokens);
    }

    /// @notice Unstake your tokens and exit the stake
    /// @dev The contract claims tokens for the users and adds the available claim to the withdrawPool in addition to the staked amount
    function unstake() external activeStake {
        UserStake storage _stake = stakeMap[msg.sender];
        uint claimableTokens = getClaimableToken(msg.sender);
        if (claimableTokens > 0) {
            _stake.claimed += claimableTokens;
            withdrawPool[msg.sender] += claimableTokens;
            emit Claim(msg.sender, claimableTokens);
        }
        _stake.stakeStatus = false;
        _stake.stakeStartBlockNumber = 0;
        _stake.claimed = 0;
        uint stakeAmt = _stake.stakeAmount;
        _stake.stakeAmount = 0;
        withdrawPool[msg.sender] += stakeAmt;
        emit Unstake(msg.sender, stakeAmt);
    }

    /// @notice This call allows anyone owed money by the contract to collect it by initiating a transfer to their account.
    /// @dev This call transfers all amount available in the withdrawPool for te caller to their account and resets it.
    function withdrawFromPool() external payable hasMoneyInWithdrawPool {
        address payable callerAddress = payable(msg.sender);
        uint256 amt = withdrawPool[msg.sender];
        withdrawPool[msg.sender] = 0;
        Erc20Utils.moveTokensFromContract(stakingToken, callerAddress, amt);
    }

    /// @notice Show the number of tokens available to claim
    /// @param _stakerAddress the address of the staker
    /// @return claimableTokens the number of tokens that can be claimed
    function getClaimableToken(address _stakerAddress) public view returns (uint claimableTokens){
        uint earnedTokens = getEarnedTokens(_stakerAddress);
        if (earnedTokens == 0) {
            return 0;
        }
        claimableTokens = SafeMath.sub(earnedTokens, stakeMap[_stakerAddress].claimed);
        return claimableTokens;
    }

    /// @notice Get the total amount of tokens earned upto this point. This includes claimed tokens as well.
    /// @param _stakerAddress The address of the staker involved
    /// @return earnedTokens The total amount of tokens earned
    function getEarnedTokens(address _stakerAddress) public view returns (uint earnedTokens) {
        UserStake memory staker = stakeMap[_stakerAddress];
        if (!stakeMap[_stakerAddress].stakeStatus) {
            return 0;
        }
        uint blockDiff = SafeMath.sub(block.number, staker.stakeStartBlockNumber);
        if (blockDiff <= payoutGap) {
            return 0;
        }
        earnedTokens = SafeMath.div(blockDiff, payoutGap);
        return earnedTokens;
    }

    function _hasActiveStake(address _userAddress) internal view returns (bool) {
        return (stakeMap[_userAddress].stakeStatus);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


library Erc20Utils {
    function addTokensToContract(
        IERC20 _token,
        address payable _payerAddress,
        uint _amount
    ) internal {
        require(_amount > 0, "Amount must be greater than 0");
        require(_token.transferFrom(_payerAddress, address(this), _amount), "Contract fails to receive payment");
    }

    function moveTokensFromContract(
        IERC20 _token,
        address payable _payeeAddress,
        uint _amount
    ) internal {
        require(_amount > 0, "Amount must be greater than 0");
        require(_token.transfer(_payeeAddress, _amount), "Token transfer to payer fails");
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