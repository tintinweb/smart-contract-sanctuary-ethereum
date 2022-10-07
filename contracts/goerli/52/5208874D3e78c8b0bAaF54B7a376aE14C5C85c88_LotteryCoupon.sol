// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract LotteryCoupon {
    //error
    error isNotowner(address);
    error noLotteryCreated();
    error lotteryNotStarted();
    error unableToMint(uint256 ticketNumber);
    error lotteryNotStopped();
    error winnerNotDeclared();

    //event
    event Lottery_Created(
        address creator,
        address contractAddress,
        uint256 time,
        string lotteryName,
        uint32 lotteryId,
        uint256 prizeInAzitoken,
        uint256 noOfTickets
    );
    event Lottery_Started();
    event Lottery_TokenMinted(address indexed buyer, uint256 ticketNumber);
    event Lottery_Stopped();
    event Lottery_Expired(uint256 time);
    event Lottery_Winner_Declared(
        address winner,
        string lotteryName,
        uint256 prize,
        uint256 ticketNumber
    );

    //immutables
    address private immutable i_owner;
    uint32 private immutable i_lotteryId;
    bytes32 private immutable i_lotteryName;
    uint32 private immutable i_prizeInAzitoken;
    uint256 private immutable i_noOfTickets;

    //structures
    struct LotteryTicketStruct {
        uint32 lotteryId;
        string lotteryName;
        uint256 ticketNo;
        address owner;
        uint256 createdAt;
    }
    struct LotteryStruct {
        string lotteryName;
        uint256 lotteryId;
        uint256 startTime;
        lotteryState state;
        uint256 noOfTickets;
        uint256 prizeInAzitoken;
        address creator;
    }
    struct WinnerTicketStruct {
        string lotteryName;
        address winnerAddress;
        uint32 lotteryId;
        uint256 winnerTicketIndex;
        uint256 prizeInAzitoken;
    }

    //storage variables
    LotteryStruct private s_lottery;
    uint256[] private s_soldTikcets;
    uint256 private s_winnerTicketIndex;
    WinnerTicketStruct private s_winner;
    uint256 s_winnerArrayIndex;

    //mappings
    mapping(address => LotteryTicketStruct[]) private m_allotedLotteryTickets;
    mapping(uint256 => bool) private m_soldTickets;
    mapping(uint256 => address) private m_ticketOwner;
    mapping(address => uint256[]) private m_ownedTickets;

    //enums
    enum lotteryState {
        NO_STATE,
        LOTTERY_CREATED,
        LOTTERY_STARTED,
        LOTTERY_STOPPED,
        LOTTERY_WINNER_DECLARED,
        LOTTERY_EXPIRED
    }

    //modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert isNotowner(msg.sender);
        }
        _;
    }
    modifier isCreationAllowed() {
        if (s_lottery.state != lotteryState.NO_STATE) {
            revert noLotteryCreated();
        }
        _;
    }
    modifier isLotteryCreated() {
        if (s_lottery.state != lotteryState.LOTTERY_CREATED) {
            revert noLotteryCreated();
        }
        _;
    }
    modifier isMintingValid() {
        if (s_lottery.state != lotteryState.LOTTERY_STARTED) {
            revert lotteryNotStarted();
        }
        _;
    }
    modifier isMintingStopped() {
        if (s_lottery.state != lotteryState.LOTTERY_STOPPED) {
            revert lotteryNotStopped();
        }
        _;
    }
    modifier isWinnerDeclared() {
        if (s_lottery.state != lotteryState.LOTTERY_WINNER_DECLARED) {
            revert lotteryNotStarted();
        }
        _;
    }

    //constructor
    constructor(
        uint32 lotteryId_,
        string memory lotteryName_,
        uint32 prizeInAzitoken_,
        uint256 noOfTickets_
    ) {
        i_owner = msg.sender;
        i_lotteryId = lotteryId_;
        i_lotteryName = bytes32(bytes(lotteryName_));
        i_prizeInAzitoken = prizeInAzitoken_;
        i_noOfTickets = noOfTickets_;
    }

    //buisness logic
    function createLottery() public onlyOwner isCreationAllowed {
        s_lottery = LotteryStruct({
            lotteryName: getLotteryName(),
            lotteryId: i_lotteryId,
            startTime: block.timestamp,
            state: lotteryState.LOTTERY_CREATED,
            noOfTickets: i_noOfTickets + 1,
            prizeInAzitoken: i_prizeInAzitoken,
            creator: i_owner
        });

        emit Lottery_Created(
            i_owner,
            address(this),
            block.timestamp,
            getLotteryName(),
            i_lotteryId,
            i_prizeInAzitoken,
            i_noOfTickets
        );
    }

    function startLottery() external onlyOwner isLotteryCreated {
        s_lottery.state = lotteryState.LOTTERY_STARTED;

        emit Lottery_Started();
    }

    function mintLottery(address buyer_, uint256 ticketNumber_)
        external
        onlyOwner
        isMintingValid
    {
        if (
            m_soldTickets[ticketNumber_] == true ||
            ticketNumber_ <= 0 ||
            ticketNumber_ > i_noOfTickets
        ) {
            revert unableToMint(ticketNumber_);
        }
        m_allotedLotteryTickets[buyer_].push(
            LotteryTicketStruct({
                lotteryId: i_lotteryId,
                lotteryName: getLotteryName(),
                ticketNo: ticketNumber_,
                owner: buyer_,
                createdAt: block.timestamp
            })
        );
        s_soldTikcets.push(ticketNumber_);
        m_soldTickets[ticketNumber_] = true;
        m_ticketOwner[ticketNumber_] = buyer_;
        m_ownedTickets[buyer_].push(ticketNumber_);

        emit Lottery_TokenMinted(buyer_, ticketNumber_);
    }

    function stopLottery() external onlyOwner isMintingValid {
        s_lottery.state = lotteryState.LOTTERY_STOPPED;

        emit Lottery_Stopped();
    }

    function spinLottery() external onlyOwner isMintingStopped {
        s_winnerArrayIndex = (getRandomNumber() % s_soldTikcets.length);

        s_winnerTicketIndex = s_soldTikcets[s_winnerArrayIndex];

        s_winner = WinnerTicketStruct({
            lotteryName: getLotteryName(),
            winnerAddress: m_ticketOwner[s_winnerTicketIndex],
            lotteryId: i_lotteryId,
            winnerTicketIndex: s_winnerTicketIndex,
            prizeInAzitoken: i_prizeInAzitoken
        });
        s_lottery.state = lotteryState.LOTTERY_WINNER_DECLARED;

        emit Lottery_Winner_Declared(
            s_winner.winnerAddress,
            s_winner.lotteryName,
            s_winner.prizeInAzitoken,
            s_winner.winnerTicketIndex
        );
    }
    function setLotteryExpired() external onlyOwner isWinnerDeclared {
        s_lottery.state = lotteryState.LOTTERY_EXPIRED;
        emit Lottery_Expired(block.timestamp);
    }

    function getRandomNumber() public view returns (uint256) {
        return (block.timestamp * block.number) / block.timestamp;
    }

    function getWinner() external view returns (WinnerTicketStruct memory) {
        return s_winner;
    }

    function getLotteryName() public view returns (string memory) {
        return string(abi.encodePacked(i_lotteryName));
    }

    function getWinnerTicketNumber() public view returns (uint256) {
        return s_winnerTicketIndex;
    }

    function getSoldTickets() public view returns (uint256[] memory) {
        return s_soldTikcets;
    }

    function getWinnerAddress() public view returns (address) {
        return s_winner.winnerAddress;
    }

    function getAllocatedTicketsToAddress(address participantAddress)
        public
        view
        returns (uint256[] memory)
    {
        return m_ownedTickets[participantAddress];
    }

    function getStatusOfTicket(uint256 ticketNumber)
        public
        view
        returns (bool)
    {
        return m_soldTickets[ticketNumber];
    }

    function getTicketOwner(uint256 ticketNumber)
        public
        view
        returns (address)
    {
        return m_ticketOwner[ticketNumber];
    }

    function getLotteryState() public view returns (lotteryState) {
        return s_lottery.state;
    }
    function getPrice() public view returns (uint32) {
        return i_prizeInAzitoken;
    }
    function getNumberOfSoldTIckets() public view returns (uint256) {
        return s_soldTikcets.length;
    }
    
    
}