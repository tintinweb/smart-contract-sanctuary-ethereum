// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

import "../interfaces/INXMMaster.sol";
import "../interfaces/IMasterAwareV2.sol";
import "../interfaces/IMemberRoles.sol";

abstract contract MasterAwareV2 is IMasterAwareV2 {

  INXMMaster public master;

  mapping(uint => address payable) public internalContracts;

  modifier onlyMember {
    require(
      IMemberRoles(internalContracts[uint(ID.MR)]).checkRole(
        msg.sender,
        uint(IMemberRoles.Role.Member)
      ),
      "Caller is not a member"
    );
    _;
  }

  modifier onlyAdvisoryBoard {
    require(
      IMemberRoles(internalContracts[uint(ID.MR)]).checkRole(
        msg.sender,
        uint(IMemberRoles.Role.AdvisoryBoard)
      ),
      "Caller is not an advisory board member"
    );
    _;
  }

  modifier onlyInternal {
    require(master.isInternal(msg.sender), "Caller is not an internal contract");
    _;
  }

  modifier onlyMaster {
    if (address(master) != address(0)) {
      require(address(master) == msg.sender, "Not master");
    }
    _;
  }

  modifier onlyGovernance {
    require(
      master.checkIsAuthToGoverned(msg.sender),
      "Caller is not authorized to govern"
    );
    _;
  }

  modifier onlyEmergencyAdmin {
    require(
      msg.sender == master.emergencyAdmin(),
      "Caller is not emergency admin"
    );
    _;
  }

  modifier whenPaused {
    require(master.isPause(), "System is not paused");
    _;
  }

  modifier whenNotPaused {
    require(!master.isPause(), "System is paused");
    _;
  }

  function getInternalContractAddress(ID id) internal view returns (address payable) {
    return internalContracts[uint(id)];
  }

  function changeMasterAddress(address masterAddress) public onlyMaster {
    master = INXMMaster(masterAddress);
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./ICoverNFT.sol";
import "./IStakingNFT.sol";
import "./IStakingPool.sol";
import "./IStakingPoolFactory.sol";

/* ========== DATA STRUCTURES ========== */

enum ClaimMethod {
  IndividualClaims,
  YieldTokenIncidents
}

// Basically CoverStatus from QuotationData.sol but with the extra Migrated status to avoid
// polluting Cover.sol state layout with new status variables.
enum LegacyCoverStatus {
  Active,
  ClaimAccepted,
  ClaimDenied,
  CoverExpired,
  ClaimSubmitted,
  Requested,
  Migrated
}

/* io structs */

struct PoolAllocationRequest {
  uint40 poolId;
  bool skip;
  uint coverAmountInAsset;
}

struct RequestAllocationVariables {
  uint previousPoolAllocationsLength;
  uint previousPremiumInNXM;
  uint refund;
  uint coverAmountInNXM;
}

struct BuyCoverParams {
  uint coverId;
  address owner;
  uint24 productId;
  uint8 coverAsset;
  uint96 amount;
  uint32 period;
  uint maxPremiumInAsset;
  uint8 paymentAsset;
  uint16 commissionRatio;
  address commissionDestination;
  string ipfsData;
}

struct ProductParam {
  string productName;
  uint productId;
  string ipfsMetadata;
  Product product;
  uint[] allowedPools;
}

struct ProductTypeParam {
  string productTypeName;
  uint productTypeId;
  string ipfsMetadata;
  ProductType productType;
}

struct ProductInitializationParams {
  uint productId;
  uint8 weight;
  uint96 initialPrice;
  uint96 targetPrice;
}

/* storage structs */

struct PoolAllocation {
  uint40 poolId;
  uint96 coverAmountInNXM;
  uint96 premiumInNXM;
  uint24 allocationId;
}

struct CoverData {
  uint24 productId;
  uint8 coverAsset;
  uint96 amountPaidOut;
}

struct CoverSegment {
  uint96 amount;
  uint32 start;
  uint32 period; // seconds
  uint32 gracePeriod; // seconds
  uint24 globalRewardsRatio;
  uint24 globalCapacityRatio;
}

struct Product {
  uint16 productType;
  address yieldTokenAddress;
  // cover assets bitmap. each bit represents whether the asset with
  // the index of that bit is enabled as a cover asset for this product
  uint32 coverAssets;
  uint16 initialPriceRatio;
  uint16 capacityReductionRatio;
  bool isDeprecated;
  bool useFixedPrice;
}

struct ProductType {
  uint8 claimMethod;
  uint32 gracePeriod;
}

struct ActiveCover {
  // Global active cover amount per asset.
  uint192 totalActiveCoverInAsset;
  // The last time activeCoverExpirationBuckets was updated
  uint64 lastBucketUpdateId;
}

interface ICover {

  /* ========== VIEWS ========== */

  function coverData(uint coverId) external view returns (CoverData memory);

  function coverDataCount() external view returns (uint);

  function coverSegmentsCount(uint coverId) external view returns (uint);

  function coverSegments(uint coverId) external view returns (CoverSegment[] memory);

  function coverSegmentWithRemainingAmount(
    uint coverId,
    uint segmentId
  ) external view returns (CoverSegment memory);

  function products(uint id) external view returns (Product memory);

  function productTypes(uint id) external view returns (ProductType memory);

  function stakingPool(uint index) external view returns (IStakingPool);

  function productNames(uint productId) external view returns (string memory);

  function productsCount() external view returns (uint);

  function productTypesCount() external view returns (uint);

  function totalActiveCoverInAsset(uint coverAsset) external view returns (uint);

  function globalCapacityRatio() external view returns (uint);

  function globalRewardsRatio() external view returns (uint);

  function getPriceAndCapacityRatios(uint[] calldata productIds) external view returns (
    uint _globalCapacityRatio,
    uint _globalMinPriceRatio,
    uint[] memory _initialPriceRatios,
    uint[] memory _capacityReductionRatios
  );

  /* === MUTATIVE FUNCTIONS ==== */

  function addLegacyCover(
    uint productId,
    uint coverAsset,
    uint amount,
    uint start,
    uint period,
    address newOwner
  ) external returns (uint coverId);

  function buyCover(
    BuyCoverParams calldata params,
    PoolAllocationRequest[] calldata coverChunkRequests
  ) external payable returns (uint coverId);

  function setProductTypes(ProductTypeParam[] calldata productTypes) external;

  function setProducts(ProductParam[] calldata params) external;

  function burnStake(
    uint coverId,
    uint segmentId,
    uint amount
  ) external returns (address coverOwner);

  function coverNFT() external returns (ICoverNFT);

  function stakingNFT() external returns (IStakingNFT);

  function stakingPoolFactory() external returns (IStakingPoolFactory);

  function createStakingPool(
    bool isPrivatePool,
    uint initialPoolFee,
    uint maxPoolFee,
    ProductInitializationParams[] calldata productInitParams,
    string calldata ipfsDescriptionHash
  ) external returns (uint poolId, address stakingPoolAddress);

  function isPoolAllowed(uint productId, uint poolId) external returns (bool);

  /* ========== EVENTS ========== */

  event ProductSet(uint id, string ipfsMetadata);
  event ProductTypeSet(uint id, string ipfsMetadata);
  event CoverEdited(uint indexed coverId, uint indexed productId, uint indexed segmentId, address buyer, string ipfsMetadata);

  // Auth
  error OnlyMemberRolesCanOperateTransfer();
  error OnlyOwnerOrApproved();

  // Cover details
  error CoverPeriodTooShort();
  error CoverPeriodTooLong();
  error CoverOutsideOfTheGracePeriod();
  error CoverAmountIsZero();

  // Products
  error ProductDoesntExist();
  error ProductTypeNotFound();
  error ProductDeprecated();
  error ProductDeprecatedOrNotInitialized();
  error InvalidProductType();
  error UnexpectedProductId();

  // Cover and payment assets
  error CoverAssetNotSupported();
  error InvalidPaymentAsset();
  error UnexpectedCoverAsset();
  error UnsupportedCoverAssets();
  error UnexpectedEthSent();

  // Price & Commission
  error PriceExceedsMaxPremiumInAsset();
  error TargetPriceBelowGlobalMinPriceRatio();
  error InitialPriceRatioBelowGlobalMinPriceRatio();
  error InitialPriceRatioAbove100Percent();
  error CommissionRateTooHigh();

  // ETH transfers
  error InsufficientEthSent();
  error SendingEthToPoolFailed();
  error SendingEthToCommissionDestinationFailed();
  error ReturningEthRemainderToSenderFailed();

  // Misc
  error AlreadyInitialized();
  error ExpiredCoversCannotBeEdited();
  error InsufficientCoverAmountAllocated();
  error UnexpectedPoolId();
  error CapacityReductionRatioAbove100Percent();
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "@openzeppelin/contracts-v4/token/ERC721/IERC721.sol";

interface ICoverNFT is IERC721 {

  function isApprovedOrOwner(address spender, uint tokenId) external returns (bool);

  function mint(address to) external returns (uint tokenId);

  function changeOperator(address newOperator) external;

  function totalSupply() external view returns (uint);

  function name() external view returns (string memory);

  error NotOperator();
  error NotMinted();
  error WrongFrom();
  error InvalidRecipient();
  error InvalidNewOperatorAddress();
  error InvalidNewNFTDescriptorAddress();
  error NotAuthorized();
  error UnsafeRecipient();
  error AlreadyMinted();

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMasterAwareV2 {

  enum ID {
    TC, // TokenController.sol
    P1, // Pool.sol
    MR, // MemberRoles.sol
    MC, // MCR.sol
    CO, // Cover.sol
    SP, // StakingProducts.sol
    PS, // LegacyPooledStaking.sol
    GV, // Governance.sol
    GW, // LegacyGateway.sol
    CL, // CoverMigrator.sol
    AS, // Assessment.sol
    CI, // IndividualClaims.sol - Claims for Individuals
    CG, // YieldTokenIncidents.sol - Claims for Groups
    // TODO: 1) if you update this enum, update lib/constants.js as well
    // TODO: 2) TK is not an internal contract!
    //          If you want to add a new contract below TK, remove TK and make it immutable in all
    //          contracts that are using it (currently LegacyGateway and LegacyPooledStaking).
    TK  // NXMToken.sol
  }

  function changeMasterAddress(address masterAddress) external;

  function changeDependentContractAddress() external;

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IMemberRoles {

  enum Role {Unassigned, AdvisoryBoard, Member, Owner}

  function join(address _userAddress, uint nonce, bytes calldata signature) external payable;

  function switchMembership(address _newAddress) external;

  function switchMembershipAndAssets(
    address newAddress,
    uint[] calldata coverIds,
    uint[] calldata stakingTokenIds
  ) external;

  function switchMembershipOf(address member, address _newAddress) external;

  function totalRoles() external view returns (uint256);

  function changeAuthorized(uint _roleId, address _newAuthorized) external;

  function setKycAuthAddress(address _add) external;

  function members(uint _memberRoleId) external view returns (uint, address[] memory memberArray);

  function numberOfMembers(uint _memberRoleId) external view returns (uint);

  function authorized(uint _memberRoleId) external view returns (address);

  function roles(address _memberAddress) external view returns (uint[] memory);

  function checkRole(address _memberAddress, uint _roleId) external view returns (bool);

  function getMemberLengthForAllRoles() external view returns (uint[] memory totalMembers);

  function memberAtIndex(uint _memberRoleId, uint index) external view returns (address, bool);

  function membersLength(uint _memberRoleId) external view returns (uint);

  event MemberRole(uint256 indexed roleId, bytes32 roleName, string roleDescription);

  event MemberJoined(address indexed newMember, uint indexed nonce);

  event switchedMembership(address indexed previousMember, address indexed newMember, uint timeStamp);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMMaster {

  function tokenAddress() external view returns (address);

  function owner() external view returns (address);

  function emergencyAdmin() external view returns (address);

  function masterInitialized() external view returns (bool);

  function isInternal(address _add) external view returns (bool);

  function isPause() external view returns (bool check);

  function isMember(address _add) external view returns (bool);

  function checkIsAuthToGoverned(address _add) external view returns (bool);

  function getLatestAddress(bytes2 _contractName) external view returns (address payable contractAddress);

  function contractAddresses(bytes2 code) external view returns (address payable);

  function upgradeMultipleContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses
  ) external;

  function removeContracts(bytes2[] calldata contractCodesToRemove) external;

  function addNewInternalContracts(
    bytes2[] calldata _contractCodes,
    address payable[] calldata newAddresses,
    uint[] calldata _types
  ) external;

  function updateOwnerParameters(bytes8 code, address payable val) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface INXMToken {

  function burn(uint256 amount) external returns (bool);

  function burnFrom(address from, uint256 value) external returns (bool);

  function operatorTransfer(address from, uint256 value) external returns (bool);

  function mint(address account, uint256 amount) external;

  function isLockedForMV(address member) external view returns (uint);

  function addToWhiteList(address _member) external returns (bool);

  function removeFromWhiteList(address _member) external returns (bool);

  function changeOperator(address _newOperator) external returns (bool);

  function lockForMemberVote(address _of, uint _days) external;

  /**
 * @dev Returns the amount of tokens in existence.
 */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./IPriceFeedOracle.sol";

struct SwapDetails {
  uint104 minAmount;
  uint104 maxAmount;
  uint32 lastSwapTime;
  // 2 decimals of precision. 0.01% -> 0.0001 -> 1e14
  uint16 maxSlippageRatio;
}

struct Asset {
  address assetAddress;
  bool isCoverAsset;
  bool isAbandoned;
}

interface IPool {

  function getAsset(uint assetId) external view returns (Asset memory);

  function getAssets() external view returns (Asset[] memory);

  function buyNXM(uint minTokensOut) external payable;

  function sellNXM(uint tokenAmount, uint minEthOut) external;

  function sellNXMTokens(uint tokenAmount) external returns (bool);

  function transferAssetToSwapOperator(address asset, uint amount) external;

  function setSwapDetailsLastSwapTime(address asset, uint32 lastSwapTime) external;

  function getAssetSwapDetails(address assetAddress) external view returns (SwapDetails memory);

  function getNXMForEth(uint ethAmount) external view returns (uint);

  function sendPayout(uint assetIndex, address payable payoutAddress, uint amount) external;

  function upgradeCapitalPool(address payable newPoolAddress) external;

  function priceFeedOracle() external view returns (IPriceFeedOracle);

  function getPoolValueInEth() external view returns (uint);

  function getEthForNXM(uint nxmAmount) external view returns (uint ethAmount);

  function calculateEthForNXM(uint nxmAmount, uint currentTotalAssetValue, uint mcrEth) external pure returns (uint);

  function calculateMCRRatio(uint totalAssetValue, uint mcrEth) external pure returns (uint);

  function calculateTokenSpotPrice(uint totalAssetValue, uint mcrEth) external pure returns (uint tokenPrice);

  function getTokenPriceInAsset(uint assetId) external view returns (uint tokenPrice);

  function getTokenPrice() external view returns (uint tokenPrice);

  function getMCRRatio() external view returns (uint);

  function setSwapValue(uint value) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface Aggregator {
  function latestAnswer() external view returns (int);
}

struct OracleAsset {
  Aggregator aggregator;
  uint8 decimals;
}

interface IPriceFeedOracle {

  function ETH() external view returns (address);
  function assets(address) external view returns (Aggregator, uint8);

  function getAssetToEthRate(address asset) external view returns (uint);
  function getAssetForEth(address asset, uint ethIn) external view returns (uint);
  function getEthForAsset(address asset, uint amount) external view returns (uint);

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "@openzeppelin/contracts-v4/token/ERC721/IERC721.sol";

interface IStakingNFT is IERC721 {

  function isApprovedOrOwner(address spender, uint tokenId) external returns (bool);

  function mint(uint poolId, address to) external returns (uint tokenId);

  function changeOperator(address newOperator) external;

  function totalSupply() external returns (uint);

  function tokenInfo(uint tokenId) external view returns (uint poolId, address owner);

  function stakingPoolOf(uint tokenId) external view returns (uint poolId);

  function stakingPoolFactory() external view returns (address);

  function name() external view returns (string memory);

  error NotOperator();
  error NotMinted();
  error WrongFrom();
  error InvalidRecipient();
  error InvalidNewOperatorAddress();
  error InvalidNewNFTDescriptorAddress();
  error NotAuthorized();
  error UnsafeRecipient();
  error AlreadyMinted();
  error NotStakingPool();

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

/* structs for io */

struct AllocationRequest {
  uint productId;
  uint coverId;
  uint allocationId;
  uint period;
  uint gracePeriod;
  bool useFixedPrice;
  uint previousStart;
  uint previousExpiration;
  uint previousRewardsRatio;
  uint globalCapacityRatio;
  uint capacityReductionRatio;
  uint rewardRatio;
  uint globalMinPrice;
}

struct StakedProductParam {
  uint productId;
  bool recalculateEffectiveWeight;
  bool setTargetWeight;
  uint8 targetWeight;
  bool setTargetPrice;
  uint96 targetPrice;
}

  struct BurnStakeParams {
    uint allocationId;
    uint productId;
    uint start;
    uint period;
    uint deallocationAmount;
  }

interface IStakingPool {

  /* structs for storage */

  // stakers are grouped in tranches based on the timelock expiration
  // tranche index is calculated based on the expiration date
  // the initial proposal is to have 4 tranches per year (1 tranche per quarter)
  struct Tranche {
    uint128 stakeShares;
    uint128 rewardsShares;
  }

  struct ExpiredTranche {
    uint96 accNxmPerRewardShareAtExpiry;
    uint96 stakeAmountAtExpiry; // nxm total supply is 6.7e24 and uint96.max is 7.9e28
    uint128 stakeSharesSupplyAtExpiry;
  }

  struct Deposit {
    uint96 lastAccNxmPerRewardShare;
    uint96 pendingRewards;
    uint128 stakeShares;
    uint128 rewardsShares;
  }

  function initialize(
    bool isPrivatePool,
    uint initialPoolFee,
    uint maxPoolFee,
    uint _poolId,
    string memory ipfsDescriptionHash
  ) external;

  function processExpirations(bool updateUntilCurrentTimestamp) external;

  function requestAllocation(
    uint amount,
    uint previousPremium,
    AllocationRequest calldata request
  ) external returns (uint premium, uint allocationId);

  function burnStake(uint amount, BurnStakeParams calldata params) external;

  function depositTo(
    uint amount,
    uint trancheId,
    uint requestTokenId,
    address destination
  ) external returns (uint tokenId);

  function withdraw(
    uint tokenId,
    bool withdrawStake,
    bool withdrawRewards,
    uint[] memory trancheIds
  ) external returns (uint withdrawnStake, uint withdrawnRewards);

  function isPrivatePool() external view returns (bool);

  function isHalted() external view returns (bool);

  function manager() external view returns (address);

  function getPoolId() external view returns (uint);

  function getPoolFee() external view returns (uint);

  function getMaxPoolFee() external view returns (uint);

  function getActiveStake() external view returns (uint);

  function getStakeSharesSupply() external view returns (uint);

  function getRewardsSharesSupply() external view returns (uint);

  function getRewardPerSecond() external view returns (uint);

  function getAccNxmPerRewardsShare() external view returns (uint);

  function getLastAccNxmUpdate() external view returns (uint);

  function getFirstActiveTrancheId() external view returns (uint);

  function getFirstActiveBucketId() external view returns (uint);

  function getNextAllocationId() external view returns (uint);

  function getDeposit(uint tokenId, uint trancheId) external view returns (
    uint lastAccNxmPerRewardShare,
    uint pendingRewards,
    uint stakeShares,
    uint rewardsShares
  );

  function getTranche(uint trancheId) external view returns (
    uint stakeShares,
    uint rewardsShares
  );

  function getExpiredTranche(uint trancheId) external view returns (
    uint accNxmPerRewardShareAtExpiry,
    uint stakeAmountAtExpiry,
    uint stakeShareSupplyAtExpiry
  );

  function setPoolFee(uint newFee) external;

  function setPoolPrivacy(bool isPrivatePool) external;

  function getActiveAllocations(
    uint productId
  ) external view returns (uint[] memory trancheAllocations);

  function getTrancheCapacities(
    uint productId,
    uint firstTrancheId,
    uint trancheCount,
    uint capacityRatio,
    uint reductionRatio
  ) external view returns (uint[] memory trancheCapacities);

  /* ========== EVENTS ========== */

  event StakeDeposited(address indexed user, uint256 amount, uint256 trancheId, uint256 tokenId);

  event DepositExtended(address indexed user, uint256 tokenId, uint256 initialTrancheId, uint256 newTrancheId, uint256 topUpAmount);

  event PoolPrivacyChanged(address indexed manager, bool isPrivate);

  event PoolFeeChanged(address indexed manager, uint newFee);

  event PoolDescriptionSet(string ipfsDescriptionHash);

  event Withdraw(address indexed user, uint indexed tokenId, uint tranche, uint amountStakeWithdrawn, uint amountRewardsWithdrawn);

  event StakeBurned(uint amount);

  // Auth
  error OnlyCoverContract();
  error OnlyManager();
  error PrivatePool();
  error SystemPaused();
  error PoolHalted();

  // Fees
  error PoolFeeExceedsMax();
  error MaxPoolFeeAbove100();

  // Voting
  error NxmIsLockedForGovernanceVote();
  error ManagerNxmIsLockedForGovernanceVote();

  // Deposit
  error InsufficientDepositAmount();
  error RewardRatioTooHigh();

  // Staking NFTs
  error InvalidTokenId();
  error NotTokenOwnerOrApproved();
  error InvalidStakingPoolForToken();

  // Tranche & capacity
  error NewTrancheEndsBeforeInitialTranche();
  error RequestedTrancheIsNotYetActive();
  error RequestedTrancheIsExpired();
  error InsufficientCapacity();

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IStakingPoolBeacon {
  /**
   * @dev Must return an address that can be used as a delegate call target.
   *
   * {BeaconProxy} will check that this address is a contract.
   */
  function stakingPoolImplementation() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

interface IStakingPoolFactory {

  function stakingPoolCount() external view returns (uint);

  function beacon() external view returns (address);

  function create(address beacon) external returns (uint poolId, address stakingPoolAddress);

  event StakingPoolCreated(uint indexed poolId, address indexed stakingPoolAddress);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./ICover.sol";
import "./IStakingPool.sol";

interface IStakingProducts {

  // TODO: resize values?
  struct Weights {
    uint32 totalEffectiveWeight;
    uint32 totalTargetWeight;
  }

  struct StakedProduct {
    uint16 lastEffectiveWeight;
    uint8 targetWeight;
    uint96 targetPrice;
    uint96 bumpedPrice;
    uint32 bumpedPriceUpdateTime;
  }

  /* ============= PRODUCT FUNCTIONS ============= */

  function setProducts(uint poolId, StakedProductParam[] memory params) external;

  function setInitialProducts(uint poolId, ProductInitializationParams[] memory params) external;

  function getProductTargetWeight(uint poolId, uint productId) external view returns (uint);

  function getTotalTargetWeight(uint poolId) external view returns (uint);

  function getTotalEffectiveWeight(uint poolId) external view returns (uint);

  function getProduct(uint poolId, uint productId) external view returns (
    uint lastEffectiveWeight,
    uint targetWeight,
    uint targetPrice,
    uint bumpedPrice,
    uint bumpedPriceUpdateTime
  );

  /* ============= PRICING FUNCTIONS ============= */

  function getPremium(
    uint poolId,
    uint productId,
    uint period,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint globalMinPrice,
    bool useFixedPrice,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm
  ) external returns (uint premium);

  function calculateFixedPricePremium(
    uint coverAmount,
    uint period,
    uint fixedPrice,
    uint nxmPerAllocationUnit,
    uint targetPriceDenominator
  ) external pure returns (uint);


  function calculatePremium(
    StakedProduct memory product,
    uint period,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint targetPrice,
    uint currentBlockTimestamp,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm,
    uint targetPriceDenominator
  ) external pure returns (uint premium, StakedProduct memory);

  function calculatePremiumPerYear(
    uint basePrice,
    uint coverAmount,
    uint initialCapacityUsed,
    uint totalCapacity,
    uint nxmPerAllocationUnit,
    uint allocationUnitsPerNxm,
    uint targetPriceDenominator
  ) external pure returns (uint);

  // Calculates the premium for a given cover amount starting with the surge point
  function calculateSurgePremium(
    uint amountOnSurge,
    uint totalCapacity,
    uint allocationUnitsPerNxm
  ) external pure returns (uint);

  /* ============= EVENTS ============= */

  event ProductUpdated(uint productId, uint8 targetWeight, uint96 targetPrice);

  /* ============= ERRORS ============= */

  // Auth
  error OnlyStakingPool();
  error OnlyCoverContract();
  error OnlyManager();

  // Products & weights
  error PoolNotAllowedForThisProduct();
  error MustSetPriceForNewProducts();
  error MustSetWeightForNewProducts();
  error TargetPriceTooHigh();
  error TargetPriceBelowMin();
  error TargetWeightTooHigh();
  error MustRecalculateEffectiveWeight();
  error TotalTargetWeightExceeded();
  error TotalEffectiveWeightExceeded();

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.5.0;

import "./INXMToken.sol";

interface ITokenController {

  struct StakingPoolNXMBalances {
    uint128 rewards;
    uint128 deposits;
  }

  struct CoverInfo {
    uint16 claimCount;
    bool hasOpenClaim;
    bool hasAcceptedClaim;
    uint96 requestedPayoutAmount;
    // note: still 128 bits available here, can be used later
  }

  struct StakingPoolOwnershipOffer {
    address proposedManager;
    uint96 deadline;
  }

  function coverInfo(uint id) external view returns (
    uint16 claimCount,
    bool hasOpenClaim,
    bool hasAcceptedClaim,
    uint96 requestedPayoutAmount
  );

  function withdrawCoverNote(
    address _of,
    uint[] calldata _coverIds,
    uint[] calldata _indexes
  ) external;

  function changeOperator(address _newOperator) external;

  function operatorTransfer(address _from, address _to, uint _value) external returns (bool);

  function burnFrom(address _of, uint amount) external returns (bool);

  function addToWhitelist(address _member) external;

  function removeFromWhitelist(address _member) external;

  function mint(address _member, uint _amount) external;

  function lockForMemberVote(address _of, uint _days) external;

  function withdrawClaimAssessmentTokens(address[] calldata users) external;

  function getLockReasons(address _of) external view returns (bytes32[] memory reasons);

  function totalSupply() external view returns (uint);

  function totalBalanceOf(address _of) external view returns (uint amount);

  function totalBalanceOfWithoutDelegations(address _of) external view returns (uint amount);

  function getTokenPrice() external view returns (uint tokenPrice);

  function token() external view returns (INXMToken);

  function getStakingPoolManager(uint poolId) external view returns (address manager);

  function getManagerStakingPools(address manager) external view returns (uint[] memory poolIds);

  function isStakingPoolManager(address member) external view returns (bool);

  function getStakingPoolOwnershipOffer(uint poolId) external view returns (address proposedManager, uint deadline);

  function transferStakingPoolsOwnership(address from, address to) external;

  function assignStakingPoolManager(uint poolId, address manager) external;

  function createStakingPoolOwnershipOffer(uint poolId, address proposedManager, uint deadline) external;

  function acceptStakingPoolOwnershipOffer(uint poolId) external;

  function cancelStakingPoolOwnershipOffer(uint poolId) external;

  function mintStakingPoolNXMRewards(uint amount, uint poolId) external;

  function burnStakingPoolNXMRewards(uint amount, uint poolId) external;

  function depositStakedNXM(address from, uint amount, uint poolId) external;

  function withdrawNXMStakeAndRewards(address to, uint stakeToWithdraw, uint rewardsToWithdraw, uint poolId) external;

  function burnStakedNXM(uint amount, uint poolId) external;

  function stakingPoolNXMBalances(uint poolId) external view returns(uint128 rewards, uint128 deposits);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

/**
 * @dev Simple library that defines min, max and babylonian sqrt functions
 */
library Math {

  function min(uint a, uint b) internal pure returns (uint) {
    return a < b ? a : b;
  }

  function max(uint a, uint b) internal pure returns (uint) {
    return a > b ? a : b;
  }

  function sum(uint[] memory items) internal pure returns (uint) {
    uint count = items.length;
    uint total;

    for (uint i = 0; i < count; i++) {
      total += items[i];
    }

    return total;
  }

  function divRound(uint a, uint b) internal pure returns (uint) {
    return (a + b / 2) / b;
  }

  function divCeil(uint a, uint b) internal pure returns (uint) {
    return (a + b - 1) / b;
  }

  function roundUp(uint a, uint b) internal pure returns (uint) {
    return divCeil(a, b) * b;
  }

  // babylonian method
  function sqrt(uint y) internal pure returns (uint) {

    if (y > 3) {
      uint z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
      return z;
    }

    if (y != 0) {
      return 1;
    }

    return 0;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeUintCast {
  /**
   * @dev Returns the downcasted uint248 from uint256, reverting on
   * overflow (when the input is greater than largest uint248).
   *
   * Counterpart to Solidity's `uint248` operator.
   *
   * Requirements:
   *
   * - input must fit into 248 bits
   */
  function toUint248(uint256 value) internal pure returns (uint248) {
    require(value < 2**248, "SafeCast: value doesn\'t fit in 248 bits");
    return uint248(value);
  }

  /**
   * @dev Returns the downcasted uint240 from uint256, reverting on
   * overflow (when the input is greater than largest uint240).
   *
   * Counterpart to Solidity's `uint240` operator.
   *
   * Requirements:
   *
   * - input must fit into 240 bits
   */
  function toUint240(uint256 value) internal pure returns (uint240) {
    require(value < 2**240, "SafeCast: value doesn\'t fit in 240 bits");
    return uint240(value);
  }

  /**
   * @dev Returns the downcasted uint232 from uint256, reverting on
   * overflow (when the input is greater than largest uint232).
   *
   * Counterpart to Solidity's `uint232` operator.
   *
   * Requirements:
   *
   * - input must fit into 232 bits
   */
  function toUint232(uint256 value) internal pure returns (uint232) {
    require(value < 2**232, "SafeCast: value doesn\'t fit in 232 bits");
    return uint232(value);
  }

  /**
   * @dev Returns the downcasted uint224 from uint256, reverting on
   * overflow (when the input is greater than largest uint224).
   *
   * Counterpart to Solidity's `uint224` operator.
   *
   * Requirements:
   *
   * - input must fit into 224 bits
   */
  function toUint224(uint256 value) internal pure returns (uint224) {
    require(value < 2**224, "SafeCast: value doesn\'t fit in 224 bits");
    return uint224(value);
  }

  /**
   * @dev Returns the downcasted uint216 from uint256, reverting on
   * overflow (when the input is greater than largest uint216).
   *
   * Counterpart to Solidity's `uint216` operator.
   *
   * Requirements:
   *
   * - input must fit into 216 bits
   */
  function toUint216(uint256 value) internal pure returns (uint216) {
    require(value < 2**216, "SafeCast: value doesn\'t fit in 216 bits");
    return uint216(value);
  }

  /**
   * @dev Returns the downcasted uint208 from uint256, reverting on
   * overflow (when the input is greater than largest uint208).
   *
   * Counterpart to Solidity's `uint208` operator.
   *
   * Requirements:
   *
   * - input must fit into 208 bits
   */
  function toUint208(uint256 value) internal pure returns (uint208) {
    require(value < 2**208, "SafeCast: value doesn\'t fit in 208 bits");
    return uint208(value);
  }

  /**
   * @dev Returns the downcasted uint200 from uint256, reverting on
   * overflow (when the input is greater than largest uint200).
   *
   * Counterpart to Solidity's `uint200` operator.
   *
   * Requirements:
   *
   * - input must fit into 200 bits
   */
  function toUint200(uint256 value) internal pure returns (uint200) {
    require(value < 2**200, "SafeCast: value doesn\'t fit in 200 bits");
    return uint200(value);
  }

  /**
   * @dev Returns the downcasted uint192 from uint256, reverting on
   * overflow (when the input is greater than largest uint192).
   *
   * Counterpart to Solidity's `uint192` operator.
   *
   * Requirements:
   *
   * - input must fit into 192 bits
   */
  function toUint192(uint256 value) internal pure returns (uint192) {
    require(value < 2**192, "SafeCast: value doesn\'t fit in 192 bits");
    return uint192(value);
  }

  /**
   * @dev Returns the downcasted uint184 from uint256, reverting on
   * overflow (when the input is greater than largest uint184).
   *
   * Counterpart to Solidity's `uint184` operator.
   *
   * Requirements:
   *
   * - input must fit into 184 bits
   */
  function toUint184(uint256 value) internal pure returns (uint184) {
    require(value < 2**184, "SafeCast: value doesn\'t fit in 184 bits");
    return uint184(value);
  }

  /**
   * @dev Returns the downcasted uint176 from uint256, reverting on
   * overflow (when the input is greater than largest uint176).
   *
   * Counterpart to Solidity's `uint176` operator.
   *
   * Requirements:
   *
   * - input must fit into 176 bits
   */
  function toUint176(uint256 value) internal pure returns (uint176) {
    require(value < 2**176, "SafeCast: value doesn\'t fit in 176 bits");
    return uint176(value);
  }

  /**
   * @dev Returns the downcasted uint168 from uint256, reverting on
   * overflow (when the input is greater than largest uint168).
   *
   * Counterpart to Solidity's `uint168` operator.
   *
   * Requirements:
   *
   * - input must fit into 168 bits
   */
  function toUint168(uint256 value) internal pure returns (uint168) {
    require(value < 2**168, "SafeCast: value doesn\'t fit in 168 bits");
    return uint168(value);
  }

  /**
   * @dev Returns the downcasted uint160 from uint256, reverting on
   * overflow (when the input is greater than largest uint160).
   *
   * Counterpart to Solidity's `uint160` operator.
   *
   * Requirements:
   *
   * - input must fit into 160 bits
   */
  function toUint160(uint256 value) internal pure returns (uint160) {
    require(value < 2**160, "SafeCast: value doesn\'t fit in 160 bits");
    return uint160(value);
  }

  /**
   * @dev Returns the downcasted uint152 from uint256, reverting on
   * overflow (when the input is greater than largest uint152).
   *
   * Counterpart to Solidity's `uint152` operator.
   *
   * Requirements:
   *
   * - input must fit into 152 bits
   */
  function toUint152(uint256 value) internal pure returns (uint152) {
    require(value < 2**152, "SafeCast: value doesn\'t fit in 152 bits");
    return uint152(value);
  }

  /**
   * @dev Returns the downcasted uint144 from uint256, reverting on
   * overflow (when the input is greater than largest uint144).
   *
   * Counterpart to Solidity's `uint144` operator.
   *
   * Requirements:
   *
   * - input must fit into 144 bits
   */
  function toUint144(uint256 value) internal pure returns (uint144) {
    require(value < 2**144, "SafeCast: value doesn\'t fit in 144 bits");
    return uint144(value);
  }

  /**
   * @dev Returns the downcasted uint136 from uint256, reverting on
   * overflow (when the input is greater than largest uint136).
   *
   * Counterpart to Solidity's `uint136` operator.
   *
   * Requirements:
   *
   * - input must fit into 136 bits
   */
  function toUint136(uint256 value) internal pure returns (uint136) {
    require(value < 2**136, "SafeCast: value doesn\'t fit in 136 bits");
    return uint136(value);
  }

  /**
   * @dev Returns the downcasted uint128 from uint256, reverting on
   * overflow (when the input is greater than largest uint128).
   *
   * Counterpart to Solidity's `uint128` operator.
   *
   * Requirements:
   *
   * - input must fit into 128 bits
   */
  function toUint128(uint256 value) internal pure returns (uint128) {
    require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
    return uint128(value);
  }

  /**
   * @dev Returns the downcasted uint120 from uint256, reverting on
   * overflow (when the input is greater than largest uint120).
   *
   * Counterpart to Solidity's `uint120` operator.
   *
   * Requirements:
   *
   * - input must fit into 120 bits
   */
  function toUint120(uint256 value) internal pure returns (uint120) {
    require(value < 2**120, "SafeCast: value doesn\'t fit in 120 bits");
    return uint120(value);
  }

  /**
   * @dev Returns the downcasted uint112 from uint256, reverting on
   * overflow (when the input is greater than largest uint112).
   *
   * Counterpart to Solidity's `uint112` operator.
   *
   * Requirements:
   *
   * - input must fit into 112 bits
   */
  function toUint112(uint256 value) internal pure returns (uint112) {
    require(value < 2**112, "SafeCast: value doesn\'t fit in 112 bits");
    return uint112(value);
  }

  /**
   * @dev Returns the downcasted uint104 from uint256, reverting on
   * overflow (when the input is greater than largest uint104).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 104 bits
   */
  function toUint104(uint256 value) internal pure returns (uint104) {
    require(value < 2**104, "SafeCast: value doesn\'t fit in 104 bits");
    return uint104(value);
  }

  /**
   * @dev Returns the downcasted uint96 from uint256, reverting on
   * overflow (when the input is greater than largest uint96).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 96 bits
   */
  function toUint96(uint256 value) internal pure returns (uint96) {
    require(value < 2**96, "SafeCast: value doesn\'t fit in 96 bits");
    return uint96(value);
  }

  /**
   * @dev Returns the downcasted uint80 from uint256, reverting on
   * overflow (when the input is greater than largest uint80).
   *
   * Counterpart to Solidity's `uint104` operator.
   *
   * Requirements:
   *
   * - input must fit into 80 bits
   */
  function toUint80(uint256 value) internal pure returns (uint80) {
    require(value < 2**80, "SafeCast: value doesn\'t fit in 80 bits");
    return uint80(value);
  }

  /**
   * @dev Returns the downcasted uint64 from uint256, reverting on
   * overflow (when the input is greater than largest uint64).
   *
   * Counterpart to Solidity's `uint64` operator.
   *
   * Requirements:
   *
   * - input must fit into 64 bits
   */
  function toUint64(uint256 value) internal pure returns (uint64) {
    require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
    return uint64(value);
  }

  /**
   * @dev Returns the downcasted uint56 from uint256, reverting on
   * overflow (when the input is greater than largest uint56).
   *
   * Counterpart to Solidity's `uint56` operator.
   *
   * Requirements:
   *
   * - input must fit into 56 bits
   */
  function toUint56(uint256 value) internal pure returns (uint56) {
    require(value < 2**56, "SafeCast: value doesn\'t fit in 56 bits");
    return uint56(value);
  }

  /**
   * @dev Returns the downcasted uint48 from uint256, reverting on
   * overflow (when the input is greater than largest uint48).
   *
   * Counterpart to Solidity's `uint48` operator.
   *
   * Requirements:
   *
   * - input must fit into 48 bits
   */
  function toUint48(uint256 value) internal pure returns (uint48) {
    require(value < 2**48, "SafeCast: value doesn\'t fit in 48 bits");
    return uint48(value);
  }

  /**
   * @dev Returns the downcasted uint40 from uint256, reverting on
   * overflow (when the input is greater than largest uint40).
   *
   * Counterpart to Solidity's `uint40` operator.
   *
   * Requirements:
   *
   * - input must fit into 40 bits
   */
  function toUint40(uint256 value) internal pure returns (uint40) {
    require(value < 2**40, "SafeCast: value doesn\'t fit in 40 bits");
    return uint40(value);
  }

  /**
   * @dev Returns the downcasted uint32 from uint256, reverting on
   * overflow (when the input is greater than largest uint32).
   *
   * Counterpart to Solidity's `uint32` operator.
   *
   * Requirements:
   *
   * - input must fit into 32 bits
   */
  function toUint32(uint256 value) internal pure returns (uint32) {
    require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
    return uint32(value);
  }

  /**
   * @dev Returns the downcasted uint24 from uint256, reverting on
   * overflow (when the input is greater than largest uint24).
   *
   * Counterpart to Solidity's `uint24` operator.
   *
   * Requirements:
   *
   * - input must fit into 24 bits
   */
  function toUint24(uint256 value) internal pure returns (uint24) {
    require(value < 2**24, "SafeCast: value doesn\'t fit in 24 bits");
    return uint24(value);
  }

  /**
   * @dev Returns the downcasted uint16 from uint256, reverting on
   * overflow (when the input is greater than largest uint16).
   *
   * Counterpart to Solidity's `uint16` operator.
   *
   * Requirements:
   *
   * - input must fit into 16 bits
   */
  function toUint16(uint256 value) internal pure returns (uint16) {
    require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
    return uint16(value);
  }

  /**
   * @dev Returns the downcasted uint8 from uint256, reverting on
   * overflow (when the input is greater than largest uint8).
   *
   * Counterpart to Solidity's `uint8` operator.
   *
   * Requirements:
   *
   * - input must fit into 8 bits.
   */
  function toUint8(uint256 value) internal pure returns (uint8) {
    require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
    return uint8(value);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

/**
 * @dev Simple library to derive the staking pool address from the pool id without external calls
 */
library StakingPoolLibrary {

  function getAddress(address factory, uint poolId) internal pure returns (address) {

    bytes32 hash = keccak256(
      abi.encodePacked(
        hex'ff',
        factory,
        poolId, // salt
        // init code hash of the MinimalBeaconProxy
        // updated using patch-staking-pool-library.js script
        hex'1eb804b66941a2e8465fa0951be9c8b855b7794ee05b0789ab22a02ee1298ebe' // init code hash
      )
    );

    // cast last 20 bytes of hash to address
    return address(uint160(uint(hash)));
  }

}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.18;

import "@openzeppelin/contracts-v4/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts-v4/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-v4/token/ERC20/utils/SafeERC20.sol";

import "../../abstract/MasterAwareV2.sol";
import "../../interfaces/ICover.sol";
import "../../interfaces/ICoverNFT.sol";
import "../../interfaces/IPool.sol";
import "../../interfaces/IStakingNFT.sol";
import "../../interfaces/IStakingPool.sol";
import "../../interfaces/IStakingPoolBeacon.sol";
import "../../interfaces/IStakingPoolFactory.sol";
import "../../interfaces/ITokenController.sol";
import "../../libraries/Math.sol";
import "../../libraries/SafeUintCast.sol";
import "../../libraries/StakingPoolLibrary.sol";
import "../../interfaces/IStakingProducts.sol";

contract Cover is ICover, MasterAwareV2, IStakingPoolBeacon, ReentrancyGuard {
  using SafeERC20 for IERC20;
  using SafeUintCast for uint;

  /* ========== STATE VARIABLES ========== */

  Product[] internal _products;
  ProductType[] internal _productTypes;

  mapping(uint => CoverData) private _coverData;

  // cover id => segment id => pool allocations array
  mapping(uint => mapping(uint => PoolAllocation[])) public coverSegmentAllocations;

  // product id => allowed pool ids
  mapping(uint => uint[]) public allowedPools;

  // Each cover has an array of segments. A new segment is created
  // every time a cover is edited to deliniate the different cover periods.
  mapping(uint => CoverSegment[]) private _coverSegments;

  // assetId => { lastBucketUpdateId, totalActiveCoverInAsset }
  mapping(uint => ActiveCover) public activeCover;
  // assetId => bucketId => amount
  mapping(uint => mapping(uint => uint)) internal activeCoverExpirationBuckets;

  // productId => product name
  mapping(uint => string) public productNames;
  // productTypeId => productType name
  mapping(uint => string) public productTypeNames;

  /* ========== CONSTANTS ========== */

  uint private constant GLOBAL_CAPACITY_RATIO = 20000; // 2
  uint private constant GLOBAL_REWARDS_RATIO = 5000; // 50%

  uint private constant PRICE_DENOMINATOR = 10000;
  uint private constant COMMISSION_DENOMINATOR = 10000;
  uint private constant CAPACITY_REDUCTION_DENOMINATOR = 10000;
  uint private constant GLOBAL_CAPACITY_DENOMINATOR = 10_000;
  uint private constant REWARD_DENOMINATOR = 10_000;

  uint private constant MAX_COVER_PERIOD = 365 days;
  uint private constant MIN_COVER_PERIOD = 28 days;
  uint private constant BUCKET_SIZE = 7 days;
  // this constant is used for calculating the normalized yearly percentage cost of cover
  uint private constant ONE_YEAR = 365 days;

  uint public constant MAX_COMMISSION_RATIO = 3000; // 30%

  uint public constant GLOBAL_MIN_PRICE_RATIO = 100; // 1%

  uint private constant ONE_NXM = 1e18;

  uint private constant ETH_ASSET_ID = 0;
  uint private constant NXM_ASSET_ID = type(uint8).max;

  // internally we store capacity using 2 decimals
  // 1 nxm of capacity is stored as 100
  uint private constant ALLOCATION_UNITS_PER_NXM = 100;

  // given capacities have 2 decimals
  // smallest unit we can allocate is 1e18 / 100 = 1e16 = 0.01 NXM
  uint public constant NXM_PER_ALLOCATION_UNIT = ONE_NXM / ALLOCATION_UNITS_PER_NXM;

  ICoverNFT public immutable override coverNFT;
  IStakingNFT public immutable override stakingNFT;
  IStakingPoolFactory public immutable override stakingPoolFactory;
  address public immutable stakingPoolImplementation;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    ICoverNFT _coverNFT,
    IStakingNFT _stakingNFT,
    IStakingPoolFactory _stakingPoolFactory,
    address _stakingPoolImplementation
  ) {
    // in constructor we only initialize immutable fields
    coverNFT = _coverNFT;
    stakingNFT = _stakingNFT;
    stakingPoolFactory = _stakingPoolFactory;
    stakingPoolImplementation = _stakingPoolImplementation;
  }

  /* === MUTATIVE FUNCTIONS ==== */

  function buyCover(
    BuyCoverParams memory params,
    PoolAllocationRequest[] memory poolAllocationRequests
  ) external payable onlyMember nonReentrant whenNotPaused returns (uint coverId) {

    if (params.period < MIN_COVER_PERIOD) {
      revert CoverPeriodTooShort();
    }

    if (params.period > MAX_COVER_PERIOD) {
      revert CoverPeriodTooLong();
    }

    if (params.commissionRatio > MAX_COMMISSION_RATIO) {
      revert CommissionRateTooHigh();
    }

    if (params.amount == 0) {
      revert CoverAmountIsZero();
    }

    uint segmentId;

    AllocationRequest memory allocationRequest;
    {
      if (_products.length <= params.productId) {
        revert ProductDoesntExist();
      }

      Product memory product = _products[params.productId];

      if (product.isDeprecated) {
        revert ProductDeprecated();
      }

      if (!isCoverAssetSupported(params.coverAsset, product.coverAssets)) {
        revert CoverAssetNotSupported();
      }

      allocationRequest = AllocationRequest(
        params.productId,
        coverId,
        0,
        params.period,
        _productTypes[product.productType].gracePeriod,
        product.useFixedPrice,
        0, // previous cover start
        0, // previous cover expiration
        0, // previous rewards ratio
        GLOBAL_CAPACITY_RATIO,
        product.capacityReductionRatio,
        GLOBAL_REWARDS_RATIO,
        GLOBAL_MIN_PRICE_RATIO
      );
    }

    uint previousSegmentAmount;

    if (params.coverId == 0) {

      // new cover
      coverId = coverNFT.mint(params.owner);
      _coverData[coverId] = CoverData(params.productId, params.coverAsset, 0 /* amountPaidOut */);

    } else {
      revert('Edit cover is not yet supported');

      /*
      // existing cover
      coverId = params.coverId;

      if (!coverNFT.isApprovedOrOwner(msg.sender, coverId)) {
        revert OnlyOwnerOrApproved();
      }

      CoverData memory cover = _coverData[coverId];

      if (params.coverAsset != cover.coverAsset) {
        revert UnexpectedCoverAsset();
      }

      if (params.productId != cover.productId) {
        revert UnexpectedProductId();
      }

      segmentId = _coverSegments[coverId].length;
      CoverSegment memory lastSegment = coverSegmentWithRemainingAmount(coverId, segmentId - 1);

      // require last segment not to be expired
      if (lastSegment.start + lastSegment.period <= block.timestamp) {
        revert ExpiredCoversCannotBeEdited();
      }

      allocationRequest.previousStart = lastSegment.start;
      allocationRequest.previousExpiration = lastSegment.start + lastSegment.period;
      allocationRequest.previousRewardsRatio = lastSegment.globalRewardsRatio;

      // mark previous cover as ending now
      _coverSegments[coverId][segmentId - 1].period = (block.timestamp - lastSegment.start).toUint32();

      // remove cover amount from from expiration buckets
      uint bucketAtExpiry = Math.divCeil(lastSegment.start + lastSegment.period, BUCKET_SIZE);
      activeCoverExpirationBuckets[params.coverAsset][bucketAtExpiry] -= lastSegment.amount;
      previousSegmentAmount += lastSegment.amount;
      */
    }

    uint nxmPriceInCoverAsset = pool().getTokenPriceInAsset(params.coverAsset);
    allocationRequest.coverId = coverId;

    (uint coverAmountInCoverAsset, uint amountDueInNXM) = requestAllocation(
      allocationRequest,
      poolAllocationRequests,
      nxmPriceInCoverAsset,
      segmentId
    );

    if (coverAmountInCoverAsset < params.amount) {
      revert InsufficientCoverAmountAllocated();
    }

    _coverSegments[coverId].push(
      CoverSegment(
        coverAmountInCoverAsset.toUint96(), // cover amount in cover asset
        block.timestamp.toUint32(), // start
        params.period, // period
        allocationRequest.gracePeriod.toUint32(),
        GLOBAL_REWARDS_RATIO.toUint24(),
        GLOBAL_CAPACITY_RATIO.toUint24()
      )
    );

    // Update totalActiveCover
    {
      ActiveCover memory _activeCover = activeCover[params.coverAsset];

      uint currentBucketId = block.timestamp / BUCKET_SIZE;
      uint totalActiveCover = _activeCover.totalActiveCoverInAsset;

      if (totalActiveCover != 0) {
        totalActiveCover -= getExpiredCoverAmount(
          params.coverAsset,
          _activeCover.lastBucketUpdateId,
          currentBucketId
        );
      }

      totalActiveCover -= previousSegmentAmount;
      totalActiveCover += coverAmountInCoverAsset;

      _activeCover.lastBucketUpdateId = currentBucketId.toUint64();
      _activeCover.totalActiveCoverInAsset = totalActiveCover.toUint192();

      // update total active cover in storage
      activeCover[params.coverAsset] = _activeCover;

      // update amount to expire at the end of this cover segment
      uint bucketAtExpiry = Math.divCeil(block.timestamp + params.period, BUCKET_SIZE);
      activeCoverExpirationBuckets[params.coverAsset][bucketAtExpiry] += coverAmountInCoverAsset;
    }

    // can pay with cover asset or nxm only
    if (params.paymentAsset != params.coverAsset && params.paymentAsset != NXM_ASSET_ID) {
      revert InvalidPaymentAsset();
    }

    retrievePayment(
      amountDueInNXM,
      params.paymentAsset,
      nxmPriceInCoverAsset,
      params.maxPremiumInAsset,
      params.commissionRatio,
      params.commissionDestination
    );

    emit CoverEdited(coverId, params.productId, segmentId, msg.sender, params.ipfsData);
  }

  function requestAllocation(
    AllocationRequest memory allocationRequest,
    PoolAllocationRequest[] memory poolAllocationRequests,
    uint nxmPriceInCoverAsset,
    uint segmentId
  ) internal returns (
    uint totalCoverAmountInCoverAsset,
    uint totalAmountDueInNXM
  ) {

    RequestAllocationVariables memory vars = RequestAllocationVariables(0, 0, 0, 0);
    uint totalCoverAmountInNXM;

    vars.previousPoolAllocationsLength = segmentId > 0
      ? coverSegmentAllocations[allocationRequest.coverId][segmentId - 1].length
      : 0;

    for (uint i = 0; i < poolAllocationRequests.length; i++) {

      // if there is a previous segment and this index is present on it
      if (vars.previousPoolAllocationsLength > i) {

        PoolAllocation memory previousPoolAllocation =
          coverSegmentAllocations[allocationRequest.coverId][segmentId - 1][i];

        // poolAllocationRequests must match the pools in the previous segment
        if (previousPoolAllocation.poolId != poolAllocationRequests[i].poolId) {
          revert UnexpectedPoolId();
        }

        // check if this request should be skipped, keeping the previous allocation
        if (poolAllocationRequests[i].skip) {
          coverSegmentAllocations[allocationRequest.coverId][segmentId].push(previousPoolAllocation);
          totalCoverAmountInNXM += previousPoolAllocation.coverAmountInNXM;
          continue;
        }

        vars.previousPremiumInNXM = previousPoolAllocation.premiumInNXM;
        vars.refund =
          previousPoolAllocation.premiumInNXM
          * (allocationRequest.previousExpiration - block.timestamp) // remaining period
          / (allocationRequest.previousExpiration - allocationRequest.previousStart); // previous period

        // get stored allocation id
        allocationRequest.allocationId = previousPoolAllocation.allocationId;
      } else {
        // request new allocation id
        allocationRequest.allocationId = 0;
      }

      // converting asset amount to nxm and rounding up to the nearest NXM_PER_ALLOCATION_UNIT
      uint coverAmountInNXM = Math.roundUp(
        Math.divCeil(poolAllocationRequests[i].coverAmountInAsset * ONE_NXM, nxmPriceInCoverAsset),
        NXM_PER_ALLOCATION_UNIT
      );

      (uint premiumInNXM, uint allocationId) = stakingPool(poolAllocationRequests[i].poolId).requestAllocation(
        coverAmountInNXM,
        vars.previousPremiumInNXM,
        allocationRequest
      );

      // omit deallocated pools from the segment
      if (coverAmountInNXM != 0) {
        coverSegmentAllocations[allocationRequest.coverId][segmentId].push(
          PoolAllocation(
            poolAllocationRequests[i].poolId,
            coverAmountInNXM.toUint96(),
            premiumInNXM.toUint96(),
            allocationId.toUint24()
          )
        );
      }

      totalAmountDueInNXM += (vars.refund >= premiumInNXM ? 0 : premiumInNXM - vars.refund);
      totalCoverAmountInNXM += coverAmountInNXM;
    }

    totalCoverAmountInCoverAsset = totalCoverAmountInNXM * nxmPriceInCoverAsset / ONE_NXM;

    return (totalCoverAmountInCoverAsset, totalAmountDueInNXM);
  }

  function retrievePayment(
    uint premiumInNxm,
    uint paymentAsset,
    uint nxmPriceInCoverAsset,
    uint maxPremiumInAsset,
    uint16 commissionRatio,
    address commissionDestination
  ) internal {

    if (paymentAsset != ETH_ASSET_ID && msg.value > 0) {
      revert UnexpectedEthSent();
    }

    // NXM payment
    if (paymentAsset == NXM_ASSET_ID) {
      if (premiumInNxm > maxPremiumInAsset) {
        revert PriceExceedsMaxPremiumInAsset();
      }

      ITokenController _tokenController = tokenController();
      _tokenController.burnFrom(msg.sender, premiumInNxm);

      if (commissionRatio > 0) {
        uint commissionInNxm = premiumInNxm * commissionRatio / COMMISSION_DENOMINATOR;
        // commission transfer reverts if the commissionDestination is not a member
        _tokenController.operatorTransfer(msg.sender, commissionDestination, commissionInNxm);
      }

      return;
    }

    IPool _pool = pool();
    uint premiumInPaymentAsset = nxmPriceInCoverAsset * premiumInNxm / ONE_NXM;
    uint commission = premiumInPaymentAsset * commissionRatio / COMMISSION_DENOMINATOR;

    if (premiumInPaymentAsset > maxPremiumInAsset) {
      revert PriceExceedsMaxPremiumInAsset();
    }

    // ETH payment
    if (paymentAsset == ETH_ASSET_ID) {

      uint premiumWithCommission = premiumInPaymentAsset + commission;
      if (msg.value < premiumWithCommission) {
        revert InsufficientEthSent();
      }

      uint remainder = msg.value - premiumWithCommission;

      {
        // send premium in eth to the pool
        // solhint-disable-next-line avoid-low-level-calls
        (bool ok, /* data */) = address(_pool).call{value: premiumInPaymentAsset}("");
        if (!ok) {
          revert SendingEthToPoolFailed();
        }
      }

      // send commission
      if (commission > 0) {
        (bool ok, /* data */) = address(commissionDestination).call{value: commission}("");
        if (!ok) {
          revert SendingEthToCommissionDestinationFailed();
        }
      }

      if (remainder > 0) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool ok, /* data */) = address(msg.sender).call{value: remainder}("");
        if (!ok) {
          revert ReturningEthRemainderToSenderFailed();
        }
      }

      return;
    }

    address coverAsset = _pool.getAsset(paymentAsset).assetAddress;
    IERC20 token = IERC20(coverAsset);
    token.safeTransferFrom(msg.sender, address(_pool), premiumInPaymentAsset);

    if (commission > 0) {
      token.safeTransferFrom(msg.sender, commissionDestination, commission);
    }
  }

  function addLegacyCover(
    uint productId,
    uint coverAsset,
    uint amount,
    uint start,
    uint period,
    address newOwner
  ) external onlyInternal returns (uint coverId) {

    ProductType memory productType = _productTypes[_products[productId].productType];

    // uses the current v2 grace period
    if (block.timestamp >= start + period + productType.gracePeriod) {
      revert CoverOutsideOfTheGracePeriod();
    }

    coverId = coverNFT.mint(newOwner);
    _coverData[coverId] = CoverData(productId.toUint24(), coverAsset.toUint8(), 0 /* amountPaidOut */);

    uint bucketAtExpiry = Math.divCeil((start + period), BUCKET_SIZE);
    activeCoverExpirationBuckets[coverAsset][bucketAtExpiry] += amount;
    activeCover[coverAsset].totalActiveCoverInAsset += amount.toUint192();

    _coverSegments[coverId].push(
      CoverSegment(
        amount.toUint96(),
        start.toUint32(),
        period.toUint32(),
        productType.gracePeriod,
        0, // global rewards ratio
        1
      )
    );

    emit CoverEdited(coverId, productId, 0, msg.sender, "");

    return coverId;
  }

  function createStakingPool(
    bool isPrivatePool,
    uint initialPoolFee,
    uint maxPoolFee,
    ProductInitializationParams[] memory productInitParams,
    string calldata ipfsDescriptionHash
  ) external whenNotPaused returns (uint /*poolId*/, address /*stakingPoolAddress*/) {

    if (msg.sender != master.getLatestAddress("PS")) {

      // TODO: replace this with onlyMember modifier after the v2 release
      require(
        IMemberRoles(internalContracts[uint(ID.MR)]).checkRole(
          msg.sender,
          uint(IMemberRoles.Role.Member)
        ),
        "Caller is not a member"
      );

      // override with initial price
      for (uint i = 0; i < productInitParams.length; i++) {

        uint productId = productInitParams[i].productId;
        productInitParams[i].initialPrice = _products[productId].initialPriceRatio;

        if (productInitParams[i].targetPrice < GLOBAL_MIN_PRICE_RATIO) {
          revert TargetPriceBelowGlobalMinPriceRatio();
        }
      }
    }

    (uint poolId, address stakingPoolAddress) = stakingPoolFactory.create(address(this));

    IStakingPool(stakingPoolAddress).initialize(
      isPrivatePool,
      initialPoolFee,
      maxPoolFee,
      poolId,
      ipfsDescriptionHash
    );

    tokenController().assignStakingPoolManager(poolId, msg.sender);

    stakingProducts().setInitialProducts(poolId, productInitParams);

    return (poolId, stakingPoolAddress);
  }

  // Gets the total amount of active cover that is currently expired for this asset
  function getExpiredCoverAmount(
    uint coverAsset,
    uint lastUpdateId,
    uint currentBucketId
  ) internal view returns (uint amountExpired) {

    while (lastUpdateId < currentBucketId) {
      ++lastUpdateId;
      amountExpired += activeCoverExpirationBuckets[coverAsset][lastUpdateId];
    }

    return amountExpired;
  }

  function burnStake(
    uint coverId,
    uint segmentId,
    uint payoutAmountInAsset
  ) external onlyInternal override returns (address /* coverOwner */) {

    CoverData storage cover = _coverData[coverId];
    ActiveCover storage _activeCover = activeCover[cover.coverAsset];
    CoverSegment memory segment = coverSegmentWithRemainingAmount(coverId, segmentId);
    PoolAllocation[] storage allocations = coverSegmentAllocations[coverId][segmentId];

    // update expired buckets and calculate the amount of active cover that should be burned
    {
      uint coverAsset = cover.coverAsset;
      uint lastUpdateBucketId = _activeCover.lastBucketUpdateId;
      uint currentBucketId = block.timestamp / BUCKET_SIZE;

      uint burnedSegmentBucketId = Math.divCeil((segment.start + segment.period), BUCKET_SIZE);
      uint activeCoverToExpire = getExpiredCoverAmount(coverAsset, lastUpdateBucketId, currentBucketId);

      // if the segment has not expired - it's still accounted for in total active cover
      if (burnedSegmentBucketId > currentBucketId) {
        uint amountToSubtract = Math.min(payoutAmountInAsset, segment.amount);
        activeCoverToExpire += amountToSubtract;
        activeCoverExpirationBuckets[coverAsset][burnedSegmentBucketId] -= amountToSubtract.toUint192();
      }

      _activeCover.totalActiveCoverInAsset -= activeCoverToExpire.toUint192();
      _activeCover.lastBucketUpdateId = currentBucketId.toUint64();
    }

    // increase amountPaidOut only *after* you read the segment
    cover.amountPaidOut += payoutAmountInAsset.toUint96();

    uint allocationCount = allocations.length;

    for (uint i = 0; i < allocationCount; i++) {
      PoolAllocation memory allocation = allocations[i];

      uint deallocationAmountInNXM = allocation.coverAmountInNXM * payoutAmountInAsset / segment.amount;
      uint burnAmountInNxm = deallocationAmountInNXM * GLOBAL_CAPACITY_DENOMINATOR / segment.globalCapacityRatio;

      allocations[i].coverAmountInNXM -= deallocationAmountInNXM.toUint96();
      allocations[i].premiumInNXM -= (allocation.premiumInNXM * payoutAmountInAsset / segment.amount).toUint96();

      BurnStakeParams memory params = BurnStakeParams(
        allocation.allocationId,
        cover.productId,
        segment.start,
        segment.period,
        deallocationAmountInNXM
      );

      uint poolId = allocations[i].poolId;
      stakingPool(poolId).burnStake(burnAmountInNxm, params);
    }

    return coverNFT.ownerOf(coverId);
  }

  /* ========== VIEWS ========== */

  function stakingPool(uint poolId) public view returns (IStakingPool) {
    return IStakingPool(
      StakingPoolLibrary.getAddress(address(stakingPoolFactory), poolId)
    );
  }

  function coverData(uint coverId) external override view returns (CoverData memory) {
    return _coverData[coverId];
  }

  function coverSegmentWithRemainingAmount(
    uint coverId,
    uint segmentId
  ) public override view returns (CoverSegment memory) {
    CoverSegment memory segment = _coverSegments[coverId][segmentId];
    uint96 amountPaidOut = _coverData[coverId].amountPaidOut;
    segment.amount = segment.amount >= amountPaidOut
      ? segment.amount - amountPaidOut
      : 0;
    return segment;
  }

  function coverSegments(uint coverId) external override view returns (CoverSegment[] memory) {
    return _coverSegments[coverId];
  }

  function coverSegmentsCount(uint coverId) external override view returns (uint) {
    return _coverSegments[coverId].length;
  }

  function coverDataCount() external override view returns (uint) {
    return coverNFT.totalSupply();
  }

  function products(uint id) external override view returns (Product memory) {
    return _products[id];
  }

  function productsCount() external override view returns (uint) {
    return _products.length;
  }

  function getProducts() external view returns (Product[] memory) {
    return _products;
  }

  function productTypes(uint id) external override view returns (ProductType memory) {
    return _productTypes[id];
  }

  function productTypesCount() external override view returns (uint) {
    return _productTypes.length;
  }

  /* ========== PRODUCT CONFIGURATION ========== */

  function setProducts(ProductParam[] calldata productParams) external override onlyAdvisoryBoard {

    uint unsupportedCoverAssetsBitmap = type(uint).max;


    Asset[] memory assets = pool().getAssets();
    uint assetsLength = assets.length;

    for (uint i = 0; i < assetsLength; i++) {
      if (assets[i].isCoverAsset && !assets[i].isAbandoned) {
        // clear the bit at index i
        unsupportedCoverAssetsBitmap ^= 1 << i;
      }
    }

    for (uint i = 0; i < productParams.length; i++) {

      ProductParam calldata param = productParams[i];
      Product calldata product = param.product;

      if (product.productType >= _productTypes.length) {
        revert InvalidProductType();
      }

      if (unsupportedCoverAssetsBitmap & product.coverAssets != 0) {
        revert UnsupportedCoverAssets();
      }

      if (product.initialPriceRatio < GLOBAL_MIN_PRICE_RATIO) {
        revert InitialPriceRatioBelowGlobalMinPriceRatio();
      }

      if (product.initialPriceRatio > PRICE_DENOMINATOR) {
        revert InitialPriceRatioAbove100Percent();
      }

      if (product.capacityReductionRatio > CAPACITY_REDUCTION_DENOMINATOR) {
        revert CapacityReductionRatioAbove100Percent();
      }

      if (product.useFixedPrice) {
        uint productId = param.productId == type(uint256).max ? _products.length : param.productId;
        allowedPools[productId] = param.allowedPools;
      }

      // New product has id == uint256.max
      if (param.productId == type(uint256).max) {
        emit ProductSet(_products.length, param.ipfsMetadata);
        productNames[_products.length] = param.productName;
        _products.push(product);
        continue;
      }

      // Existing product
      if (param.productId >= _products.length) {
        revert ProductDoesntExist();
      }
      Product storage newProductValue = _products[param.productId];
      newProductValue.isDeprecated = product.isDeprecated;
      newProductValue.coverAssets = product.coverAssets;
      newProductValue.initialPriceRatio = product.initialPriceRatio;
      newProductValue.capacityReductionRatio = product.capacityReductionRatio;

      if (bytes(param.productName).length > 0) {
        productNames[param.productId] = param.productName;
      }

      if (bytes(param.ipfsMetadata).length > 0) {
        emit ProductSet(param.productId, param.ipfsMetadata);
      }
    }
  }

  function setProductTypes(ProductTypeParam[] calldata productTypeParams) external onlyAdvisoryBoard {

    for (uint i = 0; i < productTypeParams.length; i++) {
      ProductTypeParam calldata param = productTypeParams[i];

      // New product has id == uint256.max
      if (param.productTypeId == type(uint256).max) {
        emit ProductTypeSet(_productTypes.length, param.ipfsMetadata);
        productTypeNames[_productTypes.length] = param.productTypeName;
        _productTypes.push(param.productType);
        continue;
      }

      if (param.productTypeId >= _productTypes.length) {
        revert ProductTypeNotFound();
      }
      _productTypes[param.productTypeId].gracePeriod = param.productType.gracePeriod;

      if (bytes(param.productTypeName).length > 0) {
        productTypeNames[param.productTypeId] = param.productTypeName;
      }

      if (bytes(param.ipfsMetadata).length > 0) {
        emit ProductTypeSet(param.productTypeId, param.ipfsMetadata);
      }
    }
  }

  /* ========== COVER ASSETS HELPERS ========== */

  function totalActiveCoverInAsset(uint assetId) public view returns (uint) {
    return uint(activeCover[assetId].totalActiveCoverInAsset);
  }

  function isPoolAllowed(uint productId, uint poolId) external view returns (bool) {

    uint poolCount = allowedPools[productId].length;

    if (poolCount == 0) {
      return true;
    }

    for (uint i = 0; i < poolCount; i++) {
      if (allowedPools[productId][i] == poolId) {
        return true;
      }
    }

    return false;
  }

  function globalCapacityRatio() external pure returns (uint) {
    return GLOBAL_CAPACITY_RATIO;
  }

  function globalRewardsRatio() external pure returns (uint) {
    return GLOBAL_REWARDS_RATIO;
  }

  function getPriceAndCapacityRatios(uint[] calldata productIds) public view returns (
    uint _globalCapacityRatio,
    uint _globalMinPriceRatio,
    uint[] memory _initialPrices,
    uint[] memory _capacityReductionRatios
  ) {
    _globalMinPriceRatio = GLOBAL_MIN_PRICE_RATIO;
    _globalCapacityRatio = GLOBAL_CAPACITY_RATIO;
    _capacityReductionRatios = new uint[](productIds.length);
    _initialPrices = new uint[](productIds.length);

    for (uint i = 0; i < productIds.length; i++) {
      Product memory product = _products[productIds[i]];
      if (product.initialPriceRatio == 0) {
        revert ProductDeprecatedOrNotInitialized();
      }
      _initialPrices[i] = uint(product.initialPriceRatio);
      _capacityReductionRatios[i] = uint(product.capacityReductionRatio);
    }
  }

  function isCoverAssetSupported(uint assetId, uint productCoverAssetsBitmap) internal view returns (bool) {

    if (
      // product does not use default cover assets
      productCoverAssetsBitmap != 0 &&
      // asset id is not in the product's cover assets bitmap
      ((1 << assetId) & productCoverAssetsBitmap == 0)
    ) {
      return false;
    }

    Asset memory asset = pool().getAsset(assetId);

    return asset.isCoverAsset && !asset.isAbandoned;
  }

  /* ========== DEPENDENCIES ========== */

  function pool() internal view returns (IPool) {
    return IPool(internalContracts[uint(ID.P1)]);
  }

  function tokenController() internal view returns (ITokenController) {
    return ITokenController(internalContracts[uint(ID.TC)]);
  }

  function memberRoles() internal view returns (IMemberRoles) {
    return IMemberRoles(internalContracts[uint(ID.MR)]);
  }

  function stakingProducts() internal view returns (IStakingProducts) {
    return IStakingProducts(getInternalContractAddress(ID.SP));
  }

  function changeDependentContractAddress() external override {
    internalContracts[uint(ID.P1)] = master.getLatestAddress("P1");
    internalContracts[uint(ID.TC)] = master.getLatestAddress("TC");
    internalContracts[uint(ID.MR)] = master.getLatestAddress("MR");
    internalContracts[uint(ID.SP)] = master.getLatestAddress("SP");
  }
}