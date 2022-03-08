/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

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
 * @dev Interface for checking active staked balance of a user.
 */
interface IBlubSource {
  function getAccumulatedAmount(address staker) external view returns (uint256);
}

/**
 * @dev Interface for ERC-20 $BLUB functions that are required for in-game BLUB.
 */
interface ITradableBlub is IERC20 {
  function _authorisedMint(address sender, uint256 amount) external;
  function _authorisedBurn(address sender, uint256 amount) external;
}

/**
 * @dev Implementation of in-game BLUB.
 */
contract InGameBlub is ReentrancyGuard, Ownable {
    IBlubSource public BlubSource;
    ITradableBlub public tradableBlub;

    uint256 public MAX_SUPPLY;
    uint256 public constant MAX_TAX_VALUE = 100;

    uint256 public spendTaxAmount;
    uint256 public withdrawTaxAmount;

    uint256 public taxesDistributed;
    uint256 public activeTaxCollectedAmount;

    bool public tokenCapSet;

    bool public withdrawTaxCollectionStopped;
    bool public spendTaxCollectionStopped;

    bool public isPaused;
    bool public isDepositPaused;
    bool public isWithdrawPaused;
    bool public isTransferPaused;

    mapping (address => bool) private _isAuthorised;
    address[] public authorisedLog;

    mapping(address => uint256) public depositedAmount;
    mapping(address => uint256) public spentAmount;

    modifier onlyAuthorised {
      require(_isAuthorised[_msgSender()], "Not Authorised");
      _;
    }

    modifier whenNotPaused {
      require(!isPaused, "Transfers paused!");
      _;
    }

    event Withdraw(address indexed userAddress, uint256 amount, uint256 tax);
    event Deposit(address indexed userAddress, uint256 amount);
    event DepositFor(address indexed caller, address indexed userAddress, uint256 amount);
    event Spend(address indexed caller, address indexed userAddress, uint256 amount, uint256 tax);
    event ClaimTax(address indexed caller, address indexed userAddress, uint256 amount);
    event InternalTransfer(address indexed from, address indexed to, uint256 amount);

    constructor(address _source) {
      _isAuthorised[_msgSender()] = true;
      isPaused = true;
      isTransferPaused = true;
      isDepositPaused = true;
      isWithdrawPaused = true;

      withdrawTaxAmount = 25;
      spendTaxAmount = 25;

      BlubSource = IBlubSource(_source);
    }

    /**
    * @dev Returns current spendable balance of a specific user. This balance can be spent by user for other collections without
    *      withdrawal to ERC-20 Blub OR can be withdrawn to ERC-20 Blub.
    */
    function getUserBalance(address user) public view returns (uint256) {
      return (BlubSource.getAccumulatedAmount(user) + depositedAmount[user] - spentAmount[user]);
    }

    /**
    * @dev Function to deposit ERC-20 Blub to the game balance.
    */
    function depositBlub(uint256 amount) public nonReentrant whenNotPaused {
      require(!isDepositPaused, "Deposit Paused");
      require(tradableBlub.balanceOf(_msgSender()) >= amount, "Insufficient balance");

      tradableBlub._authorisedBurn(_msgSender(), amount);
      depositedAmount[_msgSender()] += amount;

      emit Deposit(
        _msgSender(),
        amount
      );
    }

    /**
    * @dev Function to withdraw game Blub to ERC-20 Blub.
    */
    function withdrawBlub(uint256 amount) public nonReentrant whenNotPaused {
      require(!isWithdrawPaused, "Withdraw Paused");
      require(getUserBalance(_msgSender()) >= amount, "Insufficient balance");
      uint256 tax = withdrawTaxCollectionStopped ? 0 : (amount * withdrawTaxAmount) / 100;

      spentAmount[_msgSender()] += amount;
      activeTaxCollectedAmount += tax;
      tradableBlub._authorisedMint(_msgSender(), (amount - tax));

      emit Withdraw(
        _msgSender(),
        amount,
        tax
      );
    }

    /**
    * @dev Function to transfer game Blub from one account to another.
    */
    function transferBlub(address to, uint256 amount) public nonReentrant whenNotPaused {
      require(!isTransferPaused, "Transfer Paused");
      require(getUserBalance(_msgSender()) >= amount, "Insufficient balance");

      spentAmount[_msgSender()] += amount;
      depositedAmount[to] += amount;

      emit InternalTransfer(
        _msgSender(),
        to,
        amount
      );
    }

    /**
    * @dev Function to spend user balance. Can be called by other authorised contracts. To be used for internal purchases of other NFTs, etc.
    */
    function spendBlub(address user, uint256 amount) external onlyAuthorised nonReentrant {
      require(getUserBalance(user) >= amount, "Insufficient balance");
      uint256 tax = spendTaxCollectionStopped ? 0 : (amount * spendTaxAmount) / 100;

      spentAmount[user] += amount;
      activeTaxCollectedAmount += tax;

      emit Spend(
        _msgSender(),
        user,
        amount,
        tax
      );
    }

    /**
    * @dev Function to deposit tokens to a user balance. Can be only called by an authorised contracts.
    */
    function depositBlubFor(address user, uint256 amount) public onlyAuthorised nonReentrant {
      _depositBlubFor(user, amount);
    }

    /**
    * @dev Function to distribute tokens to the user balances. Can be only called by an authorised users.
    */
    function distributeBlub(address[] memory user, uint256[] memory amount) public onlyAuthorised nonReentrant {
      require(user.length == amount.length, "Wrong arrays passed");

      for (uint256 i; i < user.length; i++) {
        _depositBlubFor(user[i], amount[i]);
      }
    }

    /**
    * @dev Function to distribute a constant amount of tokens to the user balances. Can be only called by an authorised users.
    */
    function distributeBlubConstant(address[] memory user, uint256 amount) public onlyAuthorised nonReentrant {
      for (uint256 i; i < user.length; i++) {
        _depositBlubFor(user[i], amount);
      }
    }

    function _depositBlubFor(address user, uint256 amount) internal {
      require(user != address(0), "Deposit to 0 address");
      depositedAmount[user] += amount;

      emit DepositFor(
        _msgSender(),
        user,
        amount
      );
    }

    /**
    * @dev Function to mint tokens to a user balance. Can be only called by an authorised contracts.
    */
    function mintFor(address user, uint256 amount) external onlyAuthorised nonReentrant {
      if (tokenCapSet) require(tradableBlub.totalSupply() + amount <= MAX_SUPPLY, "You try to mint more than max supply");
      tradableBlub._authorisedMint(user, amount);
    }

    /**
    * @dev Function to claim tokens from the tax accumulated pot. Can be only called by an authorised contracts.
    */
    function claimBlubTax(address user, uint256 amount) public onlyAuthorised nonReentrant {
      require(activeTaxCollectedAmount >= amount, "Insufficiend tax balance");

      activeTaxCollectedAmount -= amount;
      depositedAmount[user] += amount;
      taxesDistributed += amount;

      emit ClaimTax(
        _msgSender(),
        user,
        amount
      );
    }

    /**
    * @dev Function returns maxSupply set by admin. By default returns error (Max supply is not set).
    */
    function getMaxSupply() public view returns (uint256) {
      require(tokenCapSet, "Max supply is not set");
      return MAX_SUPPLY;
    }

    /*
      ADMIN FUNCTIONS
    */

    /**
    * @dev Function allows admin to set total supply of Blub token.
    */
    function setTokenCap(uint256 newTokenCap) public onlyOwner {
      require(tradableBlub.totalSupply() < newTokenCap, "Value is smaller than the number of existing tokens");
      require(!tokenCapSet, "Token cap has been already set");

      MAX_SUPPLY = newTokenCap;
    }

    /**
    * @dev Function stops any further minting of Blub.
    */
    function lockTokenCapForever(bool _lock) public onlyOwner {
      require(!tokenCapSet, "Token cap has been locked");
      tokenCapSet = _lock;
    }

    /**
    * @dev Function allows admin add authorised address. The function also logs what addresses were authorised for transparancy.
    */
    function authorise(address addressToAuth) public onlyOwner {
      _isAuthorised[addressToAuth] = true;
      authorisedLog.push(addressToAuth);
    }

    /**
    * @dev Function allows admin add unauthorised address.
    */
    function unauthorise(address addressToUnAuth) public onlyOwner {
      _isAuthorised[addressToUnAuth] = false;
    }

    /**
    * @dev Function allows admin update the address of staking address.
    */
    function changeBlubSourceContract(address _source) public onlyOwner {
      BlubSource = IBlubSource(_source);
      authorise(_source);
    }

    /**
    * @dev Function allows admin update the address of staking address.
    */
    function changeTradableBlubContract(address _newTradableBlub) public onlyOwner {
      tradableBlub = ITradableBlub(_newTradableBlub);
      authorise(_newTradableBlub);
    }

    /**
    * @dev Function allows admin to update limit of tax on withdraw.
    */
    function updateWithdrawTaxAmount(uint256 _taxAmount) public onlyOwner {
      require(_taxAmount < MAX_TAX_VALUE, "Wrong value passed");
      withdrawTaxAmount = _taxAmount;
    }

    /**
    * @dev Function allows admin to update tax amount on spend.
    */
    function updateSpendTaxAmount(uint256 _taxAmount) public onlyOwner {
      require(_taxAmount < MAX_TAX_VALUE, "Wrong value passed");
      spendTaxAmount = _taxAmount;
    }

    /**
    * @dev Function allows admin to stop tax collection on withdraw.
    */
    function stopTaxCollectionOnWithdraw(bool _stop) public onlyOwner {
      withdrawTaxCollectionStopped = _stop;
    }

    /**
    * @dev Function allows admin to stop tax collection on spend.
    */
    function stopTaxCollectionOnSpend(bool _stop) public onlyOwner {
      spendTaxCollectionStopped = _stop;
    }

    /**
    * @dev Function allows admin to pause all in game Blub transfactions.
    */
    function pauseGameBlub(bool _pause) public onlyOwner {
      isPaused = _pause;
    }

    /**
    * @dev Function allows admin to pause in game Blub transfers.
    */
    function pauseTransfers(bool _pause) public onlyOwner {
      isTransferPaused = _pause;
    }

    /**
    * @dev Function allows admin to pause in game Blub withdraw.
    */
    function pauseWithdraw(bool _pause) public onlyOwner {
      isWithdrawPaused = _pause;
    }

    /**
    * @dev Function allows admin to pause in game Blub deposit.
    */
    function pauseDeposits(bool _pause) public onlyOwner {
      isDepositPaused = _pause;
    }

    /**
    * @dev Function allows admin to withdraw ETH accidentally dropped to the contract.
    */
    function rescue() external onlyOwner {
      payable(owner()).transfer(address(this).balance);
    }
}