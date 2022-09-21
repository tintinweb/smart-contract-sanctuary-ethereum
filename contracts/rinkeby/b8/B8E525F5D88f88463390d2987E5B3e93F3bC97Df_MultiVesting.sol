// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20Mintable.sol";
import "./interfaces/IVesting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MultiVesting is IVesting, Ownable {

    IERC20Mintable public immutable token;
    address public saleContract;

    mapping(address => uint256) public released;

    mapping(address => Beneficiary) public beneficiary;

    constructor(IERC20Mintable _token) {
        token = _token;
    }

    function setSaleContract(address _addr) external onlyOwner {
        saleContract = _addr;
    }

    /**
        cliff = duration in seconds
        duration = duration in seconds
        startTimestamp = timestamp
    */
    function vest(address beneficiaryAddress, uint256 startTimestamp, uint256 durationSeconds, uint256 amount, uint256 cliff) external override {
        require(msg.sender == saleContract, "Only sale contract can call");
        require(beneficiaryAddress != address(0), "beneficiary is zero address");

        beneficiary[beneficiaryAddress].start = startTimestamp;
        beneficiary[beneficiaryAddress].duration = durationSeconds;
        beneficiary[beneficiaryAddress].cliff = cliff;
        beneficiary[beneficiaryAddress].amount = amount;
    }

    function release(address beneficiaryAddress) external override {
        (uint256 _releasableAmount,) = _releasable(msg.sender, block.timestamp);

        require(_releasableAmount > 0, "Can't claim yet!");

        released[beneficiaryAddress] += _releasableAmount;
        token.transfer(beneficiaryAddress, _releasableAmount);

        emit Released(_releasableAmount, msg.sender);
    }

    function releasable(address _beneficiary, uint256 _timestamp)
    external view override returns (uint256 canClaim, uint256 earnedAmount) {
        return _releasable(_beneficiary, _timestamp);
    }

    function _releasable(address _beneficiary, uint256 _timestamp)
    internal view returns (uint256 canClaim, uint256 earnedAmount) {
        (canClaim, earnedAmount) = _vestingSchedule(
            _beneficiary,
            beneficiary[_beneficiary].amount,
            _timestamp
        );
        canClaim -= released[_beneficiary];
    }

    function vestedAmountBeneficiary(address _beneficiary, uint256 _timestamp)
    external view override returns (uint256 vestedAmount, uint256 maxAmount) {
        return _vestedAmountBeneficiary(_beneficiary, _timestamp);
    }

    function _vestedAmountBeneficiary(address _beneficiary, uint256 _timestamp)
    internal view returns (uint256 vestedAmount, uint256 maxAmount) {
        // maxAmount = token.balanceOf(address(this)) + _released;
        maxAmount = beneficiary[_beneficiary].amount;
        (, vestedAmount) = _vestingSchedule(_beneficiary, maxAmount, _timestamp);
    }

    function _vestingSchedule(address _beneficiary, uint256 totalAllocation, uint256 timestamp)
    internal view returns (uint256, uint256) {
        if (timestamp < beneficiary[_beneficiary].start) {
            return (0, 0);
        } else if (timestamp > beneficiary[_beneficiary].start + beneficiary[_beneficiary].duration) {
            return (totalAllocation, totalAllocation);
        } else {
            uint256 res = (totalAllocation * (timestamp - beneficiary[_beneficiary].start)) / beneficiary[_beneficiary].duration;

            if (timestamp < beneficiary[_beneficiary].start + beneficiary[_beneficiary].cliff) return (0, res);
            else return (res, res);
        }
    }

    function emergancyVest() external onlyOwner override {
        token.transfer(owner(), token.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable is IERC20 {
    function mint(uint256 _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVesting {
    event Released(uint256 amount, address to);

    struct Beneficiary {
        uint256 start;
        uint256 duration;
        uint256 cliff;
        uint256 amount;
    }

    function vest(address beneficiaryAddress, uint256 startTimestamp,uint256 durationSeconds, uint256 amount, uint256 cliff) external;

    function release(address beneficiaryAddress) external;

    function releasable(address _beneficiary, uint256 _timestamp) external view returns (uint256 canClaim, uint256 earnedAmount);
    
    function vestedAmountBeneficiary(address _beneficiary, uint256 _timestamp) external view returns (uint256 vestedAmount, uint256 maxAmount);
    
    function emergancyVest() external;

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