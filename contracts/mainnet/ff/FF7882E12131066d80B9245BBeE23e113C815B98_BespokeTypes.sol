// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library BespokeTypes {
    struct BorrowOffer {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenAmount; // 1 for ERC721, 1+ for ERC1155
        address borrower;
        uint256 borrowAmountMin;
        uint256 borrowAmountMax;
        uint40 borrowDurationMin;
        uint40 borrowDurationMax;
        uint128 borrowRate;
        address currency;
        uint256 nonce;
        uint256 deadline;
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct LoanData {
        uint256 reserveId;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenAmount; // 1 for ERC721, 1+ for ERC1155
        address borrower;
        uint256 amount;
        uint128 borrowRate;
        uint128 interestPerSecond;
        address currency;
        uint40 borrowDuration;
        // after take offer
        uint40 borrowBegin;
        uint40 borrowOverdueTime;
        uint40 liquidatableTime;
        address lender;
        LoanStatus status;
    }

    enum LoanStatus {
        NONE,
        BORROWING,
        OVERDUE,
        LIQUIDATABLE
    }

    struct WhitelistInfo {
        bool enabled;
        uint256 minBorrowDuration;
        uint256 maxBorrowDuration;
        uint256 overdueDuration;
    }
}