// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IVaultFactory.sol";
import "../interfaces/IAssetVault.sol";
import "../interfaces/ISignatureVerifier.sol";
import "../libraries/LoanLibrary.sol";

import { IV_NoAmount, IV_InvalidWildcard, IV_ItemMissingAddress, IV_InvalidCollateralType } from "../errors/Lending.sol";

/**
 * @title ArcadeItemsVerifier
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract can be used for verifying complex signature-encoded
 * bundle descriptions. This resolves on a new array of SignatureItems[],
 * which outside of verification, is passed around as bytes memory.
 *
 * Each SignatureItem has the following fields:
 *      - cType (collateral Type)
 *      - asset (contract address of the asset)
 *      - tokenId (token ID of the asset, if applicable)
 *      - amount (amount of the asset, if applicable - if ERC721, set to "1")
 *      - anyIdAllowed (whether a wildcard is supported - see below)
 *
 * - For token ids part of ERC721, other features beyond direct tokenIds are supported:
 *      - If anyIdAllowed is true, then any token ID can be passed - the field will be ignored.
 *      - If anyIdAllowed is true, then the "amount" field can be read to require
 *          a specific amount of assets from the collection.
 *      - Wildcard token ids are not supported for ERC1155 or ERC20.
 * - All amounts are taken as minimums. For instance, if the "amount" field of an ERC1155 is 5,
 *      then a bundle with 8 of those ERC1155s are accepted.
 * - For an ERC20 cType, tokenId is ignored. For an ERC721 cType, amount is ignored unless wildcard (see above).
        If a wildcard is used, 0 amount is invalid, and all nonzero amounts are ignored.
 *
 * - Any deviation from the above rules represents an unparseable signature and will always
 *      return invalid.
 *
 * - All multi-item signatures assume AND - any optional expressed by OR
 *      can be implemented by simply signing multiple separate signatures.
 */
contract ArcadeItemsVerifier is ISignatureVerifier {
    /// @dev Enum describing the collateral type of a signature item
    enum CollateralType {
        ERC_721,
        ERC_1155,
        ERC_20
    }

    /// @dev Enum describing each item that should be validated
    struct SignatureItem {
        // The type of collateral - which interface does it implement
        CollateralType cType;
        // The address of the collateral contract
        address asset;
        // The token ID of the collateral (only applicable to 721 and 1155).
        uint256 tokenId;
        // The minimum amount of collateral. For ERC721 assets, pass 1 or the
        // amount of assets needed to be held for a wildcard predicate. If the
        // tokenId is specified, the amount is assumed to be 1.
        uint256 amount;
        // Whether any token ID should be allowed. Only applies to ERC721.
        // Supersedes tokenId.
        bool anyIdAllowed;
    }

    // ==================================== COLLATERAL VERIFICATION =====================================

    /**
     * @notice Verify that the items specified by the packed SignatureItem array are held by the vault.
     * @dev    Reverts on a malformed SignatureItem, returns false on missing contents.
     *
     *         Verification for empty predicates array has been addressed in initializeLoanWithItems and
     *         rolloverLoanWithItems.
     *
     * @param predicates                    The SignatureItem[] array of items, packed in bytes.
     * @param vault                         The vault that should own the specified items.
     *
     * @return verified                     Whether the bundle contains the specified items.
     */
    // solhint-disable-next-line code-complexity
    function verifyPredicates(bytes calldata predicates, address vault) external view override returns (bool) {
        // Unpack items
        SignatureItem[] memory items = abi.decode(predicates, (SignatureItem[]));

        for (uint256 i = 0; i < items.length; i++) {
            SignatureItem memory item = items[i];

            // No asset provided
            if (item.asset == address(0)) revert IV_ItemMissingAddress();

            // No amount provided
            if (item.amount == 0) revert IV_NoAmount(item.asset, item.amount);


            if (item.cType == CollateralType.ERC_721) {
                IERC721 asset = IERC721(item.asset);
                uint256 id = item.tokenId;

                // Wildcard, but vault has no assets or not enough specified
                if (item.anyIdAllowed && asset.balanceOf(vault) < item.amount) return false;
                // Does not own specifically specified asset
                if (!item.anyIdAllowed && asset.ownerOf(id) != vault) return false;
            } else if (item.cType == CollateralType.ERC_1155) {
                IERC1155 asset = IERC1155(item.asset);

                // Wildcard not allowed, since we can't check overall 1155 balances
                if (item.anyIdAllowed) revert IV_InvalidWildcard(item.asset);

                // Does not own specifically specified asset
                if (asset.balanceOf(vault, item.tokenId) < item.amount) return false;
            } else if (item.cType == CollateralType.ERC_20) {
                IERC20 asset = IERC20(item.asset);

                // Wildcard not allowed, since nonsensical
                if (item.anyIdAllowed) revert IV_InvalidWildcard(item.asset);

                // Does not own specifically specified asset
                if (asset.balanceOf(vault) < item.amount) return false;
            } else {
                // Interface could not be parsed - fail
                revert IV_InvalidCollateralType(item.asset, uint256(item.cType));
            }
        }

        // Loop completed - all items found
        return true;
    }
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.11;

interface IVaultFactory {
    // ============= Events ==============

    event VaultCreated(address vault, address to);

    // ================ View Functions ================

    function isInstance(address instance) external view returns (bool validity);

    function instanceCount() external view returns (uint256);

    function instanceAt(uint256 tokenId) external view returns (address);

    function instanceAtIndex(uint256 index) external view returns (address);

    // ================ Factory Operations ================

    function initializeBundle(address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./ICallWhitelist.sol";

interface IAssetVault {
    // ============= Events ==============

    event WithdrawEnabled(address operator);
    event WithdrawERC20(address indexed operator, address indexed token, address recipient, uint256 amount);
    event WithdrawERC721(address indexed operator, address indexed token, address recipient, uint256 tokenId);
    event WithdrawPunk(address indexed operator, address indexed token, address recipient, uint256 tokenId);

    event WithdrawERC1155(
        address indexed operator,
        address indexed token,
        address recipient,
        uint256 tokenId,
        uint256 amount
    );

    event WithdrawETH(address indexed operator, address indexed recipient, uint256 amount);
    event Call(address indexed operator, address indexed to, bytes data);
    event Approve(address indexed operator, address indexed token, address indexed spender, uint256 amount);

    // ================= Initializer ==================

    function initialize(address _whitelist) external;

    // ================ View Functions ================

    function withdrawEnabled() external view returns (bool);

    function whitelist() external view returns (ICallWhitelist);

    // ================ Withdrawal Operations ================

    function enableWithdraw() external;

    function withdrawERC20(address token, address to) external;

    function withdrawERC721(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawERC1155(
        address token,
        uint256 tokenId,
        address to
    ) external;

    function withdrawETH(address to) external;

    function withdrawPunk(
        address punks,
        uint256 punkIndex,
        address to
    ) external;

    // ================ Utility Operations ================

    function call(address to, bytes memory data) external;

    function callApprove(address token, address spender, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../libraries/LoanLibrary.sol";

interface ISignatureVerifier {
    // ============== Collateral Verification ==============

    function verifyPredicates(bytes calldata predicates, address vault) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/**
 * @title LoanLibrary
 * @author Non-Fungible Technologies, Inc.
 *
 * Contains all data types used across Arcade lending contracts.
 */
library LoanLibrary {
    /**
     * @dev Enum describing the current state of a loan.
     * State change flow:
     * Created -> Active -> Repaid
     *                   -> Defaulted
     */
    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        DUMMY_DO_NOT_USE,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted
    }

    /**
     * @dev The raw terms of a loan.
     */
    struct LoanTerms {
        /// @dev Packed variables
        // The number of seconds representing relative due date of the loan.
        /// @dev Max is 94,608,000, fits in 32 bits
        uint32 durationSecs;
        // Timestamp for when signature for terms expires
        uint32 deadline;
        // Total number of installment periods within the loan duration.
        /// @dev Max is 1,000,000, fits in 24 bits
        uint24 numInstallments;
        // Interest expressed as a rate, unlike V1 gross value.
        // Input conversion: 0.01% = (1 * 10**18) ,  10.00% = (1000 * 10**18)
        // This represents the rate over the lifetime of the loan, not APR.
        // 0.01% is the minimum interest rate allowed by the protocol.
        /// @dev Max is 10,000%, fits in 160 bits
        uint160 interestRate;
        /// @dev Full-slot variables
        // The amount of principal in terms of the payableCurrency.
        uint256 principal;
        // The token ID of the address holding the collateral.
        /// @dev Can be an AssetVault, or the NFT contract for unbundled collateral
        address collateralAddress;
        // The token ID of the collateral.
        uint256 collateralId;
        // The payable currency for the loan principal and interest.
        address payableCurrency;
    }

    /**
     * @dev Modification of loan terms, used for signing only.
     *      Instead of a collateralId, a list of predicates
     *      is defined by 'bytes' in items.
     */
    struct LoanTermsWithItems {
        /// @dev Packed variables
        // The number of seconds representing relative due date of the loan.
        /// @dev Max is 94,608,000, fits in 32 bits
        uint32 durationSecs;
        // Timestamp for when signature for terms expires
        uint32 deadline;
        // Total number of installment periods within the loan duration.
        /// @dev Max is 1,000,000, fits in 24 bits
        uint24 numInstallments;
        // Interest expressed as a rate, unlike V1 gross value.
        // Input conversion: 0.01% = (1 * 10**18) ,  10.00% = (1000 * 10**18)
        // This represents the rate over the lifetime of the loan, not APR.
        // 0.01% is the minimum interest rate allowed by the protocol.
        /// @dev Max is 10,000%, fits in 160 bits
        uint160 interestRate;
        /// @dev Full-slot variables
        uint256 principal;
        // The tokenID of the address holding the collateral
        /// @dev Must be an AssetVault for LoanTermsWithItems
        address collateralAddress;
        // An encoded list of predicates
        bytes items;
        // The payable currency for the loan principal and interest
        address payableCurrency;
    }

    /**
     * @dev Predicate for item-based verifications
     */
    struct Predicate {
        // The encoded predicate, to decoded and parsed by the verifier contract
        bytes data;
        // The verifier contract
        address verifier;
    }

    /**
     * @dev The data of a loan. This is stored once the loan is Active
     */
    struct LoanData {
        /// @dev Packed variables
        // The current state of the loan
        LoanState state;
        // Number of installment payments made on the loan
        uint24 numInstallmentsPaid;
        // installment loan specific
        // Start date of the loan, using block.timestamp - for determining installment period
        uint160 startDate;
        /// @dev Full-slot variables
        // The raw terms of the loan
        LoanTerms terms;
        // Remaining balance of the loan. Starts as equal to principal. Can reduce based on
        // payments made, can increased based on compounded interest from missed payments and late fees
        uint256 balance;
        // Amount paid in total by the borrower
        uint256 balancePaid;
        // Total amount of late fees accrued
        uint256 lateFeesAccrued;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../libraries/LoanLibrary.sol";

/**
 * @title LendingErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for the core lending protocol contracts, with errors
 * prefixed by the contract that throws them (e.g., "OC_" for OriginationController).
 * Errors located in one place to make it possible to holistically look at all
 * protocol failure cases.
 */

// ==================================== ORIGINATION CONTROLLER ======================================
/// @notice All errors prefixed with OC_, to separate from other contracts in the protocol.

/// @notice Zero address passed in where not allowed.
error OC_ZeroAddress();

/**
 * @notice Ensure valid loan state for loan lifceycle operations.
 *
 * @param state                         Current state of a loan according to LoanState enum.
 */
error OC_InvalidState(LoanLibrary.LoanState state);

/**
 * @notice Loan duration must be greater than 1hr and less than 3yrs.
 *
 * @param durationSecs                 Total amount of time in seconds.
 */
error OC_LoanDuration(uint256 durationSecs);

/**
 * @notice Interest must be greater than 0.01%. (interestRate / 1e18 >= 1)
 *
 * @param interestRate                  InterestRate with 1e18 multiplier.
 */
error OC_InterestRate(uint256 interestRate);

/**
 * @notice Number of installment periods must be greater than 1 and less than or equal to 1000.
 *
 * @param numInstallments               Number of installment periods in loan.
 */
error OC_NumberInstallments(uint256 numInstallments);

/**
 * @notice One of the predicates for item verification failed.
 *
 * @param verifier                      The address of the verifier contract.
 * @param data                          The verification data (to be parsed by verifier).
 * @param vault                         The user's vault subject to verification.
 */
error OC_PredicateFailed(address verifier, bytes data, address vault);

/**
 * @notice The predicates array is empty.
 */
error OC_PredicatesArrayEmpty();

/**
 * @notice A caller attempted to approve themselves.
 *
 * @param caller                        The caller of the approve function.
 */
error OC_SelfApprove(address caller);

/**
 * @notice A caller attempted to originate a loan with their own signature.
 *
 * @param caller                        The caller of the approve function, who was also the signer.
 */
error OC_ApprovedOwnLoan(address caller);

/**
 * @notice The signature could not be recovered to the counterparty or approved party.
 *
 * @param target                        The target party of the signature, which should either be the signer,
 *                                      or someone who has approved the signer.
 * @param signer                        The signer determined from ECDSA.recover.
 */
error OC_InvalidSignature(address target, address signer);

/**
 * @notice The verifier contract specified in a predicate has not been whitelisted.
 *
 * @param verifier                      The verifier the caller attempted to use.
 */
error OC_InvalidVerifier(address verifier);

/**
 * @notice The function caller was neither borrower or lender, and was not approved by either.
 *
 * @param caller                        The unapproved function caller.
 */
error OC_CallerNotParticipant(address caller);

/**
 * @notice Two related parameters for batch operations did not match in length.
 */
error OC_BatchLengthMismatch();

/**
 * @notice Principal must be greater than 9999 Wei.
 *
 * @param principal                     Principal in ether.
 */
error OC_PrincipalTooLow(uint256 principal);

/**
 * @notice Signature must not be expired.
 *
 * @param deadline                      Deadline in seconds.
 */
error OC_SignatureIsExpired(uint256 deadline);

/**
 * @notice New currency does not match for a loan rollover request.
 *
 * @param oldCurrency                   The currency of the active loan.
 * @param newCurrency                   The currency of the new loan.
 */
error OC_RolloverCurrencyMismatch(address oldCurrency, address newCurrency);

/**
 * @notice New currency does not match for a loan rollover request.
 *
 * @param oldCollateralAddress          The address of the active loan's collateral.
 * @param newCollateralAddress          The token ID of the active loan's collateral.
 * @param oldCollateralId               The address of the new loan's collateral.
 * @param newCollateralId               The token ID of the new loan's collateral.
 */
error OC_RolloverCollateralMismatch(
    address oldCollateralAddress,
    uint256 oldCollateralId,
    address newCollateralAddress,
    uint256 newCollateralId
);

// ==================================== ITEMS VERIFIER ======================================
/// @notice All errors prefixed with IV_, to separate from other contracts in the protocol.

/**
 * @notice Provided SignatureItem is missing an address.
 */
error IV_ItemMissingAddress();

/**
 * @notice Provided SignatureItem has an invalid collateral type.
 * @dev    Should never actually fire, since cType is defined by an enum, so will fail on decode.
 *
 * @param asset                        The NFT contract being checked.
 * @param cType                        The collateralTytpe provided.
 */
error IV_InvalidCollateralType(address asset, uint256 cType);

/**
 * @notice Provided signature item with no required amount. For single ERC721s, specify 1.
 *
 * @param asset                         The NFT contract being checked.
 * @param amount                        The amount provided (should be 0).
 */
error IV_NoAmount(address asset, uint256 amount);

/**
 * @notice Provided a wildcard for a non-ERC721.
 *
 * @param asset                         The NFT contract being checked.
 */
error IV_InvalidWildcard(address asset);

/**
 * @notice The provided token ID is out of bounds for the given collection.
 *
 * @param tokenId                       The token ID provided.
 */
error IV_InvalidTokenId(int256 tokenId);

// ==================================== REPAYMENT CONTROLLER ======================================
/// @notice All errors prefixed with RC_, to separate from other contracts in the protocol.

/**
 * @notice Could not dereference loan from loan ID.
 *
 * @param target                     The loanId being checked.
 */
error RC_CannotDereference(uint256 target);

/**
 * @notice Ensure valid loan state for loan lifceycle operations.
 *
 * @param state                         Current state of a loan according to LoanState enum.
 */
error RC_InvalidState(LoanLibrary.LoanState state);

/**
 * @notice Repayment has already been completed for this loan without installments.
 */
error RC_NoPaymentDue();

/**
 * @notice Caller is not the owner of lender note.
 *
 * @param caller                     Msg.sender of the function call.
 */
error RC_OnlyLender(address caller);

/**
 * @notice Loan has not started yet.
 *
 * @param startDate                 block timestamp of the startDate of loan stored in LoanData.
 */
error RC_BeforeStartDate(uint256 startDate);

/**
 * @notice Loan terms do not have any installments, use repay for repayments.
 *
 * @param numInstallments           Number of installments returned from LoanTerms.
 */
error RC_NoInstallments(uint256 numInstallments);

/**
 * @notice Loan terms have installments, use repaypart or repayPartMinimum for repayments.
 *
 * @param numInstallments           Number of installments returned from LoanTerms.
 */
error RC_HasInstallments(uint256 numInstallments);

/**
 * @notice No interest payment or late fees due.
 *
 * @param amount                    Minimum interest plus late fee amount returned
 *                                  from minimum payment calculation.
 */
error RC_NoMinPaymentDue(uint256 amount);

/**
 * @notice Repaid amount must be larger than zero.
 */
error RC_RepayPartZero();

/**
 * @notice Amount paramater less than the minimum amount due.
 *
 * @param amount                    Amount function call parameter.
 * @param minAmount                 The minimum amount due.
 */
error RC_RepayPartLTMin(uint256 amount, uint256 minAmount);

// ==================================== Loan Core ======================================
/// @notice All errors prefixed with LC_, to separate from other contracts in the protocol.

/// @notice Zero address passed in where not allowed.
error LC_ZeroAddress();

/// @notice Borrower address is same as lender address.
error LC_ReusedNote();

/**
 * @notice Check collateral is not already used in a active loan.
 *
 * @param collateralAddress             Address of the collateral.
 * @param collateralId                  ID of the collateral token.
 */
error LC_CollateralInUse(address collateralAddress, uint256 collateralId);

/**
 * @notice Ensure valid loan state for loan lifceycle operations.
 *
 * @param state                         Current state of a loan according to LoanState enum.
 */
error LC_InvalidState(LoanLibrary.LoanState state);

/**
 * @notice Loan duration has not expired.
 *
 * @param dueDate                       Timestamp of the end of the loan duration.
 */
error LC_NotExpired(uint256 dueDate);

/**
 * @notice User address and the specified nonce have already been used.
 *
 * @param user                          Address of collateral owner.
 * @param nonce                         Represents the number of transactions sent by address.
 */
error LC_NonceUsed(address user, uint160 nonce);

/**
 * @notice Installment loan has not defaulted.
 */
error LC_LoanNotDefaulted();

// ================================== Full Insterest Amount Calc ====================================
/// @notice All errors prefixed with FIAC_, to separate from other contracts in the protocol.

/**
 * @notice Interest must be greater than 0.01%. (interestRate / 1e18 >= 1)
 *
 * @param interestRate                  InterestRate with 1e18 multiplier.
 */
error FIAC_InterestRate(uint256 interestRate);

// ==================================== Promissory Note ======================================
/// @notice All errors prefixed with PN_, to separate from other contracts in the protocol.

/**
 * @notice Deployer is allowed to initialize roles. Caller is not deployer.
 */
error PN_CannotInitialize();

/**
 * @notice Roles have been initialized.
 */
error PN_AlreadyInitialized();

/**
 * @notice Caller of mint function must have the MINTER_ROLE in AccessControl.
 *
 * @param caller                        Address of the function caller.
 */
error PN_MintingRole(address caller);

/**
 * @notice Caller of burn function must have the BURNER_ROLE in AccessControl.
 *
 * @param caller                        Address of the function caller.
 */
error PN_BurningRole(address caller);

/**
 * @notice No token transfers while contract is in paused state.
 */
error PN_ContractPaused();

// ==================================== Fee Controller ======================================
/// @notice All errors prefixed with FC_, to separate from other contracts in the protocol.

/**
 * @notice Caller attempted to set a fee which is larger than the global maximum.
 */
error FC_FeeTooLarge();

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.11;

interface ICallWhitelist {
    // ============= Events ==============

    event CallAdded(address operator, address callee, bytes4 selector);
    event CallRemoved(address operator, address callee, bytes4 selector);

    // ================ View Functions ================

    function isWhitelisted(address callee, bytes4 selector) external view returns (bool);

    // ================ Update Operations ================

    function add(address callee, bytes4 selector) external;

    function remove(address callee, bytes4 selector) external;
}