/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// MIT
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


// File @openzeppelin/contracts/utils/[email protected]

// MIT
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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


// File contracts/libs/TransferHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value,gas:5000}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/libs/StringHelper.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev String tools
library StringHelper {

    /// @dev Convert to upper case
    /// @param str Target string
    /// @return Upper case result
    function toUpper(string memory str) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 97 && b <= 122) {
                bs[i] = bytes1(uint8(b - 32));
            }
        }
        return str;
    }

    /// @dev Convert to lower case
    /// @param str Target string
    /// @return Lower case result
    function toLower(string memory str) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        for (uint i = 0; i < bs.length; ++i) {
            uint b = uint(uint8(bytes1(bs[i])));
            if (b >= 65 && b <= 90) {
                bs[i] = bytes1(uint8(b + 32));
            }
        }
        return str;
    }

    /// @dev Get substring
    /// @param str Target string
    /// @param start Start index in target string
    /// @param count Count of result. if length not enough, returns remain.
    /// @return Substring result
    function substring(string memory str, uint start, uint count) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        if (start >= length) {
            count = 0;
        } else if (start + count > length) {
            count = length - start;
        }
        bytes memory buffer = new bytes(count);
        while (count > 0) {
            --count;
            buffer[count] = bs[start + count];
        }
        return string(buffer);
    }

    /// @dev Get substring
    /// @param str Target string
    /// @param start Start index in target string
    /// @return Substring result
    function substring(string memory str, uint start) internal pure returns (string memory) 
    {
        bytes memory bs = bytes(str);
        uint length = bs.length;
        uint count = 0;
        if (start < length) {
            count = length - start;
        }
        bytes memory buffer = new bytes(count);
        while (count > 0) {
            --count;
            buffer[count] = bs[start + count];
        }
        return string(buffer);
    }

    /// @dev Write a uint in decimal. If length less than minLength, fill with 0 front.
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param iv Target uint value
    /// @param minLength Minimal length
    /// @return New offset in target buffer
    function writeUIntDec(bytes memory buffer, uint index, uint iv, uint minLength) internal pure returns (uint) 
    {
        uint i = index;
        minLength += index;
        while (iv > 0 || index < minLength) {
            buffer[index++] = bytes1(uint8(iv % 10 + 48));
            iv /= 10;
        }

        for (uint j = index; j > i;) {
            bytes1 tmp = buffer[i];
            buffer[i++] = buffer[--j];
            buffer[j] = tmp;
        }

        return index;
    }

    /// @dev Write a float in decimal. If length less than minLength, fill with 0 front.
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param fv Target float value
    /// @param decimals Decimal places
    /// @return New offset in target buffer
    function writeFloat(bytes memory buffer, uint index, uint fv, uint decimals) internal pure returns (uint) 
    {
        uint base = 10 ** decimals;
        index = writeUIntDec(buffer, index, fv / base, 1);
        buffer[index++] = bytes1(uint8(46));
        index = writeUIntDec(buffer, index, fv % base, decimals);

        return index;
    }
    
    /// @dev Write a uint in hexadecimal. If length less than minLength, fill with 0 front.
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param iv Target uint value
    /// @param minLength Minimal length
    /// @param upper If upper case
    /// @return New offset in target buffer
    function writeUIntHex(
        bytes memory buffer, 
        uint index, 
        uint iv, 
        uint minLength, 
        bool upper
    ) internal pure returns (uint) 
    {
        uint i = index;
        uint B = upper ? 55 : 87;
        minLength += index;
        while (iv > 0 || index < minLength) {
            uint c = iv & 0xF;
            if (c > 9) {
                buffer[index++] = bytes1(uint8(c + B));
            } else {
                buffer[index++] = bytes1(uint8(c + 48));
            }
            iv >>= 4;
        }

        for (uint j = index; j > i;) {
            bytes1 tmp = buffer[i];
            buffer[i++] = buffer[--j];
            buffer[j] = tmp;
        }

        return index;
    }

    /// @dev Write a part of string to buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param str Target string
    /// @param start Start index in target string
    /// @param count Count of string. if length not enough, use remain.
    /// @return New offset in target buffer
    function writeString(
        bytes memory buffer, 
        uint index, 
        string memory str, 
        uint start, 
        uint count
    ) private pure returns (uint) 
    {
        bytes memory bs = bytes(str);
        uint i = 0;
        while (i < count && start + i < bs.length) {
            buffer[index + i] = bs[start + i];
            ++i;
        }
        return index + i;
    }

    /// @dev Get segment from buffer
    /// @param buffer Target buffer
    /// @param start Start index in buffer
    /// @param count Count of string. if length not enough, returns remain.
    /// @return Segment from buffer
    function segment(bytes memory buffer, uint start, uint count) internal pure returns (bytes memory) 
    {
        uint length = buffer.length;
        if (start >= length) {
            count = 0;
        } else if (start + count > length) {
            count = length - start;
        }
        bytes memory re = new bytes(count);
        while (count > 0) {
            --count;
            re[count] = buffer[start + count];
        }
        return re;
    }

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0) internal pure returns (string memory) {
        return sprintf(format, [arg0, 0, 0, 0, 0]);
    }

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, 0, 0, 0]);
    }

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg2 Argument 2. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, 0, 0]);
    }
    
    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg2 Argument 2. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg3 Argument 3. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, 0]);
    }

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param arg0 Argument 0. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg1 Argument 1. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg2 Argument 2. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg3 Argument 3. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @param arg4 Argument 4. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint arg0, uint arg1, uint arg2, uint arg3, uint arg4) internal pure returns (string memory) {
        return sprintf(format, [arg0, arg1, arg2, arg3, arg4]);
    }
    
    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param args Argument array. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return Format result
    function sprintf(string memory format, uint[5] memory args) internal pure returns (string memory) {
        bytes memory buffer = new bytes(127);
        uint index = sprintf(buffer, 0, bytes(format), args);
        return string(segment(buffer, 0, index));
    }

    /// @dev Format to memory buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param format Format string
    /// @param args Argument array. (string is need to encode with StringHelper.enc, and length can not great than 31)
    /// @return New index in buffer
    function sprintf(
        bytes memory buffer, 
        uint index, 
        bytes memory format, 
        uint[5] memory args
    ) internal pure returns (uint) {

        uint i = 0;
        uint pi = 0;
        uint ai = 0;
        uint state = 0;
        uint w = 0;

        while (i < format.length) {
            uint c = uint(uint8(format[i]));
			// 0. Normal                                             
            if (state == 0) {
                // %
                if (c == 37) {
                    while (pi < i) {
                        buffer[index++] = format[pi++];
                    }
                    state = 1;
                }
                ++i;
            }
			// 1. Check if there is -
            else if (state == 1) {
                // %
                if (c == 37) {
                    buffer[index++] = bytes1(uint8(37));
                    pi = ++i;
                    state = 0;
                } else {
                    state = 3;
                }
            }
			// 3. Find with
            else if (state == 3) {
                while (c >= 48 && c <= 57) {
                    w = w * 10 + c - 48;
                    c = uint(uint8(format[++i]));
                }
                state = 4;
            }
            // 4. Find format descriptor   
			else if (state == 4) {
                uint arg = args[ai++];
                // d
                if (c == 100) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    } else {
                        buffer[index++] = bytes1(uint8(43));
                    }
                    c = 117;
                }
                // u
                if (c == 117) {
                    index = writeUIntDec(buffer, index, arg, w == 0 ? 1 : w);
                }
                // x/X
                else if (c == 120 || c == 88) {
                    index = writeUIntHex(buffer, index, arg, w == 0 ? 1 : w, c == 88);
                }
                // s/S
                else if (c == 115 || c == 83) {
                    index = writeEncString(buffer, index, arg, 0, w == 0 ? 31 : w, c == 83 ? 1 : 0);
                }
                // f
                else if (c == 102) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    }
                    index = writeFloat(buffer, index, arg, w == 0 ? 8 : w);
                }
                pi = ++i;
                state = 0;
                w = 0;
            }
        }

        while (pi < i) {
            buffer[index++] = format[pi++];
        }

        return index;
    }

    /// @dev Encode string to uint. (The length can not great than 31)
    /// @param str Target string
    /// @return Encoded result
    function enc(string memory str) public pure returns (uint) {

        uint i = bytes(str).length;
        require(i < 32, "StringHelper:string too long");
        uint v = 0;
        while (i > 0) {
            v = (v << 8) | uint(uint8(bytes(str)[--i]));
        }

        return (v << 8) | bytes(str).length;
    }

    /// @dev Decode the value that encoded with enc
    /// @param v The value that encoded with enc
    /// @return Decoded value
    function dec(uint v) public pure returns (string memory) {
        uint length = v & 0xFF;
        v >>= 8;
        bytes memory buffer = new bytes(length);
        for (uint i = 0; i < length;) {
            buffer[i++] = bytes1(uint8(v & 0xFF));
            v >>= 8;
        }
        return string(buffer);
    }

    /// @dev Decode the value that encoded with enc and write to buffer
    /// @param buffer Target memory buffer
    /// @param index Start index in buffer
    /// @param v The value that encoded with enc
    /// @param start Start index in target string
    /// @param count Count of string. if length not enough, use remain.
    /// @param charCase 0: original case, 1: upper case, 2: lower case
    /// @return New index in buffer
    function writeEncString(
        bytes memory buffer, 
        uint index, 
        uint v, 
        uint start, 
        uint count,
        uint charCase
    ) public pure returns (uint) {

        uint length = (v & 0xFF) - start;
        if (length > count) {
            length = count;
        }
        v >>= (start + 1) << 3;
        while (length > 0) {
            uint c = v & 0xFF;
            if (charCase == 1 && c >= 97 && c <= 122) {
                c -= 32;
            } else if (charCase == 2 && c >= 65 && c <= 90) {
                c -= 32;
            }
            buffer[index++] = bytes1(uint8(c));
            v >>= 8;
            --length;
        }

        return index;
    }

    // ******** Use abi encode to implement variable arguments ******** //

    /// @dev Format to memory buffer
    /// @param format Format string
    /// @param abiArgs byte array of arguments encoded by abi.encode()
    /// @return Format result
    function sprintf(string memory format, bytes memory abiArgs) internal pure returns (string memory) {
        bytes memory buffer = new bytes(127);
        uint index = sprintf(buffer, 0, bytes(format), abiArgs);
        return string(segment(buffer, 0, index));
    }

    /// @dev Format to memory buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param format Format string
    /// @param abiArgs byte array of arguments encoded by abi.encode()
    /// @return New index in buffer
    function sprintf(
        bytes memory buffer, 
        uint index, 
        bytes memory format, 
        bytes memory abiArgs
    ) internal pure returns (uint) {

        uint i = 0;
        uint pi = 0;
        uint ai = 0;
        uint state = 0;
        uint w = 0;

        while (i < format.length) {
            uint c = uint(uint8(format[i]));
			// 0. Normal                                             
            if (state == 0) {
                // %
                if (c == 37) {
                    while (pi < i) {
                        buffer[index++] = format[pi++];
                    }
                    state = 1;
                }
                ++i;
            }
			// 1. Check if there is -
            else if (state == 1) {
                // %
                if (c == 37) {
                    buffer[index++] = bytes1(uint8(37));
                    pi = ++i;
                    state = 0;
                } else {
                    state = 3;
                }
            }
			// 3. Find width
            else if (state == 3) {
                while (c >= 48 && c <= 57) {
                    w = w * 10 + c - 48;
                    c = uint(uint8(format[++i]));
                }
                state = 4;
            }
            // 4. Find format descriptor   
			else if (state == 4) {
                uint arg = readAbiUInt(abiArgs, ai);
                // d
                if (c == 100) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    } else {
                        buffer[index++] = bytes1(uint8(43));
                    }
                    c = 117;
                }
                // u
                if (c == 117) {
                    index = writeUIntDec(buffer, index, arg, w == 0 ? 1 : w);
                }
                // x/X
                else if (c == 120 || c == 88) {
                    index = writeUIntHex(buffer, index, arg, w == 0 ? 1 : w, c == 88);
                }
                // s/S
                else if (c == 115 || c == 83) {
                    index = writeAbiString(buffer, index, abiArgs, arg, w == 0 ? 31 : w, c == 83 ? 1 : 0);
                }
                // f
                else if (c == 102) {
                    if (arg >> 255 == 1) {
                        buffer[index++] = bytes1(uint8(45));
                        arg = uint(-int(arg));
                    }
                    index = writeFloat(buffer, index, arg, w == 0 ? 8 : w);
                }
                pi = ++i;
                state = 0;
                w = 0;
                ai += 32;
            }
        }

        while (pi < i) {
            buffer[index++] = format[pi++];
        }

        return index;
    }

    /// @dev Read uint from abi encoded data
    /// @param data abi encoded data
    /// @param index start index in data
    /// @return v Decoded result
    function readAbiUInt(bytes memory data, uint index) internal pure returns (uint v) {
        // uint v = 0;
        // for (uint i = 0; i < 32; ++i) {
        //     v = (v << 8) | uint(uint8(data[index + i]));
        // }
        // return v;
        assembly {
            v := mload(add(add(data, 0x20), index))
        }
    }

    /// @dev Read string from abi encoded data
    /// @param data abi encoded data
    /// @param index start index in data
    /// @return Decoded result
    function readAbiString(bytes memory data, uint index) internal pure returns (string memory) {
        return string(segment(data, index + 32, readAbiUInt(data, index)));
    }

    /// @dev Read string from abi encoded data and write to buffer
    /// @param buffer Target buffer
    /// @param index Start index in buffer
    /// @param data Target abi encoded data
    /// @param start Index of string in abi data
    /// @param count Count of string. if length not enough, use remain.
    /// @param charCase 0: original case, 1: upper case, 2: lower case
    /// @return New index in buffer
    function writeAbiString(
        bytes memory buffer, 
        uint index, 
        bytes memory data, 
        uint start, 
        uint count,
        uint charCase
    ) internal pure returns (uint) 
    {
        uint length = readAbiUInt(data, start);
        if (count > length) {
            count = length;
        }
        uint i = 0;
        start += 32;
        while (i < count) {
            uint c = uint(uint8(data[start + i]));
            if (charCase == 1 && c >= 97 && c <= 122) {
                c -= 32;
            } else if (charCase == 2 && c >= 65 && c <= 90) {
                c -= 32;
            }
            buffer[index + i] = bytes1(uint8(c));
            ++i;
        }
        return index + i;
    }
}


// File contracts/nest/interfaces/INestBatchMining.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the mining methods for nest
interface INestBatchMining {
    
    /// @dev PriceChannel open event
    /// @param channelId Target channelId
    /// @param token0 Address of token0, use to mensuration, 0 means eth
    /// @param unit Unit of token0
    /// @param reward Reward token address
    event Open(uint channelId, address token0, uint unit, address reward);

    /// @dev Post event
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param scale Scale of this post. (Which times of unit)
    event Post(uint channelId, uint pairIndex, address miner, uint index, uint scale, uint price);

    /* ========== Structures ========== */
    
    /// @dev Nest mining configuration structure
    struct Config {
        
        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        uint8 maxBiteNestedLevel;
        
        // Price effective block interval. 20
        uint16 priceEffectSpan;

        // The amount of nest to pledge for each post (Unit: 1000). 100
        uint16 pledgeNest;
    }

    /// @dev PriceSheetView structure
    struct PriceSheetView {
        
        // Index of the price sheet
        uint32 index;

        // Address of miner
        address miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remain number of this price sheet
        uint32 remainNum;

        // The eth number which miner will got
        uint32 ethNumBal;

        // The eth number which equivalent to token's value which miner will got
        uint32 tokenNumBal;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // The token price. (1eth equivalent to (price) token)
        uint152 price;
    }

    // Price channel configuration
    struct ChannelConfig {

        // Reward per block standard
        uint96 rewardPerBlock;

        // Post fee(0.0001eth, DIMI_ETHER). 1000
        uint16 postFeeUnit;

        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;

        // Reduction rate(10000 based). 8000
        uint16 reductionRate;
    }

    /// @dev PricePair view
    struct PairView {
        // Target token address
        address target;
        // Count of price sheets
        uint96 sheetCount;
    }

    /// @dev Price channel view
    struct PriceChannelView {
        
        uint channelId;

        // Address of token0, use to mensuration, 0 means eth
        address token0;
        // Unit of token0
        uint96 unit;

        // Reward token address
        address reward;
        // Reward per block standard
        uint96 rewardPerBlock;

        // Reward total
        uint128 vault;
        // The information of mining fee
        uint96 rewards;
        // Post fee(0.0001eth, DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Count of price pairs in this channel
        uint16 count;

        // Address of opener
        address opener;
        // Genesis block of this channel
        uint32 genesisBlock;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // Reduction rate(10000 based). 8000
        uint16 reductionRate;
        
        // Price pair array
        PairView[] pairs;
    }

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Open price channel
    /// @param token0 Address of token0, use to mensuration, 0 means eth
    /// @param unit Unit of token0
    /// @param reward Reward token address
    /// @param tokens Target tokens
    /// @param config Channel configuration
    function open(
        address token0, 
        uint96 unit, 
        address reward, 
        address[] calldata tokens,
        ChannelConfig calldata config
    ) external;

    /// @dev Modify channel configuration
    /// @param channelId Target channelId
    /// @param config Channel configuration
    function modify(uint channelId, ChannelConfig calldata config) external;

    /// @dev Increase vault to channel
    /// @param channelId Target channelId
    /// @param vault Total to increase
    function increase(uint channelId, uint128 vault) external payable;

    /// @dev Decrease vault from channel
    /// @param channelId Target channelId
    /// @param vault Total to decrease
    function decrease(uint channelId, uint128 vault) external;

    /// @dev Get channel information
    /// @param channelId Target channelId
    /// @return Information of channel
    function getChannelInfo(uint channelId) external view returns (PriceChannelView memory);

    /// @dev Post price
    /// @param channelId Target channelId
    /// @param scale Scale of this post. (Which times of unit)
    /// @param equivalents Price array, one to one with pairs
    function post(uint channelId, uint scale, uint[] calldata equivalents) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId Target price channelId
    /// @param pairIndex Target pairIndex. When take token0, use pairIndex direct, or add 65536 conversely
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function take(uint channelId, uint pairIndex, uint index, uint takeNum, uint newEquivalent) external payable;

    /// @dev List sheets by page
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        uint channelId, 
        uint pairIndex, 
        uint offset, 
        uint count, 
        uint order
    ) external view returns (PriceSheetView[] memory);

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId Target channelId
    /// @param indices Two-dimensional array of sheet indices, first means pair indices, seconds means sheet indices
    function close(uint channelId, uint[][] calldata indices) external;

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external;

    /// @dev Estimated mining amount
    /// @param channelId Target channelId
    /// @return Estimated mining amount
    function estimate(uint channelId) external view returns (uint);

    /// @dev Query the quantity of the target quotation
    /// @param channelId Target channelId
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view returns (uint minedBlocks, uint totalShares);

    /// @dev The function returns eth rewards of specified ntoken
    /// @param channelId Target channelId
    function totalETHRewards(uint channelId) external view returns (uint);

    /// @dev Pay
    /// @param channelId Target channelId
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address to, uint value) external;

    /// @dev Donate to dao
    /// @param channelId Target channelId
    /// @param value Amount to receive
    function donate(uint channelId, uint value) external;
}


// File contracts/nest/interfaces/INestBatchPrice2.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestBatchPrice2 {

    /// @dev Get the latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 2 is the block where the ith price is located, and i * 2 + 1 is the ith price
    function triggeredPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 4 is the block where the ith price is located, i * 4 + 1 is the ith price,
    /// i * 4 + 2 is the ith average price and i * 4 + 3 is the ith volatility
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Find the price at block number
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param height Destination block number
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 2 is the block where the ith price is located, and i * 2 + 1 is the ith price
    function findPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        uint height, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return prices Result array, i * count * 2 to (i + 1) * count * 2 - 1 are 
    /// the price results of group i quotation pairs
    function lastPriceList(
        uint channelId, 
        uint[] calldata pairIndices, 
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return prices result of group i quotation pair. Among them, the first two count * are the latest prices, 
    /// and the last four are: trigger price block number, trigger price, average price and volatility
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices);
}


// File contracts/cofix/interfaces/ICoFiXRouter.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines methods for CoFiXRouter
interface ICoFiXRouter {

    /// @dev Register trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @param pool Pool for the trade pair
    function registerPair(address token0, address token1, address pool) external;

    /// @dev Get pool address for trade pair
    /// @param token0 pair-token0. 0 address means eth
    /// @param token1 pair-token1. 0 address means eth
    /// @return pool Pool for the trade pair
    function pairFor(address token0, address token1) external view returns (address pool);

    /// @dev Register routing path
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param path Routing path
    function registerRouterPath(address src, address dest, address[] calldata path) external;

    /// @dev Get routing path from src token address to dest token address
    /// @param src Src token address
    /// @param dest Dest token address
    /// @return path If success, return the routing path, 
    /// each address in the array represents the token address experienced during the trading
    function getRouterPath(address src, address dest) external view returns (address[] memory path);

    /// @dev Maker add liquidity to pool, get pool token (mint XToken to maker) 
    /// (notice: msg.value = amountETH + oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    /// @param  amountToken The amount of Token added to pool
    /// @param  liquidityMin The minimum liquidity maker wanted
    /// @param  to The target address receiving the liquidity pool (XToken)
    /// @param  deadline The deadline of this request
    /// @return xtoken The liquidity share token address obtained
    /// @return liquidity The real liquidity or XToken minted from pool
    function addLiquidity(
        address pool,
        address token,
        uint amountETH,
        uint amountToken,
        uint liquidityMin,
        address to,
        uint deadline
    ) external payable returns (address xtoken, uint liquidity);

    // /// @dev Maker add liquidity to pool, get pool token (mint XToken) and stake automatically 
    // /// (notice: msg.value = amountETH + oracle fee)
    // /// @param  pool The address of pool
    // /// @param  token The address of ERC20 Token
    // /// @param  amountETH The amount of ETH added to pool. (When pool is AnchorPool, amountETH is 0)
    // /// @param  amountToken The amount of Token added to pool
    // /// @param  liquidityMin The minimum liquidity maker wanted
    // /// @param  to The target address receiving the liquidity pool (XToken)
    // /// @param  deadline The deadline of this request
    // /// @return xtoken The liquidity share token address obtained
    // /// @return liquidity The real liquidity or XToken minted from pool
    // function addLiquidityAndStake(
    //     address pool,
    //     address token,
    //     uint amountETH,
    //     uint amountToken,
    //     uint liquidityMin,
    //     address to,
    //     uint deadline
    // ) external payable returns (address xtoken, uint liquidity);

    /// @dev Maker remove liquidity from pool to get ERC20 Token and ETH back (maker burn XToken) 
    /// (notice: msg.value = oracle fee)
    /// @param  pool The address of pool
    /// @param  token The address of ERC20 Token
    /// @param  liquidity The amount of liquidity (XToken) sent to pool, or the liquidity to remove
    /// @param  amountETHMin The minimum amount of ETH wanted to get from pool
    /// @param  to The target address receiving the Token
    /// @param  deadline The deadline of this request
    /// @return amountETH The real amount of ETH transferred from the pool
    /// @return amountToken The real amount of Token transferred from the pool
    function removeLiquidityGetTokenAndETH(
        address pool,
        address token,
        uint liquidity,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountETH, uint amountToken);

    /// @dev Swap exact tokens for tokens
    /// @param  path Routing path. If you need to exchange through multi-level routes, you need to write down all 
    /// token addresses (ETH address is represented by 0) of the exchange path
    /// @param  amountIn The exact amount of Token a trader want to swap into pool
    /// @param  amountOutMin The minimum amount of ETH a trader want to swap out of pool
    /// @param  to The target address receiving the ETH
    /// @param  rewardTo The target address receiving the CoFi Token as rewards
    /// @param  deadline The deadline of this request
    /// @return amountOut The real amount of Token transferred out of pool
    function swapExactTokensForTokens(
        address[] calldata path,
        uint amountIn,
        uint amountOutMin,
        address to,
        address rewardTo,
        uint deadline
    ) external payable returns (uint amountOut);

    // /// @dev Acquire the transaction mining share of the target XToken
    // /// @param xtoken The destination XToken address
    // /// @return Target XToken's transaction mining share
    // function getTradeReward(address xtoken) external view returns (uint);
}


// File contracts/interfaces/IAbcMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for nest builtin contract address mapping
interface IAbcMapping {

    /// @dev Set the built-in contract address of the system
    /// @param abcPlatform Address of AbcPlatform
    /// @param abcLedger Address of AbcLedger
    /// @param cofixRouter Address of CoFiXRouter
    /// @param nestOpenPlatform Address of NestOpenPlatform
    /// @param usdtToken Address of usdt
    function setBuiltinAddress(
        address abcPlatform,
        address abcLedger,
        address cofixRouter,
        address nestOpenPlatform,
        address usdtToken
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return abcPlatform Address of AbcPlatform
    /// @return abcLedger Address of AbcLedger
    /// @return cofixRouter Address of CoFiXRouter
    /// @return nestOpenPlatform Address of NestOpenPlatform
    /// @return usdtToken Address of usdt
    function getBuiltinAddress() external view returns (
        address abcPlatform,
        address abcLedger,
        address cofixRouter,
        address nestOpenPlatform,
        address usdtToken
    );

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);
}


// File contracts/interfaces/IAbcGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface IAbcGovernance is IAbcMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/interfaces/IAbcPlatform.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest abc
interface IAbcPlatform {

    /// @dev New project event
    /// @param projectId Index of project
    /// @param target Reserve token address
    /// @param stablecoin Stablecoin address
    /// @param opener Opener of this project
    event NewProject(uint projectId, address target, address stablecoin, address opener);

    /// @dev Project information
    struct ProjectView {

        uint index;

        // The channelId for call nest price
        uint16 channelId;
        // The pairIndex for call nest price
        uint16 pairIndex;
        // Reward rate
        uint16 stakingRewardRate;
        uint48 sigmaSQ;// = 102739726027;
        // Reserve token address
        address target;

        // Post unit of target token in nest
        uint96 postUnit;
        // Stablecoin address
        address stablecoin;

        // Opener of this project
        address opener;
        uint32 openBlock;
    }
    
    /// @dev Find the projects of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param opener Target address
    /// @return projectArray Matched project array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address opener
    ) external view returns (ProjectView[] memory projectArray);

    /// @dev List projects
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return projectArray Matched project array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view returns (ProjectView[] memory projectArray);

    /// @dev Obtain the number of projects that have been opened
    /// @return Number of projects opened
    function getProjectCount() external view returns (uint);

    /// @dev Open new project
    /// @param channelId The channelId for call nest price
    /// @param pairIndex The pairIndex for call nest price
    /// @param stakingRewardRate Reward rate
    function open(
        uint16 channelId,
        uint16 pairIndex,
        uint16 stakingRewardRate
    ) external;

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mint(uint projectId, uint amount) external payable;

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mintAndStake(uint projectId, uint amount) external payable;

    /// @dev Burn stablecoin and get target token
    /// @param projectId project Index
    /// @param amount Amount of stablecoin
    function burn(uint projectId, uint amount) external payable;

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Calculate the impact cost
    /// @param vol Trade amount in dcu
    /// @return Impact cost
    function impactCost(uint vol) external pure returns (uint);

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ sigmaSQ for token
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) external view returns (uint k);
}


// File contracts/interfaces/IAbcStableCoin.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface IAbcStableCoin {

    /// @dev Mint 
    /// @param to Address to receive mined token
    /// @param amount Amount to mint
    function mint(address to, uint amount) external;

    /// @dev Mint ex
    /// @param account1 Address to receive mined token
    /// @param amount1 Amount to mint
    /// @param account2 Address to receive mined token
    /// @param amount2 Amount to mint
    function mintEx(address account1, uint256 amount1, address account2, uint amount2) external;

    /// @dev Burn
    /// @param from Address to burn token
    /// @param amount Amount to burn
    function burn(address from, uint amount) external;

    /// @dev Pay
    /// @param target Address of target token
    /// @param to Address to receive token
    /// @param value Pay value
    function pay(address target, address to, uint value) external;
}


// File contracts/interfaces/IAbcVaultForStaking.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest abc
interface IAbcVaultForStaking {

    /// @dev Get staked amount of target address
    /// @param projectId project Index
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(uint projectId, address addr) external view returns (uint);

    /// @dev Get the amount of reward
    /// @param projectId project Index
    /// @param addr Target address
    /// @return The amount of reward
    function earned(uint projectId, address addr) external view returns (uint);

    /// @dev Stake stablecoin and to earn reward
    /// @param projectId project Index
    /// @param amount Stake amount
    function stake(uint projectId, uint amount) external;

    /// @dev Withdraw stablecoin and claim reward
    /// @param projectId project Index
    function withdraw(uint projectId) external;

    /// @dev Claim reward
    /// @param projectId project Index
    function getReward(uint projectId) external;
}


// File contracts/AbcBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of nest
contract AbcBase {

    /// @dev IAbcGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance IAbcGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "ABC:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance IAbcGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || IAbcGovernance(governance).checkGovernance(msg.sender, 0), "ABC:!gov");
        _governance = newGovernance;
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(IAbcGovernance(_governance).checkGovernance(msg.sender, 0), "ABC:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "ABC:!contract");
        _;
    }
}


// File contracts/SimpleERC20.sol

// MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
abstract contract SimpleERC20 is IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view virtual override returns (uint256) {
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
    function transfer(address to, uint256 amount) external virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
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
    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
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
        _spendAllowance(from, msg.sender, amount);
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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
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
        //require(from != address(0), "ERC20: transfer from the zero address");
        //require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
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
        //require(account != address(0), "ERC20: mint to the zero address");

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
        //require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        //require(owner != address(0), "ERC20: approve from the zero address");
        //require(spender != address(0), "ERC20: approve to the zero address");

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
}


// File contracts/AbcStableCoin.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This contract implemented the mining logic of nest
contract AbcStableCoin is SimpleERC20, IAbcStableCoin {

    /// @dev Index of project
    uint immutable PROJECT_ID;

    /// @dev Address of AbcPlatform
    address immutable ABC_PLATFORM;

    /// @dev Name of the token
    string _name;

    /// @dev Symbol of the token
    string _symbol;

    modifier onlyPlatform() {
        require(msg.sender == ABC_PLATFORM, "AbcStableCoin:not platform");
        _;
    }

    /// @dev Constructor
    /// @param name_ Name of the token
    /// @param symbol_ Symbol of the token
    /// @param projectId Index of project
    constructor(
        string memory name_,
        string memory symbol_,
        uint projectId
    ) {
        _name = name_;
        _symbol = symbol_;

        PROJECT_ID = projectId;
        ABC_PLATFORM = msg.sender;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /// @dev Mint 
    /// @param to Address to receive mined token
    /// @param amount Amount to mint
    function mint(address to, uint amount) external override onlyPlatform {
        _mint(to, amount);
    }

    /// @dev Mint ex
    /// @param account1 Address to receive mined token
    /// @param amount1 Amount to mint
    /// @param account2 Address to receive mined token
    /// @param amount2 Amount to mint
    function mintEx(address account1, uint256 amount1, address account2, uint amount2) external override onlyPlatform {
        _totalSupply += amount1 + amount2;
        _balances[account1] += amount1;
        _balances[account2] += amount2;
        emit Transfer(address(0), account1, amount1);
        emit Transfer(address(0), account2, amount2);
    }

    /// @dev Burn
    /// @param from Address to burn token
    /// @param amount Amount to burn
    function burn(address from, uint amount) external override onlyPlatform {
        _burn(from, amount);
    }

    /// @dev Pay
    /// @param target Address of target token
    /// @param to Address to receive token
    /// @param value Pay value
    function pay(address target, address to, uint value) external override onlyPlatform {
        if (target == address(0)) {
            payable(to).transfer(value);
        } else {
            TransferHelper.safeTransfer(target, to, value);
        }
    }

    receive() external payable {

    }
}


// File contracts/AbcPlatform.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This contract implemented the mining logic of nest abc
contract AbcPlatform is AbcBase, IAbcPlatform, IAbcVaultForStaking {

    // TODO: Set BTC address
    /// @dev Address of BTC
    address constant BTC_TOKEN_ADDRESS = address(0);

    /// @dev Post unit of target token in nest must be 2000 ether
    //uint constant uint POST_UNIT = 2000 ether;

    // Block average time
    uint constant BLOCK_TIME = 14;
    // Blocks in one year, 2400000 for ethereum
    uint constant ONE_YEAR_BLOCK = 2400000;

    // Address of CoFiXRouter
    address COFIX_ROUTER;

    address ABC_LEDGER;

    // Address of NestBatchPlatform
    address NEST_OPEN_PLATFORM;

    // Address of usdt
    address _usdtAddress;

    /// @dev Account information
    struct Account {
        // Staked of current account
        uint160 balance;
        // Token dividend value mark of the unit that the account has received
        uint96 blockCursor;
    }

    /// @dev Project configuration structure
    struct ProjectConfig {
        // // The channelId for call nest price
        // uint16 channelId;
        // // The pairIndex for call nest price
        // uint16 pairIndex;
        // // Reward rate
        // uint16 stakingRewardRate;
        // await nestOpenPool.setConfig(0, 1, 2000000000000000000000n, 30, 10, 2000, 102739726027n);
        // Standard sigmaSQ: eth, btc and other (use nest value)
        uint48 sigmaSQ;
    }

    /// @dev Project core information
    struct ProjectCore {
        // The channelId for call nest price
        uint16 channelId;
        // The pairIndex for call nest price
        uint16 pairIndex;
        // Reward rate
        uint16 stakingRewardRate;
        uint48 sigmaSQ;// = 102739726027;
        // Reserve token address
        address target;

        // Post unit of target token in nest
        uint96 postUnit;
        // Stablecoin address
        address stablecoin;
    }

    /// @dev Project information
    struct Project {
        
        // Core information
        ProjectCore core;

        // Opener of this project
        address opener;
        // Open block number
        uint32 openBlock;

        // Accounts
        // address=>balance
        mapping(address=>Account) accounts;
    }

    // Project array
    Project[] _projects;

    // Project mapping
    mapping(bytes32=>uint) _projectMapping;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual override {
        super.update(newGovernance);
        (
            , 
            ABC_LEDGER, 
            COFIX_ROUTER, 
            NEST_OPEN_PLATFORM, 
            _usdtAddress
        ) = IAbcGovernance(newGovernance).getBuiltinAddress();
    }

    /// @dev UnRegister project
    /// @param projectId project Index
    function unRegister(uint projectId) external onlyGovernance {
        ProjectCore memory core = _projects[projectId].core;
        _projectMapping[_getKey(core.target, core.stablecoin)] = 0;
    }
    
    /// @dev Find the projects of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given contract address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param opener Target address
    /// @return projectArray Matched project array
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address opener
    ) external view override returns (ProjectView[] memory projectArray) {
        projectArray = new ProjectView[](count);
        // Calculate search region
        Project[] storage projects = _projects;
        uint end = 0;
        if (start == 0) {
            start = projects.length;
        }
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && start > end;) {
            Project storage project = projects[--start];
            if (project.opener == opener) {
                projectArray[index++] = _toProjectView(project, start);
            }
        }
    }

    /// @dev List projects
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return projectArray Matched project array
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (ProjectView[] memory projectArray) {
        // Load projects
        Project[] storage projects = _projects;
        // Create result array
        projectArray = new ProjectView[](count);
        uint length = projects.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                Project storage project = projects[--index];
                projectArray[i++] = _toProjectView(project, index);
            }
        } 
        // Positive order
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                projectArray[i++] = _toProjectView(projects[index], index);
                ++index;
            }
        }
    }

    /// @dev Obtain the number of projects that have been opened
    /// @return Number of projects opened
    function getProjectCount() external view override returns (uint) {
        return _projects.length;
    }

    /// @dev Open new project
    /// @param channelId The channelId for call nest price
    /// @param pairIndex The pairIndex for call nest price
    /// @param stakingRewardRate Reward rate
    function open(
        uint16 channelId,
        uint16 pairIndex,
        uint16 stakingRewardRate
    ) external override {
        // Load channel information
        INestBatchMining.PriceChannelView memory ci = INestBatchMining(NEST_OPEN_PLATFORM).getChannelInfo(channelId);
        // Check channel
        require(ci.token0 == _usdtAddress, "NAP:token0 must be USDT");
        require(uint(ci.unit) > 0 && uint(ci.unit) < type(uint96).max, "NAP:unit must be 2000");

        address target = ci.pairs[pairIndex].target;
        uint projectId = _projects.length;

        // Create stablecoin
        address stablecoin = address(new AbcStableCoin(
            target == address(0) ?
                 "Stablecoin for ETH" : StringHelper.sprintf("Stablecoin for %s", abi.encode(ERC20(target).name())),
            target == address(0) ?
                "U-ETH" : StringHelper.sprintf("U-%4s", abi.encode(ERC20(target).symbol())),
            projectId
        ));
        
        emit NewProject(projectId, target, stablecoin, msg.sender);

        uint sigmaSQ;
        // Set sigmaSQ
        if (target == address(0)) {
            // ETH
            //sigmaSQ = (45659142400);
            sigmaSQ = (102739726027);
        } else if (target == BTC_TOKEN_ADDRESS) {
            // BTC
            sigmaSQ = (31708924900);
        } else {
            // OTHER
            sigmaSQ = (102739726027);
        }

        // Create project information
        Project storage project = _projects.push();
        project.core = ProjectCore(
            channelId, 
            pairIndex, 
            stakingRewardRate, 
            uint48(sigmaSQ), 
            target, 
            uint96(ci.unit), 
            stablecoin
        );
        project.opener = msg.sender;
        project.openBlock = uint32(block.number);

        // Register to cofixRouter
        _projectMapping[_getKey(target, stablecoin)] = projectId + 1;
        ICoFiXRouter(COFIX_ROUTER).registerPair(target, stablecoin, address(this));
    }

    /// @dev Modify project configuration
    /// @param projectId project Index
    /// @param config project configuration
    function modify(uint projectId, ProjectConfig calldata config) external onlyGovernance {
        Project storage project = _projects[projectId];
        project.core.sigmaSQ = config.sigmaSQ;
    }

    /// @dev Swap token
    /// @param src Src token address
    /// @param dest Dest token address
    /// @param to The target address receiving the ETH
    /// @param payback As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return amountOut The real amount of ETH transferred out of pool
    /// @return mined The amount of CoFi which will be mind by this trade
    function swap(
        address src, 
        address dest, 
        uint amountIn, 
        address to, 
        address payback
    ) external payable returns (
        uint amountOut, 
        uint mined
    ) {
        // Must from cofixRouter
        require(msg.sender == COFIX_ROUTER, "APF:not cofixRouter");
        
        // Load project information
        ProjectCore memory core = _projects[_projectMapping[_getKey(src, dest)] - 1].core;

        // Check src and dest
        require(src == core.target && dest == core.stablecoin, "APF:pair not allowed");

        uint fee = msg.value;
        if (core.target == address(0)) {
            fee -= amountIn;
            payable(core.stablecoin).transfer(amountIn);
        } else {
            TransferHelper.safeTransfer(core.target, core.stablecoin, amountIn);
        }

        _mintInternal(core, amountIn, to, fee, payback);

        mined = 0;
    }

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mint(uint projectId, uint amount) external payable override {
        // Load project
        ProjectCore memory core = _projects[projectId].core;
        
        uint fee = msg.value;
        if (core.target == address(0)) {
            fee -= amount;
            payable(core.stablecoin).transfer(amount);
        } else {
            TransferHelper.safeTransferFrom(core.target, msg.sender, core.stablecoin, amount);
        }

        _mintInternal(core, amount, msg.sender, fee, msg.sender);
    }

    /// @dev Burn stablecoin and get target token
    /// @param projectId project Index
    /// @param amount Amount of stablecoin
    function burn(uint projectId, uint amount) external payable override {
        // Load project
        ProjectCore memory core = _projects[projectId].core;
        address stablecoin = core.stablecoin;

        // Query oracle price
        uint oraclePrice = _queryPrice(core, 0, false, msg.value, msg.sender);
        uint value = amount * oraclePrice / uint(core.postUnit);

        // Burn
        IAbcStableCoin(stablecoin).burn(msg.sender, amount);
        // Pay
        IAbcStableCoin(stablecoin).pay(core.target, msg.sender, value);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    /// @dev Get staked amount of target address
    /// @param projectId project Index
    /// @param addr Target address
    /// @return Staked amount of target address
    function balanceOf(uint projectId, address addr) external view override returns (uint) {
        return uint(_projects[projectId].accounts[addr].balance);
    }

    /// @dev Get the amount of reward
    /// @param projectId project Index
    /// @param addr Target address
    /// @return The amount of reward
    function earned(uint projectId, address addr) external view override returns (uint) {
        // Load project
        Project storage project = _projects[projectId];
        // Call _calcReward() to calculate new reward
        return _calcReward(project, project.accounts[addr]);
    }

    /// @dev Stake stablecoin and to earn reward
    /// @param projectId project Index
    /// @param amount Stake amount
    function stake(uint projectId, uint amount) external override {

        // Load stake channel
        Project storage project = _projects[projectId];
        
        // Transfer stable from msg.sender to this
        TransferHelper.safeTransferFrom(project.core.stablecoin, msg.sender, address(this), uint(amount));
        
        // Settle reward for account
        Account memory account = project.accounts[msg.sender];

        // Update stake balance of account
        account.balance = _toUInt160(uint(account.balance) + amount + _updateReward(project, account));
        //account.blockCursor = uint96(block.number);

        project.accounts[msg.sender] = account;
    }

    /// @dev Mint stablecoin with target token
    /// @param projectId project Index
    /// @param amount Amount of target token
    function mintAndStake(uint projectId, uint amount) external payable override {
        // Load project
        Project storage project = _projects[projectId];
        ProjectCore memory core = project.core;
        
        uint fee = msg.value;
        if (core.target == address(0)) {
            fee -= amount;
            payable(core.stablecoin).transfer(amount);
        } else {
            TransferHelper.safeTransferFrom(core.target, msg.sender, core.stablecoin, amount);
        }

        uint value = _mintInternal(core, amount, address(this), fee, msg.sender);

        // Settle reward for account
        Account memory account = project.accounts[msg.sender];

        // Update stake balance of account
        account.balance = _toUInt160(uint(account.balance) + value + _updateReward(project, account));
        //account.blockCursor = uint96(block.number);

        project.accounts[msg.sender] = account;
    }

    /// @dev Withdraw stablecoin and claim reward
    /// @param projectId project Index
    function withdraw(uint projectId) external override {
        // Load stake channel
        Project storage project = _projects[projectId];

        // Settle reward for account
        Account memory account = project.accounts[msg.sender];
        uint amount = uint(account.balance) + _updateReward(project, account);

        // Update stake balance of account
        account.balance = uint160(0);
        //account.blockCursor = uint96(block.number);
        project.accounts[msg.sender] = account;

        // Transfer stablecoin to msg.sender
        TransferHelper.safeTransfer(project.core.stablecoin, msg.sender, amount);
    }

    /// @dev Claim reward
    /// @param projectId project Index
    function getReward(uint projectId) external override {
        Project storage project = _projects[projectId];
        Account memory account = project.accounts[msg.sender];
        project.accounts[msg.sender] = account;
        TransferHelper.safeTransfer(project.core.stablecoin, msg.sender, _updateReward(project, account));
        // account.blockCursor = uint96(block.number);
    }

    /// @dev Calculate the impact cost
    /// @param vol Trade amount in usdt
    /// @return Impact cost
    function impactCost(uint vol) public pure override returns (uint) {
        //impactCost = vol / 10000 / 1000;
        //return vol / 10000000;
        require(vol >= 0, "APF:nop");
        return 0;
    }

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ sigmaSQ for token
    /// @param p0 Last price (number of tokens equivalent to 1 ETH)
    /// @param bn0 Block number of the last price
    /// @param p Latest price (number of tokens equivalent to 1 ETH)
    /// @param bn The block number when (ETH, TOKEN) price takes into effective
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view override returns (uint k) {
        uint sigmaISQ = p * 1 ether / p0;
        if (sigmaISQ > 1 ether) {
            sigmaISQ -= 1 ether;
        } else {
            sigmaISQ = 1 ether - sigmaISQ;
        }

        // The left part change to: Max((p2 - p1) / p1, 0.002)
        if (sigmaISQ > 0.002 ether) {
            k = sigmaISQ;
        } else {
            k = 0.002 ether;
        }

        sigmaISQ = sigmaISQ * sigmaISQ / (bn - bn0);

        if (sigmaISQ > sigmaSQ * BLOCK_TIME * 1 ether) {
            k += _sqrt(sigmaISQ * (block.number - bn));
        } else {
            k += _sqrt(1 ether * BLOCK_TIME * sigmaSQ * (block.number - bn));
        }
    }

    // Calculate sqrt of x
    function _sqrt(uint256 x) private pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }
    
    // Generate the mapping key based on the token address
    function _getKey(address token0, address token1) private pure returns (bytes32) {
        (token0, token1) = _sort(token0, token1);
        return keccak256(abi.encodePacked(token0, token1));
    }

    // Sort the address pair
    function _sort(address token0, address token1) private pure returns (address min, address max) {
        if (token0 < token1) {
            min = token0;
            max = token1;
        } else {
            min = token1;
            max = token0;
        }
    }

    // Ming logic    
    function _mintInternal(
        ProjectCore memory core, 
        uint amount, 
        address to, 
        uint fee, 
        address payback
    ) private returns (uint value) {

        uint oraclePrice = _queryPrice(core, 0, true, fee, payback);

        // Calculate mint value
        value = uint(core.postUnit) * amount / oraclePrice;

        // Mint
        IAbcStableCoin(core.stablecoin).mintEx(to, value, ABC_LEDGER, value / 100);
    }

    /// @dev Query price
    /// @param core Target project core information
    /// @param scale Scale of this transaction
    /// @param enlarge Modify the OraclePrice, enlarge or reduce
    /// @param fee Oracle fee
    /// @param payback Address to receive refund
    function _queryPrice(
        ProjectCore memory core,
        uint scale, 
        bool enlarge, 
        uint fee,
        address payback
    ) private returns (uint oraclePrice) {

        // Query price from oracle
        uint[] memory pairIndices = new uint[](1);
        pairIndices[0] = uint(core.pairIndex);
        uint[] memory prices = INestBatchPrice2(NEST_OPEN_PLATFORM).lastPriceList {
            value: fee
        } (uint(core.channelId), pairIndices, 2, payback);

        // Convert to usdt based price
        oraclePrice = prices[1];
        uint k = calcRevisedK(uint(core.sigmaSQ), prices[3], prices[2], oraclePrice, prices[0]);

        // Make corrections to the price
        if (enlarge) {
            oraclePrice = oraclePrice * (1 ether + k + impactCost(scale)) / 1 ether;
        } else {
            oraclePrice = oraclePrice * 1 ether / (1 ether + k + impactCost(scale));
        }
    }
    
    // Calculate new reward
    function _calcReward(Project storage project, Account memory account) private view returns (uint newReward) {
        // Call _calcReward() to calculate new reward
        return uint(account.balance) * uint(project.core.stakingRewardRate) * (block.number - account.blockCursor) 
                / ONE_YEAR_BLOCK / 10000;
    }

    // Update account
    function _updateReward(Project storage project, Account memory account) private returns (uint newReward) {
        // Call _calcReward() to calculate new reward
        newReward = _calcReward(project, account);
        IAbcStableCoin(project.core.stablecoin).mint(address(this), newReward);
        account.blockCursor = uint96(block.number);
    }

    // Convert uint to uint160
    function _toUInt160(uint v) private pure returns (uint160) {
        require(v <= type(uint160).max, "APF:can't convert to uint160");
        return uint160(v);
    }

    // Convert to ProjectView
    function _toProjectView(Project storage project, uint index) private view returns (ProjectView memory projectView) {
        projectView = ProjectView(
            index,
            project.core.channelId,
            project.core.pairIndex,
            project.core.stakingRewardRate,
            project.core.sigmaSQ,
            project.core.target,
            project.core.postUnit,
            project.core.stablecoin,
            project.opener,
            project.openBlock
        );
    }
}