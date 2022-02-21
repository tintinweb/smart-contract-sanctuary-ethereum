// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Type {
    /// @dev Voting power integrants
    struct Power {
        uint96 own; // voting power that remains after delegating to others
        uint96 delegated; // voting power delegated by others
    }
}

interface IVotingPowerSource {
    function power(address voter) external view returns (Type.Power memory);
}

/**
 * @title VotingPowerInformer
 * @notice It reads voting power data of a voter from the `Staking` contract
 * and returns votes of the voter computed by different methods.
 * @dev It's intended to serve data for off-chain voting via snapshot.org.
 * It provides latest blockchain data and does not count for snapshots.
 */
contract VotingPowerInformer {
    /// @notice Instance of the `Staking` contract
    address public immutable staking;

    // Special address the `Staking` uses to store global state
    address private constant GLOBAL_ACCOUNT = address(0);

    constructor(address _staking) {
        staking = _staking;
    }

    /// @notice Returns votes of a voter scaled to even number of tokens
    /// @dev "own" and "delegated" voting power summed up and scaled by 1e-18
    function getVotes(address voter)
        public
        view
        nonZeroAddress(voter)
        returns (uint256)
    {
        return _getPower(voter) / 1e18;
    }

    /// @notice Returns votes of all voters scaled to even number of tokens
    /// @dev "own" and "delegated" voting power summed up and scaled by 1e-18
    function getTotalVotes() public view returns (uint256) {
        return _getPower(GLOBAL_ACCOUNT) / 1e18;
    }

    /// @notice Returns votes of a voter unscaled
    /// (if a user staked 1 token, it returns 1e18)
    /// @dev "own" and "delegated" voting power summed up
    /// (function named so for compatibility with snapshot.org "strategies")
    function balanceOf(address voter)
        public
        view
        nonZeroAddress(voter)
        returns (uint256)
    {
        return _getPower(voter);
    }

    /// @notice Returns quadratic votes of a voter scaled to even number of tokens
    /// (w/o adjustment for the "voting power loss" on delegation)
    /// @dev sum of "own" and "delegated" power scaled by 1e-18
    function getQuadraticVotes(address voter)
        external
        view
        nonZeroAddress(voter)
        returns (uint256)
    {
        return sqrt(_getPower(voter) / 1e18);
    }

    /// @notice Returns quadratic votes of a voter scaled (to even number of tokens)
    /// and adjusted to compensate for "voting power loss" on delegation
    /// @dev sum of "own" and "delegated" power scaled by 1e-18
    // solhint-disable-next-line max-line-length
    // (see https://github.com/snapshot-labs/snapshot-strategies/blob/3b11de40a51a5b5db526cbdc07f965174a4e70c8/src/strategies/erc20-balance-of-quadratic-delegation/README.md)
    function getQuadraticAdjustedVotes(address voter)
        external
        view
        nonZeroAddress(voter)
        returns (uint256)
    {
        return _getQuadraticAdjustedVotes(voter);
    }

    /// @notice Returns all voters quadratic votes scaled (to even number of tokens)
    /// and adjusted to compensate for  "voting power loss" on delegation
    /// @dev Sum of square roots from "own" and "delegated" powers scaled by 1e-18
    // solhint-disable-next-line max-line-length
    // (see https://github.com/snapshot-labs/snapshot-strategies/blob/3b11de40a51a5b5db526cbdc07f965174a4e70c8/src/strategies/erc20-balance-of-quadratic-delegation/README.md)
    function getTotalQuadraticAdjustedVotes() external view returns (uint256) {
        return _getQuadraticAdjustedVotes(GLOBAL_ACCOUNT);
    }

    /// Internal and private functions follow

    function _getPower(address voter) internal view returns (uint256) {
        Type.Power memory power = IVotingPowerSource(staking).power(voter);
        return uint256(power.own) + uint256(power.delegated);
    }

    function _getQuadraticAdjustedVotes(address voter)
        internal
        view
        returns (uint256)
    {
        Type.Power memory power = IVotingPowerSource(staking).power(voter);
        uint256 credits = power.own / 1e18;
        uint256 delegated = power.delegated / 1e18;
        if (delegated != 0) {
            uint256 sqrtSum = sqrt(credits) + sqrt(delegated);
            credits = sqrtSum * sqrtSum;
        }
        return sqrt(credits);
    }

    // solhint-disable-next-line max-line-length
    // Source: https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    modifier nonZeroAddress(address voter) {
        require(
            voter != address(0),
            "VotingPowerInformer: unexpected zero address"
        );
        _;
    }
}