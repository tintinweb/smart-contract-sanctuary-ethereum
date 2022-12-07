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

contract Auction {
    uint256[] private s_auctionList;
    uint16 private constant CONFIRMATION_TIME = 300;

    struct AuctionInfomation {
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

    struct BidInfomation {
        address bidder;
        uint256 bidAmount;
    }

    event CreatedAuction(
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

    mapping(uint256 => AuctionInfomation) public s_auctionInfomations;
    mapping(uint256 => BidInfomation[]) public s_bidInfomations;
    // mapping(uint256 => BidInfomation[])

    modifier isVailidAuctionId(uint256 auctionId) {
        for (uint256 i = 0; i < s_auctionList.length; i++) {
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
            s_auctionInfomations[auctionId].startRegistrationTime < block.timestamp ||
            s_auctionInfomations[auctionId].endRegistrationTime > block.timestamp
        ) {
            revert Auction__OutOfRegistrationTime();
        }
        _;
    }
    modifier isAuctionTime(uint256 auctionId) {
        if (s_auctionInfomations[auctionId].startAuctionTime < block.timestamp || s_auctionInfomations[auctionId].endAuctionTime > block.timestamp) {
            revert Auction__OutOfAuctionTime();
        }
        _;
    }
    modifier isValidBidAmount(uint256 auctionId, uint256 bidAmount) {
        if (
            bidAmount < s_auctionInfomations[auctionId].depositAmount ||
            bidAmount < getHightestBidOfAuction(auctionId) + s_auctionInfomations[auctionId].priceStep
        ) {
            revert Auction__InvalidBidAmount();
        }
        _;
    }
    modifier isRegisteredBidder(uint256 auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_bidInfomations[auctionId].length; i++) {
            if (s_bidInfomations[auctionId][i].bidder != msg.sender) {
                count++;
            }
        }
        if (count == s_bidInfomations[auctionId].length) {
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
            AuctionInfomation memory auction;
            auction.startRegistrationTime = startRegistrationTime;
            auction.endRegistrationTime = endRegistrationTime;
            auction.startAuctionTime = startAuctionTime;
            auction.endAuctionTime = endAuctionTime;
            auction.duePaymentTime = duePaymentTime;
            auction.registrationFee = registrationFee;
            auction.depositAmount = depositAmount;
            auction.startBid = startBid;
            auction.priceStep = priceStep;
            s_auctionInfomations[auctionId] = auction;
            s_auctionList.push(auctionId);

            emit CreatedAuction(
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
        uint256 requireAmountToRegister = s_auctionInfomations[auctionId].registrationFee + s_auctionInfomations[auctionId].depositAmount;
        if (msg.value < requireAmountToRegister) {
            revert Auction__RequireAmountToRegisterNotMet(auctionId, requireAmountToRegister);
        }
        s_bidInfomations[auctionId][s_bidInfomations[auctionId].length].bidder = msg.sender;
        emit RegisteredToBid(auctionId, msg.sender);
    }

    function getHightestBidOfAuction(uint256 auctionId) public view returns (uint256) {
        uint256 highestBid = 0;
        for (uint256 i = 0; i < s_bidInfomations[auctionId].length; i++) {
            if (s_bidInfomations[auctionId][i].bidAmount > highestBid) {
                highestBid = s_bidInfomations[auctionId][i].bidAmount;
            }
        }
        return highestBid;
    }

    function getIndexOfBidder(uint256 auctionId) public view returns (uint256) {
        for (uint256 i = 0; i < s_bidInfomations[auctionId].length; i++) {
            if (s_bidInfomations[auctionId][i].bidder == msg.sender) {
                return i;
            }
        }
        return 0;
    }

    function placeBid(
        uint256 auctionId,
        uint256 bidAmount
    ) external payable isAuctionExist(auctionId) isAuctionTime(auctionId) isRegisteredBidder(auctionId) isValidBidAmount(auctionId, bidAmount) {
        s_bidInfomations[auctionId][getIndexOfBidder(auctionId)].bidAmount = bidAmount;
        emit PlacedBid(auctionId, msg.sender, bidAmount);
    }

    function closeAuction() external {}

    function withdaw() external {}

    // function getAuction(uint256 auctionId) external view returns (AuctionInfomation memory) {
    //     return s_auctionInfomations[auctionId];
    // }

    // function getRankOfAuction
}