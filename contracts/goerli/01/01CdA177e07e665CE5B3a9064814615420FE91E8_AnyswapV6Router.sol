// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ISushiswapV2Pair.sol";
import "./interfaces/IAnyswapV6ERC20.sol";
import "./interfaces/IwNATIVE.sol";
import "./libraries/SafeMathSushiswap.sol";
import "./libraries/SushiswapV2Library.sol";
import "./libraries/TransferHelper.sol";

interface IAnyswapV6Router {

    event LogChangeMPC(
        address indexed oldMPC,
        address indexed newMPC,
        uint indexed effectiveTime,
        uint chainID
    );
    event LogChangeRouter(
        address indexed oldRouter,
        address indexed newRouter,
        uint chainID
    );
    event LogAnySwapIn(
        bytes32 indexed txhash,
        address indexed token,
        address indexed to,
        uint amount,
        uint fromChainID,
        uint toChainID
    );
    event LogAnySwapOut(
        address indexed token,
        address indexed from,
        address indexed to,
        uint amount,
        uint fromChainID,
        uint toChainID
    );
    event LogAnySwapOut(
        address indexed token,
        address indexed from,
        string to,
        uint amount,
        uint fromChainID,
        uint toChainID
    );
    event LogAnySwapTradeTokensForTokens(
        address[] path,
        address indexed from,
        address indexed to,
        uint amountIn,
        uint amountOutMin,
        uint fromChainID,
        uint toChainID
    );
    event LogAnySwapTradeTokensForNative(
        address[] path,
        address indexed from,
        address indexed to,
        uint amountIn,
        uint amountOutMin,
        uint fromChainID,
        uint toChainID
    );

}

contract AnyswapV6Router is IAnyswapV6Router {
    using SafeERC20 for IERC20;
    using SafeMathSushiswap for uint;

    address private _oldMPC;
    address private _newMPC;
    uint256 private _newMPCEffectiveTime;

    address public immutable factory;
    address public immutable wNATIVE;
    bool public enableSwapTrade;

    modifier swapTradeEnabled() {
        require(enableSwapTrade, "AnyswapV6Router: SwapTrade disabled");
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "AnyswapV6Router: EXPIRED");
        _;
    }

    modifier onlyMPC() {
        //require(msg.sender == mpc(), "AnyswapV3Router: FORBIDDEN");
        _;
    }

    constructor(address _factory, address _wNATIVE, address _mpc) {
        factory = _factory;
        wNATIVE = _wNATIVE;
        _newMPC = _mpc;
        _newMPCEffectiveTime = block.timestamp;
    }

    function cID() public view returns (uint id) {
        assembly {
            id := chainid()
        }
    }

    function mpc() public view returns (address) {
        if (block.timestamp >= _newMPCEffectiveTime) {
            return _newMPC;
        }
        return _oldMPC;
    }

    function setEnableSwapTrade(bool enable)
        external
        onlyMPC
    {
        enableSwapTrade = enable;
    }

    function changeMPC(address newMPC) public onlyMPC returns (bool) {
        require(newMPC != address(0), "AnyswapV3Router: address(0x0)");
        _oldMPC = mpc();
        _newMPC = newMPC;
        _newMPCEffectiveTime = block.timestamp + 2 * 24 * 3600;
        emit LogChangeMPC(_oldMPC, _newMPC, _newMPCEffectiveTime, cID());
        return true;
    }

    function setVault(
        address token,
        address newVault
    ) public onlyMPC {
        require(newVault != address(0), "AnyswapV3Router: address(0x0)");
        IAnyswapV6ERC20(token).setVault(newVault);
    }

    function setMinter(address token, address _auth) external onlyMPC {
        return IAnyswapV6ERC20(token).setMinter(_auth);
    }

    function _anySwapOut(
        address from,
        address token,
        address to,
        uint amount,
        uint toChainID
    ) internal {
        IAnyswapV6ERC20(token).burn(from, amount);
        emit LogAnySwapOut(token, from, to, amount, cID(), toChainID);
    }

    // Swaps   from this chain to  chain with recipient
    function anySwapOut(
        address token,
        address to,
        uint amount,
        uint toChainID
    ) external {
        _anySwapOut(msg.sender, token, to, amount, toChainID);
    }

    // Swaps   from this chain to  chain with recipient  by minting with
    function anySwapOutUnderlying(
        address token,
        address to,
        uint amount,
        uint toChainID
    ) external {
        IERC20(IAnyswapV6ERC20(token).underlying()).safeTransferFrom(
            msg.sender,
            token,
            amount
        );
        emit LogAnySwapOut(token, msg.sender, to, amount, cID(), toChainID);
    }

    function anySwapOutNative(
        address token,
        address to,
        uint toChainID
    ) external payable {
        require(
            IAnyswapV6ERC20(token).underlying() == wNATIVE,
            "AnyswapV3Router: underlying is not wNATIVE"
        );
        IwNATIVE(wNATIVE).deposit{value: msg.value}();
        assert(IwNATIVE(wNATIVE).transfer(token, msg.value));
        emit LogAnySwapOut(token, msg.sender, to, msg.value, cID(), toChainID);
    }

    function anySwapOut(
        address[] calldata tokens,
        address[] calldata to,
        uint[] calldata amounts,
        uint[] calldata toChainIDs
    ) external {
        for (uint i = 0; i < tokens.length; i++) {
            _anySwapOut(
                msg.sender,
                tokens[i],
                to[i],
                amounts[i],
                toChainIDs[i]
            );
        }
    }

    function anySwapOut(
        address token,
        string memory to,
        uint amount,
        uint toChainID
    ) external {
        IAnyswapV6ERC20(token).burn(msg.sender, amount);
        emit LogAnySwapOut(token, msg.sender, to, amount, cID(), toChainID);
    }

    function anySwapOutUnderlying(
        address token,
        string memory to,
        uint amount,
        uint toChainID
    ) external {
        IERC20(IAnyswapV6ERC20(token).underlying()).safeTransferFrom(
            msg.sender,
            token,
            amount
        );
        emit LogAnySwapOut(token, msg.sender, to, amount, cID(), toChainID);
    }

    function anySwapOutNative(
        address token,
        string memory to,
        uint toChainID
    ) external payable {
        require(
            IAnyswapV6ERC20(token).underlying() == wNATIVE,
            "AnyswapV3Router: underlying is not wNATIVE"
        );
        IwNATIVE(wNATIVE).deposit{value: msg.value}();
        assert(IwNATIVE(wNATIVE).transfer(token, msg.value));
        emit LogAnySwapOut(token, msg.sender, to, msg.value, cID(), toChainID);
    }

    // swaps   in  to  on this chainID
    function _anySwapIn(
        bytes32 txs,
        address token,
        address to,
        uint amount,
        uint fromChainID
    ) internal {
        IAnyswapV6ERC20(token).mint(to, amount);
        emit LogAnySwapIn(txs, token, to, amount, fromChainID, cID());
    }

    // swaps   in  to  on this chainID
    // triggered by
    function anySwapIn(
        bytes32 txs,
        address token,
        address to,
        uint amount,
        uint fromChainID
    ) external onlyMPC {
        _anySwapIn(txs, token, to, amount, fromChainID);
    }

    // swaps   in  to  on this chainID with  receiving
    function anySwapInUnderlying(
        bytes32 txs,
        address token,
        address to,
        uint amount,
        uint fromChainID
    ) external onlyMPC {
        _anySwapIn(txs, token, to, amount, fromChainID);
        IAnyswapV6ERC20(token).withdrawVault(to, amount, to);
    }

    // swaps   in  to  on this chainID with  receiving  if possible
    function anySwapInAuto(
        bytes32 txs,
        address token,
        address to,
        uint amount,
        uint fromChainID
    ) external onlyMPC {
        _anySwapIn(txs, token, to, amount, fromChainID);
        IAnyswapV6ERC20 _anyToken = IAnyswapV6ERC20(token);
        address _underlying = _anyToken.underlying();
        if (
            _underlying != address(0) &&
            IERC20(_underlying).balanceOf(token) >= amount
        ) {
            if (_underlying == wNATIVE) {
                _anyToken.withdrawVault(to, amount, address(this));
                IwNATIVE(wNATIVE).withdraw(amount);
                TransferHelper.safeTransferNative(to, amount);
            } else {
                _anyToken.withdrawVault(to, amount, to);
            }
        }
    }

    function depositNative(
        address token,
        address to
    ) external payable returns (uint) {
        require(
            IAnyswapV6ERC20(token).underlying() == wNATIVE,
            "AnyswapV3Router: underlying is not wNATIVE"
        );
        IwNATIVE(wNATIVE).deposit{value: msg.value}();
        assert(IwNATIVE(wNATIVE).transfer(token, msg.value));
        IAnyswapV6ERC20(token).depositVault(msg.value, to);
        return msg.value;
    }

    function withdrawNative(
        address token,
        uint amount,
        address to
    ) external returns (uint) {
        require(
            IAnyswapV6ERC20(token).underlying() == wNATIVE,
            "AnyswapV3Router: underlying is not wNATIVE"
        );
        IAnyswapV6ERC20(token).withdrawVault(msg.sender, amount, address(this));
        IwNATIVE(wNATIVE).withdraw(amount);
        TransferHelper.safeTransferNative(to, amount);
        return amount;
    }

    // extracts mpc fee from bridge fees
    function anySwapFeeTo(address token, uint amount) external onlyMPC {
        address _mpc = mpc();
        IAnyswapV6ERC20(token).mint(_mpc, amount);
        IAnyswapV6ERC20(token).withdrawVault(_mpc, amount, _mpc);
    }

    function anySwapIn(
        bytes32[] calldata txs,
        address[] calldata tokens,
        address[] calldata to,
        uint256[] calldata amounts,
        uint[] calldata fromChainIDs
    ) external onlyMPC {
        for (uint i = 0; i < tokens.length; i++) {
            _anySwapIn(txs[i], tokens[i], to[i], amounts[i], fromChainIDs[i]);
        }
    }

    // **** SWAP ****
    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = SushiswapV2Library.sortTokens(input, output);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0
                ? (uint(0), amountOut)
                : (amountOut, uint(0));
            address to = i < path.length - 2
                ? SushiswapV2Library.pairFor(factory, output, path[i + 2])
                : _to;
            ISushiswapV2Pair(SushiswapV2Library.pairFor(factory, input, output))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    // sets up a cross-chain trade from this chain to  for  trades to
    function anySwapOutExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint toChainID
    ) external virtual swapTradeEnabled ensure(deadline) {
        IAnyswapV6ERC20(path[0]).burn(msg.sender, amountIn);
        emit LogAnySwapTradeTokensForTokens(
            path,
            msg.sender,
            to,
            amountIn,
            amountOutMin,
            cID(),
            toChainID
        );
    }

    // sets up a cross-chain trade from this chain to  for  trades to
    function anySwapOutExactTokensForTokensUnderlying(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint toChainID
    ) external virtual swapTradeEnabled ensure(deadline) {
        IERC20(IAnyswapV6ERC20(path[0]).underlying()).safeTransferFrom(
            msg.sender,
            path[0],
            amountIn
        );
        IAnyswapV6ERC20(path[0]).depositVault(amountIn, msg.sender);
        IAnyswapV6ERC20(path[0]).burn(msg.sender, amountIn);
        emit LogAnySwapTradeTokensForTokens(
            path,
            msg.sender,
            to,
            amountIn,
            amountOutMin,
            cID(),
            toChainID
        );
    }

    // Swaps   to  on this chain
    // Triggered by
    function anySwapInExactTokensForTokens(
        bytes32 txs,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint fromChainID
    )
        external
        virtual
        onlyMPC
        swapTradeEnabled
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        amounts = SushiswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "SushiswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _anySwapIn(
            txs,
            path[0],
            SushiswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0],
            fromChainID
        );
        _swap(amounts, path, to);
    }

    // sets up a cross-chain trade from this chain to  for  trades to
    function anySwapOutExactTokensForNative(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint toChainID
    ) external virtual swapTradeEnabled ensure(deadline) {
        IAnyswapV6ERC20(path[0]).burn(msg.sender, amountIn);
        emit LogAnySwapTradeTokensForNative(
            path,
            msg.sender,
            to,
            amountIn,
            amountOutMin,
            cID(),
            toChainID
        );
    }

    // sets up a cross-chain trade from this chain to  for  trades to
    function anySwapOutExactTokensForNativeUnderlying(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint toChainID
    ) external virtual swapTradeEnabled ensure(deadline) {
        IERC20(IAnyswapV6ERC20(path[0]).underlying()).safeTransferFrom(
            msg.sender,
            path[0],
            amountIn
        );
        IAnyswapV6ERC20(path[0]).depositVault(amountIn, msg.sender);
        IAnyswapV6ERC20(path[0]).burn(msg.sender, amountIn);
        emit LogAnySwapTradeTokensForNative(
            path,
            msg.sender,
            to,
            amountIn,
            amountOutMin,
            cID(),
            toChainID
        );
    }

    // Swaps   to  on this chain
    // Triggered by
    function anySwapInExactTokensForNative(
        bytes32 txs,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        uint fromChainID
    )
        external
        virtual
        onlyMPC
        swapTradeEnabled
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        require(
            path[path.length - 1] == wNATIVE,
            "AnyswapV3Router: INVALID_PATH"
        );
        amounts = SushiswapV2Library.getAmountsOut(factory, amountIn, path);
        require(
            amounts[amounts.length - 1] >= amountOutMin,
            "AnyswapV3Router: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        _anySwapIn(
            txs,
            path[0],
            SushiswapV2Library.pairFor(factory, path[0], path[1]),
            amounts[0],
            fromChainID
        );
        _swap(amounts, path, address(this));
        IwNATIVE(wNATIVE).withdraw(amounts[amounts.length - 1]);
        TransferHelper.safeTransferNative(to, amounts[amounts.length - 1]);
    }

    // **** LIBRARY FUNCTIONS ****
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) public pure virtual returns (uint amountB) {
        return SushiswapV2Library.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual returns (uint amountOut) {
        return SushiswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) public pure virtual returns (uint amountIn) {
        return SushiswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(
        uint amountIn,
        address[] memory path
    ) public view virtual returns (uint[] memory amounts) {
        return SushiswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(
        uint amountOut,
        address[] memory path
    ) public view virtual returns (uint[] memory amounts) {
        return SushiswapV2Library.getAmountsIn(factory, amountOut, path);
    }

    receive() external payable {
        assert(msg.sender == wNATIVE); // only accept Native via fallback from the wNative contract
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IAnyswapV6ERC20 {
    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 amount) external returns (bool);

    function setMinter(address _auth) external;

    function setVault(address newVault) external;

    function applyVault() external;

    function depositVault(uint amount, address to) external returns (uint);

    function withdrawVault(
        address from,
        uint amount,
        address to
    ) external returns (uint);

    function underlying() external view returns (address);

    function deposit(uint amount, address to) external returns (uint);

    function withdraw(uint amount, address to) external returns (uint);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

interface ISushiswapV2Pair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

interface IwNATIVE {
    function deposit() external payable;

    function transfer(address to, uint value) external returns (bool);

    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

library SafeMathSushiswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require((z = x + y) >= x, "ds-math-add-overflow");
        }
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require((z = x - y) <= x, "ds-math-sub-underflow");
        }
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        unchecked {
            require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

import "../interfaces/ISushiswapV2Pair.sol";
import "./SafeMathSushiswap.sol";

library SushiswapV2Library {
    using SafeMathSushiswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SushiswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "SushiswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1, ) = ISushiswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) internal pure returns (uint amountB) {
        require(amountA > 0, "SushiswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "SushiswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "SushiswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "SushiswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(
            amountOut > 0,
            "SushiswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT"
        );
        require(
            reserveIn > 0 && reserveOut > 0,
            "SushiswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint amountIn,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "SushiswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint amountOut,
        address[] memory path
    ) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, "SushiswapV2Library: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.17;

// helper methods for interacting with ERC20 tokens and sending NATIVE that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferNative(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: NATIVE_TRANSFER_FAILED");
    }
}