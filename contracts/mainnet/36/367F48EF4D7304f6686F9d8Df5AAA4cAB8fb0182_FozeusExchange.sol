/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity ^0.8.0;

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

/**
 * @title FozeusExchange
 * @author Fozeus Team
 * @notice Used for balance deposits as additional payment method via ERC-20 token that is supported by this contract.
 * @dev All function calls are currently implemented without side effects.
 */
contract FozeusExchange is Ownable, ReentrancyGuard {

    bool    private _isStopped;
    address private _supportedToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    uint256 private _minAmount = 10000000000000000;

    /**
     * @dev Emmited when `_amount` tokens are moved from `_payee` to contract address.
     */
    event Payment(uint indexed _amount, address indexed _payee);

    error ContractStopped();
    error MinValueValidationError(uint256 _required, uint256 _passed);

    /**
     * @notice Trasnfers amount of tokens from payee to this contract.
     * @dev Transfers `_amount` tokens with {transferFrom} function from `msg.sender` to `address(this)`.
     * @param _amount Amount of tokens to transfer from `msg.sender` to this `address(this)`.
     * @return Returns a boolean value indicating whether the operation succeeded.
     * 
     * Emits a {Payment} event.
     */
    function pay(uint256 _amount) external nonReentrant returns(bool) {
        if (_isStopped == true) {
            revert ContractStopped();
        }

        if (_amount < _minAmount) {
            revert MinValueValidationError({_required: _minAmount, _passed: _amount});
        }
        
        IERC20(_supportedToken).transferFrom(msg.sender, address(this), _amount);
        
        emit Payment(_amount, msg.sender);
        return true;
    }

    /**
     * @notice Transfers amount of specified ERC-20 token address from this contract to this contract owner.
     * @dev Transfers `_amount` of ERC-20 `_contractAddress` from this contrdact to `owner()`.
     * @param _contractAddress ERC-20 contract address.
     * @param _amount Amount of tokens to transfer from `address(this)` to `owner()`.
     * @return Returns a boolean value indicating whether the operation succeeded.
     */
    function encashment(address _contractAddress, uint256 _amount) external onlyOwner nonReentrant returns(bool) {
        IERC20(_contractAddress).approve(address(this), _amount);
        IERC20(_contractAddress).transferFrom(address(this), owner(), _amount);

        return true;
    }

    /**
     * @notice Toggles contract on/off state.
     * @dev Toggles `_isStopped` value changing contract state.
     * @return Returns a boolean value of toggled `_isStopped` variable.
     */
    function toggleIsStopped() external onlyOwner returns(bool) {
        _isStopped = !_isStopped;
        return _isStopped;
    }

    /**
     * @notice Sets new ERC-20 supported token address that will be allowed for payment within current contract. 
     * @dev Sets `_supportedToken` address.
     * @param _newTokenAddress ERC-20 contract address.
     * @return Address of new supported token.
     */
    function setSupportedToken(address _newTokenAddress) external onlyOwner returns(address) {
        _supportedToken = _newTokenAddress;
        return _newTokenAddress;
    }

    /**
     * @notice Sets minimum amount that can be paid to this contract.
     * @dev Sets `_minAmount` value.
     * @param _amount Minimum amount.
     * @return New minimum amount.
     */
    function setMinAmount(uint256 _amount) external onlyOwner returns(uint256) {
        _minAmount = _amount;
        return _amount;
    }
    
    /**
     * @notice Returns the contract (on/off) state.
     * @dev Returns the `_isStopped` flag of this contract.
     * @return Boolean value of contract state.
     */
    function isStopped() external view returns(bool) {
        return _isStopped;
    }

    /**
     * @notice Returns the supported ERC-20 contract address that is allowed to pay with using current contract.
     * @dev Returns the `_supportedToken` address of this contract.
     * @return Address of supported ERC-20 token.
     */
    function supportedToken() external view returns(address) {
        return _supportedToken;
    }

    /**
     * @notice Returns minimum amount that can be paid to this contract.
     * @dev Returns `_minAmount` that can be transferred to `address(this)` using {pay} function.
     * @return Minimum amount.
     */
    function minAmount() external view returns(uint256) {
        return _minAmount;
    }
}