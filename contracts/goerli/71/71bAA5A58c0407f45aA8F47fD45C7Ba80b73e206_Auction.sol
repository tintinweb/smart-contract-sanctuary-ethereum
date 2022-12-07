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
error Auction__InvalidBidAmount();
error Auction__NotRegisteredBidder();
error Auction__NotExistAuctionId();

contract Auction {
    uint256[] private s_auctionList;
    uint16 private constant CONFIRMATION_TIME = 300;

    struct AuctionInformation {
        uint256 startRegistrationTime;
        uint256 endRegistrationTime;
        uint256 startAuctionTime;
        uint256 endAuctionTime;
        uint256 duePaymentTime;
        uint256 registrationFee;
        uint256 depositAmount;
        uint256 startBid;
        uint256 priceStep;
    }

    struct BidInformation {
        address bidder;
        uint256 bidAmount;
    }

    event CreatedAuction(
        uint256 auctionId,
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
    event PlacedBid(uint256 auctionId, address bidder, uint256 bidAmount);
    event RegisteredToBid(uint256 auctionId, address bidder);

    mapping(uint256 => AuctionInformation) private s_AuctionInformations;
    mapping(uint256 => BidInformation[]) private s_BidInformations;
    // mapping(uint256 => BidInformation[])

    modifier isVailidAuctionId(uint256 auctionId) {
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (auctionId == s_auctionList[i]) {
                revert Auction__InvalidAuctionId();
            }
        }
        _;
    }

    modifier isExistAuctionId(uint256 auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (auctionId == s_auctionList[i]) {
                count++;
            }
        }
        if (count == s_auctionList.length) {
            revert Auction__NotExistAuctionId();
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
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            count++;
        }
        if (count == s_auctionList.length) {
            revert Auction__InvalidAuctionId();
        }
        _;
    }

    modifier isRegistrationTime(uint256 auctionId) {
        if (
            s_AuctionInformations[auctionId].startRegistrationTime < block.timestamp ||
            s_AuctionInformations[auctionId].endRegistrationTime > block.timestamp
        ) {
            revert Auction__OutOfRegistrationTime();
        }
        _;
    }
    modifier isAuctionTime(uint256 auctionId) {
        if (
            s_AuctionInformations[auctionId].startAuctionTime < block.timestamp || s_AuctionInformations[auctionId].endAuctionTime > block.timestamp
        ) {
            revert Auction__OutOfAuctionTime();
        }
        _;
    }
    modifier isValidBidAmount(uint256 auctionId, uint256 bidAmount) {
        if (
            bidAmount < s_AuctionInformations[auctionId].depositAmount ||
            bidAmount < getHightestBidOfAuction(auctionId) + s_AuctionInformations[auctionId].priceStep
        ) {
            revert Auction__InvalidBidAmount();
        }
        _;
    }
    modifier isRegisteredBidder(uint256 auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (s_BidInformations[auctionId][i].bidder != msg.sender) {
                count++;
            }
        }
        if (count == s_BidInformations[auctionId].length) {
            revert Auction__NotRegisteredBidder();
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
        uint256 auctionId,
        uint256 startRegistrationTime,
        uint256 endRegistrationTime,
        uint256 startAuctionTime,
        uint256 endAuctionTime,
        uint256 duePaymentTime,
        uint256 registrationFee,
        uint256 depositAmount,
        uint256 startBid,
        uint256 priceStep
    ) external payable {
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
            AuctionInformation memory auction;
            auction.startRegistrationTime = startRegistrationTime;
            auction.endRegistrationTime = endRegistrationTime;
            auction.startAuctionTime = startAuctionTime;
            auction.endAuctionTime = endAuctionTime;
            auction.duePaymentTime = duePaymentTime;
            auction.registrationFee = registrationFee;
            auction.depositAmount = depositAmount;
            auction.startBid = startBid;
            auction.priceStep = priceStep;
            s_AuctionInformations[auctionId] = auction;
            s_auctionList.push(auctionId);

            emit CreatedAuction(
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
            );
        }
    }

    function registerToBid(uint256 auctionId) external payable isVailidAuctionId(auctionId) isRegistrationTime(auctionId) {
        uint256 requireAmountToRegister = s_AuctionInformations[auctionId].registrationFee + s_AuctionInformations[auctionId].depositAmount;
        if (msg.value < requireAmountToRegister) {
            revert Auction__RequireAmountToRegisterNotMet(auctionId, requireAmountToRegister);
        }
        s_BidInformations[auctionId][s_BidInformations[auctionId].length].bidder = msg.sender;
        emit RegisteredToBid(auctionId, msg.sender);
    }

    function getHightestBidOfAuction(uint256 auctionId) public view returns (uint256) {
        uint256 highestBid = 0;
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (s_BidInformations[auctionId][i].bidAmount > highestBid) {
                highestBid = s_BidInformations[auctionId][i].bidAmount;
            }
        }
        return highestBid;
    }

    function getIndexOfBidder(uint256 auctionId) public view returns (uint256) {
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (s_BidInformations[auctionId][i].bidder == msg.sender) {
                return i;
            }
        }
        return 0;
    }

    function placeBid(uint256 auctionId, uint256 bidAmount)
        external
        payable
        isAuctionExist(auctionId)
        isAuctionTime(auctionId)
        isRegisteredBidder(auctionId)
        isValidBidAmount(auctionId, bidAmount)
    {
        s_BidInformations[auctionId][getIndexOfBidder(auctionId)].bidAmount = bidAmount;
        emit PlacedBid(auctionId, msg.sender, bidAmount);
    }

    function closeAuction(uint256 auctionId) external {}

    function withdaw() external {}

    function getListAuctionId() external view returns (uint256[] memory) {
        return s_auctionList;
    }

    function getListAuctionInformationById(uint256 auctionId) external view isExistAuctionId(auctionId) returns (AuctionInformation memory) {
        return s_AuctionInformations[auctionId];
    }
}