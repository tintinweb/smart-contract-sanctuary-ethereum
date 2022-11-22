// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "contracts/interfaces/INoteAdapter.sol";

/**************************************************************************/
/* NFTfiV2 Interfaces (subset) */
/**************************************************************************/

interface IDirectLoan {
    function LOAN_TYPE() external view returns (bytes32);

    function loanIdToLoan(uint32)
        external
        view
        returns (
            uint256, /* loanPrincipalAmount */
            uint256, /* maximumRepaymentAmount */
            uint256, /* nftCollateralId */
            address, /* loanERC20Denomination */
            uint32, /* loanDuration */
            uint16, /* loanInterestRateForDurationInBasisPoints */
            uint16, /* loanAdminFeeInBasisPoints */
            address, /* nftCollateralWrapper */
            uint64, /* loanStartTime */
            address, /* nftCollateralContract */
            address /* borrower */
        );
}

interface IDirectLoanCoordinator {
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    struct Loan {
        address loanContract;
        uint64 smartNftId;
        StatusType status;
    }

    function promissoryNoteToken() external view returns (address);

    function getLoanData(uint32 _loanId) external view returns (Loan memory);

    function getContractFromType(bytes32 _loanType) external view returns (address);
}

interface ISmartNft {
    function loans(uint256 _tokenId)
        external
        view
        returns (
            address, /* loanCoordinator */
            uint256 /* loanId */
        );

    function exists(uint256 _tokenId) external view returns (bool);
}

/**************************************************************************/
/* Note Adapter Implementation */
/**************************************************************************/

/**
 * @title NFTfiV2 Note Adapter
 */
contract NFTfiV2NoteAdapter is INoteAdapter {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.2";

    /**
     * @notice Supported loan type
     */
    bytes32 public constant SUPPORTED_LOAN_TYPE = bytes32("DIRECT_LOAN_FIXED_REDEPLOY");

    /**************************************************************************/
    /* Properties */
    /**************************************************************************/

    IDirectLoanCoordinator private immutable _directLoanCoordinator;
    ISmartNft private immutable _noteToken;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    /**
     * @notice NFTfiV2NoteAdapter constructor
     * @param directLoanCoordinator Direct loan coordinator contract
     */
    constructor(IDirectLoanCoordinator directLoanCoordinator) {
        _directLoanCoordinator = directLoanCoordinator;
        _noteToken = ISmartNft(directLoanCoordinator.promissoryNoteToken());
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc INoteAdapter
     */
    function name() external pure returns (string memory) {
        return "NFTfi v2 Note Adapter";
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function noteToken() external view returns (IERC721) {
        return IERC721(address(_noteToken));
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isSupported(uint256 noteTokenId, address currencyToken) external view returns (bool) {
        /* Lookup loan coordinator and loan id */
        (address loanCoordinator, uint256 loanId) = _noteToken.loans(noteTokenId);

        /* Validate loan coordinator matches */
        if (loanCoordinator != address(_directLoanCoordinator)) return false;

        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Validate loan is active */
        if (loanData.status != IDirectLoanCoordinator.StatusType.NEW) return false;

        /* Get loan contract */
        IDirectLoan loanContract = IDirectLoan(loanData.loanContract);

        /* Validate loan type matches */
        if (loanContract.LOAN_TYPE() != SUPPORTED_LOAN_TYPE) return false;

        /* Lookup loan currency token */
        (, , , address loanERC20Denomination, , , , , , , ) = loanContract.loanIdToLoan(uint32(loanId));

        /* Validate loan currency token matches */
        if (loanERC20Denomination != currencyToken) return false;

        return true;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanInfo(uint256 noteTokenId) external view returns (LoanInfo memory) {
        /* Lookup loan id */
        (, uint256 loanId) = _noteToken.loans(noteTokenId);

        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Get loan contract */
        IDirectLoan loanContract = IDirectLoan(loanData.loanContract);

        /* Lookup loan terms */
        (
            uint256 loanPrincipalAmount,
            uint256 maximumRepaymentAmount,
            uint256 nftCollateralId,
            address loanERC20Denomination,
            uint32 loanDuration,
            ,
            uint16 loanAdminFeeInBasisPoints,
            ,
            uint64 loanStartTime,
            address nftCollateralContract,
            address borrower
        ) = loanContract.loanIdToLoan(uint32(loanId));

        /* Calculate admin fee */
        uint256 adminFee = ((maximumRepaymentAmount - loanPrincipalAmount) * uint256(loanAdminFeeInBasisPoints)) /
            10000;

        /* Arrange into LoanInfo structure */
        LoanInfo memory loanInfo = LoanInfo({
            loanId: loanId,
            borrower: borrower,
            principal: loanPrincipalAmount,
            repayment: maximumRepaymentAmount - adminFee,
            maturity: loanStartTime + loanDuration,
            duration: loanDuration,
            currencyToken: loanERC20Denomination,
            collateralToken: nftCollateralContract,
            collateralTokenId: nftCollateralId
        });

        return loanInfo;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanAssets(uint256 noteTokenId) external view returns (AssetInfo[] memory) {
        /* Lookup loan id */
        (, uint256 loanId) = _noteToken.loans(noteTokenId);

        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Get loan contract */
        IDirectLoan loanContract = IDirectLoan(loanData.loanContract);

        /* Lookup loan terms */
        (, , uint256 nftCollateralId, , , , , , , address nftCollateralContract, ) = loanContract.loanIdToLoan(
            uint32(loanId)
        );

        /* Collect collateral assets */
        AssetInfo[] memory collateralAssets = new AssetInfo[](1);
        collateralAssets[0].token = nftCollateralContract;
        collateralAssets[0].tokenId = nftCollateralId;

        return collateralAssets;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLiquidateCalldata(uint256 loanId) external view returns (address, bytes memory) {
        /* Lookup loan data for loan contract */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        return (loanData.loanContract, abi.encodeWithSignature("liquidateOverdueLoan(uint32)", uint32(loanId)));
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
        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* No way to differentiate a repaid loan from a liquidated loan from just loanId */
        return loanData.status == IDirectLoanCoordinator.StatusType.RESOLVED;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isLiquidated(uint256 loanId) external view returns (bool) {
        /* Lookup loan data */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* No way to differentiate a repaid loan from a liquidated loan from just loanId */
        return loanData.status == IDirectLoanCoordinator.StatusType.RESOLVED;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isExpired(uint256 loanId) external view returns (bool) {
        /* Lookup loan data for loan contract */
        IDirectLoanCoordinator.Loan memory loanData = _directLoanCoordinator.getLoanData(uint32(loanId));

        /* Lookup loan terms */
        (, , , , uint32 loanDuration, , , , uint64 loanStartTime, , ) = IDirectLoan(loanData.loanContract).loanIdToLoan(
            uint32(loanId)
        );

        return
            loanData.status == IDirectLoanCoordinator.StatusType.NEW && block.timestamp > loanStartTime + loanDuration;
    }
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
     * @notice Asset information
     * @param token Token contract
     * @param tokenId Token ID
     */
    struct AssetInfo {
        address token;
        uint256 tokenId;
    }

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
     * @notice Get loan collateral assets
     * @param noteTokenId Note token ID
     * @return Loan collateral assets
     */
    function getLoanAssets(uint256 noteTokenId) external view returns (AssetInfo[] memory);

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