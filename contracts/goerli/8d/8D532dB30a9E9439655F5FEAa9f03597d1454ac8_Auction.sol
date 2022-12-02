// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error Auction__InvalidRegistrationTime();
error Auction__InvalidAuctionTime();
error Auction__InvalidDuePaymentTime();
error Auction__InvalidStartAuctionTime();
error Auction__InvalidRegistrationFee();
error Auction__InvalidDepositAmount();
error Auction__InvalidStartBid();
error Auction__InvalidPriceStep();
error Auction__InvalidDatetime();
error Auction__InvalidAuctionId();
error Auction__OutOfRegistrationTime();
error Auction__RequireAmountToRegisterNotMet(uint256 auctionId, uint256 requireAmountToRegister);
error Auction__OutOfAuctionTime();

contract Auction {
    uint256[] private s_listAuction;

    struct AuctionInfo {
        uint256 startRegistrationTime;
        uint256 endRegistrationTime;
        uint256 startAuctionTime;
        uint256 endAuctionTime;
        uint256 duePaymentTime;
        uint256 registrationFee;
        uint256 depositAmount;
        uint256 startBid;
        uint256 priceStep;
        address highestBidder;
        uint256 highestBid;
        address[] listBidders;
    }

    event AddedAuction(
        uint256 startRegistrationTime,
        uint256 endRegistrationTime,
        uint256 startAuctionTime,
        uint256 endAuctionTime,
        uint256 duePaymentTime,
        uint256 registrationFee,
        uint256 depositAmount,
        uint256 startBid,
        uint256 priceStep
    );

    mapping(uint256 => AuctionInfo) public s_auctions;

    modifier isVailidAuctionId(uint256 auctionId) {
        for (uint256 i = 0; i < s_listAuction.length; i++) {
            if (auctionId == i) {
                revert Auction__InvalidAuctionId();
            }
        }
        _;
    }

    modifier isValidRegistrationTime(uint256 startRegistrationTime, uint256 endRegistrationTime) {
        if (
            startRegistrationTime < block.timestamp ||
            // block.timestamp > endRegistrationTime ||
            startRegistrationTime >= endRegistrationTime
        ) {
            revert Auction__InvalidRegistrationTime();
        }
        _;
    }

    modifier isValidStartAuctionTime(uint256 endRegistrationTime, uint256 startAuctionTime) {
        if (endRegistrationTime >= startAuctionTime) {
            revert Auction__InvalidStartAuctionTime();
        }
        _;
    }

    modifier isValidAuctionTime(uint256 startAuctionTime, uint256 endAuctionTime) {
        if (startAuctionTime >= endAuctionTime) {
            revert Auction__InvalidAuctionTime();
        }
        _;
    }

    modifier isValidDuePaymentTime(uint256 endAuctionTime, uint256 duePaymentTime) {
        if (endAuctionTime >= duePaymentTime) {
            revert Auction__InvalidDuePaymentTime();
        }
        _;
    }

    modifier isValidRegistrationFee(uint256 registrationFee) {
        if (registrationFee <= 0) {
            revert Auction__InvalidRegistrationFee();
        }
        _;
    }

    modifier isValidDepositAmount(uint256 depositAmount) {
        if (depositAmount <= 0) {
            revert Auction__InvalidDepositAmount();
        }
        _;
    }

    modifier isValidStartBid(uint256 depositAmount) {
        if (depositAmount <= 0) {
            revert Auction__InvalidStartBid();
        }
        _;
    }

    modifier isValidPriceStep(uint256 depositAmount) {
        if (depositAmount <= 0) {
            revert Auction__InvalidPriceStep();
        }
        _;
    }

    modifier isAuctionExist(uint256 auctionId) {
        uint256 count;
        for (uint256 i = 0; i < s_listAuction.length; i++) {
            count++;
        }
        if (count == s_listAuction.length) {
            revert Auction__InvalidAuctionId();
        }
        _;
    }

    function isValidatedInput(
        uint256 auctionId, //need validate
        uint256 startRegistrationTime,
        uint256 endRegistrationTime,
        uint256 startAuctionTime,
        uint256 endAuctionTime,
        uint256 duePaymentTime,
        uint256 registrationFee,
        uint256 depositAmount,
        uint256 startBid,
        uint256 priceStep
    )
        internal
        view
        isVailidAuctionId(auctionId)
        isValidRegistrationTime(startRegistrationTime, endRegistrationTime)
        isValidStartAuctionTime(endRegistrationTime, startAuctionTime)
        isValidAuctionTime(startAuctionTime, endAuctionTime)
        isValidDuePaymentTime(endAuctionTime, duePaymentTime)
        isValidRegistrationFee(registrationFee)
        isValidDepositAmount(depositAmount)
        isValidStartBid(startBid)
        isValidPriceStep(priceStep)
        returns (bool)
    {
        return true;
    }

    function createAuction(
        uint256 auctionId, //need validate
        uint256 startRegistrationTime,
        uint256 endRegistrationTime,
        uint256 startAuctionTime,
        uint256 endAuctionTime,
        uint256 duePaymentTime,
        uint256 registrationFee,
        uint256 depositAmount,
        uint256 startBid,
        uint256 priceStep
    ) external {
        if (
            isValidatedInput(
                auctionId,
                startRegistrationTime,
                endRegistrationTime,
                startAuctionTime,
                endAuctionTime,
                duePaymentTime,
                registrationFee,
                depositAmount,
                startBid,
                priceStep
            )
        ) {
            AuctionInfo memory auction;
            auction.startRegistrationTime = startRegistrationTime;
            auction.endRegistrationTime = endRegistrationTime;
            auction.startAuctionTime = startAuctionTime;
            auction.endAuctionTime = endAuctionTime;
            auction.duePaymentTime = duePaymentTime;
            auction.registrationFee = registrationFee;
            auction.depositAmount = depositAmount;
            auction.startBid = startBid;
            auction.priceStep = priceStep;
            // auction.highestBidder = address(0);
            // auction.highestBid = 0;
            s_auctions[auctionId] = auction;
            s_listAuction.push(auctionId);
            emit AddedAuction(
                startRegistrationTime,
                endRegistrationTime,
                startAuctionTime,
                endAuctionTime,
                duePaymentTime,
                registrationFee,
                depositAmount,
                startBid,
                priceStep
            );
        }
    }

    modifier isRegistrationTime(uint256 auctionId) {
        if (
            s_auctions[auctionId].startRegistrationTime < block.timestamp ||
            s_auctions[auctionId].endRegistrationTime > block.timestamp
        ) {
            revert Auction__OutOfRegistrationTime();
        }
        _;
    }

    function registerToBid(uint256 auctionId)
        external
        payable
        isVailidAuctionId(auctionId)
        isRegistrationTime(auctionId)
    {
        uint256 requireAmountToRegister = s_auctions[auctionId].registrationFee +
            s_auctions[auctionId].depositAmount;
        if (msg.value < requireAmountToRegister) {
            revert Auction__RequireAmountToRegisterNotMet(auctionId, requireAmountToRegister);
        }
        s_auctions[auctionId].listBidders.push(msg.sender);
    }

    modifier isAuctionTime(uint256 auctionId) {
        if (
            s_auctions[auctionId].startAuctionTime < block.timestamp ||
            s_auctions[auctionId].endAuctionTime > block.timestamp
        ) {
            revert Auction__OutOfAuctionTime();
        }
        _;
    }

    function placeBid(uint256 auctionId)
        external
        payable
        isAuctionExist(auctionId)
        isAuctionTime(auctionId)
    {
        if (msg.value > s_auctions[auctionId].highestBid) {
            s_auctions[auctionId].highestBid = msg.value;
            s_auctions[auctionId].highestBidder = msg.sender;
        }
    }

    function getAuction(uint256 auctionId) external view returns (AuctionInfo memory) {
        return s_auctions[auctionId];
    }
}