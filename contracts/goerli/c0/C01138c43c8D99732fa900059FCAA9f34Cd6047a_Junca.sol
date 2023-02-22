// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


import "./Context.sol";
import "./user.sol";

contract Access is Context{
    using Users for Users.User;
    Users.User private _authorizer;
    
    event AuthorizerAdded(address indexed account);
    event AuthorizerDeleted(address indexed account);
    
    constructor() {
        _addAdmin(_msgSender());
    }
    
    modifier isAuthorizer() {
        require(_authorizer.exists(_msgSender()), "Access: Caller does not Authorizer");
        _;
    }
    
    function addAdmin(address account) external isAuthorizer {
        _addAdmin(account);
    }
    
    function delAdmin(address account) external isAuthorizer {
        _delAdmin(account);
    }
    
    function _addAdmin(address account) internal {
        _authorizer.add(account);
        emit AuthorizerAdded(account);
    }
    
    function _delAdmin(address account) internal {
        _authorizer.del(account);
        emit AuthorizerDeleted(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
    constructor() { }

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./access.sol";
import "./pausable.sol";


contract Junca is IERC20, Access, Pausable {
    using SafeMath for uint256;
    
    string private _name = "junca cash";
    string private _symbol = "JGCT";
    uint8 private _decimals = 18;

    uint256 private _totalSupply;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    constructor() {
        uint256 amount = 130000000 * (uint256(10) ** decimals());
        _mint(_msgSender(), amount);
    }
    
    function totalSupply() override public view returns (uint256) {
        return _totalSupply;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function balanceOf(address account) override public view returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) override public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transfer(address recipient, uint256 amount) override public notPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) override public notPaused returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "JCC: transfer amount exceeds allows"));
        return true;
    }
    
    function approve(address spender, uint256 amount) override public notPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 sumValue) public notPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(sumValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subValue) public notPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subValue, "JCC: decreased allowance zero value"));
        return true;
    }
    
    function mint(address account, uint256 amount) public isAuthorizer returns (bool) {
        _mint(account, amount);
        return true;
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "JCC: transfer from zero address");
        require(recipient != address(0), "JCC: transfer to zero address");
        
        _balances[sender] = _balances[sender].sub(amount, "JCC: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "JCC: approve from zero address");
        require(spender != address(0), "JCC: approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "JCC: mint to zero address");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "JCC: burn from the zero address");
        
        _balances[account] = _balances[account].sub(amount, "JCC: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        
        emit Transfer(account, address(0), amount);
    }
    
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(_msgSender(), account, amount);
    }

    function destruct() public isPaused isAuthorizer { 
        selfdestruct(payable(msg.sender)); 
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./pauser.sol";

contract Pausable is Pauser {
    bool private _stats;
    
    event Paused(address account);
    event unPaused(address account);
    
    constructor() {
        _stats = false;
    }
    
    function isPause() public view returns (bool) {
        return _stats;
    }
    
    modifier notPaused() {
        require(!_stats, "paused.");
        _;
    }
    
    modifier isPaused() {
        require(_stats, "not paused.");
        _;
    }
    
    function pause() public isPauser notPaused {
        _stats = true;
        emit Paused(_msgSender());
    }
    
    function unpause() public isPauser isPaused {
        _stats = false;
        emit unPaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Context.sol";
import "./user.sol";


contract Pauser is Context {
    using Users for Users.User;
    Users.User private _pauser;
    
    event PasuserAdded(address indexed account);
    event PauserDeleted(address indexed account);
    
    constructor() {
        _addPauser(_msgSender());
    }
    
    modifier isPauser() {
        require(_pauser.exists(_msgSender()));
        _;
    }
    
    function addPauser(address account) public isPauser {
        _addPauser(account);
    }
    
    function delPauser(address account) public isPauser {
        _delPauser(account);
    }
    
    function _addPauser(address account) internal {
        _pauser.add(account);
        emit PasuserAdded(account);
    }
    
    function _delPauser(address account) internal {
        _pauser.del(account);
        emit PauserDeleted(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Users {
    struct User {
        mapping (address => bool) authorizer;
    }
    
    function add(User storage admin, address account) internal {
        require(!exists(admin, account), "Admin: account has already");
        admin.authorizer[account] = true;
    }
    
    function del(User storage admin, address account) internal {
        require(exists(admin, account), "Admin: account does not authorizer");
        admin.authorizer[account] = false;
    }
    
    function exists(User storage admin, address account) internal view returns (bool) {
        require(account != address(0), "Admin: account is zero.");
        return admin.authorizer[account];
    }
}