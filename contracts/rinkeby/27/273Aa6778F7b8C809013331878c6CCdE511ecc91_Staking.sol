// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is Ownable, Pausable {
    
    // ================================================ admin ===========================================================================

    address public admin;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert("NOT Admin");
        }
        _;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    // ==================================================== pool =======================================================================

    enum PoolStatus {AVAILABLE, PAUSE}  // khả dụng <> dừng hoạt động

    struct Pool {       
        uint256 apy;            // đơn vị: phần vạn * 10000 (30,05% *10000 = 3005)
        uint256 duration;       // đơn vị: ngày
        PoolStatus status;
    }

    uint256 public numberPools;     // số lượng Pool

    mapping(uint256 => Pool) public stakingPools;   // pid => Pool

    event NewPool (uint256 pid, uint256 apy, uint256 duration);   

    event ChangePoolStatus (uint256 pid, PoolStatus status);

    // ================================================== staking =========================================================================

    enum StakingDataStatus {OPENING, CLOSED}   // đang mở <> đã đóng

    struct StakingData {
        uint256 pid;
        uint256 apy;
        uint256 amount;         // đơn vị: wei
        uint256 startTime;      // đơn vị: s
        uint256 endTime;        // đơn vị: s
        StakingDataStatus status;
    }

    mapping(address => uint256) public numberStakingDatas;  // user => số lần stake

    mapping(address => mapping(uint256 => StakingData) ) public stakeDatas; // user => lần thứ i stake => StakingData

    event Stake (address user, uint256 pid, uint256 amount, uint256 startTime, uint256 endTime);

    event Claim (address user, uint256 sid, uint256 amount);

    event Withdraw (address user, uint256 sid, uint256  amount);

    // ================================================== pausable =========================================================================

    function pause() public onlyOwner {
        _pause();
    }

    function unPause() public onlyOwner {
        _unpause();
    }
    
    // ================================================== const =========================================================================

    uint256 public ZOOM = 10000;
    uint256 public SECOND_IN_DAY = 86400;
    uint256 public DAY_IN_YEAR = 365;

    // ================================================== variables =========================================================================

    address public xBR;
    uint256 public minStakeAmount;  // đơn vị: wei
    uint256 public totalVolume;     // đơn vị: wei

    function setMinStakeAmount(uint256 _minStakeAmount) public onlyAdmin {
        minStakeAmount = _minStakeAmount;
    }

    // ================================================== constructor =========================================================================

    constructor(address _ownerAddress, address _admin, address _xBR, uint256 _minStakeAmount) {
        xBR = _xBR;
        minStakeAmount = _minStakeAmount;
        admin = _admin;
        Ownable.transferOwnership(_ownerAddress);
    }

    // ================================================== function write =========================================================================

    function newPool(uint256 _apy, uint256 _duration) public onlyAdmin {
        stakingPools[numberPools] = Pool(_apy, _duration, PoolStatus.AVAILABLE);
        emit NewPool(numberPools, _apy, _duration);
        numberPools++;
    }

    function changePoolStatus(uint256 _pid, PoolStatus _status) public onlyAdmin {
        Pool storage pool = stakingPools[_pid];
        pool.status = _status;
        emit ChangePoolStatus(_pid, _status);
    }

    function stake(uint256 _pid, uint256 _amount) public whenNotPaused {
        Pool memory pool = stakingPools[_pid];
        require(pool.status == PoolStatus.AVAILABLE, "Pool not AVAILABLE");
        require(_amount >= minStakeAmount, "Stake Amount < mint Stake Amount");

        IERC20(xBR).transferFrom(msg.sender, owner(), _amount);

        uint256 nStakeTime = numberStakingDatas[msg.sender];          // numDatas = Số lần stake của msg.sender
        StakingData storage data = stakeDatas[msg.sender][nStakeTime];    // data = staking data lần thứ numDatas
        data.pid = _pid;
        data.apy = pool.apy;
        data.amount = _amount;
        data.startTime = block.timestamp;
        data.endTime = data.startTime + pool.duration * 30 days;     // nhân với đơn vị 1 ngày
        data.status = StakingDataStatus.OPENING;

        numberStakingDatas[msg.sender] = nStakeTime + 1;        // tăng số lần stake
        totalVolume += _amount;         // tăng tổng khối lượng đã staked
        emit Stake(msg.sender, _pid, _amount, data.startTime, data.endTime);
    }

    function claim()
    public
    whenNotPaused
    {
        uint256 nStakeTime = numberStakingDatas[msg.sender];

        for (uint i = 0; i < nStakeTime; i++) {
            StakingData storage data = stakeDatas[msg.sender][i];
            if (data.status == StakingDataStatus.OPENING) {
                uint256 _reward = reward(msg.sender, i);
                IERC20(xBR).transfer(msg.sender, _reward);
                emit Claim(msg.sender, i, _reward);
                data.startTime = block.timestamp;
                if (data.startTime > data.endTime) {
                    data.startTime = data.endTime;
                }
            }
        }
    }

    function withdraw()
    public
    whenNotPaused
    {
        uint256 nStakeTime = numberStakingDatas[msg.sender];

        for (uint i = 0; i < nStakeTime; i++) {
            StakingData storage data = stakeDatas[msg.sender][i];
            if (data.status == StakingDataStatus.OPENING) {
                uint256 _reward = reward(msg.sender, i);
                IERC20(xBR).transfer(msg.sender, _reward);
                emit Claim(msg.sender, _reward, i);
                data.startTime = block.timestamp;
                if (data.startTime > data.endTime) {
                    data.startTime = data.endTime;
                }

                if (data.endTime <= block.timestamp) {
                    IERC20(xBR).transfer(msg.sender, data.amount);
                    emit Withdraw(msg.sender, i, data.amount);
                    totalVolume -= data.amount;
                    data.amount = 0;
                    data.status = StakingDataStatus.CLOSED;
                }
            }
        }

    }
    
    function emergencyWithdraw()
    public onlyOwner
    whenPaused
    {
        uint256 balance = IERC20(xBR).balanceOf(address(this));
        IERC20(xBR).transfer(owner(), balance);
    }

    // ================================================== function read =========================================================================

    function reward(address _staker, uint256 _sid)
    public view
    returns (uint256 _reward)
    {
        StakingData memory data = stakeDatas[_staker][_sid];
        uint256 calculateTime = block.timestamp;
        if (data.endTime < calculateTime) {
            calculateTime = data.endTime;
        }
        calculateTime = calculateTime - data.startTime;
        _reward = data.amount * data.apy * calculateTime/(DAY_IN_YEAR * SECOND_IN_DAY * ZOOM);
        return _reward;
    }

    function totalReward(address _staker)
    public view
    returns (uint256 _totalReward)
    {
        _totalReward = 0;
        uint256 nStakeTime = numberStakingDatas[_staker];
        for (uint i = 0; i < nStakeTime; i++) {
            _totalReward = _totalReward + (reward(_staker, i));
        }

        return _totalReward;
    }

    function checkWithdraw(address _staker) 
    public view
    returns (uint256 _total)
    {
        _total = 0;
        uint256 nStakeTime = numberStakingDatas[_staker];

        for (uint i = 0; i < nStakeTime; i++) {
            StakingData memory data = stakeDatas[_staker][i];
            if (data.status == StakingDataStatus.OPENING) {
                if (data.endTime <= block.timestamp) {
                    _total += data.amount;
                }
            }
        }
        _total += totalReward(_staker);
    }

    function checkStaking(address _staker) 
    public view
    returns (uint256 _total)
    {
        _total = 0;
        uint256 nStakeTime = numberStakingDatas[_staker];

        for (uint i = 0; i < nStakeTime; i++) {
            StakingData memory data = stakeDatas[_staker][i];
            if (data.status == StakingDataStatus.OPENING) {
                if (data.endTime > block.timestamp) {
                    _total += data.amount;
                }
            }
        }
        return _total;
    }

    function checkBlocktime() 
    public view 
    returns (uint256 _time)
    {
        _time = block.timestamp;
    }

    function getTVLPerStaking(address _staker) 
    public view
    returns (uint256 _quotient) 
    {
        uint256 totalStaking = checkStaking(_staker);
        if(totalStaking > 0) {
            _quotient = totalVolume/totalStaking;
        } else {
            _quotient = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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