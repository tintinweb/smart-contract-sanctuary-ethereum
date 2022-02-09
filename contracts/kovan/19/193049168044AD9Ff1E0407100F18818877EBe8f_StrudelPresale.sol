/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

contract StrudelPresale is ReentrancyGuard, Context, Ownable {

    /* ======== VARIABLES ======== */

    IERC20 public token;

    address payable public daoAddress;

    uint256 public rate;
    uint256 public ftmRaised;
    uint256 public endICO;
    uint256 public rewardTokenCount;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public availableTokensICO;
    uint256 public boughtTokensICO;
    uint256 public maxTokensICO;

    /* ======== STRUCTS ======== */

    struct Distributed {
        address wallet;
        uint256 amount;
    }

    /* ======== MAPPINGS ======== */

    mapping(address => Distributed) distributed;

    /* ======== EVENTS ======== */

    event TokensPurchased(address indexed _beneficiary, address indexed _daoAddress, uint256 _amount);
    event StartICO(uint256 _block);
    event EndICO(uint256 _block);
    event TokenAddress(address token);
    event WithdrawLeftovers(address _user, uint256 _amount);
    event WithdrawRewards(address _user, uint256 _amount);
    event DistrubutedAmount(address _user, uint256 _amount);
    event MinPurchase(uint256 _amount);
    event MaxPurchase(uint256 _amount);
    event MaxTokensICO(uint256 _amount);
    event Rate(uint256 _amount);
    event AvailableTokensICO(uint256 _amount);
    event DaoAddress(address payable _amount);
    event RewardTokenCount(uint256 _amount);
    event ForwardFunds(address _user, uint256 _amount);

    /* ======== MODIFIERS ======== */

    modifier icoActive() {
        require(endICO > 0 && block.number < endICO && availableTokensICO > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.number, 'ICO is active');
        _;
    }

    /* ======== INITIALIZATION ======== */

    constructor (
        IERC20 _token,
        address payable _daoAddress, 
        uint256 _availableTokensICO, 
        uint256 _rewardTokenCount, 
        uint256 _minPurchase, 
        uint256 _maxPurchase
    ) public {
        require(_daoAddress != address(0), "Pre-Sale: wallet is the zero address");
        require(address(_token) != address(0), "Pre-Sale: Token is the zero address");

        daoAddress = _daoAddress;
        availableTokensICO = _availableTokensICO;
        maxTokensICO = _availableTokensICO;
        rewardTokenCount = _rewardTokenCount;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        endICO = block.number + 864000; // 30 Days
        rate = 10 ** 9; // 1 (1000000000, the reason the rate is 10 ** 9 is because the token were going to use has 9 decimals) 
        token = _token;

        emit Rate(rate);
        emit EndICO(endICO);
        emit MaxPurchase(_maxPurchase);
        emit MinPurchase(_minPurchase);
        emit AvailableTokensICO(_availableTokensICO);
        emit MaxTokensICO(maxTokensICO);
        emit DaoAddress(daoAddress);
    }

     
    /* ======== PRESALE INITIALIZATION ======== */

    /**
    * @notice Start the presale. The owner of the contract can call this function when the ico is not active
    * @param _endICO the blocknumber when the ico should end
    * @param _minPurchase the minimum purchase to buy tokens
    */
    function startICOSale(uint256 _endICO, uint256 _minPurchase, uint256 _maxPurchase, uint256 _availableTokensICO) external onlyOwner icoNotActive() {
        require(_endICO != 0, 'Pre-Sale: The duration should be > 0');
        require(_availableTokensICO > 0, 'Pre-Sale: The available tokens should be > 0');
        require(_maxPurchase > 0, 'Pre-Sale: The max purchase should be > 0');

        endICO = _endICO;
        minPurchase = _minPurchase;
        maxPurchase = _maxPurchase;
        availableTokensICO = _availableTokensICO;

        emit EndICO(_endICO);
        emit MinPurchase(_minPurchase);
        emit MaxPurchase(_maxPurchase);
        emit AvailableTokensICO(_availableTokensICO);
        emit TokenAddress(address(token));
    }
    
    /**
    * @notice Set the new end ICO, when setting this to 0 the ico will be done
    * @param _endICO The end ico block
    */
    function endICOSale(uint256 _endICO) external onlyOwner {
        endICO = _endICO;

        emit EndICO(_endICO);
    }
    
    /* ======== BUY TOKENS ======== */

    /**
    * @notice Buy tokens
    * @param _beneficiary The wallet that buys the tokens
    */
    function buyTokens(address _beneficiary) external nonReentrant icoActive payable {
        require(_beneficiary != address(0), "Pre-Sale: Beneficiary is the zero address");

        uint256 ftmPurchaseInWei = msg.value;
        uint256 tokensPurchase = getTokenAmount(ftmPurchaseInWei);
        _validatePurchase(ftmPurchaseInWei, tokensPurchase, _beneficiary);

        // Amount of FTM that has been raised
        ftmRaised = ftmRaised + ftmPurchaseInWei;

        // Add person to distrubuted map and tokens bought
        distributed[_beneficiary].wallet = _beneficiary;
        distributed[_beneficiary].amount += tokensPurchase;
        availableTokensICO = availableTokensICO - tokensPurchase;
        boughtTokensICO += tokensPurchase;
        
        // Send the funds to the daoAddress
        daoAddress.transfer(msg.value);

        emit TokensPurchased(_beneficiary, daoAddress, tokensPurchase);
    }

    /* ======== SETTERS ======== */

    /**
    * @notice Set Token Address
    * @param _token The token address the presale is about
    */
    function setToken(IERC20 _token) external onlyOwner {
        require(address(token) != address(0), "Pre-Sale: Token is the zero address");
        token = _token;

        emit TokenAddress(address(token));
    }

    /**
    * @notice If something goes wrong you can still set the persons distrubited amount. EMERGENCY ONLY!
    * @param _wallet The distributed address where the amount is going to be changed
    * @param _amountInGwei The amount the user can claim after the ico has been ended
    */
    function setDistributedAmount(address _wallet, uint256 _amountInGwei) external onlyOwner {
         distributed[_wallet].amount = _amountInGwei;

         emit DistrubutedAmount(_wallet, _amountInGwei);
    }

    /**
    * @notice Sets the new rate
    * @param _rate The rate in (Gwei)
    */
    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;

        emit Rate(rate);
    }
    
    /**
    * @notice Sets the available tokens
    * @param _availableTokensICO the available tokens in gwei
    */
    function setAvailableTokensICO(uint256 _availableTokensICO) public onlyOwner {
        availableTokensICO = _availableTokensICO;

        emit AvailableTokensICO(_availableTokensICO);
    }
    
    /**
    * @notice Sets the new receiver of the funds
    * @param _daoAddress The address that will receive the presale funds
    */
    function setDaoAddress(address payable _daoAddress) external onlyOwner {
        require(_daoAddress != address(0), "Pre-Sale: wallet is the zero address");
        daoAddress = _daoAddress;
        
        emit DaoAddress(daoAddress);
    }
    
    /**
    * @notice Sets the new min purchase 
    * @param _minPurchase The new min purhcase in (Gwei)
    */
    function setMinPurchase(uint256 _minPurchase) external onlyOwner {
        minPurchase = _minPurchase;

        emit MinPurchase(_minPurchase);
    }

    /**
    * @notice Sets the new max purchase 
    * @param _maxPurchase The new max purhcase in (Gwei)
    */
    function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
        maxPurchase = _maxPurchase;

        emit MaxPurchase(_maxPurchase);
    }

    /**
    * @notice Sets the reward token count
    * @param _rewardTokenCount The amount per token
    */
    function setRewardTokenCount(uint256 _rewardTokenCount) external onlyOwner {
        rewardTokenCount = _rewardTokenCount;
        
        emit RewardTokenCount(rewardTokenCount);
    }

    /* ======== GETTERS ======== */

    /**
    * @notice Returns the tokenamount based on the rewardTokenCount and the rate
    * @param _weiAmount The amount of tokens in wei
    */
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
        return (_weiAmount * rewardTokenCount) / rate;
    }

    /**
    * @notice Returns the amount of tokens in the contract
    */
    function getTokensInContract() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
    * @notice returns the amount the user can withdraw after ico has ended
    * @param _beneficiary the wallet address for distributed amount
    */
    function withdrawalAmount(address _beneficiary) public view returns(uint256 amount) {
        return distributed[_beneficiary].amount;
    }

    /* ======== CALLABLE FUNCTIONS ======== */

    /**
    * @notice If the ico is not active anymore, the owner can withdraw the leftovers (if there is any)
    */
    function withdrawLeftoversToken() external icoNotActive onlyOwner {
        require(token.balanceOf(address(this)) > 0, 'Pre-Sale: Their is no tokens to withdraw');
        token.approve(address(this), token.balanceOf(address(this)));
        token.transfer(_msgSender(), token.balanceOf(address(this)));

        emit WithdrawLeftovers(_msgSender(), token.balanceOf(address(this)));
    }

    /**
    * @notice users can withdraw only when ico is ended and amount is not equal to 0
    */
    function withdrawBoughtTokens() external icoNotActive() {
        require(withdrawalAmount(_msgSender()) != 0, "Pre-Sale: Haven't bought any tokens");
        require(withdrawalAmount(_msgSender()) <= getTokensInContract(), "Pre-Sale: Not enough tokens in contract to withdraw from");

        token.transfer(_msgSender(), withdrawalAmount(_msgSender()));

        distributed[_msgSender()].amount = 0;

        emit WithdrawRewards(_msgSender(), withdrawalAmount(_msgSender()));
    }

    /* ======== INTERAL FUNCTIONS ======== */
    function _validatePurchase(uint256 _ftmPurchaseInWei, uint256 _tokensPurchase, address _beneficiary) internal {
        require(_ftmPurchaseInWei >= minPurchase, 'Pre-Sale: Have to send at least: minPurchase');
        require(_ftmPurchaseInWei <= maxPurchase, 'Pre-Sale: Have to send less than: maxPurchase');
        require(availableTokensICO != 0, "Pre-Sale: No available tokens left");
        require(_tokensPurchase != 0, "Pre-Sale: Value is 0");
        require(_tokensPurchase <= availableTokensICO, "Pre-Sale: No tokens left to buy");
        require(availableTokensICO - _tokensPurchase != 0, "Pre-Sale: Purchase amount is to high");
        require((distributed[_beneficiary].amount + _tokensPurchase) <= maxPurchase, 'Pre-Sale: Max purchase has been reached');
    }
}