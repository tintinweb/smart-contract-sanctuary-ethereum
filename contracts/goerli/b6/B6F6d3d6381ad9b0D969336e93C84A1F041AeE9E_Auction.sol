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
error Auction__RequireAmountToRegisterNotMet(bytes32 auctionId, uint256 requireAmountToRegister);
error Auction__OutOfAuctionTime();
error Auction__InvalidBidAmount();
error Auction__NotRegisteredBidder();
error Auction__NotExistAuctionId();
error Auction__ConfirmationTimeout();
error Auction__NotWinnerOfAuction();
error Auction__TransferFailed();
error Auction__RequireAmountToPaymentNotMet(bytes32 auctionId, uint256 requirePaymentAmount);

/**@title Decentralized Auction
 * @author Nguyen Thanh Trung
 * @notice This contract is for Decentralized Auction Platform
 * @dev This implements the auctioneer job
 */
contract Auction {
    bytes32[] private s_auctionList;
    uint16 private constant CONFIRMATION_TIME = 300;
    enum BidderState {
        BIDING, //registered or bidding
        WAITING, //top 2 bidder who is watting for top 1 confirm result
        WIN, //winner
        LOSE, // top 3 or lower
        CANCEL, //cencel bid or auction result
        WITHDEW, //paid back deposit
        PAID // payment complete
    }

    struct AuctionInformation {
        // bytes10
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
        BidderState bidderState;
    }

    event CreatedAuction(
        bytes32 auctionId,
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
    event PlacedBid(bytes32 auctionId, address bidder, uint256 bidAmount);
    event RegisteredToBid(bytes32 auctionId, address bidder, BidderState bidderState);
    event ClosedAuction(bytes32 auctionId);
    event CanceledAuctionResult(bytes32 auctionId, address bidder, BidderState bidderState);
    event Withdrew(bytes32 auctionId, address bidder);
    event ClosedAuctionSucessfully(bytes32 auctionId, address bidder, uint256 paidAmount);
    event TestDB(uint256 k);

    mapping(bytes32 => AuctionInformation) private s_AuctionInformations;
    mapping(bytes32 => BidInformation[]) private s_BidInformations;

    modifier isVailidAuctionId(bytes32 auctionId) {
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (auctionId == s_auctionList[i]) {
                revert Auction__InvalidAuctionId();
            }
        }
        _;
    }

    modifier isExistAuctionId(bytes32 auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (auctionId != s_auctionList[i]) {
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

    modifier isAuctionExist(bytes32 auctionId) {
        uint256 count;
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            count++;
        }
        if (count == s_auctionList.length) {
            revert Auction__InvalidAuctionId();
        }
        _;
    }

    modifier isRegistrationTime(bytes32 auctionId) {
        if (
            s_AuctionInformations[auctionId].startRegistrationTime < block.timestamp ||
            s_AuctionInformations[auctionId].endRegistrationTime > block.timestamp
        ) {
            revert Auction__OutOfRegistrationTime();
        }
        _;
    }

    modifier isAuctionTime(bytes32 auctionId) {
        if (
            s_AuctionInformations[auctionId].startAuctionTime < block.timestamp || s_AuctionInformations[auctionId].endAuctionTime > block.timestamp
        ) {
            revert Auction__OutOfAuctionTime();
        }
        _;
    }

    modifier isValidBidAmount(bytes32 auctionId, uint256 bidAmount) {
        if (
            bidAmount < s_AuctionInformations[auctionId].depositAmount ||
            bidAmount < getHightestBidOfAuction(auctionId) + s_AuctionInformations[auctionId].priceStep
        ) {
            revert Auction__InvalidBidAmount();
        }
        _;
    }

    modifier isRegisteredBidder(bytes32 auctionId) {
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

    modifier isConfirmationTime(bytes32 auctionId) {
        if (msg.sender == s_BidInformations[auctionId][getIndexOfHighestBidOfAuction(auctionId)].bidder) {
            uint256 dueConfirmationTime = s_AuctionInformations[auctionId].endAuctionTime + CONFIRMATION_TIME;
            if (dueConfirmationTime > block.timestamp) {
                revert Auction__ConfirmationTimeout();
            }
        }
        if (msg.sender == s_BidInformations[auctionId][getIndexOfSecondWinnerOfAuction(auctionId)].bidder) {
            uint256 dueConfirmationTime = s_AuctionInformations[auctionId].endAuctionTime + CONFIRMATION_TIME * 2;
            if (dueConfirmationTime > block.timestamp) {
                revert Auction__ConfirmationTimeout();
            }
        }
        _;
    }

    //check sender is winner or not
    modifier isWinnerOfAuction(bytes32 auctionId) {
        if (s_BidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState != BidderState.WIN) {
            revert Auction__NotWinnerOfAuction();
        }
        _;
    }

    function isValidatedInput(
        bytes32 auctionId, //need validate
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
        bytes32 auctionId,
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

    function registerToBid(bytes32 auctionId) external payable isVailidAuctionId(auctionId) isRegistrationTime(auctionId) {
        uint256 requireAmountToRegister = s_AuctionInformations[auctionId].registrationFee + s_AuctionInformations[auctionId].depositAmount;
        if (msg.value < requireAmountToRegister) {
            revert Auction__RequireAmountToRegisterNotMet(auctionId, requireAmountToRegister);
        }
        s_BidInformations[auctionId][s_BidInformations[auctionId].length].bidder = msg.sender;
        s_BidInformations[auctionId][s_BidInformations[auctionId].length].bidderState = BidderState.BIDING;
        emit RegisteredToBid(auctionId, msg.sender, s_BidInformations[auctionId][s_BidInformations[auctionId].length].bidderState);
    }

    function getHightestBidOfAuction(bytes32 auctionId) public view returns (uint256) {
        uint256 highestBid = 0;
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (s_BidInformations[auctionId][i].bidAmount > highestBid && s_BidInformations[auctionId][i].bidderState != BidderState.CANCEL) {
                highestBid = s_BidInformations[auctionId][i].bidAmount;
            }
        }
        return highestBid;
    }

    //get index of bidder who is sender
    function getIndexOfBidder(bytes32 auctionId) internal view returns (uint256) {
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (s_BidInformations[auctionId][i].bidder == msg.sender) {
                return i;
            }
        }
        return 0;
    }

    function placeBid(bytes32 auctionId, uint256 bidAmount)
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

    function getIndexOfHighestBidOfAuction(bytes32 auctionId) public view returns (uint256) {
        uint256 highestIndex;
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (highestIndex < s_BidInformations[auctionId][i].bidAmount && s_BidInformations[auctionId][i].bidderState != BidderState.CANCEL) {
                highestIndex = i;
            }
        }
        return highestIndex;
    }

    function closeAuction(bytes32 auctionId) external isExistAuctionId(auctionId) {
        uint256 index = getIndexOfHighestBidOfAuction(auctionId);
        s_BidInformations[auctionId][index].bidderState = BidderState.WIN;
        uint256 index2 = getIndexOfSecondWinnerOfAuction(auctionId);
        s_BidInformations[auctionId][index2].bidderState = BidderState.WAITING;
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (s_BidInformations[auctionId][i].bidderState == BidderState.BIDING) {
                s_BidInformations[auctionId][i].bidderState == BidderState.LOSE;
            }
        }
        emit ClosedAuction(auctionId);
    }

    function cancelAuctionResult(bytes32 auctionId) external payable isConfirmationTime(auctionId) isWinnerOfAuction(auctionId) {
        if (msg.sender == s_BidInformations[auctionId][getIndexOfHighestBidOfAuction(auctionId)].bidder) {
            s_BidInformations[auctionId][getIndexOfHighestBidOfAuction(auctionId)].bidderState = BidderState.CANCEL;
            s_BidInformations[auctionId][getIndexOfSecondWinnerOfAuction(auctionId)].bidderState = BidderState.WIN;
        } else {
            s_BidInformations[auctionId][getIndexOfSecondWinnerOfAuction(auctionId)].bidderState = BidderState.CANCEL;
        }
        emit CanceledAuctionResult(auctionId, msg.sender, s_BidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState);
    }

    function getIndexOfSecondWinnerOfAuction(bytes32 auctionId) public returns (uint256) {
        BidInformation[] storage tempBidInformation = s_BidInformations[auctionId];
        uint256 index = getHightestBidOfAuction(auctionId);
        require(index < tempBidInformation.length);
        tempBidInformation[index] = tempBidInformation[tempBidInformation.length - 1];
        tempBidInformation.pop();
        uint256 highestIndex;
        for (uint256 i = 0; i < tempBidInformation.length; i++) {
            if (highestIndex < tempBidInformation[i].bidAmount) {
                highestIndex = i;
            }
        }
        return highestIndex;
    }

    function withdaw(bytes32 auctionId) internal {
        uint256 depositAmount = s_AuctionInformations[auctionId].depositAmount;
        for (uint256 i = 0; i < s_BidInformations[auctionId].length; i++) {
            if (s_BidInformations[auctionId][i].bidderState == BidderState.LOSE) {
                bool success = payable(s_BidInformations[auctionId][i].bidder).send(depositAmount);
                // require(success, "Failed to send Ether");
                if (!success) {
                    revert Auction__TransferFailed();
                } else {
                    s_BidInformations[auctionId][i].bidderState = BidderState.WITHDEW;
                    emit Withdrew(auctionId, s_BidInformations[auctionId][i].bidder);
                }
            }
        }
    }

    modifier isValidPaymentAmount(bytes32 auctionId) {
        uint256 requirePaymentAmount = s_BidInformations[auctionId][getIndexOfBidder(auctionId)].bidAmount -
            s_AuctionInformations[auctionId].depositAmount;
        if (msg.value != requirePaymentAmount) {
            revert Auction__RequireAmountToPaymentNotMet(auctionId, requirePaymentAmount);
        }
        _;
    }

    function payment(bytes32 auctionId) external payable isWinnerOfAuction(auctionId) isValidPaymentAmount(auctionId) {
        s_BidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState = BidderState.PAID;
        emit ClosedAuctionSucessfully(auctionId, msg.sender, msg.value);
    }

    function getListAuctionId() external view returns (bytes32[] memory) {
        return s_auctionList;
    }

    function getAuctionInformationById(bytes32 auctionId) external view isExistAuctionId(auctionId) returns (AuctionInformation memory) {
        return s_AuctionInformations[auctionId];
    }

    function getBidInformationByAuctionId(bytes32 auctionId) external view isExistAuctionId(auctionId) returns (BidInformation[] memory) {
        return s_BidInformations[auctionId];
    }

    function testDB(uint256 k) external {
        emit TestDB(k);
    }
}