// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IClaimFacet} from "./interface/IClaimFacet.sol";
import {BorrowerAlreadyClaimed, LoanNotRepaidOrLiquidatedYet, NotBorrowerOfTheLoan} from "./DataStructure/Errors.sol";
import {ERC721CallerIsNotOwner} from "./DataStructure/ERC721Errors.sol";
import {Loan, Protocol, Provision, SupplyPosition} from "./DataStructure/Storage.sol";
import {ONE, protocolStorage, supplyPositionStorage} from "./DataStructure/Global.sol";
import {Ray} from "./DataStructure/Objects.sol";
import {RayMath} from "./utils/RayMath.sol";
import {Erc20CheckedTransfer} from "./utils/Erc20CheckedTransfer.sol";
import {SafeMint} from "./SupplyPositionLogic/SafeMint.sol";

/// @notice claims supplier and borrower rights on loans or supply positions
contract ClaimFacet is IClaimFacet, SafeMint {
    using RayMath for Ray;
    using RayMath for uint256;
    using Erc20CheckedTransfer for IERC20;

    /// @notice claims principal plus interests or liquidation share due as a supplier
    /// @param positionIds identifiers of one or multiple supply position to burn
    /// @return sent amount sent
    function claim(uint256[] calldata positionIds) external returns (uint256 sent) {
        Protocol storage proto = protocolStorage();
        SupplyPosition storage sp = supplyPositionStorage();
        Loan storage loan;
        Provision storage provision;
        uint256 loanId;
        uint256 sentTemp;

        for (uint256 i = 0; i < positionIds.length; i++) {
            if (sp.owner[positionIds[i]] != msg.sender) {
                revert ERC721CallerIsNotOwner();
            }
            _burn(positionIds[i]);
            provision = sp.provision[positionIds[i]];
            loanId = provision.loanId;
            loan = proto.loan[loanId];

            if (loan.payment.liquidated) {
                sentTemp = sendShareOfSaleAsSupplier(loan, provision);
            } else {
                if (loan.payment.paid == 0) {
                    revert LoanNotRepaidOrLiquidatedYet(loanId);
                }
                sentTemp = sendInterests(loan, provision);
            }
            emit Claim(msg.sender, sentTemp, loanId);
            sent += sentTemp;
        }
    }

    /// @notice claims share of liquidation due to a borrower who's collateral has been sold
    /// @param loanIds loan identifiers of one or multiple loans where the borrower wants to claim liquidation share
    /// @return sent amount sent
    function claimAsBorrower(uint256[] calldata loanIds) external returns (uint256 sent) {
        Protocol storage proto = protocolStorage();
        Loan storage loan;
        uint256 sentTemp;
        uint256 loanId;

        for (uint256 i = 0; i < loanIds.length; i++) {
            loanId = loanIds[i];
            loan = proto.loan[loanId];
            if (loan.borrower != msg.sender) {
                revert NotBorrowerOfTheLoan(loanId);
            }
            if (loan.payment.borrowerClaimed) {
                revert BorrowerAlreadyClaimed(loanId);
            }
            if (loan.payment.liquidated) {
                loan.payment.borrowerClaimed = true;
                // 1 - shareLent = share belonging to the borrower (not used as collateral)
                sentTemp = loan.payment.paid.mul(ONE.sub(loan.shareLent));
            } else {
                revert LoanNotRepaidOrLiquidatedYet(loanId);
            }
            if (sentTemp > 0) {
                /* the function may be called to store that the borrower claimed its due, but if this due is of 0 there
                is no point in emitting a transfer and claim event */
                loan.assetLent.checkedTransfer(msg.sender, sentTemp);
                sent += sentTemp;
                emit Claim(msg.sender, sentTemp, loanId);
                // sentTemp is reassigned or the execution reverts on next loop
            }
        }
    }

    /// @notice sends principal plus interests of the loan to `msg.sender`
    /// @param loan - to calculate amount from
    /// @param provision liquidity provision for this loan
    /// @return sent amount sent
    function sendInterests(Loan storage loan, Provision storage provision) internal returns (uint256 sent) {
        uint256 interests = loan.payment.paid - loan.lent;
        if (interests == loan.payment.minInterestsToRepay) {
            // this is the case if the loan is repaid shortly after issuance
            // each lender gets its minimal interest, as an anti ddos measure to spam offer
            sent = provision.amount + interests;
        } else {
            /* provision.amount / lent = share of the interests belonging to the lender. The parenthesis make the
            calculus in the order that maximizes precison */
            sent = provision.amount + (interests * (provision.amount)) / loan.lent;
        }
        loan.assetLent.checkedTransfer(msg.sender, sent);
    }

    /// @notice sends liquidation share due to `msg.sender` as a supplier
    /// @param loan - from which the collateral were liquidated
    /// @param provision liquidity provisioned by this loan by the supplier
    /// @return sent amount sent
    function sendShareOfSaleAsSupplier(Loan storage loan, Provision storage provision) internal returns (uint256 sent) {
        // in the case of a liqudidation, provision.share is considered the share of the NFT acquired by the lender
        sent = loan.payment.paid.mul(provision.share);
        loan.assetLent.checkedTransfer(msg.sender, sent);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

error ERC721AddressZeroIsNotAValidOwner();
error ERC721InvalidTokenId();
error ERC721ApprovalToCurrentOwner();
error ERC721CallerIsNotOwnerNorApprovedForAll();
error ERC721CallerIsNotOwnerNorApproved();
error ERC721TransferToNonERC721ReceiverImplementer();
error ERC721MintToTheZeroAddress();
error ERC721TokenAlreadyMinted();
error ERC721TransferFromIncorrectOwner();
error ERC721TransferToTheZeroAddress();
error ERC721ApproveToCaller();
error ERC721CallerIsNotOwner();

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFToken, Offer} from "./Objects.sol";

error BadCollateral(Offer offer, NFToken providedNft);
error ERC20TransferFailed(IERC20 token, address from, address to);
error OfferHasExpired(Offer offer, uint256 expirationDate);
error RequestedAmountIsUnderMinimum(Offer offer, uint256 requested, uint256 lowerBound);
error RequestedAmountTooHigh(uint256 requested, uint256 offered, Offer offer);
error LoanAlreadyRepaid(uint256 loanId);
error LoanNotRepaidOrLiquidatedYet(uint256 loanId);
error NotBorrowerOfTheLoan(uint256 loanId);
error BorrowerAlreadyClaimed(uint256 loanId);
error CallerIsNotOwner(address admin);
error InvalidTranche(uint256 nbOfTranches);
error CollateralIsNotLiquidableYet(uint256 endDate, uint256 loanId);
error UnsafeAmountLent(uint256 lent);
error MultipleOffersUsed();
error PriceOverMaximum(uint256 maxPrice, uint256 price);
error CurrencyNotSupported(IERC20 currency);
error ShareMatchedIsTooLow(Offer offer, uint256 requested);

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Protocol, SupplyPosition, SupplyPositionOffChainMetadata} from "./Storage.sol";
import {Ray} from "./Objects.sol";

/* rationale of the naming of the hash is to use kairos loan's ENS as domain, the subject of the storage struct as
subdomain and the version to anticipate upgrade. Order is revered compared to urls as it's the usage in code such as in
java imports */
bytes32 constant PROTOCOL_SP = keccak256("eth.kairosloan.protocol.v1.0");
bytes32 constant SUPPLY_SP = keccak256("eth.kairosloan.supply-position.v1.0");
bytes32 constant POSITION_OFF_CHAIN_METADATA_SP = keccak256("eth.kairosloan.position-off-chain-metadata.v1.0");

/* Ray is chosed as the only fixed-point decimals approach as it allow extreme and versatile precision accross erc20s
and timeframes */
uint256 constant RAY = 1e27;
Ray constant ONE = Ray.wrap(RAY);
Ray constant ZERO = Ray.wrap(0);

/* solhint-disable func-visibility */

/// @dev getters of storage regions of the contract for specified usage

/* we access storage only through functions in facets following the diamond storage pattern */

function protocolStorage() pure returns (Protocol storage protocol) {
    bytes32 position = PROTOCOL_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        protocol.slot := position
    }
}

function supplyPositionStorage() pure returns (SupplyPosition storage sp) {
    bytes32 position = SUPPLY_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        sp.slot := position
    }
}

function supplyPositionMetadataStorage() pure returns (SupplyPositionOffChainMetadata storage position) {
    bytes32 position_off_chain_metadata_sp = POSITION_OFF_CHAIN_METADATA_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        position.slot := position_off_chain_metadata_sp
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice file for type definitions not used in storage

/// @notice 27-decimals fixed point unsigned number
type Ray is uint256;

/// @notice Arguments to buy the collateral of one loan
/// @param loanId loan identifier
/// @param to address that will receive the collateral
/// @param maxPrice maximum price to pay for the collateral
struct BuyArg {
    uint256 loanId;
    address to;
    uint256 maxPrice;
}

/// @notice Arguments to borrow from one collateral
/// @param nft asset to use as collateral
/// @param args arguments for the borrow parameters of the offers to use with the collateral
struct BorrowArg {
    NFToken nft;
    OfferArg[] args;
}

/// @notice Arguments for the borrow parameters of an offer
/// @dev '-' means n^th
/// @param signature - of the offer
/// @param amount - to borrow from this offer
/// @param offer intended for usage in the loan
struct OfferArg {
    bytes signature;
    uint256 amount;
    Offer offer;
}

/// @notice Data on collateral state during the matching process of a NFT
///     with multiple offers
/// @param matched proportion from 0 to 1 of the collateral value matched by offers
/// @param assetLent - ERC20 that the protocol will send as loan
/// @param tranche identifier of the interest rate tranche that will be used for the loan
/// @param minOfferDuration minimal duration among offers used
/// @param minOfferLoanToValue
/// @param maxOfferLoanToValue
/// @param from original owner of the nft (borrower in most cases)
/// @param nft the collateral asset
/// @param loanId loan identifier
struct CollateralState {
    Ray matched;
    IERC20 assetLent;
    uint256 tranche;
    uint256 minOfferDuration;
    uint256 minOfferLoanToValue;
    uint256 maxOfferLoanToValue;
    address from;
    NFToken nft;
    uint256 loanId;
}

/// @notice Loan offer
/// @param assetToLend address of the ERC-20 to lend
/// @param loanToValue amount to lend per collateral
/// @param duration in seconds, time before mandatory repayment after loan start
/// @param expirationDate date after which the offer can't be used
/// @param tranche identifier of the interest rate tranche
/// @param collateral the NFT that can be used as collateral with this offer
struct Offer {
    IERC20 assetToLend;
    uint256 loanToValue;
    uint256 duration;
    uint256 expirationDate;
    uint256 tranche;
    NFToken collateral;
}

/// @title Non Fungible Token
/// @notice describes an ERC721 compliant token, can be used as single spec
///     I.e Collateral type accepting one specific NFT
/// @dev found in storgae
/// @param implem address of the NFT contract
/// @param id token identifier
struct NFToken {
    IERC721 implem;
    uint256 id;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NFToken, Ray} from "./Objects.sol";

/// @notice type definitions of data permanently stored

/// @notice Parameters affecting liquidations by dutch auctions. The current auction parameters
///         are assigned to new loans at borrow time and can't be modified during the loan life.
/// @param duration number of seconds after the auction start when the price hits 0
/// @param priceFactor multiplier of the mean tvl used as start price for the auction
struct Auction {
    uint256 duration;
    Ray priceFactor;
}

/// @notice General protocol
/// @param nbOfLoans total number of loans ever issued (active and ended)
/// @param nbOfTranches total number of interest rates tranches ever created (active and inactive)
/// @param auctionParams - sets auctions duration and initial prices
/// @param tranche interest rate of tranche of provided id, in multiplier per second
///         I.e lent * time since loan start * tranche = interests to repay
/// @param loan - of id -
/// @param minOfferCost minimum amount repaid per offer used in a loan
/// @param offerBorrowAmountLowerBound borrow amount per offer has to be strightly higher than this value
struct Protocol {
    uint256 nbOfLoans;
    uint256 nbOfTranches;
    Auction auction;
    mapping(uint256 => Ray) tranche;
    mapping(uint256 => Loan) loan;
    mapping(IERC20 => uint256) minOfferCost;
    mapping(IERC20 => uint256) offerBorrowAmountLowerBound;
}

/// @notice Issued Loan (corresponding to one collateral)
/// @param assetLent currency lent
/// @param lent total amount lent
/// @param shareLent between 0 and 1, the share of the collateral value lent
/// @param startDate timestamp of the borrowing transaction
/// @param endDate timestamp after which sale starts & repay is impossible
/// @param auction duration and price factor of the collateral auction in case of liquidation
/// @param interestPerSecond share of the amount lent added to the debt per second
/// @param borrower borrowing account
/// @param collateral NFT asset used as collateral
/// @param payment data on the payment, a non-0 payment.paid value means the loan lifecyle is over
struct Loan {
    IERC20 assetLent;
    uint256 lent;
    Ray shareLent;
    uint256 startDate;
    uint256 endDate;
    Auction auction;
    Ray interestPerSecond;
    address borrower;
    NFToken collateral;
    Payment payment;
}

/// @notice tracking of the payment state of a loan
/// @param paid amount sent on the tx closing the loan, non-zero value means loan's lifecycle is over
/// @param minInterestsToRepay minimum amount of interests that the borrower will need to repay
/// @param liquidated this loan has been closed at the liquidation stage, the collateral has been sold
/// @param borrowerClaimed borrower claimed his rights on this loan (either collateral or share of liquidation)
struct Payment {
    uint256 paid;
    uint256 minInterestsToRepay;
    bool liquidated;
    bool borrowerClaimed;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param name - of the NFT collection
/// @param symbol - of the NFT collection
/// @param totalSupply number of supply position ever issued - not decreased on burn
/// @param owner - of nft of id -
/// @param balance number of positions owned by -
/// @param tokenApproval address approved to transfer position of id - on behalf of its owner
/// @param operatorApproval address is approved to transfer all positions of - on his behalf
/// @param provision supply position metadata
struct SupplyPosition {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(uint256 => address) owner;
    mapping(address => uint256) balance;
    mapping(uint256 => address) tokenApproval;
    mapping(address => mapping(address => bool)) operatorApproval;
    mapping(uint256 => Provision) provision;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param baseUri - base uri
struct SupplyPositionOffChainMetadata {
    string baseUri;
}

/// @notice data on a liquidity provision from a supply offer in one existing loan
/// @param amount - supplied for this provision
/// @param share - of the collateral matched by this provision
/// @param loanId identifier of the loan the liquidity went to
struct Provision {
    uint256 amount;
    Ray share;
    uint256 loanId;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IERC721Events} from "../interface/IERC721Events.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";
import {SupplyPosition} from "../DataStructure/Storage.sol";
import {ERC721ApproveToCaller, ERC721InvalidTokenId, ERC721TokenAlreadyMinted, ERC721MintToTheZeroAddress, ERC721TransferFromIncorrectOwner, ERC721TransferToNonERC721ReceiverImplementer, ERC721TransferToTheZeroAddress} from "../DataStructure/ERC721Errors.sol";

/// @notice internal logic for DiamondERC721 adapted fo usage with diamond storage
abstract contract NFTUtils is IERC721Events {
    using Address for address;

    function emitTransfer(address from, address to, uint256 tokenId) internal {
        emit Transfer(from, to, tokenId);
    }

    function emitApproval(address owner, address approved, uint256 tokenId) internal {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(address owner, address operator, bool approved) internal {
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonERC721ReceiverImplementer();
                } else {
                    /* solhint-disable-next-line no-inline-assembly */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ERC721TransferToNonERC721ReceiverImplementer();
        }
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert ERC721TransferToNonERC721ReceiverImplementer();
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (to == address(0)) {
            revert ERC721MintToTheZeroAddress();
        }
        if (_exists(tokenId)) {
            revert ERC721TokenAlreadyMinted();
        }

        sp.balance[to] += 1;
        sp.owner[tokenId] = to;

        emitTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        address owner = _ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        sp.balance[owner] -= 1;
        delete sp.owner[tokenId];

        emitTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (_ownerOf(tokenId) != from) {
            revert ERC721TransferFromIncorrectOwner();
        }
        if (to == address(0)) {
            revert ERC721TransferToTheZeroAddress();
        }

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        sp.balance[from] -= 1;
        sp.balance[to] += 1;
        sp.owner[tokenId] = to;

        emitTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        sp.tokenApproval[tokenId] = to;
        emitApproval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (owner == operator) {
            revert ERC721ApproveToCaller();
        }
        sp.operatorApproval[owner][operator] = approved;
        emitApprovalForAll(owner, operator, approved);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        SupplyPosition storage sp = supplyPositionStorage();

        return sp.owner[tokenId] != address(0);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        SupplyPosition storage sp = supplyPositionStorage();

        address owner = sp.owner[tokenId];
        if (owner == address(0)) {
            revert ERC721InvalidTokenId();
        }
        return owner;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (spender == owner || _isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        if (!_exists(tokenId)) {
            revert ERC721InvalidTokenId();
        }

        return supplyPositionStorage().tokenApproval[tokenId];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return supplyPositionStorage().operatorApproval[owner][operator];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {NFTUtils} from "./NFTUtils.sol";
import {Provision, SupplyPosition} from "../DataStructure/Storage.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";

/// @notice safeMint internal method added to base ERC721 implementation for supply position minting
/// @dev inherit this to make an ERC721-compliant facet with added feature internal safeMint
contract SafeMint is NFTUtils {
    /// @notice mints a new supply position to `to`
    /// @param to receiver of the position
    /// @param provision metadata of the supply position
    /// @return tokenId identifier of the supply position
    function safeMint(address to, Provision memory provision) internal returns (uint256 tokenId) {
        SupplyPosition storage sp = supplyPositionStorage();

        tokenId = ++sp.totalSupply;
        sp.provision[tokenId] = provision;
        _safeMint(to, tokenId);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IClaimEmitter {
    /// @notice some liquidity has been claimed as principal plus interests or share of liquidation
    /// @param claimant who received the liquidity
    /// @param claimed amount sent
    /// @param loanId loan identifier where the claim rights come from
    event Claim(address indexed claimant, uint256 indexed claimed, uint256 indexed loanId);
}

interface IClaimFacet is IClaimEmitter {
    function claim(uint256[] calldata positionIds) external returns (uint256 sent);

    function claimAsBorrower(uint256[] calldata loanIds) external returns (uint256 sent);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.18;

/**
 * @dev Required events of an ERC721 compliant contract.
 */
interface IERC721Events {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ERC20TransferFailed} from "../DataStructure/Errors.sol";

/// @notice library to safely transfer ERC20 tokens, including not entirely compliant tokens like BNB and USDT
/// @dev avoids bugs due to tokens not following the erc20 standard by not returning a boolean
///     or by reverting on 0 amount transfers. Does not support fee on transfer tokens
library Erc20CheckedTransfer {
    using SafeERC20 for IERC20;

    /// @notice executes only if amount is greater than zero
    /// @param amount amount to check
    modifier skipZeroAmount(uint256 amount) {
        if (amount > 0) {
            _;
        }
    }

    /// @notice safely transfers
    /// @param currency ERC20 to transfer
    /// @param from sender
    /// @param to recipient
    /// @param amount amount to transfer
    function checkedTransferFrom(
        IERC20 currency,
        address from,
        address to,
        uint256 amount
    ) internal skipZeroAmount(amount) {
        currency.safeTransferFrom(from, to, amount);
    }

    /// @notice safely transfers
    /// @param currency ERC20 to transfer
    /// @param to recipient
    /// @param amount amount to transfer
    function checkedTransfer(IERC20 currency, address to, uint256 amount) internal skipZeroAmount(amount) {
        currency.safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {RAY} from "../DataStructure/Global.sol";
import {Ray} from "../DataStructure/Objects.sol";

/// @notice Manipulates fixed-point unsigned decimals numbers
/// @dev all uints are considered integers (no wad)
library RayMath {
    // ~~~ calculus ~~~ //

    /// @notice `a` plus `b`
    /// @return result
    function add(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) + Ray.unwrap(b));
    }

    /// @notice `a` minus `b`
    /// @return result
    function sub(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) - Ray.unwrap(b));
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap((Ray.unwrap(a) * Ray.unwrap(b)) / RAY);
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(Ray a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) * b);
    }

    /// @notice `a` times `b`
    /// @return result
    function mul(uint256 a, Ray b) internal pure returns (uint256) {
        return (a * Ray.unwrap(b)) / RAY;
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(Ray a, Ray b) internal pure returns (Ray) {
        return Ray.wrap((Ray.unwrap(a) * RAY) / Ray.unwrap(b));
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(Ray a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap(Ray.unwrap(a) / b);
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(uint256 a, Ray b) internal pure returns (uint256) {
        return (a * RAY) / Ray.unwrap(b);
    }

    /// @notice `a` divided by `b`
    /// @return result
    function div(uint256 a, uint256 b) internal pure returns (Ray) {
        return Ray.wrap((a * RAY) / b);
    }

    // ~~~ comparisons ~~~ //

    /// @notice is `a` less than `b`
    /// @return result
    function lt(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) < Ray.unwrap(b);
    }

    /// @notice is `a` greater than `b`
    /// @return result
    function gt(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) > Ray.unwrap(b);
    }

    /// @notice is `a` greater or equal to `b`
    /// @return result
    function gte(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) >= Ray.unwrap(b);
    }

    /// @notice is `a` equal to `b`
    /// @return result
    function eq(Ray a, Ray b) internal pure returns (bool) {
        return Ray.unwrap(a) == Ray.unwrap(b);
    }

    // ~~~ uint256 method ~~~ //

    /// @notice highest value among `a` and `b`
    /// @return maximum
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}