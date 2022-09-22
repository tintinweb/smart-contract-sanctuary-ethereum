// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import {IAthenaWrap} from "IAthenaWrap.sol";
import {AthenaEther} from "AthenaEther.sol";

import {Guard} from "Guard.sol";

import {Ownable} from "Ownable.sol";

/**
* @title AthenaWrap.
* @author Anthony (fps) https://github.com/0xfps.
* @dev  AthenaWrap, a simple wrapping protocol. It takes in ETH, MATIC or
*       AVAX, and sends AETH tokens to the caller.
*/
contract AthenaWrap is 
IAthenaWrap, 
AthenaEther, 
Ownable,
Guard
{
    /// @dev Total wrapped in the protocol.
    uint256 private _totalWrapped;
    /// @dev Tota unwrapped in the protocol.
    uint256 private _totalUnwrapped;
    /// @dev Protocol tax revenue.
    uint256 private tax;

    /// @dev Total amount wrapped by an address in the protocol.
    mapping(address => uint256) private _totalWrappedByAddress;
    /// @dev Total amount unwrapped by an address in the protocol.
    mapping(address => uint256) private _totalUnwrappedByAddress;

    constructor() AthenaEther(address(this)) {}

    receive() external payable {}

    /**
    * @inheritdoc IAthenaWrap
    */
    function totalWrapped() public view returns(uint256) {
        /// @dev Return total wrapped by protocol.
        return _totalWrapped;
    }

    /**
    * @inheritdoc IAthenaWrap
    */
    function totalUnwrapped() public view returns(uint256) {
        /// @dev Return total unwrapped by protocol.
        return _totalUnwrapped;
    }

    /**
    * @inheritdoc IAthenaWrap
    */
    function totalWrappedByAddress(address _address) 
    public 
    view 
    returns(uint256)
    {
        /// @dev Ensure Address is not a zero address.
        require(_address != address(0), "0x0 Address");
        /// @dev Return total wrapped by address.
        return _totalWrappedByAddress[_address];
    }

    /**
    * @inheritdoc IAthenaWrap
    */
    function totalUnwrappedByAddress(address _address) 
    public 
    view 
    returns(uint256)
    {
        /// @dev Ensure Address is not a zero address.
        require(_address != address(0), "0x0 Address");
        /// @dev Return total wrapped by address.
        return _totalUnwrappedByAddress[_address];
    }

    /**
    * @inheritdoc IAthenaWrap
    */
    function precalculateTaxForWrap(uint256 _amount) 
    public 
    pure 
    returns(uint256)
    {
        /// @dev Require that amount is not 0.
        require(_amount != 0, "Amount == 0");

        /// @dev Calculate tax [0.1% of `_amount`].
        uint256 taxOnAmount = (1 * _amount) / 1000;

        /// @dev Return value.
        return taxOnAmount;
    }

    /**
    * @inheritdoc IAthenaWrap
    */
    function wrap() public payable {
        /// @dev Require money sent is not 0.
        require(msg.value != 0, "Wrapping 0");

        /// @dev Calculate tax.
        uint256 _tax = precalculateTaxForWrap(msg.value);
        /// @dev Subtract tax.
        uint256 amountToWrap = msg.value - _tax;
        /// @dev Add that to taxes.
        tax += _tax;
        /// @dev Increment total wrapped by the value.
        _totalWrapped += msg.value;
        /// @dev Increment the total wrapped by caller by value.
        _totalWrappedByAddress[msg.sender] += msg.value;

        /// @dev Transfer tokens.
        _transfer(address(this), msg.sender, amountToWrap);

        /// @dev Emit the {Wrap()} event.
        emit Wrap(msg.sender, msg.value);
    }

    /**
    * @inheritdoc IAthenaWrap
    */
    function unwrap(uint256 _amount) public noReentrance {
        /// @dev Require money sent is not 0.
        require(_amount != 0, "Wrapping 0");

        /// @dev Calculate tax.
        uint256 _tax = precalculateTaxForWrap(_amount);
        /// @dev Subtract tax.
        uint256 amountToUnwrap = _amount - _tax;
        /// @dev Increment amount unwrapped.
        _totalUnwrapped += _amount;
        /// @dev Increment amount unwrapped by the caller.
        _totalUnwrappedByAddress[msg.sender] += _amount;

        /// @dev Transfer amount from caller to contract.
        _transfer(
            msg.sender, 
            address(this), 
            _amount
        );

        /// @dev Send transferable value after tax to caller.
        (bool sent, ) = payable(msg.sender).call{value: amountToUnwrap}("");
        /// @dev Ensure that the required amount is sent to the address unwrapping.
        require(sent, "Unwrap Funds Low.");

        /// @dev Emit the {Unwrap()} event.
        emit Unwrap(msg.sender, _amount);
    }

    /**
    * @inheritdoc IAthenaWrap
    */
    function withdraw() public onlyOwner {
        /// @dev Require that taxes have been collected.
        require(tax != 0, "Tax == 0");

        /// @dev Reset tax.
        tax = 0;

        /// @dev Transfer tax earnings.
        (bool sent, ) = payable(owner()).call{value: tax}("");
        sent; // Unused.

        /// @dev Emit the {Withdraw()} event.
        emit Withdraw(msg.sender, tax);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

/**
* @title IAthenaWrap.
* @author Anthony (fps) https://github.com/0xfps.
* @dev  Interface for control of AthenaWrap.
*/
interface IAthenaWrap {
    /// @dev Emitted when a wrap is done.
    event Wrap(address indexed _wrapper, uint256 indexed _amount);
    /// @dev Emitted when an uwrap is done.
    event Unwrap(address indexed _unwrapper, uint256 indexed _amount);
    /// @dev Emitted when the protocol taxes are withdrawn.
    event Withdraw(address indexed _to, uint256 indexed _amount);
    
    /**
    * @dev  Returns the total amount of native token wrapped 
    *       by the `AthenaWrap` contract.
    */
    function totalWrapped() external view returns(uint256);

    /**
    * @dev  Returns the total amount of native token unwrapped 
    *       by the `AthenaWrap` contract.
    */
    function totalUnwrapped() external view returns(uint256);

    /**
    * @dev  Returns the total number of native tokens wrapped by `_address`
    *       in the `AthenaWrap` contract.
    *
    * @param _address Address of wrapper.
    */
    function totalWrappedByAddress(address _address) 
    external 
    view 
    returns(uint256);

    /**
    * @dev  Returns the total number of native tokens unwrapped by `_address`
    *       in the `AthenaWrap` contract.
    *
    * @param _address Address of unwrapper.
    */
    function totalUnwrappedByAddress(address _address) 
    external 
    view 
    returns(uint256);

    /**
    * @dev  Returns the total amount of tax that will be charged for the wraping
    *       of `_amount` amount of native tokens.
    *
    * @param _amount Amount to calculate.
    */
    function precalculateTaxForWrap(uint256 _amount) 
    external 
    pure 
    returns(uint256);

    /**
    * @dev  Wraps `msg.value` amount of tokens, by transferring `msg.value` amount 
    *       of AETH tokens after deducting tax.
    *       This function increments the `_totalWrapped` variable.
    *       Emits a `Wrap()` event.
    */
    function wrap() external payable;

    /**
    * @dev  Unraps `_amount` amount of tokens, by transferring `_amount` amount
    *       of native tokens to caller after deducting tax.
    *       This function increments the `_totalUnwrapped` variable.
    *       Emits an `Unwrap()` event.
    *
    * @param _amount Amount to unwrap.
    */
    function unwrap(uint256 _amount) external;

    /**
    * @dev  Transfers the total taxes to the protocol owner's address.
    *       Emits a `Withdraw()` event.
    */
    function withdraw() external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import {ERC20} from "ERC20.sol";

/**
* @title AthenaEther.
* @author Anthony (fps) https://github.com/0xfps.
* @dev Contract for minted AthenaEther to be transferred on successful wraps.
*/
contract AthenaEther is ERC20 {
    /// @dev Emitted on a new Deployment.
    event AthenaLaunch(address, uint256);

    /// @dev Constructor, mints 1 billion tokens to the Wrap contract.
    /// @param _wrap Address of AthenaWrap contract.
    constructor(address _wrap) ERC20("AthenaEther", "AETH") {
        /// @dev Mint 1 billion tokens to the AthenaEther Contract.
        _mint(_wrap, (10 ** 9) * (10 ** 18)); // 1 Billion Tokens.
        /// @dev Emit {AthenaLaunch} event.
        emit AthenaLaunch(_wrap, (10 ** 9) * (10 ** 18));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

/**
* @title Guard Contract.
* @author Anthony (fps) https://github.com/0xfps.
* @dev Abstract contract for reentrancy lock.
*/
abstract contract Guard {
    bool locked;
    
    modifier noReentrance {
        require(!locked, "Locked");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}