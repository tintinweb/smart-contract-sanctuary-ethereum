//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RLoopStaking is Ownable {
    IERC20 internal token;
    uint256 public rewardPercent;

    struct UserTransaction {
        uint256 amount;
        uint256 lockedUntil;
        uint256 time;
        uint rewardAPY;
        bool rewardClaimed;
       
    }
    struct Transaction {
        uint256 txNo;
        uint256 totalAmount;
        mapping(uint256 => UserTransaction) stakingPerTx;
    }

    mapping(address => Transaction) public userTx;
    mapping(uint256 => uint256) public stakePeriodRewardPercent;

    event StakeDeposit(uint256 amount, uint256 time, uint256 lockedUntil);

    constructor(IERC20 _token) {
        token = _token;
    }

    function redeemTokens() public onlyOwner {
        uint amount = token.balanceOf(address(this));
        token.transfer(msg.sender,amount);
    }

    function addStake(uint256 _time, uint256 _amount) internal {
        Transaction storage txNumber = userTx[msg.sender];
        token.transferFrom(msg.sender, address(this), _amount);
        txNumber.txNo++;
        txNumber.totalAmount += _amount;
        txNumber.stakingPerTx[txNumber.txNo].amount = _amount;
        txNumber.stakingPerTx[txNumber.txNo].time = _time;
        txNumber.stakingPerTx[txNumber.txNo].lockedUntil =
            block.timestamp +
            _time;
        txNumber.stakingPerTx[txNumber.txNo].rewardAPY = stakePeriodRewardPercent[_time];
    }

    function stake(uint256 _time, uint256 _amount) public {
        require(_amount != 0, "Null Amount");
        require(stakePeriodRewardPercent[_time] != 0, "Time not specified!");
        addStake(_time, _amount);
        emit StakeDeposit(
            _amount,
            block.timestamp,
            userTx[msg.sender].stakingPerTx[userTx[msg.sender].txNo].lockedUntil
        );
    }

    function claimableReward(uint256 _txNo) public view returns (uint256) {
        Transaction storage txNumber = userTx[msg.sender];
        uint256 amount = txNumber.stakingPerTx[_txNo].amount;
        uint256 lockedTime = txNumber.stakingPerTx[_txNo].lockedUntil;
        if (
            block.timestamp > lockedTime &&
            txNumber.stakingPerTx[_txNo].rewardClaimed == false
        ) {
            uint256 reward = (amount *txNumber.stakingPerTx[_txNo].rewardAPY) /
                10000;
            return reward;
        } else return 0;
    }

     function claimReward(uint256 _txNo) public {
        Transaction storage txNumber = userTx[msg.sender];
        uint256 reward = claimableReward(_txNo);
        uint256 amount = txNumber.stakingPerTx[_txNo].amount;
        require(
            txNumber.stakingPerTx[_txNo].rewardClaimed != true,
            "Rewards already claimed!"
        );
        txNumber.totalAmount -= amount;
        token.transfer(msg.sender, reward + amount);
        txNumber.stakingPerTx[_txNo].rewardClaimed = true;
    }
    // Function to set staking time and reward percent, changing reward percent for existing staking time will not change the 
    // APY of already staked amount in the past, same for time.
    // 100 denotes 1 percent.
    function setTimeRewardPercent(uint256 time, uint256 newRewardPercent)
        public
        onlyOwner
    {
        stakePeriodRewardPercent[time] = newRewardPercent;
    }

    function checkTransaction(uint _txNo) public view returns(UserTransaction memory){
        return userTx[msg.sender].stakingPerTx[_txNo];
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