// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface ICrossFactory {
    function isPairDelisted(address _address) external view returns (bool);
}

// File: contracts\interfaces\ICrossRouter02.sol

interface ICrssReferral {
    /**
     * @dev Record referral.
     */
    function recordReferral(address user, address referrer) external;

    /**
     * @dev Record referral commission.
     */
    function recordReferralCommission(address referrer, uint256 commission)
        external;

    /**
     * @dev Get the referrer address that referred the user.
     */
    function getReferrer(address user) external view returns (address);

    function getOutstandingCommission(address _referrer)
        external
        view
        returns (uint256 amount);

    function debitOutstandingCommission(address _referrer, uint256 _debit)
        external;

    function getTotalComission(address _referrer)
        external
        view
        returns (uint256);

    function updateOperator(address _newPayer) external;
}

interface ICRSS is IERC20 {
    /* */

    function changeFarmAddress(address _address) external;

    function controlledMint(uint256 _amount) external;
    /* */
}

interface ICrossFarm {
    function updatePoolDepositFee(uint256 _pid, uint256 _newFee) external;

    function updateEarlyWithdrawTax(uint256 _newFee) external;

    function depositFeeExclusionStatus(address _address, uint256 _value)
        external;

    function changeRouter(address _token, address _router) external;

    function updateContractAddress(uint256 _id, address _address) external;

    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        address _token0,
        address _token1,
        uint256 _depositFee,
        uint256 _swapTreshold,
        uint256 _lockTime,
        uint256 _endBlock,
        address _router,
        bool _withUpdate
    ) external;

    // Update the given pool's ERC20 allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _depositFee,
        uint256 _lockTime,
        uint256 _swapTreshold,
        uint256 _endBlock,
        bool _withUpdate
    ) external;

    function setRewardPerBlock(uint256 _amount, bool _withUpdate) external;

    function getAdditionalPoolInfo(uint256 _pid)
        external
        view
        returns (
            uint256 depositFee,
            uint256 lockTime,
            uint256 fundedUntil,
            uint256 allocationPoints,
            uint256 totalAllocationPoints,
            address lpTokenAddress
        );

    function userPoolFarmInfo(address _user, uint256 _pid)
        external
        view
        returns (
            uint256 stakedLp,
            uint256 claimableRewards,
            uint256 timeUntilWithdrawUnlocked,
            bool compounding
        );
}

// Farm distributes CRSS and LP token rewards to each user based on staked LP.
// this Sushiswap arch Masterchef contract was used as base,
// https://github.com/SashimiProject/sashimiswap/blob/master/contracts/MasterChef.sol
// Added autocompounding and vesting feature as well as a dozen or so smaller features like locked pools, referral feature, deposit fee etc.
contract CrossLPFarm is Context, ReentrancyGuard, ICrossFarm {
    //using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of ERC20s
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accERC20PerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accERC20PerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
        /******** */
        uint256 lastLockDeposit;
        bool isCompounding; //user setting which continously gives users rewards in lpToken instead of CRSS when turned on
        //rewards between compounding and non-compounding subpools are divided based on total deposit percentages for these subpools
        /******** */
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. ERC20s to distribute per block.
        uint256 lastRewardBlock; // Last block number that ERC20s distribution occurs.
        uint256 accERC20PerShare; // Accumulated ERC20s per share, times 1e36.
        /******** */
        uint256 compoundRewards; //current amount of CRSS value for compunding in this pool,
        // this CRSS token amount is converted to LP token of the pool in question once swap treshold is reached
        //these two are required to correctly split CRSS token rewards, and determine LP rewards
        uint256 compoundingTokens; // total number of deposited LP tokens in compound
        uint256 nonCompoundingTokens; //total number of deposited LP tokens not compounded
        uint256 endBlock;
        /******** */
    }

    struct LpPair {
        address token0;
        address token1;
    }

    // ERC20 tokens rewarded per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    //stores a router for each token so auto-compound can correctly ajdust for any different token on the same chain
    mapping(address => address) public tokenToRouter;
    //amount off crss required to initiate conversion from CRSS => LP token
    mapping(uint256 => uint256) public poolSwapTreshold;

    // pool specific, determines min wait time in blocks before withdrawing after deposit, 0 means its turned off
    //when pool lock time is > 0, early withdrawal tax occurs if => user "lastLockDeposit" + pool "poolLocktime" > block.number
    mapping(uint256 => uint256) public poolLocktime;

    //mapping(address => uint256) public userVestTimes;
    mapping(uint256 => LpPair) public pairInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    //penalty for withdrawing before locktime period expired in a pool that has a lock
    //demominator 10 000 => 100%, 1 => 0.01%  adjustable, universal, max 20%
    uint256 public earlyWithdrawTax;
    //too many state vars..
    address[] public contractAddresses; //0  crss token, 1  vesting, 2 accountant, 3 CRSS factory
    address public adminSetter;
    //demominator 10 000 => 100%, 1 => 0.01%  adjustable, max 10%
    mapping(uint256 => uint256) public poolDepositFee;
    //this calculates deposit fee in reverse for gas savings, 10000 value means user is excluded from fees,9999 is 99.99% adjusted amount or 0.001% tax, 4000 is 60% tax, 9900 is 1% tax
    //if 0, pool specific poolDepositFee is applied
    mapping(address => uint256) public userAdjustedDeposit;

    event PoolUpdated(
        PoolInfo pool,
        uint256 lockTime,
        uint256 swapTreshold,
        uint256 depositFee
    );
    event PoolCreated(
        PoolInfo pool,
        uint256 lockTime,
        uint256 swapTreshold,
        uint256 depositFee
    );
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    //**********Owner  */
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function changeAdminSetter(address _newAdmin) external {
        require(msg.sender == adminSetter, "fCRSS:Only admin setter");
        adminSetter = _newAdmin;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership(uint256 _securityCheck) public {
        uint256 securityCheck = 1234567890; //to reduce chance of triggering this change accidently
        require(_securityCheck == securityCheck, "fCRSS:Enter security check");
        require(
            adminSetter == _msgSender() || owner() == _msgSender(),
            "Only admin setter can remove ownership"
        );
        if (adminSetter == _msgSender()) {
            adminSetter == address(0);
        } else {
            _transferOwnership(address(0));
        }
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public {
        require(
            owner() == _msgSender() || adminSetter == _msgSender(),
            "Ownable: caller is not the owner"
        );
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    constructor(address[] memory _contractAddresses) ReentrancyGuard() {
        for (uint256 i = 0; i < _contractAddresses.length; i++) {
            contractAddresses.push(_contractAddresses[i]);
        }
        IERC20(_contractAddresses[0]).approve(
            _contractAddresses[1],
            type(uint256).max
        );
        _transferOwnership(_msgSender());
        adminSetter = _msgSender();
    }

    // Add a new lp to the pool. Can only be called by the owner. block.timestamp
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        address _token0,
        address _token1,
        uint256 _depositFee,
        uint256 _swapTreshold,
        uint256 _lockTime,
        uint256 _endBlock,
        address _router,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint += _allocPoint;
        uint256 index = poolLength();
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: block.number,
                accERC20PerShare: 0,
                compoundRewards: 0,
                compoundingTokens: 0,
                nonCompoundingTokens: 0,
                endBlock: _endBlock
            })
        );

        poolDepositFee[index] = _depositFee;
        poolSwapTreshold[index] = _swapTreshold;
        poolLocktime[index] = _lockTime;
        pairInfo[index] = LpPair({token0: _token0, token1: _token1});
        tokenToRouter[address(_lpToken)] = _router;

        _lpToken.approve(contractAddresses[1], type(uint256).max);
        //_lpToken.approve(_router, type(uint256).max);
        emit PoolCreated(
            poolInfo[poolInfo.length - 1],
            _lockTime,
            _swapTreshold,
            _depositFee
        );
    }

    // Update some of the given pool's parameters. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _depositFee,
        uint256 _lockTime,
        uint256 _swapTreshold,
        uint256 _endBlock,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint =
            (totalAllocPoint + _allocPoint) -
            poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].endBlock = _endBlock;
        poolDepositFee[_pid] = _depositFee;
        poolSwapTreshold[_pid] = _swapTreshold;
        poolLocktime[_pid] = _lockTime;

        emit PoolUpdated(poolInfo[_pid], _lockTime, _swapTreshold, _depositFee);
    }

    //mass update of all pools just before changing reward per block is very important in order not to give higher rewards than intended in updatePool()
    function setRewardPerBlock(uint256 _amount, bool _withUpdate)
        external
        override(ICrossFarm)
        onlyOwner
    {
        //require(msg.sender == contractAddresses[0]);
        if (_withUpdate) {
            massUpdatePools();
        }

        rewardPerBlock = _amount;
    }

    function getCorePoolInfo(uint256 _pid)
        public
        view
        returns (PoolInfo memory)
    {
        return poolInfo[_pid];
    }

    function getAdditionalPoolInfo(uint256 _pid)
        public
        view
        returns (
            uint256 depositFee,
            uint256 lockTime,
            uint256 fundedUntil,
            uint256 allocationPoints,
            uint256 totalAllocationPoints,
            address lpTokenAddress
        )
    {
        PoolInfo memory pool = poolInfo[_pid];

        depositFee = poolDepositFee[_pid];
        lockTime = poolLocktime[_pid];
        uint256 _endBlock = poolInfo[_pid].endBlock;
        if (_endBlock > block.number) {
            fundedUntil = _endBlock - block.number;
        } else if (_endBlock == 0) {
            fundedUntil = type(uint256).max;
        } else {
            fundedUntil = 0;
        }
        allocationPoints = pool.allocPoint;
        totalAllocationPoints = totalAllocPoint;
        lpTokenAddress = address(pool.lpToken);
    }

    function userPoolFarmInfo(address _user, uint256 _pid)
        public
        view
        override
        returns (
            uint256 stakedLp,
            uint256 claimableRewards,
            uint256 timeUntilWithdrawUnlocked,
            bool compounding
        )
    {
        UserInfo memory user = userInfo[_pid][_user];

        stakedLp = user.amount;
        claimableRewards = userPending(_user, _pid);

        timeUntilWithdrawUnlocked = user.lastLockDeposit + poolLocktime[_pid] <=
            block.number
            ? 0
            : (user.lastLockDeposit + poolLocktime[_pid]) - block.number;
        compounding = user.isCompounding;
    }

    function getPoolDepositFee(uint256 _pid) public view returns (uint256) {
        return poolDepositFee[_pid];
    }

    function getPoolLocktime(uint256 _pid) public view returns (uint256) {
        return poolLocktime[_pid];
    }

    function poolFundedUntil(uint256 _pid) public view returns (uint256) {
        return poolInfo[_pid].endBlock - block.number;
    }

    // Number of LP pools
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    function isUserCompounding(uint256 _pid, address _address)
        public
        view
        returns (bool)
    {
        return userInfo[_pid][_address].isCompounding;
    }

    // View function to see deposited LP for a user.
    function deposited(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        return userInfo[_pid][_user].amount;
    }

    function extendedWithdraw(uint256 _pid, uint256 _amount)
        public
        nonReentrant
    {
        if (userInfo[_pid][msg.sender].isCompounding) {
            compoundWithdraw(_pid, _amount);
        } else {
            withdraw(_pid, _amount);
        }
    }

    function extendedDeposit(uint256 _pid, uint256 _amount)
        public
        nonReentrant
    {
        require(
            ICrossFactory(contractAddresses[3]).isPairDelisted(
                address(poolInfo[_pid].lpToken)
            ) != true,
            "fCRRS:Can't deposit to delisted pair"
        );
        require(_amount > 0, "fCRRS:Zero value deposit");
        if (userInfo[_pid][msg.sender].isCompounding) {
            compoundDeposit(_pid, _amount);
        } else {
            deposit(_pid, _amount);
        }
    }

    function userPending(address _user, uint256 _pid)
        public
        view
        returns (uint256 pendingReward)
    {
        if (userInfo[_pid][_user].isCompounding == true) {
            pendingReward = getPendingCompoundRewards(_pid, _user);
        } else {
            pendingReward = pendingCRSS(_pid, _user);
        }
    }

    function claimRewards(uint256 _pid, uint32 _vestTime) public nonReentrant {
        if (userInfo[_pid][msg.sender].isCompounding) {
            claimCompoundRewards(_pid, msg.sender, _vestTime);
        } else {
            normalClaimRewards(_pid, msg.sender, _vestTime);
        }
    }

    function massClaim(uint256[] memory _pids, uint32 _vestTime)
        public
        nonReentrant
    {
        for (uint256 i = 0; i < _pids.length; i++) {
            if (isUserCompounding(_pids[i], msg.sender)) {
                claimCompoundRewards(_pids[i], msg.sender, _vestTime);
            } else {
                normalClaimRewards(_pids[i], msg.sender, _vestTime);
            }
        }
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            if (poolInfo[pid].allocPoint != 0) {
                updatePool(pid);
            }
        }
    }

    // View function to see pending ERC20s for a user.
    function pendingCRSS(uint256 _pid, address _user)
        private
        view
        returns (uint256)
    {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        uint256 accERC20PerShare = pool.accERC20PerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 blockNumber = block.number;
        if (pool.endBlock <= blockNumber && pool.endBlock != 0) {
            return (user.amount * accERC20PerShare) / 1e36 - user.rewardDebt;
        }
        if (blockNumber > pool.lastRewardBlock && lpSupply != 0) {
            uint256 nrOfBlocks = blockNumber - pool.lastRewardBlock;
            uint256 erc20Reward = (nrOfBlocks *
                rewardPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accERC20PerShare =
                accERC20PerShare +
                ((erc20Reward * 1e36) / lpSupply);
        }

        return
            (((user.amount * accERC20PerShare) / 1e36 - user.rewardDebt) * 3) /
            10;
    }

    function getPendingCompoundRewards(uint256 _pid, address _user)
        private
        view
        returns (uint256 reward)
    {
        UserInfo memory user = userInfo[_pid][_user];
        if (user.isCompounding == true || user.amount > 0) {
            PoolInfo memory pool = poolInfo[_pid];
            uint256 compoundRewards = IERC20(address(pool.lpToken)).balanceOf(
                address(this)
            ) -
                pool.compoundingTokens -
                pool.nonCompoundingTokens;
            uint256 userReward = (user.amount * compoundRewards) /
                pool.compoundingTokens -
                user.rewardDebt;
            reward = (userReward * 3) / 10;
            return reward;
        } else return 0;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];

        uint256 currentBlock = block.number;
        if (pool.endBlock <= currentBlock && pool.endBlock != 0) {
            return;
        }
        if (currentBlock <= pool.lastRewardBlock) {
            return;
        }

        //uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        /*if (lpSupply == 0) {
            pool.lastRewardBlock = currentBlock;
            return;
        }*/

        uint256 compoundedLpTokens = pool.compoundingTokens;
        uint256 nonCompoundedLpTokens = pool.nonCompoundingTokens;
        uint256 totalActiveDeposit = compoundedLpTokens + nonCompoundedLpTokens;
        if (totalActiveDeposit == 0) {
            pool.lastRewardBlock = currentBlock;
            return;
        }
        uint256 nrOfBlocks = currentBlock - pool.lastRewardBlock;
        uint256 totalCrssReward = (nrOfBlocks *
            rewardPerBlock *
            pool.allocPoint) / totalAllocPoint;
        uint256 nonCompoundReward = (totalCrssReward * nonCompoundedLpTokens) /
            totalActiveDeposit;
        uint256 compoundReward = (totalCrssReward * compoundedLpTokens) /
            totalActiveDeposit;
        uint256 crssToMint = compoundReward + nonCompoundReward;
        ICRSS(contractAddresses[0]).controlledMint(crssToMint);
        /* */
        if (nonCompoundedLpTokens > 0) {
            pool.accERC20PerShare =
                pool.accERC20PerShare +
                ((nonCompoundReward * 1e36) / nonCompoundedLpTokens);
        }
        uint256 newCompRewards = pool.compoundRewards + compoundReward;
        pool.compoundRewards = newCompRewards;
        pool.lastRewardBlock = block.number;
    }

    function claimCompoundRewards(
        uint256 _pid,
        address _user,
        uint32 _vestTime
    ) private {
        require(
            _vestTime > 0 && _vestTime <= 12,
            "fCRSS:Wrong vest time selected"
        );
        updatePool(_pid);
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];

        //if pool specific swap treshold is reached, initiate required token swaps and execute addLiquidity() to get new LP tokens
        if (poolSwapTreshold[_pid] <= pool.compoundRewards) {
            address crssToken = contractAddresses[0];
            address poolRouterAddress = tokenToRouter[address(pool.lpToken)];
            LpPair memory lpInfo = pairInfo[_pid];
            (address token0, address token1) = (lpInfo.token0, lpInfo.token1);
            if (token0 == crssToken) {
                uint256 poolCompoundRewards = pool.compoundRewards;
                pool.compoundRewards = 0;
                address[] memory path = new address[](2);

                path[0] = crssToken;
                path[1] = token1;
                (bool success0, ) = poolRouterAddress.call(
                    abi.encodeWithSelector(
                        0x5c11d795,
                        poolCompoundRewards / 2,
                        0,
                        path,
                        address(this),
                        block.timestamp + 100
                    )
                );

                require(success0, "fCRSS:Swap call failed");
                (bool success1, ) = poolRouterAddress.call(
                    abi.encodeWithSelector(
                        0xe8e33700,
                        crssToken,
                        token1,
                        poolCompoundRewards / 2,
                        IERC20(token1).balanceOf(address(this)),
                        0,
                        0,
                        address(this),
                        block.timestamp + 100
                    )
                );
                require(success1, "fCRSS:Add liquidity call failed");
            } else if (token1 == crssToken) {
                uint256 poolCompoundRewards = pool.compoundRewards;
                pool.compoundRewards = 0;

                address[] memory path = new address[](2);

                path[0] = crssToken;
                path[1] = token0;
                (bool success0, ) = poolRouterAddress.call(
                    abi.encodeWithSelector(
                        0x5c11d795,
                        poolCompoundRewards / 2,
                        0,
                        path,
                        address(this),
                        block.timestamp + 100
                    )
                );

                require(success0, "fCRSS:Swap call failed");
                (bool success1, ) = poolRouterAddress.call(
                    abi.encodeWithSelector(
                        0xe8e33700,
                        crssToken,
                        token0,
                        poolCompoundRewards / 2,
                        IERC20(token0).balanceOf(address(this)),
                        0,
                        0,
                        address(this),
                        block.timestamp + 100
                    )
                );
                require(success1, "fCRSS:Add liquidity call failed");
            } else {
                address wBnb = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
                {
                    address[] memory path = new address[](2);

                    path[0] = crssToken;
                    path[1] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
                    (bool success0, ) = tokenToRouter[wBnb].call(
                        abi.encodeWithSelector(
                            0x5c11d795,
                            pool.compoundRewards,
                            0,
                            path,
                            address(this),
                            block.timestamp + 100
                        )
                    );

                    require(success0, "fCRSS:Swap call failed");
                }

                pool.compoundRewards = 0;
                uint256 amountBnb = IERC20(wBnb).balanceOf(address(this));
                if (token0 != wBnb) {
                    address tokenRouterAddress0 = tokenToRouter[token0];
                    address routerAddress0 = tokenRouterAddress0 != address(0)
                        ? tokenRouterAddress0
                        : poolRouterAddress;
                    address[] memory path = new address[](2);

                    path[0] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
                    path[1] = token0;
                    (bool success0, ) = routerAddress0.call(
                        abi.encodeWithSelector(
                            0x5c11d795,
                            amountBnb / 2,
                            0,
                            path,
                            address(this),
                            block.timestamp + 100
                        )
                    );

                    require(success0, "fCRSS:Swap call failed");
                }
                if (token1 != wBnb) {
                    address tokenRouterAddress1 = tokenToRouter[token1];
                    address routerAddress1 = tokenRouterAddress1 != address(0)
                        ? tokenRouterAddress1
                        : poolRouterAddress;
                    address[] memory path = new address[](2);

                    path[0] = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
                    path[1] = token1;
                    (bool success0, ) = routerAddress1.call(
                        abi.encodeWithSelector(
                            0x5c11d795,
                            amountBnb / 2,
                            0,
                            path,
                            address(this),
                            block.timestamp + 100
                        )
                    );

                    require(success0, "fCRSS:Swap call failed");
                }
                (bool success1, ) = poolRouterAddress.call(
                    abi.encodeWithSelector(
                        0xe8e33700,
                        token0,
                        token1,
                        IERC20(token0).balanceOf(address(this)),
                        IERC20(token1).balanceOf(address(this)),
                        0,
                        0,
                        address(this),
                        block.timestamp + 100
                    )
                );
                require(success1, "fCRSS:Add liquidity call failed");
            }
        }

        uint256 totalLp = IERC20(address(pool.lpToken)).balanceOf(
            address(this)
        );
        uint256 compoundRewards = (totalLp - pool.compoundingTokens) -
            pool.nonCompoundingTokens;

        uint256 userReward = (user.amount * compoundRewards) /
            pool.compoundingTokens -
            user.rewardDebt;
        if (userReward > 0) {
            ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                _pid,
                _user,
                userReward,
                address(pool.lpToken),
                uint64(block.timestamp),
                _vestTime
            );
        }
        user.rewardDebt =
            (user.amount * (compoundRewards - userReward)) /
            pool.compoundingTokens;
    }

    function normalClaimRewards(
        uint256 _pid,
        address _user,
        uint32 _vestTime
    ) private {
        require(
            _vestTime > 0 && _vestTime <= 12,
            "fCRSS:Wrong vest time selected"
        );

        updatePool(_pid);
        uint256 poolAccPerShare = poolInfo[_pid].accERC20PerShare;
        UserInfo storage user = userInfo[_pid][_user];
        uint256 pendingAmount = (user.amount * poolAccPerShare) /
            1e36 -
            user.rewardDebt;

        if (pendingAmount > 0) {
            ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                _pid,
                _user,
                pendingAmount,
                contractAddresses[0],
                uint64(block.timestamp),
                _vestTime
            );
        }

        user.rewardDebt = (user.amount * poolAccPerShare) / 1e36;
    }

    function switchCollectOption(uint256 _pid) public nonReentrant {
        address _user = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);

        uint256 depositedAmount = user.amount;
        if (user.isCompounding) {
            uint256 lpRewards = (IERC20(pool.lpToken).balanceOf(address(this)) -
                pool.nonCompoundingTokens) - pool.compoundingTokens;
            uint256 userReward = (depositedAmount * lpRewards) /
                pool.compoundingTokens -
                user.rewardDebt;

            if (userReward > 0) {
                ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                        _pid,
                        _user,
                        userReward,
                        address(pool.lpToken),
                        uint64(block.timestamp),
                        uint32(1)
                    );
            }
            if (depositedAmount > 0) {
                pool.nonCompoundingTokens += depositedAmount;
                pool.compoundingTokens -= depositedAmount;
            }
            user.rewardDebt = (depositedAmount * pool.accERC20PerShare) / 1e36;
            user.isCompounding = false;
        } else {
            uint256 pendingAmount = (user.amount * pool.accERC20PerShare) /
                1e36 -
                user.rewardDebt;
            if (pendingAmount > 0) {
                //uint32 oneMonth = 6 * 6 * 24 * 3044;
                ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                        _pid,
                        _user,
                        pendingAmount,
                        contractAddresses[0],
                        uint64(block.timestamp),
                        uint32(1)
                    );
                //erc20.transfer(vestingContract, pendingAmount);
            }
            if (depositedAmount > 0) {
                pool.compoundingTokens += depositedAmount;
                pool.nonCompoundingTokens -= depositedAmount;
            }

            uint256 lpRewards = (IERC20(pool.lpToken).balanceOf(address(this)) -
                pool.nonCompoundingTokens) - pool.compoundingTokens;
            user.rewardDebt =
                (depositedAmount * (lpRewards - lpRewards)) /
                pool.compoundingTokens;
            user.isCompounding = true;
        }
    }

    // Deposit LP tokens to Farm for ERC20 allocation.
    function deposit(uint256 _pid, uint256 _amount) private {
        require(_amount > 0, "fCRRS:Zero value deposit");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);

        uint256 adjustedAmount = _amount;
        uint256 userFeeAdjusted = userAdjustedDeposit[msg.sender];
        uint256 depositTaxAmount = userFeeAdjusted == 0
            ? (_amount * poolDepositFee[_pid]) / 10000
            : _amount - ((_amount * userFeeAdjusted) / 10000);
        adjustedAmount -= depositTaxAmount;
        if (depositTaxAmount > 0) {
            IERC20(pool.lpToken).transfer(
                contractAddresses[2],
                depositTaxAmount
            );
        }

        if (poolLocktime[_pid] > 0) {
            user.lastLockDeposit = block.number;
        } else user.lastLockDeposit = 0;

        if (user.amount > 0) {
            uint256 pendingAmount = (user.amount * pool.accERC20PerShare) /
                1e36 -
                user.rewardDebt;
            if (pendingAmount > 0) {
                //uint32 oneMonth = 6 * 6 * 24 * 3044;
                ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                        _pid,
                        msg.sender,
                        pendingAmount,
                        contractAddresses[0],
                        uint64(block.timestamp),
                        uint32(1)
                    );
            }
        }
        pool.nonCompoundingTokens += adjustedAmount;
        user.amount += adjustedAmount;
        user.rewardDebt = (user.amount * pool.accERC20PerShare) / 1e36;

        emit Deposit(msg.sender, _pid, _amount);
    }

    function compoundDeposit(uint256 _pid, uint256 _amount) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "fCRRS:Zero value deposit");

        updatePool(_pid);
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        uint256 lpRewards = (IERC20(address(pool.lpToken)).balanceOf(
            address(this)
        ) - pool.compoundingTokens) - pool.nonCompoundingTokens;
        uint256 userReward = (user.amount * lpRewards) /
            pool.compoundingTokens -
            user.rewardDebt;

        uint256 adjustedAmount = _amount;
        uint256 depositTaxAmount = userAdjustedDeposit[msg.sender] == 0
            ? (_amount * poolDepositFee[_pid]) / 10000
            : _amount - ((_amount * userAdjustedDeposit[msg.sender]) / 10000);
        adjustedAmount -= depositTaxAmount;
        if (depositTaxAmount > 0) {
            IERC20(pool.lpToken).transfer(
                contractAddresses[2],
                depositTaxAmount
            );
        }
        if (poolLocktime[_pid] > 0) {
            user.lastLockDeposit = block.number;
        } else user.lastLockDeposit = 0;
        pool.compoundingTokens += adjustedAmount;
        user.amount += adjustedAmount;
        //uint32 oneMonth = 6 * 6 * 24 * 3044; //1 month == 30.44 days (30.4375)

        if (userReward > 0) {
            ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                _pid,
                msg.sender,
                userReward,
                address(pool.lpToken),
                uint64(block.timestamp),
                uint32(1)
            );
        }
        user.rewardDebt =
            (user.amount * (lpRewards - userReward)) /
            pool.compoundingTokens;

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "fCRRS:Withdraw exceeds balance");
        require(_amount > 0, "fCRRS:Zero value withdraw");
        updatePool(_pid);
        uint256 pendingAmount = (user.amount * pool.accERC20PerShare) /
            1e36 -
            user.rewardDebt;

        if (_amount > 0) {
            user.amount -= _amount;
            pool.nonCompoundingTokens -= _amount;
            uint256 poolLockLength = getPoolLocktime(_pid);
            if (
                poolLockLength > 0 &&
                user.lastLockDeposit + poolLockLength > block.number
            ) {
                uint256 earlyTax = (_amount * earlyWithdrawTax) / 10000;
                pool.lpToken.transfer(contractAddresses[2], earlyTax);
                pool.lpToken.transfer(address(msg.sender), _amount - earlyTax);
            } else {
                pool.lpToken.transfer(address(msg.sender), _amount);
            }
        }

        user.rewardDebt = (user.amount * pool.accERC20PerShare) / 1e36;

        if (pendingAmount > 0) {
            //uint32 oneMonth = 6 * 6 * 24 * 3044; //1 month == 30.44 days (30.4375)

            ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                _pid,
                msg.sender,
                pendingAmount,
                contractAddresses[0],
                uint64(block.timestamp),
                uint32(1)
            );
            //erc20.transfer(vestingContract, pendingAmount);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function _isPoolLocked(uint256 _pid) public view returns (bool) {
        return poolLocktime[_pid] > 0;
    }

    function compoundWithdraw(uint256 _pid, uint256 _amount) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "fCRRS:Withdraw exceeds balance");
        require(_amount > 0, "fCRRS:Zero value withdraw");
        updatePool(_pid);
        uint256 lpReward = (IERC20(pool.lpToken).balanceOf(address(this)) -
            pool.compoundingTokens) - pool.nonCompoundingTokens;
        uint256 pendingAmount = (user.amount * lpReward) /
            pool.compoundingTokens -
            user.rewardDebt;

        if (_amount > 0) {
            user.amount -= _amount;
            pool.nonCompoundingTokens -= _amount;

            uint256 poolLockLength = getPoolLocktime(_pid);
            if (
                poolLockLength > 0 &&
                user.lastLockDeposit + poolLockLength > block.number
            ) {
                uint256 earlyTax = (_amount * earlyWithdrawTax) / 10000;
                pool.lpToken.transfer(contractAddresses[2], earlyTax);
                pool.lpToken.transfer(address(msg.sender), _amount - earlyTax);
            } else {
                pool.lpToken.transfer(address(msg.sender), _amount);
            }
        }

        if (pendingAmount > 0) {
            //uint32 oneMonth = 6 * 6 * 24 * 3044; //1 month == 30.44 days (30.4375)

            ICrossVesting(contractAddresses[1]).initiateFarmVestingInstance(
                _pid,
                msg.sender,
                pendingAmount,
                address(pool.lpToken),
                uint64(block.timestamp),
                uint32(1)
            );
        }
        user.rewardDebt = ((user.amount * (lpReward - pendingAmount)) /
            pool.compoundingTokens);

        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 poolLockLength = getPoolLocktime(_pid);
        if (
            poolLockLength > 0 &&
            user.lastLockDeposit + poolLockLength > block.number
        ) {
            uint256 earlyTax = (user.amount * earlyWithdrawTax) / 10000;
            pool.lpToken.transfer(contractAddresses[2], earlyTax);
            pool.lpToken.transfer(address(msg.sender), user.amount - earlyTax);
        } else {
            pool.lpToken.transfer(address(msg.sender), user.amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    function updatePoolDepositFee(uint256 _pid, uint256 _newFee)
        external
        onlyOwner
    {
        require(_newFee <= 1000, "fCRSS:Max deposit fee is 10%");
        poolDepositFee[_pid] = _newFee;
    }

    function updateEarlyWithdrawTax(uint256 _newFee) external onlyOwner {
        require(_newFee <= 2000, "fCRSS:Max early withdraw penalty is 20%");
        earlyWithdrawTax = _newFee;
    }

    function depositFeeExclusionStatus(address _address, uint256 _value)
        external
        onlyOwner
    {
        require(
            userAdjustedDeposit[_address] != _value,
            "CRSS:Already set value"
        );
        userAdjustedDeposit[_address] = _value;
    }

    function changeRouter(address _token, address _router) public onlyOwner {
        tokenToRouter[_token] = _router;
    }

    function updateContractAddress(uint256 _id, address _address)
        public
        onlyOwner
    {
        require(_id != 4, "fCRSS:Can't change CC here");
        contractAddresses[_id] = _address;
    }

    function getCurrentBlockAndTimestamp()
        public
        view
        returns (uint256 blockNumber, uint256 timestampInSeconds)
    {
        blockNumber = block.number;
        timestampInSeconds = block.timestamp;
    }

    //for testing only
    function approveContract(address _tokenAddress, address _contractAddress)
        public
    {
        IERC20(_tokenAddress).approve(_contractAddress, type(uint256).max);
    }
    /********* */
}

interface IsCRSS is IERC20 {
    function enter(uint256 _amount) external;

    function leave(uint256 _amount) external;

    function enterFor(uint256 _amount, address _to) external;

    function killswitch() external;

    function setCompoundingEnabled(bool _enabled) external;

    function setMaxTxAndWalletBPS(uint256 _pid, uint256 bps) external;

    function rescueToken(address _token, uint256 _amount) external;

    function rescueETH(uint256 _amount) external;

    function excludeFromDividends(address account, bool excluded) external;

    function upgradeDividend(address payable newDividendTracker) external;

    function impactFeeStatus(bool _value) external;

    function setImpactFeeReceiver(address _feeReceiver) external;

    function CRSStoSCRSS(uint256 _crssAmount, bool _impactFeeOn)
        external
        view
        returns (
            uint256 crssAmount,
            uint256 swapFee,
            uint256 impactFee
        );

    function sCRSStoCRSS(uint256 _sCrssAmount, bool _impactFeeOn)
        external
        view
        returns (
            uint256 crssAmount,
            uint256 swapFee,
            uint256 impactFee
        );

    event TradingHalted(uint256 timestamp);
    event TradingResumed(uint256 timestamp);
}

interface ICrossVesting {
    struct VestingInstance {
        uint256 tokenAmount;
        address tokenAddress; //these 3 take 1 memory slot
        uint64 startTimestamp;
        uint32 vestingPeriod;
    }

    struct UserVesting {
        uint128 lpTokensVesting;
        uint128 crssVesting;
    }

    function initiateFarmVestingInstance(
        uint256 _pid,
        address _address,
        uint256 _amount,
        address _tokenAddress,
        uint64 _startTimestamp,
        uint32 _vestingPeriod
    ) external;

    function userPoolVestInfo(address _user, uint256 _pid)
        external
        view
        returns (
            VestingInstance[] memory userVestingInstances,
            uint256 vestingCrss,
            uint256 vestingLpTokens,
            uint256 vestedCrss,
            uint256 vestedLpTokens,
            uint256 withdrawnCrss,
            uint256 withdrawnLpTokens,
            uint256 nextUnlock
        );
}

contract CrosswiseVesting is ReentrancyGuard {
    struct VestingInstance {
        uint256 tokenAmount;
        address tokenAddress; //these 3 take 1 memory slot
        uint64 startTimestamp;
        uint32 vestingPeriod;
    }

    struct UserVesting {
        uint128 lpTokensVesting;
        uint128 crssVesting;
    }
    /*  struct UserWithdrawn {
        uint128 crssWithdrawn;
        uint128 lpTokensWithdrawn;
    }*/
    address public referralContract;
    address public crssAddress;
    address public sCrssAddress;
    address public accountant;
    address public controlCenter;
    address public adminSetter;
    address public lpFarmAddress;
    //uint256 public minVestingPeriod;
    mapping(address => uint256) public totalVesting;
    uint256 public compoundFee; //5% or 500( / 10000)
    mapping(address => uint256) private pendingReferralRewards;
    mapping(address => mapping(uint256 => VestingInstance[]))
        public vestingInstances;
    // mapping(address => mapping(uint256 => UserVesting)) public userVesting;
    mapping(address => mapping(uint256 => uint256)) public userCrssWithdrawn;
    mapping(address => mapping(uint256 => uint256))
        public userLpTokensWithdrawn;
    // mapping(address => uint256) public totalVesting;
    mapping(uint256 => uint256) public rewardMultiplier;
    //mapping(address => uint256) public referralRewards;
    mapping(address => mapping(address => uint256)) public userEarnings;
    //uint256 private exponentialRate = 3718888; //3.72
    event UserFarmVest(
        address user,
        address token,
        uint256 amount,
        uint256 vestPeriod
    );
    event BulkCollect(address user, uint256 userReward, uint256 numOfClaimed);
    event CrossFarmVest(address user, uint256 amount, uint256 vestingPeriod);
    event BulkHarvest(
        address user,
        uint256 pid,
        uint256 crssAmount,
        uint256 lpAmount
    );
    event MassHarvest(
        address user,
        uint256[] _pids,
        uint256 crssAmount,
        uint256 lpAmount
    );

    constructor(
        address _crssAddress,
        address _sCrssAddress,
        address _accountant,
        address _referral
    ) {
        initiateRewardMultiplier(
            [
                1000,
                1156,
                1245,
                1389,
                1549,
                1728,
                1928,
                2151,
                2400,
                2678,
                2988,
                3333
            ]
        );
        crssAddress = _crssAddress;
        sCrssAddress = _sCrssAddress;
        accountant = _accountant;
        referralContract = _referral;
        compoundFee = 500;
        controlCenter = msg.sender;
        adminSetter = msg.sender;
        //approve sCRSS address so enterFor() can work
        IERC20(_crssAddress).approve(_sCrssAddress, type(uint256).max);
    }

    function initiateFarmVestingInstance(
        uint256 _pid,
        address _address,
        uint256 _amount,
        address _tokenAddress,
        uint64 _startTimestamp,
        uint32 _vestingPeriod
    ) public nonReentrant {
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
        uint32 vestPeriodInSeconds = 6 * 6 * 24 * 3044 * _vestingPeriod; // 1 month => 30.44 days (30.4375)
        //uint256 rewardsMultiplier = rewardMultiplier[_vestingPeriod];
        //uint256 adjustedReward = (rewardsMultiplier * _amount) / 3333;
        uint256 adjustedReward = getRewardMultiplier(_vestingPeriod, _amount) /
            3333;
        vestingInstances[_address][_pid].push(
            VestingInstance({
                tokenAmount: adjustedReward,
                tokenAddress: _tokenAddress,
                startTimestamp: _startTimestamp,
                vestingPeriod: vestPeriodInSeconds
            })
        );
        if (_tokenAddress == crssAddress) {
            address referrer = ICrssReferral(referralContract).getReferrer(
                _address
            );
            if (referrer != address(0)) {
                pendingReferralRewards[referrer] += (adjustedReward / 100);
            } else {
                pendingReferralRewards[accountant] += (adjustedReward / 100);
            }
        }
        totalVesting[_tokenAddress] += adjustedReward;
        emit UserFarmVest(_address, _tokenAddress, _amount, _vestingPeriod);
    }

    function massHarvest(uint256[] memory _pids) public nonReentrant {
        uint256 totalCrss;
        uint256 totalLp;

        for (uint256 x = 0; x < _pids.length; x++) {
            uint256 pidCrss;
            uint256 pidLpTokens;
            address lpToken = address(0);
            for (
                uint256 y = 0;
                y < vestingInstances[msg.sender][_pids[x]].length;
                y
            ) {
                uint256 pidIndex = _pids[x];
                VestingInstance memory vestingInstance = vestingInstances[
                    msg.sender
                ][pidIndex][y];
                if (
                    vestingInstance.vestingPeriod +
                        vestingInstance.startTimestamp <=
                    block.timestamp
                ) {
                    if (vestingInstance.tokenAddress != crssAddress) {
                        pidLpTokens += vestingInstance.tokenAmount;
                        if (lpToken == address(0)) {
                            lpToken = vestingInstance.tokenAddress;
                        }
                    } else {
                        pidCrss += vestingInstance.tokenAmount;
                    }

                    vestingInstances[msg.sender][pidIndex][
                        y
                    ] = vestingInstances[msg.sender][pidIndex][
                        vestingInstances[msg.sender][pidIndex].length - 1
                    ];
                    vestingInstances[msg.sender][pidIndex].pop();
                } else y++;
            }
            userLpTokensWithdrawn[msg.sender][_pids[x]] += pidLpTokens;
            userCrssWithdrawn[msg.sender][_pids[x]] += pidCrss;
            totalCrss += pidCrss;
            totalLp += pidLpTokens;
            if (lpToken != address(0) && pidLpTokens > 0) {
                uint256 userCompoundFee = (pidLpTokens * compoundFee) / 10000;
                IERC20(lpToken).transfer(accountant, userCompoundFee);
                IERC20(lpToken).transfer(
                    msg.sender,
                    pidLpTokens - userCompoundFee
                );
                totalVesting[lpToken] -= pidLpTokens;
            }
        }
        // require(totalCrss > 0 || totalLp > 0, "vCRSS:No unlocked rewards");

        if (totalCrss > 0) {
            address referrer = ICrssReferral(referralContract).getReferrer(
                msg.sender
            );
            if (referrer != address(0)) {
                // referralRewards[referrer] -= (totalCrss / 100);
                pendingReferralRewards[referrer] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    referrer,
                    totalCrss / 100
                );
            } else {
                pendingReferralRewards[accountant] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    accountant,
                    totalCrss / 100
                );
            }
            IERC20(crssAddress).transfer(msg.sender, totalCrss);
            totalVesting[crssAddress] -= totalCrss;
        }

        emit MassHarvest(msg.sender, _pids, totalCrss, totalLp);
    }

    //all CRSS rewards will be automatically converted to sCRSS in one transaction
    function sCrssMassHarvest(uint256[] memory _pids) public nonReentrant {
        uint256 totalCrss;
        uint256 totalLp;

        for (uint256 x = 0; x < _pids.length; x++) {
            uint256 pidCrss;
            uint256 pidLpTokens;
            address lpToken = address(0);
            for (uint256 y = 0; y < vestingInstances[msg.sender][x].length; y) {
                VestingInstance memory vestingInstance = vestingInstances[
                    msg.sender
                ][x][y];
                if (
                    vestingInstance.vestingPeriod +
                        vestingInstance.startTimestamp <=
                    block.timestamp
                ) {
                    if (vestingInstance.tokenAddress != crssAddress) {
                        pidLpTokens += vestingInstance.tokenAmount;
                        if (lpToken == address(0)) {
                            lpToken = vestingInstance.tokenAddress;
                        }
                    } else {
                        pidCrss += vestingInstance.tokenAmount;
                    }

                    vestingInstances[msg.sender][x][y] = vestingInstances[
                        msg.sender
                    ][x][vestingInstances[msg.sender][x].length - 1];
                    vestingInstances[msg.sender][x].pop();
                } else y++;
            }
            userLpTokensWithdrawn[msg.sender][x] += pidLpTokens;
            userCrssWithdrawn[msg.sender][x] += pidCrss;
            totalCrss += pidCrss;
            totalLp += pidLpTokens;
            if (lpToken != address(0) && pidLpTokens > 0) {
                uint256 userCompoundFee = (pidLpTokens * compoundFee) / 10000;
                IERC20(lpToken).transfer(accountant, userCompoundFee);
                IERC20(lpToken).transfer(
                    msg.sender,
                    pidLpTokens - userCompoundFee
                );
            }
            totalVesting[lpToken] -= pidLpTokens;
        }
        // require(totalCrss > 0 || totalLp > 0, "vCRSS:No unlocked rewards");

        if (totalCrss > 0) {
            address referrer = ICrssReferral(referralContract).getReferrer(
                msg.sender
            );

            if (referrer != address(0)) {
                // referralRewards[referrer] -= (totalCrss / 100);
                pendingReferralRewards[referrer] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    referrer,
                    totalCrss / 100
                );
            } else {
                pendingReferralRewards[accountant] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    accountant,
                    totalCrss / 100
                );
            }
            IsCRSS(sCrssAddress).enterFor(totalCrss, msg.sender);
            totalVesting[crssAddress] -= totalCrss;
        }

        emit MassHarvest(msg.sender, _pids, totalCrss, totalLp);
    }

    function bulkHarvest(uint256 _pid) public nonReentrant {
        uint256 totalCrss;
        uint256 totalLp;
        address lpToken = address(0);
        for (uint256 i = 0; i < vestingInstances[msg.sender][_pid].length; i) {
            VestingInstance memory vestingInstance = vestingInstances[
                msg.sender
            ][_pid][i];
            if (
                vestingInstance.vestingPeriod +
                    vestingInstance.startTimestamp <=
                block.timestamp
            ) {
                if (vestingInstance.tokenAddress != crssAddress) {
                    totalLp += vestingInstance.tokenAmount;
                    if (lpToken == address(0)) {
                        lpToken = vestingInstance.tokenAddress;
                    }
                } else {
                    totalCrss += vestingInstance.tokenAmount;
                }

                vestingInstances[msg.sender][_pid][i] = vestingInstances[
                    msg.sender
                ][_pid][vestingInstances[msg.sender][_pid].length - 1];
                vestingInstances[msg.sender][_pid].pop();
            } else i++;
        }
        // require(totalCrss > 0 || totalLp > 0, "vCRSS:No unlocked rewards");
        if (lpToken != address(0)) {
            userLpTokensWithdrawn[msg.sender][_pid] += totalLp;
            uint256 userCompoundFee = (totalLp * compoundFee) / 10000;
            IERC20(lpToken).transfer(accountant, userCompoundFee);
            IERC20(lpToken).transfer(msg.sender, totalLp - userCompoundFee);
            totalVesting[lpToken] -= totalLp;
        }
        if (totalCrss > 0) {
            userCrssWithdrawn[msg.sender][_pid] += totalCrss;

            address referrer = ICrssReferral(referralContract).getReferrer(
                msg.sender
            );
            if (referrer != address(0)) {
                // referralRewards[referrer] -= (totalCrss / 100);
                pendingReferralRewards[referrer] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    referrer,
                    totalCrss / 100
                );
            } else {
                pendingReferralRewards[accountant] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    accountant,
                    totalCrss / 100
                );
            }
            IERC20(crssAddress).transfer(msg.sender, totalCrss);
            totalVesting[crssAddress] -= totalCrss;
        }

        emit BulkHarvest(msg.sender, _pid, totalCrss, totalLp);
    }

    function sCrssBulkHarvest(uint256 _pid) public nonReentrant {
        uint256 totalCrss;
        uint256 totalLp;
        address lpToken = address(0);
        for (uint256 i = 0; i < vestingInstances[msg.sender][_pid].length; i) {
            VestingInstance memory vestingInstance = vestingInstances[
                msg.sender
            ][_pid][i];
            if (
                vestingInstance.vestingPeriod +
                    vestingInstance.startTimestamp <=
                block.timestamp
            ) {
                if (vestingInstance.tokenAddress != crssAddress) {
                    totalLp += vestingInstance.tokenAmount;
                    if (lpToken == address(0)) {
                        lpToken = vestingInstance.tokenAddress;
                    }
                } else {
                    totalCrss += vestingInstance.tokenAmount;
                }

                vestingInstances[msg.sender][_pid][i] = vestingInstances[
                    msg.sender
                ][_pid][vestingInstances[msg.sender][_pid].length - 1];
                vestingInstances[msg.sender][_pid].pop();
            } else i++;
        }
        // require(totalCrss > 0 || totalLp > 0, "vCRSS:No unlocked rewards");
        if (lpToken != address(0)) {
            userLpTokensWithdrawn[msg.sender][_pid] += totalLp;
            uint256 userCompoundFee = (totalLp * compoundFee) / 10000;
            IERC20(lpToken).transfer(accountant, userCompoundFee);
            IERC20(lpToken).transfer(msg.sender, totalLp - userCompoundFee);
            totalVesting[lpToken] -= totalLp;
        }
        if (totalCrss > 0) {
            userCrssWithdrawn[msg.sender][_pid] += totalCrss;

            address referrer = ICrssReferral(referralContract).getReferrer(
                msg.sender
            );
            if (referrer != address(0)) {
                // referralRewards[referrer] -= (totalCrss / 100);
                pendingReferralRewards[referrer] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    referrer,
                    totalCrss / 100
                );
            } else {
                pendingReferralRewards[accountant] -= (totalCrss / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    accountant,
                    totalCrss / 100
                );
            }
            IsCRSS(sCrssAddress).enterFor(totalCrss, msg.sender);
            totalVesting[crssAddress] -= totalCrss;
        }

        emit BulkHarvest(msg.sender, _pid, totalCrss, totalLp);
    }

    function initiateRewardMultiplier(uint16[12] memory _multiplier) private {
        /* require(
            msg.sender == address(this),
            "vCRSS:Called once during contract creation"
        );*/
        for (uint256 i = 0; i < _multiplier.length; i++) {
            uint256 multiplier = uint256(_multiplier[i]);
            rewardMultiplier[i + 1] = multiplier;
        }
    }

    function userPoolVestInfo(address _user, uint256 _pid)
        public
        view
        returns (
            VestingInstance[] memory userVestingInstances,
            uint256 vestingCrss,
            uint256 vestingLpTokens,
            uint256 vestedCrss,
            uint256 vestedLpTokens,
            uint256 withdrawnCrss,
            uint256 withdrawnLpTokens,
            uint256 nextUnlock
        )
    {
        (withdrawnCrss, withdrawnLpTokens) = getUserEarned(_user, _pid);
        (
            vestedCrss,
            vestedLpTokens,
            vestingCrss,
            vestingLpTokens,
            nextUnlock
        ) = getUserVestingVestedAndNextUnlocked(_user, _pid);
        userVestingInstances = getVestInstances(_user, _pid);
    }

    function userFarmPoolInfo(address _user, uint256 _pid)
        public
        view
        returns (
            uint256 stakedLp, //total LP tokens deposited by user in this pool
            uint256 claimableRewards, //amount of CRSS or LP tokens ready to be vested, in CRSS is user is not compounding,in LP token if user is compounding
            uint256 timeUntilWithdrawUnlocked, //amount of time left to wait before withdrawing deposited LP tokens in a locked pool without early withdraw tax
            bool compounding, // same as isUserCompounding()
            VestingInstance[] memory userVestingInstances, //array of all user vesting instances for this pool
            uint256 vestingCrss,
            uint256 vestingLpTokens,
            uint256 vestedCrss, //unlocked/withdrawable crss
            uint256 vestedLpTokens, //unlocked/withdrawable lpTokens
            uint256 withdrawnCrss,
            uint256 withdrawnLpTokens,
            uint256 nextUnlock //time in seconds until next vesting instance is unlocked
        )
    {
        (
            stakedLp,
            claimableRewards,
            timeUntilWithdrawUnlocked,
            compounding
        ) = ICrossFarm(lpFarmAddress).userPoolFarmInfo(_user, _pid);

        (withdrawnCrss, withdrawnLpTokens) = getUserEarned(_user, _pid);
        (
            vestedCrss,
            vestedLpTokens,
            vestingCrss,
            vestingLpTokens,
            nextUnlock
        ) = getUserVestingVestedAndNextUnlocked(_user, _pid);

        userVestingInstances = getVestInstances(_user, _pid);
    }

    function getVestInstances(address _user, uint256 _pid)
        public
        view
        returns (VestingInstance[] memory)
    {
        return vestingInstances[_user][_pid];
    }

    function getUserEarned(address _user, uint256 _pid)
        public
        view
        returns (uint256 withdrawnCrss, uint256 withdrawnLpTokens)
    {
        withdrawnCrss = userCrssWithdrawn[_user][_pid];
        withdrawnLpTokens = userLpTokensWithdrawn[_user][_pid];
    }

    function getMultiplier(uint256 _numOfMonths) public view returns (uint256) {
        return rewardMultiplier[_numOfMonths];
    }

    function getRewardMultiplier(uint256 _numOfMonths, uint256 _reward)
        public
        view
        returns (uint256)
    {
        return rewardMultiplier[_numOfMonths] * _reward;
    }

    function getUserPending(address _user, uint256 _pid)
        public
        view
        returns (uint256 crssVested, uint256 lpTokensVested)
    {
        uint256 currentBlock = block.timestamp;
        address crssToken = crssAddress;
        for (uint256 i = 0; i < vestingInstances[_user][_pid].length; i++) {
            VestingInstance memory userInstance = vestingInstances[_user][_pid][
                i
            ];

            if (
                userInstance.vestingPeriod + userInstance.startTimestamp <=
                currentBlock
            ) {
                if (userInstance.tokenAddress == crssToken) {
                    crssVested += userInstance.tokenAmount;
                } else {
                    lpTokensVested += userInstance.tokenAmount;
                }
            }
        }
    }

    function getUserVestingAndVested(address _user, uint256 _pid)
        public
        view
        returns (
            uint256 crssVested,
            uint256 lpTokensVested,
            uint256 crssVesting,
            uint256 lpTokensVesting
        )
    {
        uint256 currentBlock = block.timestamp;
        address crssToken = crssAddress;
        for (uint256 i = 0; i < vestingInstances[_user][_pid].length; i++) {
            VestingInstance memory userInstance = vestingInstances[_user][_pid][
                i
            ];
            if (userInstance.tokenAddress == crssToken) {
                crssVesting += userInstance.tokenAmount;
                if (
                    userInstance.vestingPeriod + userInstance.startTimestamp <=
                    currentBlock
                ) {
                    crssVested += userInstance.tokenAmount;
                }
            } else {
                lpTokensVesting += userInstance.tokenAmount;
                if (
                    userInstance.vestingPeriod + userInstance.startTimestamp <=
                    currentBlock
                ) {
                    lpTokensVested += userInstance.tokenAmount;
                }
            }
        }
    }

    function getUserVestingVestedAndNextUnlocked(address _user, uint256 _pid)
        public
        view
        returns (
            uint256 crssVested,
            uint256 lpTokensVested,
            uint256 crssVesting,
            uint256 lpTokensVesting,
            uint256 nextUnlocked
        )
    {
        uint256 currentTimestamp = block.timestamp;
        nextUnlocked = type(uint256).max;
        for (uint256 i = 0; i < vestingInstances[_user][_pid].length; i++) {
            VestingInstance memory userInstance = vestingInstances[_user][_pid][
                i
            ];
            uint256 unlockedIn = userInstance.startTimestamp +
                userInstance.vestingPeriod >
                currentTimestamp
                ? (userInstance.startTimestamp + userInstance.vestingPeriod) -
                    currentTimestamp
                : 0;
            if (unlockedIn < nextUnlocked && unlockedIn > 0) {
                nextUnlocked = unlockedIn;
            }
            if (userInstance.tokenAddress == crssAddress) {
                crssVesting += userInstance.tokenAmount;

                if (unlockedIn == 0) {
                    crssVested += userInstance.tokenAmount;
                }
            } else {
                lpTokensVesting += userInstance.tokenAmount;
                if (unlockedIn == 0) {
                    lpTokensVested += userInstance.tokenAmount;
                }
            }
        }
        if (nextUnlocked == type(uint256).max) {
            nextUnlocked = 0;
        }
    }

    function claimRewards(uint256 _pid, uint256 _id) public nonReentrant {
        VestingInstance memory vestingInstance = vestingInstances[msg.sender][
            _pid
        ][_id];
        uint32 vestingDuration = uint32(block.timestamp) -
            uint32(vestingInstance.startTimestamp);
        require(
            vestingDuration >= vestingInstance.vestingPeriod,
            "CRSS: Rewards not unlocked yet "
        );

        uint256 adjustedReward = vestingInstance.tokenAmount;
        if (vestingInstance.tokenAddress != crssAddress) {
            uint256 userCompoundFee = (adjustedReward * compoundFee) / 10000;
            IERC20(vestingInstance.tokenAddress).transfer(
                accountant,
                userCompoundFee
            );
            adjustedReward -= userCompoundFee;

            //totalVesting[vestingInstance.tokenAddress] -= adjustedReward;
            userLpTokensWithdrawn[msg.sender][_pid] += adjustedReward;
        } else {
            address referrer = ICrssReferral(referralContract).getReferrer(
                msg.sender
            );
            if (referrer != address(0)) {
                pendingReferralRewards[referrer] -= (adjustedReward / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    referrer,
                    adjustedReward / 100
                );
            } else {
                pendingReferralRewards[accountant] -= (adjustedReward / 100);
                ICrssReferral(referralContract).recordReferralCommission(
                    accountant,
                    adjustedReward / 100
                );
            }
            userCrssWithdrawn[msg.sender][_pid] += adjustedReward;
        }
        vestingInstances[msg.sender][_pid][_id] = vestingInstances[msg.sender][
            _pid
        ][vestingInstances[msg.sender][_pid].length - 1];
        vestingInstances[msg.sender][_pid].pop();
        IERC20(vestingInstance.tokenAddress).transfer(
            msg.sender,
            adjustedReward
        );
        totalVesting[vestingInstance.tokenAddress] -= adjustedReward;
    }

    function claimRewardsToVault(uint256 _pid, uint256 _id)
        public
        nonReentrant
    {
        VestingInstance memory vestingInstance = vestingInstances[msg.sender][
            _pid
        ][_id];
        require(
            vestingInstance.tokenAddress == crssAddress,
            "vCRSS:Only CRSS rewards allowed"
        );
        uint32 currentTimestamp = uint32(block.timestamp);
        uint32 vestingDuration = currentTimestamp -
            uint32(vestingInstance.startTimestamp);

        require(
            vestingDuration >= vestingInstance.vestingPeriod,
            "vCRSS: Rewards not unlocked yet "
        );

        uint256 adjustedReward = vestingInstance.tokenAmount;

        userCrssWithdrawn[msg.sender][_pid] += adjustedReward;
        address referrer = ICrssReferral(referralContract).getReferrer(
            msg.sender
        );
        if (referrer != address(0)) {
            pendingReferralRewards[referrer] -= (adjustedReward / 100);
            ICrssReferral(referralContract).recordReferralCommission(
                referrer,
                adjustedReward / 100
            );
        } else {
            pendingReferralRewards[accountant] -= (adjustedReward / 100);
            ICrssReferral(referralContract).recordReferralCommission(
                accountant,
                adjustedReward / 100
            );
        }

        vestingInstances[msg.sender][_pid][_id] = vestingInstances[msg.sender][
            _pid
        ][vestingInstances[msg.sender][_pid].length - 1];
        vestingInstances[msg.sender][_pid].pop();
        IsCRSS(sCrssAddress).enterFor(adjustedReward, msg.sender);
        totalVesting[crssAddress] -= adjustedReward;
    }

    function getPendingReferralRewards(address _referrer)
        public
        view
        returns (uint256)
    {
        return pendingReferralRewards[_referrer];
    }

    function changeCompoundFee(uint256 _newFee) public {
        require(msg.sender == controlCenter, "vCRSS:Only Control center");
        require(compoundFee <= 2000, "vCRSS:Max percentage is 20%");
        compoundFee = _newFee;
    }

    function setReferralAddress(address _newAddress) public {
        require(msg.sender == controlCenter, "vCRSS:Only Control center");
        referralContract = _newAddress;
    }

    function setFarmAddress(address _newAddress) public {
        require(msg.sender == controlCenter, "vCRSS:Only Control center");
        lpFarmAddress = _newAddress;
    }

    function setAccountantAddress(address _newAddress) public {
        require(msg.sender == controlCenter, "vCRSS:Only Control center");
        accountant = _newAddress;
    }

    function setControlCenter(address _newAddress) public {
        require(
            msg.sender == adminSetter || msg.sender == controlCenter,
            "vCRSS:Only Control center"
        );
        controlCenter = _newAddress;
    }

    function claimAccountantRewards(address _tokenAddress, uint256 _amount)
        external
    {
        require(msg.sender == accountant, "vCRSS:Only accountant");
        uint256 accountantShare = IERC20(_tokenAddress).balanceOf(
            address(this)
        ) - totalVesting[_tokenAddress];
        require(_amount >= accountantShare, "vCRSS:Exceeds allowed amount");
        IERC20(_tokenAddress).transfer(accountant, _amount);
    }

    //////FOR TESTING
    function unlockVestingInstance(uint256 _pid, uint256 _id) public {
        vestingInstances[msg.sender][_pid][_id].startTimestamp = 0;
    }

    function unlockVestingBulk(uint256 _pid) public {
        VestingInstance[] memory userInstances = vestingInstances[msg.sender][
            _pid
        ];
        for (uint256 i = 0; i < userInstances.length; i++) {
            vestingInstances[msg.sender][_pid][i].startTimestamp = 0;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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