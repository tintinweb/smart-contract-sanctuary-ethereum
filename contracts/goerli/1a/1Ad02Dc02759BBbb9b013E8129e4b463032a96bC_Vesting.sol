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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/**
 * @title  DoinGud: Vesting.sol
 * @author Daoism Systems
 * @notice Vesting Contract Implementation for DoinGudDAO
 * @custom:security-contact [email protected] || [email protected]
 * @dev Implementation of the Vesting Mechanics for DoinGud
 *
 * The Vesting Contract allows DoinGud to reward early contributors with staked dAMOR.
 * In addition, the contract allows for additional staking of AMOR for contributors.
 *
 * MIT License
 * ===========
 *
 * Copyright (c) 2022 DoinGud
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *
 */

/// Access controls
import "@openzeppelin/contracts/access/Ownable.sol";
/// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./utils/interfaces/IdAMORxGuild.sol";

contract Vesting is Ownable {
    /// Struct containing allocation details
    struct Allocation {
        uint256 tokensAllocated;
        uint256 cliff;
        uint256 vestingDate;
        uint256 tokensClaimed;
    }

    uint256 public tokensAllocated;
    address public constant SENTINAL = address(0x1);
    address public sentinalOwner;
    
    /// Address mapping to keep track of the sentinal owner
    /// Initialized as `SENTINAL`, updated in `allocateVestedTokens`
    mapping(address => address) internal sentinalOwners;
    /// Linked list of all the beneficiaries
    mapping(address => address) public beneficiaries;
    /// Mapping of beneficiary address to Allocation
    mapping(address => Allocation) public allocations;
    
    /// Tokens
    address public dAMOR;
    IERC20 public amorToken;

    /// Contract creation time (for vesting logic)
    uint256 public immutable VESTING_START;

    /// Custom errors
    /// The target has already been allocated an initial vesting amount
    error AlreadyAllocated();
    /// Not enough unallocated dAMOR to complete this allocation
    error InsufficientFunds();
    /// The transfer returned `false`
    error TransferUnsuccessful();
    /// Invalid vesting date
    error InvalidDate();
    /// Beneficiary not found
    error NotFound();
    /// The tokens haven't vested with the beneficiary yet (cliff not yet reached)
    error NotVested();

    constructor(address metaDao, address amor, address dAmor) {
        transferOwnership(metaDao);
        dAMOR = dAmor;
        amorToken = IERC20(amor);
        sentinalOwner = address(0);
        beneficiaries[sentinalOwner] = SENTINAL;
        VESTING_START = block.timestamp;
    }

    /// @notice Receives AMOR and stakes it in the dAMOR contract
    /// @dev    Requires approval of AMOR amount prior to calling
    /// @param  amount of AMOR to be transferred to this contract
    function lockAMOR(uint256 amount) external {
        if (amorToken.transferFrom(msg.sender, address(this), amount) == false) {
        revert TransferUnsuccessful();
        }
    }

    /// @notice Allows a beneficiary to withdraw AMOR that has accrued to it
    /// @dev    Converts dAMOR to AMOR and transfers it to the beneficiary
    /// @param  amount the amount of dAMOR to convert to AMOR
    function withdrawAmor(uint256 amount) external {
        if (amount > tokensAvailable(msg.sender)) {
            revert InsufficientFunds();
        }
        Allocation storage allocation = allocations[msg.sender];

        if (allocation.cliff > block.timestamp) {
            revert NotVested();
        }
        
        /// Update internal balances
        allocation.tokensClaimed -= amount;
        /// Withdraw the AMOR from the staking contract
        uint256 amountReturned = amorToken.balanceOf(address(this));
        //dAMOR.withdraw();
        amountReturned = amorToken.balanceOf(address(this)) - amountReturned;
        /// Transfer the AMOR to the caller
        if (!amorToken.transfer(msg.sender, amountReturned)) {
            revert TransferUnsuccessful();
        }
    }

    /// @notice Returns the amount of vested tokens allocated to the target
    /// @param  target the address of the beneficiary
    /// @return the amount of dAMOR allocated to the target address
    function balanceOf(address target) external view returns(uint256) {
        return allocations[target].tokensAllocated;
    }

    /// @notice Allocates dAMOR to a target beneficiary
    /// @dev    Can only be called by the MetaDAO
    /// @param  target the beneficiary to which tokens should vest
    /// @param  amount the amount of dAMOR to allocate to the tartget beneficiary
    /// @param  cliff the date at which tokens become claimable. `0` for no cliff.
    /// @param  vestingDate the date at which all the tokens have vested in the beneficiary
    function allocateVestedTokens(
        address target,
        uint256 amount,
        uint256 cliff,
        uint256 vestingDate
    ) external onlyOwner {
        /// Check that there are enough unallocated tokens
        if (amorToken.balanceOf(address(this)) < tokensAllocated + amount) {
            revert InsufficientFunds();
        }
        /// Create the new struct and add it to the mapping
        _setAllocationDetail(target, amount, cliff, vestingDate);
        /// Add the amount to the tokensAllocated;
        tokensAllocated += amount;
        /// Add the beneficiary to the beneficiaries linked list if it doesn't exist yet
        if (beneficiaries[target] == address(0)) {
            beneficiaries[sentinalOwner] = target;
            beneficiaries[target] = SENTINAL;
            sentinalOwner = target;
        }
    }

    /// @notice Modifies an existing allocation
    /// @dev    Cannot modify `amount`, `vestingDate` or `cliff` lower
    /// @param  target the beneficiary to which tokens should vest
    /// @param  amount the amount of AMOR to allocate to the tartget beneficiary
    /// @param  cliff the date at which tokens become claimable. `0` for no cliff.
    /// @param  vestingDate the date at which all the tokens have vested in the beneficiary
    function modifyAllocation(
        address target,
        uint256 amount,
        uint256 cliff,
        uint256 vestingDate
    ) external {
        if (beneficiaries[target] == address(0)) {
            revert NotFound();
        }
        if (allocations[target].cliff > cliff || allocations[target].vestingDate > vestingDate) {
            revert InvalidDate();
        }
        _setAllocationDetail(target, amount, cliff, vestingDate);
    }

    /// @notice Calculates the number of dAMOR accrued to a given beneficiary
    /// @dev    For a given beneficiary calculates the amount of dAMOR by using the vesting date
    /// @param  beneficiary the address for which the calcuation is done
    /// @return amount of tokens claimable by the beneficiary address
    function tokensAvailable(address beneficiary) public view returns(uint256) {
        if (beneficiaries[beneficiary] == address(0)) {
            revert NotFound();
        }
        Allocation storage allocation = allocations[beneficiary];
        uint256 amount = allocation.tokensAllocated * ((block.timestamp - VESTING_START) / (allocation.vestingDate - VESTING_START));
        return amount - allocation.tokensClaimed;
    }

    function _setAllocationDetail(
        address target,
        uint256 amount,
        uint256 cliff,
        uint256 vestingDate
        ) internal {
        Allocation storage allocation = allocations[target];
        allocation.cliff = cliff;
        allocation.tokensAllocated += amount;
        allocation.vestingDate = vestingDate;
        allocation.cliff = cliff;
        }
}

// SPDX-License-Identifier: MIT

/// @title  DoinGud dAMORxGuild Interface
/// @author Daoism Systems Team
pragma solidity 0.8.15;

interface IdAMORxGuild {
    function init(
        string memory name,
        string memory symbol,
        address initOwner,
        address _AMORxGuild,
        uint256 amount
    ) external returns (bool);

    //  receives ERC20 AMORxGuild tokens, which are getting locked
    //  and generate dAMORxGuild tokens in return.
    //  Tokens are minted following the formula

    /// @notice Stakes AMORxGuild and receive dAMORxGuild in return
    /// @dev    Front end must still call approve() on AMORxGuild token to allow transferFrom()
    /// @param  amount uint256 amount of dAMOR to be staked
    /// @param  time uint256
    /// @return uint256 the amount of dAMORxGuild received from staking
    function stake(uint256 amount, uint256 time) external returns (uint256);

    /// @notice Increases stake of already staken AMORxGuild and receive dAMORxGuild in return
    /// @dev    Front end must still call approve() on AMORxGuild token to allow transferFrom()
    /// @param  amount uint256 amount of dAMOR to be staked
    function increaseStake(uint256 amount) external returns (uint256);

    /// @notice Withdraws AMORxGuild tokens; burns dAMORxGuild
    /// @dev When this tokens are burned, staked AMORxGuild is being transfered
    ///      to the controller(contract that has a voting function)
    function withdraw() external returns (uint256);

    /// @notice Delegate your dAMORxGuild to the address `account`
    /// @param  to address to which delegate users FXAMORxGuild
    function delegate(address to) external;

    /// @notice Undelegate your dAMORxGuild
    function undelegate() external;
}