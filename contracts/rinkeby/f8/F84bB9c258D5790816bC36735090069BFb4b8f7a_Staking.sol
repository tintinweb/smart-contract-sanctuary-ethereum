// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

import "./IAuthority.sol";
import "./SafeMath.sol";

contract AuthorityControlled {
    using SafeMath for uint256;
    
    event AuthorityUpdated(address indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    IAuthority public authority;

    constructor(address _authority) {
        _setAuthority(_authority);
    }

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyApprover() {
        bool isApprover;
        uint256 idx;
        (isApprover, idx) = authority.checkIsApprover(msg.sender);
        require(isApprover, UNAUTHORIZED);
        _;
    }

    function setAuthority(address _newAuthority) external onlyOwner {
        _setAuthority(_newAuthority);
    }

    function _setAuthority(address _newAuthority) private {
        authority = IAuthority(_newAuthority);
        emit AuthorityUpdated(_newAuthority);
    }

    function checkRate(uint256 _length) public view returns (bool) {
        return authority.checkRate(_length);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

interface IAuthority {
    /* ========== EVENTS ========== */
    event OwnerPushed(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event OwnerPulled(
        address indexed from,
        address indexed to,
        bool _effectiveImmediately
    );
    event AddApprover(address addrs);
    event DeleteApprover(address addrs);
    event SetRate(uint256 oldRate, uint256 newRate);

    /* ========== VIEW ========== */
    function owner() external view returns (address);

    function checkIsApprover(address addr) external view returns (bool, uint256);

    function approveRate() external view returns (uint256);

    function checkRate(uint256 _length) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

interface IERC20_CHIMP {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + (a % b)); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

import "../IERC20_CHIMP.sol";
import "./IERCExtend.sol";

interface IChimp is IERC20_CHIMP, IERCExtend {
    
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

interface IERCExtend {
    function mint(address account_, uint256 amount_) external;
    function burn(uint256 amount_) external;
    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.7;

import "../SafeMath.sol";
import "../IERC20_CHIMP.sol";
import "../AuthorityControlled.sol";
import "./IChimp.sol";

// Staking is the master of Chimp. He can make Chimp and he is a fair guy.
contract Staking is AuthorityControlled {
    using SafeMath for uint256;

    // Info of each user.
    struct StakeInfo {
        uint256 amount;         // Total amount currently in mining
        uint256 rewardDebt;     // Reward debt
        uint256 totalReward;    // Total reward
    }

    // Deposit or withdraw details record
    struct StakeRecord {
        // wallet address
        address addr;
        // The amount of this pledge
        uint256 amount;
        // Operation type, 1=deposit, 2=withdraw, 3=receive reward
        uint8 opType;
        // Earnings this time
        uint256 reward;
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20_CHIMP lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Chimps to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Chimps distribution occurs.
        uint256 accChimpPerShare;   // Accumulated Chimps per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 totalStake; // The total amount of current stake
    }

    enum Status {
        Mining,
        Pause,
        Finished
    }

    // The Chimp TOKEN!
    IChimp public chimp;
    // Dev address, is reward send from address
    address public devaddr;
    // Deposit fee receive address
    address public feeAddress;
    // Reward send from address
    // address public rewardAddress;
    // Chimp tokens created per block.
    uint256 public chimpPerBlock;
    // Bonus muliplier for early chimp makers.
    uint256 public constant BONUS_MULTIPLIER = 1;

    // Info of each pool.
    PoolInfo[] public poolInfos;
    // Info of each user that stakes LP tokens
    mapping (uint256 => mapping (address => StakeInfo)) public stakeInfos;
    // The logs of deposit or withdraw
    mapping (uint256 => StakeRecord[]) public stakeRecords;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Chimp mining starts.
    uint256 public startBlock;
    // Global Status
    Status public status;

    address[] public payoutApprove;

    address public payoutAddr;

    modifier onlyMining() {
        require(status == Status.Mining, "StatusError: The status is not mining now");
        _;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event StatusChanged(Status status);

    constructor (
        IChimp _chimp,
        address _devaddr,
        address _feeAddress,
        uint256 _chimpPerBlock,
        // uint256 _startBlock,
        address authority_
    ) AuthorityControlled(authority_) {
        chimp = _chimp;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        chimpPerBlock = _chimpPerBlock;
        // startBlock = _startBlock;
    }

    // Returns the total length of the pool
    function poolLength() external view returns (uint256) {
        return poolInfos.length;
    }

    // Returns the total stake/unstake length of a pool
    function pidRecordLength(uint256 _pid) external view returns (uint256) {
        return stakeRecords[_pid].length;
    }

    // Add a new lp to the pool. Can only be called by the manager.
    // DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20_CHIMP _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfos.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accChimpPerShare: 0,
            depositFeeBP: _depositFeeBP,
            totalStake: 0
        }));
    }

    // Update the given pool's Chimp allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfos[_pid].allocPoint).add(_allocPoint);
        poolInfos[_pid].allocPoint = _allocPoint;
        poolInfos[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending Chimps on frontend.
    function pendingChimp(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][_user];
        uint256 accChimpPerShare = pool.accChimpPerShare;
        uint256 lpSupply = pool.totalStake;
        // LP decimal place handling
        uint256 decimals = 10**(18 - chimp.decimals());
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 chimpReward = multiplier.mul(chimpPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accChimpPerShare = accChimpPerShare.add(chimpReward.mul(decimals).div(lpSupply));
        }
        return user.amount.mul(accChimpPerShare).div(decimals).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfos.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfos[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lpSupply = pool.totalStake;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 chimpReward = multiplier.mul(chimpPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        /*// Give an additional 10% of the reward to the devaddr if the devaddr has been set
        if (devaddr != address(0)) {
            // chimp.mint(devaddr, chimpReward.div(10));
            chimp.transferFrom(rewardAddress, devaddr, chimpReward.div(10));
        }*/
        // chimp.mint(address(this), chimpReward);
        uint256 decimals = 10**(18 - chimp.decimals());
        pool.accChimpPerShare = pool.accChimpPerShare.add(chimpReward.mul(decimals).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to Staking for Chimp allocation.
    function deposit(uint256 _pid, uint256 _amount) public onlyMining {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][msg.sender];
        updatePool(_pid);
        uint256 pending;
        uint256 decimals = 10**(18 - chimp.decimals());
        if (user.amount > 0) {
            pending = user.amount.mul(pool.accChimpPerShare).div(decimals).sub(user.rewardDebt);
            if(pending > 0) {
                // safeChimpTransfer(msg.sender, pending);
                chimp.transferFrom(devaddr, msg.sender, pending);
                user.totalReward = user.totalReward.add(pending);
            }
        }
        uint256 _realAmount = _amount;
        if(_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0 && feeAddress != address(0)){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.transfer(feeAddress, depositFee);
                _realAmount = _realAmount.sub(depositFee);
                user.amount = user.amount.add(_realAmount);
            }else{
                user.amount = user.amount.add(_amount);
            }
        }
        pool.totalStake = pool.totalStake.add(_realAmount);
        user.rewardDebt = user.amount.mul(pool.accChimpPerShare).div(decimals);
        stakeRecords[_pid].push(StakeRecord({addr: msg.sender, amount: _realAmount, opType: _amount > 0 ? 1 : 3, reward: pending}));
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from Staking.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: insufficient balance");
        updatePool(_pid);
        // LP decimal place handling
        uint256 decimals = 10**(18 - chimp.decimals());
        uint256 pending = user.amount.mul(pool.accChimpPerShare).div(decimals).sub(user.rewardDebt);
        if(pending > 0) {
            // safeChimpTransfer(msg.sender, pending);
            chimp.transferFrom(devaddr, msg.sender, pending);
            user.totalReward = user.totalReward.add(pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        pool.totalStake = pool.totalStake.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accChimpPerShare).div(decimals);
        stakeRecords[_pid].push(StakeRecord({addr: msg.sender, amount: _amount, opType: _amount > 0 ? 2 : 3, reward: pending}));
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfos[_pid];
        StakeInfo storage user = stakeInfos[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.transfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Destroy will set the status to Finished, and transfer all refunds of this contract to the given receiveAddress
    function extractAllRefunds(address receiveAddress) private {
        require(address(0) != receiveAddress, "extractAllRefunds: receiveAddress cannot be null address");
        for (uint256 i = 0; i < poolInfos.length; i++) {
            uint256 balance = poolInfos[i].lpToken.balanceOf(address(this));
            if (balance > 0) {
                poolInfos[i].lpToken.transfer(receiveAddress, balance);
            }
        }
    }

    function payout(address _addr) public virtual onlyApprover {
        require(status == Status.Finished, "payout: Cannot payout if status is not finished");
        require(_addr != address(0), "payout: addr can't be null");
        require(payoutAddr == address(0) || (payoutAddr == _addr), "Apayout: illegal addr");
        bool isPayout;
        uint256 idx;
        (isPayout, idx) = checkPayout(msg.sender);
        require(!isPayout, "payout: approve payout repeat");
        payoutApprove.push(msg.sender);
        if (checkRate(payoutApprove.length)) {
            extractAllRefunds(_addr);
            delete payoutApprove;
            delete payoutAddr;
            return;
        }
        if (payoutAddr == address(0)) {
            payoutAddr = _addr;
        }
    }

    function checkPayout(address addr) public view returns (bool, uint256) {
        for (uint256 i = 0; i < payoutApprove.length; i++) {
            if (payoutApprove[i] == addr) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function safeChimpTransfer(address _to, uint256 _amount) internal {
        uint256 chimpBal = chimp.balanceOf(address(this));
        if (_amount > chimpBal) {
            chimp.transfer(_to, chimpBal);
        } else {
            chimp.transfer(_to, _amount);
        }
    }

    function setDev(address _devaddr) public onlyOwner {
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public onlyOwner {
        feeAddress = _feeAddress;
    }

    function setChimp(address _chimp) public onlyOwner {
        require(address(0) == _chimp, "setChimp: chimp can't be null address");
        chimp = IChimp(_chimp);
    }

    function setChimpPerBlock(uint256 _chimpPerBlock) public onlyOwner {
        massUpdatePools();
        chimpPerBlock = _chimpPerBlock;
    }

    function setStatus(Status _status) external onlyOwner {
        require(status != Status.Finished, "setStatus: Cannot modify status after finished");
        status = _status;
        emit StatusChanged(_status);
    }
}