// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract LuckyStaking is Ownable {
    event Staked(address indexed staker, uint32 indexed stakeId, uint160 amount, uint64 unlockTime);
    event Unstaked(address indexed unstaker, uint32 indexed stakeId, uint256 amount);
    // The stake mapping
    mapping(address => Stake[]) stakes;
    // Uses one slot
    struct Stake {
        uint128 stakedAmount;
        uint32 stakeId;
        uint32 profitMultiplier;
        uint64 unlockTime;
    }
    // Array to keep those with stakes
    address[] private _stakers;
    // Open block - 256
    address private stakedToken;
    uint32 private profitDivisor = 100000;
    uint32 private currentMaxStakeId;
    // 64 bytes free

    constructor(address tokenStake) {
        stakedToken = tokenStake;
        currentMaxStakeId = 0;
    }
    
    function stakeTokens(uint128 amount, uint64 lockWeeks) external returns (uint32) {
        // Minimum unlock time 1 week
        require(lockWeeks > 0, "ToadStaking: Must be more than one week until unlock.");
        // Calculate how many weeks - 1 is 1 week
        uint64 unlockTime = uint64(block.timestamp + (lockWeeks * 60*60*24*7)); 
        // Profit weeks caps at 25 (2.3x chance)
        uint64 profitWeeks = lockWeeks-1;
        if(profitWeeks > 25) {
            profitWeeks = 25;
        }
        // There turns out to be a trick of 3/2 to be sqrt(unlockWeeks^3)
        // An int is fine anyway as we use divisor of 100000 as total
        uint32 profit = uint32(sqrt(profitWeeks**3)*1000 + 105000);

        // Need tokens to be in their wallet
        IERC20 tok = IERC20(stakedToken);
        require(tok.balanceOf(msg.sender) >= amount, "LuckyStaking: Must own enough tokens to stake.");
        // Take the tokens
        tok.transferFrom(msg.sender, address(this), amount);
        // Get the current max stake ID
        uint32 newId = currentMaxStakeId;
        currentMaxStakeId = currentMaxStakeId + 1;
        if(uint32(stakes[msg.sender].length) == 0) {
            _stakers.push(msg.sender);
        }
        // Create a new Stake object 
        stakes[msg.sender].push(Stake(amount, newId, profit, unlockTime));
        emit Staked(msg.sender, newId, amount, unlockTime);
        return newId;
    }
    

    function unstakeTokens(uint32 id, uint256 index) external {
        // Get the stake
        require(stakes[msg.sender].length > index, "LuckyStaking: Invalid index.");
        require(stakes[msg.sender][index].stakeId == id, "LuckyStaking: ID doesn't match index.");
        Stake memory unstake = stakes[msg.sender][index];
        // Make sure we can unlock
        require(unstake.unlockTime < block.timestamp, "LuckyStaking: Cannot unlock yet.");
        // Send the stake amount to the sender
        IERC20 tok = IERC20(stakedToken);
        uint256 amount = unstake.stakedAmount;
        // Clear the stake from the list
        if(stakes[msg.sender].length-1 != index) {
            // Copy the last stake to index
            stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length-1];
        }
        stakes[msg.sender].pop();
        
        tok.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, id, amount);
    }

    function transferStakeOwnership(uint32 id, uint256 index, address newOwner) external {
        require(stakes[msg.sender].length > index, "LuckyStaking: Invalid index.");
        require(stakes[msg.sender][index].stakeId == id, "LuckStaking: ID doesn't match index."); 
        Stake memory stakeToTransfer = stakes[msg.sender][index];
        // Delete from sender
        // Clear the stake from the list
        if(stakes[msg.sender].length-1 != index) {
            // Copy the last stake to index
            stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length-1];
        }
        stakes[msg.sender].pop();
        stakes[newOwner].push(stakeToTransfer);
    }

    function queryAllStakes() external view returns (address[] memory stakers, Stake[][] memory stakeStructs) {
        stakers = _stakers;
        stakeStructs = new Stake[][](_stakers.length);
        for(uint i = 0; i < _stakers.length; i++) {
            stakeStructs[i] = (stakes[_stakers[i]]);
        }
    }

    function queryHoldersStakes(address holder) public view returns (uint128[] memory amounts, uint32[] memory stakeIds, uint32[] memory stakeMultipliers, uint64[] memory unlockTimes) {
        // Get the stakes for a holder
        Stake[] memory stakesForHolder = stakes[holder];
        // Create storage
        amounts = new uint128[](stakesForHolder.length);
        stakeIds = new uint32[](stakesForHolder.length);
        stakeMultipliers = new uint32[](stakesForHolder.length);
        unlockTimes = new uint64[](stakesForHolder.length);
        for(uint i = 0; i < stakesForHolder.length; i++) {
            amounts[i] = stakesForHolder[i].stakedAmount;
            stakeIds[i] = stakesForHolder[i].stakeId;
            stakeMultipliers[i] = stakesForHolder[i].profitMultiplier;
            unlockTimes[i] = stakesForHolder[i].unlockTime;
        }
    }
    
    function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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