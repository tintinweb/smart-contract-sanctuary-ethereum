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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details

contract FeeSelector {
    /**
        _decisionToken: token that is used to decide the fee
        upperBound: upper bound of the funding cost
        lowerBound
    */

    struct UserVotes {
        uint256 upperLong;
        uint256 lowerLong;
        uint256 upperShort;
        uint256 lowerShort;
    }

    IERC20 public decisionToken;

    struct PoolInfo {
        uint256 upperBound;
        uint256 lowerBound;
        uint256 upperTotal;
        uint256 lowerTotal;
    }

    PoolInfo public longPool;

    PoolInfo public shortPool;

    mapping(address => UserVotes) public userAcounts;

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

        decisionToken.transferFrom(
            msg.sender,
            address(this),
            upperAmount + lowerAmount
        );
    }

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

    /**
        Rate calculation formula:(longRate - shortRate)/ (maximum loan duration) * (target) + shortRate
        Returns the double for the duration.
     */
    function getFundingCostForDuration(
        uint256 loanDuration,
        uint256 maximumLoanDuration
    ) public view returns (uint256) {
        (uint256 longRate, uint256 shortRate) = getFundingCostRateFx();
        return
            ((longRate - shortRate) * loanDuration) /
            maximumLoanDuration +
            shortRate;
    }

    function getFundingCost(PoolInfo memory pool)
        public
        pure
        returns (uint256)
    {
        if (pool.upperTotal + pool.lowerTotal == 0) {
            return pool.lowerBound;
        }

        return
            (pool.upperBound *
                pool.upperTotal +
                pool.lowerBound *
                pool.lowerTotal) / (pool.upperTotal + pool.lowerTotal);
    }

    function getFundingCostRateFx() public view returns (uint256, uint256) {
        uint256 upper = getFundingCost(longPool);
        uint256 lower = getFundingCost(shortPool);

        return (upper, lower);
    }
}