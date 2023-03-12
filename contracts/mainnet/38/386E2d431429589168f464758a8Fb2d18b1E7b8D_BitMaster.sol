// SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.1;

/*
 *  @title Wildland's Master contract
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./IWildlandCards.sol";
import "./BitGold.sol";
import "./BitRAM.sol";

//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once bit is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract BitMaster is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many tokens the user has staked.
        uint256 rewardDebt; // Reward debt.
        uint256 lockedAt;   // Unix time locked at 
    }
    

    // Info of each pool.
    struct PoolInfo {
        IERC20 stakeToken;            // Address of LP token contract.
        uint16 depositFeeBP;      
        uint16 burnDepositFee;        // included in depositFeeBP   
        uint16 withdrawFeeBP;      
        uint16 burnWithdrawFee;       // included in withdrawFeeBP   
        bool requireMembership;  
        uint256 allocPoint;           // How many allocation points assigned to this pool. bits to distribute per block.
        uint256 lastRewardTimestamp;  // Last block timestamp that bits distribution occurs.
        uint256 accBitsPerShare;      // Accumulated bits per share, times 1e12. See below.
        uint256 lockTimer;            // lock counter in seconds (ethereum has non-fixed blocks per day)
        uint256 stakedAmount;        
    }
    

    // The bit TOKEN!
    BitGold public immutable bit;
    // The ram... where rewards are stored until users unstake or collect
    BitRAM public immutable ram;
    uint32 public constant MAX_PERCENT = 1e4; // for avoiding errors while programming, never use magic numbers :)
    uint256 public constant DECIMALS_TOKEN = 1e18;
    uint256 public constant DECIMALS_SHARE_REWARD = 1e18;
    address public constant DEAD_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    // Treasury address.
    address public treasuryaddr;
    uint256 public constant UNITS_PER_DAY = 86400; // 86400 seconds per day
    // bit tokens created per second based on max supply (11m-1m = 10m).
    uint256 public constant bitPerSecond = (10 * 10 ** 6 - 145000) * DECIMALS_TOKEN / (2 * 365 * UNITS_PER_DAY);

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint; // in 1e3
    uint256 public totalAllocPointWithoutPool; // in 1e3
    // The block number when bit mining starts.
    uint256 public startTimestamp; // in 1e0
    bool public paused;
    // codes of affiliatees
    mapping (address => bytes4) public affiliatee;
    // member cards serve as affiliate token to earn part of staking fees that have to be paid when staking (non-inflationary)
    IWildlandCards public immutable wildlandcard;

    // white list addresses as member and exclude from fees (e.g., partner contracts)
    mapping (address => bool) public isWhiteListed;
    mapping (address => bool) public IsExcludedFromFees;

    event EmitDeposit(address indexed user, uint256 indexed pid, uint256 amount, uint256 lockedFor);
    event EmitWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmitSet(uint256 pid, uint256 allocPoint, uint256 lockTimer, uint16 depositFeeBP, uint16 burnDepositFeeBP, uint16 withdrawFeeBP, uint16 burnWithdrawFeeBP, bool isMember);
    event EmitAdd(address token, uint256 allocPoint, uint256 lockTimer, uint16 depositFeeBP, uint16 burnDepositFeeBP, uint16 withdrawFeeBP, uint16 burnWithdrawFeeBP, bool isMember);
    event EmitTreasuryChanged(address _new);
    event CodeSet(address indexed user, bytes4 code);
    event SetStartTimestamp(uint256 startTimestamp);
    event ExcludedFromFees(address indexed user, bool value);
    event WhiteListed(address indexed user, bool value);
    event SetPaused(bool paused);

    constructor(
        BitGold _bit,
        BitRAM _ram,
        IWildlandCards _wildlandcard,
        address _treasuryaddr
    ) {
        bit = _bit;
        ram = _ram;
        wildlandcard = _wildlandcard;
        treasuryaddr = _treasuryaddr;
        // staking pool
        poolInfo.push(PoolInfo({
            stakeToken: _bit,
            allocPoint: 1000,
            lastRewardTimestamp: startTimestamp,
            accBitsPerShare: 0,
            lockTimer: 0,
            depositFeeBP: 300,
            burnDepositFee: 200,
            withdrawFeeBP: 300,
            burnWithdrawFee: 200,
            requireMembership: true,
            stakedAmount: 0
        }));
        totalAllocPoint = 1000;
    }

    /// SECTION MODIFIERS

    /**
     * @dev Validate if pool exists
     */
    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "validatePool: pool exists?");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Check if membership is required and if so, check if msg.sender has membership (see isMember function).
     */
    modifier requireMembership(uint256 _pid) {
        // either affiliate code or member card required
        require(!poolInfo[_pid].requireMembership || isMember(msg.sender), "restricted: affiliate code required.");
        _;
    }

    /// SECION POOL AND MINE DATA

    /** 
     * @dev Add a new lp to the pool. Can only be called by the owner.
     * Fee: Max fee 10% = fee base points <= 1000 (MAX_PERCENT = 1e4).
     * _lockTimer is measured in unix time.
     * onlyOwner protected.
     * @param _allocPoint allocation points
     * @param _token erc20 token address to be staked
     * @param _lockTimer lock timer in seconds
     * @param _depositFeeBP deposit fee base points
     * @param _burnDepositFee burn deposit fee base points
     * @param _withdrawFeeBP withdraw fee base points
     * @param _burnWithdrawFee burn withdraw fee base points
     * @param _withUpdate true if pools should be updated before change
     * @param _requireMembership is user membership required for staking?
     */
    function add(uint256 _allocPoint, IERC20 _token, uint256 _lockTimer, uint16 _depositFeeBP, uint16 _burnDepositFee, uint16 _withdrawFeeBP, uint16 _burnWithdrawFee, bool _withUpdate, bool _requireMembership) public onlyOwner {
        require(_depositFeeBP <= MAX_PERCENT.div(10), "add: invalid deposit fee basis points"); // max 10%
        require(_burnDepositFee <= _depositFeeBP, "add: invalid burn deposit fee"); // max 100% of deposit fee
        require(_withdrawFeeBP <= MAX_PERCENT.div(10), "add: invalid withdraw fee basis points"); // max 10%
        require(_burnWithdrawFee <= _withdrawFeeBP, "add: invalid burn withdraw fee"); // max 100% of withdraw fee
        require(_lockTimer <= 30 days, "add: invalid time locked. Max allowed is 30 days in seconds");
        if (_withUpdate) {
            _massUpdatePools();
        }
        // BEP20 interface check
        _token.balanceOf(address(this));
        // check lp token exist -> revert if you try to add same lp token twice
        uint256 lastRewardTimestamp = block.timestamp > startTimestamp ? block.timestamp : startTimestamp;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        totalAllocPointWithoutPool = totalAllocPointWithoutPool.add(_allocPoint);
        // add pool info
        poolInfo.push(PoolInfo({
            stakeToken: _token, // the lp token
            allocPoint: _allocPoint, //allocation points for new farm. 
            lastRewardTimestamp: lastRewardTimestamp, // last block that got rewarded
            accBitsPerShare: 0, 
            lockTimer: _lockTimer,
            depositFeeBP: _depositFeeBP,
            burnDepositFee: _burnDepositFee,
            withdrawFeeBP: _withdrawFeeBP,
            burnWithdrawFee: _burnWithdrawFee,
            requireMembership: _requireMembership,
            stakedAmount: 0
        }));
        updateStakingPool();
        emit EmitAdd(address(_token), _allocPoint, _lockTimer, _depositFeeBP, _burnDepositFee, _withdrawFeeBP, _burnWithdrawFee, _requireMembership);
    }

    /** 
     * @dev Update the given pool's bit allocation point. Can only be called by the owner.
     * Fee: Max fee 10% = fee base points <= 1000 (MAX_PERCENT = 1e4).
     * _lockTimer is measured in seconds.
     * onlyOwner protected.
     * @param _pid pool id
     * @param _allocPoint allocation points
     * @param _lockTimer lock timer in seconds
     * @param _depositFeeBP deposit fee base points
     * @param _burnDepositFee burn deposit fee base points
     * @param _withdrawFeeBP withdraw fee base points
     * @param _burnWithdrawFee burn withdraw fee base points
     * @param _withUpdate true if pool should be updated before change
     * @param _requireMembership is user membership required for staking?
     */
    function set(uint256 _pid, uint256 _allocPoint, uint256 _lockTimer, uint16 _depositFeeBP, uint16 _burnDepositFee, uint16 _withdrawFeeBP, uint16 _burnWithdrawFee, bool _withUpdate, bool _requireMembership) public onlyOwner validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        require(_depositFeeBP <= MAX_PERCENT.div(10), "set: invalid deposit fee basis points"); // max 10%
        require(_burnDepositFee <= _depositFeeBP, "set: invalid burn deposit fee"); // max 100% of deposit fee
        require(_withdrawFeeBP <= MAX_PERCENT.div(10), "set: invalid withdraw fee basis points"); // max 10%
        require(_burnWithdrawFee <= _withdrawFeeBP, "set: invalid burn withdraw fee"); // max 100% of withdraw fee
        require(_lockTimer <= 30 days, "set: invalid time locked. Max allowed is 30 days in seconds");
        if (_withUpdate) 
            _massUpdatePools();
        uint256 prevAllocPoint = pool.allocPoint;
        // update values
        pool.allocPoint = _allocPoint;
        pool.depositFeeBP = _depositFeeBP;
        pool.burnDepositFee = _burnDepositFee;
        pool.withdrawFeeBP = _withdrawFeeBP;
        pool.burnWithdrawFee = _burnWithdrawFee;
        pool.lockTimer = _lockTimer;
        pool.requireMembership = _requireMembership;
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            // update alloc points for pools other than pool _pid = 0
            if (_pid != 0)
                totalAllocPointWithoutPool = totalAllocPointWithoutPool.sub(prevAllocPoint).add(_allocPoint);
            updateStakingPool();
        }
        emit EmitSet(_pid, _allocPoint, _lockTimer, _depositFeeBP, _burnDepositFee, _withdrawFeeBP, _burnWithdrawFee, _requireMembership);
    }
    /**
     * @dev Update reward variables for all pools. Be careful of gas spending! (external)
     * nonReentrant protected.
     */
    function massUpdatePools() external nonReentrant {
        _massUpdatePools();
    }

    /**
     * @dev Update reward variables for all pools. Be careful of gas spending!
     */
    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    /**
     * @dev Update multiplier of staking pool (_pid=0).
     */
    function updateStakingPool() internal {
        uint256 points = totalAllocPointWithoutPool;
        uint256 prevAllocPoints = poolInfo[0].allocPoint;
        // won't update unless allocation points of pool > 0 
        if (points != 0 && prevAllocPoints != 0) {
            points = points.div(3);
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoints).add(points);
            poolInfo[0].allocPoint = points;
        }
    }

    /**
     * @dev Return reward multiplier based on _from and _to block number.
     */
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (paused)
            return 0;
        return _to.sub(_from);
    }

    /**
     * @dev Apply having every 365 * UNITS_PER_DAY seconds (approx 1 year).
     * Given _amount is divided by 2 ** i where i = number of passed years (>= 0).
     * @param _amount amount before halving
     * @param testcounter counter to check for next halving
     * @return final amount
     */
    function applyHalving(uint256 _amount, uint256 testcounter) public view returns (uint256) {
        // start block not reached -> no reward
        // start block not set -> no reward
        if (block.timestamp < startTimestamp || startTimestamp == 0)
            return 0;
        // current active block counter
        uint256 _seconds = block.timestamp + testcounter - startTimestamp;
        // halving every 365 days (approx) -> every 365 * UNITS_PER_DAY blocks
        uint256 i = _seconds / (UNITS_PER_DAY * 365); // 0 if less than 365 days have passed
        return _amount / (2**i);
    }
    
    /**
     * @dev Minting info per block based on halving and pause state.
     * @return current btg per block
     */
    function mintingInfo() external view returns(uint256) {
		return applyHalving(bitPerSecond, 0);
    }    
    
    /**
     * @dev Update pool (external)
     * nonReentrant protected.
     */
    function updatePool(uint256 _pid) external nonReentrant {
        _updatePool(_pid);
    }

    /**
     * @dev Update pool (internal).
     * @param _pid pool id
     */
    function _updatePool(uint256 _pid) internal validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        uint256 lastTimestamp = pool.lastRewardTimestamp;
        if (block.timestamp <= lastTimestamp) {
            return;
        }
        uint256 lpSupply = pool.stakedAmount;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(lastTimestamp, block.timestamp);
        // bit reward
        uint256 bitReward = applyHalving(multiplier.mul(bitPerSecond).mul(pool.allocPoint).div(totalAllocPoint), 0);
        if (bitReward != 0) {
            uint256 fee_tres = bitReward.div(10); 
            // 1) Mint to ram
            bit.mint(address(ram), bitReward);
            // 2) transfer fee from ram to treasury
            safeBitTransfer(treasuryaddr, fee_tres);
            // 3) bit reward is deducted by fee
            bitReward = bitReward.sub(fee_tres);
            // set new distribution per LP
            pool.accBitsPerShare = pool.accBitsPerShare.add(bitReward.mul(DECIMALS_SHARE_REWARD).div(lpSupply));
        }
        pool.lastRewardTimestamp = block.timestamp;
    }

    /**
     * @dev Returns pending bits for given pool _pid.
     * @param _pid pool id
     * @param _user user address
     * @return pending btg to be collected
     */
    function pendingBit(uint256 _pid, address _user) external view returns (uint256) {
        // get pool info in storage
        PoolInfo storage pool = poolInfo[_pid];
        // get user info in storage
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBitsPerShare = pool.accBitsPerShare;
        uint256 lpSupply = pool.stakedAmount;
        uint256 lastTimestamp = pool.lastRewardTimestamp;
        if (block.timestamp > lastTimestamp && lpSupply != 0 && totalAllocPoint != 0) {
            uint256 multiplier = getMultiplier(lastTimestamp, block.timestamp);
            // bits per block * 90% 
            uint256 bitReward = applyHalving(multiplier.mul(bitPerSecond).mul(pool.allocPoint).div(totalAllocPoint), 0);
            accBitsPerShare = accBitsPerShare.add(bitReward.mul(9).div(10).mul(DECIMALS_SHARE_REWARD).div(lpSupply));
        }
        return user.amount.mul(accBitsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
    }
    
    /**
     * @dev Remaining locked time in seconds for given _pid and _user.
     * @param _pid pool id
     * @param _user user address
     * @return seconds until unlock (0 if unlocked)
     */
    function timeToUnlock(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        uint256 _time_required = user.lockedAt + pool.lockTimer;
        if (_time_required <= block.timestamp)
            return 0;
        else
            return _time_required - block.timestamp;
    }

    /// SECTION AFFILIATE

    /**
     * @dev check if _user is member.
     * Member means: _user has either an affiliate code set (see setCode function), owns or has owned a wildlands member card.
     * or is a whitelisted address, e.g., a partner contract.
     * @param _user user address
     * @return true if user is member (if wmc card is sold, users can still withdraw)
     */
    function isMember(address _user) public view returns(bool) {
        // either be an affiliator or an affiliatee
        // affiliators who sold their member card are still considered members
        return affiliatee[_user] != 0x0 || wildlandcard.getCodeByAddress(_user) != 0x0 || isWhiteListed[_user];
    }

    /**
     * @dev Get affiliate base points for a given token id.
     * The affiliate mechanisms has 4 levels (3 vip and 1 standard). 
     * Affiliates get a portion of the fees based on the member level. 
     * There are 1000 VIP MEMBER CARDS (id 1 - 1000) and INFINITY STANDARD MEMBER CARDS (1001+).
     * @param _tokenId a token id
     * @return affiliate base points of affiliatee
     */
    function getAffiliateBasePoints(uint256 _tokenId) public pure returns (uint256) {
        // check affiliate id
        if (_tokenId == 0)
            return 0;
        else if (_tokenId <= 100) {
            // BIT CARD MEMBER
            return 20; // 20 %
        }
        else if (_tokenId <= 400) {
            // GOLD CARD MEMBER
            return 15; // 15 %
        }
        else if (_tokenId <= 1000) {
            // BLACK CARD MEMBER
            return 10; // 10 %
        }
        // STANDARD MEMBER CARD
        return 5; // 5 %
    }

    /**
     * @dev Set affiliate code
     * The affiliate code of msg.sender is stored in affiliatee[msg.sender]. 
     * Affiliate fees are to the current token owner that is linked to the provided _code.
     * nonReentrant protected.
     * @param _code affiliate code
     */
    function setCode(bytes4 _code) public nonReentrant {
        require(affiliatee[msg.sender] == 0x0, "setCode: Affiliate code already set");
        require(wildlandcard.getTokenIdByCode(_code) != 0 && _code != 0x0, "setCode: Code is not valid");
        affiliatee[msg.sender] = _code;
        emit CodeSet(msg.sender, _code);
    }

    /**
     * @dev Process fee, burn fee and affiliate fees.
     * If burn fee is lower than total fee, an affiliate fee is computed if token_id > 0.
     * Affiliate fees are sent to the CURRENT token owner.
     * Difference of _amount_fee - (_burn_fee + affiliateFee) is sent to treasury.
     * @param _pid pool id
     * @param _amount_fee full fee amount
     * @param _burn_fee burn fee amount
     */
    function handleFee(uint256 _pid, uint256 _amount_fee, uint256 _burn_fee) internal {
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 token = pool.stakeToken;
        // burn portion of fees if > 0
        if (_burn_fee > 0)
            token.safeTransfer(DEAD_ADDRESS, _burn_fee);
        // transfer fees - burn to treasury/affiliates if > 0              
        if (_burn_fee < _amount_fee) {
            // get transferrable fee
            uint256 feeTransferable = _amount_fee.sub(_burn_fee);
            bytes4 code = affiliatee[msg.sender];
            uint256 tokenId = wildlandcard.getTokenIdByCode(code);
            uint256 affiliateFee = 0;
            if (tokenId > 0) {
                // compute affiliate fee (definitely > 0 since feeTransferable > 0 at this point)
                uint256 affiliateBasePoints = getAffiliateBasePoints(tokenId);
                affiliateFee = feeTransferable.mul(affiliateBasePoints).div(100);
                // transfer affiliate fee to owner of member card id
                token.safeTransfer(wildlandcard.ownerOf(tokenId), affiliateFee);
            }
            // transfer to treasury
            token.safeTransfer(treasuryaddr, feeTransferable.sub(affiliateFee));
        }
    }

    /// USER ACTIONS

    /**
     * @dev Deposit token _amount in pool _pid
     * Checks if membership is required and validates given pool id _pid.
     * nonReentrant protected.
     * @param _pid pool id
     * @param _amount amount to stake
     */
    function deposit(uint256 _pid, uint256 _amount) external validatePool(_pid) nonReentrant requireMembership(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        _updatePool(_pid);
        if (user.amount > 0) {
            // transfer pending nuts to user since reward debts are updated below
            uint256 pending = user.amount.mul(pool.accBitsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
            if(pending > 0) {
                safeBitTransfer(msg.sender, pending);
            }
        }
        uint256 lockedFor = 0;
        if (_amount > 0) {
            uint256 amount_fee = 0;
            uint256 amount_old = user.amount; // needed for avg lock computation
            // check transfer to also allow fee on transfer
            uint256 preStakeBalance = pool.stakeToken.balanceOf(address(this));
            pool.stakeToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 postStakeBalance = pool.stakeToken.balanceOf(address(this));
            // transferred/staked amount is difference between post and pre
            _amount = postStakeBalance.sub(preStakeBalance);
            if(pool.depositFeeBP > 0 && !IsExcludedFromFees[msg.sender]){
                // depositFeeBP is factor 10000 (MAX_PERCENT) overall
                amount_fee = _amount.mul(pool.depositFeeBP).div(MAX_PERCENT);
                uint256 burn_fee = amount_fee.mul(pool.burnDepositFee).div(pool.depositFeeBP);
                handleFee(_pid, amount_fee, burn_fee);
            }
            // update stakedAmount
            pool.stakedAmount = pool.stakedAmount.add(_amount).sub(amount_fee);
            // store user amount
            user.amount = amount_old.add(_amount).sub(amount_fee);
            // set new locked amount based on average locking window
            lockedFor = timeToUnlock(_pid, msg.sender);
            // avg lockedFor: (lockedFor * amount_old + lockTimer * (_amount - amount_fee)) / user.amount
            lockedFor = lockedFor.mul(amount_old).add(pool.lockTimer.mul(_amount.sub(amount_fee))).div(user.amount);
            // set new locked at 
            user.lockedAt = block.timestamp.sub(pool.lockTimer.sub(lockedFor));
        }
        // user reward debt since there are already many nuts that had been produced before :)
        user.rewardDebt = user.amount.mul(pool.accBitsPerShare).div(DECIMALS_SHARE_REWARD);
        emit EmitDeposit(msg.sender, _pid, _amount, lockedFor);
    }

    /**
     * @dev Withdraw token _amount from pool _pid
     * Membership is not required, i.e., user can always withdraw their token regardless of membership mechanism.
     * Validates given pool id _pid.
     * nonReentrant protected.
     * @param _pid pool id
     * @param _amount amount to unstake
     */
    function withdraw(uint256 _pid, uint256 _amount) external validatePool(_pid) nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: Hm I am not sure you have that amount staked here.");
        // check locked timer
        require(timeToUnlock(_pid, msg.sender) == 0, "withdraw: tokens are still locked.");
        _updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accBitsPerShare).div(DECIMALS_SHARE_REWARD).sub(user.rewardDebt);
        if(pending > 0) {
            safeBitTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            // reduce amount before transferring
            // update stakedAmount
            pool.stakedAmount = pool.stakedAmount.sub(_amount);
            user.amount = user.amount.sub(_amount);
            uint256 amount_fee = 0;
            if (pool.withdrawFeeBP > 0 && !IsExcludedFromFees[msg.sender]) {
                amount_fee = _amount.mul(pool.withdrawFeeBP).div(MAX_PERCENT);
                uint256 burn_fee = amount_fee.mul(pool.burnWithdrawFee).div(pool.withdrawFeeBP);
                handleFee(_pid, amount_fee, burn_fee);
            }
            // transfer token minus penalty fee
            pool.stakeToken.safeTransfer(address(msg.sender), _amount.sub(amount_fee));
        }
        // update reward debts
        user.rewardDebt = user.amount.mul(pool.accBitsPerShare).div(DECIMALS_SHARE_REWARD);
        emit EmitWithdraw(msg.sender, _pid, _amount);
    }

    /// SECTION HELPERS

    /**
     * @dev Safe bit transfer function, just in case if rounding error causes pool to not have enough bits.
     * @param _to destination address
     * @param _amount token amount to be transferred to address _to
     */
    function safeBitTransfer(address _to, uint256 _amount) internal {
        ram.safeBitTransfer(_to, _amount);
    }

    /**
     * @dev Update treasury address by the previous treasury address.
     * Can only be called by current treasury address. 
     * @param _treasuryaddr new treasury address
     */
    function tres(address _treasuryaddr) public {
        require(msg.sender == treasuryaddr, "treasury: wut?");
        require(_treasuryaddr != address(0), "treasury: 0x0 address is not the best idea here");
        treasuryaddr = _treasuryaddr;
        emit EmitTreasuryChanged(_treasuryaddr);
    }

    /// SECTION ADMIN 

    /**
     * @dev Set start block any time after deployment.
     * Can only be called once if startTimestamp == 0.
     * onlyOwner protected.
     * @param _timestamp unix timestamp
     */
    function setStartTimestamp(uint256 _timestamp) public onlyOwner {
        require(
            _timestamp >= block.timestamp,
            "set startTimestamp: can not start in past"
        );
        require(
            startTimestamp == 0,
            "set startTimestamp: start block already set"
        );
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardTimestamp = _timestamp;
        }
        startTimestamp = _timestamp;
        emit SetStartTimestamp(_timestamp);
    }
    
    /**
     * @dev Pause minting.
     * Optional: all pools are updated before changing pause state.
     * onlyOwner protected.
     * @param _paused paused?
     * @param _withUpdate should pools be updated first?
     */
    function setPaused(bool _paused, bool _withUpdate) external onlyOwner {
        // only in case of emergency.
        if (_withUpdate) {
            // update all pools before activation/deactivation
            _massUpdatePools();
        }
        paused = _paused;  
        emit SetPaused(_paused);
    }

    /**
     * @dev Whitelist address -> Makes _address a member. Useful for partner contracts.
     * onlyOwner protected.
     * @param _address address to be whitelisted
     * @param _value enable/disable?
     */
    function whiteListAddress(address _address, bool _value) external onlyOwner {
        // whitelist addresses as members, such as partner contracts    
        isWhiteListed[_address] = _value;  
        emit WhiteListed(_address, _value);   
    }

    /**
     * @dev Exclude address from fee -> Useful for partner contracts that cannot handle fees.
     * onlyOwner protected.
     * @param _address address to be excluded from fees
     * @param _value enable/disable?
     */
    function excludeFromFees(address _address, bool _value) external onlyOwner {
        // whitelist addresses as non-fee-payers, such as partner contracts  
        IsExcludedFromFees[_address] = _value; 
        emit ExcludedFromFees(_address, _value);  
    }
}

// SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.8.1;

/*
 *  @title Wildland's RAM for tokens
 *  RAM for Bits... Makes sense? Of course :)
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BitRAM is Ownable {
    using SafeERC20 for ERC20;

    ERC20 public immutable token;

    /**
     * @param _token erc20 token address
     */
    constructor(
        ERC20 _token
    ) {
        token = _token;
    }

    /**
     * @dev Safe token transfer function, just in case if rounding error
     * @param _to destination address
     * @param _amount token amount to be transferred to address _to
     */
    function safeBitTransfer(address _to, uint256 _amount) external onlyOwner {
        uint256 bitBal = token.balanceOf(address(this));
        if (_amount > bitBal) {
            if (bitBal > 0)
                token.safeTransfer(_to, bitBal);
        } else {
            if (_amount > 0)
                token.safeTransfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 *  @title Wildland's Token
 *  Copyright @ Wildlands
 *  App: https://wildlands.me
 */

contract BitGold is ERC20("Bitgold", "BTG"), Ownable {

    event EmitMint(address to, uint256 amount);

    constructor(address treasury) {
        _mint(treasury, 1e6 * 10 ** decimals());
        _mint(treasury, 145000 * 10 ** decimals());
    }

    /**
     * @dev Creates `_amount` token to `_to`. Must only be called by the owner (Mine Master).
     * @param _to destination address
     * @param _amount token amount to be minted to address _to
     */
    function  mint(address _to, uint256 _amount) public onlyOwner{
        _mint(_to, _amount);
        emit EmitMint(_to, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWildlandCards is IERC721 {

    function mint(address _to, uint256 _cardId) external;

    function isCardAvailable(uint256 cardId) external view returns (bool);

    function exists(uint256 _tokenId) external view returns (bool);

    function existsCode(bytes4 _code) external view returns (bool) ;

    function getTokenIdByCode(bytes4 _code) external view returns (uint256);

    function getCodeByAddress(address _address) external view returns (bytes4);

    function cardIndex(uint256 cardId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

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
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}