// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IWormhole.sol";
import "./libraries/external/BytesLib.sol";

import "./CrossChainBorrowLendStructs.sol";
import "./CrossChainBorrowLendGetters.sol";
import "./CrossChainBorrowLendMessages.sol";

contract CrossChainBorrowLend is
    CrossChainBorrowLendGetters,
    CrossChainBorrowLendMessages,
    ReentrancyGuard
{
    constructor(
        address wormholeContractAddress_,
        uint8 consistencyLevel_,
        address mockPythAddress_,
        uint16 targetChainId_,
        bytes32 targetContractAddress_,
        address collateralAsset_,
        bytes32 collateralAssetPythId_,
        uint256 collateralizationRatio_,
        address borrowingAsset_,
        uint8 borrowTokenDecimals_,
        bytes32 borrowingAssetPythId_,
        uint256 repayGracePeriod_
    ) {
        // REVIEW: set owner for only owner methods if desired

        state.owner = msg.sender;
        // wormhole
        state.wormholeContractAddress = wormholeContractAddress_;
        state.consistencyLevel = consistencyLevel_;

        // target chain info
        state.targetChainId = targetChainId_;
        state.targetContractAddress = targetContractAddress_;

        // collateral params
        state.collateralAssetAddress = collateralAsset_;
        state.collateralizationRatio = collateralizationRatio_;
        state.collateralizationRatioPrecision = 1e18; // fixed

        // borrowing asset address
        state.borrowingAssetAddress = borrowingAsset_;
        state.borrowTokenDecimals = borrowTokenDecimals_;

        // interest rate parameters
        state.interestRateModel.ratePrecision = 1e18;
        state.interestRateModel.rateIntercept = 2e16; // 2%
        state.interestRateModel.rateCoefficientA = 0;

        // Price index of 1 with the current precision is 1e18
        // since this is the precision of our value.
        uint256 precision = 1e18;
        state.interestAccrualIndexPrecision = precision;
        state.interestAccrualIndex.source.deposited = precision;
        state.interestAccrualIndex.source.borrowed = precision;
        state.interestAccrualIndex.target.deposited = precision;
        state.interestAccrualIndex.target.borrowed = precision;

        // pyth oracle address and asset IDs
        state.mockPythAddress = mockPythAddress_;
        state.collateralAssetPythId = collateralAssetPythId_;
        state.borrowingAssetPythId = borrowingAssetPythId_;

        // repay grace period for this chain
        state.repayGracePeriod = repayGracePeriod_;
    }

    modifier onlyOwner() {
        require(state.owner == msg.sender, "Caller not owner");
        _;
    }

    function addCollateral(uint256 amount)
        public
        nonReentrant
        returns (uint64 sequence)
    {
        require(amount > 0, "nothing to deposit");

        // update current price index
        updateSourceInterestAccrualIndex();

        // update state for supplier
        uint256 normalizedAmount = normalizeAmount(
            amount, // e.g usdt : 100 usdt
            sourceCollateralInterestAccrualIndex() // : 1e18
        ); // 100 usdt will be returned

        state.accountAssets[_msgSender()].source.deposited += normalizedAmount;
        state.totalAssets.source.deposited += normalizedAmount;

        SafeERC20.safeTransferFrom(
            collateralToken(),
            _msgSender(),
            address(this),
            amount // TODO : change this to normalizedAmount
        );

        // construct wormhole message
        MessageHeader memory header = MessageHeader({
            payloadID: uint8(5),
            sender: _msgSender(),
            collateralAddress: state.collateralAssetAddress,
            borrowAddress: state.borrowingAssetAddress
        });

        sequence = sendWormholeMessage(
            encodeDepositChangeMessage(
                DepositChangeMessage({
                    header: header,
                    depositType: DepositType.Add,
                    amount: normalizeAmount(
                        amount,
                        sourceCollateralInterestAccrualIndex()
                    )
                })
            )
        );

        // emit
    }

    function removeCollateral(uint256 amount)
        public
        nonReentrant
        returns (uint64 sequence)
    {
        require(amount > 0, "nothing to withdraw");

        // update current price index
        updateSourceInterestAccrualIndex();

        // Check if user has enough to withdraw from the contract
        require(
            amount < maxAllowedToWithdraw(_msgSender()),
            "amount >= maxAllowedToWithdraw(msg.sender)"
        );

        // update state for supplier
        uint256 normalizedAmount = normalizeAmount(
            amount,
            sourceCollateralInterestAccrualIndex()
        );
        state.accountAssets[_msgSender()].source.deposited -= normalizedAmount;
        state.totalAssets.source.deposited -= normalizedAmount;

        // transfer the tokens to the caller
        SafeERC20.safeTransfer(collateralToken(), _msgSender(), amount);

        // construct wormhole message
        MessageHeader memory header = MessageHeader({
            payloadID: uint8(5),
            sender: _msgSender(),
            collateralAddress: state.collateralAssetAddress,
            borrowAddress: state.borrowingAssetAddress
        });

        sequence = sendWormholeMessage(
            encodeDepositChangeMessage(
                DepositChangeMessage({
                    header: header,
                    depositType: DepositType.Remove,
                    amount: normalizedAmount
                })
            )
        );
    }

    function removeCollateralInFull()
        public
        nonReentrant
        returns (uint64 sequence)
    {
        // fetch the account information for the caller
        SourceTargetUints memory account = state.accountAssets[_msgSender()];

        // make sure the account has closed all borrowed positions
        require(account.target.borrowed == 0, "account has outstanding loans");

        // update current price index
        updateSourceInterestAccrualIndex();

        // update state for supplier
        uint256 normalizedAmount = account.source.deposited;
        state.accountAssets[_msgSender()].source.deposited = 0;
        state.totalAssets.source.deposited -= normalizedAmount;

        // transfer the tokens to the caller
        SafeERC20.safeTransfer(
            collateralToken(),
            _msgSender(),
            denormalizeAmount(
                normalizedAmount,
                sourceCollateralInterestAccrualIndex()
            )
        );

        // construct wormhole message
        MessageHeader memory header = MessageHeader({
            payloadID: uint8(5),
            sender: _msgSender(),
            collateralAddress: state.collateralAssetAddress,
            borrowAddress: state.borrowingAssetAddress
        });

        sequence = sendWormholeMessage(
            encodeDepositChangeMessage(
                DepositChangeMessage({
                    header: header,
                    depositType: DepositType.RemoveFull,
                    amount: normalizedAmount
                })
            )
        );
    }

    function completeCollateralChange(bytes memory encodedVm) public {
        // parse and verify the wormhole BorrowMessage
        (
            IWormhole.VM memory parsed,
            bool valid,
            string memory reason
        ) = wormhole().parseAndVerifyVM(encodedVm);
        require(valid, reason);

        // verify emitter
        require(verifyEmitter(parsed), "invalid emitter");

        // completed (replay protection)
        // also serves as reentrancy protection
        require(!messageHashConsumed(parsed.hash), "message already consumed");
        consumeMessageHash(parsed.hash);

        // decode deposit change message
        DepositChangeMessage memory params = decodeDepositChangeMessage(
            parsed.payload
        );
        address depositor = params.header.sender;

        // correct assets?
        require(
            params.header.collateralAddress == state.borrowingAssetAddress &&
                params.header.borrowAddress == state.collateralAssetAddress,
            "invalid asset metadata"
        );

        // update current price index
        updateTargetInterestAccrualIndex();

        // update this contracts state to reflect the deposit change
        if (params.depositType == DepositType.Add) {
            state.totalAssets.target.deposited += params.amount;
            state.accountAssets[depositor].target.deposited += params.amount;
        } else if (params.depositType == DepositType.Remove) {
            state.totalAssets.target.deposited -= params.amount;
            state.accountAssets[depositor].target.deposited -= params.amount;
        } else if (params.depositType == DepositType.RemoveFull) {
            // fetch the deposit amount from state
            state.totalAssets.target.deposited -= state
                .accountAssets[depositor]
                .target
                .deposited;
            state.accountAssets[depositor].target.deposited = 0;
        }
    }

    function computeSourceInterestFactor(
        uint256 secondsElapsed,
        uint256 intercept,
        uint256 coefficient
    ) internal view returns (uint256) {
        return
            _computeInterestFactor(
                secondsElapsed,
                intercept,
                coefficient,
                state.totalAssets.source.deposited,
                state.totalAssets.source.borrowed
            );
    }

    function computeTargetInterestFactor(
        uint256 secondsElapsed,
        uint256 intercept,
        uint256 coefficient
    ) internal view returns (uint256) {
        return
            _computeInterestFactor(
                secondsElapsed,
                intercept,
                coefficient,
                state.totalAssets.target.deposited,
                state.totalAssets.target.borrowed
            );
    }

    function _computeInterestFactor(
        uint256 secondsElapsed,
        uint256 intercept,
        uint256 coefficient,
        uint256 deposited,
        uint256 borrowed
    ) internal pure returns (uint256) {
        if (deposited == 0) {
            return 0;
        }
        return
            (secondsElapsed *
                (intercept + (coefficient * borrowed) / deposited)) /
            365 /
            24 /
            60 /
            60;
    }

    function updateSourceInterestAccrualIndex() internal {
        // TODO: change to block.number?
        uint256 secondsElapsed = block.timestamp -
            state.lastActivityBlockTimestamp;

        if (secondsElapsed == 0) {
            // nothing to do
            return;
        }

        // Should not hit, but just here in case someone
        // tries to update the interest when there is nothing
        // deposited.
        uint256 deposited = state.totalAssets.source.deposited;
        if (deposited == 0) {
            return;
        }

        state.lastActivityBlockTimestamp = block.timestamp;
        uint256 interestFactor = computeSourceInterestFactor(
            secondsElapsed,
            state.interestRateModel.rateIntercept,
            state.interestRateModel.rateCoefficientA
        );
        state.interestAccrualIndex.source.borrowed += interestFactor;
        state.interestAccrualIndex.source.deposited +=
            (interestFactor * state.totalAssets.source.borrowed) /
            deposited;
    }

    function updateTargetInterestAccrualIndex() internal {
        uint256 secondsElapsed = block.timestamp -
            state.lastActivityBlockTimestamp;

        if (secondsElapsed == 0) {
            // nothing to do
            return;
        }

        // Should not hit, but just here in case someone
        // tries to update the interest when there is nothing
        // deposited.
        uint256 deposited = state.totalAssets.target.deposited;
        if (deposited == 0) {
            return;
        }

        state.lastActivityBlockTimestamp = block.timestamp;
        uint256 interestFactor = computeTargetInterestFactor(
            secondsElapsed,
            state.interestRateModel.rateIntercept,
            state.interestRateModel.rateCoefficientA
        );
        state.interestAccrualIndex.target.borrowed += interestFactor;
        state.interestAccrualIndex.target.deposited +=
            (interestFactor * state.totalAssets.target.borrowed) /
            deposited;
    }

    function initiateBorrow(uint256 amount) public returns (uint64 sequence) {
        require(amount > 0, "nothing to borrow");

        // update current price index
        updateTargetInterestAccrualIndex();

        // Check if user has enough to borrow
        require(
            amount < maxAllowedToBorrow(_msgSender()),
            "amount >= maxAllowedToBorrow(msg.sender)"
        );

        // update state for borrower
        uint256 borrowedIndex = targetBorrowedInterestAccrualIndex();
        uint256 normalizedAmount = normalizeAmount(amount, borrowedIndex);
        state.accountAssets[_msgSender()].target.borrowed += normalizedAmount;
        state.totalAssets.target.borrowed += normalizedAmount;

        // construct wormhole message
        MessageHeader memory header = MessageHeader({
            payloadID: uint8(1),
            sender: _msgSender(),
            collateralAddress: state.collateralAssetAddress,
            borrowAddress: state.borrowingAssetAddress
        });

        sequence = sendWormholeMessage(
            encodeBorrowMessage(
                BorrowMessage({
                    header: header,
                    borrowAmount: amount,
                    totalNormalizedBorrowAmount: state
                        .accountAssets[_msgSender()]
                        .target
                        .borrowed,
                    interestAccrualIndex: borrowedIndex
                })
            )
        );
    }

    function completeBorrow(bytes calldata encodedVm)
        public
        returns (uint64 sequence)
    {
        // parse and verify the wormhole BorrowMessage
        (
            IWormhole.VM memory parsed,
            bool valid,
            string memory reason
        ) = wormhole().parseAndVerifyVM(encodedVm);
        require(valid, reason);

        // verify emitter
        require(verifyEmitter(parsed), "invalid emitter");

        // completed (replay protection)
        // also serves as reentrancy protection
        require(!messageHashConsumed(parsed.hash), "message already consumed");
        consumeMessageHash(parsed.hash);

        // decode borrow message
        BorrowMessage memory params = decodeBorrowMessage(parsed.payload);
        address borrower = params.header.sender;

        // correct assets?
        require(verifyAssetMetaFromBorrow(params), "invalid asset metadata");

        // update current price index
        updateSourceInterestAccrualIndex();

        // make sure this contract has enough assets to fund the borrow
        if (
            normalizeAmount(
                params.borrowAmount,
                sourceBorrowedInterestAccrualIndex()
            ) > sourceLiquidity()
        ) {
            // construct RevertBorrow wormhole message
            // switch the borrow and collateral addresses for the target chain
            MessageHeader memory header = MessageHeader({
                payloadID: uint8(2),
                sender: borrower,
                collateralAddress: state.borrowingAssetAddress,
                borrowAddress: state.collateralAssetAddress
            });

            sequence = sendWormholeMessage(
                encodeRevertBorrowMessage(
                    RevertBorrowMessage({
                        header: header,
                        borrowAmount: params.borrowAmount,
                        sourceInterestAccrualIndex: params.interestAccrualIndex
                    })
                )
            );
        } else {
            // save the total normalized borrow amount for repayments
            state.totalAssets.source.borrowed +=
                params.totalNormalizedBorrowAmount -
                state.accountAssets[borrower].source.borrowed;
            state.accountAssets[borrower].source.borrowed = params
                .totalNormalizedBorrowAmount;

            // params.borrowAmount == 0 means that there was a repayment
            // made outside of the grace period, so we will have received
            // another VAA representing the updated borrowed amount
            // on the source chain.
            if (params.borrowAmount > 0) {
                // finally transfer
                SafeERC20.safeTransferFrom(
                    collateralToken(),
                    address(this),
                    borrower,
                    params.borrowAmount
                );
            }

            // no wormhole message, return the default value: zero == success
        }
    }

    function completeRevertBorrow(bytes calldata encodedVm) public {
        // parse and verify the wormhole RevertBorrowMessage
        (
            IWormhole.VM memory parsed,
            bool valid,
            string memory reason
        ) = wormhole().parseAndVerifyVM(encodedVm);
        require(valid, reason);

        // verify emitter
        require(verifyEmitter(parsed), "invalid emitter");

        // completed (replay protection)
        // also serves as reentrancy protection
        require(!messageHashConsumed(parsed.hash), "message already consumed");
        consumeMessageHash(parsed.hash);

        // decode borrow message
        RevertBorrowMessage memory params = decodeRevertBorrowMessage(
            parsed.payload
        );

        // verify asset meta
        require(
            state.collateralAssetAddress == params.header.collateralAddress &&
                state.borrowingAssetAddress == params.header.borrowAddress,
            "invalid asset metadata"
        );

        // update state for borrower
        // Normalize the borrowAmount by the original interestAccrualIndex (encoded in the BorrowMessage)
        // to revert the inteded borrow amount.
        uint256 normalizedAmount = normalizeAmount(
            params.borrowAmount,
            params.sourceInterestAccrualIndex
        );
        state
            .accountAssets[params.header.sender]
            .target
            .borrowed -= normalizedAmount;
        state.totalAssets.target.borrowed -= normalizedAmount;
    }

    function initiateRepay(uint256 amount)
        public
        nonReentrant
        returns (uint64 sequence)
    {
        require(amount > 0, "nothing to repay");

        // For EVMs, same private key will be used for borrowing-lending activity.
        // When introducing other chains (e.g. Cosmos), need to do wallet registration
        // so we can access a map of a non-EVM address based on this EVM borrower
        SourceTargetUints memory account = state.accountAssets[_msgSender()];

        // update the index
        updateSourceInterestAccrualIndex();

        // cache the index to save gas
        uint256 borrowedIndex = sourceBorrowedInterestAccrualIndex();

        // save the normalized amount
        uint256 normalizedAmount = normalizeAmount(amount, borrowedIndex);

        // confirm that the caller has loans to pay back
        require(
            normalizedAmount <= account.source.borrowed,
            "loan payment too large"
        );

        // update state on this contract
        state.accountAssets[_msgSender()].source.borrowed -= normalizedAmount;
        state.totalAssets.source.borrowed -= normalizedAmount;

        // transfer to this contract
        SafeERC20.safeTransferFrom(
            borrowToken(),
            _msgSender(),
            address(this),
            amount
        );

        // construct wormhole message
        MessageHeader memory header = MessageHeader({
            payloadID: uint8(3),
            sender: _msgSender(),
            collateralAddress: state.borrowingAssetAddress,
            borrowAddress: state.collateralAssetAddress
        });

        // add index and block timestamp
        sequence = sendWormholeMessage(
            encodeRepayMessage(
                RepayMessage({
                    header: header,
                    repayAmount: amount,
                    targetInterestAccrualIndex: borrowedIndex,
                    repayTimestamp: block.timestamp,
                    paidInFull: 0
                })
            )
        );
    }

    function initiateRepayInFull()
        public
        nonReentrant
        returns (uint64 sequence)
    {
        // For EVMs, same private key will be used for borrowing-lending activity.
        // When introducing other chains (e.g. Cosmos), need to do wallet registration
        // so we can access a map of a non-EVM address based on this EVM borrower
        SourceTargetUints memory account = state.accountAssets[_msgSender()];

        // update the index
        updateSourceInterestAccrualIndex();

        // cache the index to save gas
        uint256 borrowedIndex = sourceBorrowedInterestAccrualIndex();

        // update state on the contract
        uint256 normalizedAmount = account.source.borrowed;
        state.accountAssets[_msgSender()].source.borrowed = 0;
        state.totalAssets.source.borrowed -= normalizedAmount;

        // transfer to this contract
        SafeERC20.safeTransferFrom(
            borrowToken(),
            _msgSender(),
            address(this),
            denormalizeAmount(normalizedAmount, borrowedIndex)
        );

        // construct wormhole message
        MessageHeader memory header = MessageHeader({
            payloadID: uint8(3),
            sender: _msgSender(),
            collateralAddress: state.borrowingAssetAddress,
            borrowAddress: state.collateralAssetAddress
        });

        // add index and block timestamp
        sequence = sendWormholeMessage(
            encodeRepayMessage(
                RepayMessage({
                    header: header,
                    repayAmount: denormalizeAmount(
                        normalizedAmount,
                        borrowedIndex
                    ),
                    targetInterestAccrualIndex: borrowedIndex,
                    repayTimestamp: block.timestamp,
                    paidInFull: 1
                })
            )
        );
    }

    function completeRepay(bytes calldata encodedVm)
        public
        returns (uint64 sequence)
    {
        // parse and verify the RepayMessage
        (
            IWormhole.VM memory parsed,
            bool valid,
            string memory reason
        ) = wormhole().parseAndVerifyVM(encodedVm);
        require(valid, reason);

        // verify emitter
        require(verifyEmitter(parsed), "invalid emitter");

        // completed (replay protection)
        require(!messageHashConsumed(parsed.hash), "message already consumed");
        consumeMessageHash(parsed.hash);

        // update the index
        updateTargetInterestAccrualIndex();

        // cache the index to save gas
        uint256 borrowedIndex = targetBorrowedInterestAccrualIndex();

        // decode the RepayMessage
        RepayMessage memory params = decodeRepayMessage(parsed.payload);
        address borrower = params.header.sender;

        // correct assets?
        require(verifyAssetMetaFromRepay(params), "invalid asset metadata");

        // see if the loan is repaid in full
        if (params.paidInFull == 1) {
            // REVIEW: do we care about getting the VAA in time?
            if (
                params.repayTimestamp + state.repayGracePeriod <=
                block.timestamp
            ) {
                // update state in this contract
                uint256 normalizedAmount = normalizeAmount(
                    params.repayAmount,
                    params.targetInterestAccrualIndex
                );
                state.accountAssets[borrower].target.borrowed = 0;
                state.totalAssets.target.borrowed -= normalizedAmount;
            } else {
                uint256 normalizedAmount = normalizeAmount(
                    params.repayAmount,
                    borrowedIndex
                );
                state
                    .accountAssets[borrower]
                    .target
                    .borrowed -= normalizedAmount;
                state.totalAssets.target.borrowed -= normalizedAmount;

                // Send a wormhole message again since he did not repay in full
                // (due to repaying outside of the grace period)
                sequence = sendWormholeMessage(
                    encodeBorrowMessage(
                        BorrowMessage({
                            header: MessageHeader({
                                payloadID: uint8(1),
                                sender: borrower,
                                collateralAddress: state.collateralAssetAddress,
                                borrowAddress: state.borrowingAssetAddress
                            }),
                            borrowAmount: 0, // special value to indicate failed repay in full
                            totalNormalizedBorrowAmount: state
                                .accountAssets[borrower]
                                .target
                                .borrowed,
                            interestAccrualIndex: borrowedIndex
                        })
                    )
                );
            }
        } else {
            // update state in this contract
            uint256 normalizedAmount = normalizeAmount(
                params.repayAmount,
                params.targetInterestAccrualIndex
            );
            state.accountAssets[borrower].target.borrowed -= normalizedAmount;
            state.totalAssets.target.borrowed -= normalizedAmount;
        }
    }

    /**
     @notice `initiateLiquidationOnTargetChain` has not been implemented yet.

     This function should determine if a particular position is undercollateralized
     by querying the `accountAssets` state variable for the passed account. Calculate
     the health of the account.

     If an account is undercollateralized, this method should generate a Wormhole
     message sent to the target chain by the caller. The caller will invoke the
     `completeRepayOnBehalf` method on the target chain and pass the signed Wormhole
     message as an argument.

     If the account has not yet paid the loan back by the time the Wormhole message
     arrives on the target chain, `completeRepayOnBehalf` will accept funds from the
     caller, and generate another Wormhole messsage to be delivered to the source chain.

     The caller will then invoke `completeLiquidation` on the source chain and pass
     the signed Wormhole message in as an argument. This function should handle
     releasing the account's collateral to the liquidator, less fees (which should be
     defined in the contract and updated by the contract owner).

     In order for off-chain processes to calculate an account's health, the integrator
     needs to expose a getter that will return the list of accounts with open positions.
     The integrator needs to expose a getter that allows the liquidator to query the
     `accountAssets` state variable for a particular account.
    */
    function initiateLiquidationOnTargetChain(address accountToLiquidate)
        public
    {}

    function completeRepayOnBehalf(bytes calldata encodedVm) public {}

    function completeLiquidation(bytes calldata encodedVm) public {}

    function sendWormholeMessage(bytes memory payload)
        internal
        returns (uint64 sequence)
    {
        sequence = IWormhole(state.wormholeContractAddress).publishMessage(
            0, // nonce
            payload,
            state.consistencyLevel
        );
    }

    function verifyEmitter(IWormhole.VM memory parsed)
        internal
        view
        returns (bool)
    {
        return
            parsed.emitterAddress == state.targetContractAddress &&
            parsed.emitterChainId == state.targetChainId;
    }

    function verifyAssetMetaFromBorrow(BorrowMessage memory params)
        internal
        view
        returns (bool)
    {
        return
            params.header.collateralAddress == state.borrowingAssetAddress &&
            params.header.borrowAddress == state.collateralAssetAddress;
    }

    function verifyAssetMetaFromRepay(RepayMessage memory params)
        internal
        view
        returns (bool)
    {
        return
            params.header.collateralAddress == state.collateralAssetAddress &&
            params.header.borrowAddress == state.borrowingAssetAddress;
    }

    function consumeMessageHash(bytes32 vmHash) internal {
        state.consumedMessages[vmHash] = true;
    }

    function updateTargetContractAddress(bytes32 _newAddr) external onlyOwner {
        state.targetContractAddress = _newAddr;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import "./interfaces/IMockPyth.sol";
import "./interfaces/IWormhole.sol";
import "./CrossChainBorrowLendState.sol";

// import "forge-std/src/console.sol";

contract CrossChainBorrowLendGetters is Context, CrossChainBorrowLendState {
    function wormhole() internal view returns (IWormhole) {
        return IWormhole(state.wormholeContractAddress);
    }

    function collateralToken() internal view returns (IERC20) {
        return IERC20(state.collateralAssetAddress);
    }

    function collateralTokenDecimals() internal view returns (uint8) {
        return IERC20Metadata(state.collateralAssetAddress).decimals();
    }

    function borrowToken() internal view returns (IERC20) {
        return IERC20(state.borrowingAssetAddress);
    }

    function borrowTokenDecimals() internal view returns (uint8) {
        return state.borrowTokenDecimals;
    }

    function getOraclePrices() internal view returns (uint64, uint64) {
        IMockPyth.PriceFeed memory collateralFeed = mockPyth().queryPriceFeed(
            state.collateralAssetPythId
        );
        IMockPyth.PriceFeed memory borrowFeed = mockPyth().queryPriceFeed(
            state.borrowingAssetPythId
        );

        // sanity check the price feeds
        require(
            collateralFeed.price.price > 0 && borrowFeed.price.price > 0,
            "negative prices detected"
        );

        // Users of Pyth prices should read: https://docs.pyth.network/consumers/best-practices
        // before using the price feed. Blindly using the price alone is not recommended.
        return (
            uint64(collateralFeed.price.price),
            uint64(borrowFeed.price.price)
        );
    }

    function sourceCollateralInterestAccrualIndex()
        public
        view
        returns (uint256)
    {
        return state.interestAccrualIndex.source.deposited;
    }

    function targetCollateralInterestAccrualIndex()
        public
        view
        returns (uint256)
    {
        return state.interestAccrualIndex.target.deposited;
    }

    function sourceBorrowedInterestAccrualIndex()
        public
        view
        returns (uint256)
    {
        return state.interestAccrualIndex.source.borrowed;
    }

    function targetBorrowedInterestAccrualIndex()
        public
        view
        returns (uint256)
    {
        return state.interestAccrualIndex.target.borrowed;
    }

    function mockPyth() internal view returns (IMockPyth) {
        return IMockPyth(state.mockPythAddress);
    }

    function sourceLiquidity() internal view returns (uint256) {
        return
            state.totalAssets.source.deposited -
            state.totalAssets.source.borrowed;
    }

    function denormalizeAmount(
        uint256 normalizedAmount,
        uint256 interestAccrualIndex_
    ) public view returns (uint256) {
        return
            (normalizedAmount * interestAccrualIndex_) /
            state.interestAccrualIndexPrecision;
    }

    function normalizeAmount(
        uint256 denormalizedAmount,
        uint256 interestAccrualIndex_
    ) public view returns (uint256) {
        return
            (denormalizedAmount * state.interestAccrualIndexPrecision) /
            interestAccrualIndex_;

        // denormalizedAmount = 100 * (10**6)
        // state.interestAccrualIndexPrecision = 1e18
        // interestAccrualIndex_ = 1e18
        // so after the math, out amount will be as it is in denormalize decimals
    }

    function messageHashConsumed(bytes32 hash) public view returns (bool) {
        return state.consumedMessages[hash];
    }

    function normalizedAmounts()
        public
        view
        returns (SourceTargetUints memory)
    {
        return state.totalAssets;
    }

    function maxAllowedToBorrowWithPrices(
        address account,
        uint64 collateralPrice,
        uint64 borrowAssetPrice
    ) internal view returns (uint256) {
        // For EVMs, same private key will be used for borrowing-lending activity.
        // When introducing other chains (e.g. Cosmos), need to do wallet registration
        // so we can access a map of a non-EVM address based on this EVM borrower
        SourceTargetUints memory normalized = state.accountAssets[account];

        // denormalize
        uint256 denormalizedDeposited = denormalizeAmount(
            normalized.source.deposited,
            sourceCollateralInterestAccrualIndex()
        );
        uint256 denormalizedBorrowed = denormalizeAmount(
            normalized.target.borrowed,
            targetBorrowedInterestAccrualIndex()
        );

        // in case of first time borrow. user has "normalized.target.borrowed = 0"

        // collateralPriceFromOracle = 1e6
        // collateralizationRatio = 0.8e18
        // denormalizedDeposited = 500
        // borrowTokenDecimals = 18
        // collateralTokenDecimals = 6
        // collateralizationRatioPrecision = 1e18
        // borrowAssetPriceFromOracle = 1200 * (1e18)

        // denormalizedBorrowed = 0

        // (denormalizedDeposited * state.collateralizationRatio * collateralPriceFromOracle *borrowTokenDecimals ) / (state.collateralizationRatioPrecision * borrowAssetPriceFromOracle * collateralTokenDecimals) - denormalizedBorrowed

        // TODO : decimals of amounts by the oracle
        return
            (denormalizedDeposited *
                state.collateralizationRatio *
                collateralPrice *
                10**borrowTokenDecimals()) /
            (state.collateralizationRatioPrecision *
                borrowAssetPrice *
                10**collateralTokenDecimals()) -
            denormalizedBorrowed;
    }

    function maxAllowedToBorrow(address account) public view returns (uint256) {
        // fetch asset prices
        (uint64 collateralPrice, uint64 borrowAssetPrice) = getOraclePrices();
        return
            maxAllowedToBorrowWithPrices(
                account,
                collateralPrice,
                borrowAssetPrice
            );
    }

    function maxAllowedToWithdrawWithPrices(
        address account,
        uint64 collateralPrice,
        uint64 borrowAssetPrice
    ) internal view returns (uint256) {
        // For EVMs, same private key will be used for borrowing-lending activity.
        // When introducing other chains (e.g. Cosmos), need to do wallet registration
        // so we can access a map of a non-EVM address based on this EVM borrower
        SourceTargetUints memory normalized = state.accountAssets[account];

        // denormalize
        uint256 denormalizedDeposited = denormalizeAmount(
            normalized.source.deposited,
            sourceCollateralInterestAccrualIndex()
        );
        uint256 denormalizedBorrowed = denormalizeAmount(
            normalized.target.borrowed,
            targetBorrowedInterestAccrualIndex()
        );

        return
            denormalizedDeposited -
            (denormalizedBorrowed *
                state.collateralizationRatioPrecision *
                borrowAssetPrice *
                10**collateralTokenDecimals()) /
            (state.collateralizationRatio *
                collateralPrice *
                10**borrowTokenDecimals());
    }

    function maxAllowedToWithdraw(address account)
        public
        view
        returns (uint256)
    {
        (uint64 collateralPrice, uint64 borrowAssetPrice) = getOraclePrices();
        return
            maxAllowedToWithdrawWithPrices(
                account,
                collateralPrice,
                borrowAssetPrice
            );
    }

    function accountSourceDeposited(address _account)
        external
        view
        returns (uint256)
    {
        return state.accountAssets[_account].source.deposited;
    }

    function accountTargetDeposited(address _account)
        external
        view
        returns (uint256)
    {
        return state.accountAssets[_account].target.deposited;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./libraries/external/BytesLib.sol";

import "./CrossChainBorrowLendStructs.sol";

contract CrossChainBorrowLendMessages {
    using BytesLib for bytes;

    function encodeMessageHeader(MessageHeader memory header)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                header.sender,
                header.collateralAddress,
                header.borrowAddress
            );
    }

    function encodeBorrowMessage(BorrowMessage memory message)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                uint8(1), // payloadID
                encodeMessageHeader(message.header),
                message.borrowAmount,
                message.totalNormalizedBorrowAmount,
                message.interestAccrualIndex
            );
    }

    function encodeRevertBorrowMessage(RevertBorrowMessage memory message)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                uint8(2), // payloadID
                encodeMessageHeader(message.header),
                message.borrowAmount,
                message.sourceInterestAccrualIndex
            );
    }

    function encodeRepayMessage(RepayMessage memory message)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                uint8(3), // payloadID
                encodeMessageHeader(message.header),
                message.repayAmount,
                message.targetInterestAccrualIndex,
                message.repayTimestamp,
                message.paidInFull
            );
    }

    function encodeLiquidationIntentMessage(
        LiquidationIntentMessage memory message
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                uint8(4), // payloadID
                encodeMessageHeader(message.header)
            );
    }

    function encodeDepositChangeMessage(DepositChangeMessage memory message)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                uint8(5), // payloadID
                encodeMessageHeader(message.header),
                uint8(message.depositType),
                message.amount
            );
    }

    function decodeMessageHeader(bytes memory serialized)
        internal
        pure
        returns (MessageHeader memory header)
    {
        uint256 index = 0;

        // parse the header
        header.payloadID = serialized.toUint8(index += 1);
        header.sender = serialized.toAddress(index += 20);
        header.collateralAddress = serialized.toAddress(index += 20);
        header.borrowAddress = serialized.toAddress(index += 20);
    }

    function decodeBorrowMessage(bytes memory serialized)
        internal
        pure
        returns (BorrowMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(
            serialized.slice(index, index += 61)
        );
        params.borrowAmount = serialized.toUint256(index += 32);
        params.totalNormalizedBorrowAmount = serialized.toUint256(index += 32);
        params.interestAccrualIndex = serialized.toUint256(index += 32);

        require(params.header.payloadID == 1, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }

    function decodeRevertBorrowMessage(bytes memory serialized)
        internal
        pure
        returns (RevertBorrowMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(
            serialized.slice(index, index += 61)
        );
        params.borrowAmount = serialized.toUint256(index += 32);
        params.sourceInterestAccrualIndex = serialized.toUint256(index += 32);

        require(params.header.payloadID == 2, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }

    function decodeRepayMessage(bytes memory serialized)
        internal
        pure
        returns (RepayMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(
            serialized.slice(index, index += 61)
        );
        params.repayAmount = serialized.toUint256(index += 32);
        params.targetInterestAccrualIndex = serialized.toUint256(index += 32);
        params.repayTimestamp = serialized.toUint256(index += 32);
        params.paidInFull = serialized.toUint8(index += 1);

        require(params.header.payloadID == 3, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }

    function decodeLiquidationIntentMessage(bytes memory serialized)
        internal
        pure
        returns (LiquidationIntentMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(
            serialized.slice(index, index += 61)
        );

        // TODO: deserialize the LiquidationIntentMessage when implemented

        require(params.header.payloadID == 4, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }

    function decodeDepositChangeMessage(bytes memory serialized)
        internal
        pure
        returns (DepositChangeMessage memory params)
    {
        uint256 index = 0;

        // parse the message header
        params.header = decodeMessageHeader(
            serialized.slice(index, index += 61)
        );

        // handle DepositType enum value
        uint8 depositTypeValue = serialized.toUint8(index += 1);
        if (depositTypeValue == uint8(DepositType.Add)) {
            params.depositType = DepositType.Add;
        } else if (depositTypeValue == uint8(DepositType.Remove)) {
            params.depositType = DepositType.Remove;
        } else if (depositTypeValue == uint8(DepositType.RemoveFull)) {
            params.depositType = DepositType.RemoveFull;
        }
        else {
            revert("unrecognized deposit type");
        }
        params.amount = serialized.toUint256(index += 32);

        require(params.header.payloadID == 5, "invalid message");
        require(index == serialized.length, "index != serialized.length");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./CrossChainBorrowLendStructs.sol";

contract CrossChainBorrowLendStorage {
    struct State {
        // wormhole things
        address wormholeContractAddress;
        uint8 consistencyLevel;
        uint16 targetChainId;
        // precision variables
        uint256 collateralizationRatioPrecision;
        uint256 interestRatePrecision;
        // mock pyth price oracle
        address mockPythAddress;
        bytes32 targetContractAddress;
        // borrow and lend activity
        address collateralAssetAddress;
        bytes32 collateralAssetPythId;
        uint256 collateralizationRatio;
        address borrowingAssetAddress;
        uint8 borrowTokenDecimals;
        SourceTargetUints interestAccrualIndex;
        uint256 interestAccrualIndexPrecision;
        uint256 lastActivityBlockTimestamp;
        SourceTargetUints totalAssets;
        uint256 repayGracePeriod;
        mapping(address => SourceTargetUints) accountAssets;
        bytes32 borrowingAssetPythId;
        mapping(bytes32 => bool) consumedMessages;
        InterestRateModel interestRateModel;
        address owner;
    }
}

contract CrossChainBorrowLendState {
    CrossChainBorrowLendStorage.State state;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

enum DepositType {
    None,
    Add,
    Remove,
    RemoveFull
}

struct DepositedBorrowedUints {
    uint256 deposited;
    uint256 borrowed;
}

struct SourceTargetUints {
    DepositedBorrowedUints source;
    DepositedBorrowedUints target;
}

struct MessageHeader {
    uint8 payloadID;
    // address of the sender
    address sender;
    // collateral info
    address collateralAddress; // for verification
    // borrow info
    address borrowAddress; // for verification
}

struct BorrowMessage {
    // payloadID = 1
    MessageHeader header;
    uint256 borrowAmount;
    uint256 totalNormalizedBorrowAmount;
    uint256 interestAccrualIndex;
}

struct RevertBorrowMessage {
    // payloadID = 2
    MessageHeader header;
    uint256 borrowAmount;
    uint256 sourceInterestAccrualIndex;
}

struct RepayMessage {
    // payloadID = 3
    MessageHeader header;
    uint256 repayAmount;
    uint256 targetInterestAccrualIndex;
    uint256 repayTimestamp;
    uint8 paidInFull;
}

struct LiquidationIntentMessage {
    // payloadID = 4
    MessageHeader header;
    // TODO: add necessary variables
}

struct DepositChangeMessage {
    // payloadID = 5
    MessageHeader header;
    DepositType depositType;
    uint256 amount;
}

struct InterestRateModel {
    uint64 ratePrecision;
    uint64 rateIntercept;
    uint64 rateCoefficientA;
    // TODO: add more complexity for example?
    uint64 reserveFactor;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IMockPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint publishTime;
    }

    struct PriceFeed {
        bytes32 id;
        Price price;
        Price emaPrice;
    }

    struct PriceInfo {
        uint256 attestationTime;
        uint256 arrivalTime;
        uint256 arrivalBlock;
        PriceFeed priceFeed;
    }

    function queryPriceFeed(bytes32 id) external view returns (PriceFeed memory priceFeed);
}

// contracts/Messages.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }

    event LogMessagePublished(
        address indexed sender,
        uint64 sequence,
        uint32 nonce,
        bytes payload,
        uint8 consistencyLevel
    );

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM)
        external
        view
        returns (
            VM memory vm,
            bool valid,
            string memory reason
        );

    function chainId() external view returns (uint16);

    function messageFee() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}