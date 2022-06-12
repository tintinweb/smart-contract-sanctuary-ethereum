/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// Sources flattened with hardhat v2.9.7 https://hardhat.org

// File contracts/IBEP20.sol

// SPDX-License-Identifier: MIT

pragma solidity  0.5.17;

// BEP20 Hardhat token = 0x5FbDB2315678afecb367f032d93F642f64180aa3
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
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

function freezeToken(address recipient, uint256 amount)external returns(bool);
function unfreezeToken(address account) external returns(bool);
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
  event Unfreeze(address indexed _unfreezer, address indexed _to, uint256 _amount);
}


// File contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
pragma solidity  0.5.17;

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
  constructor() public {
  }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}


// File contracts/utils/Ownable.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

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
  constructor() public {

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


// File contracts/utils/SafeMath.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

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
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


// File contracts/BEP20.sol

// SPDX-License-Identifier: MIT
pragma solidity  0.5.17;




contract BEP20 is Context, IBEP20, Ownable {
  using SafeMath for uint256;
  mapping(address => uint256) private _balances;
  mapping(address => uint256) public _frozenBalance;
  mapping(address => bool) owners;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;

  constructor() public {
    _name = "ABC";
    _symbol = "AVE";
    _decimals = 18;
    _totalSupply = 50000000 * 1e18;
    _balances[msg.sender] = _totalSupply;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

// emit Unfreeze(address _unfreezer, address _to, uint256 _amount);
  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view  returns (address) {
    return owner();
  }
  function setOwners(address _owner)external onlyOwner {
    owners[_owner] =true;
    
  }

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view  returns (uint8) {
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
  function totalSupply() external view  returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev See {BEP20-balanceOf}.
   */
  function balanceOf(address account) external view  returns (uint256) {
    return _balances[account].add(_frozenBalance[account]);
  }

  /**
   * @dev See {BEP20-transfer}.
   *
   * Requirements:
   *
   * - `recipient` cannot be the zero address.
   * - the caller must have a balance of at least `amount`.
   */
  function transfer(address recipient, uint256 amount) external  returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev See {BEP20-allowance}.
   */
  function allowance(address owner, address spender) external view  returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev See {BEP20-approve}.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
   */
  function approve(address spender, uint256 amount) external  returns (bool) {
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
   * - the caller must have allowance for x`sender`'s tokens of at least
   * `amount`.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external  returns (bool) {
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    _transfer(sender, recipient, amount);
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
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal {
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
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal {
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
  function burnFrom(address account, uint256 amount) public {
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
    _burn(account, amount);
  }

  /**
   * @dev Burn amount from user it self acc
   */
  function burn(uint256 _amount) public {
    _burn(_msgSender(), _amount);
  }

  function freezeToken(address account, uint256 amount) external returns(bool){
    require(account != address(0), "BEP20: mint to the zero address");
    require(owners[msg.sender],"only Owner freeze Token");
    _totalSupply = _totalSupply.add(amount);
    _frozenBalance[account] = _frozenBalance[account].add(amount);
    emit Transfer(address(0), account, amount);
    return true;
  }
  function unfreezeToken(address account) external returns(bool){
   
      require(account != address(0), "BEP20: mint to the zero address");
      require(owners[msg.sender],"only Owner freeze Token");
      require(_frozenBalance[account] >0, "Not Enough Amount on Freez");
      _frozenBalance[account] = 0;
      _balances[account] = _balances[account].add(_frozenBalance[account]);
      emit Unfreeze(msg.sender,account, _frozenBalance[account]);
      return true;
  } 
}


// File contracts/ico.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.5.17;

contract PoolVine {

      address public ownerWallet;
      uint public currUserID = 0;
      uint public unlimited_level_price=0;
      struct UserStruct {
        bool isExist;
        uint id;
        uint referrerID;
        uint referredUsers;
        uint income;
        uint batchPaid;
        uint autoPoolPayReceived;
        uint missedPoolPayment;
        address autopoolPayReciever;
        uint levelIncomeReceived;
        mapping(uint => uint) levelExpired;
      }
      // MATRIX CONFIG FOR AUTO-POOL FUND
      uint public batchSize;
      uint public height;
      // USERS   
      mapping (address => UserStruct) public users;
      mapping (uint => address) public userList;
      mapping(uint => uint) public LEVEL_PRICE;
      mapping(address => uint256) public totalFreeze;
      IBEP20 token;
      uint256 public tokenReward;
    //   mapping(string => address) token; // Token Address Hold with name
      uint public REGESTRATION_FESS;
      uint pool1_price=1000000;
      bool ownerPaid;
      // Events
     event regLevelEvent(address indexed _user, address indexed _referrer, uint _time, string tokenType);
     event getMoneyForLevelEvent(address indexed _user, address indexed _referral, uint _level, uint _time,string tokenType);
     event successfulPay(string str, address sender, address referrer, uint generation, string tokenType);
     event autoPoolEvent(string str1,address sender, address referrer, uint height, uint time, string tokenType);
    UserStruct[] public requests;

     uint public pay_autopool;

     // Owner Set Token Acceptance Format
        bool isTokenAcceptance = false;
        string tokenAcceptType = "NATIVE-COIN";

    constructor(address _token, uint256 _tokenReward) public {
          ownerWallet = msg.sender;
          REGESTRATION_FESS = 1000000000;
          batchSize = 2;
          height = 5;
           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 10 * 4 / 10;
           unlimited_level_price=REGESTRATION_FESS / 10 * 4 / 10;
           pay_autopool = REGESTRATION_FESS / 10 * 4 / height;
           UserStruct memory userStruct;
           currUserID++;
           userStruct = UserStruct({
                isExist: true,
                id: currUserID,
                referrerID: 0,
                referredUsers:0,
                income : 0,
                batchPaid : 0,
                autoPoolPayReceived : 0,
                missedPoolPayment : 0,
                autopoolPayReciever : ownerWallet,
                levelIncomeReceived : 0
           });
            
          users[ownerWallet] = userStruct;
          userList[currUserID] = ownerWallet;
          token = IBEP20(_token);
          tokenReward = _tokenReward;
      }
     modifier onlyOwner(){
         require(msg.sender==ownerWallet,"Only Owner can access this function.");
         _;
     }
     function setRegistrationFess(uint fess) public onlyOwner{
           REGESTRATION_FESS = fess;
           REGESTRATION_FESS = REGESTRATION_FESS * (10 ** 18);
           LEVEL_PRICE[1] = REGESTRATION_FESS / 5;
           LEVEL_PRICE[2] = REGESTRATION_FESS / 10 * 4 / 10;
           pay_autopool = REGESTRATION_FESS / 10 * 4 / height;
           unlimited_level_price=REGESTRATION_FESS / 10 * 4 / 10;
     }
     
     function getRegistrationFess() public view returns(uint){
         return REGESTRATION_FESS;
     }
     // Change Token for Reward on register and latter owner can use this token
     function changeToken(address _tokenAddress)public onlyOwner {
         require(_tokenAddress != address(0),"Invalid Token Address");
         token= IBEP20(_tokenAddress);
     }
      // Change amount of BEP20 token Reward by owner
    function changeTokenReward(uint256 _amount) external onlyOwner{
        tokenReward = _amount;

    }
    
    function setTokenAcceptance(bool _status)external onlyOwner{
        isTokenAcceptance = _status;
    }
   

function regUser(uint _referrerID, uint256 _amount) public payable {
       
      require(!users[msg.sender].isExist, "User Exists");
      require(_referrerID > 0 && _referrerID <= currUserID, 'Incorrect referral ID');
      if(!isTokenAcceptance){
      require(msg.value == REGESTRATION_FESS, 'Incorrect Value');
      }
      else{
      require(_amount == REGESTRATION_FESS, 'Incorrect Value');
      require(token.allowance(msg.sender, address(this)) >= _amount, "NEED_TO_APPROVE_TOKEN");
      }
       
        UserStruct memory userStruct;
        currUserID++;

        userStruct = UserStruct({
            isExist: true,
            id: currUserID,
            referrerID: _referrerID,
            referredUsers:0,
            income : 0,
            batchPaid : 0,
            autoPoolPayReceived : 0,
            missedPoolPayment : 0,
            autopoolPayReciever : address(0),
            levelIncomeReceived : 0
        });
   
       users[msg.sender] = userStruct;
       userList[currUserID]=msg.sender;
       
        users[userList[users[msg.sender].referrerID]].referredUsers=users[userList[users[msg.sender].referrerID]].referredUsers+1;
        token.freezeToken(msg.sender, tokenReward); // Transfer Rewarded Token
        autoPool(msg.sender);            
        payReferral(1,msg.sender);
        totalFreeze[msg.sender] = totalFreeze[msg.sender] + tokenReward;
        if(isTokenAcceptance){
            tokenAcceptType = "ERC-20-COIN";
        }else{}
        emit regLevelEvent(msg.sender, userList[_referrerID], now,tokenAcceptType );
    }

function heightPayment(address _user,uint batch,uint id,uint h) internal{
    bool sent = false;
    if((users[userList[id]].autopoolPayReciever != address(0)) && (userList[batch] != users[userList[id]].autopoolPayReciever) && (h <= height && h<=2 && id > 0 && ownerPaid!=true)) {
        address nextLevel = userList[id];
        if(!isTokenAcceptance){
        sent = address(uint160(nextLevel)).send(pay_autopool);   
        }
        else{
        sent = token.transferFrom(msg.sender,address(uint160(nextLevel)),pay_autopool);  

        }
        users[userList[id]].income = users[userList[id]].income + pay_autopool;
        users[userList[id]].autoPoolPayReceived = users[userList[id]].autoPoolPayReceived + 1;
        if(id==1){
            ownerPaid = true;
        }            
        if(sent){
            if(h==2){ 
                  token.unfreezeToken(nextLevel);
                  if(isTokenAcceptance){
                    tokenAcceptType = "ERC-20-COIN";
                }else{

                }
                 emit autoPoolEvent("Auto-Pool Payment Successful",_user,nextLevel,h,now,tokenAcceptType );
            }
            else{
                if(isTokenAcceptance){
                    tokenAcceptType = "ERC-20-COIN";
                }else{

                }
                emit autoPoolEvent("Auto-Pool Payment Successful",_user,nextLevel,h,now,tokenAcceptType);
            }
        }
        id = users[users[userList[id]].autopoolPayReciever].id;
        heightPayment(_user,batch,id,h+1);
    }else{
            if((h > 2 && h <= height) && users[userList[id]].referredUsers>=1 
            && (id > 0 && ownerPaid!=true)){
                address nextLevel = userList[id];
                if(!isTokenAcceptance){
                sent = address(uint160(nextLevel)).send(pay_autopool); 
                }
                else{
                  sent = token.transferFrom(msg.sender,address(uint160(nextLevel)),pay_autopool);  
                }  
                users[userList[id]].income = users[userList[id]].income + pay_autopool;
                users[userList[id]].autoPoolPayReceived = users[userList[id]].autoPoolPayReceived + 1;
                if(id==1){
                    ownerPaid = true;
                }   
                if(sent){
                      if(h==2){ 
                        token.unfreezeToken(nextLevel);
                        if(isTokenAcceptance){
                            tokenAcceptType = "ERC-20-COIN";
                        }else{
        
                        }
                         emit autoPoolEvent("Auto-Pool Payment Successful",_user,nextLevel,h,now,tokenAcceptType);
                            }
                            else{
                                if(isTokenAcceptance){
                                    tokenAcceptType = "ERC-20-COIN";
                                }else{
                
                                }
                              emit autoPoolEvent("Auto-Pool Payment Successful",_user,nextLevel,h,now,tokenAcceptType);
                            }
                }
                id = users[users[userList[id]].autopoolPayReciever].id;
                heightPayment(_user,batch,id,h+1);   
            }
            else if(id>0 && h<=height && ownerPaid!=true){
                if(id==1){
                    ownerPaid = true;
                }
                users[userList[id]].missedPoolPayment = users[userList[id]].missedPoolPayment +1;
                id = users[users[userList[id]].autopoolPayReciever].id;
                heightPayment(_user,batch,id,h+1);
            }
    }
    }
function autoPool(address _user) internal {
    bool sent = false;
    ownerPaid = false;
    uint i;  
    for(i = 1; i < currUserID; i++){
        if(users[userList[i]].batchPaid < batchSize){
           if(!isTokenAcceptance){
            sent = address(uint160(userList[i])).send(pay_autopool); 
           }
            else{
                sent = token.transferFrom(msg.sender,address(uint160(userList[i])),pay_autopool);  
            }    
            users[userList[i]].batchPaid = users[userList[i]].batchPaid + 1;
            users[_user].autopoolPayReciever = userList[i];
            users[userList[i]].income = users[userList[i]].income + pay_autopool;
            users[userList[i]].autoPoolPayReceived = users[userList[i]].autoPoolPayReceived + 1;
            
            if(sent){
                if(isTokenAcceptance){
                    tokenAcceptType = "ERC-20-COIN";
                }else{

                }
                emit autoPoolEvent("Auto-Pool Payment Successful",_user,userList[i],1,now,tokenAcceptType);
            }
                
            uint heightCounter = 2;
            uint  temp = users[users[userList[i]].autopoolPayReciever].id;
            heightPayment(_user,i,temp,heightCounter);
            i = currUserID;    
        }
    }
    }
function findReferrerGeneration(address _first_ref, address _current_user) internal view returns(uint) {
    uint i;
    address _user;
    uint generation = 1;
    _user = _current_user;
    for(i = 1; i < currUserID; i++){
        address referrer = userList[users[_user].referrerID];
        if (referrer != _first_ref) {
            _user = referrer;
            generation++;
        } else {
            return generation;
        }
    }
    }

function payReferral(uint _level, address _user) internal {
    address referer;
    referer = userList[users[_user].referrerID];
        bool sent = false;
        uint level_price_local=0;
        if(_level>2){
        level_price_local=unlimited_level_price;
        }
        else{
        level_price_local=LEVEL_PRICE[_level];
        }
        if(!isTokenAcceptance){
        sent = address(uint160(referer)).send(level_price_local);
        }else{
          sent = token.transferFrom(msg.sender,address(uint160(referer)),level_price_local);  
        }  
        users[referer].levelIncomeReceived = users[referer].levelIncomeReceived +1; 
        users[userList[users[_user].referrerID]].income = users[userList[users[_user].referrerID]].income + level_price_local;
        if (sent) {
            if(isTokenAcceptance){
                tokenAcceptType = "ERC-20-COIN";
            }else{
            }
            emit getMoneyForLevelEvent(referer, msg.sender, _level, now, tokenAcceptType);
            if(_level < 20 && users[referer].referrerID >= 1){
                payReferral(_level+1,referer);
            }
            else
            {
                sendBalance();
            }
        }
    if(!sent) {
        //  emit lostMoneyForLevelEvent(referer, msg.sender, _level, now);
        payReferral(_level, referer);
    }
    }
function gettrxBalance() public view returns(uint) {
   return address(this).balance;
}
function sendBalance() private{
        users[ownerWallet].income = users[ownerWallet].income + gettrxBalance();
        if(!isTokenAcceptance){
        if (!address(uint160(ownerWallet)).send(gettrxBalance())){

         }
        }else{
            if (!token.transferFrom(msg.sender,address(uint160(ownerWallet)),gettrxBalance())){

             }  
        }
}

function currentTokenAccepting()public view returns(string memory){
 if(isTokenAcceptance){
     return "ERC20-Token-Accepting";
 }else{
    return "Native-Coin-Accepting";
 }
}
}


// File contracts/Greeter.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;


contract Greeter {
    string private greeting;

    constructor(string memory _greeting)public {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}