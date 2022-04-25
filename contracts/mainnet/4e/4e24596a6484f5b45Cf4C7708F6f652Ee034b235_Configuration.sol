// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./DataTypes.sol";

library Configuration {
    uint8 public constant BORROW_MASK = 0x0E;
    uint8 public constant REPAY_MASK = 0x0D;
    uint8 public constant WITHDRAW_MASK = 0x0B;
    uint8 public constant LIQUIDATE_MASK = 0x07;

    uint8 constant IS_BORROW_START_BIT_POSITION = 0;
    uint8 constant IS_REPAY_START_BIT_POSITION = 1;
    uint8 constant IS_WITHDRAW_START_BIT_POSITION = 2;
    uint8 constant IS_LIQUIDATE_START_BIT_POSITION = 3;

    function setBorrow(DataTypes.NFT storage self, bool active) internal {
        self.marks =
            (self.marks & BORROW_MASK) |
            (uint8(active ? 1 : 0) << IS_BORROW_START_BIT_POSITION);
    }

    function setRepay(DataTypes.NFT storage self, bool active) internal {
        self.marks =
            (self.marks & REPAY_MASK) |
            (uint8(active ? 1 : 0) << IS_REPAY_START_BIT_POSITION);
    }

    function setWithdraw(DataTypes.NFT storage self, bool active) internal {
        self.marks =
            (self.marks & WITHDRAW_MASK) |
            (uint8(active ? 1 : 0) << IS_WITHDRAW_START_BIT_POSITION);
    }

    function setLiquidate(DataTypes.NFT storage self, bool active) internal {
        self.marks =
            (self.marks & LIQUIDATE_MASK) |
            (uint8(active ? 1 : 0) << IS_LIQUIDATE_START_BIT_POSITION);
    }

    function getBorrow(DataTypes.NFT storage self)
        internal
        view
        returns (bool)
    {
        return self.marks & ~BORROW_MASK != 0;
    }

    function getRepay(DataTypes.NFT storage self) internal view returns (bool) {
        return self.marks & ~REPAY_MASK != 0;
    }

    function getWithdraw(DataTypes.NFT storage self)
        internal
        view
        returns (bool)
    {
        return self.marks & ~WITHDRAW_MASK != 0;
    }

    function getLiquidate(DataTypes.NFT storage self)
        internal
        view
        returns (bool)
    {
        return self.marks & ~LIQUIDATE_MASK != 0;
    }

    function getState(DataTypes.NFT storage self)
        internal
        view
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        return (
            self.marks & ~BORROW_MASK != 0,
            self.marks & ~REPAY_MASK != 0,
            self.marks & ~WITHDRAW_MASK != 0,
            self.marks & ~LIQUIDATE_MASK != 0
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

library DataTypes {
    struct COLLATERAL {
        uint256 apy;
        uint256 price;
        uint256 period;
        uint256 buffering;
        address erc20Token;
        string description;
    }

    struct OFFER {
        uint256 apy;
        uint256 price;
        uint256 period;
        uint256 buffering;
        address erc20Token;
        bool accept;
        bool cancel;
        uint256 offerId; //final sold offerId
        uint256 lTokenId; //lTokenId, the token's id given to the lender
        address user; //the person who given this offer
        uint256 fee;// The fee when the user adds an offer
    }

    struct NFT {
        address holder;
        address lender;
        uint256 nftId; // nft tokenId
        address nftAdr; // nft address
        uint256 depositId; // depositId
        uint256 lTokenId; // ltoken id
        uint256 borrowTimestamp; // borrow timestamp
        uint256 emergencyTimestamp; // emergency timestamp
        uint256 repayAmount; // repayAmount
        //bit 0: borrow
        //bit 1: repay
        //bit 2: withdraw
        //bit 3: liquidate
        uint8 marks;
        COLLATERAL collateral;
    }
}