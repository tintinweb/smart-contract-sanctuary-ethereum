// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)
pragma solidity 0.8.0;


import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./interfaces/IMultiVaultToken.sol";

import "./libraries/Address.sol";

import "./utils/Ownable.sol";


contract MultiVaultToken is IMultiVaultToken, Context, IERC20, IERC20Metadata, Ownable {
    uint activation;

    constructor() Ownable(_msgSender()) {}

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name}, {symbol} and {decimals}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external override {
        require(activation == 0);

        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;

        activation = block.number;
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
        return _decimals;
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

    function mint(
        address account,
        uint amount
    ) external override onlyOwner {
        _mint(account, amount);
    }

    function burn(
        address account,
        uint amount
    ) external override onlyOwner {
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity 0.8.0;

import "./IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IEverscale {
    struct EverscaleAddress {
        int8 wid;
        uint256 addr;
    }

    struct EverscaleEvent {
        uint64 eventTransactionLt;
        uint32 eventTimestamp;
        bytes eventData;
        int8 configurationWid;
        uint256 configurationAddress;
        int8 eventContractWid;
        uint256 eventContractAddress;
        address proxy;
        uint32 round;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultToken {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external;

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetLiquidity {
    struct Liquidity {
        uint activation;
        uint supply;
        uint cash;
        uint interest;
    }

    function mint(
        address token,
        uint amount,
        address receiver
    ) external;

    function redeem(
        address token,
        uint amount,
        address receiver
    ) external;

    function exchangeRateCurrent(
        address token
    ) external view returns(uint);

    function getCash(
        address token
    ) external view returns(uint);

    function getLPToken(
        address token
    ) external view returns (address);

    function setTokenInterest(
        address token,
        uint interest
    ) external;

    function setDefaultInterest(
        uint interest
    ) external;

    function liquidity(
        address token
    ) external view returns (Liquidity memory);

    function convertLPToUnderlying(
        address token,
        uint amount
    ) external view returns (uint);

    function convertUnderlyingToLP(
        address token,
        uint amount
    ) external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../IEverscale.sol";


interface IMultiVaultFacetPendingWithdrawals {
    enum ApproveStatus { NotRequired, Required, Approved, Rejected }

    struct WithdrawalLimits {
        uint undeclared;
        uint daily;
        bool enabled;
    }

    struct PendingWithdrawalParams {
        address token;
        uint256 amount;
        uint256 bounty;
        uint256 timestamp;
        ApproveStatus approveStatus;
    }

    struct PendingWithdrawalId {
        address recipient;
        uint256 id;
    }

    struct WithdrawalPeriodParams {
        uint256 total;
        uint256 considered;
    }

    function pendingWithdrawalsPerUser(address user) external view returns (uint);
    function pendingWithdrawalsTotal(address token) external view returns (uint);

    function pendingWithdrawals(
        address user,
        uint256 id
    ) external view returns (PendingWithdrawalParams memory);

    function setPendingWithdrawalBounty(
        uint256 id,
        uint256 bounty
    ) external;

    function cancelPendingWithdrawal(
        uint256 id,
        uint256 amount,
        IEverscale.EverscaleAddress memory recipient,
        uint expected_evers,
        bytes memory payload,
        uint bounty
    ) external payable;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId memory pendingWithdrawalId,
        ApproveStatus approveStatus
    ) external;

    function setPendingWithdrawalApprove(
        PendingWithdrawalId[] memory pendingWithdrawalId,
        ApproveStatus[] memory approveStatus
    ) external;

    function forceWithdraw(
        PendingWithdrawalId[] memory pendingWithdrawalIds
    ) external;

    function withdrawalLimits(
        address token
    ) external view returns(WithdrawalLimits memory);

    function withdrawalPeriods(
        address token,
        uint256 withdrawalPeriodId
    ) external view returns (WithdrawalPeriodParams memory);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./../IEverscale.sol";


interface IMultiVaultFacetTokens {
    enum TokenType { Native, Alien }

    struct TokenPrefix {
        uint activation;
        string name;
        string symbol;
    }

    struct TokenMeta {
        string name;
        string symbol;
        uint8 decimals;
    }

    struct Token {
        uint activation;
        bool blacklisted;
        uint depositFee;
        uint withdrawFee;
        bool isNative;
        address custom;
    }

    function prefixes(address _token) external view returns (TokenPrefix memory);
    function tokens(address _token) external view returns (Token memory);
    function natives(address _token) external view returns (IEverscale.EverscaleAddress memory);

    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external;

    function setTokenBlacklist(
        address token,
        bool blacklisted
    ) external;

    function getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultFacetTokensEvents {
    event BlacklistTokenAdded(address token);
    event BlacklistTokenRemoved(address token);

    event TokenActivated(
        address token,
        uint activation,
        bool isNative,
        uint depositFee,
        uint withdrawFee
    );

    event TokenCreated(
        address token,
        int8 native_wid,
        uint256 native_addr,
        string name_prefix,
        string symbol_prefix,
        string name,
        string symbol,
        uint8 decimals
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "./IMultiVaultFacetTokens.sol";
import "../IEverscale.sol";


interface IMultiVaultFacetWithdraw {
    struct Callback {
        address recipient;
        bytes payload;
        bool strict;
    }

    struct NativeWithdrawalParams {
        IEverscale.EverscaleAddress native;
        IMultiVaultFacetTokens.TokenMeta meta;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    struct AlienWithdrawalParams {
        address token;
        uint256 amount;
        address recipient;
        uint256 chainId;
        Callback callback;
    }

    function withdrawalIds(bytes32) external view returns (bool);

    function saveWithdrawNative(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures
    ) external;

    function saveWithdrawAlien(
        bytes memory payload,
        bytes[] memory signatures,
        uint bounty
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokensEvents.sol";

import "../../MultiVaultToken.sol";
import "../storage/MultiVaultStorage.sol";

import "../helpers/MultiVaultHelperActors.sol";
import "../helpers/MultiVaultHelperTokens.sol";


contract MultiVaultFacetTokens is
    MultiVaultHelperActors,
    MultiVaultHelperTokens,
    IMultiVaultFacetTokens
{
    function getInitHash() public pure returns(bytes32) {
        bytes memory bytecode = type(MultiVaultToken).creationCode;
        return keccak256(abi.encodePacked(bytecode));
    }

    /// @notice Get token prefix
    /// @dev Used to set up in advance prefix for the ERC20 native token
    /// @param _token Token address
    /// @return Name and symbol prefix
    function prefixes(
        address _token
    ) external view override returns (IMultiVaultFacetTokens.TokenPrefix memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.prefixes_[_token];
    }

    /// @notice Get token information
    /// @param _token Token address
    function tokens(
        address _token
    ) external view override returns (IMultiVaultFacetTokens.Token memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.tokens_[_token];
    }

    /// @notice Get native Everscale token address for EVM token
    /// @param _token Token address
    function natives(
        address _token
    ) external view override returns (IEverscale.EverscaleAddress memory) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        return s.natives_[_token];
    }

    /// @notice Set prefix for native token
    /// @param token Expected native token address, see note on `getNative`
    /// @param name_prefix Name prefix, leave empty for no-prefix
    /// @param symbol_prefix Symbol prefix, leave empty for no-prefix
    function setPrefix(
        address token,
        string memory name_prefix,
        string memory symbol_prefix
    ) external override onlyGovernanceOrManagement {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        TokenPrefix memory prefix = s.prefixes_[token];

        if (prefix.activation == 0) {
            prefix.activation = block.number;
        }

        prefix.name = name_prefix;
        prefix.symbol = symbol_prefix;

        s.prefixes_[token] = prefix;
    }

    function setTokenBlacklist(
        address token,
        bool blacklisted
    ) external override onlyGovernance {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.tokens_[token].blacklisted = blacklisted;
    }

    function getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) external view override returns (address token) {
        token = _getNativeToken(native);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperActors {
    modifier onlyPendingGovernance() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.pendingGovernance);

        _;
    }

    modifier onlyGovernance() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance);

        _;
    }

    modifier onlyGovernanceOrManagement() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance || msg.sender == s.management);

        _;
    }

    modifier onlyGovernanceOrWithdrawGuardian() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(msg.sender == s.governance || msg.sender == s.withdrawGuardian);

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;

import "../storage/MultiVaultStorage.sol";


abstract contract MultiVaultHelperEmergency {
    modifier onlyEmergencyDisabled() {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(!s.emergencyShutdown);

        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetWithdraw.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokensEvents.sol";
import "../../interfaces/IEverscale.sol";

import "../../MultiVaultToken.sol";
import "../storage/MultiVaultStorage.sol";
import "./MultiVaultHelperEmergency.sol";


abstract contract MultiVaultHelperTokens is
    MultiVaultHelperEmergency,
    IMultiVaultFacetTokensEvents
{
    modifier initializeToken(address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        if (s.tokens_[token].activation == 0) {
            // Non-activated tokens are always aliens, native tokens are activate on the first `saveWithdrawNative`

            require(
                IERC20Metadata(token).decimals() <= MultiVaultStorage.DECIMALS_LIMIT &&
                bytes(IERC20Metadata(token).symbol()).length <= MultiVaultStorage.SYMBOL_LENGTH_LIMIT &&
                bytes(IERC20Metadata(token).name()).length <= MultiVaultStorage.NAME_LENGTH_LIMIT
            );

            _activateToken(token, false);
        }

        _;
    }

    modifier tokenNotBlacklisted(address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        require(!s.tokens_[token].blacklisted);

        _;
    }

    function _activateToken(
        address token,
        bool isNative
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        uint depositFee = isNative ? s.defaultNativeDepositFee : s.defaultAlienDepositFee;
        uint withdrawFee = isNative ? s.defaultNativeWithdrawFee : s.defaultAlienWithdrawFee;

        s.tokens_[token] = IMultiVaultFacetTokens.Token({
            activation: block.number,
            blacklisted: false,
            isNative: isNative,
            depositFee: depositFee,
            withdrawFee: withdrawFee,
            custom: address(0)
        });

        emit TokenActivated(
            token,
            block.number,
            isNative,
            depositFee,
            withdrawFee
        );
    }

    function _getNativeWithdrawalToken(
        IMultiVaultFacetWithdraw.NativeWithdrawalParams memory withdrawal
    ) internal returns (address) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        // Derive native token address from the Everscale (token wid, token addr)
        address token = _getNativeToken(withdrawal.native);

        // Token is being withdrawn first time - activate it (set default parameters)
        // And deploy ERC20 representation
        if (s.tokens_[token].activation == 0) {
            _deployTokenForNative(withdrawal.native, withdrawal.meta);
            _activateToken(token, true);

            s.natives_[token] = withdrawal.native;
        }

        // Check if there is a custom ERC20 representing this withdrawal.native
        address custom = s.tokens_[token].custom;

        if (custom != address(0)) return custom;

        return token;
    }

    function _increaseCash(
        address token,
        uint amount
    ) internal {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        s.liquidity[token].cash += amount;
    }

    /// @notice Gets the address
    /// @param native Everscale token address
    /// @return token Token address
    function _getNativeToken(
        IEverscale.EverscaleAddress memory native
    ) internal view returns (address token) {
        token = address(uint160(uint(keccak256(abi.encodePacked(
            hex'ff',
            address(this),
            keccak256(abi.encodePacked(native.wid, native.addr)),
            hex'192c19818bebb5c6c95f5dcb3c3257379fc46fb654780cb06f3211ee77e1a360' // MultiVaultToken init code hash
        )))));
    }

    function _deployTokenForNative(
        IEverscale.EverscaleAddress memory native,
        IMultiVaultFacetTokens.TokenMeta memory meta
    ) internal returns (address token) {
        MultiVaultStorage.Storage storage s = MultiVaultStorage._storage();

        bytes memory bytecode = type(MultiVaultToken).creationCode;

        bytes32 salt = keccak256(abi.encodePacked(native.wid, native.addr));

        assembly {
            token := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Check custom prefix available
        IMultiVaultFacetTokens.TokenPrefix memory prefix = s.prefixes_[token];

        string memory name_prefix = prefix.activation == 0 ? MultiVaultStorage.DEFAULT_NAME_PREFIX : prefix.name;
        string memory symbol_prefix = prefix.activation == 0 ? MultiVaultStorage.DEFAULT_SYMBOL_PREFIX : prefix.symbol;

        IMultiVaultToken(token).initialize(
            string(abi.encodePacked(name_prefix, meta.name)),
            string(abi.encodePacked(symbol_prefix, meta.symbol)),
            meta.decimals
        );

        emit TokenCreated(
            token,
            native.wid,
            native.addr,
            name_prefix,
            symbol_prefix,
            meta.name,
            meta.symbol,
            meta.decimals
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


import "../../interfaces/IEverscale.sol";
import "../../interfaces/multivault/IMultiVaultFacetTokens.sol";
import "../../interfaces/multivault/IMultiVaultFacetPendingWithdrawals.sol";
import "../../interfaces/multivault/IMultiVaultFacetLiquidity.sol";


library MultiVaultStorage {
    uint constant MAX_BPS = 10_000;
    uint constant FEE_LIMIT = MAX_BPS / 2;

    uint8 constant DECIMALS_LIMIT = 18;
    uint256 constant SYMBOL_LENGTH_LIMIT = 32;
    uint256 constant NAME_LENGTH_LIMIT = 32;

    string constant DEFAULT_NAME_PREFIX = '';
    string constant DEFAULT_SYMBOL_PREFIX = '';

    string constant DEFAULT_NAME_LP_PREFIX = 'Octus LP ';
    string constant DEFAULT_SYMBOL_LP_PREFIX = 'octLP';

    uint256 constant WITHDRAW_PERIOD_DURATION_IN_SECONDS = 60 * 60 * 24; // 24 hours

    // Previous version of the Vault contract was built with Upgradable Proxy Pattern, without using Diamond storage
    bytes32 constant MULTIVAULT_LEGACY_STORAGE_POSITION = 0x0000000000000000000000000000000000000000000000000000000000000002;

    uint constant LP_EXCHANGE_RATE_BPS = 10_000_000_000;

    struct Storage {
        mapping (address => IMultiVaultFacetTokens.Token) tokens_;
        mapping (address => IEverscale.EverscaleAddress) natives_;

        uint defaultNativeDepositFee;
        uint defaultNativeWithdrawFee;
        uint defaultAlienDepositFee;
        uint defaultAlienWithdrawFee;

        bool emergencyShutdown;

        address bridge;
        mapping(bytes32 => bool) withdrawalIds;
        IEverscale.EverscaleAddress rewards_;
        IEverscale.EverscaleAddress configurationNative_;
        IEverscale.EverscaleAddress configurationAlien_;

        address governance;
        address pendingGovernance;
        address guardian;
        address management;

        mapping (address => IMultiVaultFacetTokens.TokenPrefix) prefixes_;
        mapping (address => uint) fees;

        // STORAGE UPDATE 1
        // Pending withdrawals
        // - Counter pending withdrawals per user
        mapping(address => uint) pendingWithdrawalsPerUser;
        // - Pending withdrawal details
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.PendingWithdrawalParams)) pendingWithdrawals_;

        // - Total amount of pending withdrawals per token
        mapping(address => uint) pendingWithdrawalsTotal;

        // STORAGE UPDATE 2
        // Withdrawal limits per token
        mapping(address => IMultiVaultFacetPendingWithdrawals.WithdrawalLimits) withdrawalLimits_;

        // - Withdrawal periods. Each period is `WITHDRAW_PERIOD_DURATION_IN_SECONDS` seconds long.
        // If some period has reached the `withdrawalLimitPerPeriod` - all the future
        // withdrawals in this period require manual approve, see note on `setPendingWithdrawalsApprove`
        mapping(address => mapping(uint256 => IMultiVaultFacetPendingWithdrawals.WithdrawalPeriodParams)) withdrawalPeriods_;

        address withdrawGuardian;

        // STORAGE UPDATE 3
        mapping (address => IMultiVaultFacetLiquidity.Liquidity) liquidity;
        uint defaultInterest;

        // STORAGE UPDATE 4
        // - Receives native value, attached to the deposit
        address gasDonor;
    }

    function _storage() internal pure returns (Storage storage s) {
        assembly {
            s.slot := MULTIVAULT_LEGACY_STORAGE_POSITION
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.0;

import "./Context.sol";

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
    constructor (address initialOwner) {
        _transferOwnership(initialOwner);
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