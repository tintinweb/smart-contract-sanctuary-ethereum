// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    event Debug(bool one, bool two, uint256 retsize);

    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    constructor(address _owner, Authority _authority) {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}
/**
 @title Balance Booster Module for Flywheel
 @notice Flywheel is a general framework for managing token incentives.
         It takes reward streams to various *strategies* such as staking LP tokens and divides them among *users* of those strategies.

         The Booster module is an optional module for virtually boosting or otherwise transforming user balances. 
         If a booster is not configured, the strategies ERC-20 balanceOf/totalSupply will be used instead.
        
         Boosting logic can be associated with referrals, vote-escrow, or other strategies.

         SECURITY NOTE: similar to how Core needs to be notified any time the strategy user composition changes, the booster would need to be notified of any conditions which change the boosted balances atomically.
         This prevents gaming of the reward calculation function by using manipulated balances when accruing.
*/
interface IFlywheelBooster {
    /**
      @notice calculate the boosted supply of a strategy.
      @param strategy the strategy to calculate boosted supply of
      @return the boosted supply
     */
    function boostedTotalSupply(ERC20 strategy) external view returns (uint256);

    /**
      @notice calculate the boosted balance of a user in a given strategy.
      @param strategy the strategy to calculate boosted balance of
      @param user the user to calculate boosted balance of
      @return the boosted balance
     */
    function boostedBalanceOf(ERC20 strategy, address user) external view returns (uint256);
}
/**
 @title Flywheel Core Incentives Manager
 @notice Flywheel is a general framework for managing token incentives.
         It takes reward streams to various *strategies* such as staking LP tokens and divides them among *users* of those strategies.

         The Core contract maintaings three important pieces of state:
         * the rewards index which determines how many rewards are owed per token per strategy. User indexes track how far behind the strategy they are to lazily calculate all catch-up rewards.
         * the accrued (unclaimed) rewards per user.
         * references to the booster and rewards module described below.

         Core does not manage any tokens directly. The rewards module maintains token balances, and approves core to pull transfer them to users when they claim.

         SECURITY NOTE: For maximum accuracy and to avoid exploits, rewards accrual should be notified atomically through the accrue hook. 
         Accrue should be called any time tokens are transferred, minted, or burned.
 */
contract FlywheelCore is Auth {
    using SafeTransferLib for ERC20;
    using SafeCastLib for uint256;

    /// @notice The token to reward
    ERC20 public immutable rewardToken;

    /// @notice append-only list of strategies added
    ERC20[] public allStrategies;

    /// @notice the rewards contract for managing streams
    IFlywheelRewards public flywheelRewards;

    /// @notice optional booster module for calculating virtual balances on strategies
    IFlywheelBooster public flywheelBooster;

    constructor(
        ERC20 _rewardToken,
        IFlywheelRewards _flywheelRewards,
        IFlywheelBooster _flywheelBooster,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        rewardToken = _rewardToken;
        flywheelRewards = _flywheelRewards;
        flywheelBooster = _flywheelBooster;
    }

    /*///////////////////////////////////////////////////////////////
                        ACCRUE/CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /** 
      @notice Emitted when a user's rewards accrue to a given strategy.
      @param strategy the updated rewards strategy
      @param user the user of the rewards
      @param rewardsDelta how many new rewards accrued to the user
      @param rewardsIndex the market index for rewards per token accrued
    */
    event AccrueRewards(ERC20 indexed strategy, address indexed user, uint256 rewardsDelta, uint256 rewardsIndex);

    /** 
      @notice Emitted when a user claims accrued rewards.
      @param user the user of the rewards
      @param amount the amount of rewards claimed
    */
    event ClaimRewards(address indexed user, uint256 amount);

    /// @notice The accrued but not yet transferred rewards for each user
    mapping(address => uint256) public rewardsAccrued;

    /** 
      @notice accrue rewards for a single user on a strategy
      @param strategy the strategy to accrue a user's rewards on
      @param user the user to be accrued
      @return the cumulative amount of rewards accrued to user (including prior)
    */
    function accrue(ERC20 strategy, address user) public returns (uint256) {
        RewardsState memory state = strategyState[strategy];

        if (state.index == 0) return 0;

        state = accrueStrategy(strategy, state);
        return accrueUser(strategy, user, state);
    }

    /** 
      @notice accrue rewards for a two users on a strategy
      @param strategy the strategy to accrue a user's rewards on
      @param user the first user to be accrued
      @param user the second user to be accrued
      @return the cumulative amount of rewards accrued to the first user (including prior)
      @return the cumulative amount of rewards accrued to the second user (including prior)
    */
    function accrue(
        ERC20 strategy,
        address user,
        address secondUser
    ) public returns (uint256, uint256) {
        RewardsState memory state = strategyState[strategy];

        if (state.index == 0) return (0, 0);

        state = accrueStrategy(strategy, state);
        return (accrueUser(strategy, user, state), accrueUser(strategy, secondUser, state));
    }

    /** 
      @notice claim rewards for a given user
      @param user the user claiming rewards
      @dev this function is public, and all rewards transfer to the user
    */
    function claimRewards(address user) external {
        uint256 accrued = rewardsAccrued[user];

        if (accrued != 0) {
            rewardsAccrued[user] = 0;

            rewardToken.safeTransferFrom(address(flywheelRewards), user, accrued);

            emit ClaimRewards(user, accrued);
        }
    }

    /*///////////////////////////////////////////////////////////////
                          ADMIN LOGIC
    //////////////////////////////////////////////////////////////*/

    /** 
      @notice Emitted when a new strategy is added to flywheel by the admin
      @param newStrategy the new added strategy
    */
    event AddStrategy(address indexed newStrategy);

    /// @notice initialize a new strategy
    function addStrategyForRewards(ERC20 strategy) external requiresAuth {
        _addStrategyForRewards(strategy);
    }

    function _addStrategyForRewards(ERC20 strategy) internal {
        require(strategyState[strategy].index == 0, "strategy");
        strategyState[strategy] = RewardsState({index: ONE, lastUpdatedTimestamp: block.timestamp.safeCastTo32()});

        allStrategies.push(strategy);
        emit AddStrategy(address(strategy));
    }

    function getAllStrategies() external view returns (ERC20[] memory) {
        return allStrategies;
    }

    /** 
      @notice Emitted when the rewards module changes
      @param newFlywheelRewards the new rewards module
    */
    event FlywheelRewardsUpdate(address indexed newFlywheelRewards);

    /// @notice swap out the flywheel rewards contract
    function setFlywheelRewards(IFlywheelRewards newFlywheelRewards) external requiresAuth {
        uint256 oldRewardBalance = rewardToken.balanceOf(address(flywheelRewards));
        if (oldRewardBalance > 0) {
            rewardToken.safeTransferFrom(address(flywheelRewards), address(newFlywheelRewards), oldRewardBalance);
        }

        flywheelRewards = newFlywheelRewards;

        emit FlywheelRewardsUpdate(address(newFlywheelRewards));
    }

    /** 
      @notice Emitted when the booster module changes
      @param newBooster the new booster module
    */
    event FlywheelBoosterUpdate(address indexed newBooster);

    /// @notice swap out the flywheel booster contract
    function setBooster(IFlywheelBooster newBooster) external requiresAuth {
        flywheelBooster = newBooster;

        emit FlywheelBoosterUpdate(address(newBooster));
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    struct RewardsState {
        /// @notice The strategy's last updated index
        uint224 index;
        /// @notice The timestamp the index was last updated at
        uint32 lastUpdatedTimestamp;
    }

    /// @notice the fixed point factor of flywheel
    uint224 public constant ONE = 1e18;

    /// @notice The strategy index and last updated per strategy
    mapping(ERC20 => RewardsState) public strategyState;

    /// @notice user index per strategy
    mapping(ERC20 => mapping(address => uint224)) public userIndex;

    /// @notice accumulate global rewards on a strategy
    function accrueStrategy(ERC20 strategy, RewardsState memory state)
        private
        returns (RewardsState memory rewardsState)
    {
        // calculate accrued rewards through module
        uint256 strategyRewardsAccrued = flywheelRewards.getAccruedRewards(strategy, state.lastUpdatedTimestamp);

        rewardsState = state;
        if (strategyRewardsAccrued > 0) {
            // use the booster or token supply to calculate reward index denominator
            uint256 supplyTokens = address(flywheelBooster) != address(0)
                ? flywheelBooster.boostedTotalSupply(strategy)
                : strategy.totalSupply();

            uint224 deltaIndex;

            if (supplyTokens != 0) deltaIndex = ((strategyRewardsAccrued * ONE) / supplyTokens).safeCastTo224();

            // accumulate rewards per token onto the index, multiplied by fixed-point factor
            rewardsState = RewardsState({
                index: state.index + deltaIndex,
                lastUpdatedTimestamp: block.timestamp.safeCastTo32()
            });
            strategyState[strategy] = rewardsState;
        }
    }

    /// @notice accumulate rewards on a strategy for a specific user
    function accrueUser(
        ERC20 strategy,
        address user,
        RewardsState memory state
    ) private returns (uint256) {
        // load indices
        uint224 strategyIndex = state.index;
        uint224 supplierIndex = userIndex[strategy][user];

        // sync user index to global
        userIndex[strategy][user] = strategyIndex;

        // if user hasn't yet accrued rewards, grant them interest from the strategy beginning if they have a balance
        // zero balances will have no effect other than syncing to global index
        if (supplierIndex == 0) {
            supplierIndex = ONE;
        }

        uint224 deltaIndex = strategyIndex - supplierIndex;
        // use the booster or token balance to calculate reward balance multiplier
        uint256 supplierTokens = address(flywheelBooster) != address(0)
            ? flywheelBooster.boostedBalanceOf(strategy, user)
            : strategy.balanceOf(user);

        // accumulate rewards by multiplying user tokens by rewardsPerToken index and adding on unclaimed
        uint256 supplierDelta = (supplierTokens * deltaIndex) / ONE;
        uint256 supplierAccrued = rewardsAccrued[user] + supplierDelta;

        rewardsAccrued[user] = supplierAccrued;

        emit AccrueRewards(strategy, user, supplierDelta, strategyIndex);

        return supplierAccrued;
    }
}

/**
 @title Rewards Module for Flywheel
 @notice Flywheel is a general framework for managing token incentives.
         It takes reward streams to various *strategies* such as staking LP tokens and divides them among *users* of those strategies.

         The Rewards module is responsible for:
         * determining the ongoing reward amounts to entire strategies (core handles the logic for dividing among users)
         * actually holding rewards that are yet to be claimed

         The reward stream can follow arbitrary logic as long as the amount of rewards passed to flywheel core has been sent to this contract.

         Different module strategies include:
         * a static reward rate per second
         * a decaying reward rate
         * a dynamic just-in-time reward stream
         * liquid governance reward delegation (Curve Gauge style)

         SECURITY NOTE: The rewards strategy should be smooth and continuous, to prevent gaming the reward distribution by frontrunning.
 */
interface IFlywheelRewards {
    /**
     @notice calculate the rewards amount accrued to a strategy since the last update.
     @param strategy the strategy to accrue rewards for.
     @param lastUpdatedTimestamp the last time rewards were accrued for the strategy.
     @return rewards the amount of rewards accrued to the market
    */
    function getAccruedRewards(ERC20 strategy, uint32 lastUpdatedTimestamp) external returns (uint256 rewards);

    /// @notice return the flywheel core address
    function flywheel() external view returns (FlywheelCore);

    /// @notice return the reward token associated with flywheel core.
    function rewardToken() external view returns (ERC20);
}


interface ICERC20 {
    function plugin() external returns (address);
}

interface IERC4626 {
    function claimRewards() external;
}

/** 
 @title Fuse Flywheel Plugin Reward Stream
 @notice Determines rewards based on how many reward tokens appeared in the market itself since last accrual.
 All rewards are claimed atomically, so there is no need to use the last reward timestamp.
*/
contract FuseFlywheelDynamicRewards is IFlywheelRewards {
    using SafeTransferLib for ERC20;

    event Log(string message);

    /// @notice the reward token paid
    ERC20 public immutable override rewardToken;

    /// @notice the flywheel core contract
    FlywheelCore public immutable flywheel;

    constructor(ERC20 _rewardToken, FlywheelCore _flywheel) {
        rewardToken = _rewardToken;
        flywheel = _flywheel;
        _rewardToken.safeApprove(address(_flywheel), type(uint256).max);
    }

    /**
     @notice calculate and transfer accrued rewards to flywheel core
     @param market the market to accrue rewards for
     @return amount the amount of tokens accrued and transferred
     */
    function getAccruedRewards(ERC20 market, uint32)
        external
        override
        returns (uint256 amount)
    {
        require(msg.sender == address(flywheel), "!flywheel");
        IERC4626 plugin = IERC4626(ICERC20(address(market)).plugin());
        try plugin.claimRewards() {} catch {
            emit Log("!plugin.claimRewards()");
        }
        amount = rewardToken.balanceOf(address(market));
        if (amount > 0)
            rewardToken.safeTransferFrom(
                address(market),
                address(this),
                amount
            );
    }
}