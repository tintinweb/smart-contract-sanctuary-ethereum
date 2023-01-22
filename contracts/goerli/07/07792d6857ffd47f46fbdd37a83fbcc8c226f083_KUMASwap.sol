// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKUMABondToken is IERC721 {
    event BondIssued(bytes4 indexed currency, bytes4 indexed country, uint96 indexed term, uint256 id);

    event BondRedeemed(bytes4 indexed currency, bytes4 indexed country, uint96 indexed term, uint256 id);

    /**
     * @param cusip Bond CUISP number.
     * @param isin Bond ISIN number.
     * @param currency Currency of the bond - example : USD
     * @param country Treasury issuer - example : US
     * @param term Lifetime of the bond ie maturity in seconds - issuance date - example : 10 years
     * @param issuance Bond issuance date - timestamp in seconds
     * @param maturity Date on which the principal amount becomes due - timestamp is seconds
     * @param coupon Annual interest rate paid on the bond per - rate per second
     * @param principal Bond face value ie redeemable amount
     * @param riskCategory Unique risk category identifier computed with keccack256(abi.encode(currency, country, term))
     */
    struct Bond {
        bytes16 cusip;
        bytes16 isin;
        bytes4 currency;
        bytes4 country;
        uint64 term;
        uint64 issuance;
        uint64 maturity;
        uint256 coupon;
        uint256 principal;
        bytes32 riskCategory;
    }

    function issueBond(address to, Bond calldata bond) external;

    function redeem(uint256 tokenId) external;

    function pause() external;

    function unpause() external;

    function getTokenIdCounter() external view returns (uint256);

    function getBond(uint256) external view returns (Bond memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

interface MCAGAggregatorInterface {
    event AnswerTransmitted(address indexed transmitter, uint80 roundId, int256 answer);
    event MaxAnswerSet(int256 oldMaxAnswer, int256 newMaxAnswer);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function maxAnswer() external view returns (int256);

    function version() external view returns (uint8);

    function transmit(int256 answer) external;

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "src/libraries/Errors.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IKUMABondToken} from "@mcag/interfaces/IKUMABondToken.sol";
import {IKIBTAddressProvider} from "src/interfaces/IKIBTAddressProvider.sol";
import {IKBCToken} from "src/interfaces/IKBCToken.sol";
import {IKIBToken} from "src/interfaces/IKIBToken.sol";
import {IKUMASwap} from "src/interfaces/IKUMASwap.sol";
import {IMCAGPriceFeed} from "src/interfaces/IMCAGPriceFeed.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";
import {Roles} from "src/libraries/Roles.sol";
import {WadRayMath} from "src/libraries/WadRayMath.sol";

contract KUMASwap is IKUMASwap, Pausable {
    using EnumerableSet for EnumerableSet.UintSet;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    uint256 public constant MIN_ALLOWED_COUPON = WadRayMath.RAY;
    uint256 public constant DEPRECATION_MODE_TIMELOCK = 2 days;

    bytes32 public immutable override riskCategory;
    uint16 public immutable override maxCoupons;
    IKIBTAddressProvider public immutable override KIBTAddressProvider;

    bool private _isDeprecated;
    uint56 private _deprecationInitializedAt;
    uint16 private _variableFee;
    IERC20 private _deprecationStableCoin;
    uint256 private _fixedFee;
    uint256 private _minGas;
    uint256 private _minCoupon;
    uint256 private _referenceRate;
    uint256 private _cloneCouponUpdateTracker;

    // @notice Set of unique coupons in reserve
    EnumerableSet.UintSet private _coupons;
    // @notice Set of all token ids in reserve
    EnumerableSet.UintSet private _bondReserve;

    // @notice KUMABondToken id to KBCToken id
    mapping(uint256 => uint256) private _cloneBonds;
    // @notice Quantity of each coupon in reserve
    mapping(uint256 => uint256) private _couponInventory;
    // @notice Bool true if a bond have been expire to expired bond id
    mapping(bool => uint256) private _isExpired;
    // @notice Token Id to current clone coupon
    mapping(uint256 => uint256) private _cloneCoupons;

    modifier onlyRole(bytes32 role) {
        if (!IAccessControl(KIBTAddressProvider.accessController()).hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    modifier whenNotDeprecated() {
        if (_isDeprecated) {
            revert Errors.DEPRECATION_MODE_ENABLED();
        }
        _;
    }

    modifier whenDeprecated() {
        if (!_isDeprecated) {
            revert Errors.DEPRECATION_MODE_NOT_ENABLED();
        }
        _;
    }

    /**
     * @param _KIBTAddressProvider KIBTAddressProvider.
     * @param currency Underlying bonds currency.
     * @param country Underlying bonds treasury issuer.
     * @param term Underling bonds term.
     */
    constructor(
        IKIBTAddressProvider _KIBTAddressProvider,
        IERC20 deprecationStableCoin,
        bytes4 currency,
        bytes4 country,
        uint64 term
    ) {
        if (address(_KIBTAddressProvider) == address(0) || address(deprecationStableCoin) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (currency == bytes4(0) || country == bytes4(0) || term == 0) {
            revert Errors.WRONG_RISK_CATEGORY();
        }
        KIBTAddressProvider = _KIBTAddressProvider;
        maxCoupons = uint16(term / 30 days);
        riskCategory = keccak256(abi.encode(currency, country, term));
        _minCoupon = MIN_ALLOWED_COUPON;
        _minGas = 100000;
        _deprecationStableCoin = deprecationStableCoin;
    }

    /**
     * @notice Sells a bond against KIBToken.
     * @param tokenId Sold bond tokenId.
     */
    function sellBond(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        if (_coupons.length() == maxCoupons) {
            revert Errors.MAX_COUPONS_REACHED();
        }
        IKIBTAddressProvider _KIBTAddressProvider = KIBTAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(_KIBTAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);

        if (_KIBTAddressProvider.getKUMASwap(bond.riskCategory) != address(this)) {
            revert Errors.WRONG_RISK_CATEGORY();
        }

        if (bond.maturity <= block.timestamp) {
            revert Errors.CANNOT_SELL_MATURED_BOND();
        }

        IKIBToken KIBToken = IKIBToken(_KIBTAddressProvider.getKIBToken(riskCategory));
        uint256 currentYield = KIBToken.getYield();
        uint256 referenceRate = IMCAGPriceFeed(_KIBTAddressProvider.getPriceFeed()).getRate(riskCategory);

        if (bond.coupon < referenceRate || bond.coupon < currentYield) {
            revert Errors.COUPON_TOO_LOW();
        }

        currentYield = _isExpired[true] != 0 || _coupons.length() == 0 ? referenceRate : currentYield;

        uint256 coupon = bond.coupon;

        if (bond.coupon > currentYield && referenceRate >= currentYield) {
            coupon = currentYield;
            _cloneCoupons[tokenId] = currentYield;
            emit GhostCouponSet(tokenId, currentYield);
        }

        if (referenceRate < currentYield) {
            coupon = referenceRate;
        }

        if (_coupons.length() == 0) {
            _minCoupon = bond.coupon;
            _coupons.add(bond.coupon);
        } else {
            if (bond.coupon < _minCoupon) {
                _minCoupon = bond.coupon;
            }
            if (!_coupons.contains(bond.coupon)) {
                _coupons.add(bond.coupon);
            }
        }

        _couponInventory[bond.coupon]++;
        _bondReserve.add(tokenId);

        (uint256 bondValue) = _getBondValue(bond.issuance, bond.term, coupon, bond.principal);

        uint256 fee = _calculateFees(bondValue);

        uint256 mintAmount = bondValue;

        if (fee > 0) {
            mintAmount = bondValue - fee;
            KIBToken.mint(KIBTAddressProvider.getKIBTFeeCollector(riskCategory), fee);
        }

        KIBToken.mint(msg.sender, mintAmount);
        KUMABondToken.safeTransferFrom(msg.sender, address(this), tokenId);

        emit FeeCharged(fee);
        emit BondSold(tokenId, mintAmount, msg.sender);
    }

    /**
     * @notice Buys a bond against KIBToken.
     * @param tokenId Bought bond tokenId.
     */
    function buyBond(uint256 tokenId) external override whenNotPaused whenNotDeprecated {
        IKIBTAddressProvider _KIBTAddressProvider = KIBTAddressProvider;
        IKUMABondToken KUMABondToken = IKUMABondToken(_KIBTAddressProvider.getKUMABondToken());
        IKUMABondToken.Bond memory bond = KUMABondToken.getBond(tokenId);

        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        if (_couponInventory[bond.coupon] == 1) {
            _coupons.remove(bond.coupon);
        }

        _couponInventory[bond.coupon]--;
        _bondReserve.remove(tokenId);

        if (_isExpired[true] == tokenId) {
            delete _isExpired[true];
        }

        // If there is a clone bond coupon issue clone bond if not then regular buy

        IKIBToken KIBToken = IKIBToken(_KIBTAddressProvider.getKIBToken(riskCategory));
        uint256 referenceRate = IMCAGPriceFeed(_KIBTAddressProvider.getPriceFeed()).getRate(riskCategory);
        uint256 currentYield = KIBToken.getYield();
        uint256 coupon = bond.coupon;

        bool hasGhostCoupon =
            _cloneCoupons[tokenId] != 0 || (bond.coupon > referenceRate && referenceRate < currentYield);

        if (hasGhostCoupon) {
            coupon = _cloneCoupons[tokenId];
            if (coupon == 0) {
                coupon = referenceRate;
            }
            uint256 gBondId = IKBCToken(_KIBTAddressProvider.getKBCToken()).issueBond(
                msg.sender, IKBCToken.CloneBond({parentId: tokenId, coupon: coupon})
            );
            _cloneBonds[tokenId] = gBondId;
            _bondReserve.remove(tokenId);
        }

        _updateMinCoupon();

        uint256 bondValue = _getBondValue(bond.issuance, bond.term, coupon, bond.principal);
        KIBToken.burn(msg.sender, bondValue);

        if (!hasGhostCoupon) {
            KUMABondToken.safeTransferFrom(address(this), msg.sender, tokenId);
        }

        emit BondBought(tokenId, bondValue, msg.sender);
    }

    /**
     * @notice Buys a bond against _deprecationStableCoin.
     * @dev Requires an approval on amount from buyer. This will also result in some stale state for the contract on _coupons
     * and _minCoupon but this is acceptable as deprecation mode is irreversible. This function also ignores any existing clone bond
     * which is the intended bahaviour as bonds will be valued per their market rate offchain.
     * @param tokenId Bought bond tokenId.
     * @param buyer Bought bond buyer.
     * @param amount Stable coin price paid by the buyer.
     */
    function buyBondForStableCoin(uint256 tokenId, address buyer, uint256 amount)
        external
        override
        onlyRole(Roles.MANAGER_ROLE)
        whenDeprecated
    {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }
        if (buyer == address(0)) {
            revert Errors.BUYER_CANNOT_BE_ADDRESS_ZERO();
        }
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }

        _bondReserve.remove(tokenId);

        _deprecationStableCoin.safeTransferFrom(buyer, address(this), amount);
        IKUMABondToken(KIBTAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), buyer, tokenId);

        emit BondBought(tokenId, amount, buyer);
    }

    /**
     * @notice Claims a bond against a CloneBond.
     * @dev Can only by called by a MIBT_SWAP_CLAIM_ROLE address.
     * @param tokenId Claimed bond tokenId.
     */
    function claimBond(uint256 tokenId) external override onlyRole(Roles.MIBT_SWAP_CLAIM_ROLE) {
        IKIBTAddressProvider _KIBTAddressProvider = KIBTAddressProvider;

        if (_cloneBonds[tokenId] == 0) {
            revert Errors.BOND_NOT_AVAILABLE_FOR_CLAIM();
        }

        uint256 gBondId = _cloneBonds[tokenId];
        delete _cloneBonds[tokenId];

        IKBCToken(_KIBTAddressProvider.getKBCToken()).redeem(gBondId);
        IKUMABondToken(_KIBTAddressProvider.getKUMABondToken()).safeTransferFrom(address(this), msg.sender, tokenId);

        emit BondClaimed(tokenId, gBondId);
    }

    /**
     * @notice Redeems KIBToken against deprecation mode stable coin. Redeem stable coin amount is calculated as follow :
     *                          KIBTokenAmount
     *      redeemAmount = ------------------------ * KUMASwapStableCoinBalance
     *                        KIBTokenTotalSupply
     * @dev Can only be called if deprecation mode is enabled.
     * @param amount Amount of KIBToken to redeem.
     */
    function redeemMIBT(uint256 amount) external override whenDeprecated {
        if (amount == 0) {
            revert Errors.AMOUNT_CANNOT_BE_ZERO();
        }
        if (_bondReserve.length() != 0) {
            revert Errors.BOND_RESERVE_NOT_EMPTY();
        }
        IKIBToken KIBToken = IKIBToken(KIBTAddressProvider.getKIBToken(riskCategory));
        IERC20 deprecationStableCoin = _deprecationStableCoin;

        uint256 redeemAmount =
            amount.wadMul(_deprecationStableCoin.balanceOf(address(this))).wadDiv(KIBToken.totalSupply());
        KIBToken.burn(msg.sender, amount);
        deprecationStableCoin.safeTransfer(msg.sender, redeemAmount);

        emit MIBTRedeemed(msg.sender, redeemAmount);
    }

    /**
     * @notice Expires a bond if it has reached maturity by setting _minCoupon to MIN_ALLOWED_COUPON.
     * @param tokenId Claimed bond tokenId.
     */
    function expireBond(uint256 tokenId) external override whenNotDeprecated {
        if (!_bondReserve.contains(tokenId)) {
            revert Errors.INVALID_TOKEN_ID();
        }

        IKIBTAddressProvider _KIBTAddressProvider = KIBTAddressProvider;

        if (IKUMABondToken(_KIBTAddressProvider.getKUMABondToken()).getBond(tokenId).maturity <= block.timestamp) {
            _isExpired[true] = tokenId;

            IKIBToken(_KIBTAddressProvider.getKIBToken(riskCategory)).refreshYield();

            emit BondExpired(tokenId);
        }
    }

    /**
     * @notice Updates the current _cloneCoupons per the following rule :
     * if coupon of bond in reserve > reference rate => clone coupon = reference rate.
     * @dev Can only be called when contract is paused which will happen in the event of a reference
     * rate decrease.
     */
    function updateCloneBondCoupons() external override whenPaused {
        IKUMABondToken KUMABondToken = IKUMABondToken(KIBTAddressProvider.getKUMABondToken());
        uint256 referenceRate = _referenceRate;
        uint256 bondReserveLength = _bondReserve.length();
        uint256 minGas = _minGas;
        for (uint256 i = _cloneCouponUpdateTracker; i < bondReserveLength;) {
            uint256 tokenId = _bondReserve.at(i);
            if (KUMABondToken.getBond(tokenId).coupon > referenceRate) {
                _cloneCoupons[tokenId] = referenceRate;
                emit GhostCouponSet(tokenId, referenceRate);
            }
            if (i == bondReserveLength - 1) {
                _cloneCouponUpdateTracker = 0;
                _unpause();
                break;
            }
            if (gasleft() < minGas) {
                _cloneCouponUpdateTracker = i;
                break;
            }

            // Will require a limit on the set length
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {Pausable-_pause}.
     */
    function pause() external override onlyRole(Roles.MIBT_SWAP_PAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     */
    function unpause() external override onlyRole(Roles.MIBT_SWAP_UNPAUSE_ROLE) {
        _unpause();
    }

    /**
     * @notice Set fees that will be charges upon bond sale per the following formula :
     * totalFee = bondValue * variableFee + fixedFee.
     * @param variableFee in basis points.
     * @param fixedFee in KIBToken decimals.
     */
    function setFees(uint16 variableFee, uint256 fixedFee) external override onlyRole(Roles.MANAGER_ROLE) {
        _variableFee = variableFee;
        _fixedFee = fixedFee;
        emit FeeSet(variableFee, fixedFee);
    }

    /**
     * @notice Sets a new minumum gas value for the updateCloneBondCoupons function.
     * @param minGas New minimum gas value.
     */
    function setMinGas(uint256 minGas) external override onlyRole(Roles.MANAGER_ROLE) {
        if (minGas == 0) {
            revert Errors.CANNOT_SET_TO_ZERO();
        }
        emit MinGasSet(_minGas, minGas);
        _minGas = minGas;
    }

    /**
     * @notice Sets a new stable coin to be accepted during deprecation mode.
     * @param newDeprecationStableCoin New stable coin.
     */
    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin)
        external
        override
        onlyRole(Roles.MANAGER_ROLE)
        whenNotDeprecated
    {
        if (address(newDeprecationStableCoin) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        emit DeprecationStableCoinSet(address(_deprecationStableCoin), address(newDeprecationStableCoin));
        _deprecationStableCoin = newDeprecationStableCoin;
    }

    /**
     * @notice Initializes deprecation mode.
     */
    function initializeDeprecationMode() external override onlyRole(Roles.MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt != 0) {
            revert Errors.DEPRECATION_MODE_ALREADY_INITIALIZED();
        }

        _deprecationInitializedAt = uint56(block.timestamp);

        emit DeprecationModeInitialized();
    }

    /**
     * @notice Cancel the initialization of the deprecation mode.
     */
    function uninitializeDeprecationMode() external onlyRole(Roles.MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        _deprecationInitializedAt = 0;

        emit DeprecationModeUninitialized();
    }

    /**
     * @notice Enables deprecation.
     * @dev Deprecation mode must have been initialized at least 2 days before through the initializeDeprecationMode function.
     */
    function enableDeprecationMode() external override onlyRole(Roles.MANAGER_ROLE) whenNotDeprecated {
        if (_deprecationInitializedAt == 0) {
            revert Errors.DEPRECATION_MODE_NOT_INITIALIZED();
        }

        uint256 elapsedTime = block.timestamp - _deprecationInitializedAt;

        if (elapsedTime < DEPRECATION_MODE_TIMELOCK) {
            revert Errors.ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(
                elapsedTime, DEPRECATION_MODE_TIMELOCK
            );
        }

        _isDeprecated = true;

        IKIBToken(KIBTAddressProvider.getKIBToken(riskCategory)).refreshYield();

        emit DeprecationModeEnabled();
    }

    /**
     * @notice Sets the new reference rate which will be used to set clone coupons in `updateCloneBondCoupons`.
     * @dev This function will pause the contract.
     * @param referenceRate New lowest oracle rate.
     */
    function setReferenceRate(uint256 referenceRate) external {
        if (msg.sender != KIBTAddressProvider.getKIBToken(riskCategory)) {
            revert Errors.CALLER_IS_NOT_MIB_TOKEN();
        }
        _referenceRate = referenceRate;
        _pause();
        emit ReferenceRateSet(referenceRate);
    }

    /**
     * @return True if deprecation mode has been initialized false if not.
     */
    function isDeprecationInitialized() external view override returns (bool) {
        return _deprecationInitializedAt != 0;
    }

    /**
     * @return Timestamp of deprecation mode initialization.
     */
    function getDeprecationInitializedAt() external view override returns (uint56) {
        return _deprecationInitializedAt;
    }

    /**
     * @return True if deprecation mode has been enabled false if not.
     */
    function isDeprecated() external view override returns (bool) {
        return _isDeprecated;
    }

    /**
     * @return _varibaleFee Variable fee in basis points.
     */
    function getVariableFee() external view override returns (uint16) {
        return _variableFee;
    }

    /**
     * @return _deprecationStableCoin Accepted stable coin during deprecation mode.
     */
    function getDeprecationStableCoin() external view override returns (IERC20) {
        return _deprecationStableCoin;
    }

    /**
     * @return _fixedFee Fixed fee in KIBToken decimals.
     */
    function getFixedFee() external view override returns (uint256) {
        return _fixedFee;
    }

    /**
     * @return _minGas Minimum gas value used as a break condition in the updateCloneBondCoupons function loop.
     */
    function getMinGas() external view override returns (uint256) {
        return _minGas;
    }

    /**
     * @return Lowest coupon of bonds in reserve.
     */
    function getMinCoupon() external view override returns (uint256) {
        return _minCoupon;
    }

    /**
     * @notice The _referenceRate state variable is not necessarly up to date with the latest oracle rate.
     * It is set only when a call meets the condtion where the KIBToken calls the setReferenceRate function.
     * @return _referenceRate Set rate serving as pivot for the updateCloneBondCoupons function.
     */
    function getReferenceRate() external view override returns (uint256) {
        return _referenceRate;
    }

    /**
     * @notice The _cloneCouponUpdateTracker goal is to track the updateCloneBondCoupons loop index in order to enable
     * an update over multiple blocks.
     * @return _cloneCouponUpdateTracker updateCloneBondCoupons loop index tracker.
     */
    function getGhostCouponUpdateTracker() external view override returns (uint256) {
        return _cloneCouponUpdateTracker;
    }

    /**
     * @return Array of all coupons in reserve.
     */
    function getCoupons() external view override returns (uint256[] memory) {
        return _coupons.values();
    }

    /**
     * @return Index of coupon in the _coupons Set.
     */
    function getCouponIndex(uint256 coupon) external view override returns (uint256) {
        return _coupons._inner._indexes[bytes32(coupon)];
    }

    /**
     * @return Array of all tokenIds in reserve.
     */
    function getBondReserve() external view override returns (uint256[] memory) {
        return _bondReserve.values();
    }

    /**
     * @return Index of tokenId in the _bondReserve Array.
     */
    function getBondIndex(uint256 tokenId) external view override returns (uint256) {
        return _bondReserve._inner._indexes[bytes32(tokenId)];
    }

    /**
     * @return CloneBond Id of parent tokenId.
     */
    function getGhostBond(uint256 tokenId) external view override returns (uint256) {
        return _cloneBonds[tokenId];
    }

    /**
     * @return Amount of bonds with coupon value in inventory.
     */
    function getCouponInventory(uint256 coupon) external view override returns (uint256) {
        return _couponInventory[coupon];
    }

    /**
     * @return True if bond is in reserve false if not.
     */
    function isInReserve(uint256 tokenId) external view override returns (bool) {
        return _bondReserve.contains(tokenId);
    }

    /**
     * @return True if reserve has an expired bond false if not.
     */
    function isExpired() external view override returns (bool) {
        return _isExpired[true] != 0;
    }

    /**
     * @return Current clone coupon for a specific token id.
     */
    function getCloneCoupon(uint256 tokenId) external view override returns (uint256) {
        return _cloneCoupons[tokenId];
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @return bondValue Bond principal value + accrued interests.
     */
    function _getBondValue(uint256 issuance, uint256 term, uint256 coupon, uint256 principal)
        private
        view
        returns (uint256)
    {
        uint256 previousEpochTimestamp =
            IKIBToken(KIBTAddressProvider.getKIBToken(riskCategory)).getPreviousEpochTimestamp();

        if (previousEpochTimestamp <= issuance) {
            return principal;
        }

        uint256 elapsedTime = previousEpochTimestamp - issuance;

        if (elapsedTime > term) {
            elapsedTime = term;
        }

        return coupon.rayPow(elapsedTime).rayMul(principal.wadToRay()).rayToWad();
    }

    /**
     * @return minCoupon Lowest coupon of bonds in reserve.
     */
    function _updateMinCoupon() private returns (uint256) {
        uint256 currentMinCoupon = _minCoupon;

        if (_coupons.length() == 0) {
            _minCoupon = MIN_ALLOWED_COUPON;
            emit MinCouponUpdated(currentMinCoupon, MIN_ALLOWED_COUPON);
            return MIN_ALLOWED_COUPON;
        }

        if (_couponInventory[currentMinCoupon] != 0) {
            return currentMinCoupon;
        }

        uint256 minCoupon = _coupons.at(0);

        for (uint256 i = 1; i < _coupons.length();) {
            uint256 coupon = _coupons.at(i);

            if (coupon < minCoupon) {
                minCoupon = coupon;
            }

            unchecked {
                ++i;
            }
        }

        _minCoupon = minCoupon;

        emit MinCouponUpdated(currentMinCoupon, minCoupon);

        return minCoupon;
    }

    /**
     * @return fee Based on a specific amount.
     */
    function _calculateFees(uint256 amount) private view returns (uint256 fee) {
        if (_variableFee > 0) {
            fee = amount.percentMul(_variableFee);
        }
        if (_fixedFee > 0) {
            fee += _fixedFee;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IKBCToken is IERC721 {
    event CloneBondIssued(uint256 ghostId, uint256 parentId, uint256 newCoupon);
    event CloneBondRedeemed(uint256 ghostId, uint256 parentId);

    struct CloneBond {
        uint256 parentId;
        uint256 coupon;
    }

    function issueBond(address to, CloneBond memory cBond) external returns (uint256 tokenId);

    function redeem(uint256 tokenId) external;

    function getBond(uint256) external returns (CloneBond memory);

    function getTokenIdCounter() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IKIBTAddressProvider {
    event KIBTokenSet(address KIBToken);

    event KUMABondTokenSet(address KUMABondToken);

    event KBCTokenSet(address KBCToken);

    event KUMASwapSet(address KUMASwap);

    function setKUMABondToken(address KUMABondToken) external;

    function setKBCToken(address KBCToken) external;

    function setPriceFeed(address priceFeed) external;

    function setKIBToken(bytes4 currency, bytes4 country, uint64 term, address KIBToken) external;

    function setKUMASwap(bytes4 currency, bytes4 country, uint64 term, address KUMASwap) external;

    function setKIBTFeeCollector(bytes4 currency, bytes4 country, uint64 term, address feeCollector) external;

    function accessController() external view returns (IAccessControl);

    function getKUMABondToken() external view returns (address);

    function getPriceFeed() external view returns (address);

    function getKBCToken() external view returns (address);

    function getKIBToken(bytes32 riskCategory) external view returns (address);

    function getKUMASwap(bytes32 riskCategory) external view returns (address);

    function getKIBTFeeCollector(bytes32 riskCategory) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IKIBTAddressProvider} from "src/interfaces/IKIBTAddressProvider.sol";
import {IMCAGPriceFeed} from "src/interfaces/IMCAGPriceFeed.sol";

interface IKIBToken is IERC20Metadata {
    event YieldUpdated(uint256 oldYield, uint256 newYield);

    event CumulativeYieldUpdated(uint256 oldCumulativeYield, uint256 newCumulativeYield);

    event EpochLengthSet(uint256 previousEpochLength, uint256 newEpochLength);

    function setEpochLength(uint256 epochLength) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function refreshYield() external;

    function KIBTAddressProvider() external returns (IKIBTAddressProvider);

    function riskCategory() external view returns (bytes32);

    function getYield() external view returns (uint256);

    function getTotalBaseSupply() external view returns (uint256);

    function getBaseBalance(address account) external view returns (uint256);

    function getEpochLength() external view returns (uint256);

    function getLastRefresh() external view returns (uint256);

    function getCumulativeYield() external view returns (uint256);

    function getUpdatedCumulativeYield() external view returns (uint256);

    function getPreviousEpochTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IKIBTAddressProvider} from "src/interfaces/IKIBTAddressProvider.sol";

interface IKUMASwap is IERC721Receiver {
    event BondBought(uint256 tokenId, uint256 KIBTokenBurned, address indexed buyer);
    event BondClaimed(uint256 tokenId, uint256 ghostTokenId);
    event BondExpired(uint256 tokenId);
    event BondSold(uint256 tokenId, uint256 KIBTokenMinted, address indexed seller);
    event DeprecationModeInitialized();
    event DeprecationModeEnabled();
    event DeprecationModeUninitialized();
    event DeprecationStableCoinSet(address oldDeprecationStableCoin, address newDeprecationStableCoin);
    event FeeCharged(uint256 fee);
    event FeeSet(uint16 variableFee, uint256 fixedFee);
    event GhostCouponSet(uint256 tokenId, uint256 ghostCoupon);
    event IncomeClaimed(uint256 claimedIncome);
    event MinCouponUpdated(uint256 oldMinCoupon, uint256 newMinCoupon);
    event MinGasSet(uint256 oldMinGas, uint256 newMinGas);
    event ReferenceRateSet(uint256 referenceRate);
    event MIBTRedeemed(address indexed redeemer, uint256 redeemedStableCoinAmount);

    function sellBond(uint256 tokenId) external;

    function buyBond(uint256 tokenId) external;

    function buyBondForStableCoin(uint256 tokenId, address buyer, uint256 amount) external;

    function claimBond(uint256 tokenId) external;

    function redeemMIBT(uint256 amount) external;

    function pause() external;

    function unpause() external;

    function expireBond(uint256 tokenId) external;

    function updateCloneBondCoupons() external;

    function setFees(uint16 variableFee, uint256 fixedFee) external;

    function setMinGas(uint256 minGas) external;

    function setDeprecationStableCoin(IERC20 newDeprecationStableCoin) external;

    function initializeDeprecationMode() external;

    function uninitializeDeprecationMode() external;

    function enableDeprecationMode() external;

    function setReferenceRate(uint256 referenceRate) external;

    function isDeprecationInitialized() external view returns (bool);

    function getDeprecationInitializedAt() external view returns (uint56);

    function isDeprecated() external view returns (bool);

    function maxCoupons() external view returns (uint16);

    function riskCategory() external view returns (bytes32);

    function KIBTAddressProvider() external view returns (IKIBTAddressProvider);

    function getVariableFee() external view returns (uint16);

    function getDeprecationStableCoin() external view returns (IERC20);

    function getFixedFee() external view returns (uint256);

    function getMinGas() external view returns (uint256);

    function getMinCoupon() external view returns (uint256);

    function getReferenceRate() external view returns (uint256);

    function getGhostCouponUpdateTracker() external view returns (uint256);

    function getCoupons() external view returns (uint256[] memory);

    function getCouponIndex(uint256 coupon) external view returns (uint256);

    function getBondReserve() external view returns (uint256[] memory);

    function getBondIndex(uint256 tokenId) external view returns (uint256);

    function getGhostBond(uint256 tokenId) external view returns (uint256);

    function getCouponInventory(uint256 coupon) external view returns (uint256);

    function isInReserve(uint256 tokenId) external view returns (bool);

    function isExpired() external view returns (bool);

    function getCloneCoupon(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {MCAGAggregatorInterface} from "@mcag/interfaces/MCAGAggregatorInterface.sol";

interface IMCAGPriceFeed {
    event OracleSet(bytes32 indexed riskCategory, address oracle);

    function setOracle(bytes4 currency, bytes4 country, uint64 term, MCAGAggregatorInterface oracle) external;

    function minRateCoupon() external view returns (uint256);

    function decimals() external view returns (uint8);

    function accessController() external view returns (IAccessControl);

    function getRate(bytes32 riskCategory) external view returns (uint256);

    function getOracle(bytes32 riskCategory) external view returns (MCAGAggregatorInterface);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Errors {
    error CANNOT_SET_TO_ADDRESS_ZERO();
    error CANNOT_SET_TO_ZERO();
    error ERC20_TRANSFER_FROM_THE_ZERO_ADDRESS();
    error ERC20_TRANSER_TO_THE_ZERO_ADDRESS();
    error ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE();
    error ERC20_MINT_TO_THE_ZERO_ADDRESS();
    error ERC20_BURN_FROM_THE_ZERO_ADDRESS();
    error ERC20_BURN_AMOUNT_EXCEEDS_BALANCE();
    error START_TIME_NOT_REACHED();
    error EPOCH_LENGTH_CANNOT_BE_ZERO();
    error ERROR_YIELD_LT_RAY();
    error ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(address account, bytes32 role);
    error BLACKLISTABLE_CALLER_IS_NOT_BLACKLISTER();
    error BLACKLISTABLE_ACCOUNT_IS_BLACKLISTED(address account);
    error NEW_YIELD_TOO_HIGH();
    error NEW_EPOCH_LENGTH_TOO_HIGH();
    error WRONG_RISK_CATEGORY();
    error WRONG_RISK_CONFIG();
    error INVALID_RISK_CATEGORY();
    error INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
    error ERC721_APPROVAL_TO_CURRENT_OWNER();
    error ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
    error ERC721_INVALID_TOKEN_ID();
    error ERC721_CALLER_IS_NOT_TOKEN_OWNER();
    error CALLER_NOT_KUMASWAP();
    error CALLER_NOT_MIMO_BOND_TOKEN();
    error BOND_NOT_AVAILABLE_FOR_CLAIM();
    error CANNOT_SELL_MATURED_BOND();
    error NO_EXPIRED_BOND_IN_RESERVE();
    error MAX_COUPONS_REACHED();
    error COUPON_TOO_LOW();
    error CALLER_IS_NOT_MIB_TOKEN();
    error CALLER_NOT_FEE_COLLECTOR();
    error PAYEE_ALREADY_EXISTS();
    error PAYEE_DOES_NOT_EXIST();
    error PAYEES_AND_SHARES_MISMATCHED(uint256 payeeLength, uint256 shareLength);
    error NO_PAYEES();
    error NO_AVAILABLE_INCOME();
    error SHARE_CANNOT_BE_ZERO();
    error DEPRECATION_MODE_ENABLED();
    error DEPRECATION_MODE_ALREADY_INITIALIZED();
    error DEPRECATION_MODE_NOT_INITIALIZED();
    error DEPRECATION_MODE_NOT_ENABLED();
    error ELAPSED_TIME_SINCE_DEPRECATION_MODE_INITIALIZATION_TOO_SHORT(uint256 elapsed, uint256 minElapsedTime);
    error AMOUNT_CANNOT_BE_ZERO();
    error BOND_RESERVE_NOT_EMPTY();
    error BUYER_CANNOT_BE_ADDRESS_ZERO();
    error RISK_CATEGORY_MISMATCH();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/**
 * @title PercentageMath library
 * @author Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     */
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(or(iszero(percentage), iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     */
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(
                iszero(percentage), iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))
            ) { revert(0, 0) }

            result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

library Roles {
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant MIBT_MINT_ROLE = keccak256("MIBT_MINT_ROLE");
    bytes32 public constant MIBT_BURN_ROLE = keccak256("MIBT_BURN_ROLE");
    bytes32 public constant MIBT_SET_EPOCH_LENGTH_ROLE = keccak256("MIBT_SET_EPOCH_LENGTH_ROLE");
    bytes32 public constant MIBT_SWAP_CLAIM_ROLE = keccak256("MIBT_SWAP_CLAIM_ROLE");
    bytes32 public constant MIBT_SWAP_PAUSE_ROLE = keccak256("MIBT_SWAP_PAUSE_ROLE");
    bytes32 public constant MIBT_SWAP_UNPAUSE_ROLE = keccak256("MIBT_SWAP_UNPAUSE_ROLE");
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.16;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 *
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     *
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     *
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) { revert(0, 0) }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     *
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     *
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) { revert(0, 0) }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     *
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) { b := add(b, 1) }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     *
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) { revert(0, 0) }
        }
    }

    /**
     * @dev calculates base^exp. The code uses the ModExp precompile
     * @return z base^exp, in ray
     *
     */
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}