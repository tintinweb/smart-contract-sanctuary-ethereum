//SPDX-License-Identifier:UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SaitaMask is Ownable {
    IERC20 token;
    struct userTransaction {
        uint256 amount;
        uint256 time;
        uint256 lockedUntil;
        bool stakingOver;
    }

    struct staking {
        uint256 txNo;
        uint256 totalAmount;
        mapping(uint256 => userTransaction) stakingPerTx;
    }

    error timeNotSpecified(uint256 _time);
    event StakeDeposit(
        uint256 _amount,
        uint256 _lockPeriod,
        uint256 _lockedUntil
    );
    event RewardWithdraw(uint256 _amount, uint256 _reward);

    mapping(address => staking) public stakingTx;
    mapping(uint256 => uint256) public rewardPercent;

    constructor(IERC20 _token) {
        token = _token;
    }

    function addStake(uint256 _time, uint256 _amount) internal {
        token.transferFrom(msg.sender, address(this), _amount);
        stakingTx[msg.sender].txNo++;
        stakingTx[msg.sender].totalAmount += _amount;
        stakingTx[msg.sender]
            .stakingPerTx[stakingTx[msg.sender].txNo]
            .amount = _amount;
        stakingTx[msg.sender]
            .stakingPerTx[stakingTx[msg.sender].txNo]
            .time = _time;
        stakingTx[msg.sender]
            .stakingPerTx[stakingTx[msg.sender].txNo]
            .lockedUntil = block.timestamp + _time;
    }

    function stake(uint256 _time, uint256 _amount) public {
        require(_amount != 0, "Null amount!");
        require(_time != 0, "Null time!");
        require(
            rewardPercent[_time] != 0,
            "Time not specified."
        );
        addStake(_time, _amount);
        emit StakeDeposit(
            _amount,
            _time,
            stakingTx[msg.sender]
                .stakingPerTx[stakingTx[msg.sender].txNo]
                .lockedUntil
        );
    }

    function rewards(uint256 _txNo)
        public
        view
        returns (uint256)
    {
        uint256 amount = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .amount;
        uint256 lockTime = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .lockedUntil;
        uint256 time = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .time;
        uint256 rewardBalance;

        rewardBalance = (amount * rewardPercent[time]) / 100;
        return rewardBalance;
    }

    function claim(uint256 _txNo) public {
        require(
            stakingTx[msg.sender]
                .stakingPerTx[_txNo]
                .stakingOver != true,
            "The rewards for this staking is already claimed."
        );
        require(
            block.timestamp >
                stakingTx[msg.sender]
                    .stakingPerTx[_txNo]
                    .lockedUntil,
            "Stake period is not over."
        );
        uint256 reward = rewards(_txNo);
        require(reward != 0, "Not eligible for reward!");
        uint256 amount = stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .amount;
        uint256 totalAmount = amount + reward;
        stakingTx[msg.sender].totalAmount -= amount;
        token.transfer(msg.sender, totalAmount);
        stakingTx[msg.sender]
            .stakingPerTx[_txNo]
            .stakingOver = true;
        emit RewardWithdraw(amount, reward);
    }

    function setRewardPercent(uint256 _days, uint256 _percent)
        public
        onlyOwner
    {
        rewardPercent[_days] = _percent;
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