/**
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./Holdable.sol";

/**
 *
 * This implementation of Token contract is inherited from ERC20
 * token smart contract from openzeplin library which is a standard
 * implementation of the {IERC20} interface.Please find below link for source-code
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
 *
 * That(Openzeplin's ERC20 contract) implementation is agnostic to
 * the way tokens are created. This means that a supply mechanism has to be
 * added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * That(Openzeplin's ERC20 contract) contract follows OpenZeppelin guidelines:
 * functions revert instead of returning `false` on failure. This behavior
 * is nonetheless conventional and does not conflict with the expectations
 * of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 *
 */
contract Token is Holdable {
    /**
     * @dev Sets the values for {name}, {symbol} and {initialSupply}.
     *
     * This function is used to initialize ERC20 token with token name,
     * token symbol (it's short symbol) and amount of initial tokens available.
     */
    constructor(string memory name_,
                string memory symbol_,
                uint256 initialSupply
                ) ERC20(name_, symbol_) {
        _mint(msg.sender, initialSupply);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
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
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

//SPDX-License-Identifier: MIT
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Roles.sol";

/**
 * @title AdminRole
 * @dev Admins are responsible for minting new tokens.
 */
contract AdminRole is Ownable {
    using Roles for Roles.Role;

    /**
     * @dev Emitted when `account` is added in the Admin list.
     */
    event AdminAdded(address indexed account);
    /**
     * @dev Emitted when `account` is removed from the Admin list.
     */
    event AdminRemoved(address indexed account);

    Roles.Role private _Admins;

    /**
     * @dev Initializes the contract setting the deployer as the Admin.
     */
    constructor () {
        _addAdmin(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "AdminRole: caller is not the Admin");
        _;
    }

    /**
     * @dev Returns `true` if `account` is in the Admin list.
     * @param account The account address to be checked
     */
    function isAdmin(address account) public view returns (bool) {
        return _Admins.has(account);
    }

    /**
     * @dev Adds the `account` address in the Admin list.
     * @param account The account address to be added
     * Emits an {AdminAdded} event.
     */
    function addAdmin(address account) external onlyOwner {
        _addAdmin(account);
    }

    /**
     * @dev Removes the `account` address from the Admin list.
     * @param account The account address to be removed
     * Emits an {AdminRemoved} event.
     */
    function removeAdmin(address account) external onlyOwner {
        require(isAdmin(account), "AdminRole: arg account is not the Admin");
        _removeAdmin(account);
    }

    /**
     * @dev Removes the `account` address from the Admin list.
     * Note: This will remove the caller from the Admin list.
     * Emits an {AdminRemoved} event.
     */
    function renounceAdmin() public {
        require(isAdmin(msg.sender), "AdminRole: caller is not the Admin");
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _Admins.add(account);
        emit AdminAdded(account);
    }

    function _removeAdmin(address account) internal {
        _Admins.remove(account);
        emit AdminRemoved(account);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Roles/AdminRole.sol";

/**
 * @title Holdable
 * @dev This contract is inherited from ERC20
 * token smart contract from openzepplin library.
 * Holdable smart contract provide functionalitites
 * related to lock-in of tokens before it is available for spending.
 *
 * The {transferWithHold} function helps in setting up the holding period
 * while allowing the transfer of tokens. The recipient will be able to
 * see the funds but if the tokens are transferred before the holding period,
 * an exception will be raised indicating 'Insufficient balance'.
 *
 * The {getHoldBalance} method can be used to view the balances under hold.
 *
 * Finally the {revoke} and {releaseHold} functions assit the owner to
 * control the transfer of funds before the holding period.
 */
abstract contract Holdable is ERC20, AdminRole {
    using SafeMath for uint256;

    uint256 private _maxHolds;

    /**
     * @dev Initializes the maximum number of holds.
     */
    constructor () {
        _maxHolds = 50;
    }

    /**
     * Struct stores locked account with amount with given period.
     */
    struct HoldData {
        address recipient;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        bool isHeld;
    }

    /**
     * @dev Emitted when `value` tokens are revoked for a specified account ('from').
     */
    event Revoke(
        address indexed from,
        address indexed to,
        uint256 value,
        string message
    );  
    event TransferWithHold (
        address indexed msg,
        address indexed rec,
        uint256 value,
        string message
    );

    /**
     * @dev Emitted when `value` tokens are released for a specified account ('from').
     */
    event Release(address indexed from, address indexed to, string message);
    event DeleteAllhold(address indexed sender,address indexed recipient,string message);
    event DeleteHold(uint256 index,address indexed sender,address indexed to,string message);
    event BeforeTokentransfer(address indexed sender,address indexed from,uint256 amount,string message);


    // mapping of accounts to array of HoldData
    mapping(address => HoldData[]) internal holds;

    /**
     * @dev Transfers and Locks a specified amount of tokens againts the address
     *      for a specified time
     *
     * @param recipient The address to which tokens are transferred and locked
     * @param amount Number of tokens to be transferred and locked
     * @param endTime The endTime for which the tokens will remain locked.
     */
    function transferWithHold(
        address recipient,
        uint256 amount,
        uint256 endTime
    ) external onlyAdmin returns (bool) {
        require(
            recipient != address(0),
            "transferWithHold: transfer with zero address"
        );
        require(
            holds[recipient].length < _maxHolds, "revoke: Max number of holds exceeded for the address"
        );
        require(
            amount != 0,
            "transferWithHold: amount must be greater than zero"
        );
        require(
            endTime > block.timestamp,
            "endTime should not be earlier to start time"
        );

        holds[recipient].push(
            HoldData(recipient, amount, block.timestamp, endTime, true)
        );

        emit TransferWithHold ( _msgSender(), recipient,amount,"Transfer With Hold tokens");
        
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Deletes an element from the array at 'index' position..
     *
     * @param index The index position of the element
     * @param to The address account, whose element has to be deleted
     */
    function _deleteHold(uint256 index, address to) internal {
        require(index < holds[to].length, "Index values is greater than the of the hold array");
        holds[to][index] = holds[to][holds[to].length - 1];
        holds[to].pop();
        emit DeleteHold(index,msg.sender,to,"Delete with Hold tokens");
    }

    /**
     * @dev Delete all elements from the array.
     *
     * @param recipient The address whose tokens are locked
     */
    function _deleteAllHold(address recipient) internal {
        uint256 arr_len = holds[recipient].length;
        for (uint256 i = 0; i < arr_len && i < _maxHolds; i++) {
            holds[recipient].pop();
        }
        emit DeleteAllhold(msg.sender,recipient,"Delete all Holding tokens in one time.");
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes minting and burning.
     *
     * The function checks if any tokens are already held for the specified address.
     * If not, it will immediately return and continue with futher operation.
     * If yes, it will check if any of the hold time has expired. If yes, it will delete the hold
     * and continue with further operation.
     * See {ERC20-_beforeTokenTransfer}
     */
    function _beforeTokenTransfer(
        address from,
        address,
        uint256 amount
    ) internal override {
        if (holds[from].length == 0) {
            return;
        }
        uint256 unreleasedBalance = 0;

        // check if any hold has expired. If yes, deduct the accountHold and remove the hold
        for (uint256 i = 1; i < holds[from].length + 1 && i < _maxHolds; i++) {
            if (
                holds[from][i - 1].isHeld &&
                holds[from][i - 1].endTime <= block.timestamp
            ) {
                holds[from][i - 1].isHeld = false;
                _deleteHold(i - 1, from);
                i--;
            } else {
                unreleasedBalance = unreleasedBalance.add(
                    holds[from][i - 1].amount
                );
            }
        }
        if (holds[from].length == 0) {
            _deleteAllHold(from);
            
        }

        require(
            amount <= super.balanceOf(from) - unreleasedBalance,
            "Not enough balance"
        );
    }

    /**
     * @dev Returns tokens locked for a specified address
     *
     * @param recipient The address whose tokens are locked
     */
    function getHoldBalance(address recipient) public view returns (uint256) {
        uint256 amountOnHold = 0;
        for (uint256 i = 0; i < holds[recipient].length && i < _maxHolds; i++) {
            if (holds[recipient][i].endTime > block.timestamp) {
                amountOnHold = amountOnHold.add(holds[recipient][i].amount);
            }
        }
        //emit GetHoldbalance(recipient,amountOnHold,"Recipient Hold Balance");
        return amountOnHold;
    }

    /**
     * @dev Revokes the amount of tokens held againts the address
     *      and transfers them back to the owner of the smart contract
     *
     * @param recipient The address of which held tokens has to be revoked.
     *
     * Emits an {Revoke} event.
     */
    function revoke(address recipient) external onlyOwner returns (bool) {
        require(recipient != address(0), "revoke: revoke with zero address");
        require(holds[recipient].length != 0, "revoke: hold does not exist for the user");
        uint256 amountToRevoke;
        amountToRevoke = getHoldBalance(recipient);

        _deleteAllHold(recipient);

        require(
            amountToRevoke <= super.balanceOf(recipient),
            "Not enough tokens to be revoked"
        );

        _transfer(recipient, _msgSender(), amountToRevoke);

        emit Revoke(
            recipient,
            _msgSender(),
            amountToRevoke,
            "Locked tokens revoked by owner"
        );
        return true;
    }

    /**
     * @dev Releases the amount of tokens held againts the address
     *
     * @param recipient The address of which held tokens has to be released.
     *
     * Emits an {Release} event.
     */
    function releaseHold(address recipient) external onlyOwner returns (bool) {
        require(
            recipient != address(0),
            "releaseHold: releaseHold with zero address"
        );
        require(holds[recipient].length != 0, "release: hold does not exist for the user");

        _deleteAllHold(recipient);

        emit Release(
            recipient,
            _msgSender(),
            "Locked tokens released by owner"
        );

        return true;
    }

    // To transfer tokens from Contract to the provided list of token holders with respective amount
    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) 
    external returns(bool)
    {
        require(recipients.length > 0, "There should be more than 0 reciepents");
        require(recipients.length == amounts.length, "Invalid input parameters");
        for(uint256 index = 0; index < recipients.length; index++) {
            _transfer(msg.sender,recipients[index], amounts[index]);
        }
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
    constructor () {
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