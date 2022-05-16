/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

pragma solidity 0.8.9;
// SPDX-License-Identifier: MIT


interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor ()  { }

  function _msgSender() internal view returns (address payable) {
    return (payable(msg.sender));
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor ()  {
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

contract TICO_TOKEN is Context, IBEP20, Ownable, Pausable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  bool public remainingTokenBurnt = false;



   // The tokens already used for the ICO buyers
   uint256 public tokensDistributedCrowdsale = 0;

   // The address of the crowdsale
   address public crowdsale;



   // The maximum amount of tokens sold in the crowdsale
   uint256 public limitCrowdsale = 150e24;

   /// @notice Only allows the execution of the function if it's comming from crowdsale
   modifier onlyCrowdsale() {
      require(msg.sender == crowdsale);
      _;
   }

   // When someone refunds tokens
   event RefundedTokens(address indexed user, uint256 tokens);

  constructor()  {
    _name = "Test Token";
    _symbol = "TST 1.0";
    _decimals = 18;
    _totalSupply = 10000000000 * 10 ** 18;
    _balances[msg.sender] = _totalSupply;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address) {
    return owner();
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8) {
    return _decimals;
  }

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory) {
    return _symbol;
  }

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory) {
    return _name;
  }

  /**
   * @dev See {BEP20-totalSupply}.
   */
  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev See {BEP20-transferFrom}.
   *
   * Emits an {Approval} event indicating the updated allowance. This is not
   * required by the EIP. See the note at the beginning of {BEP20};
   *
   * Requirements:
   * - `sender` and `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   * - the caller must have allowance for `sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  /**
   * @dev Atomically decreases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   * - `spender` must have allowance for the caller of at least
   * `subtractedValue`.
   */
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  

  /**
   * @dev Moves tokens `amount` from `sender` to `recipient`.
   *
   * This is internal function is equivalent to {transfer}, and can be used to
   * e.g. implement automatic token fees, slashing mechanisms, etc.
   *
   * Emits a {Transfer} event.
   *
   * Requirements:
   *
   * - `sender` cannot be the zero address.
   * - `recipient` cannot be the zero address.
   * - `sender` must have a balance of at least `amount`.
   */
  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * Emits a {Transfer} event with `from` set to the zero address.
   *
   * Requirements
   *
   * - `to` cannot be the zero address.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
   *
   * This is internal function is equivalent to `approve`, and can be used to
   * e.g. set automatic allowances for certain subsystems, etc.
   *
   * Emits an {Approval} event.
   *
   * Requirements:
   *
   * - `owner` cannot be the zero address.
   * - `spender` cannot be the zero address.
   */
  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
   * from the caller's allowance.
   *
   * See {_burn} and {_approve}.
   */
  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }

   /// @notice Function to set the crowdsale smart contract's address only by the owner of this token
   /// @param _crowdsale The address that will be used
   function setCrowdsaleAddress(address _crowdsale) external onlyOwner whenNotPaused {
      require(_crowdsale != address(0));

      crowdsale = _crowdsale;
   }


   /// @notice Distributes the ICO tokens. Only the crowdsale address can execute this
   /// @param _buyer The buyer address
   /// @param tokens The amount of tokens to send to that address
   function distributeICOTokens(address _buyer, uint tokens) external onlyCrowdsale whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0);

      // Check that the limit of 50M ICO tokens hasn't been met yet
      require(tokensDistributedCrowdsale < limitCrowdsale);
      require(tokensDistributedCrowdsale.add(tokens) <= limitCrowdsale);

      tokensDistributedCrowdsale = tokensDistributedCrowdsale.add(tokens);
      _balances[_buyer] = _balances[_buyer].add(tokens);
   }

   /// @notice Deletes the amount of tokens refunded from that buyer balance
   /// @param _buyer The buyer that wants the refund
   /// @param tokens The tokens to return
   function refundTokens(address _buyer, uint256 tokens) external onlyCrowdsale whenNotPaused {
      require(_buyer != address(0));
      require(tokens > 0);
      require(_balances[_buyer] >= tokens);

      _balances[_buyer] = _balances[_buyer].sub(tokens);
      emit RefundedTokens(_buyer, tokens);
   }

   /// @notice Burn the amount of tokens remaining after ICO ends
   function burnTokens() external onlyCrowdsale whenNotPaused {
      
      uint256 remainingICOToken = limitCrowdsale.sub(tokensDistributedCrowdsale);
      if(remainingICOToken > 0 && !remainingTokenBurnt) {
      remainingTokenBurnt = true;    
      limitCrowdsale = limitCrowdsale.sub(remainingICOToken);  
      _totalSupply = _totalSupply.sub(remainingICOToken);
      }
   }


}


contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  constructor (address _wallet) {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor)public onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() public onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    emit Closed();
    payable(wallet).transfer(address(this).balance);
  }

  function enableRefunds() public  onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    emit RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    payable(investor).transfer(depositedValue);
    emit Refunded(investor, depositedValue);
  }
}




/// 1. First you set the address of the wallet in the RefundVault contract that will store the deposit of ether
// 2. If the goal is reached, the state of the vault will change and the ether will be sent to the address
// 3. If the goal is not reached , the state of the vault will change to refunding and the users will be able to call claimRefund() to get their ether

/// @title Crowdsale contract to carry out an ICO with the TestToken
/// Crowdsales have a start and end timestamps, where investors can make
/// token purchases and the crowdsale will assign them tokens based
/// on a token per ETH rate. Funds collected are forwarded to a wallet
/// as they arrive.
contract Crowdsale is Pausable, Ownable {
   using SafeMath for uint256;

   // The token being sold
   TICO_TOKEN public token;

   string public stageNow = "NoSale";

   // The vault that will store the ether until the goal is reached
   RefundVault public vault;

  // uint256 public startTime = 1651763868;

  // uint256 public endTime = 1652694465;

   uint256 public startTime1 = 1652663669;

   uint256 public endTime1 = 1652818469;

   uint256 public startTime2 = 1652872469;

   uint256 public endTime2 = 1653045269;

   uint256 public startTime3 = 1653131669;

   uint256 public endTime3 = 1653131769;

   uint256 public startTime4 = 1653132869;

   uint256 public endTime4 = 1653133069;

   uint256 public startTime5 = 1653133569;

   uint256 public endTime5 = 1653133569;

   uint256 public startTime6 = 1653133569;

   uint256 public endTime6 = 1653133569;

   uint256 public startTime7 = 1653133569;

   uint256 public endTime7 = 1653133569;

   uint256 public startTime8 = 1653133569;

   uint256 public endTime8 = 1653133569;

   uint256 public startTime9 = 1653133569;

   uint256 public endTime9 = 1653133569;

   uint256 public startTime10 = 1653133569;

   uint256 public endTime10 = 1653133569;

   uint256 public startTime11 = 1653133569;

   uint256 public endTime11 = 1653133569;

   uint256 public startTime12 = 1653133569;

   uint256 public endTime12 = 1653133569;

   uint256 public startTime13 = 1653133569;

   uint256 public endTime13 = 1653133569;

   uint256 public startTime14 = 1653133569;

   uint256 public endTime14 = 1653133569;

   uint256 public startTime15 = 1653133569;

   uint256 public endTime15 = 1653133569;

   // The wallet that holds the Wei raised on the crowdsale
   address public wallet;

   // The wallet that holds the Wei raised on the crowdsale after soft cap reached
   address public walletB;

   // The rate of tokens per ether. Only applied for the first tier, the first
   // 10 million tokens sold
   uint256 public rate;

   uint256 public rateTier2;

   uint256 public rateTier3;

   uint256 public rateTier4;
   uint256 public rateTier5;
   uint256 public rateTier6;
   uint256 public rateTier7;
   uint256 public rateTier8;
   uint256 public rateTier9;
   uint256 public rateTier10;
   uint256 public rateTier11;
   uint256 public rateTier12;
   uint256 public rateTier13;
   uint256 public rateTier14;
   uint256 public rateTier15;


   // The maximum amount of wei for each tier
   uint256 public limitTier1 = 10e24;
   uint256 public limitTier2 = 10e24;
   uint256 public limitTier3 = 10e24;
   uint256 public limitTier4 = 10e24;
   uint256 public limitTier5 = 10e24;
   uint256 public limitTier6 = 10e24;
   uint256 public limitTier7 = 10e24;
   uint256 public limitTier8 = 10e24;
   uint256 public limitTier9 = 10e24;
   uint256 public limitTier10 = 10e24;
   uint256 public limitTier11 = 10e24;
   uint256 public limitTier12 = 10e24;
   uint256 public limitTier13 = 10e24;
   uint256 public limitTier14 = 10e24;
   uint256 public limitTier15 = 10e24;

   // The amount of wei raised
   uint256 public weiRaised = 0;

   // The amount of tokens raised
   uint256 public tokensRaised = 0;

   // You can only buy up to 150 M tokens during the ICO
   uint256 public  maxTokensRaised = 150e24;

   // The minimum amount of Wei you must pay to participate in the crowdsale
   uint256 public  minPurchase = 1 * 1e17; /** 0.1 BNB  **/

   // The max amount of Wei that you can pay to participate in the crowdsale
   uint256 public  maxPurchase = 25 * 1e18; /** 25 BNB  **/

   // Minimum amount of tokens to be raised. 7.5 million tokens which is the 15%
   // of the total of 50 million tokens sold in the crowdsale
   // 7.5e6 + 1e18
   uint256 public  minimumGoal = 5.33e24;

   // If the crowdsale wasn't successful, this will be true and users will be able
   // to claim the refund of their ether
   bool public isRefunding = false;

   // If the crowdsale has ended or not
   bool public isEnded = false;

   // The number of transactions
   uint256 public numberOfTransactions;

   // The gas price to buy tokens must be 50 gwei or below
   uint256 public limitGasPrice = 50000000000 wei;

   // How much each user paid for the crowdsale
   mapping(address => uint256) public crowdsaleBalances;

   // How many tokens each user got for the crowdsale
   mapping(address => uint256) public tokensBought;

   // To indicate who purchased what amount of tokens and who received what amount of wei
   event TokenPurchase(address indexed buyer, uint256 value, uint256 amountOfTokens);

   // Indicates if the crowdsale has ended
   event Finalized();

   // Only allow the execution of the function before the crowdsale starts
  /* modifier beforeStarting() {
      require(block.timestamp < startTime);
      _;
   }
   */

   /// @notice Constructor of the crowsale to set up the main variables and create a token
   /// @param _wallet The wallet address that stores the Wei raised
   /// @param _walletB The wallet address that stores the Wei raised after soft cap reached
   /// @param _tokenAddress The token used for the ICO
   constructor(
      address _wallet,
      address _walletB,
      address _tokenAddress,
      uint256 _startTime1,
      uint256 _endTime1
   )  {
      require(_wallet != address(0));
      require(_tokenAddress != address(0));
      require(_walletB != address(0));

      // If you send the start and end time on the constructor, the end must be larger
      if(_startTime1 > 0 && _endTime1 > 0)
         require(_startTime1 < _endTime1);

      wallet = _wallet;
      walletB = _walletB;
      token = TICO_TOKEN(_tokenAddress);
      vault = new RefundVault(_wallet);

      if(_startTime1 > 0)
         startTime1 = _startTime1;

      if(_endTime1 > 0)
         endTime1 = _endTime1;
   }

   /// @notice Fallback function to buy tokens
   fallback () external payable {
     // buyTokens();
     newBuyTokens();
   }

   /// @notice To buy tokens given an address
   function buyTokens() public payable whenNotPaused {
      require(validPurchase());

      uint256 tokens = 0;
      
      uint256 amountPaid = calculateExcessBalance();

      if(tokensRaised < limitTier1) {

         // Tier 1
         tokens = amountPaid.mul(rate);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier1)
            tokens = calculateExcessTokens(amountPaid, limitTier1, 1, rate);
      } else if(tokensRaised >= limitTier1 && tokensRaised < limitTier2) {

         // Tier 2
         tokens = amountPaid.mul(rateTier2);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier2)
            tokens = calculateExcessTokens(amountPaid, limitTier2, 2, rateTier2);
      } else if(tokensRaised >= limitTier2 && tokensRaised < limitTier3) {

         // Tier 3
         tokens = amountPaid.mul(rateTier3);

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier3)
            tokens = calculateExcessTokens(amountPaid, limitTier3, 3, rateTier3);
      } else if(tokensRaised >= limitTier3) {

         // Tier 4
         tokens = amountPaid.mul(rateTier4);
      }

      weiRaised = weiRaised.add(amountPaid);
      uint256 tokensRaisedBeforeThisTransaction = tokensRaised;
      tokensRaised = tokensRaised.add(tokens);
      token.distributeICOTokens(msg.sender, tokens);

      // Keep a record of how many tokens everybody gets in case we need to do refunds
      tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);
      emit TokenPurchase(msg.sender, amountPaid, tokens);
      numberOfTransactions = numberOfTransactions.add(1);

      if(tokensRaisedBeforeThisTransaction > minimumGoal) {

        payable( walletB).transfer(amountPaid);

      } else {
         vault.deposit{value: amountPaid}(msg.sender);
         if(goalReached()) {
          vault.close();
         }
         
      }

      // If the minimum goal of the ICO has been reach, close the vault to send
      // the ether to the wallet of the crowdsale
      checkCompletedCrowdsale();
   }

   function newBuyTokens() public payable whenNotPaused {
       require(validPurchase());

      uint256 tokens = 0;
      uint256 amountPaid = calculateNewExcessBalance();


      if (block.timestamp >= startTime1 && block.timestamp <= endTime1) {
            require(tokensRaised < limitTier1, "The tokens exceed Round 1 limit.");

           tokens = amountPaid.mul(rate); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier1)
            tokens = calculateNewExcessTokens(amountPaid, limitTier1,  rate);


            stageNow = "Round 1";
            
        } else if (block.timestamp >= startTime2 && block.timestamp <= endTime2) {
          require(tokensRaised < limitTier2, "The tokens exceed Round 2 limit.");

           tokens = amountPaid.mul(rateTier2); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier2)
            tokens = calculateNewExcessTokens(amountPaid, limitTier2,  rateTier2);


            stageNow = "Round 2";

        } else if (block.timestamp >= startTime3 && block.timestamp <= endTime3) {
          require(tokensRaised < limitTier3, "The tokens exceed Round 3 limit.");

           tokens = amountPaid.mul(rateTier3); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier3)
            tokens = calculateNewExcessTokens(amountPaid, limitTier3,  rateTier3);


            stageNow = "Round 3";

        } else if (block.timestamp >= startTime4 && block.timestamp <= endTime4) {
           require(tokensRaised < limitTier4, "The tokens exceed Round 4 limit.");

           tokens = amountPaid.mul(rateTier4); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier4)
            tokens = calculateNewExcessTokens(amountPaid, limitTier4,  rateTier4);


            stageNow = "Round 4";
        
        } else if (block.timestamp >= startTime5 && block.timestamp <= endTime5) {
           require(tokensRaised < limitTier5, "The tokens exceed Round 5 limit.");

           tokens = amountPaid.mul(rateTier5); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier5)
            tokens = calculateNewExcessTokens(amountPaid, limitTier5,  rateTier5);


            stageNow = "Round 5";
        } else if (block.timestamp >= startTime6 && block.timestamp <= endTime6) {
           require(tokensRaised < limitTier6, "The tokens exceed Round 6 limit.");

           tokens = amountPaid.mul(rateTier6); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier6)
            tokens = calculateNewExcessTokens(amountPaid, limitTier6,  rateTier6);


            stageNow = "Round 6";

        } else if (block.timestamp >= startTime7 && block.timestamp <= endTime7) {
           require(tokensRaised < limitTier7, "The tokens exceed Round 7 limit.");

           tokens = amountPaid.mul(rateTier7); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier7)
            tokens = calculateNewExcessTokens(amountPaid, limitTier7,  rateTier7);


            stageNow = "Round 7";

        } else if (block.timestamp >= startTime8 && block.timestamp <= endTime8) {
           require(tokensRaised < limitTier8, "The tokens exceed Round 8 limit.");

           tokens = amountPaid.mul(rateTier8); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier8)
            tokens = calculateNewExcessTokens(amountPaid, limitTier8,  rateTier8);


            stageNow = "Round 8";

        } else if (block.timestamp >= startTime9 && block.timestamp <= endTime9) {
           require(tokensRaised < limitTier9, "The tokens exceed Round 9 limit.");

           tokens = amountPaid.mul(rateTier9); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier9)
            tokens = calculateNewExcessTokens(amountPaid, limitTier9,  rateTier9);


            stageNow = "Round 9";

        } else if (block.timestamp >= startTime10 && block.timestamp <= endTime10) {
           require(tokensRaised < limitTier10, "The tokens exceed Round 10 limit.");

           tokens = amountPaid.mul(rateTier10); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier10)
            tokens = calculateNewExcessTokens(amountPaid, limitTier10,  rateTier10);


            stageNow = "Round 10";

        } else if (block.timestamp >= startTime11 && block.timestamp <= endTime11) {
           require(tokensRaised < limitTier11, "The tokens exceed Round 11 limit.");

           tokens = amountPaid.mul(rateTier11); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier11)
            tokens = calculateNewExcessTokens(amountPaid, limitTier11,  rateTier11);


            stageNow = "Round 11";
        } else if (block.timestamp >= startTime12 && block.timestamp <= endTime12) {
           require(tokensRaised < limitTier12, "The tokens exceed Round 12 limit.");

           tokens = amountPaid.mul(rateTier12); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier12)
            tokens = calculateNewExcessTokens(amountPaid, limitTier12,  rateTier12);


            stageNow = "Round 12";

        } else if (block.timestamp >= startTime13 && block.timestamp <= endTime13) {
           require(tokensRaised < limitTier13, "The tokens exceed Round 13 limit.");

           tokens = amountPaid.mul(rateTier13); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier13)
            tokens = calculateNewExcessTokens(amountPaid, limitTier13,  rateTier13);


            stageNow = "Round 13";

        } else if (block.timestamp >= startTime14 && block.timestamp <= endTime14) {
           require(tokensRaised < limitTier14, "The tokens exceed Round 14 limit.");

           tokens = amountPaid.mul(rateTier14); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier14)
            tokens = calculateNewExcessTokens(amountPaid, limitTier14,  rateTier14);


            stageNow = "Round 14";

        } else if (block.timestamp >= startTime15 && block.timestamp <= endTime15) {
           require(tokensRaised < limitTier15, "The tokens exceed Round 15 limit.");

           tokens = amountPaid.mul(rateTier15); 

         // If the amount of tokens that you want to buy gets out of this tier
         if(tokensRaised.add(tokens) > limitTier15)
            tokens = calculateNewExcessTokens(amountPaid, limitTier15,  rateTier15);


            stageNow = "Round 15";

        } else {
            stageNow = "No Sale";
            revert();
        } 

         weiRaised = weiRaised.add(amountPaid);
      uint256 tokensRaisedBeforeThisTransaction = tokensRaised;
      tokensRaised = tokensRaised.add(tokens);
      token.distributeICOTokens(msg.sender, tokens);

      // Keep a record of how many tokens everybody gets in case we need to do refunds
      tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);
      emit TokenPurchase(msg.sender, amountPaid, tokens);
      numberOfTransactions = numberOfTransactions.add(1);

      if(tokensRaisedBeforeThisTransaction > minimumGoal) {

        payable( walletB).transfer(amountPaid);

      } else {
         vault.deposit{value: amountPaid}(msg.sender);
         if(goalReached()) {
          vault.close();
         }
         
      }

      // If the minimum goal of the ICO has been reach, close the vault to send
      // the ether to the wallet of the crowdsale
      checkCompletedCrowdsale();





   }


   /// @notice Calculates how many ether will be used to generate the tokens in
   /// case the buyer sends more than the maximum balance but has some balance left
   /// and updates the balance of that buyer.
   /// For instance if he's 500 balance and he sends 1000, it will return 500
   /// and refund the other 500 ether
   function calculateExcessBalance() internal whenNotPaused returns(uint256) {
      uint256 amountPaid = msg.value;
      uint256 differenceWei = 0;
      uint256 exceedingBalance = 0;

      // If we're in the last tier, check that the limit hasn't been reached
      // and if so, refund the difference and return what will be used to
      // buy the remaining tokens
      if(tokensRaised >= limitTier3) {
         uint256 addedTokens = tokensRaised.add(amountPaid.mul(rateTier4));

         // If tokensRaised + what you paid converted to tokens is bigger than the max
         if(addedTokens > maxTokensRaised) {

            // Refund the difference
            uint256 difference = addedTokens.sub(maxTokensRaised);
            differenceWei = difference.div(rateTier4);
            amountPaid = amountPaid.sub(differenceWei);
         }
      }

      uint256 addedBalance = crowdsaleBalances[msg.sender].add(amountPaid);

      // Checking that the individual limit of 1000 ETH per user is not reached
      if(addedBalance <= maxPurchase) {
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      } else {

         // Substracting 1000 ether in wei
         exceedingBalance = addedBalance.sub(maxPurchase);
         amountPaid = amountPaid.sub(exceedingBalance);

         // Add that balance to the balances
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      }

      // Make the transfers at the end of the function for security purposes
      if(differenceWei > 0)
         payable(msg.sender).transfer(differenceWei);

      if(exceedingBalance > 0) {

         // Return the exceeding balance to the buyer
         payable(msg.sender).transfer(exceedingBalance);
      }

      return amountPaid;
   }

   function calculateNewExcessBalance() internal whenNotPaused returns(uint256) {
      uint256 amountPaid = msg.value;
      uint256 differenceWei = 0;
      uint256 exceedingBalance = 0;

      

      uint256 addedBalance = crowdsaleBalances[msg.sender].add(amountPaid);

      // Checking that the individual limit of 1000 ETH per user is not reached
      if(addedBalance <= maxPurchase) {
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      } else {

         // Substracting 1000 ether in wei
         exceedingBalance = addedBalance.sub(maxPurchase);
         amountPaid = amountPaid.sub(exceedingBalance);

         // Add that balance to the balances
         crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);
      }

      // Make the transfers at the end of the function for security purposes
      if(differenceWei > 0)
         payable(msg.sender).transfer(differenceWei);

      if(exceedingBalance > 0) {

         // Return the exceeding balance to the buyer
         payable(msg.sender).transfer(exceedingBalance);
      }

      return amountPaid;
   }

   function setAllRoundsLimit(uint256 _limitTier1, uint256 _limitTier2, uint256 _limitTier3
   , uint256 _limitTier4, uint256 _limitTier5, uint256 _limitTier6, uint256 _limitTier7
   , uint256 _limitTier8, uint256 _limitTier9, uint256 _limitTier10)
      external onlyOwner whenNotPaused 
   {
     // require(_limitTier1 > 0 && _limitTier2 > 0 && _limitTier3 > 0 );
     // require(_limitTier1 < _limitTier2 && _limitTier2 < _limitTier3  );

      limitTier1 = _limitTier1;
      limitTier2 = _limitTier2;
      limitTier3 = _limitTier3;
      limitTier4 = _limitTier4;
      limitTier5 = _limitTier5;
      limitTier6 = _limitTier6;
      limitTier7 = _limitTier7;
      limitTier8 = _limitTier8;
      limitTier9 = _limitTier9;
      limitTier10 = _limitTier10;
     // limitTier11 = _limitTier11;
     // limitTier12 = _limitTier12;
     // limitTier13 = _limitTier13;
     // limitTier14 = _limitTier14;
     // limitTier15 = _limitTier15;
   }




   function setRound1Rate(uint256 tier1) external onlyOwner whenNotPaused {
       require(tier1> 0 ,"The rate should be non-Zero ");
       rate = tier1;
   }

   function setRound2Rate(uint256 tier2) external onlyOwner whenNotPaused {
       require(tier2> 0 && tier2 < rate ,"The rate should be non-Zero and less than first round ");
       rateTier2 = tier2;
   }

   function setRound3Rate(uint256 tier3) external onlyOwner whenNotPaused {
       require(tier3> 0 && tier3 < rateTier2 ,"The rate should be non-Zero and less than second round ");
       rateTier3 = tier3;
   }

   function setRound4Rate(uint256 tier4) external onlyOwner whenNotPaused {
       require(tier4> 0 && tier4 < rateTier3 ,"The rate should be non-Zero and less than third round ");
       rateTier4 = tier4;
   }

     function setRound5Rate(uint256 tier5) external onlyOwner whenNotPaused {
       require(tier5> 0 && tier5 < rateTier4 ,"The rate should be non-Zero and less than 4th round ");
       rateTier5 = tier5;
   }

    function setRound6Rate(uint256 tier6) external onlyOwner whenNotPaused {
       require(tier6> 0 && tier6 < rateTier5 ,"The rate should be non-Zero and less than 5th round ");
       rateTier6 = tier6;
   }

    function setRound7Rate(uint256 tier7) external onlyOwner whenNotPaused {
       require(tier7> 0 && tier7 < rateTier6 ,"The rate should be non-Zero and less than 6th round ");
       rateTier7 = tier7;
   }

    function setRound8Rate(uint256 tier8) external onlyOwner whenNotPaused {
       require(tier8> 0 && tier8 < rateTier7 ,"The rate should be non-Zero and less than 7th round ");
       rateTier8 = tier8;
   }

    function setRound9Rate(uint256 tier9) external onlyOwner whenNotPaused {
       require(tier9> 0 && tier9 < rateTier8 ,"The rate should be non-Zero and less than 8th round ");
       rateTier9 = tier9;
   }

    function setRound10Rate(uint256 tier10) external onlyOwner whenNotPaused {
       require(tier10> 0 && tier10 < rateTier9 ,"The rate should be non-Zero and less than 9th round ");
       rateTier10 = tier10;
   }

    function setRound11Rate(uint256 tier11) external onlyOwner whenNotPaused {
       require(tier11> 0 && tier11 < rateTier10 ,"The rate should be non-Zero and less than 10th round ");
       rateTier11 = tier11;
   }

    function setRound12Rate(uint256 tier12) external onlyOwner whenNotPaused {
       require(tier12> 0 && tier12 < rateTier11 ,"The rate should be non-Zero and less than 11th round ");
       rateTier12 = tier12;
   }

    function setRound13Rate(uint256 tier13) external onlyOwner whenNotPaused {
       require(tier13> 0 && tier13 < rateTier12 ,"The rate should be non-Zero and less than 12th round ");
       rateTier13 = tier13;
   }

    function setRound14Rate(uint256 tier14) external onlyOwner whenNotPaused {
       require(tier14> 0 && tier14 < rateTier13 ,"The rate should be non-Zero and less than 13th round ");
       rateTier14 = tier14;
   }

    function setRound15Rate(uint256 tier15) external onlyOwner whenNotPaused {
       require(tier15> 0 && tier15 < rateTier14 ,"The rate should be non-Zero and less than 14th round ");
       rateTier15 = tier15;
   }

    
   


   function setAllRoundsRate(uint256 tier1, uint256 tier2, uint256 tier3, uint256 tier4
   ,uint256 tier5, uint256 tier6, uint256 tier7, uint256 tier8, uint256 tier9, uint256 tier10)
      external onlyOwner whenNotPaused
   {
      /*
      require(tier1 > 0 && tier2 > 0 && tier3 > 0 && tier4 > 0 && tier5 > 0 && tier6 > 0 
      && tier7 > 0 && tier8 > 0 && tier9 > 0 && tier10 > 0 ); 

      require(tier1 > tier2 && tier2 > tier3 && tier3 > tier4 && tier4 > tier5 && tier5 > tier6
      && tier6 > tier7 && tier7 > tier8 && tier8 > tier9 && tier9 > tier10);

      */

      rate = tier1;
      rateTier2 = tier2;
      rateTier3 = tier3;
      rateTier4 = tier4;
      rateTier5 = tier5;
      rateTier6 = tier6;
      rateTier7 = tier7;
      rateTier8 = tier8;
      rateTier9 = tier9;
      rateTier10 = tier10;
    //  rateTier11 = tier11;
    //  rateTier12 = tier12;
    //  rateTier13 = tier13;
    //  rateTier14 = tier14;
    //  rateTier15 = tier15;
   }

   function SetmaxTokensAvailable(uint256 totalTokens ) external onlyOwner whenNotPaused{
       maxTokensRaised = totalTokens * 10 **18;
   }

   function SetminPurchase(uint minimumInvestment) external onlyOwner whenNotPaused{
       require(minPurchase < maxPurchase, "The minimum purchase limit should be less than Maximum purchase limit");
       minPurchase = minimumInvestment;
   }

   function SetmaxPurchase(uint maximumInvestment) external onlyOwner whenNotPaused{
       require(maxPurchase > minPurchase, "The maximum purchase limit should be greater than Minimum purchase limit");
       maxPurchase = maximumInvestment;
   }

   function SetSoftCap(uint256 _minimumGoal) external onlyOwner whenNotPaused{
       minimumGoal = _minimumGoal;
   }

 /*  function setEndDate(uint256 _endTime)
      external onlyOwner whenNotPaused
   {
      require(block.timestamp <= _endTime);
      require(startTime < _endTime);
      
      endTime = _endTime;
   }

   */

   function SetRound1StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime1 = startTime;

   }

    function SetRound2StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime2 = startTime;

   }

    function SetRound3StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime3 = startTime;

   }

    function SetRound4StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime4 = startTime;

   }

    function SetRound5StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime5 = startTime;

   }

    function SetRound6StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime6 = startTime;

   }

    function SetRound7StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime7 = startTime;

   }

    function SetRound8StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime8 = startTime;

   }

    function SetRound9StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime9 = startTime;

   }

    function SetRound10StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime10 = startTime;

   }

    function SetRound11StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime11 = startTime;

   }

    function SetRound12StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime12 = startTime;

   }

    function SetRound13StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime13 = startTime;

   }

    function SetRound14StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime14 = startTime;

   }

    function SetRound15StartTime(uint startTime) external onlyOwner whenNotPaused{
       startTime15 = startTime;

   }

   function SetRound1EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime1 = endTime;

   } 

   function SetRound2EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime2 = endTime;

   }

   function SetRound3EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime3 = endTime;

   }

   function SetRound4EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime4 = endTime;

   }

   function SetRound5EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime5 = endTime;

   }

   function SetRound6EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime6 = endTime;

   }

   function SetRound7EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime7 = endTime;

   }

   function SetRound8EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime8 = endTime;

   }

   function SetRound9EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime9 = endTime;

   }

   function SetRound10EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime10 = endTime;

   }

   function SetRound11EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime11 = endTime;

   }

   function SetRound12EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime12 = endTime;

   }

   function SetRound13EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime13 = endTime;

   }

   function SetRound14EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime14 = endTime;

   }

   function SetRound15EndTime(uint endTime) external onlyOwner whenNotPaused{
       endTime15 = endTime;

   }


   /// @notice Check if the crowdsale has ended and enables refunds only in case the
   /// goal hasn't been reached
   function checkCompletedCrowdsale() public whenNotPaused {
      if(!isEnded) {
         if(hasEnded() && !goalReached()){
            vault.enableRefunds();

            isRefunding = true;
            isEnded = true;
            emit Finalized();
         } else if(hasEnded()  && goalReached()) {
            
            
            isEnded = true; 


            // Burn token only when minimum goal reached and maxGoal not reached. 
            if(tokensRaised < maxTokensRaised) {

               token.burnTokens();

            } 

           emit Finalized();
         } 
         
         
      }
   }

   /// @notice If crowdsale is unsuccessful, investors can claim refunds here
   function claimRefund() public whenNotPaused {
     require(hasEnded() && !goalReached() && isRefunding);

     vault.refund(msg.sender);
     token.refundTokens(msg.sender, tokensBought[msg.sender]);
   }

   ///  Buys the tokens for the specified tier and for the next one
   /// @param amount The amount of ether paid to buy the tokens
   /// @param tokensThisTier The limit of tokens of that tier
   /// @param tierSelected The tier selected
   /// @param _rate The rate used for that `tierSelected`
   ///  uint The total amount of tokens bought combining the tier prices
   function calculateExcessTokens(
      uint256 amount,
      uint256 tokensThisTier,
      uint256 tierSelected,
      uint256 _rate
   ) public returns(uint256 totalTokens) {
      require(amount > 0 && tokensThisTier > 0 && _rate > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      uint weiThisTier = tokensThisTier.sub(tokensRaised).div(_rate);
      uint weiNextTier = amount.sub(weiThisTier);
      uint tokensNextTier = 0;
      bool returnTokens = false;

      // If there's excessive wei for the last tier, refund those
      if(tierSelected != 4)
         tokensNextTier = calculateTokensTier(weiNextTier, tierSelected.add(1));
      else
         returnTokens = true;

      totalTokens = tokensThisTier.sub(tokensRaised).add(tokensNextTier);

      // Do the transfer at the end
      if(returnTokens) payable(msg.sender).transfer(weiNextTier);
   }


   function calculateNewExcessTokens(
      uint256 amount,
      uint256 tokensThisTier,
      //uint256 tierSelected,
      uint256 _rate
   ) public returns(uint256 totalTokens) {
      require(amount > 0 && tokensThisTier > 0 && _rate > 0);
     // require(tierSelected >= 1 && tierSelected <= 4);

      uint weiThisTier = tokensThisTier.sub(tokensRaised).div(_rate);
      uint weiNextTier = amount.sub(weiThisTier);
      uint tokensNextTier = 0;
      bool returnTokens = true;

      /*

       If there's excessive wei for the last tier, refund those
      if(tierSelected != 4)
         tokensNextTier = calculateTokensTier(weiNextTier, tierSelected.add(1));
      else
         returnTokens = true;

         */

      totalTokens = tokensThisTier.sub(tokensRaised).add(tokensNextTier);

      // Do the transfer at the end
      if(returnTokens) payable(msg.sender).transfer(weiNextTier);
   }

   /// @notice Buys the tokens given the price of the tier one and the wei paid
   /// @param weiPaid The amount of wei paid that will be used to buy tokens
   /// @param tierSelected The tier that you'll use for thir purchase
   /// @return calculatedTokens Returns how many tokens you've bought for that wei paid
   function calculateTokensTier(uint256 weiPaid, uint256 tierSelected)
        internal view returns(uint256 calculatedTokens)
   {
      require(weiPaid > 0);
      require(tierSelected >= 1 && tierSelected <= 4);

      if(tierSelected == 1)
         calculatedTokens = weiPaid.mul(rate);
      else if(tierSelected == 2)
         calculatedTokens = weiPaid.mul(rateTier2);
      else if(tierSelected == 3)
         calculatedTokens = weiPaid.mul(rateTier3);
      else
         calculatedTokens = weiPaid.mul(rateTier4);
   } 


   /// @notice Checks if a purchase is considered valid
   /// @return bool If the purchase is valid or not
   function validPurchase() internal view returns(bool) {
     // bool withinPeriod = block.timestamp >= startTime && block.timestamp <= endTime;
      bool nonZeroPurchase = msg.value > 0;
      bool withinTokenLimit = tokensRaised < maxTokensRaised;
      bool minimumPurchase = msg.value >= minPurchase;
      bool hasBalanceAvailable = crowdsaleBalances[msg.sender] < maxPurchase;

      // We want to limit the gas to avoid giving priority to the biggest paying contributors
      //bool limitGas = tx.gasprice <= limitGasPrice;

     // return withinPeriod && nonZeroPurchase && withinTokenLimit && minimumPurchase && hasBalanceAvailable;
     return nonZeroPurchase && withinTokenLimit && minimumPurchase && hasBalanceAvailable;
   }

   /// @notice To see if the minimum goal of tokens of the ICO has been reached
   /// @return bool True if the tokens raised are bigger than the goal or false otherwise
   function goalReached() public view returns(bool) {
      return tokensRaised >= minimumGoal;
   }

   /// @notice Public function to check if the crowdsale has ended or not
   function hasEnded() public view returns(bool) {
      return block.timestamp > endTime15 || tokensRaised >= maxTokensRaised;
   }


    /**
   * tokensAvailable
   * @dev returns the number of tokens allocated to this contract
   **/
  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }

   receive () external payable {
   }
}