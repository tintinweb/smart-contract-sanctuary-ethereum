//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract SampleStaking is Ownable {
    address private _stakingToken;
    address private _rewardToken;
    uint32 private _holdInterval;
    uint16 private _percent;

    struct Account {
        uint256 deposit;
        uint64 updateTime;
        uint256 reward;
        uint256 claimed;
    }

    mapping(address=>Account) public accounts;

    event Stake(address indexed account, uint256 amount);
    event UnStake(address indexed account, uint256 amount);
    event Winthdraw(address indexed account, uint256 amount);
    event Claim(address indexed account, uint256 amount);
    event UnClaim(address indexed account, uint256 amount);
    event SetPercent(uint16 percent_);
    event SetHoldInterval(uint32 holdIntreval_);


    constructor(address stakingToken_, address rewardToken_, uint32 holdInterval_, uint16 percent_) {
        _stakingToken = stakingToken_;
        _rewardToken = rewardToken_;
        _holdInterval = holdInterval_;
        _percent = percent_;

    }


    function countReward (uint256 deposit, uint16 percent_, uint256 periods) public pure returns (uint256) {

        return ((deposit * percent_) / 100) * periods;
}

    function accountReward(address account) public view returns (uint256) {

 
        return (accounts[account].updateTime > 0  ? this.countReward(accounts[account].deposit, _percent, (block.timestamp - accounts[account].updateTime) / _holdInterval) : 0) + accounts[account].reward; 
    }


    function _updateReward(address account) private {
        accounts[account].reward = this.accountReward(account);
        accounts[account].updateTime = uint64(block.timestamp);
    }
    
    function  stake(uint256 amount) public {
        IERC20 stakingTokenI = IERC20(_stakingToken);
        stakingTokenI.transferFrom(msg.sender, address(this), amount);
        _updateReward(msg.sender);
        accounts[msg.sender].deposit += amount;
        emit Stake(msg.sender, amount);   
        
    }


    function unstake(uint256 amount) public {
        require((block.timestamp - accounts[msg.sender].updateTime) >= _holdInterval, "hold interval isn't up");
        require(accounts[msg.sender].deposit >= amount, "not enough balance");
        _updateReward(msg.sender);
        IERC20 stakingTokenI = IERC20(_stakingToken);
        accounts[msg.sender].deposit -= amount;
        stakingTokenI.transfer(msg.sender, amount);
        emit UnStake(msg.sender, amount);   

    }

    function accountInfo(address account) public view returns(uint256, uint64, uint256, uint256) {
        return (accounts[account].deposit, accounts[account].updateTime, this.accountReward(account), accounts[account].claimed);
    }

    function winthdraw() public {
        IERC20 rewardTokenI = IERC20(_rewardToken);
        _updateReward(msg.sender);
        uint256 reward = accounts[msg.sender].reward;
        accounts[msg.sender].reward = 0;
        rewardTokenI.transfer(msg.sender, reward);
        emit Winthdraw(msg.sender, reward);
        
    }

    function claim(address account, uint256 amount) public onlyOwner {
        _updateReward(account);
        require(accounts[account].reward >= amount, "not enough balance");
        accounts[account].claimed += amount;
        accounts[account].reward -= amount;
        emit Claim(account, amount);
    }

    function unclaim(address account, uint256 amount) public onlyOwner {
        _updateReward(account);
        require(accounts[account].claimed >= amount, "not enough claimed balance");
        accounts[account].claimed -= amount;
        accounts[account].reward += amount;
        emit UnClaim(account, amount);
    }

    function setPercent(uint16 percent_) public onlyOwner{ 
        _percent = percent_;
        emit SetPercent(percent_);
    }

    function setHoldInterval(uint32 holdInterval_) public onlyOwner {
        _holdInterval = holdInterval_;
        emit SetHoldInterval(holdInterval_);
    }

    function percent() public view returns (uint16) {
        return _percent;
    }

    function holdInterval() public view returns (uint32) {
        return _holdInterval;
    }

    function rewardToken() public view returns (address) {
        return _rewardToken;
    }

    function stakingToken() public view returns (address) {
        return _stakingToken;
    }

}

// Написать смарт-контракт стейкинга, создать пул ликвидности на uniswap в тестовой сети. Контракт стейкинга принимает ЛП токены, после определенного времени (например 10 минут) пользователю начисляются награды в виде ревард токенов написанных на первой неделе. Количество токенов зависит от суммы застейканных ЛП токенов (например 20 процентов). Вывести застейканные ЛП токены также можно после определенного времени (например 20 минут).

// - Создать пул ликвидности
// - Реализовать функционал стейкинга в смарт контракте
// - Написать полноценные тесты к контракту
// - Написать скрипт деплоя
// - Задеплоить в тестовую сеть
// - Написать таски на stake, unstake, claim
// - Верифицировать контракт

// Требования
// - Функция stake(uint256 amount) - списывает с пользователя на контракт стейкинга ЛП токены в количестве amount, обновляет в контракте баланс пользователя
// - Функция claim() - списывает с контракта стейкинга ревард токены доступные в качестве наград
// - Функция unstake() - списывает с контракта стейкинга ЛП токены доступные для вывода
// - Функции админа для изменения параметров стейкинга (время заморозки, процент)

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