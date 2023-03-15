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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "contracts/interfaces/INoteAdapter.sol";

/**************************************************************************/
/* XY3 Interfaces (derived and/or subset) */
/**************************************************************************/

/* derived interface */
interface IXY3 {
    /* ILoanStatus */
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }

    /* ILoanStatus */
    struct LoanState {
        uint64 xy3NftId;
        StatusType status;
    }

    /* IXY3 */
    function loanDetails(
        uint32
    )
        external
        view
        returns (
            uint256 /* borrowAmount */,
            uint256 /* repayAmount */,
            uint256 /* nftTokenId */,
            address /* borrowAsset */,
            uint32 /* loanDuration */,
            uint16 /* adminShare */,
            uint64 /* loanStart */,
            address /* nftAsset */,
            bool /* isCollection */
        );

    /* ILoanStatus */
    function getLoanState(uint32 _loanId) external view returns (LoanState memory);

    /* IConfig */
    function getAddressProvider() external view returns (IAddressProvider);

    /* public state variable in LoanStatus */
    function totalNumLoans() external view returns (uint32);
}

/* derived interface */
interface IXY3Nft is IERC721 {
    /* Xy3Nft */
    struct Ticket {
        uint256 loanId;
        address minter /* xy3 address */;
    }

    /* public state variable in Xy3Nft */
    function tickets(uint256 _tokenId) external view returns (Ticket memory);

    /* Xy3Nft */
    function exists(uint256 _tokenId) external view returns (bool);
}

interface IAddressProvider {
    function getBorrowerNote() external view returns (address);

    function getLenderNote() external view returns (address);
}

/**************************************************************************/
/* Note Adapter Implementation */
/**************************************************************************/

/**
 * @title X2Y2 V2 Note Adapter
 */
contract XY3NoteAdapter is INoteAdapter {
    /**************************************************************************/
    /* Constants */
    /**************************************************************************/

    /**
     * @notice Implementation version
     */
    string public constant IMPLEMENTATION_VERSION = "1.0";

    /**
     * @notice Basis points denominator used for calculating repayment
     */
    uint256 public constant BASIS_POINTS_DENOMINATOR = 10_000;

    /**************************************************************************/
    /* Properties */
    /**************************************************************************/

    IXY3 private immutable _xy3;
    IXY3Nft private immutable _lenderNote;
    IXY3Nft private immutable _borrowerNote;

    /**************************************************************************/
    /* Constructor */
    /**************************************************************************/

    constructor(IXY3 xY3) {
        _xy3 = xY3;
        _lenderNote = IXY3Nft(_xy3.getAddressProvider().getLenderNote());
        _borrowerNote = IXY3Nft(_xy3.getAddressProvider().getBorrowerNote());
    }

    /**************************************************************************/
    /* Implementation */
    /**************************************************************************/

    /**
     * @inheritdoc INoteAdapter
     */
    function name() external pure returns (string memory) {
        return "XY3 Note Adapter";
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
        /* Validate note token exists */
        if (!_lenderNote.exists(noteTokenId)) return false;

        /* Lookup minter and loan id */
        IXY3Nft.Ticket memory ticket = _lenderNote.tickets(noteTokenId);

        /* Validate XY3 minter matches */
        if (ticket.minter != address(_xy3)) return false;

        /* Validate loan is active */
        if (_xy3.getLoanState(uint32(ticket.loanId)).status != IXY3.StatusType.NEW) return false;

        /* Lookup loan current token */
        (, , , address borrowAsset, , , , , ) = _xy3.loanDetails(uint32(ticket.loanId));

        /* Validate loan currency token matches */
        if (borrowAsset != currencyToken) return false;

        return true;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanInfo(uint256 noteTokenId) external view returns (LoanInfo memory) {
        /* Lookup minter and loan id */
        IXY3Nft.Ticket memory ticket = _lenderNote.tickets(noteTokenId);

        /* Lookup loan data */
        (
            uint256 borrowAmount,
            uint256 repayAmount,
            uint256 nftTokenId,
            address borrowAsset,
            uint32 loanDuration,
            uint16 adminShare,
            uint64 loanStart,
            address nftAsset,

        ) = _xy3.loanDetails(uint32(ticket.loanId));

        /* Lookup borrower */
        address borrower = _borrowerNote.ownerOf(noteTokenId);

        /* Calculate admin fee */
        uint256 adminFee = ((repayAmount - borrowAmount) * uint256(adminShare)) / BASIS_POINTS_DENOMINATOR;

        /* Arrange into LoanInfo structure */
        LoanInfo memory loanInfo = LoanInfo({
            loanId: ticket.loanId,
            borrower: borrower,
            principal: borrowAmount,
            repayment: repayAmount - adminFee,
            maturity: loanStart + loanDuration,
            duration: loanDuration,
            currencyToken: borrowAsset,
            collateralToken: nftAsset,
            collateralTokenId: nftTokenId
        });

        return loanInfo;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLoanAssets(uint256 noteTokenId) external view returns (AssetInfo[] memory) {
        /* Lookup minter and loan id */
        IXY3Nft.Ticket memory ticket = _lenderNote.tickets(noteTokenId);

        /* Lookup loan data */
        (, , uint256 nftTokenId, , , , , address nftAsset, ) = _xy3.loanDetails(uint32(ticket.loanId));

        /* Collect collateral assets */
        AssetInfo[] memory collateralAssets = new AssetInfo[](1);
        collateralAssets[0].token = nftAsset;
        collateralAssets[0].tokenId = nftTokenId;

        return collateralAssets;
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function getLiquidateCalldata(uint256 loanId) external view returns (address, bytes memory) {
        return (address(_xy3), abi.encodeWithSignature("liquidate(uint32)", uint32(loanId)));
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
        /* Loan status deleted on resolved loan */
        return (loanId > 10_000 && loanId <= _xy3.totalNumLoans() && _xy3.getLoanState(uint32(loanId)).xy3NftId == 0);
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isLiquidated(uint256 loanId) external view returns (bool) {
        /* Loan status deleted on resolved loan */
        return (loanId > 10_000 && loanId <= _xy3.totalNumLoans() && _xy3.getLoanState(uint32(loanId)).xy3NftId == 0);
    }

    /**
     * @inheritdoc INoteAdapter
     */
    function isExpired(uint256 loanId) external view returns (bool) {
        /* Lookup loan data */
        (, , , , uint32 loanDuration, , uint64 loanStart, , ) = _xy3.loanDetails(uint32(loanId));

        return
            _xy3.getLoanState(uint32(loanId)).status == IXY3.StatusType.NEW &&
            block.timestamp > loanStart + loanDuration;
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