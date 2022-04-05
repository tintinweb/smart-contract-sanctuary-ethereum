/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;
pragma abicoder v2;


contract DeadPool {


    /* Types */

    enum eventStatus{open, finished, closed}
    enum bidStatus{open, closed}

    struct bid {
        uint id;
        uint256 name;
        address[] whoBet;
        uint amountReceived;
        bidStatus status;
    }

    struct betEvent {
        uint id;
        bytes32 name;
        address creator;
        address arbitrator;
        uint256 winner;
        uint arbitratorFee;
        uint minBid; // value in wei
        uint maxBid; // value in wei
        bid[] bids;
        bet[] bets;
        eventStatus status;
    }

    struct bet {
        address person;
        uint256 bidName;
        uint amount;
        uint256 timestamp;
    }


    /* Storage */

    address public owner;

    mapping(address => betEvent[]) public betEvents;
    mapping(address => uint) public pendingWithdrawals;


    /* Events */

    //    event eventCreated(uint id, address creator);
    //    event betMade(uint value, uint id);
    //    event eventStatusChanged(uint status);
    //    event withdrawalDone(uint amount);


    /* Modifiers */

    modifier onlyOwner(){
        if (msg.sender == owner) {
            _;
        }
    }

    modifier onlyOpen(address creator, uint eventId){
        if (betEvents[creator][eventId].status == eventStatus.open) {
            _;
        }
    }

    modifier onlyFinished(address creator, uint eventId){
        if (betEvents[creator][eventId].status == eventStatus.finished) {
            _;
        }
    }

    modifier onlyArbitrator(address creator, uint eventId){
        if (msg.sender == betEvents[creator][eventId].arbitrator) {
            _;
        }
    }

    modifier onlyOpenAndArbitrator(address creator, uint eventId){
        if (betEvents[creator][eventId].status == eventStatus.open && msg.sender == betEvents[creator][eventId].arbitrator) {
            _;
        }
    }

    modifier onlyFinishedAndArbitrator(address creator, uint eventId){
        if (betEvents[creator][eventId].status == eventStatus.finished && msg.sender == betEvents[creator][eventId].arbitrator) {
            _;
        }
    }


    /* Methods */

    constructor() {
        owner = msg.sender;
    }

    fallback() external payable {
        // custom function code
    }

    receive() external payable {
        // custom function code
    }

    bid public newBid;
    betEvent public newEvent;
    bet public newBet;

    function createEvent(address arbitrator, bytes32 name, uint fee, uint minBid, uint maxBid) external
    onlyOwner {
        require(fee < 100, "Fee must be lower than 100.");
        /* check whether event with such name already exist */
        bool found = false;
        for (uint x = 0; x < betEvents[msg.sender].length; x++) {
            if (betEvents[msg.sender][x].name == name) {
                found = true;
            }
        }
        require(!found, "Event with same name already exists.");
        uint newId = betEvents[msg.sender].length;
        newEvent.id = newId;
        newEvent.name = name;
        newEvent.arbitrator = arbitrator;
        newEvent.status = eventStatus.open;
        newEvent.creator = msg.sender;
        newEvent.minBid = minBid;
        newEvent.maxBid = maxBid;
        newEvent.arbitratorFee = fee;
        betEvents[msg.sender].push(newEvent);
        //        emit eventCreated(newId, msg.sender);
    }

    function finishEvent(address creator, uint eventId) external
    onlyOpenAndArbitrator(creator, eventId) {
        betEvents[creator][eventId].status = eventStatus.finished;
        //        emit eventStatusChanged(1);
    }

    function _addBid(address creator, uint eventId, uint256 bidName) private
    onlyOpen(creator, eventId) {
        uint newBidId = 0;
        bool found = findBid(creator, eventId, bidName);
        if (!found) {
            newBidId = betEvents[creator][eventId].bids.length;
            newBid.id = newBidId;
            newBid.name = bidName;
            newBid.status = bidStatus.open;
            betEvents[creator][eventId].bids.push(newBid);
        }
    }

    function addBid(address creator, uint eventId, uint256 bidName) external
    onlyOpen(creator, eventId) {
        _addBid(creator, eventId, bidName);
    }

    function addBids(address creator, uint eventId, uint256[] calldata bidNames) external
    onlyOpen(creator, eventId) {
        for (uint i = 0; i < bidNames.length; i++) {
            _addBid(creator, eventId, bidNames[i]);
        }
    }

    function _closeBid(address creator, uint eventId, uint256 bidName) private
    onlyOpenAndArbitrator(creator, eventId) {
        for (uint i = 0; i < betEvents[creator][eventId].bids.length; i++) {
            if (betEvents[creator][eventId].bids[i].name == bidName) {
                betEvents[creator][eventId].bids[i].status = bidStatus.closed;
            }
        }
    }

    function closeBid(address creator, uint eventId, uint256 bidName) external
    onlyOpenAndArbitrator(creator, eventId) {
        _closeBid(creator, eventId, bidName);
    }

    function closeBids(address creator, uint eventId, uint256[] calldata bidNames) external
    onlyOpenAndArbitrator(creator, eventId) {
        for (uint i = 0; i < bidNames.length; i++) {
            _closeBid(creator, eventId, bidNames[i]);
        }
    }

    // function openBid(address creator, uint eventId, bytes32 bidName) external
    // onlyOpen(creator, eventId) onlyArbitrator(creator, eventId) {
    //     for (uint i = 0; i < betEvents[creator][eventId].bids.length; i++) {
    //         if (betEvents[creator][eventId].bids[i].name == bidName) {
    //             betEvents[creator][eventId].bids[i].status = bidStatus.open;
    //         }
    //     }
    // }

    function makeBet(address creator, uint eventId, uint256 bidName) public payable
    onlyOpen(creator, eventId) {
        uint256 minDate = (block.timestamp / (60 * 60 * 24) + 1) * (60 * 60 * 24);
        require(bidName >= minDate, "Bid must be more than today.");
        /* check whether bid with given name actually exists */
        bool found = findBid(creator, eventId, bidName);
        if (!found) {
            this.addBid(creator, eventId, bidName);
        }
        for (uint i = 0; i < betEvents[creator][eventId].bids.length; i++) {
            if (betEvents[creator][eventId].bids[i].name == bidName) {
                bid storage foundBid = betEvents[creator][eventId].bids[i];
                found = true;
                require(foundBid.status == bidStatus.open, "Bid is closed.");
                //check for minimal amount
                if (betEvents[creator][eventId].minBid > 0) {
                    require(msg.value >= betEvents[creator][eventId].minBid, "Min amount error.");
                }
                //check for maximal amount
                if (betEvents[creator][eventId].maxBid > 0) {
                    require(msg.value <= betEvents[creator][eventId].maxBid, "Max amount error.");
                }
                foundBid.whoBet.push(msg.sender);
                foundBid.amountReceived += msg.value;
                newBet.person = msg.sender;
                newBet.amount = msg.value;
                newBet.bidName = bidName;
                newBet.timestamp = block.timestamp;
                betEvents[creator][eventId].bets.push(newBet);
                //                emit betMade(msg.value, newBetId);
            }

        }
        require(found, "Bid not found.");
    }

    function determineWinner(address creator, uint eventId, uint256 bidName) external
    onlyFinishedAndArbitrator(creator, eventId) {
        require(findBid(creator, eventId, bidName));
        betEvent storage cEvent = betEvents[creator][eventId];
        cEvent.winner = bidName;
        uint amountLost;
        uint amountWon;
        uint lostBetsLen;
        /* Calculating amount of all won and lost bets */
        for (uint x = 0; x < cEvent.bets.length; x++) {
            uint betAmount = cEvent.bets[x].amount;
            if (cEvent.bets[x].bidName == cEvent.winner) {
                amountWon += betAmount;
                pendingWithdrawals[cEvent.bets[x].person] += betAmount;
            } else {
                lostBetsLen++;
                amountLost += betAmount;
            }
        }
        uint arbitratorAmount = amountLost / 100 * cEvent.arbitratorFee;
        pendingWithdrawals[cEvent.arbitrator] += arbitratorAmount;
        amountLost -= arbitratorAmount;
        /* If we do have win bets */
        if (amountWon > 0) {
            for (uint x = 0; x < cEvent.bets.length; x++) {
                if (cEvent.bets[x].bidName == cEvent.winner) {
                    uint wonBetPercentage = percent(cEvent.bets[x].amount, amountWon, 2);
                    pendingWithdrawals[cEvent.bets[x].person] += (amountLost / 100) * wonBetPercentage;
                }
            }
        } else {
            /* If we don't have any bets won, we pay all the funds back except arbitrator fee */
            for (uint x = 0; x < cEvent.bets.length; x++) {
                pendingWithdrawals[cEvent.bets[x].person] += cEvent.bets[x].amount - ((cEvent.bets[x].amount / 100) * cEvent.arbitratorFee);
            }
        }
        cEvent.status = eventStatus.closed;
        //        emit eventStatusChanged(2);
    }

    function withdraw(address payable person) private {
        uint amount = pendingWithdrawals[person];
        pendingWithdrawals[person] = 0;
        person.transfer(amount);
        //        emit withdrawalDone(amount);
    }

    function requestWithdraw() external {
        require(pendingWithdrawals[msg.sender] != 0, "No withdrawal available.");
        withdraw(payable(msg.sender));
    }

    function findBid(address creator, uint eventId, uint256 bidName) private view returns (bool){
        for (uint i = 0; i < betEvents[creator][eventId].bids.length; i++) {
            if (betEvents[creator][eventId].bids[i].name == bidName) {
                return true;
            }
        }
        return false;
    }

    function percent(uint numerator, uint denominator, uint precision) public pure returns (uint quotient) {
        // caution, check safe-to-multiply here
        uint _numerator = numerator * 10 ** (precision + 1);
        // with rounding of last digit
        uint _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }


    /* Getters */

    function getBetEvents(address creator) external view returns (betEvent[] memory){
        return betEvents[creator];
    }
    //
    //    function getBetEvent(address creator, uint eventId) external view returns (betEvent memory){
    //        return betEvents[creator][eventId];
    //    }
    //
    //    function getBidsNum(address creator, uint eventId) external view returns (uint){
    //        return betEvents[creator][eventId].bids.length;
    //    }
    //
    function getBids(address creator, uint eventId) external view returns (bid[] memory){
        return betEvents[creator][eventId].bids;
    }
    //
    //    function getBid(address creator, uint eventId, uint bidId) external view returns (uint, bytes32, uint){
    //        bid storage foundBid = betEvents[creator][eventId].bids[bidId];
    //        return (foundBid.id, foundBid.name, foundBid.amountReceived);
    //    }
    //
    //    function getBetsNums(address creator, uint eventId) external view returns (uint){
    //        return betEvents[creator][eventId].bets.length;
    //    }
    //
    //    function getWhoBet(address creator, uint eventId, uint bidId) external view returns (address[] memory){
    //        return betEvents[creator][eventId].bids[bidId].whoBet;
    //    }
    //
    function getBets(address creator, uint eventId) external view returns (bet[] memory){
        return betEvents[creator][eventId].bets;
    }
    //
    //    function getBet(address creator, uint eventId, uint betId) external view returns (address, bytes32, uint){
    //        bet storage foundBet = betEvents[creator][eventId].bets[betId];
    //        return (foundBet.person, foundBet.bidName, foundBet.amount);
    //    }
    //
    //    function getEventId(address creator, bytes32 eventName) external view returns (uint, bool){
    //        for (uint i = 0; i < betEvents[creator].length; i++) {
    //            if (betEvents[creator][i].name == eventName) {
    //                return (betEvents[creator][i].id, true);
    //            }
    //        }
    //        return (0, false);
    //    }


}