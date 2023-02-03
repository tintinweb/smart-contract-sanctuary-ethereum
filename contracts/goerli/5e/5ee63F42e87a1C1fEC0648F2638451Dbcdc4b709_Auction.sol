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
error Auction__RequireAmountToRegisterNotMet(
    string auctionId,
    uint256 value,
    uint256 requireAmountToRegister
);
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
error Auction__NoProceeds();
error Auction__WithdrawDeposit();
error Auction__BidderRetractedBid();

/**@title Decentralized Auction Platform
 * @author Decentralized Auction Platform Team
 * @notice This contract is for Decentralized Auction Platform
 * @dev This implements the auctioneer job
 */
contract Auction {
    string[] private s_auctionList;
    uint256 private s_proceeds;
    address private immutable i_owner;
    uint16 private constant CONFIRMATION_TIME = 300;
    enum BidderState {
        BIDING, // registered or bidding
        RETRACT, // retract bid
        CANCEL, // cancel auction result
        WITHDRAW, // withdaw deposit
        PAYMENT // payment complete
    }

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
    event RegisteredToBid(string auctionId, address bidder);
    event PlacedBid(string auctionId, address bidder, uint256 bidAmount);
    event RetractedBid(string auctionId, address bidder);
    event CanceledAuctionResult(string auctionId, address bidder);
    event PaymentCompeleted(string auctionId, address bidder, uint256 paidAmount);
    event Withdraw(string auctionId, address bidder);

    mapping(string => AuctionInformation) private s_auctionInformations;
    mapping(string => BidInformation[]) private s_bidInformations;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert Auction__NotOwner();
        _;
    }

    modifier isVailidAuctionId(string memory auctionId) {
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (
                keccak256(abi.encodePacked(auctionId)) ==
                keccak256(abi.encodePacked(s_auctionList[i]))
            ) {
                revert Auction__InvalidAuctionId();
            }
        }
        _;
    }

    modifier isExistAuctionId(string memory auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_auctionList.length; i++) {
            if (
                keccak256(abi.encodePacked(auctionId)) !=
                keccak256(abi.encodePacked(s_auctionList[i]))
            ) {
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
            startRegistrationTime < block.timestamp || startRegistrationTime >= endRegistrationTime
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
            s_auctionInformations[auctionId].startAuctionTime > block.timestamp ||
            s_auctionInformations[auctionId].endAuctionTime < block.timestamp
        ) {
            revert Auction__OutOfAuctionTime();
        }
        _;
    }

    modifier isValidBidAmount(string memory auctionId, uint256 bidAmount) {
        if (
            bidAmount < s_auctionInformations[auctionId].startBid ||
            bidAmount <
            getHighestBidOfAuction(auctionId) + s_auctionInformations[auctionId].priceStep
        ) {
            revert Auction__InvalidBidAmount();
        }
        _;
    }

    modifier isRegisteredBidder(string memory auctionId) {
        uint256 count = 0;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (
                s_bidInformations[auctionId][i].bidder != msg.sender &&
                s_bidInformations[auctionId][i].bidderState == BidderState.BIDING
            ) {
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
        if (
            msg.sender == s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidder &&
            s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidAmount ==
            s_bidInformations[auctionId][getIndexOfFirstOfAuction(auctionId)].bidAmount
        ) {
            uint256 dueConfirmationTime = s_auctionInformations[auctionId].endAuctionTime +
                CONFIRMATION_TIME;
            if (dueConfirmationTime < block.timestamp) {
                revert Auction__ConfirmationTimeout();
            }
        }
        if (
            msg.sender == s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidder &&
            s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidAmount ==
            s_bidInformations[auctionId][getIndexOfSecondOfAuction(auctionId)].bidAmount
        ) {
            uint256 dueConfirmationTime = s_auctionInformations[auctionId].endAuctionTime +
                CONFIRMATION_TIME *
                2;
            if (dueConfirmationTime < block.timestamp) {
                revert Auction__ConfirmationTimeout();
            }
        }
        _;
    }

    modifier isWinnerOfAuction(string memory auctionId) {
        uint256 index = getIndexOfBidder(auctionId);
        if (index == 9999) {
            revert Auction__NotRegisteredBidder();
        }
        _;
        if (
            s_bidInformations[auctionId][index].bidderState != BidderState.BIDING ||
            s_bidInformations[auctionId][index].bidAmount != getHighestBidOfAuction(auctionId)
        ) {
            revert Auction__NotWinnerOfAuction();
        }
        _;
    }
    modifier isValidPaymentAmount(string memory auctionId) {
        uint256 requirePaymentAmount = s_bidInformations[auctionId][getIndexOfBidder(auctionId)]
            .bidAmount - s_auctionInformations[auctionId].depositAmount;
        if (msg.value < requirePaymentAmount) {
            revert Auction__RequireAmountToPaymentNotMet(auctionId, requirePaymentAmount);
        }
        _;
    }

    modifier isWithdrawDeposit(string memory auctionId) {
        if (
            s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState ==
            BidderState.WITHDRAW ||
            s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState ==
            BidderState.CANCEL ||
            s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState ==
            BidderState.RETRACT
        ) {
            revert Auction__WithdrawDeposit();
        }
        _;
    }

    function isValidatedInput(
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

    modifier isStateBidding(string memory auctionId) {
        if (
            s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState !=
            BidderState.BIDING
        ) {
            revert Auction__BidderRetractedBid();
        }
        _;
    }

    function registerToBid(string memory auctionId)
        external
        payable
        isExistAuctionId(auctionId)
        isRegistrationTime(auctionId)
        isAlreadyRegisteredBidder(auctionId)
    {
        uint256 requireAmountToRegister = s_auctionInformations[auctionId].registrationFee +
            s_auctionInformations[auctionId].depositAmount;
        if (msg.value != requireAmountToRegister) {
            revert Auction__RequireAmountToRegisterNotMet(
                auctionId,
                msg.value,
                requireAmountToRegister
            );
        }
        BidInformation memory bidInformation;
        bidInformation.bidder = msg.sender;
        bidInformation.bidderState = BidderState.BIDING;
        s_bidInformations[auctionId].push(bidInformation);
        s_proceeds += s_auctionInformations[auctionId].registrationFee;
        emit RegisteredToBid(auctionId, bidInformation.bidder);
    }

    function placeBid(string memory auctionId, uint256 bidAmount)
        external
        payable
        isExistAuctionId(auctionId)
        isAuctionTime(auctionId)
        isRegisteredBidder(auctionId)
        isValidBidAmount(auctionId, bidAmount)
        isStateBidding(auctionId)
    {
        s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidAmount = bidAmount;
        emit PlacedBid(auctionId, msg.sender, bidAmount);
    }

    function retractBid(string memory auctionId)
        external
        payable
        isExistAuctionId(auctionId)
        isAuctionTime(auctionId)
        isRegisteredBidder(auctionId)
        isStateBidding(auctionId)
    {
        s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState = BidderState.RETRACT;
        s_proceeds += s_auctionInformations[auctionId].depositAmount;
        emit RetractedBid(auctionId, msg.sender);
    }

    // isWinnerOfAuction(auctionId)
    function cancelAuctionResult(string memory auctionId)
        external
        payable
        isRegisteredBidder(auctionId)
        isConfirmationTime(auctionId)
    {
        s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState = BidderState.CANCEL;
        s_proceeds += s_auctionInformations[auctionId].depositAmount;
        emit CanceledAuctionResult(auctionId, msg.sender);
    }

    function withdraw() external onlyOwner {
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function withdrawProceeds() external onlyOwner {
        if (s_proceeds <= 0) {
            revert Auction__NoProceeds();
        }
        (bool success, ) = i_owner.call{value: s_proceeds}("");
        require(success, "Transfer failed");
    }

    function withdrawDeposit(string memory auctionId) external isWithdrawDeposit(auctionId) {
        uint256 value = s_auctionInformations[auctionId].depositAmount;
        s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState = BidderState
            .WITHDRAW;
        (bool success, ) = payable(msg.sender).call{value: value}("");
        require(success, "Transfer failed");
        emit Withdraw(auctionId, msg.sender);
    }

    // isWinnerOfAuction(auctionId)
    function payment(string memory auctionId) external payable isValidPaymentAmount(auctionId) {
        s_bidInformations[auctionId][getIndexOfBidder(auctionId)].bidderState = BidderState.PAYMENT;
        s_proceeds += s_auctionInformations[auctionId].depositAmount;
        s_proceeds += msg.value;
        emit PaymentCompeleted(auctionId, msg.sender, msg.value);
    }

    function getHighestBidOfAuction(string memory auctionId) public view returns (uint256) {
        uint256 highestBid = 0;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (
                s_bidInformations[auctionId][i].bidAmount > highestBid &&
                s_bidInformations[auctionId][i].bidderState != BidderState.RETRACT &&
                s_bidInformations[auctionId][i].bidderState != BidderState.CANCEL
            ) {
                highestBid = s_bidInformations[auctionId][i].bidAmount;
            }
        }
        return highestBid;
    }

    //get index of bidder who is sender
    function getIndexOfBidder(string memory auctionId) internal view returns (uint256) {
        uint256 index = 9999;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (s_bidInformations[auctionId][i].bidder == msg.sender) {
                index = i;
            }
        }
        return index;
    }

    function getIndexOfSecondOfAuction(string memory auctionId) private returns (uint256) {
        BidInformation[] storage tempBidInformation = s_bidInformations[auctionId];
        uint256 index = getHighestBidOfAuction(auctionId);
        require(index < tempBidInformation.length);
        tempBidInformation[index] = tempBidInformation[tempBidInformation.length - 1];
        tempBidInformation.pop();
        uint256 highestIndex;
        for (uint256 i = 0; i < tempBidInformation.length; i++) {
            if (
                highestIndex < tempBidInformation[i].bidAmount &&
                tempBidInformation[i].bidderState == BidderState.BIDING
            ) {
                highestIndex = i;
            }
        }
        return highestIndex;
    }

    function getIndexOfFirstOfAuction(string memory auctionId) private view returns (uint256) {
        uint256 index = 0;
        for (uint256 i = 0; i < s_bidInformations[auctionId].length; i++) {
            if (
                index < s_bidInformations[auctionId][i].bidAmount &&
                s_bidInformations[auctionId][i].bidderState != BidderState.CANCEL &&
                s_bidInformations[auctionId][i].bidderState != BidderState.RETRACT
            ) {
                index = i;
            }
        }
        return index;
    }

    function getListAuctionId() external view returns (string[] memory) {
        return s_auctionList;
    }

    function getAuctionInformationById(string memory auctionId)
        external
        view
        isExistAuctionId(auctionId)
        returns (AuctionInformation memory)
    {
        return s_auctionInformations[auctionId];
    }

    function getBidInformationByAuctionId(string memory auctionId)
        external
        view
        isExistAuctionId(auctionId)
        returns (BidInformation[] memory)
    {
        return s_bidInformations[auctionId];
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getProceeds() public view returns (uint256) {
        return s_proceeds;
    }
}