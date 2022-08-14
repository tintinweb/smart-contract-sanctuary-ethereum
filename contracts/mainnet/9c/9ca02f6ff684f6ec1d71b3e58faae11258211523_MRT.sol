/**
 *Submitted for verification at Etherscan.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
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

// File: lib.sol


pragma solidity >=0.8.15 <0.9.0;

library Lib {
    struct Order {
        uint8 status;
        uint16 token;
        uint232 value;
    }

    struct User {
        bool active;
        mapping(address => mapping(uint256 => Order)) orders;
    }

    struct Contract {
        bool active;
        uint16 token;
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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: mrt_token.sol


pragma solidity >=0.8.15 <0.9.0;




contract MrtToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("MrtToken", "MRT") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }


}

// File: mrt.sol


pragma solidity >=0.8.15 <0.9.0;




contract MRT is MrtToken {
    constructor() {
        _tokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = Lib.Contract(true,2);
        _tokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = Lib.Contract(true,3);
        _tokens[0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599] = Lib.Contract(true,4);
        _tokens[0x3832d2F059E55934220881F831bE501D180671A7] = Lib.Contract(true,5);
       
  
    }


    // Vendors in the app
    mapping(address => Lib.User) public _users; // 6 

    // In-app payable tokens
    mapping(address =>Lib.Contract) public _tokens; // 7 

    // Voting admins
    mapping(address =>bool) public _signer; // 8

    // contract balance
    mapping(uint16 => uint256) internal _contractBalance; // 9

    // contract percentage
    uint8 public CONTRACTPERCENTAGE; // 10

   

    // Token Ids
    uint16 public TOKENINCREAMENT = uint16(5); // 10

    //events
    event UserRegistred(string username, address indexed seller);
    event TokenUpdate(address token, bool active);
    event OrderPaid(
        uint256 total,
        uint256 indexed order_id,
        address indexed buyer,
        address indexed seller,
        address contract_address
    );
    event WSeller(
        uint256 indexed order_id,
        address indexed seller,
        address buyer
    );
    event WBuyer(
        uint256 indexed order_id,
        address indexed buyer,
        address seller
    );

    // Sellers must register in the contract before selling in-app
    function registerUser(string memory username) external {
        assembly {
            if iszero(caller()) {
                revert(0, 0)
            }
            mstore(0x0, caller())
            mstore(0x20, _users.slot)
            let h := keccak256(0x0, 0x40)
            let s := sload(h)
            switch iszero(and(s, 0xFF))
            case 1 {
                s := or(s, and(1, 0xFF))
                sstore(h, s)
            }
            case 0 {
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(free_mem_ptr, 4), 32)
                mstore(add(free_mem_ptr, 36), 12)
                mstore(add(free_mem_ptr, 68), "re_userexist")
                revert(free_mem_ptr, 100)
            }
        }
        emit UserRegistred(username, msg.sender);
    }

    // Enable and disable order registration with tokens in the app
    function toggleToken( address tokenAddress) external onlyOwner{
        bool enabled = true;
        assembly{
            mstore(0x0, tokenAddress)
            mstore(0x20, _tokens.slot)
            let h := keccak256(0x0, 0x40)
            let s := sload(h)
            switch iszero(shr(8,s))
            case 1 {
                if iszero(extcodesize(tokenAddress)) {
                    revert(0, 0)
                }
                let slot := sload(TOKENINCREAMENT.slot)
                let increamet := add(shr(8,slot),1)
                slot := and(slot,not(shl(8,0xFFFF)))   // *********important*********** CONTRACTPERCENTAGE and TOKENINCREAMENT in same slot 
                slot := or(slot,shl(8,and(increamet,0xFFFF)))
                sstore(TOKENINCREAMENT.slot,slot)
                s := and(s,not(0xFF))
                s := or(s,and(1,0xFF))
                s := and(s,not(shl(8,0xFFFF)))
                s := or(s,shl(8,and(increamet, 0xFFFF)))
                sstore(h,s)
            }
            case 0 {
                switch iszero(and(s,0xFF))
                case 1{
                    s := or(and(s,not(0xFF)),and(1,0xFF))
                    sstore(h,s)
                }
                default{
                    s := or(and(s,not(0xFF)),and(0,0xFF))
                    sstore(h,s)
                    enabled := false
                }
            }
        }
        emit TokenUpdate(tokenAddress,enabled);
    }

    // Enable and disable signer ( dapp Voting admins )
    function toggleSigner(address signer) external onlyOwner{
        assembly{
            if iszero(signer){
                revert(0,0)
            }
            mstore(0x0, signer)
            mstore(0x20, _signer.slot)
            let hash := keccak256(0x0, 0x40)
            let slot := sload(hash)
            switch iszero(and(slot,0xFF))
            case 1 {
                slot := and(slot,not(0xFF))
                slot := or(slot, and(1,0xFF))
                sstore(hash,slot)
            }
            case 0 {
                slot := and(slot,not(0xFF))
                sstore(hash,slot)
           
            }
        }
    }


    function updateContractPercentage(uint8 newPercentage) external onlyOwner{
        assembly{
            if gt(newPercentage ,3){
                revert(0,0)
            }
            let s := sload(CONTRACTPERCENTAGE.slot)
            s := or(and(s,not(0xFF)),and(newPercentage,0xFF))
            sstore(CONTRACTPERCENTAGE.slot, s)
        }
    }




    /**
    
    Order payment with active tokens in the contract, order information (buyer, order number amount, and token id).
    Relevant information is recorded in the seller struct with order ID.
    After payment, the order status changes to 1

    **/

    // 16k gas lower than normal methods
    function PayWithTokens(
        uint256 order_id,
        uint256 order_total,
        address contractAddress,
        address seller
    ) external {
        assembly {
             function sendRevert(mesg,size){
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(free_mem_ptr, 4), 32)
                mstore(add(free_mem_ptr, 36), size)
                mstore(add(free_mem_ptr, 68), mesg)
                revert(free_mem_ptr, 100)
            }
            if iszero(order_total){
                sendRevert("re_value",8)
            }
            mstore(0x0, contractAddress)
            mstore(0x20, _tokens.slot)
            let hash := keccak256(0x0, 0x40)
            let slot := sload(hash)
            if iszero(and(slot,0xFF)){
                sendRevert("re_contract",11) // wrong contract!
            }
            let token_id := shr(8,slot)
            mstore(0x0, seller)
            mstore(0x20, _users.slot)
            hash := keccak256(0, 0x40)
            slot := sload(hash)
            if iszero(and(slot, 0xFF)) {
                sendRevert("re_usernotexist",15) // user does not exist
            }
            mstore(0x0, caller())
            mstore(0x20, add(hash,1))
            hash := keccak256(0, 0x40)
            mstore(0x0, order_id)
            mstore(0x20, hash)
            hash := keccak256(0, 0x40)
            slot := sload(hash)
            switch gt(and(slot,0xFF), 0)
            case 0 {
                let ptr := mload(0x40)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                mstore(add(ptr, 0x44), order_total)
                let t := call(
                    gas(),
                    contractAddress,
                    0,
                    ptr,
                    0x64,
                    ptr,
                    0x20
                )
                if iszero(returndatasize()) {
                    sendRevert("re_payharvest",13)
                }
                if iszero(t) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
                slot := and(slot,not(0xFF))
                slot := or(slot,and(1,0xFF))
                slot := and(slot,not(shl(8,0xFFFF)))
                slot := or(slot,shl(8,and(token_id,0xFFFF)))
                slot := and(slot,not(shl(24,0xFFFF)))
                slot := or(slot,shl(24,and(order_total,0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)))
                sstore(hash, slot)
            }
            case 1 {
                sendRevert("re_orderpaid",12)
            }
        }
        emit OrderPaid(order_total,order_id,msg.sender,seller,contractAddress);
    }

    /**
    
    Order payment with native network token, order information (buyer, order number amount, and token Id ( 1 ) ).
    Relevant information is recorded in the seller struct with order ID and token ID 1.
    After payment, the order status changes to 1

    **/

    // 23k gas lower than normal methods
    function payWithNativeToken(
        uint256 order_id,
        address seller
    ) external payable {
        assembly {
            function sendRevert(mesg,size){
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(free_mem_ptr, 4), 32)
                mstore(add(free_mem_ptr, 36), size)
                mstore(add(free_mem_ptr, 68), mesg)
                revert(free_mem_ptr, 100)
            }
            if iszero(callvalue()){
                sendRevert("re_value",8)
            }
            mstore(0x0, seller)
            mstore(0x20, _users.slot)
            let hash := keccak256(0, 0x40)
            let slot := sload(hash)
            if iszero(and(slot, 0xFF)) {
                sendRevert("re_usernotexist",15)
            }
            mstore(0x0, caller())
            mstore(0x20, add(hash,1))
            hash := keccak256(0, 0x40)
            mstore(0x0, order_id)
            mstore(0x20, hash)
            hash := keccak256(0, 0x40)
            slot := sload(hash)
            switch gt(and(slot,0xFF), 0)
            case 0 {
                slot := and(slot,not(0xFF))
                slot := or(slot,and(1,0xFF))
                slot := and(slot,not(shl(8,0xFFFF)))
                slot := or(slot,shl(8,and(1,0xFFFF)))
                slot := and(slot,not(shl(24,0xFFFF)))
                slot := or(slot,shl(24,and(callvalue(),0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)))
                //
                sstore(hash, slot)
            }
            case 1 {
                sendRevert("re_orderpaid",12)
            }
        }
        emit OrderPaid(msg.value,order_id,msg.sender,seller,address(0));
    }
    



    // 8k gas lower than normal methods
    function widthrawForSellers(
        address[] memory buyer,
        bytes[] memory signature,
        uint256[] memory order_id,
        address contractAddress
    ) external {
        for (uint8 i = 0; i < order_id.length; ) {
            verifyPaymentSignature(
                order_id[i],
                buyer[i],
                _msgSender(),
                signature[i]
            );
            unchecked{
                i++;
            }
        }
        assembly{
            function sendRevert(mesg,size){
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(free_mem_ptr, 4), 32)
                mstore(add(free_mem_ptr, 36), size)
                mstore(add(free_mem_ptr, 68), mesg)
                revert(free_mem_ptr, 100)
            }
            function sendEmit(_buyer,_order){
                mstore(0x0, "WSeller(uint256,address,address)")
                let t2 := keccak256(0x0, 32) // add(0x0, 32 ) 32 is len of   Deposit(uint256,uint256,address)
                let p := mload(0x40)
                mstore(p, _buyer)
                log3(p, 0x20, t2, _order, caller())
            }
            let orders := mload(order_id)
            if iszero(orders){
                sendRevert("re_wrongdata",12)
            }
            mstore(0x0, contractAddress)
            mstore(0x20, _tokens.slot)
            let hash := keccak256(0x0, 0x40)
            let slot := sload(hash)
            let total := 0
            let token_id := shr(8,slot)
            if iszero(token_id){
                token_id := 1
            }
            for {let i := 0} lt(i, orders) {i := add(i, 1)} {
                mstore(0x0, caller())
                mstore(0x20, _users.slot)
                hash := keccak256(0, 0x40)
                slot := sload(hash)
                let b :=mload(add(buyer, add(0x20, mul(0x20, i))))
                mstore(0x0, b)
                mstore(0x20, add(hash,1))
                hash := keccak256(0, 0x40)
                let id := mload(add(order_id, add(0x20, mul(0x20, i))))
                mstore(0x0, id)
                mstore(0x20, hash)
                hash := keccak256(0, 0x40)
                slot := sload(hash)
                switch and(
                    eq(and(slot,0xFF), 1),
                    eq(shr(8,and(slot,shl(8,0xFFFF))), token_id)
                )
                case 1 {
                    slot := and(slot,not(0xFF))
                    slot := or(slot,and(2,0xFF))
                    sstore(hash, slot)
                    total := add(total,shr(24,slot))
                    sendEmit(b,id)
                }
                case 0 {
                    if eq(shr(8,and(slot,shl(8,0xFFFF))), token_id){
                         if eq(and(slot,0xFF), 2){
                        sendRevert("re_withdrawbyseller",19)
                        }
                        if eq(and(slot,0xFF), 3){
                            sendRevert("re_withdrawbybuyer",18)
                    }
                        sendRevert("re_wrongdata",12)
                    }
                    sendRevert("re_contract",11)
                   
                }   
            }
            let c_p := sload(CONTRACTPERCENTAGE.slot)
            c_p := and(c_p,0xFF)
            if gt(c_p,0){
                let contract_p := div(mul(total, c_p),100)
                total := sub(total,contract_p)
                mstore(0x0, token_id)
                mstore(0x20, _contractBalance.slot)
                hash := keccak256(0, 0x40)
                slot := sload(hash)
                let t := add(contract_p,shr(0,slot))
                slot := and(slot,not(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                slot := or(slot,and(t,0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                sstore(hash,slot)
            }
            switch eq(token_id,1)
            case 1 {
                mstore(0x0,"()")
                hash := keccak256(0x0, 0x2)
                let p := mload(0x40)
                mstore ( p, hash ) 
                let send := call (gas(), 
                caller(),
                total, 
                p,
                0x04,
                p, 
                0x0
                )
                if iszero(send){
                   sendRevert("re_harvest",10)
                }
            }
            case 0 {
                mstore(0x0,"transfer(address,uint256)")
                hash := keccak256(0x0,0x19)
                let ptr := mload(0x40)
                mstore ( ptr, hash ) 
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), total)
                let send := call(
                    gas(),
                    contractAddress,
                    0,
                    ptr,
                    0x44,
                    ptr,
                    0x20
                )
                if iszero(returndatasize()) {
                    sendRevert("re_harvest",10)
                }
                if iszero(send) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }

        }
       
    }
    function widthrowForBuyers(
        address seller,
        bytes memory  signature,
        uint256 order_id,
        address contractAddress
    ) external{
        verifyPaymentSignature(
                    order_id,
                    seller,
                    msg.sender,
                    signature
                );
        assembly{
            function sendRevert(mesg,size){
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(free_mem_ptr, 4), 32)
                mstore(add(free_mem_ptr, 36), size)
                mstore(add(free_mem_ptr, 68), mesg)
                revert(free_mem_ptr, 100)
            }
            mstore(0x0, contractAddress)
            mstore(0x20, _tokens.slot)
            let hash := keccak256(0x0, 0x40)
            let slot := sload(hash)
            let total := 0
            let token_id := shr(8,slot)
            if iszero(token_id){
                token_id := 1
            }
            mstore(0x0, seller)
            mstore(0x20, _users.slot)
            hash := keccak256(0, 0x40)
            slot := sload(hash)
            mstore(0x0, caller())
            mstore(0x20, add(hash,1))
            hash := keccak256(0, 0x40)
            mstore(0x0, order_id)
            mstore(0x20, hash)
            hash := keccak256(0, 0x40)
            slot := sload(hash)
            switch and(
                    eq(and(slot,0xFF), 1),
                    eq(shr(8,and(slot,shl(8,0xFFFF))), token_id)
                )
            case 1 {
                    slot := and(slot,not(0xFF))
                    slot := or(slot,and(3,0xFF))
                    sstore(hash, slot)
                    total := add(total,shr(24,slot))
            }
            case 0 {
                     if eq(shr(8,and(slot,shl(8,0xFFFF))), token_id){
                         if eq(and(slot,0xFF), 2){
                        sendRevert("re_withdrawbyseller",19)
                        }
                        if eq(and(slot,0xFF), 3){
                            sendRevert("re_withdrawbybuyer",18)
                    }
                        sendRevert("re_wrongdata",12)
                    }
                    sendRevert("re_contract",11)
            }
            switch eq(token_id,1)
            case 1 {
                mstore(0x0,"()")
                hash := keccak256(0x0, 0x2)
                let p := mload(0x40)
                mstore ( p, hash ) 
                let send := call (gas(), 
                caller(),
                total, 
                p,
                0x04,
                p, 
                0x0
                )
                if iszero(send){
                    sendRevert("re_harvest",10)
                }
            }
            case 0 {
                mstore(0x0,"transfer(address,uint256)")
                hash := keccak256(0x0,0x19)
                let ptr := mload(0x40)
                mstore ( ptr, hash ) 
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), total)
                let send := call(
                    gas(),
                    contractAddress,
                    0,
                    ptr,
                    0x44,
                    ptr,
                    0x20
                )
                if iszero(returndatasize()) {
                    sendRevert("re_harvest",10)
                }
                if iszero(send) {
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }

        }
        emit WBuyer(order_id,msg.sender,seller);
    }

    function balanceOfContract(address token)external view onlyOwner returns(uint256){
        uint16 token_id =_tokens[token].token;
        if(token_id ==0){
            token_id = 1;
        }
        return _contractBalance[token_id];
    }

    function contractWithdraw(uint256 value, address _contractAddress)
        external
        onlyOwner
    {
        uint16 token_id =_tokens[_contractAddress].token;
        if(token_id == 0){
            token_id = 1;
        }
        require(_contractBalance[token_id] >= value);
        _contractBalance[token_id] -= value;
        if (token_id > 1) {
            ERC20(_contractAddress).transfer(_msgSender(), value);
        } else {
            payable(_msgSender()).transfer(value);
        }
    }


    function payToContract(address token, uint256 value)
        external
        payable
    {
        uint16 token_id =_tokens[token].token;
        if(token_id ==0){
            token_id = 1;
        }
        require(msg.value > 0 && token_id == 1 || value > 0 && token_id >1);
        if (token_id > 1) {
            ERC20(token).transferFrom(
                msg.sender,
                address(this),
                value
            );
            _contractBalance[token_id] += value;
        }else{
            _contractBalance[token_id] += msg.value;
        }
        
    }
    function selectOrder(uint256 order_id,address seller,address buyer) public view returns(uint232,uint16,uint8){
        Lib.Order storage order = _users[seller].orders[buyer][order_id];
        return(order.value,order.token,order.status);
    }

    // 1k gas lower than normal
    function verifyPaymentSignature(
        uint256 order_id,
        address signer,
        address receiver,
        bytes memory signature
    )
        internal
        view
    {
        // How can I convert these two methods into an assembly? 
        // The strings and bytes more than 31 length in the assembly are nerve-wracking :-(
        bytes memory _hash = abi.encodePacked(
            "nonce:",
            Strings.toHexString(uint160(receiver), 20),
            Strings.toString(order_id)
        );
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(_hash.length),
                _hash
            )
        );
        assembly {
             function sendRevert(mesg,size){
                let free_mem_ptr := mload(64)
                mstore(free_mem_ptr, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(add(free_mem_ptr, 4), 32)
                mstore(add(free_mem_ptr, 36), size)
                mstore(add(free_mem_ptr, 68), mesg)
                revert(free_mem_ptr, 100)
            }
            switch mload(signature) // signature length most be 65
            case 65 {
                let pointer := mload(0x40) 
                let s := mload(add(signature, 0x40))
                let v := byte(0, mload(add(signature, 0x60))) 
                mstore(pointer, hash) 
                mstore(add(pointer, 0x20), v) 
                mstore(add(pointer, 0x40), mload(add(signature, 0x20))) 
                mstore(add(pointer, 0x60), s) 
                if gt(s,0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0){ 
                    sendRevert("re_wrongdata",12)
                }
                switch or(eq(v,27),eq(v,28)) 
                case 0 {sendRevert("re_verify",9)}
                if iszero(staticcall(not(0), 0x01, pointer, 0x80, pointer, 0x20)) { 
                    sendRevert("re_verify",9)
                }
                let size := returndatasize()
                returndatacopy(pointer, 0, size)
                let msgSigner := mload(pointer)
                switch eq(msgSigner,signer) 
                case 0 {
                    mstore(0x0, msgSigner)
                    mstore(0x20,_signer.slot)
                    hash := keccak256(0x0, 0x40)
                    let slot := sload(hash)
                    if iszero(and(slot,0xFF)){
                        sendRevert("re_verify",9)
                    }
                }
            }
            default {
                sendRevert("re_verify",9)
            }
            
        }
    }
}