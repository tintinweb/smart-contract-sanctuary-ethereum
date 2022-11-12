/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
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

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
    // function renounceOwnership() public virtual onlyOwner {
    //     _setOwner(address(0));
    // }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

contract BitOption is Pausable, Ownable, ReentrancyGuard {

    /* ========== STRUCTS ========== */

    struct DepositTokenInfo {
        uint256 amount;
        uint256 depositAt;
    }

    /* ========== EVENTS ========== */

    event Receive(address indexed account, uint256 amount);

    event DepositNativeToken(address indexed account, uint256 amount);
    event WithdrawNativeToken(address indexed account, uint256 amount);
    event WithdrawNativeTokenTo(address indexed account, address indexed to, uint256 amount);

    event StakeToken(address indexed account, uint256 amount);
    event UnStakeToken(address indexed account, uint256 amount);
    event WithdrawToken(address indexed account, uint256 amount);
    event WithdrawTokenTo(address indexed account, address indexed to , uint256 amount);
    
    event SetB2OToken(address indexed owner, address _newToken);
    event SetUnstakePeriod(address indexed owner, uint256 _newPeriod);

    /* ========== VARIABLES ========== */

    mapping(address => bool) private _isAdmin;
    mapping(address => DepositTokenInfo) public depositInfo;
    address public B2OToken = 0xc6Cc3d07C705E39D11c7f60d8836C7C78D4aC5f1;
    uint256 public UNSTAKE_PERIOD = 600;

    /* ========== MODIFIER ========== */

    modifier onlyAdmin() {
        require(
            _isAdmin[_msgSender()] || _msgSender() == owner(),
            "GameFiPool: caller is not admin"
        );
        _;
    }

    /* ========== VIEWS ========== */

    function balance() public view returns(uint256) {
        return address(this).balance;
    }

    function balanceOf(address account) public view returns(uint256) {
        return address(account).balance;
    }

    function balanceToken() public view returns(uint256) {
        return IERC20(B2OToken).balanceOf(address(this));
    }

    function balanceTokenOfUser(address account) public view returns(uint256) {
        return IERC20(B2OToken).balanceOf(account);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    
    function withdrawNativeToken(address to, uint256 amount) external onlyAdmin {
        _withdrawNativeToken(to, amount);
    }

    function withdrawToken(uint256 amount) external onlyAdmin {
        _withdrawToken(_msgSender(), amount);
    }

    function setB2OToken(address _newToken) external onlyAdmin {
        require(_newToken != address(0), "SetB2OToken: new token is zero token");
        B2OToken = _newToken;

        emit SetB2OToken(_msgSender(), _newToken);
    }

    function setUnstakePeriod(uint256 _newPeriod) external onlyAdmin {
        UNSTAKE_PERIOD = _newPeriod;

        emit SetUnstakePeriod(_msgSender(), _newPeriod);
    }

    function withdrawAllNativeToken() external onlyAdmin {
        uint256 _balance = address(this).balance;
        payable(owner()).transfer(_balance);

        emit WithdrawNativeToken(_msgSender(), _balance);
    }

    function withdrawAllToken() external onlyAdmin {
        uint256 _balance = balanceToken();
        IERC20(B2OToken).transfer(owner(), _balance);

        emit WithdrawToken(_msgSender(), _balance);
    }

    /* ========== FUNCTIONS ========== */

    function deposit() external payable {
        _depositNativeToken(_msgSender(), msg.value);
    }

    function staking(uint256 amount) external {
        _stakeToken(_msgSender(), amount);
    }

    function unstaking(uint256 amount) external {
        _unstakeToken(_msgSender(), amount);
    }
    
    receive() external payable{
        emit Receive(_msgSender(), msg.value);
    }

    /* ========== INTERNALS ========== */

    function _depositNativeToken(address _to, uint256 _amount) private nonReentrant whenNotPaused { 
        require(_to != address(0), "Deposit: _to is zero address");
        require(_amount > 0, "Deposit: amount must be greater than zero");

        emit DepositNativeToken(_to, _amount);
    }

    function _withdrawNativeToken(address _to, uint256 _amount) private nonReentrant whenNotPaused { 
         require(_to != address(0), "WithdrawNativeTokenTo: account is zero address");
        require(_amount > 0, "WithdrawNativeTokenTo: amount must greater than zero");

        payable(_to).transfer(_amount);

        emit WithdrawNativeTokenTo(_msgSender(), _to, _amount);
    }

    function _stakeToken(address _to, uint256 _amount) private nonReentrant whenNotPaused { 
        require(_to != address(0), "StakeToken: _to is zero address");
        require(_amount > 0, "StakeToken: amount must be greater than zero");
        
        DepositTokenInfo storage info = depositInfo[_to];
        info.amount = info.amount + _amount;
        info.depositAt = block.timestamp;

        IERC20(B2OToken).transferFrom(_to, address(this), _amount);

        emit StakeToken(_to, _amount);
    }

    function _unstakeToken(address _to, uint256 _amount) private nonReentrant whenNotPaused {
        require(_to != address(0), "UnstakeToken: _to is zero address");
        require(_amount > 0, "UnstakeToken: amount must be greater than zero");

        DepositTokenInfo storage info = depositInfo[_to];

        require(info.depositAt + UNSTAKE_PERIOD < block.timestamp, "UnstakeToken: in locked time");

        IERC20(B2OToken).transfer(_to, _amount);

        emit UnStakeToken(_to, _amount);
    }

    function _withdrawToken(address _to, uint256 _amount) private nonReentrant whenNotPaused { 
        require(_to != address(0), "WithdrawTokenTo: _to is zero address");
        require(_amount > 0, "WithdrawTokenTo: amount must be greater than zero");

        IERC20(B2OToken).transfer(_to, _amount);

        emit WithdrawTokenTo(_msgSender(), _to, _amount);
    }

}