// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract pool  is Ownable {

    //质押token地址
    IERC20 public stakeToken;
    //质押奖励token地址
    IERC20 public rewardToken;
    //每分钟产出奖励数量
    uint256 public rewardPerMin;
    //某地址的质押份额
    mapping(address => uint256) private shares;
    //某地址已经提现的奖励
    mapping(address => uint256) private withdrawdReward;
    //某地址上一次关联的每份额累计已产出奖励
    mapping(address => uint256) private lastAddUpRewardPerShare;
    //某地址最近一次关联的累计已产出总奖励
    mapping(address => uint256) private lastAddUpReward;
    //每份额累计总奖励
    uint256 public addUpRewardPerShare;
    //总挖矿奖励数量
    uint256 public totalReward;
    //累计份额
    uint256 public totalShares;

    //最近一次（如果没有最近一次则是首次）挖矿区块时间，秒
    uint256 public lastBlockT;
    //最近一次（如果没有最近一次则是首次）每份额累计奖励
    uint256 public lastAddUpRewardPerShareAll;

    //构造函数
    constructor(address _stakeTokenAddr, address _rewardTokenAddr, uint256 _rewardPerMin){
        stakeToken = IERC20(_stakeTokenAddr);
        rewardToken = IERC20(_rewardTokenAddr);
        rewardPerMin = _rewardPerMin;
    }

    //质押,【外部调用/所有人/不需要支付/读写状态】
    /// @notice 1. msg.sender转入本合约_amount数量的质押token
    /// @notice 4. 记录此时msg.sender已经产出的总奖励
    /// @notice 2. 增加msg.sender等量的质押份额
    /// @notice 3. 计算此时每份额累计总产出奖励
    function stake(uint256 _amount) external 
    {
        stakeToken.transferFrom(address(this), msg.sender, _amount); 
        uint256 currenTotalRewardPerShare = getRewardPerShare();
        lastAddUpReward[msg.sender] +=  (currenTotalRewardPerShare - lastAddUpRewardPerShare[msg.sender]) * shares[msg.sender];
        shares[msg.sender] += _amount;
        updateTotalShare(_amount, 1);
        lastAddUpRewardPerShare[msg.sender] = currenTotalRewardPerShare;
    } 

    //解除质押，提取token,【外部调用/所有人/不需要支付/读写状态】
    /// @notice 1. _amount必须<=已经质押的份额
    /// @notice 4. 记录此时msg.sender已经产出的总奖励
    function unStake(uint256 _amount) external 
    {
        require(_amount <= shares[msg.sender], "UNSTAKE_AMOUNT_MUST_LESS_SHARES");
        stakeToken.transferFrom(address(this), msg.sender, _amount); 
        uint256 currenTotalRewardPerShare = getRewardPerShare();
        lastAddUpReward[msg.sender] +=  (currenTotalRewardPerShare - lastAddUpRewardPerShare[msg.sender]) * shares[msg.sender];
        shares[msg.sender] -= _amount;
        updateTotalShare(_amount, 2);
        lastAddUpRewardPerShare[msg.sender] = currenTotalRewardPerShare;
    }

    //更新质押份额,【内部调用/合约创建者/不需要支付】
    /// @param _amount 更新的数量
    /// @param _type 1增加，其他 减少
    /// @notice 每次更新份额之前，先计算之前的份额累计奖励
    function updateTotalShare(uint256 _amount, uint256 _type) 
        internal 
        onlyOwner 
    {  
        lastAddUpRewardPerShareAll = getRewardPerShare();
        lastBlockT = block.timestamp;
        if(_type == 1){
            totalShares += _amount;
        } else{
            totalShares -= _amount;
        }
    }

    //获取截至当前每份额累计产出,【内部调用/合约创建者/不需要支付/只读】
    /// @notice 1.（当前区块时间戳-具体当前最近一次计算的时间戳） * 每分钟产出奖励 / 60秒 / 总份额  + 距离当前最近一次计算的时候的每份额累计奖励 = 当前每份额累计奖励 
    /// @notice 2. 更新最近一次计算每份额累计奖励的时间和数量 
    function getRewardPerShare() 
        internal 
        view 
        onlyOwner 
        returns(uint256)
    {  
        return (block.timestamp - lastBlockT) * rewardPerMin / 60 / totalShares + lastAddUpRewardPerShareAll;
    }

    //计算累计奖励,【内部调用/合约创建者/不需要支付/只读】
    /// @notice 仅供内部调用，统一计算规则
    function getaddupReword(address _address) 
        internal
        onlyOwner 
        view 
        returns(uint256)
    {
        return lastAddUpReward[_address] +  ((getRewardPerShare() - lastAddUpRewardPerShare[_address]) * shares[_address]);
    }

    //计算可提现奖励,【内部调用/合约创建者/不需要支付/只读】
    /// @notice 仅供内部调用，统一计算规则
    function getWithdrawdReword(address _address) 
        internal
        onlyOwner 
        view 
        returns(uint256)
    {
        return lastAddUpReward[_address] +  ((getRewardPerShare() - lastAddUpRewardPerShare[_address]) * shares[_address]) - withdrawdReward[_address];
    }

    //提现收益,【外部调用/所有人/不需要支付/读写】
    /// @notice 1. 计算截至到当前的累计获得奖励
    /// @notice 2. _amount必须<=(累计获得奖励-已提现奖励)
    /// @notice 3. 提现，提现需要先增加数据，再进行提现操作
    function withdraw(uint256 _amount) 
        external 
    {
        require(_amount <= getWithdrawdReword(msg.sender), "WITHDRAW_AMOUNT_LESS_ADDUPREWARD");
        withdrawdReward[msg.sender] += _amount;
        rewardToken.transferFrom(address(this), msg.sender, _amount); 
    }

    //获取可提现奖励，【外部调用/所有人/不需要支付】
    function withdrawdReword() 
        external
        view 
        returns(uint256)
    {
        return getWithdrawdReword(msg.sender);
    }

    //获取已提现奖励，【外部调用/所有人/不需要支付】
    function hadWithdrawdReword() 
        external
        view 
        returns(uint256)
    {
        return withdrawdReward[msg.sender];
    }

    //获取累计奖励，【外部调用/所有人/不需要支付】
    function addupReword() 
        external
        view 
        returns(uint256)
    {
        return getaddupReword(msg.sender);
    }

    //获取质押份额,【外部调用/所有人/不需要支付/只读】
    function getShare() 
        external
        view 
        returns(uint256)
    {
        return shares[msg.sender];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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