/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
This is Context Contract.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/utils/Context.sol
*/

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
/*
This is Ownable Contract.
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/solc-0.6/contracts/access/Ownable.sol
*/

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

/*
This is contract for IERC20
*/

interface IERC20 {

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
 * @dev Returns the ERC token owner.
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
This is SafeMath Contract
*/

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

/*
This is SafeERC20 Contract.
*/


/** 
* @dev Library to perform safe calls to standard method for ERC20 tokens.
*
* Why Transfers: transfer methods could have a return value (bool), throw or revert for insufficient funds or
* unathorized value.
*
* Why Approve: approve method could has a return value (bool) or does not accept 0 as a valid value (BNB token).
* The common strategy used to clean approvals.
*
* We use the Solidity call instead of interface methods because in the case of transfer, it will fail
* for tokens with an implementation without returning a value.
* Since versions of Solidity 0.4.22 the EVM has a new opcode, called RETURNDATASIZE.
* This opcode stores the size of the returned data of an external call. The code checks the size of the return value
* after an external call and reverts the transaction in case the return data is shorter than expected
*/
library SafeERC20 {
    /**
    * @dev Transfer token for a specified address
    * @param _token erc20 The address of the ERC20 contract
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    * @return bool whether the transfer was successful or not
    */
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        if (prevBalance < _value) {
            // Insufficient funds
            return false;
        }

        address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _value)
        );

        // Fail if the new balance its not equal than previous balance sub _value
        return prevBalance - _value == _token.balanceOf(address(this));
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _token erc20 The address of the ERC20 contract
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    * @return bool whether the transfer was successful or not
    */
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool)
    {
        uint256 prevBalance = _token.balanceOf(_from);

        if (
          prevBalance < _value || // Insufficient funds
          _token.allowance(_from, address(this)) < _value // Insufficient allowance
        ) {
            return false;
        }

        address(_token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value)
        );

        // Fail if the new balance its not equal than previous balance sub _value
        return prevBalance - _value == _token.balanceOf(_from);
    }

   /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @return bool whether the approve was successful or not
   */
    function safeApprove(IERC20 _token, address _spender, uint256 _value) internal returns (bool) {
        address(_token).call(
            abi.encodeWithSignature("approve(address,uint256)",_spender, _value)
        );

        // Fail if the new allowance its not equal than _value
        return _token.allowance(address(this), _spender) == _value;
    }

   /**
   * @dev Clear approval
   * Note that if 0 is not a valid value it will be set to 1.
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   */
    function clearApprove(IERC20 _token, address _spender) internal returns (bool) {
        bool success = safeApprove(_token, _spender, 0);

        if (!success) {
            success = safeApprove(_token, _spender, 1);
        }

        return success;
    }
}

/*
This is ERC20 Contract
*/

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, Ownable {
 using SafeMath for uint256;

 mapping(address => uint256) private _balances;

 mapping(address => mapping(address => uint256)) private _allowances;

 uint256 private _totalSupply;

 string private _name;
 string private _symbol;
 uint8 private _decimals;

 /**
 * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
 * a default value of 18.
 *
 * To select a different value for {decimals}, use {_setupDecimals}.
 *
 * All three of these values are immutable: they can only be set once during
 * construction.
 */
 constructor(string memory name, string memory symbol) public {
 _name = name;
 _symbol = symbol;
 _decimals = 18;
 }

 /**
 * @dev Returns the ERC token owner.
 */
 function getOwner() external override view returns (address) {
 return owner();
 }

 /**
 * @dev Returns the name of the token.
 */
 function name() public override view returns (string memory) {
 return _name;
 }

 /**
 * @dev Returns the symbol of the token, usually a shorter version of the
 * name.
 */
 function symbol() public override view returns (string memory) {
 return _symbol;
 }

 /**
 * @dev Returns the number of decimals used to get its user representation.
 */
 function decimals() public override view returns (uint8) {
 return _decimals;
 }

 /**
 * @dev See {ERC20-totalSupply}.
 */
 function totalSupply() public override view returns (uint256) {
 return _totalSupply;
 }

 /**
 * @dev See {ERC20-balanceOf}.
 */
 function balanceOf(address account) public override view returns (uint256) {
 return _balances[account];
 }

 /**
 * @dev See {ERC20-transfer}.
 *
 * Requirements:
 *
 * - `recipient` cannot be the zero address.
 * - the caller must have a balance of at least `amount`.
 */
 function transfer(address recipient, uint256 amount) public override returns (bool) {
 _transfer(_msgSender(), recipient, amount);
 return true;
 }

 /**
 * @dev See {ERC20-allowance}.
 */
 function allowance(address owner, address spender) public override view returns (uint256) {
 return _allowances[owner][spender];
 }

 /**
 * @dev See {ERC20-approve}.
 *
 * Requirements:
 *
 * - `spender` cannot be the zero address.
 */
 function approve(address spender, uint256 amount) public override returns (bool) {
 _approve(_msgSender(), spender, amount);
 return true;
 }

 /**
 * @dev See {ERC20-transferFrom}.
 *
 * Emits an {Approval} event indicating the updated allowance. This is not
 * required by the EIP. See the note at the beginning of {ERC20};
 *
 * Requirements:
 * - `sender` and `recipient` cannot be the zero address.
 * - `sender` must have a balance of at least `amount`.
 * - the caller must have allowance for `sender`'s tokens of at least
 * `amount`.
 */
 function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
 _transfer(sender, recipient, amount);
 _approve(
 sender,
 _msgSender(),
 _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
 );
 return true;
 }

 /**
 * @dev Atomically increases the allowance granted to `spender` by the caller.
 *
 * This is an alternative to {approve} that can be used as a mitigation for
 * problems described in {ERC20-approve}.
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
 * problems described in {ERC20-approve}.
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
 _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero'));
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
 function _transfer (address sender, address recipient, uint256 amount) internal {
 require(sender != address(0), 'ERC20: transfer from the zero address');
 require(recipient != address(0), 'ERC20: transfer to the zero address');

 _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
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
 require(account != address(0), 'ERC20: mint to the zero address');

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
 require(account != address(0), 'ERC20: burn from the zero address');

 _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
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
 function _approve (address owner, address spender, uint256 amount) internal {
 require(owner != address(0), 'ERC20: approve from the zero address');
 require(spender != address(0), 'ERC20: approve to the zero address');

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
 _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'ERC20: burn amount exceeds allowance'));
 }
}

/*
Apple Token Contract
*/

//APPLEToken is the reward token for MasterChef.
contract AppleToken is ERC20('Apple Token', 'APPLE') {
//Mints '_amount' of AppleToken to '_to'. This function can only be called by owner (Masterchef).
 function mint(address _to, uint256 _amount) public onlyOwner {
 _mint(_to, _amount);
 }
}

/*
This MasterChef was forked from PancakeSwap and is written to use in test projects.
USE AT YOUR OWN RISK!!!!!

MasterChef is the master of Apples. He can make Apples and he is a fair guy.
This contract is ownable and this version has no governece and hence no plan to relinquish that ownership power.
The owner holds tremendous power.
*/

contract AppleMasterChef is Ownable {
 using SafeMath for uint256;
 using SafeERC20 for IERC20;

/*
Info for each user. 

The exludedReward is calculated as follows whenever a user deposits or withdraws LP tokens.
1. Pool's accApplePerShare and lastRewardBlock are updated.
2. User recieves pending award sent to their address. Always recieves total amount pending because rewardRate for new total may differ.
3. User's amount is updated. (Increases if depositing and decreases if withdrawing.)
4. User's excludedReward is updated. (Namely it excludes all rewards obtained until block after the deposit or withdrawl.)
*/

 struct UserInfo {
 uint256 amount; // # LP tokens user has depositied in contract.
 uint256 excludedReward; // Amount of the total appleRewards that user is not entitled to. (Entered contract after those rewards)
 }

 
 /*
 Info for each pool
 */
 struct PoolInfo {
 IERC20 lpToken; // Address of LP token contract.
 uint256 allocPoint; // How many allocation points assigned to this pool. Used to determine percent Apples to send per block
 uint256 lastRewardBlock; // Last block number of Apple distribution.
 uint256 accApplePerShare; // Total Accumulated Apples per share in pool, times 1e12. See below.
 uint16 depositFeeBP; // Deposit fee in basis points
 }

 AppleToken public apple; // The Apple TOKEN!

 address public devaddr; // Dev address.
 address public feeAddress; // Deposit Fee address

 uint256 public applePerBlock; // Apples tokens created per block.
 uint256 public constant BONUS_MULTIPLIER = 1; // Bonus muliplier for early apple makers.


 PoolInfo[] public poolInfo; // Info of each pool.

 // Info of each user that stakes LP tokens. userInfo[which LP][which user]
 mapping (uint256 => mapping (address => UserInfo)) public userInfo;

 uint256 public totalAllocPoint = 0; // Total allocation points. Must be the sum of all allocation points in all pools.
 uint256 public startBlock; // The block number when apple mining starts.

 event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
 event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
 event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

 constructor(
 AppleToken _apple,
 address _devaddr,
 address _feeAddress,
 uint256 _applePerBlock,
 uint256 _startBlock
 ) public {
 apple = _apple;
 devaddr = _devaddr;
 feeAddress = _feeAddress;
 applePerBlock = _applePerBlock;
 startBlock = _startBlock;
 }

/*
 Gives the total number of pools in staking contract.
*/
 function poolLength() external view returns (uint256) {
 return poolInfo.length;
 }


/*
 Adds a new lp to the pool. Can only be called by the owner.
 XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do. 

 Inputs _allocPoint is value so percentage rewards you want for pool = _allocPoint/totalAllocPoint.
 _lpToken is lpToken you want new LP pool for.
 _depositFeeBP is the deposit fee you want to charge each time in basis points.
 _withUpdate is a bool. Choose 1 if you want to massUpdate all pools and 0 if you dont want to update pools.
*/
 function add(uint256 _allocPoint, IERC20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
 require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
 if (_withUpdate) {
 massUpdatePools();
 }
 uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
 totalAllocPoint = totalAllocPoint.add(_allocPoint);
 poolInfo.push(PoolInfo({
 lpToken: _lpToken,
 allocPoint: _allocPoint,
 lastRewardBlock: lastRewardBlock,
 accApplePerShare: 0,
 depositFeeBP: _depositFeeBP
 }));
 }


/*
Updates the given pool's apple allocation point and deposit fee. Can only be called by the owner.
Inputs: _pid is pool you want to update.
_allocPoint is new allocation points want pool to have.
_depositFeeBP is new deposit fee in basis points.
_withUpdate is a bool. Choose 1 if want to massUpdatePools and 0 if not.
*/
 
 function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
 require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
 if (_withUpdate) {
 massUpdatePools();
 }
 totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
 poolInfo[_pid].allocPoint = _allocPoint;
 poolInfo[_pid].depositFeeBP = _depositFeeBP;
 }

/*
 Returns the reward multiplier over the given _from to _to block.
*/
 function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
 return _to.sub(_from).mul(BONUS_MULTIPLIER);
 }

/*
 Function that calculates pending apples for _user from rewards from staking _pid.
*/
 function pendingApple(uint256 _pid, address _user) external view returns (uint256) {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][_user];
 uint256 accApplePerShare = pool.accApplePerShare;
 uint256 lpSupply = pool.lpToken.balanceOf(address(this));
 if (block.number > pool.lastRewardBlock && lpSupply != 0) {
 uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
 uint256 appleReward = multiplier.mul(applePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
 accApplePerShare = accApplePerShare.add(appleReward.mul(1e12).div(lpSupply));
 }
 return user.amount.mul(accApplePerShare).div(1e12).sub(user.excludedReward);
 }

/*
 Updates reward variables for all pools. Be careful of gas spending!
*/
 function massUpdatePools() public {
 uint256 length = poolInfo.length;
 for (uint256 pid = 0; pid < length; ++pid) {
 updatePool(pid);
 }
 }

 /*
 Updates reward variables of _pid to be up-to-date.
 */
 function updatePool(uint256 _pid) public {
 PoolInfo storage pool = poolInfo[_pid];
 if (block.number <= pool.lastRewardBlock) {
 return;
 }
 uint256 lpSupply = pool.lpToken.balanceOf(address(this));
 if (lpSupply == 0 || pool.allocPoint == 0) {
 pool.lastRewardBlock = block.number;
 return;
 }
 uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
 uint256 appleReward = multiplier.mul(applePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
 //apple.mint(devaddr, appleReward.div(10)); If you want to pay a devFee, can uncomment this.
 apple.mint(address(this), appleReward);
 pool.accApplePerShare = pool.accApplePerShare.add(appleReward.mul(1e12).div(lpSupply));
 pool.lastRewardBlock = block.number;
 }

/*
 Deposits LP tokens to MasterChef to earn apples.
 When a user deposits, first pool is updated and all pendingRewards are transferred. 
 This is because if there is already some amount deposited, the new total amount will have a different reward rate.
 So you must pay out the pending rewards which then changes excludedRewards to exclude all rewards until next block.
*/

 function deposit(uint256 _pid, uint256 _amount) public {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][msg.sender];
 require(pool.lpToken.balanceOf(msg.sender) >= _amount, "not enough lp tokens");
 updatePool(_pid);
 if (user.amount > 0) {
 uint256 pending = user.amount.mul(pool.accApplePerShare).div(1e12).sub(user.excludedReward);
 if(pending > 0) {
 safeAppleTransfer(msg.sender, pending);
 }
 }
 if(_amount > 0) {
 pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
 if(pool.depositFeeBP > 0){
 uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
 pool.lpToken.safeTransfer(feeAddress, depositFee);
 user.amount = user.amount.add(_amount).sub(depositFee);
 }else{
 user.amount = user.amount.add(_amount);
 }
 }
 //at time of deposit, record accApplePerShare so can be subtracted away from rewards later
 user.excludedReward = user.amount.mul(pool.accApplePerShare).div(1e12);
 emit Deposit(msg.sender, _pid, _amount);
 }

/*
 Withdraws msg.sender's LP tokens from MasterChef and also transfers all pendingRewards to msg.sender.
*/

 function withdraw(uint256 _pid, uint256 _amount) public {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][msg.sender];
 require(user.amount >= _amount, "withdraw: withdrawal amount cannot exceed user pool balance");
 updatePool(_pid);
 uint256 pending = user.amount.mul(pool.accApplePerShare).div(1e12).sub(user.excludedReward);
 if(pending > 0) {
 safeAppleTransfer(msg.sender, pending);
 }
 if(_amount > 0) {
 user.amount = user.amount.sub(_amount);
 pool.lpToken.safeTransfer(address(msg.sender), _amount);
 }
 user.excludedReward= user.amount.mul(pool.accApplePerShare).div(1e12);
 emit Withdraw(msg.sender, _pid, _amount);
 }

/*
 Withdraws msg.senders lp tokens without caring about rewards. EMERGENCY ONLY.
*/

 function emergencyWithdraw(uint256 _pid) public {
 PoolInfo storage pool = poolInfo[_pid];
 UserInfo storage user = userInfo[_pid][msg.sender];
 uint256 amount = user.amount;
 user.amount = 0;
 user.excludedReward = 0;
 pool.lpToken.safeTransfer(address(msg.sender), amount);
 emit EmergencyWithdraw(msg.sender, _pid, amount);
 }

/*
 Safe apple transfer function, just in case if rounding error causes pool to not have enough apples.
*/

 function safeAppleTransfer(address _to, uint256 _amount) internal {
 uint256 appleBal = apple.balanceOf(address(this));
 if (_amount > appleBal) {
 apple.transfer(_to, appleBal);
 } else {
 apple.transfer(_to, _amount);
 }
 }

/*
 Updates dev address by the previous dev.
*/

 function dev(address _devaddr) public {
 require(msg.sender == devaddr, "dev: wut?");
 devaddr = _devaddr;
 }

 function setFeeAddress(address _feeAddress) public{
 require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
 feeAddress = _feeAddress;
 }

/*
 Updates Emmission Rate
*/

 function updateEmissionRate(uint256 _applePerBlock) public onlyOwner {
 massUpdatePools();
 applePerBlock = _applePerBlock;
 }
}