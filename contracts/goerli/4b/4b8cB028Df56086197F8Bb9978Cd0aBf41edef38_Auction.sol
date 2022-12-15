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
error Auction__RequireAmountToRegisterNotMet(string auctionId, uint256 value, uint256 requireAmountToRegister);
error Auction__OutOfAuctionTime();
error Auction__InvalidBidAmount();
error Auction__NotRegisteredBidder();
error Auction__NotExistAuctionId();
error Auction__ConfirmationTimeout();
error Auction__NotWinnerOfAuction();
error Auction__TransferFailed();
error Auction__RequireAmountToPaymentNotMet(string auctionId, uint256 requirePaymentAmount);
error Auction__NotExistAuction();
error Auction__NotOwner();
error Auction__AlreadyRegisteredBidder();

/**@title Decentralized Auction
 * @author Nguyen Thanh Trung
 * @notice This contract is for Decentralized Auction Platform
 * @dev This implements the auctioneer job
 */
contract Auction {
    string[] private s_auctionList;
    address private immutable i_owner;
    uint16 private constant CONFIRMATION_TIME = 300;
    uint128 f = 34000000000000000000;
    enum BidderState {
        BIDING, //registered or bidding
        WAITING, //top 2 bidder who is watting for top 1 confirm result
        WIN, //winner
        LOSE, // top 3 or lower
        CANCEL, //cencel bid or auction result
        PAIDBACK, //paid back deposit
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

    constructor() {
        i_owner = msg.sender;
    }

    struct BidInformation {
        address bidder;
        uint256 bidAmount;
        BidderState bidderState;
    }

    event CreatedAuction(
        string auctionId,
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
    event PlacedBid(string auctionId, address bidder, uint256 bidAmount);
    event RegisteredToBid(string auctionId, address bidder, BidderState bidderState);
    event ClosedAuction(string auctionId);
    event CanceledAuctionResult(string auctionId, address bidder, BidderState bidderState);
    event Paidback(string auctionId, address bidder);
    event ClosedAuctionSucessfully(string auctionId, address bidder, uint256 paidAmount);

    mapping(string => AuctionInformation) private s_auctionInformations;
    mapping(string => BidInformation[]) private s_bidInformations;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Auction__NotOwner();
        _;
    }

    modifier isVailidAuctionId(string memory auctionId) {
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (keccak256(abi.encodePacked(auctionId)) == keccak256(abi.encodePacked(s_auctionList[i]))) {
                revert Auction__InvalidAuctionId();
            }
        }
        _;
    }

    modifier isExistAuctionId(string memory auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (keccak256(abi.encodePacked(auctionId)) != keccak256(abi.encodePacked(s_auctionList[i]))) {
                count++;
            }
        }
        if (count == s_auctionList.length) {
            revert Auction__NotExistAuctionId();
        }
        _;
    }

    modifier isValidRegistrationTime(uint256 startRegistrationTime, uint256 endRegistrationTime) {
        if (startRegistrationTime < block.timestamp || startRegistrationTime >= endRegistrationTime) {
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

    modifier isRegistrationTime(string memory auctionId) {
        if (
            s_auctionInformations[auctionId].startRegistrationTime > block.timestamp ||
            s_auctionInformations[auctionId].endRegistrationTime < block.timestamp
        ) {
            revert Auction__OutOfRegistrationTime();
        }
        _;
    }

    modifier isAuctionTime(string memory auctionId) {
        if (
            s_auctionInformations[auctionId].startAuctionTime > block.timestamp || s_auctionInformations[auctionId].endAuctionTime < block.timestamp
        ) {
            revert Auction__OutOfAuctionTime();
        }
        _;
    }

    modifier isValidBidAmount(string memory auctionId, uint256 bidAmount) {
        if (
            bidAmount < s_auctionInformations[auctionId].startBid ||
            bidAmount < getHighestBidOfAuction(auctionId) + s_auctionInformations[auctionId].priceStep
        ) {
            revert Auction__InvalidBidAmount();
        }
        _;
    }

    modifier isRegisteredBidder(string memory auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (s_bidInformations[auctionId][i].bidder != msg.sender) {
                count++;
            }
        }
        if (count == s_bidInformations[auctionId].length) {
            revert Auction__NotRegisteredBidder();
        }
        _;
    }
    modifier isAlreadyRegisteredBidder(string memory auctionId) {
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (s_bidInformations[auctionId][i].bidder == msg.sender) {
                revert Auction__AlreadyRegisteredBidder();
            }
        }
        _;
    }
    modifier isConfirmationTime(string memory auctionId) {
        if (msg.sender == s_bidInformations[auctionId][getIndexOfHighestBidOfAuction(auctionId)].bidder) {
            uint256 dueConfirmationTime = s_auctionInformations[auctionId].endAuctionTime + CONFIRMATION_TIME;
            if (dueConfirmationTime > block.timestamp) {
                revert Auction__ConfirmationTimeout();
            }
        }
        if (msg.sender == s_bidInformations[auctionId][getIndexOfSecondWinnerOfAuction(auctionId)].bidder) {
            uint256 dueConfirmationTime = s_auctionInformations[auctionId].endAuctionTime + CONFIRMATION_TIME * 2;
            if (dueConfirmationTime > block.timestamp) {
                revert Auction__ConfirmationTimeout();
            }
        }
        _;
    }

    //check sender is winner or not
    modifier isWinnerOfAuction(string memory auctionId) {
        if (s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState != BidderState.WIN) {
            revert Auction__NotWinnerOfAuction();
        }
        _;
    }

    function isValidatedInput(
        string memory auctionId, //need validate
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
        string memory auctionId,
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
            s_auctionInformations[auctionId] = auction;
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

    function registerToBid(string memory auctionId)
        external
        payable
        isExistAuctionId(auctionId)
        isRegistrationTime(auctionId)
        isAlreadyRegisteredBidder(auctionId)
    {
        uint256 requireAmountToRegister = s_auctionInformations[auctionId].registrationFee + s_auctionInformations[auctionId].depositAmount;
        if (msg.value != requireAmountToRegister) {
            revert Auction__RequireAmountToRegisterNotMet(auctionId, msg.value, requireAmountToRegister);
        }
        BidInformation memory bidInformation;
        bidInformation.bidder = msg.sender;
        bidInformation.bidderState = BidderState.BIDING;
        s_bidInformations[auctionId].push(bidInformation);
        emit RegisteredToBid(auctionId, bidInformation.bidder, bidInformation.bidderState);
    }

    function getHighestBidOfAuction(string memory auctionId) public view returns (uint256) {
        uint256 highestBid = 0;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (s_bidInformations[auctionId][i].bidAmount > highestBid && s_bidInformations[auctionId][i].bidderState != BidderState.CANCEL) {
                highestBid = s_bidInformations[auctionId][i].bidAmount;
            }
        }
        return highestBid;
    }

    //get index of bidder who is sender
    function getIndexOfBidder(string memory auctionId) internal view returns (uint256) {
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (s_bidInformations[auctionId][i].bidder == msg.sender) {
                return i;
            }
        }
        return 0;
    }

    function placeBid(string memory auctionId, uint256 bidAmount)
        external
        payable
        isExistAuctionId(auctionId)
        isAuctionTime(auctionId)
        isRegisteredBidder(auctionId)
        isValidBidAmount(auctionId, bidAmount)
    {
        s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidAmount = bidAmount;
        emit PlacedBid(auctionId, msg.sender, bidAmount);
    }

    function getIndexOfHighestBidOfAuction(string memory auctionId) public view returns (uint256) {
        uint256 highestIndex;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (highestIndex < s_bidInformations[auctionId][i].bidAmount && s_bidInformations[auctionId][i].bidderState != BidderState.CANCEL) {
                highestIndex = i;
            }
        }
        return highestIndex;
    }

    function closeAuction(string memory auctionId) external isExistAuctionId(auctionId) {
        uint256 index = getIndexOfHighestBidOfAuction(auctionId);
        s_bidInformations[auctionId][index].bidderState = BidderState.WIN;
        uint256 index2 = getIndexOfSecondWinnerOfAuction(auctionId);
        s_bidInformations[auctionId][index2].bidderState = BidderState.WAITING;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (s_bidInformations[auctionId][i].bidderState == BidderState.BIDING) {
                s_bidInformations[auctionId][i].bidderState == BidderState.LOSE;
            }
        }
        emit ClosedAuction(auctionId);
    }

    function cancelAuctionResult(string memory auctionId) external payable isConfirmationTime(auctionId) isWinnerOfAuction(auctionId) {
        if (msg.sender == s_bidInformations[auctionId][getIndexOfHighestBidOfAuction(auctionId)].bidder) {
            s_bidInformations[auctionId][getIndexOfHighestBidOfAuction(auctionId)].bidderState = BidderState.CANCEL;
            s_bidInformations[auctionId][getIndexOfSecondWinnerOfAuction(auctionId)].bidderState = BidderState.WIN;
        } else {
            s_bidInformations[auctionId][getIndexOfSecondWinnerOfAuction(auctionId)].bidderState = BidderState.CANCEL;
        }
        emit CanceledAuctionResult(auctionId, msg.sender, s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState);
    }

    function getIndexOfSecondWinnerOfAuction(string memory auctionId) public returns (uint256) {
        BidInformation[] storage tempBidInformation = s_bidInformations[auctionId];
        uint256 index = getHighestBidOfAuction(auctionId);
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

    function withdraw() public onlyOwner {
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function payback(string memory auctionId) internal {
        uint256 depositAmount = s_auctionInformations[auctionId].depositAmount;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (s_bidInformations[auctionId][i].bidderState == BidderState.LOSE) {
                bool success = payable(s_bidInformations[auctionId][i].bidder).send(depositAmount);
                // require(success, "Failed to send Ether");
                if (!success) {
                    revert Auction__TransferFailed();
                } else {
                    s_bidInformations[auctionId][i].bidderState = BidderState.PAIDBACK;
                    emit Paidback(auctionId, s_bidInformations[auctionId][i].bidder);
                }
            }
        }
    }

    modifier isValidPaymentAmount(string memory auctionId) {
        uint256 requirePaymentAmount = s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidAmount -
            s_auctionInformations[auctionId].depositAmount;
        if (msg.value != requirePaymentAmount) {
            revert Auction__RequireAmountToPaymentNotMet(auctionId, requirePaymentAmount);
        }
        _;
    }

    function payment(string memory auctionId) external payable isWinnerOfAuction(auctionId) isValidPaymentAmount(auctionId) {
        s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState = BidderState.PAID;
        emit ClosedAuctionSucessfully(auctionId, msg.sender, msg.value);
    }

    function getListAuctionId() external view returns (string[] memory) {
        return s_auctionList;
    }

    function getAuctionInformationById(string memory auctionId) external view isExistAuctionId(auctionId) returns (AuctionInformation memory) {
        return s_auctionInformations[auctionId];
    }

    function getBidInformationByAuctionId(string memory auctionId) external view isExistAuctionId(auctionId) returns (BidInformation[] memory) {
        return s_bidInformations[auctionId];
    }

    function receiver() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}