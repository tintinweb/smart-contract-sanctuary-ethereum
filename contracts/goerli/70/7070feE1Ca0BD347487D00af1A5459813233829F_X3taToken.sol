/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * @dev Moves `amount` of tokens from `from` to `to`.
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

// File: xetatoken.sol

//SPDX-License-Identifier: UNLICENSED



pragma solidity 0.8.17;








/// @title A $X3TA token contract

/// @notice Use this contract to manage the $X3TA token

contract X3taToken is ERC20, Pausable, Ownable {

    IERC20 internal usdcToken;

    address internal xetaWallet;

    address[] internal distributedWallets = [

        0x8D17B9A7ed442F4133Bd3421B297bA975F8Fd091, // Buyback

        0x34f95B36474Dd5e3e8CB65f0Cef3856eaA022330, // Treasury

        0x9A0e00ff86732755379eb5e68DBDe7fF868616c9, // Liquidity

        0xe0F607c8355F1BbcDBa4843D2AA36e537CE588a9 // Operations

    ];

    uint256 internal xonCost = 10 * (10 ** 18);

    uint256 internal xonCreationFee = 15 * (10 ** 6);

    uint256 internal claimRewardFee = 5 * (10 ** 6);

    uint256 internal subscriptionFee = 15 * (10 ** 6);

    uint256 internal maxXonsPerUser = 500;

    uint256[] internal walletDistribution = [25, 25, 25, 25];



    event ClaimRequestsEvent(address indexed userWallet, bytes24[] nodeIds);

    event TransferEvent(address indexed userWallet, uint indexed amount); // the address and amount of transferred tokens

    event CreatingXonEvent(address indexed userWallet, uint256 indexed amount, uint8 indexed _type);

    event SubscriptionsPaymentEvent(address indexed userWallet, bytes24[] nodeIds, uint8 indexed months);

    event SetXetaWalletEvent(address indexed wallet);

    event SetXonCostEvent(uint256 indexed cost);

    event SetXonCreationFeeEvent(uint256 indexed fee);

    event SetSubscriptionFeeEvent(uint256 indexed fee);

    event SetClaimRewardFeeEvent(uint256 indexed fee);

    event SetMaxXonsPerUserEvent(uint256 indexed number);

    event SetWalletDistributionEvent(uint8[4] arr);

    event SetDistributedWalletEvent(uint8 indexed number, address indexed _address);

    event GiveAwayEvent(address indexed recipient, uint256 indexed amount);



    modifier onlyXetaOrOwner() {

        require(msg.sender == xetaWallet || msg.sender == owner(), "Neither XETA nor owner");

        _;

    }



    constructor(address _usdcToken) ERC20("X3TA", "X3TA") {

        xetaWallet = 0xB63b14F85a0D11842a5c9e1b28C91d3AE9d31A6a;

        //usdcToken = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E); // for Avalanche mainnet

        usdcToken = IERC20(_usdcToken);

        _mint(address(this), 21 * (10 ** 6) * (10 ** 18)); // pre-mint

    }



    /// @notice Use this function by a user to request a reward for the specified nodes

    /// @dev User should allow to spend (claimRewardFee * nodeIds.length) USDC tokens

    /// @dev An external service should listen to the ClaimRequestsEvent event and execute transferFromBackend function

    /// @dev with the reward calculated by the whitepaper descriptions

    /// @param nodeIds XON IDs that were generated by the external service

    function requestRewards(bytes24[] memory nodeIds, uint256 _claimRewardFee) external whenNotPaused {

        require(_claimRewardFee == claimRewardFee, "Invalid claim reward fee");

        require(nodeIds.length > 0 && nodeIds.length <= maxXonsPerUser, "Illegal number of nodes");

        if (claimRewardFee > 0) {

            bool res = distributePaymentInUsdc(claimRewardFee * nodeIds.length);

            require(res == true, "Error in payment distribution");

        }

        emit ClaimRequestsEvent(msg.sender, nodeIds);

    }



    /// @notice Use this function by the special $XETA wallet or the owner of the smart contract to transfer rewards.

    /// @param user The wallet address of the user who has requested a reward

    /// @param sum An amount of $XETA tokens

    function transferFromBackend(address user, uint sum) external onlyXetaOrOwner whenNotPaused {

        _transfer(address(this), user, sum);

        emit TransferEvent(user, sum);

    }



    /// @notice Use this function to create a XON. A user should pay a create fee and a $XETA tokens

    /// @dev An external service should listen to the CreatingXonEvent

    function mintXon(uint256 amount, uint256 _xonCreationFee, uint8 _type) external whenNotPaused {

        require(_xonCreationFee == xonCreationFee, "Invalid XON creation fee");

        require(amount > 0, "Illegal amount");

        if (xonCreationFee > 0) {

            bool res = distributePaymentInUsdc(xonCreationFee * amount);

            require(res == true, "Error in payment distribution");

        }

        _transfer(msg.sender, address(this), xonCost * amount);

        emit CreatingXonEvent(msg.sender, amount, _type);

    }



    /// @notice A user with XONs should pay a subscription fee for each XON every 28 days

    /// @dev An external service should listen to the SubscriptionsPaymentEvent

    function requestSubscriptions(bytes24[] memory nodeIds, uint8 months, uint256 _subscriptionFee) external whenNotPaused {

        require (_subscriptionFee == subscriptionFee, "Invalid subscription fee");

        require(nodeIds.length > 0 && nodeIds.length <= maxXonsPerUser, "Illegal number of nodes");

        if (subscriptionFee > 0) {

            bool res = distributePaymentInUsdc(subscriptionFee * nodeIds.length * months);

            require(res == true, "Error in payment distribution");

        }

        emit SubscriptionsPaymentEvent(msg.sender, nodeIds, months);

    }



    /// @dev If a user sends other tokens to this smart contract, the owner can transfer it to himself.

    function withdrawToken(address _tokenContract, address _recipient, uint256 _amount) external onlyOwner {

        IERC20 tokenContract = IERC20(_tokenContract);



        // transfer the token from address of this contract

        // to address of the user (executing the withdrawToken() function)

        tokenContract.transfer(_recipient, _amount);

    }



    /// @dev Due to the nature of smart contracts and the fact they're immutable, for the interest of the community and

    /// @dev the ecosystem, we decided to add an option to disable critical contract functionality in case of an emergency.

    function pause() external onlyOwner {

        _pause();

    }



    /// @dev Due to the nature of smart contracts and the fact they're immutable, for the interest of the community and

    /// @dev the ecosystem, we decided to add an option to disable critical contract functionality in case of an emergency.

    function unpause() external onlyOwner {

        _unpause();

    }



    /// @notice Set address of a special xeta wallet that is able to transfer rewards

    /// @param newAddress address of the special xeta wallet

    function setXetaWallet(address newAddress) external onlyOwner {

        require (newAddress != address(0x0), "Invalid address");

        xetaWallet = newAddress;

        emit SetXetaWalletEvent(newAddress);

    }



    /// @notice Sets the XON cost in XETA

    function setXonCost(uint256 cost) external onlyOwner {

        xonCost = cost;

        emit SetXonCostEvent(cost);

    }



    /// @notice Sets the XON creation fee in USDC

    function setXonCreationFee(uint256 fee) external onlyOwner {

        xonCreationFee = fee;

        emit SetXonCreationFeeEvent(fee);

    }



    /// @notice Sets the subscription fee in USDC

    function setSubscriptionFee(uint256 cost) external onlyOwner {

        subscriptionFee = cost;

        emit SetSubscriptionFeeEvent(cost);

    }



    /// @notice Sets the reward fee in USDC

    function setClaimRewardFee(uint256 fee) external onlyXetaOrOwner {

        claimRewardFee = fee;

        emit SetClaimRewardFeeEvent(fee);

    }



    /// @notice Sets the max amount of XONs per user

    function setMaxXonsPerUser(uint256 _amount) external onlyOwner {

        maxXonsPerUser = _amount;

        emit SetMaxXonsPerUserEvent(_amount);

    }



    /// @notice Sets the wallet distribution (between treasury, liquidity and operation wallet addresses)

    /// @param percentages Array of treasury, liquidity and operation distribution in percents

    function setWalletDistribution(uint8[4] memory percentages) external onlyOwner {

        require(percentages[0] + percentages[1] + percentages[2] + percentages[3] == 100, "Percentage sum must be equal 100");

        for (uint8 i = 0; i < walletDistribution.length; i++) {

            walletDistribution[i] = percentages[i];

        }

        emit SetWalletDistributionEvent(percentages);

    }



    /// @notice Sets the wallet address of the treasury, liquidity and operation wallet addresses

    /// @param number buyback(0), treasury(1), liquidity(2) and operation(3) wallet addresses

    /// @param newAddress The address of the specified wallet

    function setDistributedWallet(uint8 number, address newAddress) external onlyOwner {

        require(newAddress != address(0x0));

        require(number < distributedWallets.length, "Wrong wallet number");

        require(newAddress != address(0), "Wrong wallet address");

        distributedWallets[number] = newAddress;

        emit SetDistributedWalletEvent(number, newAddress);

    }



    /// @notice Gets current USDC token address

    function getUsdcToken() external view returns(IERC20) {

        return usdcToken;

    }



    /// @notice Gets current XON cost (in $XETA)

    function getXonCost() external view returns(uint256) {

        return xonCost;

    }



    /// @notice Gets current XON creation fee (in USDC)

    function getXonCreationFee() external view returns(uint256) {

        return xonCreationFee;

    }



    /// @notice Gets current reward fee (in USDC)

    function getClaimRewardFee() external view returns(uint256) {

        return claimRewardFee;

    }



    /// @notice Gets current subscription fee (in USDC)

    function getSubscriptionFee() external view returns(uint256) {

        return subscriptionFee;

    }



    /// @notice Gets current wallet distribution in percent

    /// @param number treasury(0), liquidity(1) and operation(2)

    function getWalletDistribution(uint8 number) external view returns(uint256) {

        require (number < walletDistribution.length, "Wrong wallet number");

        return walletDistribution[number];

    }



    /// @notice Gets current wallet distribution address

    /// @param number treasury(0), liquidity(1) and operation(2)

    function getDistributedWallet(uint8 number) external view returns(address) {

        require (number < distributedWallets.length, "Wrong wallet number");

        return distributedWallets[number];

    }



    /// @notice Gets the maximal amount of XONs per user

    function getMaxXonsPerUser() external view returns(uint256) {

        return maxXonsPerUser;

    }



    /// @notice Make an airdrop of this tokens

    function giveAwayBatch(address[] memory recipients, uint256[] memory amount) external onlyOwner {

        require(recipients.length == amount.length, "Recipient and amount arrays mismatch");

        uint sum = 0;

        for (uint i = 0; i < recipients.length; i++) {

            require(recipients[i] != address(0), "Recipient should not have 0x0 address");

            sum += amount[i];

        }

        require(balanceOf(address(this)) >= sum, "Insufficient amount of tokens");



        for (uint i = 0; i < recipients.length; i++) {

            _transfer(address(this), recipients[i], amount[i]);

            emit GiveAwayEvent(recipients[i], amount[i]);

        }

    }



    /// @notice Overrides _beforeTokenTransfer for pause functionality

    function _beforeTokenTransfer(

        address from,

        address to,

        uint256 amount

    )

    internal

    override

    whenNotPaused

    {

        super._beforeTokenTransfer(from, to, amount);

    }



    /// @notice Distributes payment between treasury, liquidity and operation addresses

    function distributePaymentInUsdc(uint256 amount) private returns (bool) {

        if (amount == 0) {

            return false;

        }

        return usdcToken.transferFrom(msg.sender, distributedWallets[0], amount * walletDistribution[0] / 100)

        && usdcToken.transferFrom(msg.sender, distributedWallets[1], amount * walletDistribution[1] / 100)

        && usdcToken.transferFrom(msg.sender, distributedWallets[2], amount * walletDistribution[2] / 100)

        && usdcToken.transferFrom(msg.sender, distributedWallets[3], amount * walletDistribution[3] / 100);

    }

}