// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./coreInterfaces/IFeeSelector.sol";

contract FeeSelector is IFeeSelector {
    constructor(
        IERC20 _decisionToken,
        uint256 _upperBoundLong,
        uint256 _lowerBoundLong,
        uint256 _upperBoundShort,
        uint256 _lowerBoundShort
    ) {
        decisionToken = _decisionToken;
        longPool.upperBound = _upperBoundLong;
        longPool.lowerBound = _lowerBoundLong;

        shortPool.upperBound = _upperBoundShort;
        shortPool.lowerBound = _lowerBoundShort;
    }

    // @notice A user can call this address to cast their vote on the interest rates used by the protocol
    // @param  upperAmount  The amount of decisionToken casted to vote for the upper bound of the term of the interest rate
    // @param  lowerAmount  The amount of decisionToken casted to vote for the lower bound of the term of the interest rate
    // @param  isLong  Whether this vote is for the long term interest rate or short term interest rate
    function stake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong += upperAmount;
            userAcounts[msg.sender].lowerLong += lowerAmount;

            longPool.upperTotal += upperAmount;
            longPool.lowerTotal += lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort += upperAmount;
            userAcounts[msg.sender].lowerShort += lowerAmount;

            shortPool.upperTotal += upperAmount;
            shortPool.lowerTotal += lowerAmount;
        }

        decisionToken.transferFrom(msg.sender, address(this), upperAmount + lowerAmount);
    }

    // @notice A user can call this address to unstake the decisionToken from this contract and remove the casted votes
    // @param  upperAmount  The amount of decisionToken casted to vote for the upper bound of the term of the interest rate
    // @param  lowerAmount  The amount of decisionToken casted to vote for the lower bound of the term of the interest rate
    // @param  isLong  Whether this vote is for the long term interest rate or short term interest rate
    function unstake(
        uint256 upperAmount,
        uint256 lowerAmount,
        bool isLong
    ) public {
        if (isLong) {
            userAcounts[msg.sender].upperLong -= upperAmount;
            userAcounts[msg.sender].lowerLong -= lowerAmount;

            longPool.upperTotal -= upperAmount;
            longPool.lowerTotal -= lowerAmount;
        } else {
            userAcounts[msg.sender].upperShort -= upperAmount;
            userAcounts[msg.sender].lowerShort -= lowerAmount;

            shortPool.upperTotal -= upperAmount;
            shortPool.lowerTotal -= lowerAmount;
        }

        decisionToken.transfer(msg.sender, upperAmount + lowerAmount);
    }

    // @notice This function calculates the funding cost for a specified duration
    // @dev  Rate calculation formula:shortRate + (loanDuration) * (longRate - shortRate)/ (maximumLoanDuration)
    // @param  loanDuration  The duration of the loan
    // @param  maximumLoanDuration The maximum duration of the loan
    // @return The interest rate for the loanDuration
    function getFundingCostForDuration(uint256 loanDuration, uint256 maximumLoanDuration) external view override returns (uint256) {
        require(loanDuration <= maximumLoanDuration, "FeeSelector: loanDuration should be lt or eq to maximumLoanDuration");
        (uint256 longRate, uint256 shortRate) = getFundingCostRateFx();
        return ((longRate - shortRate) * loanDuration) / maximumLoanDuration + shortRate;
    }

    // @notice This function calculates the funding cost for a given term based on casted votes
    // @param  pool  The specified term of which the rate is being calculated
    // @return The interest rate for the term
    function getFundingCost(PoolInfo memory pool) public pure returns (uint256) {
        if (pool.upperTotal + pool.lowerTotal == 0) {
            return pool.lowerBound;
        }

        return (pool.upperBound * pool.upperTotal + pool.lowerBound * pool.lowerTotal) / (pool.upperTotal + pool.lowerTotal);
    }

    // @notice This function calculates the funding cost for the short duration and the long duration
    // @return The interest rate for the both short term and long term
    function getFundingCostRateFx() public view returns (uint256, uint256) {
        uint256 longTermRate = getFundingCost(longPool);
        uint256 shortTermRate = getFundingCost(shortPool);
        return (longTermRate, shortTermRate);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FeeSelectorStorage {
    // @notice A container that stores a user's votes toward different interest rates
    struct UserVotes {
        // @notice Upper bound of the long term interest rate
        uint256 upperLong;
        // @notice Lower bound of the long term interest rate
        uint256 lowerLong;
        // @notice Upper bound of the short term interest rate
        uint256 upperShort;
        // @notice Lower bound of the short term interest rate
        uint256 lowerShort;
    }

    // @notice A container that stores a pool level accumulated votes
    struct PoolInfo {
        // @notice Upper bound of the interest rate term
        uint256 upperBound;
        // @notice Lower bound of the interest rate term
        uint256 lowerBound;
        // @notice Total votes for the upper bound
        uint256 upperTotal;
        // @notice Total votes for the lower bound
        uint256 lowerTotal;
    }
    // @notice The ERC20 token that is used for voting
    IERC20 public decisionToken;
    // @notice The long term interest rate info
    PoolInfo public longPool;
    // @notice The short term interest rate info
    PoolInfo public shortPool;
    // @notice The global mapping of address to its accumulated votes
    mapping(address => UserVotes) public userAcounts;
}

abstract contract IFeeSelector is FeeSelectorStorage {
    function getFundingCostForDuration(uint256 loanDuration, uint256 maximumLoanDuration) external view virtual returns (uint256);
}