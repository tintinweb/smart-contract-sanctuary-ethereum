/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// File: BEP_Token.sol

pragma solidity 0.5.16;

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
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
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

contract BEP20Token is IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _totalSupply = totalSupply;
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
   * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
   * the total supply.
   *
   * Requirements
   *
   * - `msg.sender` must be the token owner
   */
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
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
}
// File: Game.sol

pragma solidity ^0.5.16;


contract Game is BEP20Token {

    using SafeMath for uint256;

    address[15][2] private tables;

    uint256[5] private entry_price = [120,480]; 
    uint256[5] private referal_price = [20,80];

    mapping (address => uint256 ) private my_table;
    mapping (address => bool ) private check_inGame;


    mapping (address => address) private my_inviter;
    mapping (address => address[]) private my_referrals;

    mapping (address => bool) public second_game;


    address[15][2] private tables2;

    uint256[5] private entry_price2 = [1920,7200]; 
    uint256[5] private referal_price2 = [320,1200];

    mapping (address => uint256 ) private my_table2;
    mapping (address => bool ) private check_inGame2;

    IBEP20 public tokenUSDT;

    event EmperorLog(address emperator, uint256 money, uint256 number_imperia, uint256 date);
    event ReferalsSum(address referal, uint256 revards, uint256 number_imperia, uint256 date);

    event MyLog(address emperor, uint256 sum, uint256 number_imperia, uint256 date);

    uint256 private all_money; 
    uint256 private all_participant; 
    
    constructor() BEP20Token("","",0,0 ) public {

    }

     function Check_Count_MyReferals() public view returns(uint256){
        return my_referrals[msg.sender].length;
    }

    function Check_All_Money() public view returns(uint256){
        return all_money;
    }

     function Check_All_Participant() public view returns(uint256){
        return all_participant;
    }

    function Check_Status(uint number_circle) public view returns(string memory){
        uint256 number_status;
        if (number_circle == 1)
         number_status = M_Set_Number(tables,number_circle);
        else if (number_circle == 2)
         number_status = M_Set_Number(tables2,number_circle);
        else
        revert("error number circle");

       if ( number_status < 8)
       return "Legion";
       else if (number_status >= 8 && number_status < 12)
        return "Adviser";
       else if (number_status >= 12 && number_status < 14)
        return "Chancellor";
       else if (number_status == 14)
        return "Emperor";
        else
        return "error";
    }

    function Check_Number(uint number_circle) public view returns(uint256){
        if (number_circle == 1)
        return M_Set_Number(tables,number_circle)+1;
        else if (number_circle == 2)
        return M_Set_Number(tables2,number_circle)+1;
        else
        revert("error number circle");
    }

    function Check_Table(uint number_circle) public view returns(uint256){
         if (number_circle == 1)
        return my_table[msg.sender] + 1;
        else if (number_circle == 2)
        return my_table2[msg.sender] + 3;
        else
        revert("error number circle");
    }

    function Check_Players(uint256 number_table,uint number_circle) public view returns(uint256){
        if (number_circle == 1)
        return M_Free_Place(tables, number_table);
        else if (number_circle == 2)
        return M_Free_Place(tables2, number_table);
        else
        revert("error number circle");
    }

    function Check_MyInviter() public view returns (address){
        return my_inviter[msg.sender];
    }

    function Check_MyReferals() public view returns (address[] memory){
        return my_referrals[msg.sender];
    }

    function Check_player(uint256 number_table, uint256 number_player ,uint number_circle) public onlyOwner view returns(address){
        if (number_circle == 1)
        return tables[number_table][number_player];
        else if (number_circle == 2)
        return tables2[number_table][number_player];
        else
        revert("error number circle");
    }

    function Edit_entry_price(uint256 number_table, uint256 new_price ,uint number_circle) public onlyOwner {
        if (number_circle == 1)
        entry_price[number_table] = new_price;
         else if (number_circle == 2)
          entry_price2[number_table] = new_price;
            else
        revert("error number circle");
    }

    function Edit_referal_price(uint256 number, uint256 new_price) public onlyOwner {
        entry_price[number] = new_price;
    }

    function AddToken(address new_token) public onlyOwner {
       tokenUSDT = IBEP20(new_token);
    }

    function Add_Inviter(address inviter) public{
        require(my_inviter[msg.sender] == address(0) && inviter != msg.sender, "error address");
        my_inviter[msg.sender] = inviter;
        my_referrals[inviter].push(msg.sender);
    }

    function WithdrawalAll() public onlyOwner{
         tokenUSDT.transfer(owner(),tokenUSDT.balanceOf(address(this)));
    }

    function First_Game() public Set_InGame(){

 
       require(tokenUSDT.allowance(msg.sender,address(this)) >= entry_price[my_table[msg.sender]] * 10 ** 18 , "Payment not confirmed");
       require(tokenUSDT.balanceOf(msg.sender)  >= entry_price[my_table[msg.sender]] * 10 ** 18, "Insufficient funds to pay" );

       tokenUSDT.transferFrom(msg.sender,address(this),entry_price[my_table[msg.sender]] * 10 ** 18);

        all_money += entry_price[my_table[msg.sender]];
        all_participant++;

       if (my_inviter[msg.sender] != address(0)){
           tokenUSDT.transfer(my_inviter[msg.sender], (entry_price[my_table[msg.sender]] - (entry_price[my_table[msg.sender]] - referal_price[my_table[msg.sender]]))* 10 ** 18);
           emit ReferalsSum(msg.sender,(entry_price[my_table[msg.sender]] - (entry_price[my_table[msg.sender]] - referal_price[my_table[msg.sender]])), my_table[msg.sender], block.timestamp );
       }
       

       if (tables[my_table[msg.sender]][tables[my_table[msg.sender]].length-1] != address(0)){
           tokenUSDT.transfer(tables[my_table[msg.sender]][tables[my_table[msg.sender]].length-1], (entry_price[my_table[msg.sender]] - referal_price[my_table[msg.sender]]) * 10 ** 18);
          emit EmperorLog(msg.sender,entry_price[my_table[msg.sender]] - referal_price[my_table[msg.sender]],my_table[tables[my_table[msg.sender]][tables[my_table[msg.sender]].length-1]],block.timestamp);
          emit MyLog(tables[my_table[msg.sender]][tables[my_table[msg.sender]].length-1],entry_price[my_table[msg.sender]] - referal_price[my_table[msg.sender]],my_table[tables[my_table[msg.sender]][tables[my_table[msg.sender]].length-1]], block.timestamp );
       }
       
       else
       WithdrawalAll();
       

       check_inGame[msg.sender] = true;
        
       if(tables[my_table[msg.sender]][tables[my_table[msg.sender]].length-1] != address(0) 
          && tables[my_table[msg.sender]][tables[my_table[msg.sender]].length-1] != address(this))
        {
            if (my_table[tables[my_table[msg.sender]][14]] != 1)
            my_table[tables[my_table[msg.sender]][14]]++;
            else{
                     my_table[tables[my_table[msg.sender]][14]] = 0;
                     second_game[tables[my_table[msg.sender]][14]] = true;
            }
           

            check_inGame[tables[my_table[msg.sender]][14]] = false;
        }
       

        for (uint i = tables[my_table[msg.sender]].length-1; i > 0 ; i--){
            if(tables[my_table[msg.sender]][i-1] != address(0))
            tables[my_table[msg.sender]][i] = tables[my_table[msg.sender]][i-1];
            
        }

        tables[my_table[msg.sender]][0] = msg.sender;

    }


    function SecondGame() public CheckReferals(){

    require(second_game[msg.sender] == true, "Second game lock");

    require(check_inGame2[msg.sender] == false, "You not in game");

    
    require(tokenUSDT.allowance(msg.sender,address(this)) >= entry_price2[my_table2[msg.sender]] * 10 ** 18 , "Payment not confirmed");
    require(tokenUSDT.balanceOf(msg.sender)  >= entry_price2[my_table2[msg.sender]] * 10 ** 18, "Insufficient funds to pay" );

       tokenUSDT.transferFrom(msg.sender,address(this),entry_price2[my_table2[msg.sender]] * 10 ** 18);

       if (my_inviter[msg.sender] != address(0)){
           tokenUSDT.transfer(my_inviter[msg.sender], (entry_price2[my_table2[msg.sender]] - (entry_price2[my_table2[msg.sender]] - referal_price2[my_table2[msg.sender]]))* 10 ** 18);
           emit ReferalsSum(msg.sender,(entry_price2[my_table2[msg.sender]] - (entry_price2[my_table2[msg.sender]] - referal_price2[my_table2[msg.sender]])), my_table2[msg.sender], block.timestamp );
       }
       

       if (tables2[my_table2[msg.sender]][tables2[my_table2[msg.sender]].length-1] != address(0))
       tokenUSDT.transfer(tables2[my_table2[msg.sender]][tables2[my_table2[msg.sender]].length-1], (entry_price2[my_table2[msg.sender]] - referal_price2[my_table2[msg.sender]]) * 10 ** 18);
       else
       WithdrawalAll();
       
    
       check_inGame2[msg.sender] = true;
        
       if(tables2[my_table2[msg.sender]][tables2[my_table2[msg.sender]].length-1] != address(0) 
          && tables2[my_table2[msg.sender]][tables2[my_table2[msg.sender]].length-1] != address(this))
        {
            if (my_table2[tables2[my_table2[msg.sender]][14]] != 1)
            my_table2[tables2[my_table2[msg.sender]][14]]++;
            else{
            my_table2[tables2[my_table2[msg.sender]][14]] = 0;
            }
           
            check_inGame2[tables2[my_table2[msg.sender]][14]] = false;

         emit EmperorLog(msg.sender,entry_price2[my_table2[msg.sender]] - referal_price2[my_table2[msg.sender]],my_table2[tables2[my_table2[msg.sender]][tables2[my_table2[msg.sender]].length-1]],block.timestamp);
         emit MyLog(tables[my_table2[msg.sender]][tables2[my_table2[msg.sender]].length-1],entry_price2[my_table2[msg.sender]] - referal_price2[my_table2[msg.sender]],my_table2[tables2[my_table2[msg.sender]][tables2[my_table2[msg.sender]].length-1]], block.timestamp );
        }
       

        for (uint i = tables2[my_table2[msg.sender]].length-1; i > 0 ; i--){
            if(tables2[my_table2[msg.sender]][i-1] != address(0))
            tables2[my_table2[msg.sender]][i] = tables2[my_table2[msg.sender]][i-1];
            
        }

        tables2[my_table2[msg.sender]][0] = msg.sender;
    }



      function Change(address new_adr) public onlyOwner{
        transferOwnership(new_adr);
    }

////////////////////////////ищет свободное место/////////////////////////////////////////////
    function M_Free_Place(address[15][2] memory arr, uint256 num) public  view returns (uint256){

        uint256 count;

        for (uint i = 0; i < arr[num].length-1; i++){
            if (arr[num][i] == address(0))
            count++;
        }

        return count;
    }
//////////////////////////////////////////////////////////////////////////////////////////////


////////////////////////////присваивает порядковый номер////////////////////////////////////////////
    function M_Set_Number(address[15][2] memory arr, uint256 number_circle) public view returns (uint256){

        if (number_circle == 1){
             for (uint i = 0; i < arr[my_table[msg.sender]].length; i++){
            if (arr[my_table[msg.sender]][i] == msg.sender){
                return i;
            }

        }
        revert("you are not in the game");
        }
        else if (number_circle == 2){
             for (uint i = 0; i < arr[my_table[msg.sender]].length; i++){
            if (arr[my_table[msg.sender]][i] == msg.sender){
                return i;
            }

        }
        revert("you are not in the game");
        }

        revert("error number circle");

    }
/////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////проверка в игре игрок или нет////////////////////////////////////////////
     modifier Set_InGame(){
        require(check_inGame[msg.sender] == false, "You not in game");
        _;
    }
////////////////////////////////////////////////////////////////////////////////////////////////////

    modifier CheckReferals(){
        require(my_referrals[msg.sender].length < 2,"Not enough referrals");
        _;
    }

}