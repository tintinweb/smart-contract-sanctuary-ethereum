/**
 *Submitted for verification at Etherscan.io on 2022-03-21
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

// Part: OpenZeppelin/[email protected]/ReentrancyGuard

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
     * by making the `nonReentrant` function external, and make it call a
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

// File: Locker.sol

// lock coins for some amount of time
// TODO: pay a premium if you want them back sooner
contract Locker is ReentrancyGuard {

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

  struct Balance {
    uint256 locked;
    uint256 nextUnlockIndex;
  }

  Deposit[] public userDeposits; // deprecated

  uint256 public earlyExitPenalty = 3; // default

  // track deposits by token -> user -> deposits
  mapping(address => 
    mapping(address => Deposit[])
  ) public deposits;

  // track the locked balance. token -> user -> balance
  mapping(address => mapping(address => Balance)) public lockedBalance;

  event NewDeposit(Deposit deposit);
  event Withdraw(Deposit deposit, uint256 amount);
  // event WithdrawAllDeposits(Deposit[]);
  event NotUnlocked(uint256 blocktimestamp, uint256 unlocktime);
  // event ProcessingDeposit(uint256 duration, uint256 timestamp);
  // event Deposited(uint256);
  // event UnlockTime(uint256);
  // event Blocktime(uint256);
  event UnlockedAmount(uint256 amount);
  event NextUnlockIndex(uint256 unlockIndex);

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

  function getBalance (address _user, address _token) public view returns (uint256) {
    return IERC20(_token).balanceOf(_user);
  }

  function deposit(address token, uint256 amount, uint256 duration) public {
    
    require(amount > 0, "Amount cannot be 0");
    require(duration > 0, "Duration cannot be 0");
    require(getBalance(msg.sender, token) >= amount, "Not enough tokens");

    IERC20(token).transferFrom(msg.sender, address(this), amount);
    lockedBalance[token][msg.sender].locked += amount;

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

  function withdrawAllUnlocked (address _token) public nonReentrant {
    uint256 unlockedAmount = amountEligibleForWithdrawal(msg.sender, _token);
    emit UnlockedAmount(unlockedAmount);
    uint256 unlocked;
    Deposit[] memory _deposits = deposits[_token][msg.sender];
    uint256 nextUnlockIndex = lockedBalance[_token][msg.sender].nextUnlockIndex;
    
    // emit WithdrawAllDeposits(_deposits);
    emit NextUnlockIndex(nextUnlockIndex);

    for (uint i = nextUnlockIndex; i < _deposits.length; i++){
      Deposit memory _deposit = _deposits[i];
      // emit Deposited(_deposit.timestamp);
      // emit ProcessingDeposit(_deposit.duration, _deposit.timestamp);
      // emit UnlockTime(_deposit.timestamp + _deposit.duration);
      // emit Blocktime(block.timestamp);
      uint256 unlockTime = _deposit.timestamp + _deposit.duration;
      if (unlockTime <= block.timestamp) {
        unlocked += _deposit.amount;
        nextUnlockIndex++;

      } else {
        emit NotUnlocked(block.timestamp, _deposit.timestamp + _deposit.duration);
      }
    }

    // require(unlocked > 0, "Nothing unlocked");
    
    IERC20(_token).transfer(msg.sender, unlocked);

    lockedBalance[_token][msg.sender].nextUnlockIndex = nextUnlockIndex;
    lockedBalance[_token][msg.sender].locked -= unlocked;
  }

  function withdraw (address _token, uint256 _amount, uint256 _depositId) public nonReentrant {

    require(_amount > 0, "Amount cannot be 0");

    uint256 unlockedAmount = amountEligibleForWithdrawal(msg.sender, _token);

    require(
      _amount <= unlockedAmount, 
      "Amount requested exceeds unlocked amount"
    );

    Deposit memory _deposit;
    uint256 _depositIndex;

    (_deposit, _depositIndex) = getDepositById(_token, msg.sender, _depositId);

    require(_deposit.user == msg.sender, "Can't withdraw for another user");
    require(_deposit.amount != 0, "Deposit not found.");

    uint256 depositAmount = _deposit.amount;

    require(_amount <= depositAmount, "Can't withdraw more than the deposit amount");

    IERC20(_token).transfer(msg.sender, _amount);
    lockedBalance[_token][msg.sender].locked -= _amount;

    // TODO: figure out a way to clean up the deposits list
    Deposit[] storage _deposits = deposits[_token][msg.sender];
    
    if (_amount == depositAmount) {
        _deposits[_depositIndex] = _deposits[_deposits.length - 1];
        _deposits.pop();
    } else {
      _deposit.amount -= _amount; // update the balance of the deposit
    }

    emit Withdraw(_deposit, _amount);
  }

  function isUnlocked(Deposit memory _deposit) internal view returns (bool) {
    return block.timestamp - _deposit.timestamp >= _deposit.duration;
  }

  function amountEligibleForWithdrawal (address _user, address _token) public view returns (uint256) {
    uint256 eligibleAmount = 0;

    Deposit[] memory _deposits = getUserDeposits(_user, _token);
    Balance memory _balance = lockedBalance[_token][_user];

    for (uint256 i = _balance.nextUnlockIndex; i < _deposits.length; i++) {
      Deposit memory _deposit = _deposits[i];
      if (!_deposit.unlocked && _deposit.token == _token && _deposit.user == _user) {
        if (isUnlocked(_deposit)) {
          eligibleAmount += _deposit.amount;
        }
      }
    }

    // if the total amount from unlocked deposits exceeds their currently deposited balance
    // all of it is eligible
    return eligibleAmount >= lockedBalance[_token][_user].locked
            ? lockedBalance[_token][_user].locked
            : eligibleAmount;
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

  function withdrawWithPenalty (address _token, uint256 _amount, uint256 _depositId) public nonReentrant {

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

    lockedBalance[_token][msg.sender].locked -= _amount; // subtract requested amount and contract keeps their penalty

    Deposit[] storage _deposits = deposits[_token][msg.sender];
    
    if (_amount == depositAmount) {
        _deposits[_depositIndex] = _deposits[_deposits.length - 1];
        _deposits.pop();
    } else {
      _deposit.amount -= _amount; // update the balance of the deposit
    }
  }         
}