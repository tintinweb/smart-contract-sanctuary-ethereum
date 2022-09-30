// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "contracts/interfaces/INoteAdapter.sol";

import "./LoanLibrary.sol";

/**************************************************************************/
/* ArcadeV2 Interfaces (subset) */
/**************************************************************************/

interface ILoanCore {
    function getLoan(uint256 loanId) external view returns (LoanLibrary.LoanData calldata loanData);

    function borrowerNote() external returns (IERC721);

    function lenderNote() external returns (IERC721);
}

interface IRepaymentController {
    function claim(uint256 loanId) external;
}

/**************************************************************************/
/* Note Adapter Implementation */
/**************************************************************************/

/**
 * @title ArcadeV2 Note Adapter
 */
contract ArcadeV2NoteAdapter is INoteAdapter {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /**
     * @notice Interest rate denominator used for calculating repayment
     */
    uint256 public constant INTEREST_RATE_DENOMINATOR = 1e18;

    /**
     * @notice Basis points denominator used for calculating repayment
     */
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10_000;

    /**************************************************************************/
    /* Properties */
    /**************************************************************************/

    ILoanCore private immutable _loanCore;
    IERC721 private immutable _borrowerNote;
    IERC721 private immutable _lenderNote;
    IRepaymentController private immutable _repaymentController;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice ArcadeV2NoteAdapter constructor
     * @param loanCore Loan core contract
     */
    constructor(ILoanCore loanCore, IRepaymentController repaymentController) {
        _loanCore = loanCore;
        _borrowerNote = loanCore.borrowerNote();
        _lenderNote = loanCore.lenderNote();
        _repaymentController = repaymentController;
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc INoteAdapter
     */
    function name() external pure returns (string memory) {
        return "Arcade v2 Note Adapter";
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function noteToken() external view returns (IERC721) {
        return IERC721(address(_lenderNote));
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isSupported(uint256 noteTokenId, address currencyToken) external view returns (bool) {
        /* Lookup loan data */
        LoanLibrary.LoanData memory loanData = _loanCore.getLoan(noteTokenId);

        /* Vadiate loan state is active */
        if (loanData.state != LoanLibrary.LoanState.Active) return false;

        /* Validate loan is a single installment */
        if (loanData.terms.numInstallments != 0) return false;

        /* Validate loan currency token matches */
        if (loanData.terms.payableCurrency != currencyToken) return false;

        return true;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanInfo(uint256 noteTokenId) external view returns (LoanInfo memory) {
        /* Lookup loan data */
        LoanLibrary.LoanData memory loanData = _loanCore.getLoan(noteTokenId);

        /* Calculate repayment */
        uint256 principal = loanData.terms.principal;
        uint256 repayment = principal +
            (principal * loanData.terms.interestRate) /
            INTEREST_RATE_DENOMINATOR /
            BASIS_POINTS_DENOMINATOR;

        /* Arrange into LoanInfo structure */
        LoanInfo memory loanInfo = LoanInfo({
            loanId: noteTokenId,
            borrower: _borrowerNote.ownerOf(noteTokenId),
            principal: principal,
            repayment: repayment,
            maturity: uint64(loanData.startDate + loanData.terms.durationSecs),
            duration: uint64(loanData.terms.durationSecs),
            currencyToken: loanData.terms.payableCurrency,
            collateralToken: loanData.terms.collateralAddress,
            collateralTokenId: loanData.terms.collateralId
        });

        return loanInfo;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLiquidateCalldata(uint256 loanId) external view returns (address, bytes memory) {
        return (address(_repaymentController), abi.encodeWithSignature("claim(uint256)", loanId));
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getUnwrapCalldata(uint256) external pure returns (address, bytes memory) {
        return (address(0), "");
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isRepaid(uint256 loanId) external view returns (bool) {
        return _loanCore.getLoan(loanId).state == LoanLibrary.LoanState.Repaid;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isLiquidated(uint256 loanId) external view returns (bool) {
        return _loanCore.getLoan(loanId).state == LoanLibrary.LoanState.Defaulted;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isExpired(uint256 loanId) external view returns (bool) {
        /* Lookup loan data */
        LoanLibrary.LoanData memory loanData = _loanCore.getLoan(loanId);

        return
            loanData.state == LoanLibrary.LoanState.Active &&
            block.timestamp > loanData.startDate + loanData.terms.durationSecs;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title Interface to a note adapter, a generic interface to a lending
 * platform
 */
interface INoteAdapter {
    /**************************************************************************/
    /* Structures */
    /**************************************************************************/

    /**
     * @notice Loan information
     * @param loanId Loan ID
     * @param borrower Borrower
     * @param principal Principal value
     * @param repayment Repayment value
     * @param maturity Maturity in seconds since Unix epoch
     * @param duration Duration in seconds
     * @param currencyToken Currency token used by loan
     * @param collateralToken Collateral token contract
     * @param collateralTokenId Collateral token ID
     */
    struct LoanInfo {
        uint256 loanId;
        address borrower;
        uint256 principal;
        uint256 repayment;
        uint64 maturity;
        uint64 duration;
        address currencyToken;
        address collateralToken;
        uint256 collateralTokenId;
    }

    /**************************************************************************/
    /* Primary API */
    /**************************************************************************/

    /**
     * @notice Get note adapter name
     * @return Note adapter name
     */
    function name() external view returns (string memory);

    /**
     * @notice Get note token of lending platform
     * @return Note token contract
     */
    function noteToken() external view returns (IERC721);

    /**
     * @notice Check if loan is supported by Vault
     * @param noteTokenId Note token ID
     * @param currencyToken Currency token used by Vault
     * @return True if supported, otherwise false
     */
    function isSupported(uint256 noteTokenId, address currencyToken) external view returns (bool);

    /**
     * @notice Get loan information
     * @param noteTokenId Note token ID
     * @return Loan information
     */
    function getLoanInfo(uint256 noteTokenId) external view returns (LoanInfo memory);

    /**
     * @notice Get target and calldata to liquidate loan
     * @param loanId Loan ID
     * @return Target address
     * @return Encoded calldata with selector
     */
    function getLiquidateCalldata(uint256 loanId) external view returns (address, bytes memory);

    /**
     * @notice Get target and calldata to unwrap collateral
     * @param loanId Loan ID
     * @return Target address
     * @return Encoded calldata with selector
     */
    function getUnwrapCalldata(uint256 loanId) external view returns (address, bytes memory);

    /**
     * @notice Check if loan is repaid
     * @param loanId Loan ID
     * @return True if repaid, otherwise false
     */
    function isRepaid(uint256 loanId) external view returns (bool);

    /**
     * @notice Check if loan is liquidated
     * @param loanId Loan ID
     * @return True if liquidated, otherwise false
     */
    function isLiquidated(uint256 loanId) external view returns (bool);

    /**
     * @notice Check if loan is expired
     * @param loanId Loan ID
     * @return True if expired, otherwise false
     */
    function isExpired(uint256 loanId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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