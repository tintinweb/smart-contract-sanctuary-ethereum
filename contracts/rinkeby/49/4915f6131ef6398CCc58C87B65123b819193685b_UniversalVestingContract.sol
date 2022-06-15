//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract UniversalVestingContract is Ownable, Pausable {


    IERC20 token;


    struct Investor {
        address account;
        uint256 amount;
        uint256 investorType;
    }


    struct vestingDetails {
        uint investorType;
        uint totalBalance;
        uint lastClaimTime;
        uint initialToBeClaimed;
        uint intermediateToBeClaimed;
        uint linearToBeClaimed;
        uint initialClaimed;
        uint intermediateClaimed;
        uint linearClaimed;
        bool hasInitialClaimed;
        bool hasIntermediateClaim;
        bool hasLinearClaimed;
    }

    event InvestorAddress(address account, uint _amout,uint investorType);
    event VestingAmountTaken(address account, uint _amout);
    mapping (address => vestingDetails) public Investors;
    mapping (address => bool) public isUserAdded;
//    address public signer;

    uint initialVestingAmountWithdrawThresholdTime;
    uint intermediateVestingAmountWithdrawThresholdTime;
    uint linearVestingAmountWithdrawThresholdTime;
    uint[] public initialAmountReleased;
    uint[] public intermediateAmountReleased;
    uint[] public linearVestingAmountReleased; // stores percentage
    uint[] public intermediateVestingTimePeriod;
    uint[] public linearVestingTimePeriod;

    function addMinter(Investor[] memory vest) external onlyOwner {
        for (uint i = 0;i < vest.length;i++) {
            require (!isUserAdded[vest[i].account],'User already whitelisted');
            isUserAdded[vest[i].account] = true;
            vestingDetails memory vesting;
            vesting.investorType = vest[i].investorType;
            vesting.totalBalance = vest[i].amount;
            vesting.initialToBeClaimed = (initialAmountReleased[vest[i].investorType] * 100)/(vest[i].amount);
            vesting.intermediateToBeClaimed = (intermediateAmountReleased[vest[i].investorType] * 100)/vest[i].amount;
            vesting.linearToBeClaimed = (linearVestingAmountReleased[vest[i].investorType] * 100) / vest[i].amount;
            if (vesting.intermediateToBeClaimed >= 0) vesting.lastClaimTime = intermediateVestingAmountWithdrawThresholdTime;
            else if (vesting.intermediateToBeClaimed == 0 && vesting.linearToBeClaimed >=0) vesting.lastClaimTime = linearVestingAmountWithdrawThresholdTime;
            Investors[vest[i].account] = vesting;
            emit InvestorAddress(vest[i].account, vest[i].amount,vest[i].investorType);
        }
    }

    function withdraw() external whenNotPaused {
        require (isUserAdded[msg.sender],'User Not Added');
        require (!Investors[msg.sender].hasLinearClaimed,'Vesting: All Amount Claimed');
        (uint amount, uint returnType) = getVestingBalance(msg.sender);
        require(returnType != 4,'Time Period is Not Over');
        if (returnType == 1) {
            Investors[msg.sender].hasInitialClaimed = true;
            token.transfer(msg.sender, amount);
            emit VestingAmountTaken(msg.sender, amount);
        } else if (returnType == 2) {
            Investors[msg.sender].lastClaimTime = block.timestamp;
            Investors[msg.sender].intermediateClaimed+=amount;
            require (Investors[msg.sender].intermediateToBeClaimed >= Investors[msg.sender].intermediateClaimed,'Intermediate Vesting: Cannot Claim More');
            if (Investors[msg.sender].intermediateToBeClaimed ==  Investors[msg.sender].intermediateClaimed)
            {
                Investors[msg.sender].hasIntermediateClaim = true;
                Investors[msg.sender].lastClaimTime = linearVestingAmountWithdrawThresholdTime;
            }
            token.transfer(msg.sender, amount);
            emit VestingAmountTaken(msg.sender, amount);
        }
        else {
            Investors[msg.sender].lastClaimTime = block.timestamp;
            Investors[msg.sender].linearClaimed += amount;
            require (Investors[msg.sender].linearToBeClaimed >= Investors[msg.sender].linearClaimed,'Linear Besting: Cannot Claim More');
            if (Investors[msg.sender].linearToBeClaimed == Investors[msg.sender].linearClaimed)
            {
                Investors[msg.sender].hasLinearClaimed = true;
            }
            token.transfer(msg.sender, amount);
            emit VestingAmountTaken(msg.sender, amount);
        }
    }

    //@dev Contract Setters

    function setRewardTokenAddress (address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
    }
    
    function setThresholdTimeForVesting (uint initial, uint intermediate, uint linear) external onlyOwner {
        initialVestingAmountWithdrawThresholdTime = initial;
        intermediateVestingAmountWithdrawThresholdTime = intermediate;
        linearVestingAmountWithdrawThresholdTime = linear;
    }

    function setArray (
        uint[] memory initialAmountPerInvestor,
        uint[] memory intermediateAmountReleasedPerInvestor,
        uint[] memory linearAmountReleasedAmountReleasedPerInvestor,
        uint[] memory intermediateVestingTimePeriodPerInvestor,
        uint[] memory linearVestingTimePeriodPerInvestor) external  onlyOwner {
        if (initialAmountPerInvestor.length > 0)
            initialAmountReleased = initialAmountPerInvestor;
        if (intermediateAmountReleasedPerInvestor.length > 0)
            intermediateAmountReleased = intermediateAmountReleasedPerInvestor;
        if (linearAmountReleasedAmountReleasedPerInvestor.length > 0)
            linearVestingAmountReleased = linearAmountReleasedAmountReleasedPerInvestor;
        if (intermediateVestingTimePeriodPerInvestor.length > 0)
            intermediateVestingTimePeriod = intermediateVestingTimePeriodPerInvestor;
        if (linearVestingTimePeriodPerInvestor.length > 0)
            linearVestingTimePeriod = linearVestingTimePeriodPerInvestor;
    }


    //@dev Get Details About Vesting Time Period

    function getVestingBalance(address _userAddress) public view returns (uint, uint) {
        if (!Investors[_userAddress].hasInitialClaimed && block.timestamp >= initialVestingAmountWithdrawThresholdTime) return (Investors[_userAddress].initialToBeClaimed,1);
        else if (!Investors[_userAddress].hasIntermediateClaim && Investors[_userAddress].intermediateToBeClaimed > 0 && block.timestamp <= intermediateVestingTimePeriod[Investors[_userAddress].investorType]+intermediateVestingAmountWithdrawThresholdTime) return (intermediatevesttatus(_userAddress),2);
        else if (!Investors[_userAddress].hasLinearClaimed && Investors[_userAddress].linearToBeClaimed > 0 && block.timestamp >= linearVestingAmountWithdrawThresholdTime) return (linearVestingDetails(_userAddress),3);
        else return (0,4);
    }

    function intermediatevesttatus(address _userAddress) public view returns (uint) {
        uint lastClaimTime = Investors[_userAddress].lastClaimTime;
        uint timeDifference = block.timestamp - lastClaimTime;
        timeDifference = timeDifference / 1 days;
        uint intermediateReleaseTimeSpan = intermediateVestingTimePeriod[Investors[_userAddress].investorType];
        uint totalIntermediateFund = Investors[_userAddress].intermediateToBeClaimed;
        uint perDayFund = totalIntermediateFund / intermediateReleaseTimeSpan;
        return perDayFund * timeDifference;
    }

    function linearVestingDetails(address _userAddress) public view returns (uint) {
        uint lastClaimTime = Investors[_userAddress].lastClaimTime;
        uint timeDifference = block.timestamp - lastClaimTime;
        timeDifference = timeDifference / 1 days;
        uint linearReleaseTimeSpan = linearVestingTimePeriod[Investors[_userAddress].investorType];
        uint totalIntermediateFund = Investors[_userAddress].linearToBeClaimed;
        uint perDayFund = totalIntermediateFund / linearReleaseTimeSpan;
        return perDayFund * timeDifference;
    }

    //@dev strictly owner function
    function setPauseStatus(bool status) external onlyOwner {
        if (status) _pause();
        else _unpause();
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