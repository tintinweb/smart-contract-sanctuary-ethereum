/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: Apache-2.0
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: contracts/Presale ETH/Presale.sol








pragma solidity ^0.8.0;


contract Presale is Pausable, Ownable {
    event BuyEvent(address indexed to, uint256 amount);
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);

    struct Terms {
        uint256 initialprice; //1e6
        uint256 startTime; // presale start time
        uint256 period; // each round period
        uint hikeRate; // each round hike
        uint256 roundCount;
        uint256 ethPrice; //1e6
    }

    // round infos
    uint public roundNum;
    Terms public terms;

    //checks when the presale is ended
    bool private presaleEnded;

     // Checks if claming have started
    bool public claimingStarted;

    // total amount of tokens sold
    uint public totalTokensSold;

    //To check amount of usdRaised
    uint public usdRaised;

    //To check price value of each purchase
    uint public usdPrice;
    
    //maps and stores each address with amount to claim
    mapping(address => uint) public tokenClaims;

    //check if a user have claimed their purchased token
    mapping(address => bool) public hasClaimed;

    // addresses
    address public tokenAddress;
    address public usdtAddress;

    // payment Address
    address public paymentAddress;

     // to set the targetted amount
    uint public targetAmount;


    // config

    function setInitAddresses(
        address _tokenAddress,
        address _usdtAddress
    ) external onlyOwner {
        tokenAddress = _tokenAddress;
        usdtAddress = _usdtAddress;
    }

    function setTerms(
        uint initialprice,
        uint start,
        uint period,
        uint hikeRate,
        uint roundCount,
        uint ethPrice
    ) external onlyOwner {
        terms.initialprice = initialprice;
        terms.startTime = start + block.timestamp;
        terms.period = period;
        terms.hikeRate = hikeRate;
        terms.roundCount = roundCount;
        terms.ethPrice = ethPrice;
    }

    function changePaymentWallet(address _paymentAddress) external onlyOwner {
        paymentAddress = _paymentAddress;
    }

     function incrementCurrentStep(uint _targetAmount) external onlyOwner {
        targetAmount = _targetAmount;
    }

    function setETHPrice(uint _ethPrice) external onlyOwner {
        terms.ethPrice = _ethPrice;
    }

    // presale
    function checkTerm() internal view returns (bool) {
        return
            block.timestamp > terms.startTime + terms.period * terms.roundCount;
    }

    function startClaim() external onlyOwner {
    require(checkTerm(), "Presale not ended yet");
    require(IERC20(tokenAddress).balanceOf(address(this)) > 0, "No tokens in contract address");
    claimingStarted = true;
    }


    //gets the current price depending on the round
    function getPrice() public view returns (uint) {
        return
            terms.initialprice +
            ((block.timestamp - terms.startTime) / terms.period) *
            terms.hikeRate;
    }

    //Calculates the amount of token to get based on amount of ETH
    function getAmount(uint amount) public view returns (uint) {
    return ((amount * terms.ethPrice) / getPrice());
    }

    //Calculates the amount of token to get based on amount of USDT
   function getAmountWithUSDT(uint amount) public view returns (uint) {
    return (amount * 1e6) / getPrice();
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    function buyWithETH() whenNotPaused external payable {
    require(!checkTerm(), "Presale ended");
    uint tokensToTransfer = getAmount(msg.value);
    tokenClaims[msg.sender] += tokensToTransfer;
    totalTokensSold += tokensToTransfer;
    usdPrice = (msg.value * terms.ethPrice);
    usdRaised += usdPrice; 
    emit BuyEvent(msg.sender, tokensToTransfer);
     _transferETH();
    }

    function buyWithUSDT(uint amount) whenNotPaused external {
   require(!checkTerm(), "Presale ended");
    IERC20(usdtAddress).transferFrom(msg.sender, address(this), amount);
    uint tokensToTransfer = getAmountWithUSDT(amount);
    tokenClaims[msg.sender] += tokensToTransfer;
    totalTokensSold += tokensToTransfer;
    usdPrice = (amount * 1e6);
    usdRaised += usdPrice;
    emit BuyEvent(msg.sender, tokensToTransfer);
    _transferUSDT(amount);
    }


    function _transferETH() internal {
    uint contractBalance = address(this).balance;
    if (contractBalance > 0) {
    payable(paymentAddress).transfer(contractBalance);
    }
    }

    function _transferUSDT(uint amount) internal {
    IERC20(usdtAddress).transfer(paymentAddress, amount);
    }

    function getTotalTokensSold() external view returns (uint) {
    uint sold = totalTokensSold;
    return sold;
    }

    function getUsdRaised() external view returns (uint) {
    uint soldAmount = usdRaised;
    return soldAmount;
    }

    function claimTokens() whenNotPaused external returns (bool) {
    require(checkTerm(), "Presale not ended");
    require(claimingStarted, "Claiming not started yet");
    require(tokenClaims[msg.sender] > 0, "No tokens to claim");
    uint tokensToClaim = tokenClaims[msg.sender];
    delete tokenClaims[msg.sender];
    IERC20(tokenAddress).transfer(msg.sender, tokensToClaim);
    hasClaimed[msg.sender] = true;
    emit TokensClaimed(msg.sender, tokensToClaim, block.timestamp);
    return true;
    }

    function endPresale() external onlyOwner {
    require(!presaleEnded, "Presale already ended");
    require(!checkTerm(), "Presale not ended yet");
    presaleEnded = true;
    }


     // get balance that a user have and is supposed to claim
    function getTokenClaimBalance(address user) external view returns (uint) {
    return tokenClaims[user];
    }

    // claim token that unexpectedly send to contract
    function claimToken(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(owner(), _amount);
    }

    // claim ETH that unexpectedly send to contract
    function claimETH(uint256 amount) external onlyOwner {
        payable(owner()).transfer(amount);
    }

  

    fallback() external payable {}

    receive() external payable {}
}