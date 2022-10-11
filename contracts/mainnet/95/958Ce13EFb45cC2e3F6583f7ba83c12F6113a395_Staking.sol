// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity  0.8.9;

contract Staking is Ownable{
    /**
     * 1- first pool: 
     */

    struct Pool {
        uint256 poolId;
        uint256 poolBalance;
        uint256 coolDown;
        uint256 totalStake;
        uint256 startTime;
        uint256 stakers;
    }

    struct StakeInfo {
        uint256 poolId;
        uint256 staked;
        bool claimed;
        uint256 coolDown;
    }

    mapping(address=>mapping(uint256=>StakeInfo)) public stakers;
    mapping(address=>bool) public whitelisted;
    mapping(uint256=>Pool) public pools;

    IERC20 public ICY;
    uint256 private ICY_ts;

    uint256 public poolOneBalance;
    uint256 public poolTwoBalance;
    uint256 public poolThreeBalance;

    Pool public PoolOne;
    Pool public PoolTwo;
    Pool public PoolThree;

    uint256 public totalFund;

    uint256 public stakeFee = 2;
    uint256 public unstakeFee = 2;
    address public marketingWallet = 0x3EaE574542E1aAC362C84f0cCb363a8EB4d13Da0;

    constructor(address icy_token){
        ICY = IERC20(icy_token);
        ICY_ts = ICY.totalSupply();

        poolOneBalance = ICY_ts / 200;
        poolTwoBalance = ICY_ts / 100;
        poolThreeBalance = (ICY_ts * 15) / 1000;

        PoolOne = Pool(0, poolOneBalance, 0, 0,  0, 0);
        PoolTwo = Pool(1, poolTwoBalance, 15 days, 0,  0, 0);
        PoolThree = Pool(2, poolThreeBalance, 30 days, 0,  0, 0);

        totalFund = poolOneBalance + poolTwoBalance + poolThreeBalance;
        whitelisted[msg.sender] = true;
        pools[0] = PoolOne;
        pools[1] = PoolTwo;
        pools[2] = PoolThree;
    }

    function setWhitelisted(address staker, bool status) public onlyOwner{
        whitelisted[staker] = status;
    }

    function StartPool(uint256 poolId) public onlyOwner{
        pools[poolId].startTime = block.timestamp;
    }

    function fundStakingContract() external onlyOwner {
        ICY.transferFrom(msg.sender, address(this), totalFund);
    }

    function deposit(uint256 stakeAmount, uint256 poolId) public {
        //validating data
        bool Iswhitelisted = whitelisted[msg.sender];
        require(stakeAmount > 0 && poolId < 3, "Invalid Operation");
        Pool memory m_pool = pools[poolId];
        require((m_pool.startTime != 0 && m_pool.startTime < block.timestamp) || Iswhitelisted == true, "Pool not started yet!");
        bool stakedBefore = false;

        //User Staking Info
        StakeInfo memory m_stakeInfo = stakers[msg.sender][poolId];
        if(m_stakeInfo.staked > 0){
            stakedBefore = true;
        }
        if(m_pool.coolDown > 0){
            m_stakeInfo.coolDown = block.timestamp + m_pool.coolDown;
        }

        //Taxes
        uint256 fee = 0;
        if(!Iswhitelisted){
            fee = (stakeAmount * stakeFee) / 100;
            ICY.transferFrom(msg.sender, marketingWallet, fee);
        }

        m_stakeInfo.staked += stakeAmount - fee;
        m_stakeInfo.poolId = poolId;
        stakers[msg.sender][poolId] = m_stakeInfo;

        //Pool Staking Info
        m_pool.totalStake += (stakeAmount - fee);
        if(!stakedBefore){
            m_pool.stakers += 1;
        }
        pools[poolId] = m_pool;


        uint256 toStake = stakeAmount - fee;
        ICY.transferFrom(msg.sender, address(this), toStake);
    }

    function withdraw(uint256 withdrawAmount, uint256 poolId) public {
        require(poolId < 3 && withdrawAmount > 0, "Invalid Operation");

        //Checking balances
        Pool memory m_pool = pools[poolId];
        StakeInfo memory m_stakeInfo = stakers[msg.sender][poolId];
        require(withdrawAmount <= m_stakeInfo.staked, "can not withdraw more than staked!");

        //Effects
        m_pool.stakers -= 1;
        m_pool.totalStake -= withdrawAmount;
        m_stakeInfo.staked -= withdrawAmount;
        stakers[msg.sender][poolId] = m_stakeInfo;
        pools[poolId] = m_pool;

        //Taxes
        uint256 fee = 0;
        if(!whitelisted[msg.sender]){
            fee = (withdrawAmount * unstakeFee) / 100;
            ICY.transfer(marketingWallet, fee);
        }

        uint256 toSend = withdrawAmount - fee;
        ICY.transfer(msg.sender, toSend);
    }

    function harvest(uint256 poolId) public {
        StakeInfo memory m_stakeInfo = stakers[msg.sender][poolId];
        Pool memory m_pool = pools[poolId];
        require(poolId < 3 && m_stakeInfo.staked > 0 && m_pool.stakers >= 5, "Invalid Operation");
        require(!m_stakeInfo.claimed, "already claimed");
        require(m_stakeInfo.coolDown < block.timestamp, "can not withdraw before cooldown");

        //Calculating Rewards
        uint256 toClaim = (m_stakeInfo.staked * m_pool.poolBalance) / m_pool.totalStake;
        m_stakeInfo.claimed = true;
        m_pool.poolBalance -= toClaim;
        pools[poolId] = m_pool;
        stakers[msg.sender][poolId] = m_stakeInfo;
        ICY.transfer(msg.sender, toClaim);
    }

    function getPendingReward(address _staker, uint256 poolId) public view returns(uint256){
        StakeInfo memory m_stakeInfo = stakers[_staker][poolId];
        Pool memory m_pool = pools[poolId];
        if(m_pool.totalStake == 0){
            return 0;
        }
        return (m_stakeInfo.staked * m_pool.poolBalance) / m_pool.totalStake;
    }

    function getPoolInfo(uint256 id) public view returns(Pool memory){
        return pools[id];
    }

    function getUserInfo(address staker, uint256 id) public view returns(StakeInfo memory){
        return stakers[staker][id];
    }

    receive() payable external{}

    fallback() payable external{}
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