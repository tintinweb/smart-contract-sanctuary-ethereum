/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// File: https://github.com/Daichotomy/UpSideDai/blob/master/contracts/StableMath.sol

pragma solidity ^0.5.16;

/**
 * @title StableMath
 * @dev Accesses the Stable Math library using generic system wide variables for managing precision
 * Derives from OpenZeppelin's SafeMath lib
 */
library StableMath {
    /** @dev Scaling units for use in specific calculations */
    uint256 private constant fullScale = 1e18;

    /** @dev Getters */
    function getScale() internal pure returns (uint256) {
        return fullScale;
    }

    /** @dev Scaled a given integer to the power of the full scale. */
    function scale(uint256 a) internal pure returns (uint256 b) {
        return mul(a, fullScale);
    }

    /** @dev Returns the addition of two unsigned integers, reverting on overflow. */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "StableMath: addition overflow");
    }

    /** @dev Returns the subtraction of two unsigned integers, reverting on overflow. */
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a, "StableMath: subtraction overflow");
        c = a - b;
    }

    /** @dev Returns the multiplication of two unsigned integers, reverting on overflow. */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "StableMath: multiplication overflow");
    }

    /** @dev Multiplies two numbers and truncates */
    function mulTruncate(uint256 a, uint256 b, uint256 _scale)
        internal
        pure
        returns (uint256 c)
    {
        uint256 d = mul(a, b);
        c = div(d, _scale);
    }

    /** @dev Multiplies two numbers and truncates using standard full scale */
    function mulTruncate(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        return mulTruncate(a, b, fullScale);
    }

    /** @dev Returns the integer division of two unsigned integers */
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0, "StableMath: division by zero");
        c = a / b;
    }

    /** @dev Precisely divides two numbers, first by expanding */
    function divPrecisely(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        uint256 d = mul(a, fullScale);
        c = div(d, b);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/access/Roles.sol

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/access/roles/MinterRole.sol

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// File: https://github.com/Daichotomy/UpSideDai/blob/master/contracts/interfaces/IMakerMedianizer.sol

pragma solidity ^0.5.16;

interface IMakerMedianizer {
    function read() external view returns (bytes32);
}

// File: https://github.com/Daichotomy/UpSideDai/blob/master/contracts/interfaces/IUniswapExchange.sol

pragma solidity ^0.5.16;

contract IUniswapExchange {
    // Address of ERC20 token sold on this exchange
    function tokenAddress() external view returns (address token);
    // Address of Uniswap Factory
    function factoryAddress() external view returns (address factory);
    // Provide Liquidity
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);
    function removeLiquidity(
        uint256 amount,
        uint256 min_eth,
        uint256 min_tokens,
        uint256 deadline
    ) external returns (uint256, uint256);
    // Get Prices
    function getEthToTokenInputPrice(uint256 eth_sold)
        external
        view
        returns (uint256 tokens_bought);
    function getEthToTokenOutputPrice(uint256 tokens_bought)
        external
        view
        returns (uint256 eth_sold);
    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256 eth_bought);
    function getTokenToEthOutputPrice(uint256 eth_bought)
        external
        view
        returns (uint256 tokens_sold);
    // Trade ETH to ERC20
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        returns (uint256 tokens_bought);
    function ethToTokenTransferInput(
        uint256 min_tokens,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 tokens_bought);
    function ethToTokenSwapOutput(uint256 tokens_bought, uint256 deadline)
        external
        payable
        returns (uint256 eth_sold);
    function ethToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 deadline,
        address recipient
    ) external payable returns (uint256 eth_sold);
    // Trade ERC20 to ETH
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256 eth_bought);
    function tokenToEthTransferInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline,
        address recipient
    ) external returns (uint256 eth_bought);
    function tokenToEthSwapOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline
    ) external returns (uint256 tokens_sold);
    function tokenToEthTransferOutput(
        uint256 eth_bought,
        uint256 max_tokens,
        uint256 deadline,
        address recipient
    ) external returns (uint256 tokens_sold);
    // Trade ERC20 to ERC20
    function tokenToTokenSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_bought);
    function tokenToTokenTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_bought);
    function tokenToTokenSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address token_addr
    ) external returns (uint256 tokens_sold);
    function tokenToTokenTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address token_addr
    ) external returns (uint256 tokens_sold);
    // Trade ERC20 to Custom Pool
    function tokenToExchangeSwapInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_bought);
    function tokenToExchangeTransferInput(
        uint256 tokens_sold,
        uint256 min_tokens_bought,
        uint256 min_eth_bought,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_bought);
    function tokenToExchangeSwapOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address exchange_addr
    ) external returns (uint256 tokens_sold);
    function tokenToExchangeTransferOutput(
        uint256 tokens_bought,
        uint256 max_tokens_sold,
        uint256 max_eth_sold,
        uint256 deadline,
        address recipient,
        address exchange_addr
    ) external returns (uint256 tokens_sold);
    // ERC20 comaptibility for liquidity tokens
    bytes32 public name;
    bytes32 public symbol;
    uint256 public decimals;
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 value)
        external
        returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    // Never use
    function setup(address token_addr) external;
}

// File: https://github.com/Daichotomy/UpSideDai/blob/master/contracts/interfaces/IUniswapFactory.sol

pragma solidity ^0.5.16;

contract IUniswapFactory {
    // Public Variables
    address public exchangeTemplate;
    uint256 public tokenCount;
    // Create Exchange
    function createExchange(address token) external returns (address exchange);
    // Get Exchange and Token Info
    function getExchange(address token)
        external
        view
        returns (address exchange);
    function getToken(address exchange) external view returns (address token);
    function getTokenWithId(uint256 tokenId)
        external
        view
        returns (address token);
    // Never use
    function initializeFactory(address template) external;
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.5.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
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
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
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
     * problems described in {IERC20-approve}.
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

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
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Burnable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Mintable.sol

pragma solidity ^0.5.0;



/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract ERC20Mintable is ERC20, MinterRole {
    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC20/ERC20Detailed.sol

pragma solidity ^0.5.0;


/**
 * @dev Optional functions from the ERC20 standard.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/DownDai.sol

pragma solidity ^0.5.16;




/**
 * @notice DownDai erc20 mock
 */
contract DownDai is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    uint256 public version;

    constructor(uint256 _version)
        public
        ERC20Detailed("Down Dai", "DOWNDAI", 18)
    {
        version = _version;
    }
}
// File: contracts/UpDai.sol

pragma solidity ^0.5.17;




/**
 * @notice UpDai erc20 token
 */
contract UpDai is ERC20Detailed, ERC20Mintable, ERC20Burnable {
    uint256 public version;

    constructor(uint256 _version)
        public
        ERC20Detailed("Up Dai", "UpDAI", 18)
    {
        version = _version;
    }
}
// File: contracts/CFD.sol

pragma solidity ^0.5.17;








/**
  * @title CFD - take a 20x leveraged position on the future price of DAI.. or provide
  * liquidity to the market and earn staking rewards. Liquidation prices at 20x are 0.95<>1.05
  * @author Daichotomy team
  * @dev Check out all this sweet code!
  */
contract CFD {
    using StableMath for uint256;

    /***************************************
                  CONNECTIONS
    ****************************************/

    address public makerMedianizer;
    address public uniswapFactory;
    address public daiToken;

    /***************************************
                    CONFIG
    ****************************************/

    UpDai public upDai;
    DownDai public downDai;
    IUniswapExchange public uniswapUpDaiExchange;
    IUniswapExchange public uniswapDownDaiExchange;

    uint256 public leverage; // 1x leverage == 1e18
    uint256 public feeRate; // 100% fee == 1e18, 0.3% fee == 3e15
    uint256 public settlementDate; // In seconds

    /***************************************
              STAKING & SETTLEMENT
    ****************************************/

    bool public inSettlementPeriod = false;
    uint256 public daiPriceAtSettlement; // $1 == 1e18
    uint256 public upDaiRateAtSettlement; // 1:1 == 1e18
    uint256 public downDaiRateAtSettlement; // 1:1 == 1e18

    uint256 public totalMintVolumeInDai;

    struct Stake {
        uint256 upLP; // Total LP for the UPDAI pool
        uint256 downLP; // Total LP for the UPDAI pool
        uint256 mintVolume; // Total mint volume in DA units
        bool liquidated; // Has this staker withdrawn his funds?
    }

    mapping(address => Stake) public stakes;

    event UpDownDaiRates(
        uint256 upDaiRate,
        uint256 downDaiRate
    );

    event NeededEthCollateral(
        address indexed depositor,
        address indexed cfd,
        uint256 indexed amount,
        uint256 upDaiPoolEth,
        uint256 downDaiPoolEth,
        uint256 totalEthCollateral
    );

    /**
     * @notice constructor
     * @param _makerMedianizer maker medianizer address
     * @param _uniswapFactory uniswap factory address
     * @param _daiToken maker medianizer address
     * @param _leverage leverage (1000000000000000x) (1x == 1e18)
     * @param _fee payout fee (1% == 1e16)
     * @param _settlementDate maker medianizer address
     * @param _version which tranche are we on?
     */
    constructor(
        address _makerMedianizer,
        address _uniswapFactory,
        address _daiToken,
        uint256 _leverage,
        uint256 _fee,
        uint256 _settlementDate,
        uint256 _version
    ) public payable {
        makerMedianizer = _makerMedianizer;
        uniswapFactory = _uniswapFactory;
        daiToken = _daiToken;

        leverage = _leverage;
        feeRate = _fee;
        settlementDate = _settlementDate;

        upDai = new UpDai(_version);
        
        downDai = new DownDai(_version);

        uniswapUpDaiExchange = IUniswapExchange(
            IUniswapFactory(uniswapFactory).createExchange(address(upDai))
        );
        uniswapDownDaiExchange = IUniswapExchange(
          IUniswapFactory(uniswapFactory).createExchange(address(downDai))
       );

        require(
         upDai.approve(address(uniswapUpDaiExchange), uint256(-1)),
           "Approval of upDai failed"
        );
        require(
           downDai.approve(address(uniswapDownDaiExchange), uint256(-1)),
          "Approval of downDai failed"
     );
    }

    /***************************************
                    MODIFIERS
    ****************************************/

    modifier notInSettlementPeriod() {
        if (now > settlementDate) {
            inSettlementPeriod = true;
            daiPriceAtSettlement = GetDaiPriceUSD();
            (
                upDaiRateAtSettlement,
                downDaiRateAtSettlement
            ) = getCurrentDaiRates(daiPriceAtSettlement);
        }
        require(!inSettlementPeriod, "Must not be in settlement period");
        _;
    }

    modifier onlyInSettlementPeriod() {
        require(inSettlementPeriod, "Must be in settlement period");
        _;
    }

    /***************************************
              LIQUIDITY PROVIDERS
    ****************************************/

    /**
     * @notice mint UP and DOWN DAI tokens
     * @param _daiDeposit amount of DAI to deposit
     */
    function mint(uint256 _daiDeposit) external payable notInSettlementPeriod {
        // Step 1. Take the DAI
        require(
            IERC20(daiToken).transferFrom(
                msg.sender,
                address(this),
                _daiDeposit
            ),
            "CFD::error transfering underlying asset"
        );

        // Step 2. Calculate the value of these tokens, and how much ETH that is
        (uint256 upDaiEthUnits, uint256 downDaiEthUnits) = getETHCollateralRequirements(
            _daiDeposit
        );
        uint256 totalETHCollateral = upDaiEthUnits.add(downDaiEthUnits);
        require(msg.value >= totalETHCollateral, "CFD::error transfering ETH");
        if (msg.value > totalETHCollateral) {
            msg.sender.transfer(msg.value - totalETHCollateral);
        }

        // Step 3. Mint the up/down DAI tokens
        upDai.mint(address(this), _daiDeposit.div(2));
        downDai.mint(address(this), _daiDeposit.div(2));

        // Step 4. Contribute to Uniswap
        uint256 upLP = uniswapUpDaiExchange.addLiquidity.value(upDaiEthUnits)(
            1,
            _daiDeposit.div(2),
            now.add(3600)
        );
        uint256 downLP = uniswapDownDaiExchange.addLiquidity.value(
            downDaiEthUnits
        )(1, _daiDeposit.div(2), now + 3600);

        // Step 5. Store the LP and log the mint volume
        totalMintVolumeInDai = totalMintVolumeInDai.add(_daiDeposit);
        stakes[msg.sender] = Stake({
            upLP: stakes[msg.sender].upLP.add(upLP),
            downLP: stakes[msg.sender].downLP.add(downLP),
            mintVolume: stakes[msg.sender].mintVolume.add(_daiDeposit),
            liquidated: false
        });

        // TODO - add a time element here to incentivise early stakers to provide liquidity
        // This will affect the proportionate amount of rewards they receive at the end

    }

    /**
     * @notice get the amount of ETH required to create a uniswap exchange
     * @param _daiDeposit the total amount of underlying to deposit (UP/DOWN DAI = _daiDeposit/2)
     * @return the amount of ETH needed for UPDAI pool and DOWNDAI pool
     */
    function getETHCollateralRequirements(uint256 _daiDeposit)
        public
        returns (uint256, uint256)
    {
        uint256 individualDeposits = _daiDeposit.div(2);
        // get ETH price, where $200 == 200e18
        uint256 ethUsdPrice = GetETHUSDPriceFromMedianizer();
        // get DAI price, where $1 == 1e18
        uint256 daiPriceUsd = GetDaiPriceUSD();

        // Rate 1:1 == 1e18, 1.2:1 == 12e17
        (uint256 upDaiRate, uint256 downDaiRate) = getCurrentDaiRates(
            daiPriceUsd
        );
        // e.g. (11e17 * 1e18) / 1e18 = 11e17
        uint256 totalUpDaiValue = upDaiRate.mulTruncate(individualDeposits);
        uint256 totalDownDaiValue = downDaiRate.mulTruncate(individualDeposits);

        // ETH amount needed for the UPDAI pool
        // e.g. (11e17 * 1e18) / 287e18 = 11e35 / 287e18 = 3e15 ETH
        uint256 upDaiPoolEth = totalUpDaiValue.divPrecisely(ethUsdPrice);
        uint256 downDaiPoolEth = totalDownDaiValue.divPrecisely(ethUsdPrice);

        emit NeededEthCollateral(
            msg.sender,
            address(this),
            _daiDeposit,
            upDaiPoolEth,
            downDaiPoolEth,
            upDaiPoolEth.add(downDaiPoolEth)
        );

        return (upDaiPoolEth, downDaiPoolEth);
    }

    /**
     * @notice Claims all rewards that a staker is eligable for
     */
    function claimRewards() external onlyInSettlementPeriod {
        Stake memory stake = stakes[msg.sender];
        require(
            stake.mintVolume > 0 && !stake.liquidated,
            "Must be a valid staker"
        );
        stakes[msg.sender].liquidated = true;

        // 1. Claim Redemption Fees (proportionate to LP)
        // e.g. (1e27 * 3e15)/1e18 = 3e42/1e18 = 3e24
        uint256 totalRedemptionFees = totalMintVolumeInDai.mulTruncate(feeRate);
        require(
            IERC20(daiToken).transfer(msg.sender, totalRedemptionFees),
            "Must receive the fees"
        );

        // 2. Redeem or withdraw LP
        // 2.1. Get everything from Uniswap
        (uint256 ethRedeemedUp, uint256 upDaiRedeemed) = uniswapUpDaiExchange
            .removeLiquidity(stake.upLP, 1, 1, now + 3600);
        (uint256 ethRedeemedDown, uint256 downDaiRedeemed) = uniswapDownDaiExchange
            .removeLiquidity(stake.downLP, 1, 1, now + 3600);
        // 2.2. Redeem all the tokens
        _payout(
            msg.sender,
            upDaiRedeemed,
            downDaiRedeemed,
            upDaiRateAtSettlement,
            downDaiRateAtSettlement
        );
        // 2.3. Transfer the eth to the user
        msg.sender.transfer(ethRedeemedUp.add(ethRedeemedDown));
    }

    /***************************************
                PUBLIC REDEPTION
    ****************************************/

    /**
     * @notice redeem a pair of UPDAI and DOWNDAI
     * @dev this function can be called before the settlement date, an equal amount of UPDAI and DOWNDAI should be deposited
     * @param _redeemAmount Pair count where 1 real token == 1e18 base units
     */
    function redeem(uint256 _redeemAmount) public notInSettlementPeriod {
        // burn UPDAI & DOWNDAI from redeemer
        upDai.burnFrom(msg.sender, _redeemAmount);
        downDai.burnFrom(msg.sender, _redeemAmount);

        uint256 daiPriceUsd = GetDaiPriceUSD();
        // Rate 1:1 == 1e18, 1.2:1 == 12e17
        (uint256 upDaiRate, uint256 downDaiRate) = getCurrentDaiRates(
            daiPriceUsd
        );

        // spread MONEY bitches
        _payout(
            msg.sender,
            _redeemAmount,
            _redeemAmount,
            upDaiRate,
            downDaiRate
        );
    }

    /**
     * @notice redeem UPDAI or DOWNDAI token
     * @dev this function can only be called after contract settlement
     */
    function redeemFinal() public onlyInSettlementPeriod {
        // get upDai balance
        uint256 upDaiRedeemAmount = upDai.balanceOf(msg.sender);
        // get downDai balance
        uint256 downDaiRedeemAmount = downDai.balanceOf(msg.sender);

        // burn upDai
        upDai.burnFrom(msg.sender, upDaiRedeemAmount);
        // burn downDai
        downDai.burnFrom(msg.sender, downDaiRedeemAmount);

        // spread MONEY bitches
        _payout(
            msg.sender,
            upDaiRedeemAmount,
            downDaiRedeemAmount,
            upDaiRateAtSettlement,
            downDaiRateAtSettlement
        );
    }

    /***************************************
              INTERNAL - PAYOUT
    ****************************************/

    /**
     * @notice $ payout function $
     * @dev can only be called internally
     * @param redeemer redeemer address
     * @param upDaiUnits units of UpDai
     * @param downDaiUnits units of DownDai
     * @param upDaiRate Rate of uDAI<>DAI
     * @param downDaiRate units of downDAI<>DAI
     */
    function _payout(
        address redeemer,
        uint256 upDaiUnits,
        uint256 downDaiUnits,
        uint256 upDaiRate,
        uint256 downDaiRate
    ) internal {
        // e.g. (12e17 * 100e18) / 1e18 = 12e37 / 1e18 = 120e18
        uint256 convertedUpDai = upDaiRate.mulTruncate(upDaiUnits);
        // e.g. (8e17 * 100e18) / 1e18 = 8e37 / 1e18 = 80e18
        uint256 convertedDownDai = downDaiRate.mulTruncate(downDaiUnits);
        // if feeRate = 3e15, (2e20*3e15)/1e18 = 6e17
        uint256 totalDaiPayout = convertedUpDai.add(convertedDownDai);
        uint256 fee = totalDaiPayout.mulTruncate(feeRate);
        // Pay the moola
        IERC20(daiToken).transfer(redeemer, totalDaiPayout.sub(fee));
    }

    /***************************************
              INTERNAL - SETTLE CONTRACT
    ****************************************/

    /**
     * @notice settle CFD
     * @param daiUsdPrice Dai price in USD where $1 == 1e18
     */
    function _settleContract(uint256 daiUsdPrice, bool priceIsPositive) internal {
        inSettlementPeriod = true;
        daiPriceAtSettlement = daiUsdPrice;

        // If Price is positive, Up wins and is worth 2:1, where Down is worth 0:1
        (uint256 finalUpDaiRate, uint256 finalDownDaiRate) = priceIsPositive
            ? (uint256(2e18), uint256(0))
            : (uint256(0), uint256(2e18));
        upDaiRateAtSettlement = finalUpDaiRate;
        downDaiRateAtSettlement = finalDownDaiRate;
    }

    /***************************************
                  PRICE HELPERS
    ****************************************/

    /**
     * @notice Based on the price of DAI, what are the current exchange rates for upDai and downDai?
     * @param daiUsdPrice Dai price in USD where $1 == 1e18
     * @return upDaiRate where 1:1 == 1e18
     * @return downDaiRate where 1:1 == 1e18
     */
    function getCurrentDaiRates(uint256 daiUsdPrice)
        public
        returns (uint256, uint256)
    {
        // (1 + ((DaiPriceFeed-1) *  Leverage))
        // Given that price is reflected absolutely on both sides.. then
        // (1 + (delta * leverage)), to find the up multiplier
        uint256 one = 1e18;
        bool priceIsPositive = daiUsdPrice > one;
        // Get price delta, e.g. if daiUsdPrice == 1007e15, delta == 7e15
        uint256 delta = priceIsPositive
            ? daiUsdPrice.sub(one)
            : one.sub(daiUsdPrice);
        // Consider 20x leverage == 20e18 == 2e19, then
        // e.g. 7e15 * 2e19 == 14e34, then truncate to 4e16
        uint256 deltaWithLeverage = delta.mulTruncate(leverage);
        // e.g. 1e18 + 4e16 = 104e16
        uint256 winRate = one.add(deltaWithLeverage);
        // If the price has hit the roof, settle the contract
        if (winRate >= uint256(2e18)) {
            _settleContract(daiUsdPrice, priceIsPositive);

            emit UpDownDaiRates(upDaiRateAtSettlement, downDaiRateAtSettlement);

            return (upDaiRateAtSettlement, downDaiRateAtSettlement);
        }
        else {
            // e.g. 1e18 - 2e17 = 8e17
            uint256 loseRate = (uint256(2e18)).sub(deltaWithLeverage);
            // If price is positive, upDaiRate should be better :)
            if(priceIsPositive) {
                emit UpDownDaiRates(winRate, loseRate);

                return (winRate, loseRate);
            }
            else {
                emit UpDownDaiRates(loseRate, winRate);

                return (loseRate, winRate);
            }
        }
    }

    /**
     * @notice get DAI price in USD
     * @dev this function get the DAI/USD price by getting the price of ETH/USD from Maker medianizer and dividing it by the price of ETH/DAI from Uniswap.
     * @return relativePrice of DAI with regards to USD peg, where 1:1 == 1e18
     */
    function GetDaiPriceUSD() public view returns (uint256 relativePrice) {
        address uniswapExchangeAddress = IUniswapFactory(uniswapFactory)
            .getExchange(daiToken);

        // ethUsdPrice, where $1 == 1e18
        uint256 ethUsdPrice = GetETHUSDPriceFromMedianizer();
        // ethDaiPrice, where 1:1 == 1e8. Using a single wei here means 0 slippage and allows pricing from low liq pool
        // extrapolate to base 1e18 in order to do calcs
        uint256 ethDaiPriceSimple = IUniswapExchange(uniswapExchangeAddress)
            .getEthToTokenInputPrice(1 * 10**6);
        uint256 ethDaiPriceExact = ethDaiPriceSimple.mul(10**12);

        return ethUsdPrice.divPrecisely(ethDaiPriceExact);
    }

    /**
     * @notice Parses the bytes32 price from Makers Medianizer into uint
     * @return uint256 Medianised price where $1 == 1e18
     */
    function GetETHUSDPriceFromMedianizer() public view returns (uint256) {
        return uint256(IMakerMedianizer(makerMedianizer).read());
    }
}