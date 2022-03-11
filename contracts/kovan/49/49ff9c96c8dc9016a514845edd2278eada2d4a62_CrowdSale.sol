/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol



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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: sale.sol


pragma solidity ^0.8.10;


  /*
  *@title Croud Sale Contract
  *@author Jay singh dhakd
  *@notice this contract does sale JayToken for USDT, USDC, Ethers
  *@custom:experimental This is an experimental contract.
  */
contract CrowdSale is ReentrancyGuard {
   IERC20 USDT = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138);
   IERC20 USDC = IERC20(0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8);
   IERC20 JayToken = IERC20(0xf8e81D47203A594245E36C48e151709F0C19fBe8);
   uint256 ratePertokenUSDT; 
   uint256 ratePertokenUSDC;
   uint256 ratePertokenETH;
   bool saleStopped;
   uint256 startTime;
   uint256 stopTime;
   uint256 purchaseLimit;
   address owner;
   mapping(address => uint256) purchases;

   event TokenTranfer(address indexed from, address indexed to, uint256 amount);
   event EtherTransfer(address indexed from, address indexed to, uint256 amount);
   
   /*
   * @notice provides initial arguments for token swap rates and purchase rate of Jaytoken per ether and sets purchase limit 
   * and  owner as the msg sender.
   * @param jayToken rate per USDT , USDC , ETH , start time and stop time of contract with respect to block stamp time
   * purchase limit of Jay tokens per purchaser.  
   */
   constructor(uint256  _ratePertokenUSDT, uint256 _ratePertokenUSDC, uint256 _ratePertokenETH, uint256 _startTime, uint256 _stopTime, uint256 _purchaseLimit ){
      ratePertokenUSDT = _ratePertokenUSDT;
      ratePertokenUSDC = _ratePertokenUSDC;
      ratePertokenETH = _ratePertokenETH;
      startTime = block.timestamp + _startTime* 1 minutes;
      if(!(_stopTime == 0))stopTime = block.timestamp + _stopTime* 1 minutes;
      purchaseLimit = _purchaseLimit;
      owner = msg.sender;
   }

   /*
   * @notice checks if the message sender is the owner
   */
   modifier onlyOwner(){
      require(msg.sender == owner, "onlyOwner: not authorised for the call");
      _;
   }

   /*
   * @notice checks if sale is stopped by the owner
   */
   modifier _checkSale(){
      require(!saleStopped,"_checkSale: sale has stopped");
      _;
   }

   /*
   * @notice checks if the sale has started and ended 
   */
   modifier _checkTime(){
      require( startTime <= block.timestamp , "_checkTime: Sale has not started");
      if(stopTime != 0) require(block.timestamp <= stopTime, "_checkTime:Sale time expired sale has stopped");
      _;
   }

   /*
   * @notice checks if the purchaser has bought his share of Jaytokens With respect to purchase limit 
   *  and checks if the amount of token requested to be purchased is less than the limit
   * @params puchaser address and amout of token requested 
   */
   modifier _checkLimit(address purchaser, uint256 amount){
      require( purchases[purchaser] < purchaseLimit, "_checkLimit : Purchasing limit reached "); 
      require(amount <= (purchaseLimit - purchases[purchaser]), "_checkLimit: amount more than purchase Limit ");
      _;   
   }
 
   /*
   * @notice checks if the spending allowance granted by the purchaser is enough to buy requested jaytokens
   * @params token for which the allowance is made , purchaser address , cost to purchase the jays token
   */
   function _checkAllowance(IERC20 token, address purchaser,  uint256 cost) internal {
     require(token.allowance(purchaser, address(this)) >= cost,"_checkAllowance : spending allowance less than amount");
   }
 
   /*
   * @notice to purchase the jaytoken with USDT Tokens 
   * @params purchaser address and amount of tokens requested
   */ 
   function purchaseWithUSDT(address purchaser, uint256 amount) external _checkSale() _checkTime() _checkLimit(purchaser,amount){
      _checkAllowance(USDT, purchaser, _getCost(amount, ratePertokenUSDT));
      bool sent  =  USDT.transferFrom(purchaser, address(this), _getCost(amount, ratePertokenUSDT) );
      require(sent, "purchaseWithUSDT : tokenTransfer failed");
      _tranferToken(purchaser, amount);
   }
   
   /*
   * @notice to purchase the jaytoken with USDC Tokens
   * @params purchaser address and amount of tokens requested
   */
   function purchaseWithUSDC(address purchaser, uint256 amount) external _checkSale() _checkTime() _checkLimit(purchaser,amount){
      _checkAllowance(USDC, purchaser, _getCost(amount, ratePertokenUSDC));
      bool sent  =  USDC.transferFrom(purchaser, address(this), _getCost(amount, ratePertokenUSDC) );
      require(sent, "purchaseWithUSDC : tokenTransfer failed");
      _tranferToken(purchaser, amount);
   }

   /*
   * @notice gives the cost of pruchase of "amount" of jayToken with respected to the rate of token purchase provided 
   * @params amount of jays token want to puchase and token purchase rate of token sent to buy them
   * @returns the cost in sent token 
   */
   function _getCost(uint amount,uint tokenPurchaseRate) internal returns(uint256){
      return (amount/tokenPurchaseRate);
   }

   /*
   * @notice transfers token amount of jayToken purchase to the purchaser account and add to it purchses 
   *  emits token transfer event
   * @params address o the purchaser and the amount of jayTokens purchased 
   */
   function _tranferToken(address purchaser, uint amount) internal {
      bool sent  = JayToken.transferFrom(owner, purchaser, amount);
      require(sent, "_tranferToken: token tranfer to purchaser failed");
      purchases[purchaser] += amount;
      emit TokenTranfer(owner,purchaser,amount);
   }

   /*
   * @notice to purchase jaysToken with ethers  
   * @params purchaser address and amount of jaytoken to purchase
   */
   function purchaseWithETH(address purchaser, uint256 amount) external payable _checkSale() _checkTime() _checkLimit(purchaser,amount) {
      require( (msg.value/10**18) >= _getCost(amount,ratePertokenETH), "purchaseWithETH: ether sent less than the required fee");
      uint256 remaningAmount = msg.value - _getCost(amount,ratePertokenETH)*(10**18);
      if(remaningAmount > 0) sendRemainingEther(purchaser, remaningAmount);
      _tranferToken(purchaser, amount);
   }

   /*
   * @notice send the remaining ether back to the purchasers account emits EtherTransdfer event 
   * @params purchaser address and the amount to tranfer back 
   */
   function sendRemainingEther(address  purchaser, uint256 remaningAmount) internal nonReentrant(){
      uint256 balance = address(this).balance;
      payable(purchaser).transfer(remaningAmount);
      require(address(this).balance == (balance - remaningAmount), "sendRemainingEther: faulty transaction");
      emit EtherTransfer(address(this),purchaser,remaningAmount);
   }

   /*
   * @notice gets the rate per token in USDC tokens 
   */ 
   function getRatePerTokenUSDC() external returns(uint256){
      return ratePertokenUSDC;
   }

   /*
   * @notice gets the rate per token in USDT tokens 
   */
   function getRatePerTokenUSDT() external returns(uint256){
      return ratePertokenUSDT;
   }

   /*
   * @notice gets the rate per token in ethers
   */
   function getRatePerTokenETH() external returns(uint256){
      return ratePertokenETH;
   } 

   /*
   * @notice sets the rate per token in USDC tokens 
   */
   function setRatePerTokenUSDC(uint256 _ratePertokenUSDC ) external onlyOwner(){
      ratePertokenUSDC = _ratePertokenUSDC;
   }
 
   /*
   * @notice sets the rate per token in USDT tokens 
   */
   function setRatePerTokenUSDT(uint256 _ratePertokenUSDT ) external onlyOwner(){
      ratePertokenUSDT = _ratePertokenUSDT;
   }

   /*
   * @notice sets the rate per token in Ethers
   */
   function setRatePerTokenETH(uint256 _ratePertokenETH ) external onlyOwner(){
      ratePertokenETH = _ratePertokenETH;
   }

   /*
   * @notice gets the start time of sale 
   */
   function getStartTime() external returns(uint256){
      return startTime;
   }
   
   /*
   * @notice gets the stop time of the contract 
   */
   function getStopTime() external returns(uint256){
      return stopTime;
   }

   /*
   * @notice gets the purchase limit for the purchser 
   * @params purchaser address  
   */
   function getPurchaseLimit(address purchaser) external returns(uint256){
      return purchaseLimit -purchases[purchaser];
   }

   /*
   * @notice stops the sale 
   */
   function stopSale() external onlyOwner(){
      saleStopped = true;
   }

   /*
   * @notice restart the sale but sale will not restart after the stop time 
   */
   function startSale() external onlyOwner(){
      saleStopped = false;
   }

   /*
   * @notice with draw the Ether on this contract account after the sale is stopped
   */
   function withDrawal() external onlyOwner(){
      require(saleStopped || block.timestamp >= stopTime, "withDrawal: sale has not stopped cant withdraw ");
      uint256 balance = address(this).balance;
      payable(owner).transfer(balance);
      require(address(this).balance == 0, "withDrawal: faulty transaction");
   }
}