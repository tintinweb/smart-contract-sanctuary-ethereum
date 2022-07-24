// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error Auction__BidPriceInvalid();
error Auction__NotEnoughToken();
error Auction__WinnerUnableWithdraw();
error Auction__NotTheAuctioneer();
error Auction__UnavailableAtThisState();

contract Auction {
    // Data

    // Structure to hold details of Bidder
    struct IBidder {
        uint8 token;
        uint8 deposit;
    }

    // Structure to hold details of Rule
    struct IRule {
        uint8 startingPrice;
        uint8 minimumStep;
    }

    // State Enum to define Auction's state
    enum State {
        CREATED,
        STARTED,
        CLOSING,
        CLOSED
    }

    State public state = State.CREATED; // State of Auction

    uint8 public announcementTimes = 0; // Number of announcements
    uint8 public currentPrice = 0; // Latest price is bid.
    IRule public rule; // Rule of this session
    address public currentWinner; // Current Winner, who bid the highest price.
    address public auctioneer;

    uint16 private totalDeposit = 0;

    mapping(address => IBidder) public bidders; // Mapping to hold bidders' information

    event Register(address _account, uint8 _amountToken);
    event StartSession();
    event Bid(address _bidders, uint8 _price);
    event Announce(
        address _currentWinner,
        uint8 _currentPrice,
        uint8 _announcementTimes
    );
    event Withdraw(address _withdrawer, uint _amount);
    event EndSession();

    modifier onlyAuctioneer() {
        if (msg.sender != auctioneer) revert Auction__NotTheAuctioneer();
        _;
    }

    modifier availableAtState(State _state) {
        if (state != _state) revert Auction__UnavailableAtThisState();
        _;
    }

    constructor(uint8 _startingPrice, uint8 _minimumStep) {
        // Task #1 - Initialize the Smart contract
        // + Initialize Auctioneer with address of smart contract's owner
        // + Set the starting price & minimumStep
        // + Set the current price as the Starting price

        // ** Start code here. 4 lines approximately. ** /

        auctioneer = msg.sender;
        rule.startingPrice = _startingPrice;
        rule.minimumStep = _minimumStep;
        currentPrice = _startingPrice;

        // ** End code here. ** /
    }

    // Register new Bidder
    function register(address _account, uint8 _token)
        public
        onlyAuctioneer
        availableAtState(State.CREATED)
    {
        // Task #2 - Register the bidder
        // + Initialize a Bidder with address and token are given.
        // + Initialize a Bidder's deposit with 0

        // ** Start code here. 3 lines approximately. ** /
        IBidder memory bidder = IBidder(_token, 0);
        bidders[_account] = bidder;

        emit Register(_account, _token);

        // ** End code here. **/
    }

    // Start the session.
    function startSession()
        public
        onlyAuctioneer
        availableAtState(State.CREATED)
    {
        state = State.STARTED;
        emit StartSession();
    }

    function bid(uint8 _price) public availableAtState(State.STARTED) {
        // Task #3 - Bid by Bidders
        // + Check the price with currentPirce and minimumStep. Revert if invalid.
        // + Check if the Bidder has enough token to bid. Revert if invalid.
        // + Move token to Deposit.

        address bidderAddr = msg.sender;
        IBidder storage currentBidder = bidders[bidderAddr];

        // ** Start code here.  ** /

        if (_price <= currentPrice + rule.minimumStep) revert Auction__BidPriceInvalid();
        uint8 bidDiff = _price - currentPrice;
        if (bidDiff > currentBidder.token) revert Auction__NotEnoughToken();
        currentBidder.token -= bidDiff;
        currentBidder.deposit = _price;
        emit Bid(bidderAddr, _price);

        // ** End code here. **/

        // Tracking deposit
        totalDeposit += bidDiff;

        // Update the price and the winner after this bid.
        currentPrice = _price;
        currentWinner = bidderAddr;

        // Reset the Annoucements Counter
        announcementTimes = 0;
    }

    function announce() public onlyAuctioneer availableAtState(State.STARTED) {
        // Task #4 - Handle announcement.
        // + When Auctioneer annouce, increase the counter.
        // + When Auctioneer annouced more than 3 times, switch session to Closing state.

        // ** Start code here.  ** /
        announcementTimes++;
        emit Announce(currentWinner, currentPrice, announcementTimes);
        if (announcementTimes >= 4) {
            state = State.CLOSING;
        }

        // ** End code here. **/
    }

    function getDeposit() public availableAtState(State.CLOSING) {
        // Task #5 - Handle get Deposit.
        // + Allow bidders (except Winner) to withdraw their deposit
        // + When all bidders' deposit are withdrew, close the session

        // ** Start code here.  ** /
        // HINT: Remember to decrease totalDeposit.
        if (msg.sender == currentWinner) revert Auction__WinnerUnableWithdraw();
        IBidder storage bidder = bidders[msg.sender];
        bidder.token += bidder.deposit;
        totalDeposit -= bidder.deposit;
        emit Withdraw(msg.sender, bidder.deposit);
        bidder.deposit = 0;
        // ** End code here ** /

        if (totalDeposit <= currentPrice) {
            state = State.CLOSED;
            emit EndSession();
        }
    }
}

// PART 2 - Using Modifier to:
// - Check if the action (startSession, register, bid, annoucement, getDeposit) can be done in current State.
// - Check if the current user can do the action.