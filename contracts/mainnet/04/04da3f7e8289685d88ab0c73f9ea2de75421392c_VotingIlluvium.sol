// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IERC20} from "./interfaces/staking/IERC20.sol";
import {ICorePoolV1, V1Stake} from "./interfaces/staking/ICorePoolV1.sol";
import {ICorePoolV2, V2Stake, V2User} from "./interfaces/staking/ICorePoolV2.sol";
import {IVesting} from "./interfaces/vesting/IVesting.sol";

contract VotingIlluvium {
    string public constant name = "Voting Illuvium";
    string public constant symbol = "vILV";

    uint256 public constant decimals = 18;

    address public constant ILV = 0x767FE9EDC9E0dF98E07454847909b5E959D7ca0E;
    address public constant ILV_POOL =
        0x25121EDDf746c884ddE4619b573A7B10714E2a36;
    address public constant ILV_POOL_V2 =
        0x7f5f854FfB6b7701540a00C69c4AB2De2B34291D;
    address public constant LP_POOL =
        0x8B4d8443a0229349A9892D4F7CbE89eF5f843F72;
    address public constant LP_POOL_V2 =
        0xe98477bDc16126bB0877c6e3882e3Edd72571Cc2;
    address public constant VESTING =
        0x6Bd2814426f9a6abaA427D2ad3FC898D2A57aDC6;

    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MAX_WEIGHT_MULTIPLIER = 2e6;
    uint256 internal constant BASE_WEIGHT = 1e6;
    uint256 internal constant MAX_STAKE_PERIOD = 365 days;

    function balanceOf(address _account)
        external
        view
        returns (uint256 balance)
    {
        // Get balance staked as deposits + yield in the v2 ilv pool
        uint256 ilvPoolV2Balance = ICorePoolV2(ILV_POOL_V2).balanceOf(_account);

        // Now we need to get deposits + yield in v1.
        // Copy the v2 user struct to memory and number of stakes in v2.
        V2User memory user = ICorePoolV2(ILV_POOL_V2).users(_account);
        uint256 userStakesLength = ICorePoolV2(ILV_POOL_V2).getStakesLength(
            _account
        );

        // Loop over each stake, compute its weight and add to v2StakedWeight
        uint256 v2StakedWeight;
        for (uint256 i = 0; i < userStakesLength; i++) {
            // Read stake in ilv pool v2 contract
            V2Stake memory stake = ICorePoolV2(ILV_POOL_V2).getStake(
                _account,
                i
            );
            // Computes stake weight based on lock period and balance
            uint256 stakeWeight = _getStakeWeight(stake);
            v2StakedWeight += stakeWeight;
        }
        // V1 yield balance can be determined by the difference of
        // the user total weight and the v2 staked weight.
        // any extra weight that isn't coming from v2 = v1YieldWeight
        uint256 v1YieldBalance = (user.totalWeight - v2StakedWeight) /
            MAX_WEIGHT_MULTIPLIER;

        // To finalize, we need to get the total amount of deposits
        // that are still in v1
        uint256 v1DepositBalance;
        // Loop over each v1StakeId stored in V2 contract.
        // Each stake id represents a deposit in v1
        for (uint256 i = 0; i < user.v1IdsLength; i++) {
            uint256 v1StakeId = ICorePoolV2(ILV_POOL_V2).getV1StakeId(
                _account,
                i
            );
            // Call v1 contract for deposit balance
            v1DepositBalance += (
                ICorePoolV1(ILV_POOL).getDeposit(_account, v1StakeId)
            ).tokenAmount;
        }

        // Now sum the queried ilv pool v2 balance with
        // the v1 yield balance and the v1 deposit balance
        // to have the final result
        uint256 totalILVPoolsBalance = ilvPoolV2Balance +
            v1YieldBalance +
            v1DepositBalance;

        // And simply query ILV normalized values from LP pools
        // V1 and V2
        uint256 lpPoolBalance = _lpToILV(
            ICorePoolV1(LP_POOL).balanceOf(_account)
        );
        uint256 lpPoolV2Balance = _lpToILV(
            ICorePoolV2(LP_POOL_V2).balanceOf(_account)
        );

        // We manually query index 0 because current vesting state in L1 is one position per address
        // If this changes we need to change the approach
        uint256 vestingBalance;

        try IVesting(VESTING).tokenOfOwnerByIndex(_account, 0) returns (
            uint256 vestingPositionId
        ) {
            vestingBalance = (IVesting(VESTING).positions(vestingPositionId))
                .balance;
        } catch Error(string memory) {}

        balance =
            totalILVPoolsBalance +
            lpPoolBalance +
            lpPoolV2Balance +
            vestingBalance;
    }

    function totalSupply() external view returns (uint256) {
        return IERC20(ILV).totalSupply();
    }

    function _lpToILV(uint256 _lpBalance)
        internal
        view
        returns (uint256 ilvAmount)
    {
        address _poolToken = ICorePoolV2(LP_POOL).poolToken();

        uint256 totalLP = IERC20(_poolToken).totalSupply();
        uint256 ilvInLP = IERC20(ILV).balanceOf(_poolToken);
        ilvAmount = (ilvInLP * _lpBalance) / totalLP;
    }

    function _getStakeWeight(V2Stake memory _stake)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                (((_stake.lockedUntil - _stake.lockedFrom) *
                    WEIGHT_MULTIPLIER) /
                    MAX_STAKE_PERIOD +
                    BASE_WEIGHT) * _stake.value
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct V1Stake {
    // @dev token amount staked
    uint256 tokenAmount;
    // @dev stake weight
    uint256 weight;
    // @dev locking period - from
    uint64 lockedFrom;
    // @dev locking period - until
    uint64 lockedUntil;
    // @dev indicates if the stake was created as a yield reward
    bool isYield;
}

struct V1User {
    // @dev Total staked amount
    uint256 tokenAmount;
    // @dev Total weight
    uint256 totalWeight;
    // @dev Auxiliary variable for yield calculation
    uint256 subYieldRewards;
    // @dev Auxiliary variable for vault rewards calculation
    uint256 subVaultRewards;
    // @dev An array of holder's deposits
    V1Stake[] deposits;
}

interface ICorePoolV1 {
    function users(address _who) external view returns (V1User memory);

    function balanceOf(address _user) external view returns (uint256);

    function getDeposit(address _from, uint256 _stakeId)
        external
        view
        returns (V1Stake memory);

    function poolToken() external view returns (address);

    function usersLockingWeight() external view returns (uint256);

    function poolTokenReserve() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @dev Data structure representing token holder using a pool.
struct V2User {
    /// @dev pending yield rewards to be claimed
    uint128 pendingYield;
    /// @dev pending revenue distribution to be claimed
    uint128 pendingRevDis;
    /// @dev Total weight
    uint248 totalWeight;
    /// @dev number of v1StakesIds
    uint8 v1IdsLength;
    /// @dev Checkpoint variable for yield calculation
    uint256 yieldRewardsPerWeightPaid;
    /// @dev Checkpoint variable for vault rewards calculation
    uint256 vaultRewardsPerWeightPaid;
}

struct V2Stake {
    /// @dev token amount staked
    uint120 value;
    /// @dev locking period - from
    uint64 lockedFrom;
    /// @dev locking period - until
    uint64 lockedUntil;
    /// @dev indicates if the stake was created as a yield reward
    bool isYield;
}

interface ICorePoolV2 {
    function users(address _user) external view returns (V2User memory);

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint32);

    function lastYieldDistribution() external view returns (uint64);

    function yieldRewardsPerWeight() external view returns (uint256);

    function globalWeight() external view returns (uint256);

    function pendingRewards(address _user)
        external
        view
        returns (uint256, uint256);

    function poolTokenReserve() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getTotalReserves() external view returns (uint256);

    function getStake(address _user, uint256 _stakeId)
        external
        view
        returns (V2Stake memory);

    function getV1StakeId(address _user, uint256 _position)
        external
        view
        returns (uint256);

    function getStakesLength(address _user) external view returns (uint256);

    function sync() external;

    function setWeight(uint32 _weight) external;

    function receiveVaultRewards(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/// @param balance total underlying balance
/// @param unlocked underlying value already unlocked
/// @param rate value unlocked per second, up to ~1.84e19 tokens per second
/// @param start when position starts unlocking
/// @param end when position unlocking ends
/// @param pendingRevDis pending revenue distribution share to be claimed
/// @param revDisPerTokenPaid last revDisPerToken applied to the position
struct Position {
    uint128 balance;
    uint128 unlocked;
    uint64 start;
    uint64 end;
    uint128 rate;
    uint128 pendingRevDis;
    uint256 revDisPerTokenPaid;
}

interface IVesting {
    /// @notice Returns locked token holders vesting positions
    /// @param _tokenId position nft identifier
    /// @return position the vesting position stored data
    function positions(uint256 _tokenId)
        external
        view
        returns (Position memory);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}