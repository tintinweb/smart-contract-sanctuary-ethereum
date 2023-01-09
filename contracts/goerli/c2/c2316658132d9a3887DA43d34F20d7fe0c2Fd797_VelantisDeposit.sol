// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VelantisDeposit is Ownable {
    address public tokensAddress; //deposit token address
    uint256 public percentage; //dailypercentage
    uint256 public constant basisPoints = 10000;
    //user details like pendingBalance,available balance,deposit time and withdrawal time
    struct User {
        uint256 availableBalance;
        uint256 pendingBalance;
        uint256 withdrawalTimeStamp;
    }
    //mapping for user details
    mapping(address => User) public userDetails;

    //withdraw time
    uint256 constant oneDay = 180; //TODO changes time in second(86400) for  mainnet
    //events
    event Deposited(
        address indexed admin,
        address indexed user,
        uint256 amount
    ); //event for deposit
    event Withdrawn(address indexed payee, uint256 amount); //event for withdrawal

    constructor(address _tokenAddress, uint256 _percentage) {
        require(
            _tokenAddress != address(0) && _percentage > 0,
            "Token address should not be zero address and Percentage must be greater than zero"
        );
        tokensAddress = _tokenAddress; //initial token address set
        percentage = _percentage; //initial percentage set
    }

    //setter function for daily percentage in future
    function setPercentage(uint256 _percentage) external onlyOwner {
        require(
            _percentage > 0 && _percentage <= basisPoints,
            "Invalid percentage."
        );
        percentage = _percentage;
    }

    //setter function for token address in future
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(
            _tokenAddress != address(0),
            "Token address should not be zero address"
        );
        tokensAddress = _tokenAddress;
    }

    //deposit token contracts
    function deposit(address to_address, uint256 _amount) public onlyOwner {
        User storage user = userDetails[to_address];
        require(_amount > 0, "Deposit amount must be greater than zero");
        uint256 pendingBalance = getPendingBalance(to_address);
        if (pendingBalance > 0) {
            user.availableBalance -= pendingBalance;
            user.pendingBalance += pendingBalance;
            user.withdrawalTimeStamp = block.timestamp;
        } else {
            user.withdrawalTimeStamp = user.withdrawalTimeStamp != 0
                ? user.withdrawalTimeStamp
                : block.timestamp;
        }
        user.availableBalance += _amount;
        IERC20(tokensAddress).transferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, to_address, _amount);
    }

    //modifier to check timestamp
    modifier checkTimeStamp() {
        User storage user = userDetails[msg.sender];
        require(
            block.timestamp - user.withdrawalTimeStamp > oneDay,
            "WITHDRAW_TIME_ERROR"
        );
        _;
    }

    //withdraw tokens from contract
    function withdrawToken(address _token, uint256 _amount)
        public
        checkTimeStamp
    {
        User storage user = userDetails[msg.sender];
        uint256 pendingBalance = getPendingBalance(msg.sender);
        require(
            _amount > 0 && pendingBalance > 0 && _amount <= pendingBalance,
            "INVALID BALANCE"
        );
        user.availableBalance -= _amount;
        user.pendingBalance = pendingBalance - _amount;
        user.withdrawalTimeStamp = user.availableBalance == 0
            ? 0
            : block.timestamp;
        IERC20(_token).transfer(msg.sender, _amount);
        emit Withdrawn(_token, _amount);
    }

    //add daily value to pendingbalance  and subtract from avaiable balance
    function getPendingBalance(address user_wallet)
        public
        view
        returns (uint256 _balance)
    {
        User storage user = userDetails[user_wallet];
        //adding balance to pending balance from available balance for withdrawal
        uint256 day = countDays(user_wallet);
        uint256 balance = (((
            ((user.availableBalance * percentage) / basisPoints)
        ) * day) + user.pendingBalance);
        return
            balance > user.availableBalance ? user.availableBalance : balance;
    }

    //returns days
    function countDays(address user_wallet)
        public
        view
        returns (uint256 _days)
    {
        User storage user = userDetails[user_wallet];
        uint256 diff = user.availableBalance == 0
            ? 0
            : (block.timestamp - user.withdrawalTimeStamp) / oneDay;
        return diff;
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