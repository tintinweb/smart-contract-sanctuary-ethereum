/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.2;
 
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor ()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers owanership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}
interface IERCOwnable {
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

    function owner() external view returns (address);
}

interface IwrappedToken {
    function transferOwnership(address newOwner) external;

    function owner() external returns (address);

    function burn(uint256 amount) external;

    function mint(address account, uint256 amount) external;
}

interface IRegistery {
    struct Transaction {
        uint256 chainId;
        address assetAddress;
        uint256 amount;
        address receiver;
        uint256 nounce;
        bool isCompleted;
    }

    function getUserNonce(address user) external returns (uint256);

    function isSendTransaction(bytes32 transactionID) external returns (bool);

    function isClaimTransaction(bytes32 transactionID) external returns (bool);

    function isMintTransaction(bytes32 transactionID) external returns (bool);

    function isburnTransactio(bytes32 transactionID) external returns (bool);

    function transactionValidated(bytes32 transactionID)
        external
        returns (bool);

    function assetChainBalance(address asset, uint256 chainid)
        external
        returns (uint256);

    function sendTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function claimTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function burnTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function mintTransactions(bytes32 transactionID)
        external
        returns (Transaction memory);

    function completeSendTransaction(bytes32 transactionID) external;

    function completeBurnTransaction(bytes32 transactionID) external;

    function completeMintTransaction(bytes32 transactionID) external;

    function completeClaimTransaction(bytes32 transactionID) external;

    function transferOwnership(address newOwner) external;

    function registerTransaction(
        uint256 chainTo,
        address assetAddress,
        uint256 amount,
        address receiver,
        uint8 _transactionType
    ) external returns (bytes32 transactionID, uint256 _nounce);
}

interface Isettings {
    function networkFee(uint256 chainId) external view returns (uint256);

    function minValidations() external view returns (uint256);

    function isNetworkSupportedChain(uint256 chainID)
        external
        view
        returns (bool);

    function feeRemitance() external view returns (address);

    function railRegistrationFee() external view returns (uint256);

    function railOwnerFeeShare() external view returns (uint256);

    function onlyOwnableRail() external view returns (bool);

    function updatableAssetState() external view returns (bool);

    function minWithdrawableFee() external view returns (uint256);

    function brgToken() external view returns (address);

    function getNetworkSupportedChains()
        external
        view
        returns (uint256[] memory);

    function baseFeePercentage() external view returns (uint256);

    function networkGas(uint256 chainID) external view returns (uint256);

    function gasBank() external view returns (address);

    function baseFeeEnable() external view returns (bool);

    function maxFeeThreshold() external view returns (uint256);

    function approvedToAdd(address token, address user)
        external
        view
        returns (bool);
}

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
interface IbridgeMigrator {
    function isDirectSwap(address assetAddress, uint256 chainID)
        external
        returns (bool);

    function registerNativeMigration(
        address assetAddress,
        uint256[2] memory limits,
        uint256 collectedFees,
        bool ownedRail,
        address manager,
        address feeRemitance,
        uint256[3] memory balances,
        bool active,
        uint256[] memory supportedChains
    ) external payable;

    function registerForiegnMigration(
        address foriegnAddress,
        uint256 chainID,
        uint256 minAmount,
        uint256 maxAmount,
        bool ownedRail,
        address manager,
        address feeAddress,
        uint256 _collectedFees,
        bool directSwap,
        address wrappedAddress
    ) external;
}

interface IController {
    function isAdmin(address account) external view returns (bool);

    function isRegistrar(address account) external view returns (bool);

    function isOracle(address account) external view returns (bool);

    function isValidator(address account) external view returns (bool);

    function owner() external view returns (address);

    function validatorsCount() external view returns (uint256);

    function settings() external view returns (address);

    function deployer() external view returns (address);

    function feeController() external view returns (address);
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
// controller :  0xF9062a513DbDc8819A941cF5Bc4B7674c2Fb1eD4
// settings :  0xe1Cc3393dBF6646Ad2D41c8d09DE05130953591A
// deployer :  0x6BaA7bAEF208954bC4859B36238E4CAA985252A8
// feeController :  0x355DeD867d21210e88f5B40be7239c4f1E47CC1c
// registry :  0xa0C8Fe6332Ac6477D802800553f4b5dC139c9316
// pool :  0x5339834438B780566155e2608aBCB85f4c931b38
// bridge :  0x4f45a410C38FF07A29b0a518b885123Ee5D103b8
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
interface Ideployer {
    function deployerWrappedAsset(
        string calldata _name,
        string calldata _symbol,
        uint256 lossless
    ) external returns (address);
}

interface IfeeController {
    function getBridgeFee(address sender, address assetAddress)
        external
        view
        returns (uint256);
}

interface IbridgePool {
    function validPool(address poolAddress) external view returns (bool);

    function topUp(address poolAddress, uint256 amount) external payable;

    function sendOut(address poolAddress, address receiver, uint256 amount)
        external;

    function createPool(address poolAddress, uint256 debtThreshold) external;

    function deposit(address poolAddress, uint256 amount) external payable;
}

contract Bridge is Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    struct asset {
        address tokenAddress;
        uint256 minAmount;
        uint256 maxAmount;
        uint256 ownerFeeBalance;
        uint256 networkFeeBalance;
        uint256 collectedFees;
        bool ownedRail;
        address manager;
        address feeRemitance;
        bool isSet;
    }
    struct directForiegnAsset {
        address foriegnAddress;
        address nativeAddress;
        uint256 chainID;
        bool isSet;
    }

    IController public controller;
    Isettings public settings;
    IRegistery public registry;
    IbridgePool public bridgePool;
    bool public paused;

    mapping(address => asset) public nativeAssets;
    mapping(address => bool) public isActiveNativeAsset;
    mapping(address => uint256[]) assetSupportedChainIds;
    mapping(address => mapping(uint256 => bool)) public isAssetSupportedChain;
    mapping(address => uint256) public foriegnAssetChainID;
    mapping(address => asset) public foriegnAssets;
    mapping(uint256 => directForiegnAsset) public directForiegnAssets;
    mapping(address => mapping(uint256 => address)) public wrappedForiegnPair;
    mapping(address => address) public foriegnPair;
    mapping(address => mapping(uint256 => bool)) public hasWrappedForiegnPair;
    mapping(address => mapping(uint256 => bool)) public isDirectSwap;

    uint256 public totalGas;
    uint256 public chainId; // current chain id
    //    uint256 public immutable chainId; // current chain id
    address public deployer;
    address public feeController;
    bool activeMigration;
    uint256 migrationInitiationTime;
    uint256 constant migrationDelay = 2 days;
    address newBridge;
    address migrator;

    uint256 directForiegnCount;
    //    address public immutable migrator;
    uint256 fMigrationAt;
    uint256 fDirectSwapMigrationAt;
    uint256 nMigrationAt;
    uint256 public constant standardDecimals = 18;
    address[] public foriegnAssetsList;
    address[] public nativeAssetsList;

    event MigrationInitiated(address indexed newBridge);
    event RegisterredNativeMigration(address indexed assetAddress);
    event RegisteredForiegnMigration(
        address indexed foriegnAddress,
        uint256 indexed chainID,
        address indexed wrappedAddress
    );
    event MigratedAsset(address indexed assetAddress, bool isNativeAsset);
    event ForiegnAssetAdded(
        address indexed foriegnAddress,
        uint256 indexed chainID,
        address indexed wrappedAddress
    );
    event UpdatedAddresses(
        address indexed settings,
        address indexed feeController,
        address indexed deployer
    );
    event AssetUpdated(
        address indexed assetAddress,
        address indexed manager,
        address indexed feeRemitance,
        uint256 min,
        uint256 max,
        bool native
    );
    event MigrationCompleted(address indexed newBridge);
    event BridgePauseStatusChanged(bool status);
    //    event NativeAssetStatusChanged(address indexed assetAddress , bool status);

    event SendTransaction(
        bytes32 transactionID,
        uint256 chainID,
        address indexed assetAddress,
        uint256 sendAmount,
        address indexed receiver,
        uint256 nounce,
        address indexed sender
    );
    event BurnTransaction(
        bytes32 transactionID,
        uint256 chainID,
        address indexed assetAddress,
        uint256 sendAmount,
        address indexed receiver,
        uint256 nounce,
        address indexed sender
    );
    event RailAdded(
        address indexed assetAddress,
        uint256 minAmount,
        uint256 maxAmount,
        uint256[] supportedChains,
        address[] foriegnAddresses,
        bool directSwap,
        address registrar,
        bool ownedRail,
        address indexed manager,
        address feeRemitance,
        uint256 deployWith
    );

    constructor(
        address _controllers,
        address _settings,
        address _registry,
        address _deployer,
        address _feeController,
        address _bridgePool,
        address _migrator
    ) {
        noneZeroAddress(_controllers);
        noneZeroAddress(_settings);
        noneZeroAddress(_registry);
        noneZeroAddress(_deployer);
        noneZeroAddress(_feeController);
        noneZeroAddress(_bridgePool);
        settings = Isettings(_settings);
        controller = IController(_controllers);
        registry = IRegistery(_registry);
        migrator = _migrator;
        deployer = _deployer;
        feeController = _feeController;
        bridgePool = IbridgePool(_bridgePool);
        uint256 id;
        assembly {
            id := chainid()
        }
        chainId = id;
    }

    function pauseBrigde() external {
        isOwner();
        paused = !paused;
        //    emit BridgePauseStatusChanged(paused);
    }

    function updateAddresses(
        address _settings,
        address _feeController,
        address _deployer
    ) external {
        isOwner();
        noneZeroAddress(_settings);
        noneZeroAddress(_feeController);
        noneZeroAddress(_deployer);
        emit UpdatedAddresses(_settings, _feeController, _deployer);
        settings = Isettings(_settings);
        feeController = _feeController;
        deployer = _deployer;
    }

    function activeNativeAsset(address assetAddress, bool activate) public {
        //    require(nativeAssets[assetAddress].isSet , "I_A");
        require(
            nativeAssets[assetAddress].isSet &&
                (controller.isAdmin(_msgSender()) ||
                    controller.isRegistrar(_msgSender()) ||
                    isAssetManager(assetAddress, true)),
            "U_A"
        );
        //    emit NativeAssetStatusChanged(assetAddress , activate);
        isActiveNativeAsset[assetAddress] = activate;
    }

    function updateAsset(
        address assetAddress,
        address manager,
        address _feeRemitance,
        uint256 min,
        uint256 max
    ) external {
        notPaused();
        noneZeroAddress(manager);
        noneZeroAddress(_feeRemitance);
        require(
            (foriegnAssets[assetAddress].isSet ||
                nativeAssets[assetAddress].isSet) && max > min,
            "I_A"
        );
        bool native;
        if (isAssetManager(assetAddress, true)) {
            native = true;
        } else if (isAssetManager(assetAddress, false)) {
            native = false;
        } else {
            isOwner();
            if (foriegnAssets[assetAddress].isSet) native = false;
            else if (nativeAssets[assetAddress].isSet) native = true;
            else require(false, "U_A");
        }

        if (native) {
            nativeAssets[assetAddress].manager = manager;
            nativeAssets[assetAddress].feeRemitance = _feeRemitance;
            nativeAssets[assetAddress].minAmount = min;
            nativeAssets[assetAddress].maxAmount = max;
        } else {
            foriegnAssets[assetAddress].manager = manager;
            foriegnAssets[assetAddress].feeRemitance = _feeRemitance;
            foriegnAssets[assetAddress].minAmount = min;
            foriegnAssets[assetAddress].maxAmount = max;
        }

        AssetUpdated(assetAddress, manager, _feeRemitance, min, max, native);
    }

    function registerRail(
        address assetAddress,
        uint256 minAmount,
        uint256 maxAmount,
        uint256[] calldata supportedChains,
        address[] calldata foriegnAddresses,
        bool directSwap,
        address feeAccount,
        address manager,
        uint256 deployWith
    ) external {
        notPaused();
        bool ownedRail;
        //   require(maxAmount > minAmount  && supportedChains.length == foriegnAddresses.length, "AL_E");
        if (controller.isAdmin(msg.sender)) {
            if (manager != address(0) && feeAccount != address(0)) {
                ownedRail = true;
            }
        } else {
            ownedRail = true;
            if (settings.onlyOwnableRail()) {
                if (assetAddress == address(0)) {
                    require(
                        settings.approvedToAdd(assetAddress, msg.sender),
                        "U_A"
                    );
                } else {
                    require(
                        _msgSender() == IERCOwnable(assetAddress).owner() ||
                            settings.approvedToAdd(assetAddress, msg.sender),
                        "U_A"
                    );
                }
            }
            IERC20 token = IERC20(settings.brgToken());
            token.safeTransferFrom(
                _msgSender(),
                settings.feeRemitance(),
                supportedChains.length * settings.railRegistrationFee()
            );
        }

        _registerRail(
            assetAddress,
            supportedChains,
            directSwap,
            minAmount,
            maxAmount,
            ownedRail,
            feeAccount,
            manager,
            false
        );
        emit RailAdded(
            assetAddress,
            minAmount,
            maxAmount,
            supportedChains,
            foriegnAddresses,
            directSwap,
            _msgSender(),
            ownedRail,
            manager,
            feeAccount,
            deployWith
        );
    }

    function _registerRail(
        address assetAddress,
        uint256[] memory supportedChains,
        bool directSwap,
        uint256 minAmount,
        uint256 maxAmount,
        bool ownedRail,
        address feeAccount,
        address manager,
        bool migration
    ) internal {
        asset storage newNativeAsset = nativeAssets[assetAddress];
        if (!newNativeAsset.isSet) {
            newNativeAsset.tokenAddress = assetAddress;
            newNativeAsset.minAmount = minAmount;
            newNativeAsset.maxAmount = maxAmount;
            if (ownedRail) {
                if (feeAccount != address(0) && manager != address(0)) {
                    newNativeAsset.ownedRail = true;
                    newNativeAsset.feeRemitance = feeAccount;
                    newNativeAsset.manager = manager;
                }
            }
            newNativeAsset.isSet = true;
            isActiveNativeAsset[assetAddress] = false;
            nativeAssetsList.push(assetAddress);
        }
        if (directSwap && !bridgePool.validPool(assetAddress)) {
            bridgePool.createPool(assetAddress, maxAmount);
        }
        uint256 chainLenght = supportedChains.length;
        for (uint256 index; index < chainLenght; index++) {
            if (settings.isNetworkSupportedChain(supportedChains[index])) {
                if (
                    !isAssetSupportedChain[assetAddress][supportedChains[index]]
                ) {
                    isAssetSupportedChain[assetAddress][
                        supportedChains[index]
                    ] = true;
                    assetSupportedChainIds[assetAddress].push(
                        supportedChains[index]
                    );
                    if (migration) {
                        if (
                            IbridgeMigrator(migrator).isDirectSwap(
                                assetAddress,
                                supportedChains[index]
                            )
                        ) {
                            isDirectSwap[assetAddress][
                                supportedChains[index]
                            ] = true;
                            
                        }
                    } else {
                        if (directSwap) {
                            isDirectSwap[assetAddress][
                                supportedChains[index]
                            ] = true;
                        }
                    }
                }
            }
        }
    }

    function addForiegnAsset(
        address foriegnAddress,
        uint256 chainID,
        uint256[] calldata range,
        string[] calldata assetMeta,
        bool OwnedRail,
        address manager,
        address feeAddress,
        uint256 deployWith,
        bool directSwap,
        address nativeAddress
    ) external {
        require(
            controller.isAdmin(_msgSender()) ||
                controller.isRegistrar(_msgSender()),
            "U_A_r"
        );
        require(
            settings.isNetworkSupportedChain(chainID) &&
                !hasWrappedForiegnPair[foriegnAddress][chainID] &&
                range.length == 2 &&
                assetMeta.length == 2,
            "registered"
        );

        address wrappedAddress;
        if (directSwap) {
            wrappedAddress = nativeAddress;
            isDirectSwap[foriegnAddress][chainID] = true;
            directForiegnAssets[directForiegnCount] = directForiegnAsset(
                foriegnAddress,
                wrappedAddress,
                chainID,
                true
            );
            directForiegnCount++;
        } else {
            wrappedAddress = Ideployer(deployer).deployerWrappedAsset(
                assetMeta[0],
                assetMeta[1],
                deployWith
            );
            foriegnAssets[wrappedAddress] = asset(
                wrappedAddress,
                range[0],
                range[1],
                0,
                0,
                0,
                OwnedRail,
                manager,
                feeAddress,
                true
            );

            foriegnAssetChainID[wrappedAddress] = chainID;
            foriegnPair[wrappedAddress] = foriegnAddress;
            foriegnAssetsList.push(wrappedAddress);
        }

        _registerForiegn(foriegnAddress, chainID, wrappedAddress);
    }

    function _registerForiegn(
        address foriegnAddress,
        uint256 chainID,
        address wrappedAddress
    ) internal {
        wrappedForiegnPair[foriegnAddress][chainID] = wrappedAddress;
        hasWrappedForiegnPair[foriegnAddress][chainID] = true;
        emit ForiegnAssetAdded(foriegnAddress, chainID, wrappedAddress);
    }

    function getAssetDecimals(address assetAddress)
        internal
        view
        returns (uint256 decimals)
    {
        if (assetAddress == address(0)) {
            decimals = standardDecimals;
        } else {
            decimals = IERCOwnable(assetAddress).decimals();
        }
    }

    function standaredize(uint256 amount, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        return amount * (10**(standardDecimals - decimals));
    }

    function convertToAssetDecimals(uint256 amount, uint256 decimals)
        internal
        pure
        returns (uint256)
    {
        return amount / (10**(standardDecimals - decimals));
    }

    function send(
        uint256 chainTo,
        address assetAddress,
        uint256 amount,
        address receiver
    ) external payable nonReentrant returns (bytes32 transactionID) {
        notPaused();
        //    require(, "C_E");
        require(
            isActiveNativeAsset[assetAddress] &&
                isAssetSupportedChain[assetAddress][chainTo],
            "AL_E"
        );
        noneZeroAddress(receiver);
        (bool success, uint256 recievedValue) = processedPayment(
            assetAddress,
            chainTo,
            amount
        );
        require(
            success &&
            recievedValue > 0 &&
            recievedValue >= nativeAssets[assetAddress].minAmount &&
            recievedValue <= nativeAssets[assetAddress].maxAmount,
            "I_F"
        );

        recievedValue = deductFees(assetAddress, recievedValue, true);
        if (isDirectSwap[assetAddress][chainTo]) {
            if (assetAddress == address(0)) {
                bridgePool.topUp{value: recievedValue}(
                    assetAddress,
                    recievedValue
                );
            } else {
                IERC20(assetAddress).approve(
                    address(bridgePool),
                    recievedValue
                );
                bridgePool.topUp(assetAddress, recievedValue);
            }
        }

        recievedValue = standaredize(
            recievedValue,
            getAssetDecimals(assetAddress)
        );
        uint256 nounce;
        (transactionID, nounce) = registry.registerTransaction(
            chainTo,
            assetAddress,
            recievedValue,
            receiver,
            0
        );

        emit SendTransaction(
            transactionID,
            chainTo,
            assetAddress,
            recievedValue,
            receiver,
            nounce,
            msg.sender
        );
    }

    function burn(address assetAddress, uint256 amount, address receiver)
        external
        payable
        nonReentrant
        returns (bytes32 transactionID)
    {
        notPaused();
        uint256 chainTo = foriegnAssetChainID[assetAddress];
        require(foriegnAssets[assetAddress].isSet, "I_A");

        noneZeroAddress(receiver);
        (bool success, uint256 recievedValue) = processedPayment(
            assetAddress,
            chainTo,
            amount
        );
        require(
            success &&
                recievedValue >= foriegnAssets[assetAddress].minAmount &&
                recievedValue <= foriegnAssets[assetAddress].maxAmount,
            "I_F"
        );
        recievedValue = deductFees(assetAddress, recievedValue, false);
        IwrappedToken(assetAddress).burn(recievedValue);
        address _foriegnAsset = foriegnPair[assetAddress];
        recievedValue = standaredize(
            recievedValue,
            getAssetDecimals(assetAddress)
        );
        uint256 nounce;
        (transactionID, nounce) = registry.registerTransaction(
            chainTo,
            _foriegnAsset,
            recievedValue,
            receiver,
            1
        );

        emit BurnTransaction(
            transactionID,
            chainTo,
            _foriegnAsset,
            recievedValue,
            receiver,
            nounce,
            msg.sender
        );
    }

    function mint(bytes32 mintID) public nonReentrant {
        notPaused();
        //    require(, "MI_E");
        IRegistery.Transaction memory transaction = registry.mintTransactions(
            mintID
        );
        require(
            registry.isMintTransaction(mintID) &&
                !transaction.isCompleted &&
                registry.transactionValidated(mintID),
            "M"
        );
        uint256 amount = convertToAssetDecimals(
            transaction.amount,
            getAssetDecimals(transaction.assetAddress)
        );
        if (isDirectSwap[transaction.assetAddress][transaction.chainId]) {
            bridgePool.sendOut(
                transaction.assetAddress,
                transaction.receiver,
                amount
            );
        } else {
            IwrappedToken(transaction.assetAddress).mint(
                transaction.receiver,
                amount
            );
        }

        registry.completeMintTransaction(mintID);
    }

    function claim(bytes32 claimID) public nonReentrant {
        notPaused();
        //    require( , "CI_E");
        IRegistery.Transaction memory transaction = registry.claimTransactions(
            claimID
        );
        uint256 amount = convertToAssetDecimals(
            transaction.amount,
            getAssetDecimals(transaction.assetAddress)
        );
        require(
            registry.isClaimTransaction(claimID) &&
                registry.assetChainBalance(
                    transaction.assetAddress,
                    transaction.chainId
                ) >=
                amount &&
                !transaction.isCompleted &&
                registry.transactionValidated(claimID),
            "AL_E"
        );

        payoutUser(
            payable(transaction.receiver),
            transaction.assetAddress,
            amount
        );
        registry.completeClaimTransaction(claimID);
    }

    function payoutUser(
        address payable recipient,
        address _paymentMethod,
        uint256 amount
    ) private {
        noneZeroAddress(recipient);
        if (_paymentMethod == address(0)) {
            recipient.transfer(amount);
        } else {
            IERC20 currentPaymentMethod = IERC20(_paymentMethod);
            require(currentPaymentMethod.transfer(recipient, amount), "I_F");
        }
    }

    // internal fxn used to process incoming payments
    function processedPayment(
        address assetAddress,
        uint256 chainID,
        uint256 amount
    ) internal returns (bool, uint256) {
        uint256 gas = settings.networkGas(chainID);
        if (assetAddress == address(0)) {
            if (msg.value >= amount + gas ) {
                totalGas += gas;
                if (gas > 0)
                    payoutUser(
                        payable(settings.gasBank()),
                        address(0),
                        gas
                    );
                return (true, msg.value - gas);
            } else {
                return (false, 0);
            }
        } else {
            IERC20 token = IERC20(assetAddress);
            if (
                token.allowance(_msgSender(), address(this)) >= amount &&
                (msg.value >= gas)
            ) {
                totalGas += msg.value;
                if (gas > 0)
                    payoutUser(
                        payable(settings.gasBank()),
                        address(0),
                        msg.value
                    );
                uint256 balanceBefore = token.balanceOf(address(this));
                token.safeTransferFrom(_msgSender(), address(this), amount);
                uint256 balanceAfter = token.balanceOf(address(this));
                return (true, balanceAfter - balanceBefore);
            } else {
                return (false, 0);
            }
        }
    }

    // internal fxn for deducting and remitting fees after a sale
    function deductFees(address assetAddress, uint256 amount, bool native)
        private
        returns (uint256)
    {
        asset storage currentasset;
        if (native) currentasset = nativeAssets[assetAddress];
        else currentasset = foriegnAssets[assetAddress];

        require(currentasset.isSet, "I_A");
        if (!settings.baseFeeEnable()) {
            return amount;
        }
        // uint256 fees_to_deduct = settings.networkFee(chainID);

        uint256 feePercentage = IfeeController(feeController).getBridgeFee(
            msg.sender,
            assetAddress
        );

        if (feePercentage == 0) {
            return amount;
        }

        if (feePercentage > settings.maxFeeThreshold()) {
            feePercentage = settings.maxFeeThreshold();
        }

        uint256 baseFee = (amount * feePercentage) / 10000;
        if (currentasset.ownedRail) {
            uint256 ownershare = (baseFee * settings.railOwnerFeeShare()) / 100;
            uint256 networkshare = baseFee - ownershare;
            currentasset.collectedFees += baseFee;
            currentasset.ownerFeeBalance += ownershare;
            currentasset.networkFeeBalance += networkshare;
        } else {
            currentasset.collectedFees += baseFee;
            currentasset.networkFeeBalance += baseFee;
        }

        return amount - baseFee;
    }

    function remitFees(address assetAddress, bool native) public {
        asset storage currentasset;
        uint256 amount;
        if (native) currentasset = nativeAssets[assetAddress];
        else currentasset = foriegnAssets[assetAddress];

        if (currentasset.ownedRail) {
            if (currentasset.ownerFeeBalance > 0) {
                amount = currentasset.ownerFeeBalance;
                currentasset.ownerFeeBalance = 0;
                payoutUser(
                    payable(currentasset.feeRemitance),
                    assetAddress,
                    amount
                );
            }
        }
        if (currentasset.networkFeeBalance > 0) {
            amount = currentasset.networkFeeBalance;
            currentasset.networkFeeBalance = 0;
            payoutUser(payable(settings.feeRemitance()), assetAddress, amount);
        }
    }

    function initiateMigration(address _newbridge) external {
        notPaused();
        isOwner();
        noneZeroAddress(_newbridge);
        require(!activeMigration, "P_M");
        newBridge = _newbridge;
        activeMigration = true;
        paused = true;
        migrationInitiationTime = block.timestamp;
        emit MigrationInitiated(_newbridge);
    }

    function completeMigration() external {
        isOwner();

        require(
            activeMigration && fMigrationAt >= foriegnAssetsList.length,
            "P_M"
        );
        registry.transferOwnership(newBridge);
        activeMigration = false;
        emit MigrationCompleted(newBridge);
    }

    function migrateForiegn(uint256 limit, bool directSwap) external {
        isOwner();
        require(
            activeMigration &&
                block.timestamp - migrationInitiationTime >= migrationDelay,
            "N_Y_T"
        );
        uint256 start;
        uint256 migrationAmount;
        if (directSwap) {
            require(fDirectSwapMigrationAt < directForiegnCount, "completed");
            start = fDirectSwapMigrationAt;

            if (limit + fDirectSwapMigrationAt < directForiegnCount)
                migrationAmount = limit;
            else migrationAmount = directForiegnCount - fDirectSwapMigrationAt;

            for (uint256 i; i < migrationAmount; i++) {
                directForiegnAsset
                    storage directSwapAsset = directForiegnAssets[start + i];
                if (directSwapAsset.isSet) {
                    IbridgeMigrator(newBridge).registerForiegnMigration(
                        directSwapAsset.foriegnAddress,
                        directSwapAsset.chainID,
                        0,
                        0,
                        false,
                        address(0),
                        address(0),
                        0,
                        true,
                        directSwapAsset.nativeAddress
                    );
                    fDirectSwapMigrationAt = fDirectSwapMigrationAt + 1;
                    // emit MigratedAsset(directSwapAsset.foriegnAddress , false);
                }
            }
        } else {
            require(fMigrationAt < foriegnAssetsList.length, "completed");
            start = fMigrationAt;

            if (limit + fMigrationAt < foriegnAssetsList.length)
                migrationAmount = limit;
            else migrationAmount = foriegnAssetsList.length - fMigrationAt;

            for (uint256 i; i < migrationAmount; i++) {
                address assetAddress = foriegnAssetsList[start + i];
                remitFees(assetAddress, false);
                asset memory foriegnAsset = foriegnAssets[assetAddress];

                IwrappedToken(assetAddress).transferOwnership(newBridge);
                IbridgeMigrator(newBridge).registerForiegnMigration(
                    foriegnAsset.tokenAddress,
                    foriegnAssetChainID[foriegnAsset.tokenAddress],
                    foriegnAsset.minAmount,
                    foriegnAsset.maxAmount,
                    foriegnAsset.ownedRail,
                    foriegnAsset.manager,
                    foriegnAsset.feeRemitance,
                    foriegnAsset.collectedFees,
                    false,
                    foriegnPair[foriegnAsset.tokenAddress]
                );

                fMigrationAt = fMigrationAt + 1;
                // emit MigratedAsset(assetAddress , false);
            }
        }
    }

    function migrateNative(uint256 limit) external {
        isOwner();
        require(
            activeMigration &&
                block.timestamp - migrationInitiationTime >= migrationDelay,
            "N_Y_T"
        );
        uint256 migrationAmount;
        uint256 start;
        if (nMigrationAt == 0) start = nMigrationAt;
        else start = nMigrationAt + 1;
        if (limit + nativeAssetsList.length < nMigrationAt)
            migrationAmount = limit;
        else migrationAmount = nativeAssetsList.length - nMigrationAt;

        for (uint256 i; i < migrationAmount; i++) {
            _migrateNative(nativeAssetsList[start + i]);
        }

        // emit MigratedAsset(assetAddress , true);
    }

    function _migrateNative(address assetAddress) internal {
        asset memory nativeAsset = nativeAssets[assetAddress];
        uint256 balance;
        if (assetAddress == address(0)) {
            balance = address(this).balance;
            IbridgeMigrator(newBridge).registerNativeMigration{value: balance}(
                assetAddress,
                [nativeAsset.minAmount, nativeAsset.maxAmount],
                nativeAsset.collectedFees,
                nativeAsset.ownedRail,
                nativeAsset.manager,
                nativeAsset.feeRemitance,
                [
                    nativeAsset.ownerFeeBalance,
                    balance,
                    nativeAsset.networkFeeBalance
                ],
                isActiveNativeAsset[assetAddress],
                assetSupportedChainIds[assetAddress]
            );
        } else {
            balance = IERC20(assetAddress).balanceOf(address(this));
            IERC20(assetAddress).safeApprove(newBridge, balance);
            IbridgeMigrator(newBridge).registerNativeMigration(
                assetAddress,
                [nativeAsset.minAmount, nativeAsset.maxAmount],
                nativeAsset.collectedFees,
                nativeAsset.ownedRail,
                nativeAsset.manager,
                nativeAsset.feeRemitance,
                [
                    nativeAsset.ownerFeeBalance,
                    balance,
                    nativeAsset.networkFeeBalance
                ],
                isActiveNativeAsset[assetAddress],
                assetSupportedChainIds[assetAddress]
            );
        }
        nMigrationAt = nMigrationAt + 1;
    }

    function registerNativeMigration(
        address assetAddress,
        uint256[2] memory limits,
        uint256 collectedFees,
        bool ownedRail,
        address manager,
        address feeRemitance,
        uint256[3] memory balances,
        bool active,
        uint256[] memory supportedChains
    ) external payable {
        require(
            !nativeAssets[assetAddress].isSet && _msgSender() == migrator,
            "U_A"
        );

        (bool success, uint256 amountRecieved) = processedPayment(
            assetAddress,
            0,
            balances[1]
        );
        require(success && amountRecieved >= balances[1], "I_F");
        _registerRail(
            assetAddress,
            supportedChains,
            false,
            limits[0],
            limits[1],
            ownedRail,
            feeRemitance,
            manager,
            true
        );
        nativeAssets[assetAddress].ownerFeeBalance = balances[0];
        nativeAssets[assetAddress].networkFeeBalance = balances[2];
        nativeAssets[assetAddress].collectedFees = collectedFees;

        if (active) {
            isActiveNativeAsset[assetAddress] = true;
        }
        //  emit RegisterredNativeMigration(assetAddress);
    }

    function registerForiegnMigration(
        address wrappedAddress,
        uint256 chainID,
        uint256 minAmount,
        uint256 maxAmount,
        bool ownedRail,
        address manager,
        address feeAddress,
        uint256 _collectedFees,
        bool directSwap,
        address foriegnAddress
    ) external {
        // require(settings.isNetworkSupportedChain(chainID) && !hasWrappedForiegnPair[foriegnAddress][chainID] , "A_R");
        require(
            settings.isNetworkSupportedChain(chainID) &&
                !hasWrappedForiegnPair[foriegnAddress][chainID] &&
                _msgSender() == migrator,
            "U_A"
        );

        if (directSwap) {
            isDirectSwap[wrappedAddress][chainID] = true;
            directForiegnAssets[directForiegnCount] = directForiegnAsset(
                wrappedAddress,
                foriegnAddress,
                chainID,
                true
            );
            directForiegnCount++;
        } else {
            foriegnAssets[wrappedAddress] = asset(
                wrappedAddress,
                minAmount,
                maxAmount,
                0,
                0,
                _collectedFees,
                ownedRail,
                manager,
                feeAddress,
                true
            );
            foriegnAssetChainID[wrappedAddress] = chainID;
            foriegnPair[wrappedAddress] = foriegnAddress;
            foriegnAssetsList.push(wrappedAddress);
        }

        _registerForiegn(foriegnAddress, chainID, wrappedAddress);

        // emit RegisteredForiegnMigration(foriegnAddress , chainID, wrappedAddress);
    }

    function assetLimits(address assetAddress, bool native)
        external
        view
        returns (uint256, uint256)
    {
        if (native)
            return (
                nativeAssets[assetAddress].minAmount,
                nativeAssets[assetAddress].maxAmount
            );
        else
            return (
                foriegnAssets[assetAddress].minAmount,
                foriegnAssets[assetAddress].maxAmount
            );
    }

    function getAssetSupportedChainIds(address assetAddress)
        external
        view
        returns (uint256[] memory)
    {
        return assetSupportedChainIds[assetAddress];
    }

    function getAssetCount() external view returns (uint256, uint256, uint256) {
        return (
            nativeAssetsList.length,
            foriegnAssetsList.length,
            directForiegnCount
        );
    }

    function notPaused() private view returns (bool) {
        require(!paused, "B_P");
        return true;
    }

    function noneZeroAddress(address _address) private pure returns (bool) {
        require(_address != address(0), "A_z");
        return true;
    }

    function onlyAdmin() private view returns (bool) {
        require(
            controller.isAdmin(msg.sender) || msg.sender == controller.owner(),
            "U_A"
        );
        return true;
    }

    function isOwner() internal view returns (bool) {
        require(controller.owner() == _msgSender(), "U_A");
        return true;
    }

    function isAssetManager(address assetAddress, bool native)
        internal
        view
        returns (bool)
    {
        bool isManager;
        if (native) {
            if (
                nativeAssets[assetAddress].manager == _msgSender() &&
                nativeAssets[assetAddress].manager != address(0)
            ) {
                isManager = true;
            }
        } else {
            if (
                foriegnAssets[assetAddress].manager == _msgSender() &&
                foriegnAssets[assetAddress].manager != address(0)
            ) {
                isManager = true;
            }
        }
        return isManager;
    }

    function bridgeData()
        external
        view
        returns (
            address,
            address,
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            migrator,
            newBridge,
            activeMigration,
            migrationInitiationTime,
            migrationDelay,
            fMigrationAt,
            fDirectSwapMigrationAt,
            nMigrationAt,
            feeController
        );
    }
}