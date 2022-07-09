// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 	// ERC20 interface
import "@openzeppelin/contracts/access/Ownable.sol"; 		// OZ: Ownable

contract SuperHolder is Ownable{

    enum DepositCategory{
        HOLDER,
        SUPER_HOLDER
    }
    enum DepositType
    {
        HOLDER_3MONTHS,
        HOLDER_6MONTHS,
        HOLDER_12MONTHS
    }

    uint256 public constant HOLDER_QUOTA = 200;
    uint256 public constant SUPER_HOLDER_QUOTA = 20;
    uint256 public  HOLDER_DEPOSIT_LIMIT = 2500 * 1 ether;
    uint256[] public  HOLDER_PERIOD = [7776000,15552000,31104000];
    uint256[] public  HOLDER_APY_TIERS = [9,11,15];
    uint256[] public  SUPER_HOLDER_APY_TIERS = [12,14,18];
    uint256 public constant ONE_YEAR_SECONDS = 31536000;
    uint256 public  SUPER_HOLDER_DEPOSIT_LIMIT = 5000 * 1 ether;
    uint256 public holders_num;
    uint256 public super_holders_num;
    uint256 public total_locked_esg;
    uint256 public total_interest_claimed;
    IERC20 public immutable esgToken;
    struct User{
        uint256 depositTimestamp;
        uint256 claimedAmount;
        uint256 isUsed;
        DepositCategory category;
        DepositType dtype;
    }

    mapping (address => User) public accounts;

    constructor (address _esgAddress){
        require(_esgAddress != address(0), "invalid token address");
        esgToken = IERC20(_esgAddress);

        holders_num = 0;
        super_holders_num = 0;
        total_locked_esg = 0;
        total_interest_claimed = 0;
    }

    function deposit(DepositCategory _category, DepositType _type) external {
        require(_category <= DepositCategory.SUPER_HOLDER, "invalid deposit category");
        require(_type <= DepositType.HOLDER_12MONTHS, "invalid deposit type");
        if(_category == DepositCategory.HOLDER)
        {
            require(holders_num+1 <= HOLDER_QUOTA, "holders number exceeds limit");
            holders_num = holders_num + 1;
        }
        else if(_category == DepositCategory.SUPER_HOLDER)
        {
            require(super_holders_num+1 <= SUPER_HOLDER_QUOTA, "super holders number exceeds limit");
            super_holders_num = super_holders_num + 1;
        }
            
        User storage user = accounts[msg.sender];
        require(user.isUsed == 0, "user has already deposited.");
        uint256 amount = HOLDER_DEPOSIT_LIMIT;
        if(_category == DepositCategory.SUPER_HOLDER)
            amount = SUPER_HOLDER_DEPOSIT_LIMIT;
	user.depositTimestamp = block.timestamp;
        total_locked_esg = total_locked_esg + amount;
        esgToken.transferFrom(msg.sender, address(this), amount);
        accounts[msg.sender] = User(block.timestamp, 0, 1, _category, _type);
    }

    function claimInterest() external {
        User storage user = accounts[msg.sender];
        require(user.isUsed == 1, "no deposit");
        uint256 amount = getInterestAvailable(msg.sender);
        uint256 balance = esgToken.balanceOf(address(this));
        if(balance < amount)
            amount = balance;
        user.claimedAmount = user.claimedAmount + amount;
        total_interest_claimed = total_interest_claimed + amount;
        esgToken.transfer(msg.sender, amount);
    }

    function withdrawPrincipal() external {
        User memory user = accounts[msg.sender];
        require(user.isUsed == 1, "no deposit");
        uint256 timeSpan = block.timestamp - user.depositTimestamp;
        require(timeSpan > HOLDER_PERIOD[uint256(user.dtype)], "deposit is in locked status");

        uint256 amount = HOLDER_DEPOSIT_LIMIT;
        if(user.category == DepositCategory.HOLDER)
        {
            holders_num = holders_num - 1;
        }
        else if(user.category == DepositCategory.SUPER_HOLDER)
        {
            amount = SUPER_HOLDER_DEPOSIT_LIMIT;
            super_holders_num = super_holders_num - 1;
        }
            
        total_locked_esg = total_locked_esg - amount;

        amount = amount + getInterestAvailable(msg.sender);
        uint256 balance = esgToken.balanceOf(address(this));
        if(balance < amount)
            amount = balance;
        delete accounts[msg.sender];
        esgToken.transfer(msg.sender, amount);
    }

    function getInterestAvailable(address account) public view returns(uint256){
        User memory user = accounts[account];
        if(user.isUsed == 0)
            return 0;
        else
        {
            uint256 amount = 0;
            if(user.category == DepositCategory.HOLDER)
            {
                if(block.timestamp - user.depositTimestamp >=  HOLDER_PERIOD[uint256(user.dtype)])
                    amount = HOLDER_DEPOSIT_LIMIT * HOLDER_APY_TIERS[uint256(user.dtype)] * HOLDER_PERIOD[uint256(user.dtype)] / ONE_YEAR_SECONDS / 100;
                else
                    amount = HOLDER_DEPOSIT_LIMIT * HOLDER_APY_TIERS[uint256(user.dtype)] * (block.timestamp - user.depositTimestamp)/ ONE_YEAR_SECONDS / 100;
            }else if(user.category == DepositCategory.SUPER_HOLDER)
            {
                if(block.timestamp - user.depositTimestamp >=  HOLDER_PERIOD[uint256(user.dtype)])
                    amount = SUPER_HOLDER_DEPOSIT_LIMIT * SUPER_HOLDER_APY_TIERS[uint256(user.dtype)] * HOLDER_PERIOD[uint256(user.dtype)] / ONE_YEAR_SECONDS / 100;
                else
                    amount = SUPER_HOLDER_DEPOSIT_LIMIT * SUPER_HOLDER_APY_TIERS[uint256(user.dtype)] * (block.timestamp - user.depositTimestamp)/ ONE_YEAR_SECONDS / 100;
            }
            return amount - user.claimedAmount;
        }
    }

    function _withdrawERC20Token(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "invalid address");
        uint256 tokenAmount = IERC20(tokenAddress).balanceOf(address(this));
        if(tokenAmount > 0)
            IERC20(tokenAddress).transfer(msg.sender, tokenAmount);
        else
            revert("insufficient ERC20 tokens");
    }

    function _setHolderDepositLimit(uint256 depositLimit) external onlyOwner {
        HOLDER_DEPOSIT_LIMIT = depositLimit;
    }

    function _setSuperHolderDepositLimit(uint256 depositLimit) external onlyOwner {
        SUPER_HOLDER_DEPOSIT_LIMIT = depositLimit;
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