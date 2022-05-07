// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./CartPoolBase.sol";
import "./interfaces/IFactory.sol";

/**
 * @title CART Core Pool
 *
 * @notice Core pools represent permanent pools like CART or CART/ETH Pair pool,
 *      core pools allow staking for arbitrary periods of time up to 1 year
 *
 * @dev See CartPoolBase for more details
 *
 */
contract CartCorePool is CartPoolBase {
    /// @dev Flag indicating pool type, false means "core pool"
    bool public constant override isFlashPool = false;

    /// @dev Pool tokens value available in the pool;
    ///      pool token examples are CART (CART core pool) or CART/ETH pair (LP core pool)
    /// @dev For LP core pool
    ///      while for CART core pool it does count for such tokens as well
    uint256 public poolTokenReserve;

    /**
     * @dev Creates/deploys an instance of the core pool
     *
     * @param _cart CART ERC20 Token IlluviumERC20 address
     * @param _factory Pool factory CartPoolFactory address
     * @param _poolToken token the pool operates on, for example CART or CART/ETH pair
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _cart,
        address _factory,
        address _poolToken,
        uint256 _weight
    ) CartPoolBase(_cart, _factory, _poolToken, _weight) {}

    /**
     * @notice Service function to calculate
     *
     * @dev Internally executes similar function `_processRewards` from the parent smart contract
     *      to calculate and pay yield rewards
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when "staking as a pool" (`stakeAsPool`)
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function processRewards() external override nonReentrant{
        _processRewards(msg.sender, true);
        User storage user = users[msg.sender];
    }

    /**
     * @dev Executed internally by the pool itself (from the parent `CartPoolBase` smart contract)
     *      as part of yield rewards processing logic (`CartPoolBase._processRewards` function)
     *
     * @dev Because the reward in all pools should be regarded as a yield staking in CART token pool
     *      thus this function can only be excecuted within CART token pool
     *
     * @param _staker an address which stakes (the yield reward)
     * @param _amount amount to be staked (yield reward amount)
     */
    function stakeAsPool(address _staker, uint256 _amount) external {
        require(IFactory(factory).isPoolExists(msg.sender), "access denied");
        require(poolToken == CART, "not CART token pool");

        _sync();
        User storage user = users[_staker];
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }
        // if length of deposits is zero, then push zero value of unlocked deposit
        if (user.deposits.length == 0) {
            // create zero value of unlocked deposit and save the deposit (append it to deposits array)
            Deposit memory unlockedDeposit =
                Deposit({
                    tokenAmount: 0,
                    weight: 0,
                    lockedFrom: 0,
                    lockedUntil: 0,
                    isYield: false
                });
            user.deposits.push(unlockedDeposit);
        }
        // staking for a year, stakeWeight should be 2
        uint256 depositWeight = _amount * 2 * weightMultiplier;
        Deposit memory newDeposit =
            Deposit({
                tokenAmount: _amount,
                lockedFrom: uint64(now256()),
                lockedUntil: uint64(now256() + 365 days),
                weight: depositWeight,
                isYield: true
            });
        user.tokenAmount += _amount;
        user.rewardAmount += _amount;
        user.totalWeight += depositWeight;
        user.deposits.push(newDeposit);

        usersLockingWeight += depositWeight;

        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update `poolTokenReserve` only if this is a LP Core Pool (stakeAsPool can be executed only for LP pool)
        poolTokenReserve += _amount;
    }
    
    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockPeriod,
        address _nftAddress,
        uint256 _nftTokenId
    ) internal override {
        super._stake(_staker, _amount, _lockPeriod, _nftAddress, _nftTokenId);
        User storage user = users[_staker];

        poolTokenReserve += _amount;
    }

    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal override {
        User storage user = users[_staker];
        Deposit memory stakeDeposit = user.deposits[_depositId];
        require(stakeDeposit.lockedFrom == 0 || now256() > stakeDeposit.lockedUntil, "deposit not yet unlocked");
        poolTokenReserve -= _amount;
        super._unstake(_staker, _depositId, _amount);
    }

    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and updates (decreases) pool token reserve (pool tokens value available in the pool)
     */
    function _emergencyWithdraw(
        address _staker
    ) internal override {
        User storage user = users[_staker];
        uint256 amount = user.tokenAmount;

        poolTokenReserve -= amount;
        super._emergencyWithdraw(_staker);
    }

    /**
     * @inheritdoc CartPoolBase
     *
     * @dev Additionally to the parent smart contract
     *      and for CART pool updates (increases) pool token reserve (pool tokens value available in the pool)
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal override returns (uint256 pendingYield) {
        pendingYield = super._processRewards(_staker, _withUpdate);
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a CART token
     *
     */
    function transferCartToken(address _to, uint256 _value) internal {
        // just delegate call to the target
        SafeERC20.safeTransfer(IERC20(CART), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a CART token
     *
     */
    function transferCartTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // just delegate call to the target
        SafeERC20.safeTransferFrom(IERC20(CART), _from, _to, _value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IPool.sol";
import "./interfaces/ICorePool.sol";
import "./interfaces/ITokenRecipient.sol";
import "./interfaces/IFactory.sol";

/**
 * @title Cart Pool Base
 *
 * @notice An abstract contract containing common logic for a core pool (permanent pool like CART/ETH or CART pool)
 *
 * @dev Deployment and initialization.
 *      Any pool deployed must be bound to the deployed pool factory (CartPoolFactory)
 *      Additionally, 3 token instance addresses must be defined on deployment:
 *          - CART token address
 *          - pool token address, it can be CART token address, CART/ETH pair address, and others
 *
 * @dev Pool weight defines the fraction of the yield current pool receives among the other pools,
 *      pool factory is responsible for the weight synchronization between the pools.
 * @dev The weight is logically 20% for CART pool and 80% for CART/ETH pool.
 *      Since Solidity doesn't support fractions the weight is defined by the division of
 *      pool weight by total pools weight (sum of all registered pools within the factory)
 * @dev For CART Pool we use 200 as weight and for CART/ETH pool - 800.
 *
 */
abstract contract CartPoolBase is IPool, ReentrancyGuard, ITokenRecipient {
    
    /// @dev Link to CART STREET ERC20 Token instance
    address public immutable override CART;

    /// @dev Token holder storage, maps token holder address to their data record
    mapping(address => User) public users;

    /// @dev Link to the pool factory CartPoolFactory addresss
    address public immutable factory;

    /// @dev Link to the pool token instance, for example CART or CART/ETH pair
    address public immutable override poolToken;

    /// @dev Pool weight, 200 for CART pool or 800 for CART/ETH
    uint256 public override weight;

    /// @dev Block number of the last yield distribution event
    uint256 public override lastYieldDistribution;

    /// @dev Used to calculate yield rewards
    /// @dev This value is different from "reward per token" used in locked pool
    /// @dev Note: stakes are different in duration and "weight" reflects that
    uint256 public override yieldRewardsPerWeight;

    /// @dev Used to calculate yield rewards, keeps track of the tokens weight locked in staking
    uint256 public override usersLockingWeight;

    /// @dev Support for specified NFT whitelist address, True representing this NFT can be staked
    mapping(address => uint256) public supportNTF;

    /**
     * @dev Stake weight is proportional to deposit amount and time locked, precisely
     *      "deposit amount wei multiplied by (fraction of the year locked plus one)"
     * @dev To avoid significant precision loss due to multiplication by "fraction of the year" [0, 1],
     *      weight is stored multiplied by 1e24 constant, as an integer
     * @dev Corner case 1: if time locked is zero, weight is deposit amount multiplied by 1e24
     * @dev Corner case 2: if time locked is one year, fraction of the year locked is one, and
     *      weight is a deposit amount multiplied by 2 * 1e24
     */
    uint256 public weightMultiplier;

    /**
     * @dev Rewards per weight are stored multiplied by 1e48, as integers.
     */
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e48;

    /**
     * @dev We want to get deposits batched but not one by one, thus here is define the size of each batch.
     */
    uint256 internal constant DEPOSIT_BATCH_SIZE  = 20;

    /**
     * @dev Fired in _stake() and stake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _from token holder address, the tokens will be returned to that address
     * @param amount amount of tokens staked
     */
    event Staked(address indexed _by, address indexed _from, uint256 amount);


    /**
     * @dev Fired in _unstake() and unstake()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param _to an address which received the unstaked tokens, usually token holder
     * @param amount amount of tokens unstaked
     */
    event Unstaked(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in _sync(), sync() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param yieldRewardsPerWeight updated yield rewards per weight value
     * @param lastYieldDistribution usually, current block number
     */
    event Synchronized(address indexed _by, uint256 yieldRewardsPerWeight, uint256 lastYieldDistribution);

    /**
     * @dev Fired in _processRewards(), processRewards() and dependent functions (stake, unstake, etc.)
     *
     * @param _by an address which performed an operation
     * @param _to an address which claimed the yield reward
     * @param amount amount of yield paid
     */
    event YieldClaimed(address indexed _by, address indexed _to, uint256 amount);

    /**
     * @dev Fired in setWeight()
     *
     * @param _fromVal old pool weight value
     * @param _toVal new pool weight value
     */
    event PoolWeightUpdated(uint256 _fromVal, uint256 _toVal);

    /**
     * @dev Fired in _emergencyWithdraw()
     *
     * @param _by an address which performed an operation, usually token holder
     * @param amount amount of tokens withdraw
     */
    event EmergencyWithdraw(address indexed _by, uint256 amount);

    /**
     * @dev Overridden in sub-contracts to construct the pool
     *
     * @param _cart CART ERC20 Token IlluviumERC20 address
     * @param _factory Pool factory CartPoolFactory address
     * @param _poolToken token the pool operates on, for example CART or CART/ETH pair
     * @param _weight number representing a weight of the pool, actual weight fraction
     *      is calculated as that number divided by the total pools weight and doesn't exceed one
     */
    constructor(
        address _cart,
        address _factory,
        address _poolToken,
        uint256 _weight
    ) {
        // verify the inputs are set
        require(_cart != address(0), "cart token address not set");
        require(_factory != address(0), "CART Pool fct address not set");
        require(_poolToken != address(0), "pool token address not set");
        require(_weight > 0, "pool weight not set");

        // verify CartPoolFactory instance supplied
        require(
            IFactory(_factory).FACTORY_UID() == 0xb77099a6d99df5887a6108e413b3c6dfe0c11a1583c9d9b3cd08bfb8ca996aef,
            "unexpected FACTORY_UID"
        );

        // save the inputs into internal state variables
        CART = _cart;
        factory = _factory;
        poolToken = _poolToken;
        weight = _weight;
        weightMultiplier = 1e24;
    }

    /**
     * @notice Returns total staked token balance for the given address
     *
     * @param _user an address to query balance for
     * @return total staked token balance
     */
    function balanceOf(address _user) external view override returns (uint256) {
        // read specified user token amount and return
        return users[_user].tokenAmount;
    }

    /**
     * @notice Returns origin information on the given deposit for the given address
     *
     * @dev See getDepositsLength
     *
     * @param _user an address to query deposit for
     * @param _depositId zero-indexed deposit ID for the address specified
     * @return deposit info as Deposit structure
     */
    function getOriginDeposit(address _user, uint256 _depositId) external view override returns (Deposit memory) {
        // read deposit at specified index and return
        return users[_user].deposits[_depositId];
    } 

    /**
     * @notice Returns number of deposits for the given address. Allows iteration over deposits.
     *
     * @dev See getDeposit
     *
     * @param _user an address to query deposit length for
     * @return number of deposits for the given address
     */
    function getDepositsLength(address _user) external view override returns (uint256) {
        // read deposits array length and return
        return users[_user].deposits.length;
    }
    
    /**
     * @notice Returns weight of NFT
     *
     * @param _nftAddress an address to query weight of NFT
     * @return weight of NFT
     */
    function getNFTWeight(address _nftAddress) external view returns (uint256) {
        // return weight of NFT
        return supportNTF[_nftAddress];
    }

    /**
     * @notice Returns structure of user
     *
     * @param _user an address to query deposit length for
     * @return user data structure
     */
    function getUser(address _user) external view returns (User memory) {
        return users[_user];
    }

    /**
     * @notice TokenRecipient. if got cart tokens, it will receive and stake.
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _data include stake period, NFT address, NFT Token ID.
     */
    function tokensReceived(address _staker, uint _amount, bytes calldata _data) external override nonReentrant returns (bool) {
        require(msg.sender == CART, "must from cart");
        require(_data.length == 60, "length of bytes error");

        // stake period as unix timestamp; zero means no locking
        uint64 _lockPeriod = uint64(toUint(_data, 0));
        address _nftAddress = address(toBytes20(_data, 20));
        uint _nftTokenId = toUint(_data, 40);
    
        _stake(_staker, _amount, _lockPeriod, _nftAddress, _nftTokenId);
        return true;
    }
    
    /**
     * @notice to 20 bytes
     *
     * @param _b bytes 
     * @param _offset initial position to processing
     */
    function toBytes20(bytes memory _b, uint _offset) private pure returns (bytes20) {
        bytes20 out;
        for (uint i = 0; i < 20; i++) {
        out |= bytes20(_b[_offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    /**
     * @notice bytes to uint
     *
     * @param _b bytes 
     * @param _offset initial position to processing
     */
    function toUint(bytes memory _b, uint _offset) private pure returns (uint) {
        uint out;
        for(uint i = 0; i < 20; i++){
        out = out + uint8(_b[_offset + i])*(2**(8*(20-(i+1))));
        }
        return out;
    }

    /**
     * @notice Stakes specified amount of tokens for the specified amount of time,
     *      and pays pending yield rewards if any
     *
     * @dev Requires amount to stake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _amount amount of tokens to stake
     * @param _lockPeriod stake period as unix timestamp; zero means no locking
     * @param _nftAddress supported nft address
     * @param _nftTokenId users hold nft tokenId
     */
    function stake (
        uint256 _amount,
        uint64 _lockPeriod,
        address _nftAddress,
        uint256 _nftTokenId
    ) external override nonReentrant {
        // transfer `_amount`
        transferPoolTokenFrom(msg.sender, address(this), _amount);
        // delegate call to an internal function
        _stake(msg.sender, _amount, _lockPeriod, _nftAddress, _nftTokenId);
    }

    /**
     * @notice Unstakes specified amount of tokens, and pays pending yield rewards if any
     *
     * @dev Requires amount to unstake to be greater than zero
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function unstake(
        uint256 _depositId,
        uint256 _amount
    ) external override nonReentrant {
        // delegate call to an internal function
        _unstake(msg.sender, _depositId, _amount);
    }

    /**
     * @notice Service function to synchronize pool state with current time
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      at least one block passes between synchronizations
     * @dev Executed internally when staking, unstaking, processing rewards in order
     *      for calculations to be correct and to reflect state progress of the contract
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     */
    function sync() external override {
        // delegate call to an internal function
        _sync();
    }

    /**
     * @notice Service function to calculate and pay pending yield rewards to the sender
     *
     * @dev Can be executed by anyone at any time, but has an effect only when
     *      executed by deposit holder and when at least one block passes from the
     *      previous reward processing
     * @dev Executed internally when staking and unstaking, executes sync() under the hood
     *      before making further calculations and payouts
     * @dev When timing conditions are not met (executed too frequently, or after factory
     *      end block), function doesn't throw and exits silently
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function processRewards() external virtual override nonReentrant {
        // delegate call to an internal function
        _processRewards(msg.sender, true);
    }

    /**
     * @dev Executed by the factory to modify pool weight; the factory is expected
     *      to keep track of the total pools weight when updating
     *
     * @dev Set weight to zero to disable the pool
     *
     * @param _weight new weight to set for the pool
     */
    function setWeight(uint256 _weight) external override {
        // verify function is executed by the factory
        require(msg.sender == factory, "access denied");

        // emit an event logging old and new weight values
        emit PoolWeightUpdated(weight, _weight);

        // set the new weight value
        weight = _weight;
    }

    /**
     * @dev Executed by the factory to modify NFTWeight
     *
     * @dev Set new weight to the NFT address
     *
     * @param _nftAddress address of NFT
     * @param _nftWeight weight of NFT
     */
    function NFTWeightUpdated(address _nftAddress, uint256 _nftWeight) external {
        // verify function is executed by the factory
        require(msg.sender == factory, "access denied");
        // set new weight of NFT
        supportNTF[_nftAddress] = _nftWeight;
    }

    /**
     * @dev Executed by the factory to modify weightMultiplier
     *
     * @dev Set new weight to weightMultiplier
     *
     * @param _newWeightMultiplier new weightMultiplier
     */
    function setWeightMultiplierbyFactory(uint256 _newWeightMultiplier) external {
        // verify function is executed by the factory
        require(msg.sender == factory, "access denied");
        // set the new weight multiplier
        weightMultiplier = _newWeightMultiplier;
    }

    /**
     * @dev Similar to public pendingYieldRewards, but performs calculations based on
     *      current smart contract state only, not taking into account any additional
     *      time/blocks which might have passed
     *
     * @param _staker an address to calculate yield rewards value for
     * @return pending calculated yield reward value for the given address
     */
    function _pendingYieldRewards(address _staker) internal view returns (uint256 pending) {
        // read user data structure into memory
        User memory user = users[_staker];

        // and perform the calculation using the values read
        return weightToReward(user.totalWeight, yieldRewardsPerWeight) - user.subYieldRewards;
    }

    /**
     * @dev Used internally, mostly by children implementations, see stake()
     *
     * @param _staker an address which stakes tokens and which will receive them back
     * @param _amount amount of tokens to stake
     * @param _lockPeriod stake period as unix timestamp; zero means no locking 
     * @param _nftAddress supported nft address, zero means no NFT token
     * @param _nftTokenId users hold nft tokenId, zero means no NFT token
     */
    function _stake(
        address _staker,
        uint256 _amount,
        uint64 _lockPeriod,
        address _nftAddress,
        uint256 _nftTokenId
    ) internal virtual {
        // validate the inputs

        require(_amount > 0, "zero amount");
        require(_lockPeriod == 0 || _lockPeriod <= 365 days,"invalid lock interval");
 
        // update smart contract state
        _sync();

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // process current pending rewards if any
        if (user.tokenAmount > 0) {
            _processRewards(_staker, false);
        }

        // if length of deposits is zero, then push zero value of unlocked deposit
        if (user.deposits.length == 0) {
            // create zero value of unlocked deposit and save the deposit (append it to deposits array)
            Deposit memory unlockedDeposit =
                Deposit({
                    tokenAmount: 0,
                    weight: 0,
                    lockedFrom: 0,
                    lockedUntil: 0,
                    isYield: false
                });
            user.deposits.push(unlockedDeposit);
        }

        // zero value for `_lockPeriod` means "no locking" and leads to zero values
        uint64 lockFrom = uint64(now256());
        uint64 lockPeriod = _lockPeriod;

        // stakeWeight
        uint256 stakeWeight = ((lockPeriod * weightMultiplier) / 365 days + weightMultiplier) * _amount;

        // makes sure stakeWeight is valid
        require(stakeWeight > 0, "invalid stakeWeight");    

        // if the user has new unlocked stake, deposit will merge it
        if (lockPeriod == 0) {
            // init weight of NFT
            uint nft_weight = 0;
            // if the user hold the right NFT tokenId, nft_weight will increase
            if (_nftTokenId != 0 && _nftAddress != address(0) ) {
                require(IERC721(_nftAddress).ownerOf(_nftTokenId) == msg.sender, "the NFT tokenId doesn't match the user");
                nft_weight = supportNTF[_nftAddress];
            }
            
            // old stakeWeight
            uint256 oldStakeWeight = user.deposits[0].weight;
            // new stakeWeight, only check user's NFT info for unlocked deposit
            uint256 newStakeWeight = oldStakeWeight + _amount * weightMultiplier + nft_weight * weightMultiplier;
            // the stake is currently unlocked 
            user.deposits[0].tokenAmount += _amount;
            user.deposits[0].weight = newStakeWeight;
            user.deposits[0].lockedFrom = 0;

            // update user record
            user.tokenAmount += _amount;
            user.totalWeight = (user.totalWeight - oldStakeWeight + newStakeWeight);
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

            // update global variable
            usersLockingWeight = (usersLockingWeight - oldStakeWeight + newStakeWeight);
        } else {
            // the stake is currently locking
            // create and save the deposit (append it to deposits array)
            Deposit memory deposit =
                Deposit({
                    tokenAmount: _amount,
                    weight: stakeWeight,
                    lockedFrom: lockFrom,
                    lockedUntil: lockFrom + lockPeriod,
                    isYield: false
                });
            // deposit ID is an index of the deposit in `deposits` array
            user.deposits.push(deposit);

            // update user record
            user.tokenAmount += _amount;
            user.totalWeight += stakeWeight;
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

            // update global variable
            usersLockingWeight += stakeWeight;
        }

        // emit an event
        emit Staked(msg.sender, _staker, _amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see unstake()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     * @param _depositId deposit ID to unstake from, zero-indexed
     * @param _amount amount of tokens to unstake
     */
    function _unstake(
        address _staker,
        uint256 _depositId,
        uint256 _amount
    ) internal virtual {
        // verify an amount is set
        require(_amount > 0, "zero amount");

        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];
        // get a link to the corresponding deposit, we may write to it later
        Deposit storage stakeDeposit = user.deposits[_depositId];
        // deposit structure may get deleted, so we save isYield flag to be able to use it
        bool isYield = stakeDeposit.isYield;

        // verify available balance
        // if staker address ot deposit doesn't exist this check will fail as well
        require(stakeDeposit.tokenAmount >= _amount, "amount exceeds stake");

        // update smart contract state
        _sync();
        // and process current pending rewards if any
        _processRewards(_staker, false);

        // recalculate deposit weight
        uint256 previousWeight = stakeDeposit.weight;
        uint256 newWeight =
            (((stakeDeposit.lockedUntil - stakeDeposit.lockedFrom) * weightMultiplier) /
                365 days +
                weightMultiplier) * (stakeDeposit.tokenAmount - _amount);

        // update the deposit, or delete it if its depleted
        if (stakeDeposit.tokenAmount == _amount) {
            //set all deposits value to zero (default)
            delete user.deposits[_depositId];
        } else {
            stakeDeposit.tokenAmount -= _amount;
            stakeDeposit.weight = newWeight;
        }

        // update user record
        user.tokenAmount -= _amount;
        user.totalWeight = user.totalWeight - previousWeight + newWeight;
        user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);

        // update global variable
        usersLockingWeight = usersLockingWeight - previousWeight + newWeight;

        // if the deposit was created by the pool itself as a yield reward
        if (isYield) {
            user.rewardAmount -= _amount;
            // mint the yield via the factory
            IFactory(factory).mintYieldTo(msg.sender, _amount);
        } else {
            // otherwise just return tokens back to holder, staking for a year
            transferPoolToken(msg.sender, _amount);
        }

        // emit an event
        emit Unstaked(msg.sender, _staker, _amount);
    }

    /**
     * @notice Emergency withdraw specified amount of tokens
     *
     *
     * @dev Reentrancy safety enforced via `ReentrancyGuard.nonReentrant`
     *
     */
    function emergencyWithdraw() external nonReentrant {
        require(IFactory(factory).totalWeight() == 0, "totalWeight != 0");

        // delegate call to an internal function
        _emergencyWithdraw(msg.sender);
    }

    /**
     * @dev Used internally, mostly by children implementations, see emergencyWithdraw()
     *
     * @param _staker an address which unstakes tokens (which previously staked them)
     */
    function _emergencyWithdraw(
        address _staker
    ) internal virtual {
        // get a link to user data struct, we will write to it later
        User storage user = users[_staker];

        uint256 totalWeight = user.totalWeight ;
        uint256 amount = user.tokenAmount;
        uint256 reward = user.rewardAmount;

        // update user record
        user.tokenAmount = 0;
        user.rewardAmount = 0;
        user.totalWeight = 0;
        user.subYieldRewards = 0;

        // delete entire array directly
        delete user.deposits;

        // update global variable
        usersLockingWeight = usersLockingWeight - totalWeight;

        // just return tokens back to holder
        transferPoolToken(msg.sender, amount - reward);
        // mint the yield via the factory
        IFactory(factory).mintYieldTo(msg.sender, reward);

        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @dev Used internally, mostly by children implementations, see sync()
     *
     * @dev Updates smart contract state (`yieldRewardsPerWeight`, `lastYieldDistribution`),
     */
    function _sync() internal virtual {

        // Initialize lastYieldDistribution when the first stake
        if (lastYieldDistribution == 0) {
            lastYieldDistribution = blockNumber();
        }
        // check bound conditions and if these are not met -
        // exit silently, without emitting an event
        uint256 endBlock = IFactory(factory).endBlock();
        if (lastYieldDistribution >= endBlock) {
            return;
        }
        if (blockNumber() <= lastYieldDistribution) {
            return;
        }
        // if locking weight is zero - update only `lastYieldDistribution` and exit
        if (usersLockingWeight == 0) {
            lastYieldDistribution = blockNumber();
            return;
        }

        // to calculate the reward we need to know how many blocks passed, and reward per block
        uint256 currentBlock = blockNumber() > endBlock ? endBlock : blockNumber();
        uint256 blocksPassed = currentBlock - lastYieldDistribution;
        uint256 cartPerBlock = IFactory(factory).cartPerBlock();

        // calculate the reward
        uint256 cartReward = (blocksPassed * cartPerBlock * weight) / IFactory(factory).totalWeight();

        // update rewards per weight and `lastYieldDistribution`
        yieldRewardsPerWeight += rewardToWeight(cartReward, usersLockingWeight);
        lastYieldDistribution = currentBlock;

        // emit an event
        emit Synchronized(msg.sender, yieldRewardsPerWeight, lastYieldDistribution);
    }

    /**
     * @dev Used internally, mostly by children implementations, see processRewards()
     *
     * @param _staker an address which receives the reward (which has staked some tokens earlier)
     * @param _withUpdate flag allowing to disable synchronization (see sync()) if set to false
     * @return pendingYield the rewards calculated and optionally re-staked
     */
    function _processRewards(
        address _staker,
        bool _withUpdate
    ) internal virtual returns (uint256 pendingYield) {
        // update smart contract state if required
        if (_withUpdate) {
            _sync();
        }

        // calculate pending yield rewards, this value will be returned
        pendingYield = _pendingYieldRewards(_staker);

        // if pending yield is zero - just return silently
        if (pendingYield == 0) return 0;

        // get link to a user data structure, we will write into it later
        User storage user = users[_staker];

        if (poolToken == CART) {
            // mint the yield via the factory
            IFactory(factory).mintYieldTo(_staker, pendingYield);
        } else {
            // for other pools - stake as pool
            address cartPool = IFactory(factory).getPoolAddress(CART);
            require(cartPool != address(0),"invalid cart pool address");
            ICorePool(cartPool).stakeAsPool(_staker, pendingYield);
        }

        // update users's record for `subYieldRewards` if requested
        if (_withUpdate) {
            user.subYieldRewards = weightToReward(user.totalWeight, yieldRewardsPerWeight);
        }

        // emit an event
        emit YieldClaimed(msg.sender, _staker, pendingYield);
    }


    /**
     * @dev Converts stake weight (not to be mixed with the pool weight) to
     *      CART reward value, applying the 10^48 division on weight
     *
     * @param _weight stake weight
     * @param rewardPerWeight CART reward per weight
     * @return reward value normalized to 10^48
     */
    function weightToReward(uint256 _weight, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the formula and return
        return (_weight * rewardPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    /**
     * @dev Converts reward CART value to stake weight (not to be mixed with the pool weight),
     *      applying the 10^12 multiplication on the reward
     *      - OR -
     * @dev Converts reward CART value to reward/weight if stake weight is supplied as second
     *      function parameter instead of reward/weight
     *
     * @param reward yield reward
     * @param rewardPerWeight reward/weight (or stake weight)
     * @return stake weight (or reward/weight)
     */
    function rewardToWeight(uint256 reward, uint256 rewardPerWeight) public pure returns (uint256) {
        // apply the reverse formula and return
        return (reward * REWARD_PER_WEIGHT_MULTIPLIER) / rewardPerWeight;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override block number in helper test smart contracts
     *
     * @return `block.number` in mainnet, custom values in testnets (if overridden)
     */
    function blockNumber() public view virtual returns (uint256) {
        // return current block number
        return block.number;
    }

    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden)
     */
    function now256() public view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Executes SafeERC20.safeTransfer on a pool token
     *
     */
    function transferPoolToken(address _to, uint256 _value) internal {
        SafeERC20.safeTransfer(IERC20(poolToken), _to, _value);
    }

    /**
     * @dev Executes SafeERC20.safeTransferFrom on a pool token
     *
     */
    function transferPoolTokenFrom(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(poolToken), _from, _to, _value);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./IPool.sol";

interface ICorePool is IPool {

    function poolTokenReserve() external view returns (uint256);

    function stakeAsPool(address _staker, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title ITokenRecipient
 *
 * @notice Recipient Cart Token and stake
 *
 */

interface ITokenRecipient {
  function tokensReceived(
      address from,
      uint amount,
      bytes calldata exData
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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