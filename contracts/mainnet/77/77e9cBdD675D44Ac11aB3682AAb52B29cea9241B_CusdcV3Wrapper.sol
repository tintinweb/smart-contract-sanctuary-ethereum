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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

contract CometHelpers {
    uint64 internal constant BASE_INDEX_SCALE = 1e15;
    uint256 public constant EXP_SCALE = 1e18;
    uint256 public constant BASE_SCALE = 1e6;

    error InvalidUInt64();
    error InvalidUInt104();
    error InvalidInt256();
    error NegativeNumber();

    function safe64(uint256 n) internal pure returns (uint64) {
        if (n > type(uint64).max) revert InvalidUInt64();
        return uint64(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        if (n > uint256(type(int256).max)) revert InvalidInt256();
        return int256(n);
    }

    function presentValueSupply(uint64 baseSupplyIndex_, uint104 principalValue_)
        internal
        pure
        returns (uint256)
    {
        return (uint256(principalValue_) * baseSupplyIndex_) / BASE_INDEX_SCALE;
    }

    function principalValueSupply(uint64 baseSupplyIndex_, uint256 presentValue_)
        internal
        pure
        returns (uint104)
    {
        return safe104((presentValue_ * BASE_INDEX_SCALE) / baseSupplyIndex_);
    }

    function safe104(uint256 n) internal pure returns (uint104) {
        if (n > type(uint104).max) revert InvalidUInt104();
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        if (n < 0) revert NegativeNumber();
        return uint256(n);
    }

    /**
     * @dev Multiply a number by a factor
     */
    function mulFactor(uint256 n, uint256 factor) internal pure returns (uint256) {
        return (n * factor) / EXP_SCALE;
    }

    function divBaseWei(uint256 n, uint256 baseWei) internal pure returns (uint256) {
        return (n * BASE_SCALE) / baseWei;
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./vendor/CometInterface.sol";
import "./WrappedERC20.sol";
import "./vendor/ICometRewards.sol";
import "./ICusdcV3Wrapper.sol";
import "./CometHelpers.sol";

/**
 * @title CusdcV3Wrapper
 * @notice Wrapper for cUSDCV3 / COMET that acts as a stable-balance ERC20, instead of rebasing
 * token. {comet} will be used as the unit for the underlying token, and {wComet} will be used
 * as the unit for wrapped tokens.
 */
contract CusdcV3Wrapper is ICusdcV3Wrapper, WrappedERC20, CometHelpers {
    using SafeERC20 for IERC20;

    /// From cUSDCv3, used in principal <> present calculations
    uint256 public constant TRACKING_INDEX_SCALE = 1e15;
    /// From cUSDCv3, scaling factor for USDC rewards
    uint64 public constant RESCALE_FACTOR = 1e12;

    CometInterface public immutable underlyingComet;
    ICometRewards public immutable rewardsAddr;
    IERC20 public immutable rewardERC20;

    mapping(address => uint64) public baseTrackingIndex;
    mapping(address => uint64) public baseTrackingAccrued;
    mapping(address => uint256) public rewardsClaimed;

    constructor(
        address cusdcv3,
        address rewardsAddr_,
        address rewardERC20_
    ) WrappedERC20("Wrapped cUSDCv3", "wcUSDCv3") {
        if (cusdcv3 == address(0)) revert ZeroAddress();

        rewardsAddr = ICometRewards(rewardsAddr_);
        rewardERC20 = IERC20(rewardERC20_);
        underlyingComet = CometInterface(cusdcv3);
    }

    /// @return number of decimals
    function decimals() public pure override returns (uint8) {
        return 6;
    }

    /// @param amount {Comet} The amount of cUSDCv3 to deposit
    function deposit(uint256 amount) external {
        _deposit(msg.sender, msg.sender, msg.sender, amount);
    }

    /// @param dst The dst to deposit into
    /// @param amount {Comet} The amount of cUSDCv3 to deposit
    function depositTo(address dst, uint256 amount) external {
        _deposit(msg.sender, msg.sender, dst, amount);
    }

    /// @param src The address to deposit from
    /// @param dst The address to deposit to
    /// @param amount {Comet} The amount of cUSDCv3 to deposit
    function depositFrom(
        address src,
        address dst,
        uint256 amount
    ) external {
        _deposit(msg.sender, src, dst, amount);
    }

    /// Only called internally to run the deposit logic
    /// Takes `amount` fo cUSDCv3 from `src` and deposits to `dst` account in the wrapper.
    /// @param operator The address calling the contract (msg.sender)
    /// @param src The address to deposit from
    /// @param dst The address to deposit to
    /// @param amount {Comet} The amount of cUSDCv3 to deposit
    function _deposit(
        address operator,
        address src,
        address dst,
        uint256 amount
    ) internal {
        if (!hasPermission(src, operator)) revert Unauthorized();
        // {Comet}
        uint256 srcBal = underlyingComet.balanceOf(src);
        if (amount > srcBal) amount = srcBal;
        if (amount == 0) revert BadAmount();

        underlyingComet.accrueAccount(address(this));
        underlyingComet.accrueAccount(src);

        CometInterface.UserBasic memory wrappedBasic = underlyingComet.userBasic(address(this));
        int104 wrapperPrePrinc = wrappedBasic.principal;

        IERC20(address(underlyingComet)).safeTransferFrom(src, address(this), amount);

        wrappedBasic = underlyingComet.userBasic(address(this));
        int104 wrapperPostPrinc = wrappedBasic.principal;
        accrueAccountRewards(dst);
        // safe to cast because amount is positive
        _mint(dst, uint104(wrapperPostPrinc - wrapperPrePrinc));
    }

    /// @param amount {Comet} The amount of cUSDCv3 to withdraw
    function withdraw(uint256 amount) external {
        _withdraw(msg.sender, msg.sender, msg.sender, amount);
    }

    /// @param dst The address to withdraw cUSDCv3 to
    /// @param amount {Comet} The amount of cUSDCv3 to withdraw
    function withdrawTo(address dst, uint256 amount) external {
        _withdraw(msg.sender, msg.sender, dst, amount);
    }

    /// @param src The address to withdraw from
    /// @param dst The address to withdraw cUSDCv3 to
    /// @param amount {Comet} The amount of cUSDCv3 to withdraw
    function withdrawFrom(
        address src,
        address dst,
        uint256 amount
    ) external {
        _withdraw(msg.sender, src, dst, amount);
    }

    /// Internally called to run the withdraw logic
    /// Withdraws `amount` cUSDCv3 from `src` account in the wrapper and sends to `dst`
    /// @dev Rounds conservatively so as not to over-withdraw from the wrapper
    /// @param operator The address calling the contract (msg.sender)
    /// @param src The address to withdraw from
    /// @param dst The address to withdraw cUSDCv3 to
    /// @param amount {Comet} The amount of cUSDCv3 to withdraw
    function _withdraw(
        address operator,
        address src,
        address dst,
        uint256 amount
    ) internal {
        if (!hasPermission(src, operator)) revert Unauthorized();
        // {Comet}
        uint256 srcBalUnderlying = underlyingBalanceOf(src);
        if (srcBalUnderlying < amount) amount = srcBalUnderlying;
        if (amount == 0) revert BadAmount();

        underlyingComet.accrueAccount(address(this));
        underlyingComet.accrueAccount(src);

        uint256 srcBalPre = balanceOf(src);
        CometInterface.UserBasic memory wrappedBasic = underlyingComet.userBasic(address(this));
        int104 wrapperPrePrinc = wrappedBasic.principal;

        // conservative rounding in favor of the wrapper
        IERC20(address(underlyingComet)).safeTransfer(dst, (amount / 10) * 10);

        wrappedBasic = underlyingComet.userBasic(address(this));
        int104 wrapperPostPrinc = wrappedBasic.principal;

        // safe to cast because principal can't go negative, wrapper is not borrowing
        uint256 burnAmt = uint256(uint104(wrapperPrePrinc - wrapperPostPrinc));
        // occasionally comet will withdraw 1-10 wei more than we asked for.
        // this is ok because 9 times out of 10 we are rounding in favor of the wrapper.
        // safe because we have already capped the comet withdraw amount to src underlying bal.
        if (srcBalPre <= burnAmt) burnAmt = srcBalPre;

        accrueAccountRewards(src);
        _burn(src, safe104(burnAmt));
    }

    /// Internally called to run transfer logic.
    /// Accrues rewards for `src` and `dst` before transferring value.
    function _beforeTokenTransfer(
        address src,
        address dst,
        uint256 amount
    ) internal virtual override {
        underlyingComet.accrueAccount(address(this));

        super._beforeTokenTransfer(src, dst, amount);

        accrueAccountRewards(src);
        accrueAccountRewards(dst);
    }

    /// @param src The account to claim from
    /// @param dst The address to send claimed rewards to
    function claimTo(address src, address dst) public {
        address sender = msg.sender;
        if (!hasPermission(src, sender)) revert Unauthorized();

        accrueAccount(src);
        uint256 claimed = rewardsClaimed[src];
        uint256 accrued = baseTrackingAccrued[src] * RESCALE_FACTOR;

        if (accrued > claimed) {
            uint256 owed = accrued - claimed;
            rewardsClaimed[src] = accrued;

            rewardsAddr.claimTo(address(underlyingComet), address(this), address(this), true);
            IERC20(rewardERC20).safeTransfer(dst, owed);
            emit RewardClaimed(src, dst, address(rewardERC20), owed);
        }
    }

    /// Accure the cUSDCv3 account of the wrapper
    function accrue() public {
        underlyingComet.accrueAccount(address(this));
    }

    /// @param account The address to accrue, first in cUSDCv3, then locally
    function accrueAccount(address account) public {
        underlyingComet.accrueAccount(address(this));
        accrueAccountRewards(account);
    }

    /// Get the balance of cUSDCv3 that is represented by the `accounts` wrapper value.
    /// @param account The address to calculate the cUSDCv3 balance of
    /// @return {Comet} The cUSDCv3 balance that `account` holds in the wrapper
    function underlyingBalanceOf(address account) public view returns (uint256) {
        uint256 balance = balanceOf(account);
        if (balance == 0) {
            return 0;
        }
        return convertStaticToDynamic(safe104(balance));
    }

    /// @return The exchange rate {comet/wComet}
    function exchangeRate() public view returns (uint256) {
        (uint64 baseSupplyIndex, ) = getUpdatedSupplyIndicies();
        return presentValueSupply(baseSupplyIndex, safe104(10**underlyingComet.decimals()));
    }

    /// @param amount The value of {wComet} to convert to {Comet}
    /// @return {Comet} The amount of cUSDCv3 represented by `amount of {wComet}
    function convertStaticToDynamic(uint104 amount) public view returns (uint256) {
        (uint64 baseSupplyIndex, ) = getUpdatedSupplyIndicies();
        return presentValueSupply(baseSupplyIndex, amount);
    }

    /// @param amount The value of {Comet} to convert to {wComet}
    /// @return {wComet} The amount of wrapped token represented by `amount` of {Comet}
    function convertDynamicToStatic(uint256 amount) public view returns (uint104) {
        (uint64 baseSupplyIndex, ) = getUpdatedSupplyIndicies();
        return principalValueSupply(baseSupplyIndex, amount);
    }

    /// @param account The address to view the owed rewards of
    /// @return {reward} The amount of reward tokens owed to `account`
    function getRewardOwed(address account) external view returns (uint256) {
        (, uint64 trackingSupplyIndex) = getUpdatedSupplyIndicies();

        uint256 indexDelta = uint256(trackingSupplyIndex - baseTrackingIndex[account]);
        uint256 newBaseTrackingAccrued = baseTrackingAccrued[account] +
            safe64((safe104(balanceOf(account)) * indexDelta) / TRACKING_INDEX_SCALE);

        uint256 claimed = rewardsClaimed[account];
        uint256 accrued = newBaseTrackingAccrued * RESCALE_FACTOR;
        uint256 owed = accrued > claimed ? accrued - claimed : 0;

        return owed;
    }

    /// Internally called to get saved indicies
    /// @return baseSupplyIndex_ {1} The saved baseSupplyIndex
    /// @return trackingSupplyIndex_ {1} The saved trackingSupplyIndex
    function getSupplyIndices()
        internal
        view
        returns (uint64 baseSupplyIndex_, uint64 trackingSupplyIndex_)
    {
        TotalsBasic memory totals = underlyingComet.totalsBasic();
        baseSupplyIndex_ = totals.baseSupplyIndex;
        trackingSupplyIndex_ = totals.trackingSupplyIndex;
    }

    /// Internally called to update the account indicies and accrued rewards for a given address
    /// @param account The UserBasic struct for a target address
    function accrueAccountRewards(address account) internal {
        uint256 accountBal = balanceOf(account);
        (, uint64 trackingSupplyIndex) = getSupplyIndices();
        uint256 indexDelta = uint256(trackingSupplyIndex - baseTrackingIndex[account]);

        baseTrackingAccrued[account] += safe64(
            (safe104(accountBal) * indexDelta) / TRACKING_INDEX_SCALE
        );
        baseTrackingIndex[account] = trackingSupplyIndex;
    }

    /// Internally called to get the updated supply indicies
    /// @return {1} The current baseSupplyIndex
    /// @return {1} The current trackingSupplyIndex
    function getUpdatedSupplyIndicies() internal view returns (uint64, uint64) {
        TotalsBasic memory totals = underlyingComet.totalsBasic();
        uint40 timeDelta = uint40(block.timestamp) - totals.lastAccrualTime;
        uint64 baseSupplyIndex_ = totals.baseSupplyIndex;
        uint64 trackingSupplyIndex_ = totals.trackingSupplyIndex;
        if (timeDelta > 0) {
            uint256 baseTrackingSupplySpeed = underlyingComet.baseTrackingSupplySpeed();
            uint256 utilization = underlyingComet.getUtilization();
            uint256 supplyRate = underlyingComet.getSupplyRate(utilization);
            baseSupplyIndex_ += safe64(mulFactor(baseSupplyIndex_, supplyRate * timeDelta));
            trackingSupplyIndex_ += safe64(
                divBaseWei(baseTrackingSupplySpeed * timeDelta, totals.totalSupplyBase)
            );
        }
        return (baseSupplyIndex_, trackingSupplyIndex_);
    }
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./vendor/CometInterface.sol";
import "./IWrappedERC20.sol";

interface ICusdcV3Wrapper is IWrappedERC20 {
    event RewardClaimed(
        address indexed src,
        address indexed recipient,
        address indexed token,
        uint256 amount
    );

    function deposit(uint256 amount) external;

    function depositTo(address account, uint256 amount) external;

    function claimTo(address src, address to) external;

    function accrue() external;

    function exchangeRate() external view returns (uint256);

    function convertStaticToDynamic(uint104 amount) external view returns (uint256);

    function convertDynamicToStatic(uint256 amount) external view returns (uint104);

    function underlyingComet() external view returns (CometInterface);

    function rewardERC20() external view returns (IERC20);
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IWrappedERC20 is IERC20Metadata {
    function allow(address account, bool isAllowed_) external;

    function hasPermission(address owner, address manager) external view returns (bool);

    function isAllowed(address first, address second) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

struct TotalsBasic {
    uint64 baseSupplyIndex;
    uint64 baseBorrowIndex;
    uint64 trackingSupplyIndex;
    uint64 trackingBorrowIndex;
    uint104 totalSupplyBase;
    uint104 totalBorrowBase;
    uint40 lastAccrualTime;
    uint8 pauseFlags;
}

/**
 * @title Compound's Comet Ext Interface
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometExtInterface {
    error BadAmount();
    error BadNonce();
    error BadSignatory();
    error InvalidValueS();
    error InvalidValueV();
    error SignatureExpired();

    function allow(address manager, bool isAllowed) external virtual;

    function allowBySig(
        address owner,
        address manager,
        bool isAllowed,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual;

    function collateralBalanceOf(address account, address asset)
        external
        view
        virtual
        returns (uint128);

    function baseTrackingAccrued(address account) external view virtual returns (uint64);

    function baseAccrualScale() external view virtual returns (uint64);

    function baseIndexScale() external view virtual returns (uint64);

    function factorScale() external view virtual returns (uint64);

    function priceScale() external view virtual returns (uint64);

    function maxAssets() external view virtual returns (uint8);

    function totalsBasic() external view virtual returns (TotalsBasic memory);

    function version() external view virtual returns (string memory);

    /**
     * ===== ERC20 interfaces =====
     * Does not include the following functions/events, which are defined in `CometMainInterface`
     * instead:
     * - function decimals() virtual external view returns (uint8)
     * - function totalSupply() virtual external view returns (uint256)
     * - function transfer(address dst, uint amount) virtual external returns (bool)
     * - function transferFrom(address src, address dst, uint amount) virtual external returns
        (bool)
     * - function balanceOf(address owner) virtual external view returns (uint256)
     * - event Transfer(address indexed from, address indexed to, uint256 amount)
     */
    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external virtual returns (bool);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view virtual returns (uint256);

    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./CometMainInterface.sol";
import "./CometExtInterface.sol";

/**
 * @title Compound's Comet Interface
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometInterface is CometMainInterface, CometExtInterface {
    struct UserBasic {
        int104 principal;
        uint64 baseTrackingIndex;
        uint64 baseTrackingAccrued;
    }

    function userBasic(address account) external view virtual returns (UserBasic memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
}

/**
 * @title Compound's Comet Main Interface (without Ext)
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometMainInterface {
    error Absurd();
    error AlreadyInitialized();
    error BadAsset();
    error BadDecimals();
    error BadDiscount();
    error BadMinimum();
    error BadPrice();
    error BorrowTooSmall();
    error BorrowCFTooLarge();
    error InsufficientReserves();
    error LiquidateCFTooLarge();
    error NoSelfTransfer();
    error NotCollateralized();
    error NotForSale();
    error NotLiquidatable();
    error Paused();
    error SupplyCapExceeded();
    error TimestampTooLarge();
    error TooManyAssets();
    error TooMuchSlippage();
    error TransferInFailed();
    error TransferOutFailed();
    error Unauthorized();

    event Supply(address indexed from, address indexed dst, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed src, address indexed to, uint256 amount);

    event SupplyCollateral(
        address indexed from,
        address indexed dst,
        address indexed asset,
        uint256 amount
    );
    event TransferCollateral(
        address indexed from,
        address indexed to,
        address indexed asset,
        uint256 amount
    );
    event WithdrawCollateral(
        address indexed src,
        address indexed to,
        address indexed asset,
        uint256 amount
    );

    /// @notice Event emitted when a borrow position is absorbed by the protocol
    event AbsorbDebt(
        address indexed absorber,
        address indexed borrower,
        uint256 basePaidOut,
        uint256 usdValue
    );

    /// @notice Event emitted when a user's collateral is absorbed by the protocol
    event AbsorbCollateral(
        address indexed absorber,
        address indexed borrower,
        address indexed asset,
        uint256 collateralAbsorbed,
        uint256 usdValue
    );

    /// @notice Event emitted when a collateral asset is purchased from the protocol
    event BuyCollateral(
        address indexed buyer,
        address indexed asset,
        uint256 baseAmount,
        uint256 collateralAmount
    );

    /// @notice Event emitted when an action is paused/unpaused
    event PauseAction(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    );

    /// @notice Event emitted when reserves are withdrawn by the governor
    event WithdrawReserves(address indexed to, uint256 amount);

    function supply(address asset, uint256 amount) external virtual;

    function supplyTo(
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function supplyFrom(
        address from,
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function transfer(address dst, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function transferAsset(
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function transferAssetFrom(
        address src,
        address dst,
        address asset,
        uint256 amount
    ) external virtual;

    function withdraw(address asset, uint256 amount) external virtual;

    function withdrawTo(
        address to,
        address asset,
        uint256 amount
    ) external virtual;

    function withdrawFrom(
        address src,
        address to,
        address asset,
        uint256 amount
    ) external virtual;

    function approveThis(
        address manager,
        address asset,
        uint256 amount
    ) external virtual;

    function withdrawReserves(address to, uint256 amount) external virtual;

    function absorb(address absorber, address[] calldata accounts) external virtual;

    function buyCollateral(
        address asset,
        uint256 minAmount,
        uint256 baseAmount,
        address recipient
    ) external virtual;

    function quoteCollateral(address asset, uint256 baseAmount)
        public
        view
        virtual
        returns (uint256);

    function getAssetInfo(uint8 i) public view virtual returns (AssetInfo memory);

    function getAssetInfoByAddress(address asset) public view virtual returns (AssetInfo memory);

    function getReserves() public view virtual returns (int256);

    function getPrice(address priceFeed) public view virtual returns (uint256);

    function isBorrowCollateralized(address account) public view virtual returns (bool);

    function isLiquidatable(address account) public view virtual returns (bool);

    function totalSupply() external view virtual returns (uint256);

    function totalBorrow() external view virtual returns (uint256);

    function balanceOf(address owner) public view virtual returns (uint256);

    function borrowBalanceOf(address account) public view virtual returns (uint256);

    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) external virtual;

    function isSupplyPaused() public view virtual returns (bool);

    function isTransferPaused() public view virtual returns (bool);

    function isWithdrawPaused() public view virtual returns (bool);

    function isAbsorbPaused() public view virtual returns (bool);

    function isBuyPaused() public view virtual returns (bool);

    function accrueAccount(address account) external virtual;

    function getSupplyRate(uint256 utilization) public view virtual returns (uint64);

    function getBorrowRate(uint256 utilization) public view virtual returns (uint64);

    function getUtilization() public view virtual returns (uint256);

    function governor() external view virtual returns (address);

    function pauseGuardian() external view virtual returns (address);

    function baseToken() external view virtual returns (address);

    function baseTokenPriceFeed() external view virtual returns (address);

    function extensionDelegate() external view virtual returns (address);

    /// @dev uint64
    function supplyKink() external view virtual returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() external view virtual returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() external view virtual returns (uint256);

    /// @dev uint64
    function supplyPerSecondInterestRateBase() external view virtual returns (uint256);

    /// @dev uint64
    function borrowKink() external view virtual returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() external view virtual returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() external view virtual returns (uint256);

    /// @dev uint64
    function borrowPerSecondInterestRateBase() external view virtual returns (uint256);

    /// @dev uint64
    function storeFrontPriceFactor() external view virtual returns (uint256);

    /// @dev uint64
    function baseScale() external view virtual returns (uint256);

    /// @dev uint64
    function trackingIndexScale() external view virtual returns (uint256);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view virtual returns (uint256);

    /// @dev uint64
    function baseTrackingBorrowSpeed() external view virtual returns (uint256);

    /// @dev uint104
    function baseMinForRewards() external view virtual returns (uint256);

    /// @dev uint104
    function baseBorrowMin() external view virtual returns (uint256);

    /// @dev uint104
    function targetReserves() external view virtual returns (uint256);

    function numAssets() external view virtual returns (uint8);

    function decimals() external view virtual returns (uint8);

    function initializeStorage() external virtual;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

interface ICometRewards {
    struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }

    struct RewardOwed {
        address token;
        uint256 owed;
    }

    function rewardConfig(address) external view returns (RewardConfig memory);

    function claim(
        address comet,
        address src,
        bool shouldAccrue
    ) external;

    function getRewardOwed(address comet, address account) external returns (RewardOwed memory);

    function claimTo(
        address comet,
        address src,
        address to,
        bool shouldAccrue
    ) external;
}

// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.17;

import "./IWrappedERC20.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This is a "soft-fork" of Open Zeppelin's ERC20 contract but with some notable
 * changes including:
 *
 *   - The allowance system is changed so that users are either allowed or not.
 *   There are no approved/allowed amounts. `approve` function still exists to
 *   adhere to the ERC-20 interface.
 *
 *   - Adds `allow` for easier authorization and is an easier-to-use alternative
 *   to `approve`.
 *
 *   - All hooks are removed except for `_beforeTokenTransfer` in `_transfer`.
 *   This is done to save on gas.
 *
 *   - All reverts use custom errors instead of strings. Another gas-optimization.
 *
 *   - Adds `hasPermission` which works the same as `allowance` and checks whether
 *   a user is authorized to make balance transfers.
 *
 *   - Some state variables are removed in anticipation of this contract
 *   being inherited by the cUSDCv3 wrapper
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract WrappedERC20 is IWrappedERC20 {
    error BadAmount();
    error Unauthorized();
    error ZeroAddress();
    error ExceedsBalance(uint256 amount);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => bool)) public isAllowed;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
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
        return hasPermission(owner, spender) ? type(uint256).max : 0;
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
        if (spender == address(0)) revert ZeroAddress();
        if (amount == type(uint256).max) {
            _allow(msg.sender, spender, true);
        } else if (amount == 0) {
            _allow(msg.sender, spender, false);
        } else {
            revert BadAmount();
        }
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
     * - the caller must be authorized to transfer ``from``'s tokens
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (!hasPermission(from, msg.sender)) revert Unauthorized();
        _transfer(from, to, amount);
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
        if (from == address(0)) revert ZeroAddress();
        if (to == address(0)) revert ZeroAddress();

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        if (amount > fromBalance) revert ExceedsBalance(amount);
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
        if (account == address(0)) revert ZeroAddress();

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
        if (account == address(0)) revert ZeroAddress();

        uint256 accountBalance = _balances[account];
        if (amount > accountBalance) revert ExceedsBalance(amount);
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Allow or disallow another address to withdraw, or transfer from the sender.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `manager` cannot be the zero address.
     */
    function allow(address account, bool isAllowed_) external {
        _allow(msg.sender, account, isAllowed_);
    }

    /**
     * @dev Gives `manager` control over the  `owner` s tokens.
     *
     * This internal function is equivalent to `allow`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `manager` cannot be the zero address.
     */
    function _allow(
        address owner,
        address manager,
        bool isAllowed_
    ) internal {
        if (owner == address(0)) revert ZeroAddress();
        if (manager == address(0)) revert ZeroAddress();

        isAllowed[owner][manager] = isAllowed_;
        emit Approval(owner, manager, isAllowed_ ? type(uint256).max : 0);
    }

    /**
     * @dev Determine if the `manager` has permission to act on behalf of the `owner`.
     */
    function hasPermission(address owner, address manager) public view returns (bool) {
        return owner == manager || isAllowed[owner][manager];
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This does not include
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     */
    // solhint-disable no-empty-blocks
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}