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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @title Migration: Contract for Migrating MRI tokens over to the MFC token
 */
contract Migration is Ownable, ReentrancyGuard {
    
    
    bool public isWithdrawEnabled;
    bool public isDepositEnabled;
    uint256 public swapRateMultiplier;
    uint256 public swapRateDivider;

    mapping (address => uint256) public migratedMRI;
    mapping (address => uint256) public totalMFCdue;
    mapping (address => uint256) public withdrawnMFC;

    IERC20 public MRI;
    IERC20 public MFC;
    
    

    event WithdrawnMRI(address indexed user, uint256 amount);
    event WithdrawnMFC(address indexed user, uint256 amount);
    event DepositedMRI(address indexed user, uint256 amount);
    event EmergencyWithdrawMFC(uint256 amount);
    event WithdrawsEnabled(bool status);
    event DepositEnabled(bool status);
    event SwapRateUpdated(uint256 swapRateMultiplier, uint256 swapRateDivider);
    event TokenSet(address tokenMRI, address tokenMFC);
    error WithdrawMFC_NotEnabled();
    error DepositedMRI_NotEnabled();
    error WithdrawMFC_NothingToWithdraw();

    constructor(address _MRI, uint256 _swapRateMultiplier, uint256 _swapRateDivider) {
        MRI =  IERC20(_MRI);
        swapRateMultiplier = _swapRateMultiplier; 
        swapRateDivider = _swapRateDivider;
    }

    /**
     * @dev deposit MRI tokens to get the MFC MFC tokens
     * @param _amount: Amount of MRI tokens to migrate
     */
    function depositMRI(uint256 _amount) external nonReentrant {
        if( !isDepositEnabled) {
            revert DepositedMRI_NotEnabled();
        }
        bool success = MRI.transferFrom(msg.sender, address(this), _amount);
        if( success){
            uint256 MFCAmount = _amount * swapRateMultiplier / swapRateDivider;
            migratedMRI[msg.sender] += _amount;
            totalMFCdue[msg.sender] += MFCAmount;
            emit DepositedMRI(msg.sender, _amount);
        }
        else {
            revert();
        }

    }
    /**
     * @dev Withdraws MFC tokens from the contract
     */
    function withdrawMFC() external nonReentrant {
        if( !isWithdrawEnabled) {
            revert WithdrawMFC_NotEnabled();
        } 
        uint256 withdrawAmount = totalMFCdue[msg.sender] - withdrawnMFC[msg.sender];
      
        if(  withdrawAmount == 0) {
            revert WithdrawMFC_NothingToWithdraw();
        }
        withdrawnMFC[msg.sender] += withdrawAmount;
        bool success = MFC.transfer(msg.sender, withdrawAmount);
        if(!success)
            revert();
        emit WithdrawnMFC(msg.sender, withdrawAmount);
    }

    /**
     * @dev Withdraws MRI tokens from the contract
     * @param percentage: Percentage of MRI tokens to withdraw
     */
    function withdrawMRI(uint256 percentage) external onlyOwner {
        bool success = MRI.transfer(msg.sender, MRI.balanceOf(address(this)) * percentage / 100);
        if(!success)
            revert();
        emit WithdrawnMRI(msg.sender, MRI.balanceOf(address(this)) * percentage / 100);
    }

    /**
     * @dev Owner Withdraws MFC tokens from the contract in case of emergency
     * @param percentage: Percentage of MFC tokens to withdraw
     */
    function emergencyWithdrawMFC(uint256 percentage) external onlyOwner {
        bool success = MFC.transfer(msg.sender, MFC.balanceOf(address(this)) * percentage / 100);
        if(!success)
            revert();
        emit EmergencyWithdrawMFC(MFC.balanceOf(address(this)) * percentage / 100);
    }

    /**
     * @dev Enable withdraws
     * param status: Boolean to enable or disable withdraws
     */
    function enableWithdraws(bool status) external onlyOwner {
        isWithdrawEnabled = status;
        emit WithdrawsEnabled(status);
    }
    /**
     * @dev Enable deposits
     * param status: Boolean to enable or disable deposits
     */
    function enableDeposits(bool status) external onlyOwner {
        isDepositEnabled = status;
        emit DepositEnabled(status);
    }

    /**
    
     */

    /**
     * @dev Sets the swap rate for the migration (therefore: 0 < swapRate < 1 or swapRate > 1 )
     * @param _swapRateMultiplier: Multiplier to calculate the token migration rate
     * @param _swapRateDivider: Divider to calculate the token migration rate 
     */
    function setSwapRate(uint256 _swapRateMultiplier, uint256 _swapRateDivider) external onlyOwner {
        if( _swapRateMultiplier == 0 || _swapRateDivider == 0)
            revert();
        swapRateMultiplier = _swapRateMultiplier;
        swapRateDivider = _swapRateDivider;
        emit SwapRateUpdated(_swapRateMultiplier, _swapRateDivider);
    }

    /**
     * @dev Sets the start time for the migration
     * @param _MRI: Address of the MRI token
     * @param _MFC: Address of the MFC token
     */
    function setTokens(address _MRI, address _MFC) external onlyOwner {
        MRI = IERC20(_MRI);
        MFC = IERC20(_MFC);
        emit TokenSet(_MRI, _MFC);
    }

    /**
     * @dev Returns the amount of MFC tokens that can be withdrawn by the user
     */
    function getWithdrawableTokens(address _user) external view returns(uint256 withdrawableTokens) {
        return totalMFCdue[_user] - withdrawnMFC[_user];
    }

}