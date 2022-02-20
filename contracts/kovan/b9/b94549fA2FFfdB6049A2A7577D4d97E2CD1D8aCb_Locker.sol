/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;



// Part: OpenZeppelin/[email protected]/IERC20

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

// File: Locker.sol

// lock coins for some amount of time
// TODO: pay a premium if you want them back sooner
contract Locker {

  address public owner;

  // represent a deposit into the locker
  // track the token, amount, the length of lock, and when it was locked
  struct Deposit {
    address user;
    address token;
    uint256 id;
    uint256 amount;
    uint256 duration;
    uint256 timestamp;
    bool unlocked;
  }

  Deposit[] public userDeposits; // deprecated

  uint256 public earlyExitPenalty = 3; // default

  // track deposits by token -> user -> deposits
  mapping(address => 
    mapping(address => Deposit[])
  ) public deposits;

  // track the locked balance. token -> user -> balance
  mapping(address => mapping(address => uint256)) public lockedBalance;

  event NewDeposit(Deposit);
  event GotDeposits(Deposit[]);
  event DepositNotUnlocked(Deposit);
  event ResultNotFound(Deposit);
  event UpdatedAmount(uint256);
  event GotDeposit(Deposit);
  event FinalEligibleAmount(uint256);

  constructor (uint256 _earlyExitPenalty) {
    if (_earlyExitPenalty != 0) {
      earlyExitPenalty = _earlyExitPenalty;
    }

    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setEarlyExitPenalty (uint256 _penalty) public onlyOwner {
    earlyExitPenalty = _penalty;
  }
  
  function getUserDeposits (address _user, address _token) public view returns(Deposit[] memory) {
    return deposits[_token][_user];
  }

  function getBlockTimestamp () public view returns(uint256) {
    return block.timestamp;
  }

  function getBalance (address _user, address _token) public view returns (uint256) {
    return IERC20(_token).balanceOf(_user);
  }

  function deposit(address token, uint256 amount, uint256 duration) public {
    
    require(amount > 0, "Amount cannot be 0");
    require(duration > 0, "Duration cannot be 0");
    require(getBalance(msg.sender, token) >= amount, "Not enough tokens");

    IERC20(token).transferFrom(msg.sender, address(this), amount);
    lockedBalance[token][msg.sender] += amount;

    Deposit memory newDeposit = Deposit({
      id: deposits[token][msg.sender].length,
      user: msg.sender,
      token: token,
      amount: amount,
      duration: duration, 
      timestamp: block.timestamp,
      unlocked: false
    });

    deposits[token][msg.sender].push(newDeposit);

    emit NewDeposit(newDeposit);
  }

  function withdraw (address _token, uint256 _amount) public {

    require(_amount > 0, "Amount cannot be 0");

    uint256 unlockedAmount = amountEligibleForWithdrawal(msg.sender, _token);

    require(
      _amount <= unlockedAmount, 
      "Amount requested exceeds unlocked amount"
    );

    IERC20(_token).transfer(msg.sender, _amount);
    lockedBalance[_token][msg.sender] -= _amount;

    // TODO: figure out a way to clean up the deposits list
  }

  function isUnlocked(Deposit memory _deposit) public view returns (bool) {
    return (block.timestamp - _deposit.timestamp) >= _deposit.duration;
  }

  // function getBlockTimestamp () public view returns (uint256) {
  //   return block.timestamp;
  // }

  function amountEligibleForWithdrawal (address _user, address _token) public view returns (uint256) {
    uint256 eligibleAmount = 0;

    Deposit[] storage _deposits = deposits[_token][_user]; // getUserDeposits(_user, _token);

    // emit GotDeposits(_deposits);

    for (uint256 i = 0; i < _deposits.length; i++) {
      Deposit storage _deposit = _deposits[i];
      // emit GotDeposit(_deposit);
      if (!_deposit.unlocked && _deposit.token == _token && _deposit.user == _user) {
        if (isUnlocked(_deposit)) {
          eligibleAmount += _deposit.amount;
          //emit UpdatedAmount(eligibleAmount);
        } else {
          //emit DepositNotUnlocked(_deposit);
        }
      } else {
        //emit ResultNotFound(_deposit);
      }

      // eligibleAmount = _deposit.amount;
    }

    // if the total amount from unlocked deposits exceeds their currently deposited balance
    // all of it is eligible
    uint256 finalAmount = eligibleAmount >= lockedBalance[_token][_user] 
            ? lockedBalance[_token][_user] 
            : eligibleAmount;

    // emit FinalEligibleAmount(finalAmount);

    return finalAmount; // eligibleAmount;
  }

  function calculateExitPenalty (uint256 _amount, uint256 _earlyExitPenalty) pure public returns (uint256) {
    return _amount * _earlyExitPenalty / 100; 
  }

  function getDepositById (address _token, address _user, uint256 _depositId) public view returns(Deposit memory, uint256) {
    Deposit[] storage _deposits = deposits[_token][_user];

    Deposit memory _deposit;
    uint256 _depositIndex;

    for (uint256 i = 0; i < _deposits.length; i++){
      if (_deposits[i].id == _depositId){
        _deposit = _deposits[i];
        _depositIndex = i;
        break;
      }
    }

    return (_deposit, _depositIndex);
  }

  function withdrawWithPenalty (address _token, uint256 _amount, uint256 _depositId) public {
    // Deposit[] storage _deposits = deposits[_token][msg.sender];

    // Deposit memory _deposit;
    // uint256 _depositIndex;

    // for (uint256 i = 0; i < _deposits.length; i++){
    //   if (_deposits[i].id == _depositId){
    //     _deposit = _deposits[i];
    //     _depositIndex = i;
    //     break;
    //   }
    // }

    Deposit memory _deposit;
    uint256 _depositIndex;

    (_deposit, _depositIndex) = getDepositById(_token, msg.sender, _depositId);

    require(_deposit.amount != 0, "Deposit not found.");

    uint256 depositAmount = _deposit.amount;

    require(_amount <= depositAmount, "Can't withdraw more than the deposit amount");

    uint256 timeLeft = _deposit.duration - (block.timestamp - _deposit.timestamp);

    require(timeLeft > 0, "This deposit is alread unlocked?");

    uint256 penalty = calculateExitPenalty(_amount, earlyExitPenalty);

    IERC20(_token).transfer(msg.sender, _amount - penalty);

    lockedBalance[_token][msg.sender] -= _amount; // subtract requested amount and contract keeps their penalty

    Deposit[] storage _deposits = deposits[_token][msg.sender];
    
    if (_amount == depositAmount) {
        _deposits[_depositIndex] = _deposits[_deposits.length - 1];
        _deposits.pop();
    } else {
      _deposit.amount -= _amount; // update the balance of the deposit
    }
  }         
}