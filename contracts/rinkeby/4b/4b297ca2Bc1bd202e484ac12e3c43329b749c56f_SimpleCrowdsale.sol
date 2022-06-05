/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

// - Token Address - where the tokens are being taken
// - Presale Rate - N tokens per BNB (example : 1,000,000 tokens per BNB)
// - A Soft cap - goal to raise in BNB for the presale (example : 10 BNB)
// - A Hard cap - when the sale stop automatically if hit (example : 50 BNB)
// - a Min contribution in BNB for people buying the pre-sale (for ex 0.100)
// - a Max contribution in BNB for people buying the pre-sale (for ex 10)
// - A start time of the pre-sale (example : 2021-08-18 12:13:28 UTC)
// - Duration of Presale (in Days, example : 7 days)
// - Manual claim of tokens (people can manually claim their tokens)
// - Lock Days before claim is open (people have to wait n days, example : 30 days)
// - A defined admin address - Used to manage Ido contracts and receive raised tokens

// Written by blockchainguy.net






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
    
    function decimals() external view returns (uint);

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract SimpleCrowdsale is Ownable{
  using SafeMath for uint256;
  // The token address which is being sold
  address public token = 0x90425209214C405f7CaDEfda312DfB5C27872b93;
  
  //this means 500 per bnb
  uint256 public rate = 500000;
  
  uint256 public softcap = 50 ether;
  uint256 public hardcap = 100 ether;
  
  uint256 public min_buy_limit = 0.2 ether;
  uint256 public max_buy_limit = 2 ether;
  
  uint256 public sale_start_time = block.timestamp;
  uint256 public sale_end_time = 1655319600;
  uint256 public claim_time = 1655737200;

  // Amount of wei raised
  uint256 public weiRaised = 0;
  
  mapping (address => uint256) public _Deposits;
  mapping (address => uint256) public _DepositsTotalBNB;
  mapping(address => bool) private presaleList;

  bool public locked = true;

    constructor() {
        _owner = msg.sender;
    }
    
    function total_tokens() public view returns (uint256){
        return IERC20(token).balanceOf(address(this));
    }
    
    function lock() onlyOwner public {
        locked = true;
    }    
    
    function unlock() onlyOwner public {
        locked = false;
    }
    
    function get_back_all_tokens() onlyOwner public {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function get_wei_raised() public view returns (uint256){
        return weiRaised;
    }
    function get_back_tokens(uint256 amount) onlyOwner public {
        require(total_tokens() >= amount, "Not Enough Tokens");
        IERC20(token).transfer(msg.sender, amount);
    }

    function depositbnb() public payable{
        address _beneficiary = msg.sender;
        uint256 weiAmount = msg.value;
        require(!locked, "Sale is Locked");
        require(weiRaised <= hardcap, "Hardcap Reached");
        require(_beneficiary != address(0), "Beneficiary = address(0)");
        require(weiAmount >= min_buy_limit && weiAmount <= max_buy_limit ,"Make Transactions within the TX limits");
        require(block.timestamp >= sale_start_time, "Sale is not started");
        require(block.timestamp <= sale_end_time, "Sale Ended");
        require(isWhitelisted(msg.sender), "You are not allowed.");
        require(_DepositsTotalBNB[msg.sender].add(weiAmount) <= max_buy_limit, "Max Limit Reached");

        // calculate token amount to be created
        uint256 t_rate = _getTokenAmount(weiAmount, rate);

        //require(total_tokens() >= t_rate, "Contract Doesnot have enough tokens");
        
        _Deposits[_beneficiary] = _Deposits[_beneficiary].add(t_rate);  
        _DepositsTotalBNB[_beneficiary] = _DepositsTotalBNB[_beneficiary].add(weiAmount);

        //IERC20(token).transfer(_beneficiary, t_rate);
        weiRaised = weiRaised.add(weiAmount);
        payable(owner()).transfer(address(this).balance);
    }

      function claimTokens() public{
            uint256 deposited_amount = _Deposits[_msgSender()];
            require(block.timestamp > claim_time, "Cannot claim right now");
            require(deposited_amount > 0, "Claim amount is zero.");
            require(total_tokens() >= deposited_amount, "Contract Doesnot have enough tokens");   

            IERC20(token).transfer(_msgSender(), deposited_amount);
            _Deposits[_msgSender()] = 0;
    }

    function addPresaleList(address[] memory _wallets) public onlyOwner{
        for(uint i; i < _wallets.length; i++)
            presaleList[_wallets[i]] = true;
    }
    
    function isWhitelisted(address _sender) public view returns(bool){
        return presaleList[_sender];
    }
    function total_deposited_by_user(address _sender) public view returns(uint256){
        return _DepositsTotalBNB[_sender];
    }
    function tokens_for_user(address _sender) public view returns(uint256){
        return _Deposits[_sender];
    }
    function update_timings(uint256 t_sale_start_time, uint256 t_sale_end_time, uint256 t_claim_time) public onlyOwner{
        sale_start_time = t_sale_start_time;
        sale_end_time = t_sale_end_time;
        claim_time = t_claim_time;
    }
    function update_caps(uint256 t_soft_cap, uint256 t_hard_cap) public onlyOwner{
        softcap = t_soft_cap;
        hardcap = t_hard_cap;

    }
    function update_limits(uint256 t_min_limit, uint256 t_max_limit) public onlyOwner{
        min_buy_limit = t_min_limit;
        max_buy_limit = t_max_limit;

    }
    receive() external payable {
        depositbnb();
    }
    
    fallback() external payable {}
    

    function extractEther() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }
  
    function _getTokenAmount(uint256 _weiAmount, uint256 t_rate) public view returns (uint256){
        uint256 token_decimals = IERC20(token).decimals();
        
        //if token decimals are 10
        if(token_decimals == 10){
            _weiAmount = _weiAmount.div(100000000);
            return _weiAmount.mul(t_rate);
        }
        
        //if token decimals are 18
        _weiAmount = _weiAmount.div(1);
        return _weiAmount.mul(t_rate);
        
        //return _weiAmount.mul(rate) * 10**9;
      // return _weiAmount.mul(325) * 10**9;
    }
    
    function _calculate_TokenAmount(uint256 _weiAmount, uint256 t_rate, uint divide_amount) public pure returns (uint256){
        uint256 temp2 = _weiAmount.div(divide_amount);
        return temp2.mul(t_rate);
    }
    
    function update_rate(uint256 _rate) onlyOwner public {
        rate = _rate;
    }

    function update_token_Address(address _token) onlyOwner public {
        token = _token;
    }

    
}
// Written by blockchainguy.net