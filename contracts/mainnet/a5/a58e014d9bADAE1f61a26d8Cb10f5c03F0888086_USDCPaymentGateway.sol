// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
}

/**
 * @dev Facilitates payments and withdrawals for the SDC-CCI examination.
 */
contract USDCPaymentGateway is Ownable, ReentrancyGuard {
    DaiToken private immutable daiToken;
    
    uint256 private minimumWithdrawalAmount;
    uint256 private withdrawalAmount;
    uint256 private cost;
    bool private stopped;

    event CircuitBreaker(bool stopped);
    event PaymentReceived(address from, uint256 amount);
    event Withdrawal(uint256 amount);
   
    /*
    USDC 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
    USDC Proxy 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF

    USDC GOERLI TESTNET 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
    GOERLI Proxy 0xe27658a36cA8A59fE5Cc76a14Bde34a51e587ab4
    */

    /**
    * @dev Initializes the smart contract's withdrawalAmount and circuit breaker state, and the
    * _currencyTokenAddress, _cost, and _minimumWithdrawalAmount variables.
    * @param _currencyTokenAddress The address of the token in which payment will be accepted.
    * @param _cost The cost of the exam.
    * @param _minimumWithdrawalAmount The minimum amount that can be withdrawn by the owner.
    */
    constructor(address _currencyTokenAddress, uint256 _cost, uint256 _minimumWithdrawalAmount) ReentrancyGuard() { 
        daiToken = DaiToken(_currencyTokenAddress);
        stopped = false;
        withdrawalAmount = 0;
       
        cost = _cost;
        minimumWithdrawalAmount = _minimumWithdrawalAmount;
    }
    
    modifier stopWhenCircuitBreakerEnabled {
        require(!stopped, "USDCPaymentGateway: The smart contract is currently stopped");
        _;
    }

    fallback() external payable {
        revert("USDCPaymentGateway: Cannot receive ETH directly");
    }

    receive() external payable {
        revert("USDCPaymentGateway: Cannot receive ETH directly");
    }

    /**
     * @dev Makes payment and ensures that the sender has enough USDC.
     * @param amount The amount to be paid by the sender.
     */ 
    function makePayment(uint256 amount) external nonReentrant stopWhenCircuitBreakerEnabled {
        require(daiToken.balanceOf(msg.sender) >= amount, "USDCPaymentGateway: Sender's balance is less then the amount being paid.");
        require(amount >= cost, "USDCPaymentGateway: Amount sent must be greater than or equal to the cost.");
        
        daiToken.transferFrom(msg.sender, address(this), amount);
        emit PaymentReceived(msg.sender, amount);
    }

    /**
     * @dev Sets the amount to be withdrawn by the owner.
     * @param amount The amount to be withdrawn by the owner.
    */ 
    function setWithdrawalAmount(uint256 amount) external onlyOwner {
        withdrawalAmount = amount;
    }

    /**
     * @dev Stops the smart contract from receiving payments.
     */
    function toggleCircuitBreaker() external onlyOwner {
        stopped = !stopped;
        emit CircuitBreaker(stopped);
    } 

    /**
     * @dev Withdraws the amount set by the owner.
    */
    function withdraw() external nonReentrant onlyOwner {
        require(withdrawalAmount > minimumWithdrawalAmount, "USDCPaymentGateway: Withdrawal amount must be greater than configured minimum withdrawal amount.");

        daiToken.approve(owner(), withdrawalAmount);
        daiToken.transfer(owner(), withdrawalAmount);

        emit Withdrawal(withdrawalAmount);
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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