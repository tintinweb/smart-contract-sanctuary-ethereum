/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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

    /*///////////////////////////////////////////////////////////////
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
            bytes32 digest = keccak256(
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
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

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

    /*///////////////////////////////////////////////////////////////
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

    modifier requiresAuth() {
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
}

/**
 @title Rewards Module for Flywheel
 @notice The rewards module is a minimal interface for determining the quantity of rewards accrued to a flywheel market.

 Different module strategies include:
  * a static reward rate per second
  * a decaying reward rate
  * a dynamic just-in-time reward stream
  * liquid governance reward delegation
 */
interface IFlywheelRewards {
    function getAccruedRewards(ERC20 market, uint32 lastUpdatedTimestamp) external returns (uint256 rewards);
}
/**
 @title Balance Booster Module for Flywheel
 @notice An optional module for virtually boosting user balances. This allows a Flywheel Core to plug into some balance boosting logic.

 Boosting logic can be associated with referrals, vote-escrow, or other strategies. It can even be used to model exotic strategies like borrowing.
 */
interface IFlywheelBooster {
    function boostedTotalSupply(ERC20 market) external view returns(uint256);

    function boostedBalanceOf(ERC20 market, address user) external view returns(uint256);
}

/**
 @title Flywheel Core Incentives Manager
 @notice Flywheel is a general framework for managing token incentives.
         It is comprised of the Core (this contract), Rewards module, and optional Booster module.

         Core is responsible for maintaining reward accrual through reward indexes. 
         It delegates the actual accrual logic to the Rewards Module.

         For maximum accuracy and to avoid exploits, rewards accrual should be notified atomically through the accrue hook. 
         Accrue should be called any time tokens are transferred, minted, or burned.
 */
contract FlywheelCore is Auth {

    event AddMarket(address indexed newMarket);

    event FlywheelRewardsUpdate(address indexed oldFlywheelRewards, address indexed newFlywheelRewards);

    event AccrueRewards(ERC20 indexed cToken, address indexed owner, uint rewardsDelta, uint rewardsIndex);
    
    event ClaimRewards(address indexed owner, uint256 amount);

    struct RewardsState {
        /// @notice The market's last updated index
        uint224 index;

        /// @notice The timestamp the index was last updated at
        uint32 lastUpdatedTimestamp;
    }

    /// @notice The token to reward
    ERC20 public immutable rewardToken;

    /// @notice the rewards contract for managing streams
    IFlywheelRewards public flywheelRewards;

    /// @notice optional booster module for calculating virtual balances on markets
    IFlywheelBooster public immutable flywheelBooster;

    /// @notice the fixed point factor of flywheel
    uint224 public constant ONE = 1e18;

    /// @notice The market index and last updated per market
    mapping(ERC20 => RewardsState) public marketState;

    /// @notice user index per market
    mapping(ERC20 => mapping(address => uint224)) public userIndex;

    /// @notice The accrued but not yet transferred rewards for each user
    mapping(address => uint256) public rewardsAccrued;

    /// @dev immutable flag for short-circuiting boosting logic
    bool internal immutable applyBoosting;

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

        applyBoosting = address(_flywheelBooster) != address(0);
    }

    /// @notice initialize a new market
    function addMarketForRewards(ERC20 market) external requiresAuth {
        marketState[market] = RewardsState({
            index: ONE,
            lastUpdatedTimestamp: uint32(block.timestamp)
        });

        emit AddMarket(address(market));
    }

    /// @notice swap out the flywheel rewards contract
    function setFlywheelRewards(IFlywheelRewards newFlywheelRewards) external requiresAuth {
        address oldFlywheelRewards = address(flywheelRewards);

        flywheelRewards = newFlywheelRewards;

        emit FlywheelRewardsUpdate(oldFlywheelRewards, address(newFlywheelRewards));
    }

    /// @notice accrue rewards for a single user on a market
    function accrue(ERC20 market, address user) public returns (uint256) {
        RewardsState memory state = marketState[market];

        if (state.index == 0) return 0;

        state = accrueMarket(market, state);
        return accrueUser(market, user, state);
    }

    /// @notice accrue rewards for two users on a market
    function accrue(ERC20 market, address user, address secondUser) public returns (uint256, uint256) {
        RewardsState memory state = marketState[market];

        if (state.index == 0) return (0, 0);

        state = accrueMarket(market, state);
        return (accrueUser(market, user, state), accrueUser(market, secondUser, state));
    }

    /// @notice claim rewards for a given owner
    function claim(address owner) external {
        uint256 accrued = rewardsAccrued[owner];

        if (accrued != 0) {
            rewardsAccrued[owner] = 0;

            rewardToken.transfer(owner, accrued); 

            emit ClaimRewards(owner, accrued);
        }
    }

    /// @notice accumulate global rewards on a market
    function accrueMarket(ERC20 market, RewardsState memory state) private returns(RewardsState memory rewardsState) {
        // calculate accrued rewards through module
        uint256 marketRewardsAccrued = flywheelRewards.getAccruedRewards(market, state.lastUpdatedTimestamp);

        rewardsState = state;
        if (marketRewardsAccrued > 0) {
            // use the booster or token supply to calculate reward index denominator
            uint256 supplyTokens = applyBoosting ? flywheelBooster.boostedTotalSupply(market): market.totalSupply();

            // accumulate rewards per token onto the index, multiplied by fixed-point factor
            rewardsState = RewardsState({
                index: state.index + uint224(marketRewardsAccrued * ONE / supplyTokens),
                lastUpdatedTimestamp: uint32(block.timestamp)
            });
            marketState[market] = rewardsState;
        }
    }

    /// @notice accumulate rewards on a market for a specific user
    function accrueUser(ERC20 market, address user, RewardsState memory state) private returns (uint256) {
        // load indices
        uint224 supplyIndex = state.index;
        uint224 supplierIndex = userIndex[market][user];

        // sync user index to global
        userIndex[market][user] = supplyIndex;

        // if user hasn't yet accrued rewards, grant them interest from the market beginning if they have a balance
        // zero balances will have no effect other than syncing to global index
        if (supplierIndex == 0) {
            supplierIndex = ONE;
        }

        uint224 deltaIndex = supplyIndex - supplierIndex;
        // use the booster or token balance to calculate reward balance multiplier
        uint256 supplierTokens = applyBoosting ? flywheelBooster.boostedBalanceOf(market, user) : market.balanceOf(user);

        // accumulate rewards by multiplying user tokens by rewardsPerToken index and adding on unclaimed
        uint256 supplierDelta = supplierTokens * deltaIndex / ONE;
        uint256 supplierAccrued = rewardsAccrued[user] + supplierDelta;
        
        rewardsAccrued[user] = supplierAccrued;

        emit AccrueRewards(market, user, supplierDelta, supplyIndex);

        return supplierAccrued;
    }
}

contract FuseFlywheelCore is FlywheelCore {

    bool public constant isRewardsDistributor = true;

    constructor(
        ERC20 _rewardToken, 
        IFlywheelRewards _flywheelRewards, 
        IFlywheelBooster _flywheelBooster,
        address _owner,
        Authority _authority
    ) FlywheelCore(_rewardToken, _flywheelRewards, _flywheelBooster, _owner, _authority) {}

    function flywheelPreSupplierAction(ERC20 market, address supplier) external {
        accrue(market, supplier);  
    }

    function flywheelPreBorrowerAction(ERC20 market, address borrower) external {}

    function flywheelPreTransferAction(ERC20 market, address src, address dst) external {
        accrue(market, src, dst);
    }
}