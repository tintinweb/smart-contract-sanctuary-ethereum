/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

/**
 *
 *
 */

// Meta Real
// Version: 1
// Website: metarealcrypto.com
// Twitter: https://twitter.com/metarealcrypto (@metarealcrypto)
// TG: https://t.me/metarealcryptoCommunity
// Facebook: https://www.facebook.com/metarealcrypto
// Instagram: https://www.instagram.com/metarealcrypto/
// Medium: https://medium.com/@metarealcrypto
// Reddit: https://www.reddit.com/r/metarealcrypto/
// Discord: https://discord.gg/metarealcrypto

pragma solidity ^0.8.17;
// SPDX-License-Identifier: Unlicensed
interface IUniswapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

}

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            allowance(msg.sender, spender) + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
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
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
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

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}
  /**
   * @title ContractName
   * @dev ContractDescription
   * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
   */
  contract ContractName {}

    contract MREAL is ERC20, Ownable {
    address payable public marketingFeeAddress;
    address payable public stakingFeeAddress;

    uint16 constant feeDenominator = 1000;
    uint16 constant lpDenominator = 1000;
    uint16 constant maxFeeLimit = 300;

    bool public tradingActive;

    mapping(address => bool) public isExcludedFromFee;

    uint16 public buyBurnFee = 10;
    uint16 public buyLiquidityFee = 10;
    uint16 public buyMarketingFee = 35;
    uint16 public buyStakingFee = 20;

    uint16 public sellBurnFee = 10;
    uint16 public sellLiquidityFee = 20;
    uint16 public sellMarketingFee = 40;
    uint16 public sellStakingFee = 30;

    uint16 public transferBurnFee = 10;
    uint16 public transferLiquidityFee = 5;
    uint16 public transferMarketingFee = 5;
    uint16 public transferStakingFee = 20;

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingFeeTokensToSwap;
    uint256 private _burnFeeTokens;
    uint256 private _stakingFeeTokens;

    uint256 private lpTokens;

    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public botWallet;
    address[] public botWallets;
    uint256 public minLpBeforeSwapping;

    IUniswapRouter02 public immutable uniswapRouter;
    address public immutable uniswapPair;
    address public bridgeAddress;

    bool inSwapAndLiquify;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }


    constructor() ERC20("Meta Real", "MREAL") {
        _mint(msg.sender, 1e11 * 10**decimals());

        marketingFeeAddress = payable(
            0x7F9c98E3fEc26974C013d53762fAF53d9e416536
        );
        stakingFeeAddress = payable(0x7F9c98E3fEc26974C013d53762fAF53d9e416536);

        minLpBeforeSwapping = 10; // this means: 10 / 1000 = 1% of the liquidity pool is the threshold before swapping

        // address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Mainnet
        address routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Mainnet
        uniswapRouter = IUniswapRouter02(payable(routerAddress));

        uniswapPair = IFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingFeeAddress] = true;
        isExcludedFromFee[stakingFeeAddress] = true;

        _limits[msg.sender].isExcluded = true;
        _limits[address(this)].isExcluded = true;
        _limits[routerAddress].isExcluded = true;

        // Limits Configuration
        globalLimit = 25 ether;
        globalLimitPeriod = 24 hours;
        limitsActive = true;

        _approve(msg.sender, routerAddress, ~uint256(0));
        _setAutomatedMarketMakerPair(uniswapPair, true);
        bridgeAddress = 0x7F9c98E3fEc26974C013d53762fAF53d9e416536;
        isExcludedFromFee[bridgeAddress] = true;
        _limits[bridgeAddress].isExcluded = true;
        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }

    function increaseRouterAllowance(address routerAddress) external onlyOwner {
        _approve(address(this), routerAddress, type(uint256).max);
    }

    function migrateBridge(address newAddress) external onlyOwner {
        require(
            newAddress != address(0) && !automatedMarketMakerPairs[newAddress],
            "Can't set this address"
        );
        bridgeAddress = newAddress;
        isExcludedFromFee[newAddress] = true;
        _limits[newAddress].isExcluded = true;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function addBotWallet(address wallet) external onlyOwner {
        require(!botWallet[wallet], "Wallet already added");
        botWallet[wallet] = true;
        botWallets.push(wallet);
    }

    function addBotWalletBulk(address[] memory wallets) external onlyOwner {
        for (uint256 i = 0; i < wallets.length; i++) {
            require(!botWallet[wallets[i]], "Wallet already added");
            botWallet[wallets[i]] = true;
            botWallets.push(wallets[i]);
        }
    }

    function getBotWallets() external view returns (address[] memory) {
        return botWallets;
    }

    function removeBotWallet(address wallet) external onlyOwner {
        require(botWallet[wallet], "Wallet not added");
        botWallet[wallet] = false;
        for (uint256 i = 0; i < botWallets.length; i++) {
            if (botWallets[i] == wallet) {
                botWallets[i] = botWallets[botWallets.length - 1];
                botWallets.pop();
                break;
            }
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
    }

    function disableTrading() external onlyOwner {
        tradingActive = false;
    }

    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() - bridgeBalance();
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (account == bridgeAddress) return 0;
        return super.balanceOf(account);
    }

    function bridgeBalance() public view returns (uint256) {
        return super.balanceOf(bridgeAddress);
    }

    function updateMinLpBeforeSwapping(uint256 minLpBeforeSwapping_)
        external
        onlyOwner
    {
        minLpBeforeSwapping = minLpBeforeSwapping_;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(pair != uniswapPair, "The pair cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function updateBuyFee(
        uint16 _buyBurnFee,
        uint16 _buyLiquidityFee,
        uint16 _buyMarketingFee,
        uint16 _buyStakingFee
    ) external onlyOwner {
        buyBurnFee = _buyBurnFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        buyStakingFee = _buyStakingFee;
        require(
            _buyBurnFee +
                _buyLiquidityFee +
                _buyMarketingFee +
                _buyStakingFee <=
                maxFeeLimit,
            "Must keep fees below 30%"
        );
    }

    function updateSellFee(
        uint16 _sellBurnFee,
        uint16 _sellLiquidityFee,
        uint16 _sellMarketingFee,
        uint16 _sellStakingFee
    ) external onlyOwner {
        sellBurnFee = _sellBurnFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        sellStakingFee = _sellStakingFee;
        require(
            _sellBurnFee +
                _sellLiquidityFee +
                _sellMarketingFee +
                _sellStakingFee <=
                maxFeeLimit,
            "Must keep fees <= 30%"
        );
    }

    function updateTransferFee(
        uint16 _transferBurnFee,
        uint16 _transferLiquidityFee,
        uint16 _transferMarketingFee,
        uint16 _transferStakingfee
    ) external onlyOwner {
        transferBurnFee = _transferBurnFee;
        transferLiquidityFee = _transferLiquidityFee;
        transferMarketingFee = _transferMarketingFee;
        transferStakingFee = _transferStakingfee;
        require(
            _transferBurnFee +
                _transferLiquidityFee +
                _transferMarketingFee +
                _transferStakingfee <=
                maxFeeLimit,
            "Must keep fees <= 30%"
        );
    }

    function updateMarketingFeeAddress(address marketingFeeAddress_)
        external
        onlyOwner
    {
        require(marketingFeeAddress_ != address(0), "Can't set 0");
        marketingFeeAddress = payable(marketingFeeAddress_);
    }

    function updateStakingAddress(address stakingFeeAddress_)
        external
        onlyOwner
    {
        require(stakingFeeAddress_ != address(0), "Can't set 0");
        stakingFeeAddress = payable(stakingFeeAddress_);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!tradingActive) {
            require(
                isExcludedFromFee[from] || isExcludedFromFee[to],
                "Trading is not active yet."
            );
        }
        require(!botWallet[from] && !botWallet[to], "Bot wallet");
        checkLiquidity();

        if (
            hasLiquidity && !inSwapAndLiquify && automatedMarketMakerPairs[to]
        ) {
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                contractTokenBalance >=
                (lpTokens * minLpBeforeSwapping) / lpDenominator
            ) takeFee(contractTokenBalance);
        }

        uint256 _burnFee;
        uint256 _liquidityFee;
        uint256 _marketingFee;
        uint256 _stakingFee;

        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _burnFee = (amount * buyBurnFee) / feeDenominator;
                _liquidityFee = (amount * buyLiquidityFee) / feeDenominator;
                _marketingFee = (amount * buyMarketingFee) / feeDenominator;
                _stakingFee = (amount * buyStakingFee) / feeDenominator;
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _burnFee = (amount * sellBurnFee) / feeDenominator;
                _liquidityFee = (amount * sellLiquidityFee) / feeDenominator;
                _marketingFee = (amount * sellMarketingFee) / feeDenominator;
                _stakingFee = (amount * sellStakingFee) / feeDenominator;
            } else {
                _burnFee = (amount * transferBurnFee) / feeDenominator;
                _liquidityFee =
                    (amount * transferLiquidityFee) /
                    feeDenominator;
                _marketingFee =
                    (amount * transferMarketingFee) /
                    feeDenominator;
                _stakingFee = (amount * transferStakingFee) / feeDenominator;
            }

            _handleLimited(
                from,
                to,
                amount - _burnFee - _liquidityFee - _marketingFee - _stakingFee
            );
        }

        uint256 _transferAmount = amount -
            _burnFee -
            _liquidityFee -
            _marketingFee -
            _stakingFee;
        super._transfer(from, to, _transferAmount);
        uint256 _feeTotal = _burnFee +
            _liquidityFee +
            _marketingFee +
            _stakingFee;
        if (_feeTotal > 0) {
            super._transfer(from, address(this), _feeTotal);
            _liquidityTokensToSwap += _liquidityFee;
            _marketingFeeTokensToSwap += _marketingFee;
            _burnFeeTokens += _burnFee;
            _stakingFeeTokens += _stakingFee;
        }
    }

    function takeFee(uint256 contractBalance) private lockTheSwap {
        uint256 totalTokensTaken = _liquidityTokensToSwap +
            _marketingFeeTokensToSwap +
            _burnFeeTokens +
            _stakingFeeTokens;
        if (totalTokensTaken == 0 || contractBalance < totalTokensTaken) {
            return;
        }

        uint256 tokensForLiquidity = _liquidityTokensToSwap / 2;
        uint256 initialETHBalance = address(this).balance;
        uint256 toSwap = tokensForLiquidity +
            _marketingFeeTokensToSwap +
            _stakingFeeTokens;
        swapTokensForETH(toSwap);
        uint256 ethBalance = address(this).balance - initialETHBalance;

        uint256 ethForMarketing = (ethBalance * _marketingFeeTokensToSwap) /
            toSwap;
        uint256 ethForLiquidity = (ethBalance * tokensForLiquidity) / toSwap;
        uint256 ethForStaking = (ethBalance * _stakingFeeTokens) / toSwap;

        if (tokensForLiquidity > 0 && ethForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, ethForLiquidity);
        }
        bool success;

        (success, ) = address(marketingFeeAddress).call{
            value: ethForMarketing,
            gas: 50000
        }("");
        (success, ) = address(stakingFeeAddress).call{
            value: ethForStaking,
            gas: 50000
        }("");

        if (_burnFeeTokens > 0) {
            _burn(address(this), _burnFeeTokens);
        }

        _liquidityTokensToSwap = 0;
        _marketingFeeTokensToSwap = 0;
        _burnFeeTokens = 0;
        _stakingFeeTokens = 0;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    receive() external payable {}

    // Limits
    event LimitSet(address indexed user, uint256 limitETH, uint256 period);

    mapping(address => LimitedWallet) private _limits;

    uint256 public globalLimit; // limit over timeframe for all
    uint256 public globalLimitPeriod; // timeframe for all

    bool public limitsActive;

    bool private hasLiquidity;

    struct LimitedWallet {
        uint256[] sellAmounts;
        uint256[] sellTimestamps;
        uint256 limitPeriod; // ability to set custom values for individual wallets
        uint256 limitETH; // ability to set custom values for individual wallets
        bool isExcluded;
    }

    function setGlobalLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= 1 ether, "Too low");
        globalLimit = newLimit;
    }

    function setGlobalLimitPeriod(uint256 newPeriod) external onlyOwner {
        require(newPeriod <= 2 weeks, "Too long");
        globalLimitPeriod = newPeriod;
    }

    function setLimitsActiveStatus(bool status) external onlyOwner {
        limitsActive = status;
    }

    function getLimits(address _address)
        external
        view
        returns (LimitedWallet memory)
    {
        return _limits[_address];
    }

    function removeLimits(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; i++) {
            address account = addresses[i];
            _limits[account].limitPeriod = 0;
            _limits[account].limitETH = 0;
            emit LimitSet(account, 0, 0);
        }
    }

    // Set custom limits for an address. Defaults to 0, thus will use the "globalLimitPeriod" and "globalLimitETH" if we don't set them
    function setLimits(
        address[] calldata addresses,
        uint256[] calldata limitPeriods,
        uint256[] calldata limitsETH
    ) external onlyOwner {
        require(
            addresses.length == limitPeriods.length &&
                limitPeriods.length == limitsETH.length,
            "Array lengths don't match"
        );

        for (uint256 i = 0; i < addresses.length; i++) {
            if (limitPeriods[i] == 0 && limitsETH[i] == 0) continue;
            _limits[addresses[i]].limitPeriod = limitPeriods[i];
            _limits[addresses[i]].limitETH = limitsETH[i];
            emit LimitSet(addresses[i], limitsETH[i], limitPeriods[i]);
        }
    }

    function addExcludedFromLimits(address[] calldata addresses)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            _limits[addresses[i]].isExcluded = true;
        }
    }

    function removeExcludedFromLimits(address[] calldata addresses)
        external
        onlyOwner
    {
        require(addresses.length <= 500, "Array too long");
        for (uint256 i = 0; i < addresses.length; i++) {
            _limits[addresses[i]].isExcluded = false;
        }
    }

    // Can be used to check how much a wallet sold in their timeframe
    function getSoldLastPeriod(address _address)
        public
        view
        returns (uint256 sellAmount)
    {
        LimitedWallet memory __limits = _limits[_address];
        uint256 numberOfSells = __limits.sellAmounts.length;

        if (numberOfSells == 0) {
            return sellAmount;
        }

        uint256 limitPeriod = __limits.limitPeriod == 0
            ? globalLimitPeriod
            : __limits.limitPeriod;
        while (true) {
            if (numberOfSells == 0) {
                break;
            }
            numberOfSells--;
            uint256 sellTimestamp = __limits.sellTimestamps[numberOfSells];
            if (block.timestamp - limitPeriod <= sellTimestamp) {
                sellAmount += __limits.sellAmounts[numberOfSells];
            } else {
                break;
            }
        }
    }

    function checkLiquidity() internal {
        (uint256 r1, uint256 r2, ) = IUniswapV2Pair(uniswapPair).getReserves();

        lpTokens = balanceOf(uniswapPair); // this is not a problem, since contract sell will get that unsynced balance as if we sold it, so we just get more ETH.
        hasLiquidity = r1 > 0 && r2 > 0 ? true : false;
    }

    function getETHValue(uint256 tokenAmount)
        public
        view
        returns (uint256 ethValue)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        ethValue = uniswapRouter.getAmountsOut(tokenAmount, path)[1];
    }

    // Handle private sale wallets
    function _handleLimited(
        address from,
        address to,
        uint256 taxedAmount
    ) private {
        LimitedWallet memory _from = _limits[from];
        if (
            _from.isExcluded ||
            _limits[to].isExcluded ||
            !hasLiquidity ||
            automatedMarketMakerPairs[from] ||
            inSwapAndLiquify ||
            (!limitsActive && _from.limitETH == 0) // if limits are disabled and the wallet doesn't have a custom limit, we don't need to check
        ) {
            return;
        }
        uint256 ethValue = getETHValue(taxedAmount);
        _limits[from].sellTimestamps.push(block.timestamp);
        _limits[from].sellAmounts.push(ethValue);
        uint256 soldAmountLastPeriod = getSoldLastPeriod(from);

        uint256 limit = _from.limitETH == 0 ? globalLimit : _from.limitETH;
        require(
            soldAmountLastPeriod <= limit,
            "Amount over the limit for time period"
        );
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 tokenAddress, address walletAddress)
        external
        onlyOwner
    {
        require(
            walletAddress != address(0),
            "walletAddress can't be 0 address"
        );
        SafeERC20.safeTransfer(
            tokenAddress,
            walletAddress,
            tokenAddress.balanceOf(address(this))
        );
    }
}