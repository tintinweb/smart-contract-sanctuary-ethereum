// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IFactory.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPair.sol";

/**
 * @title helper
 *
 * @notice to interact with core pool contracts
 *
 */

contract Helper {

    constructor(){}

    /**
     * @notice Returns adjusted information on the given deposit for the given address
     * @dev processing weight of Deposit structure
     *
     * @param pool address of pool
     * @param staker an address to query deposit for
     * @param depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getDeposit(address pool, address staker, uint256 depositId) public view returns (Deposit memory) {
        // read deposit at specified index and return
        Deposit memory deposit = IPool(pool).getOriginDeposit(staker, depositId);
        if(deposit.tokenAmount != 0){
            deposit.weight = deposit.weight / deposit.tokenAmount;
        }
        return deposit;
    }

    /**
     * @notice Returns all deposits for the given address
     *
     * @dev processing weight of Deposit structure
     *
     * @param pool address of pool
     * @param staker an address to query deposit for
     * @return all deposits
     */
    function getAllDeposit(address pool, address staker) public view returns (Deposit[] memory) {
        uint256 depositsLength = IPool(pool).getDepositsLength(staker);
        if(depositsLength == 0) {
            return new Deposit[](0);
        }
        // all deposits
        Deposit[] memory deposits = new Deposit[](depositsLength);
        for(uint256 i = 0; i < depositsLength; i++) {
            deposits[i] = IPool(pool).getOriginDeposit(staker, i);
            if(deposits[i].tokenAmount != 0){
                deposits[i].weight = deposits[i].weight / deposits[i].tokenAmount;
            }
        }
        return deposits;
    }

    /**
     * @dev return arrary of deposit which was created by the pool itself or as a yield reward
     *
     * @param pool address of pool
     * @param staker an address to query arrary of deposit for
     * @param isYield deposit was created by the pool itself or as a yield reward  
     *
     * @return param1(Array): array of deposit ID
     * @return param2(Array): array of deposits
     */
    function getDepositsByIsYield(address pool, address staker, bool isYield) public view returns (uint[] memory, Deposit[] memory) {
        uint256 depositsLength = IPool(pool).getDepositsLength(staker);
        if(depositsLength == 0) {
            return (new uint[](0), new Deposit[](0));
        }
        // length of Deposits By isYield
        uint256 lengthIsYield = 0;
        for(uint256 i = 0; i < depositsLength; i++) {
            if((IPool(pool).getOriginDeposit(staker, i)).isYield == isYield) {
                lengthIsYield++;
            }
        }
        // deposit ID
        uint [] memory depositsID = new uint[](lengthIsYield);
        // deposits
        Deposit[] memory deposits = new Deposit[](lengthIsYield);
        // j is the index of deposits
        uint j = 0;
        for(uint256 i = 0; i < depositsLength; i++) {
            if((IPool(pool).getOriginDeposit(staker, i)).isYield == isYield) {
                deposits[j] = IPool(pool).getOriginDeposit(staker, i);
                depositsID[j] = i;
                if(deposits[j].tokenAmount != 0){
                    deposits[j].weight = deposits[j].weight / deposits[j].tokenAmount;
                }
                j++;
            }
        }
        return (depositsID, deposits);
    }

    /**
     * @dev return calculated lockingWeight

     * @param pool address of pool
     * @param lockPeriod stake period as unix timestamp; zero means no locking  
     */
    function getLockingWeight(address pool, uint64 lockPeriod) public view returns (uint256) {
        // weightMultiplier
        uint256 weightMultiplier = IPool(pool).weightMultiplier();
        // stake weight formula rewards for locking
        uint256 stakeWeight =
            ((lockPeriod * weightMultiplier) / 365 days + weightMultiplier);
        return stakeWeight;
    }

    /**
     * @notice Returns predicted rewards
     *
     * @param factory address of factory
     * @param pool address of pool
     * @param amount amount of tokens to stake
     * @param lockPeriod stake period as unix timestamp; zero means no locking
     * @param forecastTime how many rewards we get after forecast time
     * @param yieldTime how many seconds Ethereum produces one block
     * @return predicted rewards
     */
    function getPredictedRewards(
        address factory,
        address pool,
        uint256 amount, 
        uint256 lockPeriod, 
        uint256 forecastTime, 
        uint256 yieldTime
    ) external view returns (uint256) {
        uint256 multiplier = forecastTime / yieldTime;
        if(amount == 0){
            return 0;
        }
        // poolToken
        address poolToken = IPool(pool).poolToken();
        // weightMultiplier
        uint256 weightMultiplier = IPool(pool).weightMultiplier();
        // poolWgight
        uint256 poolWeight = (IFactory(factory).getPoolData(poolToken)).weight;
        // stakeWeight
        uint256 stakeWeight = 0;
        // stake weight formula rewards for locking
        stakeWeight =
            ((lockPeriod * weightMultiplier) / 365 days + weightMultiplier) * amount;
        // makes sure stakeWeight is valid
        require(stakeWeight > 0, "invalid input");    
        uint256 cartRewards = (multiplier * poolWeight * IFactory(factory).cartPerBlock()) / IFactory(factory).totalWeight();
        // newUsersLockingWeight
        uint256 newUsersLockingWeight = IPool(pool).usersLockingWeight() + stakeWeight;
        uint256 rewardsPerWeight = IPool(pool).rewardToWeight(cartRewards, newUsersLockingWeight);
        return IPool(pool).weightToReward(stakeWeight, rewardsPerWeight);
    }

    /**
     * @notice Calculates current yield rewards value available for address specified
     *
     * @param factory address of factory
     * @param pool address of pool
     * @param staker an address to calculate yield rewards value for
     * @return calculated yield reward value for the given address
     */
    function pendingYieldRewards(address factory, address pool, address staker) public view returns (uint256) {
        // Used to calculate yield rewards
        uint256 yieldRewardsPerWeight = IPool(pool).yieldRewardsPerWeight();
        // `newYieldRewardsPerWeight` will store stored or recalculated value for `yieldRewardsPerWeight`
        uint256 newYieldRewardsPerWeight;
        // current block number
        uint256 blockNumber = block.number;
        // Block number of the last yield distribution event
        uint256 lastYieldDistribution = IPool(pool).lastYieldDistribution();
        // Used to calculate yield rewards, keeps track of the tokens weight locked in staking
        uint256 usersLockingWeight = IPool(pool).usersLockingWeight();
        // poolToken
        address poolToken = IPool(pool).poolToken();
        // poolWgight
        uint256 poolWeight = (IFactory(factory).getPoolData(poolToken)).weight;
        // if smart contract state was not updated recently, `yieldRewardsPerWeight` value
        // is outdated and we need to recalculate it in order to calculate pending rewards correctly
        if (blockNumber > lastYieldDistribution && usersLockingWeight != 0) {
            uint256 endBlock = IFactory(factory).endBlock();
            uint256 multiplier =
                blockNumber > endBlock ? endBlock - lastYieldDistribution : blockNumber - lastYieldDistribution;
            uint256 cartRewards = (multiplier * poolWeight * IFactory(factory).cartPerBlock()) / IFactory(factory).totalWeight();
            // recalculated value for `yieldRewardsPerWeight`
            newYieldRewardsPerWeight = IPool(pool).rewardToWeight(cartRewards, usersLockingWeight) + yieldRewardsPerWeight;
        } else {
            // if smart contract state is up to date, we don't recalculate
            newYieldRewardsPerWeight = yieldRewardsPerWeight;
        }
        // based on the rewards per weight value, calculate pending rewards;
        User memory user = IPool(pool).getUser(staker);
        uint256 pending = IPool(pool).weightToReward(user.totalWeight, newYieldRewardsPerWeight) - user.subYieldRewards;
        return pending;
    }

    /**
     * @dev lptoTokenAmount lp tokens passed in, and return amounts of two tokens 
     * 
     * function lptoTokenAmount(address lpAddress, uint256 lpAmount)
     * 
     * @param lpAddress lp地址
     * @param lpAmount lp数量
     * 
     * @return amount0 amounts of two tokens 
     * @return amount1 amounts of two tokens 
     * 
     */
    function lptoTokenAmount(address lpAddress, uint256 lpAmount) external view returns(uint256 amount0, uint256 amount1){
        uint lpSupply = IERC20(lpAddress).totalSupply();
        (uint112 reserve0, uint112 reserve1, ) = IPair(lpAddress).getReserves();
        uint amount0 = uint(reserve0) * lpAmount / lpSupply;
        uint amount1 = uint(reserve1) * lpAmount/ lpSupply;
        return (amount0, amount1);
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title Cart factory
 *
 * @notice An abstraction representing a factory, see CartPoolFactory for details
 *
 */
interface IFactory {

    struct PoolData {
        // @dev pool token address (like CART)
        address poolToken;
        // @dev pool address (like deployed core pool instance)
        address poolAddress;
        // @dev pool weight (200 for CART pools, 800 for CART/ETH pools - set during deployment)
        uint256 weight;
        // @dev flash pool flag
        bool isFlashPool;
    }

    function FACTORY_UID() external view returns (uint256);

    function CART() external view returns (address);

    function cartPerBlock() external view returns (uint256);
    
    function totalWeight() external view returns (uint256);

    function endBlock() external view returns (uint256);

    function getPoolData(address _poolToken) external view returns (PoolData memory);

    function getPoolAddress(address poolToken) external view returns (address);

    function isPoolExists(address _pool) external view returns (bool);
    
    function mintYieldTo(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
* @dev Data structure representing token holder using a pool
*/
struct User {
    // @dev Total staked amount
    uint256 tokenAmount;
    // @dev Total reward amount
    uint256 rewardAmount;
    // @dev Total weight
    uint256 totalWeight;
    // @dev Auxiliary variable for yield calculation
    uint256 subYieldRewards;
    // @dev An array of holder's deposits
    Deposit[] deposits;
}

/**
* @dev Deposit is a key data structure used in staking,
*      it represents a unit of stake with its amount, weight and term (time interval)
*/
struct Deposit {
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

/**
 * @title Cart Pool
 *
 * @notice An abstraction representing a pool, see CARTPoolBase for details
 *
 */
interface IPool {
    
    // for the rest of the functions see Soldoc in CARTPoolBase
    function CART() external view returns (address);

    function poolToken() external view returns (address);

    function isFlashPool() external view returns (bool);

    function weight() external view returns (uint256);

    function lastYieldDistribution() external view returns (uint256);

    function yieldRewardsPerWeight() external view returns (uint256);

    function usersLockingWeight() external view returns (uint256);

    function weightMultiplier() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function getDepositsLength(address _user) external view returns (uint256);

    function getOriginDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getUser(address _user) external view returns (User memory);

    function stake(
        uint256 _amount,
        uint64 _lockedUntil,
        address _nftAddress,
        uint256 _nftTokenId
    ) external;

    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external;

    function sync() external;

    function processRewards() external;

    function setWeight(uint256 _weight) external;

    function NFTWeightUpdated(address _nftAddress, uint256 _nftWeight) external;

    function setWeightMultiplierbyFactory(uint256 _newWeightMultiplier) external;

    function getNFTWeight(address _nftAddress) external view returns (uint256);

    function weightToReward(uint256 _weight, uint256 rewardPerWeight) external pure returns (uint256);

    function rewardToWeight(uint256 reward, uint256 rewardPerWeight) external pure returns (uint256);

}

pragma solidity 0.8.10;
interface IERC20 {

  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.5.0;

interface IPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}