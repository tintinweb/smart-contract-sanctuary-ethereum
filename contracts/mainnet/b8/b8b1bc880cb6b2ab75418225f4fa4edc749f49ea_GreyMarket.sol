// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./GreyMarketStorage.sol";
import "./GreyMarketEvent.sol";
import "./GreyMarketData.sol";

/** 
 * @title gm.co
 * @custom:version 1.0
 * @author projectPXN
 * @custom:coauthor bldr
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarket is Ownable, ReentrancyGuard, GreyMarketStorage, GreyMarketEvent {
    using SafeERC20 for IERC20;

    string public constant CONTRACT_NAME = "GreyMarket Contract";
    
    bytes32 public constant DOMAIN_TYPEHASH = 
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    
    bytes32 public constant CREATE_ORDER_TYPEHASH = 
        keccak256(
            "Create(bytes32 id,address buyer,address seller,address paymentToken,uint256 orderType,uint256 amount)"
        );

    bytes32 public constant CLAIM_ORDER_TYPEHASH = 
        keccak256(
            "Claim(bytes32 id,address buyer,address seller,uint256 orderStatus)"
        );
    
    bytes32 public constant WITHDRAW_ORDER_TYPEHASH = 
        keccak256(
            "Withdraw(bytes32 id,address buyer,address seller,uint256 orderStatus)"
        );

    bytes32 public constant RELEASE_DISPUTED_ORDER_TYPEHASH = 
        keccak256(
            "Release(bytes32 id,address buyer,address seller,uint256 orderStatus,address winner)"
        );

    bytes32 public domainSeperator = 
        keccak256(
            abi.encode(
                DOMAIN_TYPEHASH, 
                keccak256(bytes(CONTRACT_NAME)), 
                getChainId(), 
                address(this)
            )
        );
    
    constructor(address _proofSigner, address _usdc) {
        require(_usdc != address(0) && _proofSigner != address(0), "invalid token or signer address");

        proofSigner = _proofSigner;
        paymentTokens[_usdc] = true;
    }

    /**
     * @notice Create the order.
     * @dev Create the order with order information.
     * @param id Order id
     * @param seller Address of the seller
     * @param paymentToken Address of the payment token used for the order
     * @param orderType Type of the order
     * @param amount Payment amount
     * @param sig ECDSA signature
     */
    function createOrder(
        bytes32 id, 
        address seller, 
        address paymentToken,
        OrderType orderType, 
        uint256 amount, 
        Sig calldata sig
    ) external payable {
        require(validateCreateOrder(sig, id, msg.sender, seller, paymentToken, uint256(orderType), amount), "createOrder: invalid signature");
        require(paymentToken == address(0) || paymentTokens[paymentToken], "createOrder: invalid payment token");
        require(orderType < OrderType.COUNT, "createOrder: invalid order type");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_NONE, "createOrder: invalid status");

        orderInfo.id = id;
        orderInfo.createdAt = uint128(block.timestamp);
        orderInfo.buyer = msg.sender;
        orderInfo.orderType = orderType;
        orderInfo.seller = seller;
        orderInfo.status = OrderStatus.ORDER_CREATED;

        if (paymentToken == address(0)) {
            orderInfo.amount = msg.value;
            orderInfo.paymentType = PaymentType.PAYMENT_ETH;
        } else {
            IERC20(paymentToken).safeTransferFrom(msg.sender, address(this), amount);
            orderInfo.amount = amount;
            orderInfo.paymentType = PaymentType.PAYMENT_ERC20;
        }

        orderInfo.paymentToken = paymentToken;
        emit OrderCreated(id, orderInfo.buyer, seller, uint8(orderInfo.paymentType), uint8(orderType), orderInfo.createdAt, orderInfo.amount);
    }

    /**
     * @notice Claim the order fund by seller after order is delivered and confirmed.
     * @dev Claim the order fund with order information.
     * @param id Order id
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param sig ECDSA signature
     */
    function claimOrder(
        bytes32 id,
        address buyer,
        address seller,
        Sig calldata sig
    ) public {
        require(validateClaimOrder(sig, id, buyer, seller, uint256(OrderStatus.ORDER_DELIVERED)), "claimOrder: invalid signature");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "claimOrder: invalid status");
        require(orderInfo.seller == msg.sender && orderInfo.seller == seller, "claimOrder: invalid seller");
        require(orderInfo.buyer == buyer, "claimOrder: invalid buyer info");
        require(orderInfo.orderType < OrderType.COUNT, "claimOrder: invalid order type");

        uint256 fee = orderInfo.amount * transactionFee / 100000;

        if(orderInfo.orderType == OrderType.ESCROW) {
            uint256 escrowFee = orderInfo.amount * defaultEscrowFee / 100000;
            fee += escrowFee * 10 / 100;
            escrowFees[orderInfo.seller] = escrowFees[orderInfo.seller] + escrowFee * 90 / 100;
        }

        adminFees[orderInfo.paymentToken] = adminFees[orderInfo.paymentToken] + fee;
        orderInfo.status = OrderStatus.ORDER_COMPLETED;

        if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
            payable(orderInfo.seller).transfer(orderInfo.amount - fee);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(orderInfo.seller, orderInfo.amount - fee);

        orderInfo.completedAt = uint128(block.timestamp);
        emit OrderCompleted(id, orderInfo.buyer, orderInfo.seller, orderInfo.completedAt);
    }

    /**
     * @notice Claim multiple orders.
     * @dev Claim multiple orders.
     * @param ids Order ids
     * @param buyers The addresses of the buyers
     * @param sellers The addresses of the sellers
     * @param sigs Array of ECDSA signatures
     */
    function claimOrders(
        bytes32[] calldata ids,
        address[] calldata buyers,
        address[] calldata sellers,
        Sig[] calldata sigs
    ) external {
        require(sigs.length == ids.length, "invalid length");
        require(sellers.length == buyers.length, "invalid length");

        uint256 len = ids.length;
        uint256 i;

        unchecked {
            do {
               claimOrder(ids[i], buyers[i], sellers[i], sigs[i]);
            } while(++i < len);
        }
    }

    /**
     * @notice Withdraw funds for a buyer after an order is cancelled
     * @dev Withdraw the order fund with order data
     * @param id Order id
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param sig ECDSA signature
     */
    function withdrawOrder(
        bytes32 id, 
        address buyer, 
        address seller, 
        Sig calldata sig
    ) external {
        require(validateWithdrawOrder(sig, id, buyer, seller, uint256(OrderStatus.ORDER_CANCELLED)), "withdrawOrder: invalid signature");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "withdrawOrder: invalid status");
        require(orderInfo.buyer == msg.sender && orderInfo.buyer == buyer, "withdrawOrder: invalid buyer");
        require(orderInfo.seller == seller, "withdrawOrder: invalid seller info");

        orderInfo.status = OrderStatus.ORDER_CANCELLED;

        if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
            payable(orderInfo.buyer).transfer(orderInfo.amount);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(orderInfo.buyer, orderInfo.amount);

        uint256 remainingEscrowFees = escrowFees[orderInfo.seller];
        if(remainingEscrowFees > 0) {
            escrowFees[orderInfo.seller] = 0;
            if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
                payable(orderInfo.seller).transfer(remainingEscrowFees);
            else
                IERC20(orderInfo.paymentToken).safeTransfer(orderInfo.seller, remainingEscrowFees);
        }
            
        orderInfo.cancelledAt = uint128(block.timestamp);
        emit OrderCancelled(id, orderInfo.buyer, orderInfo.seller, orderInfo.cancelledAt);
    }

    /**
     * @notice Release the disputed fund by buyer or seller as admin indicated.
     * @dev Release the disputed fund by buyer or seller as admin indicated.
     * @param id Order id.
     * @param buyer Address of the buyer
     * @param seller Address of the seller
     * @param winner Address of the winner
     * @param sigs Array of the v,r,s values of the ECDSA signatures
     */
    function releaseDisputedOrder(
        bytes32 id, 
        address buyer, 
        address seller, 
        address winner, 
        Sig[] calldata sigs
    ) external {
        require(validateReleaseDisputedOrder(sigs, id, buyer, seller, uint256(OrderStatus.ORDER_DISPUTE), winner), "releaseDisputedOrder: invalid signature");
        require(buyer == winner || seller == winner, "releaseDisputedOrder: invalid winner");
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "releaseDisputedOrder: invalid status");
        require(winner == msg.sender && orderInfo.buyer == buyer &&  orderInfo.seller == seller, "releaseDisputedOrder: invalid info");

        orderInfo.status = OrderStatus.ORDER_DISPUTE_HANDLED;
        if (orderInfo.paymentType == PaymentType.PAYMENT_ETH)
            payable(winner).transfer(orderInfo.amount);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(winner, orderInfo.amount);

        orderInfo.disputedAt = uint128(block.timestamp);
        emit OrderDisputeHandled(id, orderInfo.buyer, orderInfo.seller, winner, orderInfo.disputedAt);
    }

    /**
     * @notice Sets the proof signer address.
     * @dev Admin function to set the proof signer address.
     * @param newProofSigner The new proof signer.
     */
    function _setProofSigner(address newProofSigner) external onlyOwner {
        require(newProofSigner != address(0), "invalid proof signer");
        proofSigner = newProofSigner;
        emit NewProofSigner(proofSigner);
    }

    /**
     * @notice Add new market admin.
     * @dev Admin function to add new market admin.
     * @param newAdmins The new admin.
     */
    function _setNewAdmins(address[] calldata newAdmins) external onlyOwner {
        require(newAdmins.length > 0, "invalid admins length");
        admins = newAdmins;
        emit NewAdmins(admins);
    }

    /**
     * @notice Add new payment token
     * @dev Admin function to add new payment token
     * @param paymentToken Supported payment token
     * @param add Add or remove admin.
     */
    function _addOrRemovePaymentToken(address paymentToken, bool add) external onlyOwner {
        require(paymentToken != address(0), "invalid payment token");
        paymentTokens[paymentToken] = add;
    }

    /**
     * @notice Sets the transaction fee 
     * @dev Admin function to set the transaction fee
     * @param newFee escrow fee recipient.
     */
     function _setTransactionFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_TRANSACTION_FEE, "invalid fee range");
        transactionFee = newFee;
        emit NewTransactionFee(newFee);
     }

    /**
     * @notice Sets the escrow fee.
     * @dev Admin function to set the escrow fee.
     * @param newEscrowFee The new escrow fee, scaled by 1e18.
     */
    function _setEscrowFee(uint256 newEscrowFee) external onlyOwner {
        require(newEscrowFee <= MAX_ESCROW_FEE, "invalid fee range");
        defaultEscrowFee = newEscrowFee;
        emit NewEscrowFee(newEscrowFee);
    }

    /**
     * @notice Sets the escrow pending period.
     * @dev Admin function to set the escrow pending period.
     * @param newEscrowPendingPeriod The new escrow pending period in timestamp
     */
    function _setEscrowPendingPeriod(uint256 newEscrowPendingPeriod) external onlyOwner {
        require(newEscrowPendingPeriod <= MAX_ESCROW_PENDING_PERIOD, "pending period must not exceed maximum period");
        require(newEscrowPendingPeriod >= MIN_ESCROW_PENDING_PERIOD, "pending period must exceed minimum period");
        escrowPendingPeriod = newEscrowPendingPeriod;
        emit NewEscrowPendingPeriod(escrowPendingPeriod);
    }

    /**
     * @notice Sets the escrow lock period.
     * @dev Admin function to set the escrow lock period.
     * @param newEscrowLockPeriod The new escrow lock period in timestamp
     */
    function _setEscrowLockPeriod(uint256 newEscrowLockPeriod) external onlyOwner {
        require(newEscrowLockPeriod <= MAX_ESCROW_LOCK_PERIOD, "lock period must not exceed maximum period");
        require(newEscrowLockPeriod >= MIN_ESCROW_LOCK_PERIOD, "lock period must exceed minimum period");
        escrowLockPeriod = newEscrowLockPeriod;
        emit NewEscrowLockPeriod(escrowLockPeriod);
    }

    /**
     * @notice Withdraw the admin fee.
     * @dev Admin function to withdraw the admin fee.
     * @param recipient The address that will receive the fees.
     * @param token The token address to withdraw, NULL for ETH, token address for ERC20.
     * @param amount The amount to withdraw.
     */
    function _withdrawAdminFee(address recipient, address token, uint256 amount) external onlyOwner {
        require(recipient != address(0), "invalid recipient address");
        require(adminFees[token] >= amount, "invalid token address or amount");

        if (token == address(0))
            payable(recipient).transfer(amount);
        else
            IERC20(token).safeTransfer(recipient, amount);

        adminFees[token] = adminFees[token] - amount;
        emit WithdrawAdminFee(msg.sender, recipient, token, amount);
    }

    /**
     * @notice Withdraw the unclaimed fund for lock period.
     * @dev Admin function to withdraw the unclaimed fund for lock period.
     * @param id The order id.
     * @param recipient The address that will receive the fees.
     */
    function _withdrawLockedFund(bytes32 id, address recipient) external onlyOwner {
        OrderInfo storage orderInfo = orders[id];
        require(orderInfo.status == OrderStatus.ORDER_CREATED, "invalid order status");
        require(recipient != address(0), "invalid recipient address");
        require(orderInfo.createdAt + escrowLockPeriod >= block.timestamp, "can not withdraw before lock period");
        
        if (orderInfo.paymentToken == address(0))
            payable(recipient).transfer(orderInfo.amount);
        else
            IERC20(orderInfo.paymentToken).safeTransfer(recipient, orderInfo.amount);

        orderInfo.status = OrderStatus.ORDER_ADMIN_WITHDRAWN;
        emit WithdrawLockedFund(msg.sender, id, recipient, orderInfo.amount);
    }

    /**
     * @notice Retrieve the chain ID the contract is deployed to
     * @dev Retrieve the chain ID from the EVM
     * @return chainId chain ID
     */
    function getChainId() internal view returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    /**
     * @notice Validates a create order signature
     * @dev Validates the signature of a create order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param paymentToken Payment token address
     * @param orderType Order type
     * @param amount Order amount
     * @return bool Whether the signature is valid or not
     */
    function validateCreateOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        address paymentToken, 
        uint256 orderType, 
        uint256 amount
    ) internal view returns(bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        CREATE_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        paymentToken,
                        orderType,
                        amount
                    )
                )
            )
        );

        return ecrecover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a claim order signature
     * @dev Validates the signature of a claim order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param orderStatus Order status in integer value
     * @return bool Whether the signature is valid or not
     */
    function validateClaimOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        uint256 orderStatus
    ) internal view returns(bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        CLAIM_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        orderStatus
                    )
                )
            )
        );
        
        return ecrecover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a withdraw order signature
     * @dev Validates the signature of a withdraw order action by verifying the signature
     * @param sig ECDSA signature
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param orderStatus Order status in integer value
     * @return bool Whether the signature is valid or not
     */
    function validateWithdrawOrder(
        Sig calldata sig,
        bytes32 id, 
        address buyer, 
        address seller, 
        uint256 orderStatus
    ) internal view returns(bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        WITHDRAW_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        orderStatus
                    )
                )
            )
        );

        return ecrecover(digest, sig.v, sig.r, sig.s) == proofSigner;
    }

    /**
     * @notice Validates a release disputed order signature
     * @dev Validates the signature of a release disputed order action by verifying the signature
     * @param sigs Array of the v,r,s values of the ECDSA signatures
     * @param id Order id
     * @param buyer Buyer address
     * @param seller Seller address
     * @param orderStatus Order status in integer value
     * @param winner Winner address
     * @return bool Whether the signature is valid or not
     */
    function validateReleaseDisputedOrder(
        Sig[] calldata sigs,
        bytes32 id,
        address buyer,
        address seller,
        uint256 orderStatus,
        address winner
    ) internal view returns(bool) {
        require(sigs.length == REQUIRED_SIGNATURE_COUNT, "invalid signature required count");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeperator,
                keccak256(
                    abi.encode(
                        RELEASE_DISPUTED_ORDER_TYPEHASH,
                        id,
                        buyer,
                        seller,
                        orderStatus,
                        winner
                    )
                )
            )
        );
        
        address signerOne = ecrecover(digest, sigs[0].v, sigs[0].r, sigs[0].s);
        address signerTwo = ecrecover(digest, sigs[1].v, sigs[1].r, sigs[1].s);
        require(signerOne != signerTwo, "same signature");

        uint256 validSignatureCount;
        for(uint256 i; i < admins.length; i++) {
            if(signerOne == admins[i] || signerTwo == admins[i]) {
                validSignatureCount++;
            }
        }

        return validSignatureCount == REQUIRED_SIGNATURE_COUNT;
    }

    /**
     * @notice View function to get order info by ID
     * @dev Retrieves the order struct by ID
     * @param orderId Order ID
     * @return OrderInfo Order struct
     */
    function getOrderInfo(bytes32 orderId) public view returns (OrderInfo memory) {
        return orders[orderId];
    }
    
    /**
     * @notice View function to get the amount of admin fees by a specific token
     * @dev Retrieves the amount of admin fees by a specific token address, either ETH or ERC20
     * @param token Token address
     * @return uint256 Amount of fees in wei
     */
    function getAdminFeeAmount(address token) public view returns (uint256) {
        return adminFees[token];
    }

    /**
     * @dev Internal pure function to retrieve the name of this contract as a
     *      string that will be used to derive the name hash in the constructor.
     * @return The name of this contract as a string.
     */
    function _nameString() public pure returns (string memory) {
        return "GreyMarket";
    }

    /**
     * @notice UUID V4 to bytes32 representation in Solidity
     * @param s UUID V4 string
     */
    function UUIDStringToBytes32(string memory s) public pure returns (bytes32) {
        bytes memory bytesArray = bytes(s);
        bytes memory noDashes = new bytes(32);
        uint index;
        for (uint256 i; i < bytesArray.length; i++) {
            if (bytesArray[i] == "-") {
                continue;
            }
            noDashes[index] = bytesArray[i];
            index++;
        }
        bytes32 result;
        assembly {
            result := mload(add(noDashes, 32))
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

uint256 constant MAX_TRANSACTION_FEE = 10000;
uint256 constant MAX_ESCROW_FEE = 5000;
uint256 constant MAX_ESCROW_PENDING_PERIOD = 6 * 30 days;
uint256 constant MIN_ESCROW_PENDING_PERIOD = 7 days;
uint256 constant REQUIRED_SIGNATURE_COUNT = 2;
uint256 constant MAX_ESCROW_LOCK_PERIOD = 12 * 30 days;
uint256 constant MIN_ESCROW_LOCK_PERIOD = 6 * 30 days;

enum PaymentType {
    PAYMENT_ETH,
    PAYMENT_ERC20
}

enum OrderStatus {
    ORDER_NONE,
    ORDER_CREATED,
    ORDER_PENDING,
    ORDER_TRANSIT,
    ORDER_DELIVERED,
    ORDER_COMPLETED,
    ORDER_CANCELLED,
    ORDER_DISPUTE,
    ORDER_DISPUTE_HANDLED,
    ORDER_ADMIN_WITHDRAWN
}

enum OrderType {
    ESCROW,
    DIRECT,
    COUNT
}

struct OrderInfo {
    bytes32 id;
    address buyer;
    address seller;
    OrderStatus status;
    PaymentType paymentType;
    address paymentToken;
    uint256 amount;
    OrderType orderType;
    bytes sellerSignature;
    uint128 createdAt;
    uint128 cancelledAt;
    uint128 completedAt;
    uint128 disputedAt;
}

struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title gm.co Event
 * @author projectPXN
 * @custom:coauthor bldr
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarketEvent {
    event NewProofSigner(address newProofSigner);

    event OrderCreated(bytes32 id, address indexed buyer, address indexed seller, uint8 paymentType, uint8 orderType, uint256 blockTimestamp, uint256 amount);

    event OrderCancelled(bytes32 id, address indexed buyer, address indexed seller, uint256 blockTimestamp);

    event OrderCompleted(bytes32 id, address indexed buyer, address indexed seller, uint256 blockTimestamp);

    event OrderDisputeHandled(bytes32 id, address indexed buyer, address indexed seller, address winner, uint256 blockTimestamp);

    event NewEscrowFee(uint256 newEscrowFee);

    event NewEscrowPendingPeriod(uint256 newEscrowPendingPeriod);

    event NewEscrowLockPeriod(uint256 newEscrowLockPeriod);

    event NewAdmins(address[] newAdmins);

    event WithdrawAdminFee(address caller, address recipient, address token, uint256 amount);

    event WithdrawLockedFund(address caller, bytes32 orderId, address recipient, uint256 amount);

    event NewTransactionFee(uint256 newTransactionFee);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GreyMarketData.sol";

/**
 * @title gm.co Storage
 * @author projectPXN
 * @custom:coauthor bldr
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarketStorage {
    address public proofSigner;

    address[] public admins;

    uint256 public transactionFee = 5000;

    uint256 public defaultEscrowFee = 2900;

    uint256 public escrowPendingPeriod;

    uint256 public escrowLockPeriod;

    mapping(address => uint256) public adminFees;

    mapping(address => uint256) public escrowFees;

    mapping(bytes32 => OrderInfo) public orders;

    mapping(address => bool) public paymentTokens;
}