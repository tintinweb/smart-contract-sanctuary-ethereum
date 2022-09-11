// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./WayaToken.sol";


/// @notice The idea for this MasterChef (CF) contract is to be the owner of a dummy token
/// that is deposited into the TaskMaster (TM) contract.
/// The allocation point for this pool on TM is the total allocation point for all pools that receive incentives.
contract ChiefFarmer is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for WayaToken;

    /// @notice Info of each MasterChef user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` Used to calculate the correct amount of rewards. See explanation below.
    ///
    /// We do some fancy math here. Basically, any point in time, the amount of WAYAs
    /// entitled to a user but is pending to be distributed is:
    ///
    ///   pending reward = (user share * pool.accWayaPerShare) - user.rewardDebt
    ///
    ///   Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    ///   1. The pool's `accWayaPerShare` (and `lastRewardBlock`) gets updated.
    ///   2. User receives the pending reward sent to his/her address.
    ///   3. User's `amount` gets updated. Pool's `totalBoostedShare` gets updated.
    ///   4. User's `rewardDebt` gets updated.

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 boostMultiplier;
    }

    /// @notice Info of each MasterChef pool.
    /// `allocPoint` The amount of allocation points assigned to the pool.
    ///     Also known as the amount of "multipliers". Combined with `totalXAllocPoint`, it defines the % of
    ///     WAYA rewards each pool gets.
    /// `accWayaPerShare` Accumulated WAYAs per share, times 1e12.
    /// `lastRewardBlock` Last block number that pool update action is executed.
    /// `isRegular` The flag to set pool is regular or special. See below:
    ///     In TaskMaster farms are "regular pools". "special pools", which use a different sets of
    ///     `allocPoint` and their own `totalSpecialAllocPoint` are designed to handle the distribution of
    ///     the WAYA rewards to all the PlexSwap products.
    /// `totalBoostedShare` The total amount of user shares in each pool. After considering the share boosts.
    
   struct PoolInfo {
        uint256 accWayaPerShare;
        uint256 lastRewardBlock;
        uint256 allocPoint;
        uint256 totalBoostedShare;
        bool    isRegular;
    }

    /// @notice The only address can withdraw all the WAYA Reserves.
    address public financialController;

    /// @notice The contract handles the share boosts.
    address public boostContract;

    /// @notice Info of each MasterChef pool.
    PoolInfo[] public poolInfo;

    /// @notice Address of the LP token for each CF pool.
    IERC20[] public lpToken;

    /// @notice Info of each pool user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    /// @notice The whitelist of addresses allowed to deposit in special pools.
    mapping(address => bool) public whiteList;

    /// @notice Total regular allocation points. Must be the sum of all regular pools' allocation points.
    uint256 public totalRegularAllocPoint;

    /// @notice Total special allocation points. Must be the sum of all special pools' allocation points.
    uint256 public totalSpecialAllocPoint;

    uint256 public constant ACC_WAYA_PRECISION = 1e18;

    /// @notice Basic boost factor, none boosted user's boost factor
    uint256 public constant BOOST_PRECISION = 100 * 1e10;

    /// @notice Hard limit for maxmium boost factor, it must greater than BOOST_PRECISION
    uint256 public constant MAX_BOOST_PRECISION = 200 * 1e10;

    /// @notice total waya rate = toReserve + toRegular + toSpecial
    uint256 public constant WAYA_RATE_TOTAL_PRECISION = 1e12;

    /// @notice The last block number of WAYA reserve action being executed.

    /// @notice WAYA distribute % for reserve
    uint256 public wayaRateToReserve = 25750000000;

    /// @notice WAYA distribute % for regular farm pool
    uint256 public wayaRateToRegularFarm = 175365000000;

    /// @notice WAYA distribute % for special pools
    uint256 public wayaRateToSpecialFarm = 798885000000;

    //-------------------------------- The Beginning of Heaven  ---------------------
    // The WAYA TOKEN!
    WayaToken public immutable WAYA;

    // WAYA tokens created per block.
    uint256 public emissionPerBlock;

   //------------------------------------------------------------------------------------------

    uint256 public lastAccruedBlock;


    event AddPool(uint256 indexed pid, uint256 allocPoint, IERC20 indexed lpToken, bool isRegular);
    event UpdatePoolParams(uint256 indexed pid, uint256 allocPoint, bool isRegular);
    event UpdatePoolReward(uint256 indexed pid, uint256 lastRewardBlock, uint256 lpSupply, uint256 accWayaPerShare);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event UpdateWayaRate(uint256 reserveRate, uint256 regularFarmRate, uint256 specialFarmRate);
    event UpdatefinancialController(address indexed oldAdmin, address indexed newAdmin);
    event UpdateWhiteList(address indexed user, bool isValid);
    event UpdateBoostContract(address indexed boostContract);
    event UpdateBoostMultiplier(address indexed user, uint256 pid, uint256 oldMultiplier, uint256 newMultiplier);
    event EmissionPerBlockUpdated (uint256 oldEmissionPerBlock, uint256 newEmissionPerBlock);


    constructor(
        WayaToken _wayaAddress,
        uint256 _emissionPerBlock,
        address _financialController
    ) {
        WAYA = _wayaAddress;
        emissionPerBlock = _emissionPerBlock * (1e18);
        financialController = _financialController;
    }
 
    /**
     * @dev Throws if caller is not the boost contract.
     */
    modifier onlyBoostContract() {
        require(boostContract == msg.sender, "Ownable: caller is not the boost contract");
        _;
    }

    function linkedPoolInfo(uint256 _pid) external view returns (IERC20 _lpTokenAddress, PoolInfo memory _poolInfo) {
        _lpTokenAddress     =  lpToken[_pid];
        _poolInfo           =  poolInfo[_pid];
    }
    
    function linkedParams() external view returns (address, address){
        return(address(WAYA), address(boostContract));
    }
    
     /// @notice Updates WAYA emission.
    function updateEmissionPerBlock(uint256 _newEmissionPerBlock) public onlyOwner {
        uint256 _oldWayaPerBlock = emissionPerBlock;
        emissionPerBlock = _newEmissionPerBlock * (1e18);
        emit EmissionPerBlockUpdated(_oldWayaPerBlock, _newEmissionPerBlock);
    }
    /// @notice Returns the number of CF pools.
    function poolLength() public view returns (uint256 pools) {
        pools = poolInfo.length;
    }

    function isPoolRegistered (IERC20 _newPool) public view returns (bool) {
        for (uint256 i=0; i < poolInfo.length; i++){
            if (lpToken[i] == _newPool) return true;
        }
        return  false;                 
    }

    /// @notice Add a new pool. Can only be called by the owner.
    /// @param _allocPoint Number of allocation points for the new pool.
    /// @param _lpToken Address of the LP ERC-20 token.
    /// @param _isRegular Whether the pool is regular or special. LP farms are always "regular". "Special" pools are
    /// only for WAYA distributions within PlexSwap products.
    /// @param _withUpdate Whether call "massUpdatePools" operation.

    function addPool(
        uint256 _allocPoint,
        IERC20  _lpToken,
        bool    _isRegular,
        bool    _withUpdate
    ) external onlyOwner {
        require( !isPoolRegistered(_lpToken), "Pool already registered");
        require(_lpToken.balanceOf(address(this)) >= 0, "None ERC20 tokens");

        // stake WAYA token will cause staked token and reward token mixed up,
        // may cause staked tokens withdraw as reward token,never do it.
        require(_lpToken != WAYA, "WAYA token can't be added to farm pools");

        if (_withUpdate) {
            massUpdatePools();
        }

        if (_isRegular) {
            totalRegularAllocPoint = totalRegularAllocPoint + _allocPoint;
        } else {
            totalSpecialAllocPoint = totalSpecialAllocPoint + _allocPoint;
        }

        lpToken.push(_lpToken);

        poolInfo.push(
            PoolInfo({
        allocPoint: _allocPoint,
        lastRewardBlock: block.number,
        accWayaPerShare: 0,
        isRegular: _isRegular,
        totalBoostedShare: 0
        })
        );
        emit AddPool(lpToken.length - 1, _allocPoint, _lpToken, _isRegular);
    }

    /// @notice  Update the given pool's WAYA allocation point. Can only be called by the owner.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _allocPoint New number of allocation points for the pool.
    /// @param _isRegular Whether pool is "regular" or "special".
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function updatePoolParams(
        uint256 _pid,
        uint256 _allocPoint,
        bool _isRegular,
        bool _withUpdate
    ) external onlyOwner {
        // No matter _withUpdate is true or false, 
       //  it´s necessary  to execute updatePool once before set the pool parameters.
        updatePoolReward(_pid);

        if (_withUpdate) {
            massUpdatePools();
        }

        if (poolInfo[_pid].isRegular) {
            totalRegularAllocPoint = totalRegularAllocPoint - poolInfo[_pid].allocPoint;
        } else {
            totalSpecialAllocPoint = totalSpecialAllocPoint - poolInfo[_pid].allocPoint;
        }

        if (_isRegular) {
            totalRegularAllocPoint = totalRegularAllocPoint + _allocPoint;
        } else {
            totalSpecialAllocPoint = totalSpecialAllocPoint + _allocPoint;
        }

        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].isRegular  = _isRegular;

        emit UpdatePoolParams(_pid, _allocPoint, _isRegular);
    }

    /// @notice View function for checking pending WAYA rewards.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _user Address of the user.
    function pendingWaya(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accWayaPerShare = pool.accWayaPerShare;
        uint256 lpSupply = pool.totalBoostedShare;

        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = block.number - pool.lastRewardBlock;

            uint256 wayaReward = (multiplier * (wayaPerBlock(pool.isRegular)) * (pool.allocPoint)) / (
                (pool.isRegular ? totalRegularAllocPoint : totalSpecialAllocPoint)
            );
            accWayaPerShare = accWayaPerShare + ((wayaReward *(ACC_WAYA_PRECISION)) / lpSupply);
        }

        uint256 boostedAmount = (user.amount * (getBoostMultiplier(_user, _pid))) / BOOST_PRECISION;
        return ((boostedAmount * (accWayaPerShare)) / ACC_WAYA_PRECISION)- user.rewardDebt;
    }

    /// @notice Update waya reward for all the active pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo memory pool = poolInfo[pid];
            if (pool.allocPoint != 0) {
                updatePoolReward(pid);
            }
        }
    }
 
    /// @notice Calculates and returns the `amount` of WAYA per block, depending on type of Farm.
    /// @param _isRegular If the pool belongs to regular or special.
    function wayaPerBlock(bool _isRegular) public view returns (uint256 amount) {
        if (_isRegular) {
            amount = (emissionPerBlock * wayaRateToRegularFarm) / WAYA_RATE_TOTAL_PRECISION;
        } else {
            amount = (emissionPerBlock * wayaRateToSpecialFarm) / WAYA_RATE_TOTAL_PRECISION;
        }
    }

    /// @notice Calculates and returns the `amount` of WAYA per block to reserve.
    function wayaPerBlockToReserve() public view returns (uint256 amount) {
        amount = (emissionPerBlock * wayaRateToReserve) / WAYA_RATE_TOTAL_PRECISION;
    }

    /// @notice UPDATE reward variables for the given pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @return pool Returns the pool that was updated.
    function updatePoolReward(uint256 _pid) public returns (PoolInfo memory pool) {
        pool = poolInfo[_pid];
        if (block.number > pool.lastRewardBlock) {
            uint256 lpSupply = pool.totalBoostedShare;
            uint256 totalAllocPoint = (pool.isRegular ? totalRegularAllocPoint : totalSpecialAllocPoint);

            if (lpSupply > 0 && totalAllocPoint > 0) {
                uint256 multiplier = block.number - pool.lastRewardBlock;
                uint256 wayaReward = (multiplier * wayaPerBlock(pool.isRegular) * pool.allocPoint) /  totalAllocPoint;
                WAYA.mint(address(this), wayaReward);
				pool.accWayaPerShare = pool.accWayaPerShare + (((wayaReward * ACC_WAYA_PRECISION) / lpSupply));
            }
            pool.lastRewardBlock = block.number;
            poolInfo[_pid] = pool;
            emit UpdatePoolReward(_pid, pool.lastRewardBlock, lpSupply, pool.accWayaPerShare);
        }
    }

    /// @notice DEPOSIT LP tokens to pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to deposit.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo memory pool = updatePoolReward(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(
            pool.isRegular || whiteList[msg.sender],
            "MasterChef: The address is not available to deposit in this pool"
        );

        uint256 multiplier = getBoostMultiplier(msg.sender, _pid);

        if (user.amount > 0) {
            settlePendingWaya(msg.sender, _pid, multiplier);
        }

        if (_amount > 0) {
            uint256 before = lpToken[_pid].balanceOf(address(this));
            lpToken[_pid].safeTransferFrom(msg.sender, address(this), _amount);
            _amount = lpToken[_pid].balanceOf(address(this)) - before;
            user.amount = user.amount + _amount;

            // Update total boosted share.
            pool.totalBoostedShare = pool.totalBoostedShare + ((_amount * multiplier) / BOOST_PRECISION);
        }

        user.rewardDebt = (((user.amount * multiplier) / BOOST_PRECISION) * pool.accWayaPerShare) / 
            ACC_WAYA_PRECISION;

        poolInfo[_pid] = pool;

        emit Deposit(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw LP tokens from pool.
    /// @param _pid The id of the pool. See `poolInfo`.
    /// @param _amount Amount of LP tokens to withdraw.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo memory pool = updatePoolReward(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount, "withdraw: Insufficient Balance");

        uint256 multiplier = getBoostMultiplier(msg.sender, _pid);

        settlePendingWaya(msg.sender, _pid, multiplier);

        if (_amount > 0) {
            user.amount = user.amount - _amount;
            lpToken[_pid].safeTransfer(msg.sender, _amount);
        }

        user.rewardDebt = (((user.amount * multiplier) / BOOST_PRECISION) * pool.accWayaPerShare) / ACC_WAYA_PRECISION;

        poolInfo[_pid].totalBoostedShare = poolInfo[_pid].totalBoostedShare - (
            (_amount * multiplier) / BOOST_PRECISION
        );

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @notice Withdraw without caring about the rewards. EMERGENCY ONLY.
    /// @param _pid The id of the pool. See `poolInfo`.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        uint256 boostedAmount = (amount * getBoostMultiplier(msg.sender, _pid)) / BOOST_PRECISION;
        pool.totalBoostedShare = pool.totalBoostedShare > boostedAmount ? pool.totalBoostedShare - boostedAmount : 0;

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken[_pid].safeTransfer(msg.sender, amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /// @notice Send WAYA pending for reserve to `financialController`.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function reserveWaya(bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 multiplier = block.number - lastAccruedBlock;
        uint256 pendingWayaToReserve = multiplier * wayaPerBlockToReserve();

        // SafeTransfer WAYA
        _safeWayaTransfer(financialController, pendingWayaToReserve);
        lastAccruedBlock = block.number;
    }

    /// @notice Update the % of WAYA distributions for reserve, regular pools and special pools.
    /// @param _reserveRate The % of WAYA to reserve each block.
    /// @param _regularFarmRate The % of WAYA to regular pools each block.
    /// @param _specialFarmRate The % of WAYA to special pools each block.
    /// @param _withUpdate Whether call "massUpdatePools" operation.
    function updateWayaRate(
        uint256 _reserveRate,
        uint256 _regularFarmRate,
        uint256 _specialFarmRate,
        bool _withUpdate
    ) external onlyOwner {
        require(
            _reserveRate > 0 && _regularFarmRate > 0 && _specialFarmRate > 0,
            "MasterChef: Waya rate must be greater than 0"
        );
        require(
            _reserveRate + _regularFarmRate + _specialFarmRate == WAYA_RATE_TOTAL_PRECISION,
            "MasterChef: Total rate must be 1e12"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
       
        reserveWaya(false);

        wayaRateToReserve        = _reserveRate;
        wayaRateToRegularFarm = _regularFarmRate;
        wayaRateToSpecialFarm = _specialFarmRate;

        emit UpdateWayaRate(_reserveRate, _regularFarmRate, _specialFarmRate);
    }

    /// @notice Update Financial Controller address.
    /// @param _newFC  The new Financial Controller address.
    function updateFinancialController(address _newFC) external onlyOwner {
        require(_newFC != address(0), "Financial Controller address must be valid");
        require(_newFC != financialController,  "Financial Controller address is the same");
        address _oldFC = financialController;
        financialController = _newFC;
        emit UpdatefinancialController(_oldFC, _newFC);
    }

    /// @notice Update whitelisted addresses for special pools.
    /// @param _user The address to be updated.
    /// @param _isValid The flag for valid or invalid.
    function updateWhiteList(address _user, bool _isValid) external onlyOwner {
        require(_user != address(0), "MasterChef: The white list address must be valid");

        whiteList[_user] = _isValid;
        emit UpdateWhiteList(_user, _isValid);
    }

    /// @notice Update boost contract address and max boost factor.
    /// @param _newBoostContract The new address for handling all the share boosts.
    function updateBoostContract(address _newBoostContract) external onlyOwner {
        require(
            _newBoostContract != address(0) && _newBoostContract != boostContract,
            "MasterChef: New boost contract address must be valid"
        );

        boostContract = _newBoostContract;
        emit UpdateBoostContract(_newBoostContract);
    }

    /// @notice Update user boost factor.
    /// @param _user The user address for boost factor updates.
    /// @param _pid The pool id for the boost factor updates.
    /// @param _newMultiplier New boost multiplier.
    function updateBoostMultiplier(
        address _user,
        uint256 _pid,
        uint256 _newMultiplier
    ) external onlyBoostContract nonReentrant {
        require(_user != address(0), "MasterChef: The user address must be valid");
        require(poolInfo[_pid].isRegular, "MasterChef: Only regular farm could be boosted");
        require(
            _newMultiplier >= BOOST_PRECISION && _newMultiplier <= MAX_BOOST_PRECISION,
            "MasterChef: Invalid new boost multiplier"
        );

        PoolInfo memory pool = updatePoolReward(_pid);
        UserInfo storage user = userInfo[_pid][_user];

        uint256 prevMultiplier = getBoostMultiplier(_user, _pid);
        settlePendingWaya(_user, _pid, prevMultiplier);

        user.rewardDebt = (((user.amount * _newMultiplier) / BOOST_PRECISION) * pool.accWayaPerShare) / 
            ACC_WAYA_PRECISION;

        pool.totalBoostedShare = pool.totalBoostedShare - ((user.amount * prevMultiplier) / BOOST_PRECISION) + (
            (user.amount * _newMultiplier) / BOOST_PRECISION
        );
        poolInfo[_pid] = pool;
        userInfo[_pid][_user].boostMultiplier = _newMultiplier;

        emit UpdateBoostMultiplier(_user, _pid, prevMultiplier, _newMultiplier);
    }

    /// @notice Get user boost multiplier for specific pool id.
    /// @param _user The user address.
    /// @param _pid The pool id.
    function getBoostMultiplier(address _user, uint256 _pid) public view returns (uint256) {
        uint256 multiplier = userInfo[_pid][_user].boostMultiplier;
        return multiplier > BOOST_PRECISION ? multiplier : BOOST_PRECISION;
    }

    /// @notice Settles, distribute the pending WAYA rewards for given user.
    /// @param _user The user address for settling rewards.
    /// @param _pid The pool id.
    /// @param _boostMultiplier The user boost multiplier in specific pool id.
    function settlePendingWaya(
        address _user,
        uint256 _pid,
        uint256 _boostMultiplier
    ) internal {
        UserInfo memory user = userInfo[_pid][_user];

        uint256 boostedAmount = (user.amount * _boostMultiplier) / BOOST_PRECISION;
        uint256 accWaya = (boostedAmount * poolInfo[_pid].accWayaPerShare) / ACC_WAYA_PRECISION;
        uint256 pending = accWaya - user.rewardDebt;

        // SafeTransfer WAYA
        _safeWayaTransfer(_user, pending);
    }

    /// @notice Safe Transfer WAYA.
    /// @param _to The WAYA receiver address.
    /// @param _amount transfer WAYA amounts.
    function _safeWayaTransfer(address _to, uint256 _amount) internal {
        if (_amount > 0) {
           uint256 wayaBalance = WAYA.balanceOf(address(this));
           _amount = (_amount > wayaBalance ? wayaBalance : _amount); 
           WAYA.safeTransfer(_to, _amount);
        }
    }
}