/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

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

    function decimals() external view returns(uint8);

}


contract YoloCabsICO is ReentrancyGuard, Context, Ownable {

    mapping (address => uint256) private _contributions;
    mapping (address => uint256) public totalContributions;
    mapping (address => uint256) public claimed;

    IERC20 public _token;
    uint256 private _tokenDecimals;
    uint256 public _rate;
    uint256 public _weiRaised;
    uint256 public endICO;
    uint256 public minPurchase;
    uint256 public maxPurchasePer;
    uint256 public hardcap;
    uint256 public purchasedTokens;
    uint256 public bnbCollected;
    uint256 timeToWait;
    

    event TokensPurchased(address indexed  purchaser, uint256 value, uint256 amount);
    event TokensClaimed(address indexed  user, uint256 value, uint256 amount);

    /*
        * Constructor Arguments taken for the Contract Deployment :
        * rate - Total number of token recieved for 1 ETH
        * token - Token address of the sale
        * _timeToWait - UNIX Timestamp of the claim date of the token
    */
    constructor (uint256 rate, IERC20 token)  {
        require(rate > 0, "Pre-Sale: rate is 0");
        require(address(token) != address(0), "Pre-Sale: token is the zero address");
        
        _rate = rate;
        _token = token;
        _tokenDecimals = 18 - _token.decimals();
    }
    
 
    
    /*
        * startICO Function to Start the ICO, Following Parameters should be added before the launch :
        * Only Owner Can Call the Function
        * endDate - UNIX Timestamp for the ICO End Date
        * _minPurchase - Minimum Purchase with respect to ETH in WEI 
        * _maxPurchase - Maximum Purchase with respect to ETH in WEI 
        * _hardcap - Total token the sale want to raise with resepcet to ETH in WEI
    */
    function startICO(uint256 endDate, uint256 _minPurchase,uint256 _maxPurchase,  uint256 _hardcap, uint256 _timeToWait) external onlyOwner icoNotActive() {
        require(endDate > block.timestamp, 'End Date shoild be greater than Current Time');
        require(_timeToWait > endDate, 'Claim Date Should be Greater than End Date');
        require(_timeToWait < endDate + 120 days, 'Claim Date should be less than 4 months after Sale End');
        require(_minPurchase<_maxPurchase, 'Min Purchase should be less than Max Purchase');
        require(_hardcap>0,'Hardcap Should not be set to 0');

        endICO = endDate; 
        minPurchase = _minPurchase;
        maxPurchasePer = _maxPurchase;
        hardcap = _hardcap;
        _weiRaised = 0;
        timeToWait = _timeToWait;
    }


    /*
        * stopICO Function to Stop the ICO :
        * Only Owner can call the function
        * This function will stop the ICO
    */
    function stopICO() external onlyOwner icoActive(){
        endICO = 0;
    }
    
    
    /*
        * buyToken Function is used to buy tokens using ETH :
        * All User can call the function
        * This function will buy the token using bnb
        * ETH is passed as a payable option in this function
    */
    function buyTokens() external payable nonReentrant icoActive{

        uint256 weiAmount = msg.value;
        payable(owner()).transfer(weiAmount);
        uint256 tokens = _getTokenAmount(weiAmount);
        _preValidatePurchase(_msgSender(), weiAmount);
        _weiRaised = _weiRaised + weiAmount;
        bnbCollected = bnbCollected + weiAmount;
        purchasedTokens += tokens;
        totalContributions[_msgSender()] = totalContributions[_msgSender()] + weiAmount;
        _contributions[_msgSender()] = _contributions[_msgSender()] + weiAmount;

        emit TokensPurchased(_msgSender(), weiAmount, tokens);
    }

    /*
        * _preValidatePurchase Function is internal function :
        * This function will check all the requirement for buying token
        * This is a internal function only called inside the contract
    */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(beneficiary != address(0), "Presale: beneficiary is the zero address");
        require(weiAmount != 0, "Presale: weiAmount is 0");
        require(weiAmount >= minPurchase, 'have to send at least: minPurchase');
        require(_weiRaised + weiAmount <= hardcap, "Exceeding hardcap");
        require(_contributions[beneficiary] + weiAmount <= maxPurchasePer, "can't buy more than: maxPurchase");
    }

    /*
        * claim Function is used to Claim tokens brought using ETH :
        * All User can call the function
        * This function can only be called after timeToWait time is reached
    */
    function claim() external nonReentrant{
        require(checkContribution(_msgSender()) > 0, "No tokens to claim");
        require(checkContribution(_msgSender()) <= IERC20(_token).balanceOf(address(this)), "No enough tokens in contract");
        require( block.timestamp > timeToWait, "You must wait until claim time / Launch time");
        
        uint256 amount = _contributions[_msgSender()];
        claimed[_msgSender()] = claimed[_msgSender()] + amount;
        uint256 tokenTransfer = _getTokenAmount(amount);
        _contributions[_msgSender()] = 0;

        require(IERC20(_token).transfer(_msgSender(), tokenTransfer));
        emit TokensClaimed(_msgSender(), amount, tokenTransfer);
    }

    /*
        * changeWaitTime Function is used to change wait time of token claim :
        * Only Owner can call the function
        * Owner cannot change wait time after the previous time is passed 
        * _timeToWait - New Time should be passed as UNIX timestamp
    */
    function changeWaitTime(uint256 _timeToWait) external onlyOwner icoNotActive() returns(bool){
        require(block.timestamp < timeToWait, "Cannot change wait time after claim time is passed");
        timeToWait =_timeToWait;
        return true;
    }

    /*
        * _getTokenAmount Function is a internal function :
        * This function will check how much token user will recieve for bnb sent
        * This is a internal function only called inside the contract
        * weiAmount - ETH Wei amount is passed as a parameter
    */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return (weiAmount * _rate)/10**_tokenDecimals;
    }


    /*
        * _forwardFunds Function is used to transfer ETH inside the contract :
        * Only Owner can call the function
        * amount - amount of ETH should be passed in wei
    */
    function _forwardFunds(uint256 amount) external onlyOwner {
        require(amount>0, 'Amount Should be greater than 0');
        payable(owner()).transfer(amount);
    }


    /*
        * checkContribution Function is used to check the amount of tokens brought by user :
        * All user can call the function to check their token brought
        * addr - User Address is passed as a input parameter
    */
    function checkContribution(address addr) public view returns(uint256){
        uint256 tokensBought = _getTokenAmount(_contributions[addr]);
        return (tokensBought);
    }


    /*
        * setRate Function is used to change rate of the token sale :
        * Only Owner can call the function
        * Owner cannot change rate once ICO is turned on
        * newRate - New rate of the token
    */
    function setRate(uint256 newRate) external onlyOwner icoNotActive{
        require(newRate>0,'New Rate Should not be 0');
        _rate = newRate;
    }
    
    /*
        * setMinPurchase Function is used to change Minimum ETH for buy  :
        * Only Owner can call the function
        * Owner cannot change value once ICO is turned on
        * value - New Min Token to Buy
    */
     function setMinPurchase(uint256 value) external onlyOwner icoNotActive{
        require(value < maxPurchasePer,'Min Puchase Should be less than Max Purchase');
        minPurchase = value;
    }

    /*
        * setMaxPurchase Function is used to change Maximum ETH for buy  :
        * Only Owner can call the function
        * Owner cannot change value once ICO is turned on
        * value - New Max Token to Buy
    */
    function setMaxPurchase(uint256 value) external onlyOwner icoNotActive{
        require(value > minPurchase ,'Max Puchase Should be greater than Min Purchase');
        maxPurchasePer = value;
    }

    /*
        * setHardcap Function is used to change Total Hardcap to be raised in the ICO  :
        * Only Owner can call the function
        * Owner cannot change value once ICO is turned on
        * value - New Hardcap of the token
    */
    function setHardcap(uint256 value) external onlyOwner icoNotActive{
        require(value>0,'Hardcap Should not be set to 0');
        hardcap = value;
    }
    
    /*
        * takeTokens Function is used to remove any tokens inside the contract :
        * Only Owner can call the function
        * tokenAddress - Address of the which admin wants to remove 
        * amount - total amount the user wants to transfer
    */
    function takeTokens(IERC20 tokenAddress,uint256 amount) external onlyOwner returns(bool){
        IERC20 tokenERC = tokenAddress;
        uint256 tokenAmt = tokenERC.balanceOf(address(this));
        require(tokenAmt > amount, "ERC-20 balance is low in contract");
        tokenERC.transfer(owner(), amount);
        return true;
    }
    

    /*
        * icoActive is a modifier to indicate if the ICO is Active
    */
    modifier icoActive() {
        require(endICO > 0 && block.timestamp < endICO, "ICO must be active");
        _;
    }
    
    /*
        * icoNotActive is a modifier to indicate if the ICO is Not Active
    */
    modifier icoNotActive() {
        require(endICO < block.timestamp, 'ICO should not be active');
        _;
    }

}