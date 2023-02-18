// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/IERC20.sol";
import "@openzeppelin/[email protected]/security/Pausable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract SFCICO is Pausable, Ownable {
    address public constant SFC = 0xb03258Cb22005515B3E42484bc8857caAeF19C26;
    address public constant TREASURY = 0xE10b0A4766C04d5D4618dF018F1A3a0E5Cc36d5D;
    address public constant RESEARCH_AND_DEVELOPMENT = 0x80a5285133cc93a3Cf4A08d874156E92431c6d17;
    address public constant LIQUIDITY_POOL = 0xe4Bc29d5fb845288FA211be4F154ce5E198c4972;
    
    uint public constant MAX_ORDER_SIZE = 500000000000000000000000000;
    mapping(address => uint) public orders;

    mapping(address => uint) public referrals;
    uint public rewardPercent = 10;
    uint public rewardPercentTo = 10;

    uint public valueForGetReward = 1;
   
    uint public bnbPrice;
    uint public icoBalance;

    event Released(address indexed to, uint amount);

    function start() public onlyOwner {
       icoBalance = IERC20(SFC).balanceOf(address(this));
    }

    function purchese(address referral) public payable whenNotPaused {
        if(msg.value < valueForGetReward) 
        {
            _purchese(msg.value);
        }
        
        _purcheseWithReferral(msg.value, referral);
    }

    function _purchese(uint value) private returns (bool) {
        uint amount = (1000 * (bnbPrice * value * 1000000000000000000)) / 1000000000000000000; 
       
        require(amount <= icoBalance, "ICO BALANCE IS LESS THAN YOUR ORDER");
        require(amount < MAX_ORDER_SIZE, "MAX_ORDER_SIZE ERROR");
        require((orders[msg.sender] + amount) < MAX_ORDER_SIZE, "YOU ARE LIMITED");

        (bool treasurySuccess, ) = TREASURY.call{value: ((msg.value * 20) / 100)}("");
        (bool developmentSuccess, ) = RESEARCH_AND_DEVELOPMENT.call{value: ((msg.value * 20) / 100)}("");
        (bool liquiditySuccess, ) = LIQUIDITY_POOL.call{value: ((msg.value * 60) / 100)}("");

        if(treasurySuccess && developmentSuccess && liquiditySuccess) {
            IERC20(SFC).transfer(msg.sender, amount);
            orders[msg.sender] += amount;
            icoBalance -= amount;
            emit Released(msg.sender,amount);

            return true;
        }

        return false;
    }

    function _purcheseWithReferral(uint value, address referral) private returns (bool) {
        uint amount = (1000 * (bnbPrice * value * 1000000000000000000)) / 1000000000000000000; 
        uint referralReward = ((amount * rewardPercent) / 100);
        uint referralRewardTo = ((amount * rewardPercentTo) / 100);
        uint totalAmount = amount + referralReward + referralRewardTo;

        require(totalAmount <= icoBalance, "ICO BALANCE IS LESS THAN YOUR ORDER");
        require(totalAmount < MAX_ORDER_SIZE, "MAX_ORDER_SIZE ERROR");
        require((orders[msg.sender] + totalAmount) < MAX_ORDER_SIZE, "YOU ARE LIMITED");

        (bool treasurySuccess, ) = TREASURY.call{value: ((msg.value * 20) / 100)}("");
        (bool developmentSuccess, ) = RESEARCH_AND_DEVELOPMENT.call{value: ((msg.value * 20) / 100)}("");
        (bool liquiditySuccess, ) = LIQUIDITY_POOL.call{value: ((msg.value * 60) / 100)}("");

        if(treasurySuccess && developmentSuccess && liquiditySuccess) {
            IERC20(SFC).transfer(msg.sender, (amount + referralRewardTo));
            IERC20(SFC).transfer(referral, referralReward);
            orders[msg.sender] += amount;
            referrals[referral] += referralReward;
            icoBalance -= totalAmount;
            emit Released(msg.sender,amount);

            return true;
        }

        return false;
    }

    function setBnbPrice(uint price) public onlyOwner {
        bnbPrice = price;
    }

    function setRewardPercent(uint percent) public onlyOwner {
        rewardPercent = percent;
    }

    function setRewardPercentTo(uint percent) public onlyOwner {
        rewardPercentTo = percent;
    }

    function setValueForGetReward(uint value) public onlyOwner {
        valueForGetReward = value;
    }

    function emergencyWithdraw() public onlyOwner {
       uint balance = IERC20(SFC).balanceOf(address(this));
       IERC20(SFC).transfer(msg.sender, balance);
	   icoBalance -= balance;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
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