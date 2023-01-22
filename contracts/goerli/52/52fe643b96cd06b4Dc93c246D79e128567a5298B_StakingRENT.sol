// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract StakingRENT is Ownable {

    using Counters for Counters.Counter;

    /// ============ Errors ==================
    error ErrorSendingFunds(address to, uint256 amount);


    /// ============ Immutable storage ==================
    IERC20 private RENT;

    struct Stak {
        uint256 idStake;
        uint256 amount;
        uint256 timestamp;
        address user;
        uint8 typeOfStake;
        bool isClaimed;
    }

    struct TypeOfStake {
        uint8 idTypeOfStake;
        uint8 percentage;
        uint256 duration;
        bool isActived;
    }

    ///=========== Mutable Storage ======================

    mapping(uint256 => Stak) public stakes;

    mapping(address => uint256[]) public userStakes;

    mapping(uint8 => TypeOfStake) public typeOfStakes;

    // Total staked
    uint256 public totalStaked;
    // Total rewards
    uint256 public totalRewards;

    uint256 public minStakingAmount = 2000e18;

    Counters.Counter private idStake;
    Counters.Counter private idTypeOfStake;

    constructor() {
        RENT = IERC20(0x97d3D125Bc61557E8E8E20A82EA21Bba1541616f);

        typeOfStakes[1] = TypeOfStake({
            idTypeOfStake: 1,
            percentage: 15,
            duration: 365 days,
            isActived: true
        });

        typeOfStakes[2] = TypeOfStake({
            idTypeOfStake: 2,
            percentage: 20,
            duration: 730 days,
            isActived: true
        });
    }

    /// ==================== Events ============================
    event Stake(address indexed user, uint256 amount, uint256 timestamp, uint8 typeOfStake);
    event Claim(address indexed user, uint256 amount, uint256 timestamp, uint8 typeOfStake);

    //stake
    function stake(uint256 amount, uint8 typeOfStake) public {

        require(typeOfStakes[typeOfStake].isActived, "Stake: the type of stake is not actived");
        require(amount >= minStakingAmount, "Stake: the amount is less than the minimum staking amount");
        require(amount <= RENT.balanceOf(msg.sender), "Stake: the amount is greater than the balance of the user");

        idStake.increment();

        stakes[idStake.current()] = Stak({
            idStake: idStake.current(),
            amount: amount,
            timestamp: block.timestamp,
            user: msg.sender,
            typeOfStake: typeOfStake,
            isClaimed: false
        });

        userStakes[msg.sender].push(idStake.current());

        totalStaked += amount;

        emit Stake(msg.sender, amount, block.timestamp, typeOfStake);

        if (!RENT.transferFrom(msg.sender, address(this), amount)) {
            revert ErrorSendingFunds(msg.sender, amount);
        }

    }

    //claim
    function claim(uint256 idStakeClaim) public {
        require(typeOfStakes[stakes[idStakeClaim].typeOfStake].isActived, "Stake: the type of stake is not actived");
        require(stakes[idStakeClaim].user == msg.sender, "Claim: you are not the owner of this stake");
        require(stakes[idStakeClaim].isClaimed == false, "Claim: this stake is already claimed");
        require(block.timestamp > stakes[idStakeClaim].timestamp + typeOfStakes[stakes[idStakeClaim].typeOfStake].duration, "Claim: the stake is not ready to be claimed");

        uint256 amountStakeToClaim = stakes[idStakeClaim].amount;
        uint256 amountRewardsToClaim = (amountStakeToClaim * typeOfStakes[stakes[idStakeClaim].typeOfStake].percentage) / 100;
        uint256 amountToClaim = amountStakeToClaim + amountRewardsToClaim;


        stakes[idStakeClaim].isClaimed = true;

        totalRewards += amountRewardsToClaim;

        emit Claim(msg.sender, amountToClaim, block.timestamp, stakes[idStakeClaim].typeOfStake);

        if (!RENT.transfer(msg.sender, amountToClaim)) {
            revert ErrorSendingFunds(msg.sender, amountToClaim);
        }

    }

    //Create new type of stake
    function createTypeOfStake(uint8 percentage, uint256 duration) public onlyOwner {
        require(percentage > 0, "CreateTypeOfStake: the percentage must be greater than 0");
        require(duration > 0, "CreateTypeOfStake: the duration must be greater than 0");

        idTypeOfStake.increment();

        typeOfStakes[uint8(idTypeOfStake.current())] = TypeOfStake({
            idTypeOfStake: uint8(idTypeOfStake.current()),
            percentage: percentage,
            duration: duration,
            isActived: true
        });
    }

    //withdraw RENT
    function withdrawRENT(uint256 amount) public onlyOwner {
        require(amount > 0, "Withdraw: amount must be greater than 0");
        require(amount <= RENT.balanceOf(address(this)), "Withdraw: amount must be less than the contract balance");

        if (!RENT.transfer(msg.sender, amount)) {
            revert ErrorSendingFunds(msg.sender, amount);
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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