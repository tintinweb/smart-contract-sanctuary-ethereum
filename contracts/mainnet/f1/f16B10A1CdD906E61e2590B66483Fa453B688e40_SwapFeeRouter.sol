/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// Sources flattened with hardhat v2.11.1 https://hardhat.org

// File contracts/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

abstract contract Ownable {

    error Unauthorized();
    error ZeroAddress();

    event OwnerSet(address indexed newOwner_);
    event PendingOwnerSet(address indexed pendingOwner_);

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    function setPendingOwner(address pendingOwner_) external onlyOwner {
        _setPendingOwner(pendingOwner_);
    }

    function acceptOwnership() external {
        if (msg.sender != pendingOwner) revert Unauthorized();

        _setPendingOwner(address(0));
        _setOwner(msg.sender);
    }

    function _setOwner(address owner_) internal {
        if (owner_ == address(0)) revert ZeroAddress();

        emit OwnerSet(owner = owner_);
    }

    function _setPendingOwner(address pendingOwner_) internal {
        emit PendingOwnerSet(pendingOwner = pendingOwner_);
    }

}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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


// File contracts/SwapFeeRouter.sol


pragma solidity 0.8.16;

// NOTE: There is no non-arbitrary upper-limit for the `feeBasisPoints`, and setting it above 10_000 just pauses the swap functions.

contract SwapFeeRouter is Ownable {

    error ETHTransferFailed(bytes errorData);
    error FeeBasisPointsNotRespected(uint256 expectedFeeBasisPoints_, uint256 actualFeeBasisPoints_);
    error ContractNotWhitelisted(address callee);
    error RenterAttempted();
    error SwapCallFailed(bytes errorData);

    event ContractAddedToWhitelist(address indexed contract_);
    event ContractRemovedFromWhitelist(address indexed contract_);
    event ETHPulled(address indexed destination_, uint256 amount_);
    event FeeSet(uint256 feeBasisPoints_);
    event TokensPulled(address indexed token_, address indexed destination_, uint256 amount_);

    uint256 internal _locked = 1;

    uint256 public feeBasisPoints;  // 1 = 0.01%, 100 = 1%, 10_000 = 100%

    mapping(address => bool) public isWhitelisted;

    constructor(address owner_, uint256 feeBasisPoints_, address[] memory whitelist_) {
        _setOwner(owner_);
        _setFees(feeBasisPoints_);
        _addToWhitelist(whitelist_);
    }

    modifier noRenter() {
        if (_locked == 2) revert RenterAttempted();

        _locked = 2;

        _;

        _locked = 1;
    }

    modifier feeBasisPointsRespected(uint256 feeBasisPoints_) {
        // Revert if the expected fee is less than the current fee.
        if (feeBasisPoints_ < feeBasisPoints) revert FeeBasisPointsNotRespected(feeBasisPoints_, feeBasisPoints);

        _;
    }

    function swapWithFeesOnInput(
        address inAsset_,
        uint256 swapAmount_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) public noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Pull funds plus fees from caller.
        // NOTE: Assuming `swapCallData_` is correct, fees will remain in this contract.
        // NOTE: Worst case, assuming `swapCallData_` is incorrect/malicious, this contract loses nothing, but gains nothing.
        SafeERC20.safeTransferFrom(IERC20(inAsset_), msg.sender, address(this), getAmountWithFees(swapAmount_, feeBasisPoints));

        // Perform the swap (set allowance, swap, unset allowance).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to correct destination.
        _performSwap(inAsset_, swapAmount_, swapContract_, tokenPuller_, swapCallData_);
    }

    function swapWithFeesOnOutput(
        address inAsset_,
        uint256 swapAmount_,
        address outAsset_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) external noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Track this contract's starting outAsset balance to determine its increase later.
        uint256 startingOutAssetBalance = IERC20(outAsset_).balanceOf(address(this));

        // Pull funds from caller.
        SafeERC20.safeTransferFrom(IERC20(inAsset_), msg.sender, address(this), swapAmount_);

        // Perform the swap (set allowance, swap, unset allowance).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to this contract.
        _performSwap(inAsset_, swapAmount_, swapContract_, tokenPuller_, swapCallData_);

        // Send the amount of outAsset the swap produced, minus fees, to the destination.
        SafeERC20.safeTransfer(
            IERC20(outAsset_),
            msg.sender,
            getAmountWithoutFees(
                IERC20(outAsset_).balanceOf(address(this)) - startingOutAssetBalance,
                feeBasisPoints
            )
        );
    }

    function swapFromEthWithFeesOnInput(
        uint256 feeBasisPoints_,
        address swapContract_,
        bytes calldata swapCallData_
    ) external payable noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Perform the swap (attaching ETH minus fees to call).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to correct destination.
        _performSwap(getAmountWithoutFees(msg.value, feeBasisPoints), swapContract_, swapCallData_);
    }

    function swapFromEthWithFeesOnOutput(
        address outAsset_,
        uint256 feeBasisPoints_,
        address swapContract_,
        bytes calldata swapCallData_
    ) external payable noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Track this contract's starting outAsset balance to determine its increase later.
        uint256 startingOutAssetBalance = IERC20(outAsset_).balanceOf(address(this));

        // Perform the swap (attaching ETH to call).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send outAsset to this contract.
        _performSwap(msg.value, swapContract_, swapCallData_);

        // Send the amount of outAsset the swap produced, minus fees, to the destination.
        SafeERC20.safeTransfer(
            IERC20(outAsset_),
            msg.sender,
            getAmountWithoutFees(
                IERC20(outAsset_).balanceOf(address(this)) - startingOutAssetBalance,
                feeBasisPoints
            )
        );
    }

    function swapToEthWithFeesOnInput(
        address inAsset_,
        uint256 swapAmount_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) external feeBasisPointsRespected(feeBasisPoints_) {
        // NOTE: Ths is functionally the same as `swapWithFeesOnInput` since the output is irrelevant.
        // NOTE: No `noRenter` needed since `swapWithFeesOnInput` will check that.
        swapWithFeesOnInput(inAsset_, swapAmount_, feeBasisPoints_, swapContract_, tokenPuller_, swapCallData_);
    }

    function swapToEthWithFeesOnOutput(
        address inAsset_,
        uint256 swapAmount_,
        uint256 feeBasisPoints_,
        address swapContract_,
        address tokenPuller_,
        bytes calldata swapCallData_
    ) external noRenter feeBasisPointsRespected(feeBasisPoints_) {
        // Track this contract's starting ETH balance to determine its increase later.
        uint256 startingETHBalance = address(this).balance;

        // Pull funds from caller.
        SafeERC20.safeTransferFrom(IERC20(inAsset_), msg.sender, address(this), swapAmount_);

        // Perform the swap (set allowance, swap, unset allowance).
        // NOTE: This assume that the `swapCallData_` instructs the swapContract to send ETH to this contract.
        _performSwap(inAsset_, swapAmount_, swapContract_, tokenPuller_, swapCallData_);

        // Send the amount of ETH the swap produced, minus fees, to the destination, and revert if it fails.
        _transferETH(
            msg.sender,
            getAmountWithoutFees(
                address(this).balance - startingETHBalance,
                feeBasisPoints
            )
        );
    }

    function addToWhitelist(address[] calldata whitelist_) external onlyOwner {
        _addToWhitelist(whitelist_);
    }

    function removeFromWhitelist(address[] calldata whitelist_) external onlyOwner {
        _removeFromWhitelist(whitelist_);
    }

    function setFee(uint256 feeBasisPoints_) external onlyOwner {
        _setFees(feeBasisPoints_);
    }

    function pullToken(address token_, address destination_) public onlyOwner {
        if (destination_ == address(0)) revert ZeroAddress();

        uint256 amount = IERC20(token_).balanceOf(address(this));

        emit TokensPulled(token_, destination_, amount);

        SafeERC20.safeTransfer(IERC20(token_), destination_, amount);
    }

    function pullTokens(address[] calldata tokens_, address destination_) external onlyOwner {
        for (uint256 i; i < tokens_.length; ++i) {
            pullToken(tokens_[i], destination_);
        }
    }

    function pullETH(address destination_) external onlyOwner {
        if (destination_ == address(0)) revert ZeroAddress();

        uint256 amount = address(this).balance;

        emit ETHPulled(destination_, amount);

        _transferETH(destination_, amount);
    }

    function getAmountWithFees(uint256 amountWithoutFees_, uint256 feeBasisPoints_) public pure returns (uint256 amountWithFees_) {
        amountWithFees_ = (amountWithoutFees_ * (10_000 + feeBasisPoints_)) / 10_000;
    }

    function getAmountWithoutFees(uint256 amountWithFees_, uint256 feeBasisPoints_) public pure returns (uint256 amountWithoutFees_) {
        amountWithoutFees_ = (10_000 * amountWithFees_) / (10_000 + feeBasisPoints_);
    }

    function _addToWhitelist(address[] memory whitelist_) internal {
        for (uint256 i; i < whitelist_.length; ++i) {
            address account = whitelist_[i];
            isWhitelisted[whitelist_[i]] = true;
            emit ContractAddedToWhitelist(account);
        }
    }

    function _performSwap(address inAsset_, uint256 swapAmount_, address swapContract_, address tokenPuller_, bytes calldata swapCallData_) internal {
        // Prevent calling contracts that are not whitelisted.
        if (!isWhitelisted[swapContract_]) revert ContractNotWhitelisted(swapContract_);

        // Approve the contract that will pull inAsset.
        IERC20(inAsset_).approve(tokenPuller_, swapAmount_);

        // Call the swap contract as defined by `swapCallData_`, and revert if it fails.
        ( bool success, bytes memory errorData ) = swapContract_.call(swapCallData_);
        if (!success) revert SwapCallFailed(errorData);

        // Un-approve the contract that pulled inAsset.
        // NOTE: This is important to prevent exploits that rely on allowances to arbitrary swapContracts to be non-zero after swap calls.
        IERC20(inAsset_).approve(tokenPuller_, 0);
    }

    function _performSwap(uint256 swapAmount_, address swapContract_, bytes calldata swapCallData_) internal {
        // Prevent calling contracts that are not whitelisted.
        if (!isWhitelisted[swapContract_]) revert ContractNotWhitelisted(swapContract_);

        // Call the swap contract as defined by `swapCallData_`, and revert if it fails.
        ( bool success, bytes memory errorData ) = swapContract_.call{ value: swapAmount_ }(swapCallData_);
        if (!success) revert SwapCallFailed(errorData);
    }

    function _removeFromWhitelist(address[] memory whitelist_) internal {
        for (uint256 i; i < whitelist_.length; ++i) {
            address account = whitelist_[i];
            isWhitelisted[whitelist_[i]] = false;
            emit ContractRemovedFromWhitelist(account);
        }
    }

    function _setFees(uint256 feeBasisPoints_) internal {
        emit FeeSet(feeBasisPoints = feeBasisPoints_);
    }

    function _transferETH(address destination_, uint256 amount_) internal {
        // NOTE: callers of this function are validating `destination_` to not be zero.
        ( bool success, bytes memory errorData ) = destination_.call{ value: amount_ }("");
        if (!success) revert ETHTransferFailed(errorData);
    }

    receive() external payable {}

}