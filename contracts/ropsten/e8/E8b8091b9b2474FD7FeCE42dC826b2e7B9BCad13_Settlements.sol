pragma solidity >=0.4.22 <0.9.0;

contract Settlements {
    address public owner = msg.sender;
    address payable public feeAccount = msg.sender;
    uint256 public endTimeframe = 600000;

    uint256 private currentSettlement = 0;

    mapping(uint256 => address payable) private invitees;
    mapping(uint256 => address payable[2]) private members;
    mapping(uint256 => uint256[2]) private lastBidAsk;
    mapping(uint256 => uint256) private lastBidDate;
    mapping(uint256 => bool[2]) private requestEnd;
    mapping(uint256 => bool) private openSettlements;
    mapping(uint256 => bool) private settlementSetup;
    mapping(uint256 => uint8) private settlementTypes;
    mapping(uint256 => bool) private secondUserIsAsker;

    event NewSettlement(
        uint256 id,
        address indexed creator,
        address indexed invitee,
        uint8 stype,
        bool creatorIsAsker,
        bytes32 ipfspgp
    );
    event SettlementSetup(uint256 id, bytes32 ipfscontract);
    event InviteeJoined(uint256 id, bytes32 ipfscontract, bytes32 ipfspgp);
    event NewBid(uint256 id, address user, uint256 amount);
    event NewAsk(uint256 id, address user, uint256 amount);
    event AttemptEnd(uint256 id, address user);
    event End(uint256 id, uint256 winner, address user);

    event Log(string msg);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "This function is restricted to the contract's owner"
        );
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function changeFeeAccount(address payable newFee) public onlyOwner {
        feeAccount = newFee;
    }

    function changeEndTimeframe(uint256 timeframe) public onlyOwner {
        endTimeframe = timeframe;
    }

    function _getPos(uint256 id, address user) private view returns (uint8) {
        uint8 pos = 2;
        if (members[id][0] == user) pos = 0;
        else if (members[id][1] == user) pos = 1;
        return pos;
    }

    function _getOppositePos(uint256 pos) private view returns (uint8) {
        return pos == 1 ? 0 : 1;
    }

    function _getBidderPos(uint256 id) private view returns (uint8) {
        return secondUserIsAsker[id] ? 0 : 1;
    }

    function _getAskerPos(uint256 id) private view returns (uint8) {
        return secondUserIsAsker[id] ? 1 : 0;
    }

    function _getID() private returns (uint256) {
        return ++currentSettlement;
    }

    function _checkWithinTimeframe(uint256 id) private view returns (bool) {
        return (block.timestamp - lastBidDate[id]) <= endTimeframe; // NEED TO CHANGE
    }

    modifier isOpen(uint256 id) {
        require(
            openSettlements[id] == true,
            "This Settlement is already closed or does not exist"
        );
        _;
    }

    function createSettlement(
        address payable invitee,
        bytes32 ipfs,
        uint8 stype,
        bool isBidder
    ) public {
        require(
            invitee != msg.sender,
            "You Cannot Create A Settlement against yourself"
        );
        require(stype == 1 || stype == 0, "Invalid Settlement Type");
        uint256 id = _getID();
        openSettlements[id] = true;
        invitees[id] = invitee;
        members[id][0] = msg.sender;
        lastBidAsk[id] = [0, 0];
        requestEnd[id] = [false, false];
        settlementSetup[id] = false;
        settlementTypes[id] = stype;
        if (isBidder) {
            secondUserIsAsker[id] = true;
        }
        emit NewSettlement(id, msg.sender, invitee, stype, !isBidder, ipfs);
    }

    function setupSettlement(uint256 id, bytes32 ipfs) public isOpen(id) {
        require(
            settlementSetup[id] == false,
            "You have already uploaded the IPFS"
        );
        uint256 pos = _getPos(id, msg.sender);
        require(pos == 0, "You are not the creator of this settlement");
        settlementSetup[id] = true;
        emit SettlementSetup(id, ipfs);
    }

    function joinSettlement(
        uint256 id,
        bytes32 pdfipfs,
        bytes32 pgpipfs
    ) public isOpen(id) {
        require(
            invitees[id] == msg.sender,
            "You are not invited to this settlement"
        );
        require(
            members[id][1] != invitees[id],
            "You have already joined this settlement"
        );
        members[id][1] = invitees[id];
        emit InviteeJoined(id, pdfipfs, pgpipfs);
    }

    function ask(uint256 id, uint256 amount) public isOpen(id) {
        uint256 pos = _getPos(id, msg.sender);
        require(pos != 2, "You are not in this settlement");
        require(
            members[id][1] == invitees[id],
            "Nobody Has Joined This Settlement Yet"
        );
        require(
            settlementSetup[id] == true,
            "The creator has not set up this settlement yet"
        );
        require(settlementTypes[id] == 1, "This settlement isnt bid/ask");
        bool isAsker = _getAskerPos(id) == pos;
        require(isAsker, "You are not the asker in this settlement");
        lastBidAsk[id][pos] = amount;
        lastBidDate[id] = block.timestamp;
        emit NewAsk(id, msg.sender, amount);
    }

    function bid(uint256 id) public payable isOpen(id) {
        uint256 pos = _getPos(id, msg.sender);
        require(pos != 2, "You are not in this settlement");
        require(
            members[id][1] == invitees[id],
            "Nobody Has Joined This Settlement Yet"
        );
        require(
            settlementSetup[id] == true,
            "The creator has not set up this settlement yet"
        );
        if (settlementTypes[id] == 1) {
            bool isBidder = _getBidderPos(id) == pos;
            require(isBidder, "You must be the bidder on this settlement");
        }

        bool firstBid = (lastBidAsk[id][0] == 0 && lastBidAsk[id][1] == 0);

        require(
            _checkWithinTimeframe(id) || firstBid,
            "The bidding has closed"
        );

        lastBidDate[id] = block.timestamp;

        if (settlementTypes[id] == 0) {
            require(
                firstBid ||
                    msg.value + lastBidAsk[id][pos] >=
                    (lastBidAsk[id][_getOppositePos(pos)] * 110) / 100,
                "Bid Must Be 10% Greater Than opposing Bid"
            );
        } else if (settlementTypes[id] == 1) {
            require(
                firstBid ||
                    msg.value + lastBidAsk[id][pos] >=
                    (lastBidAsk[id][pos] * 110) / 100,
                "Bid Must Be 10% Greater Than previous Bid"
            );
        }

        requestEnd[id] = [false, false];

        uint256 amount = msg.value + lastBidAsk[id][pos];
        lastBidAsk[id][pos] = amount;

        emit NewBid(id, msg.sender, msg.value);
    }

    function _end(uint256 id) private {
        bool firstBid = (lastBidAsk[id][0] == 0 && lastBidAsk[id][1] == 0);
        require(!firstBid, "Cannot End With No Bids Placed");

        uint256 winnerPos = 2;

        uint256 total = 0;
        if (settlementTypes[id] == 0) {
            total = lastBidAsk[id][0] + lastBidAsk[id][1];
            winnerPos = lastBidAsk[id][0] > lastBidAsk[id][1] ? 0 : 1;
        } else if (settlementTypes[id] == 1) {
            total = lastBidAsk[id][_getBidderPos(id)];
            winnerPos = _getAskerPos(id);
        }
        address payable winner = members[id][winnerPos];

        uint256 fee = (total / 100) * 5;

        bool sent = winner.send(total - fee) && feeAccount.send(fee);
        require(sent, "Issue Sending Funds");

        emit End(id, winnerPos, msg.sender);
        delete openSettlements[id];
        delete members[id];
        delete lastBidAsk[id];
        delete lastBidDate[id];
        delete requestEnd[id];
        delete invitees[id];
    }

    function attemptEnd(uint256 id) public isOpen(id) {
        uint256 pos = _getPos(id, msg.sender);
        require(pos != 2, "You are not in this settlement");
        if (settlementTypes[id] == 1 && _getAskerPos(id) == pos) _end(id);
        else if (
            requestEnd[id][_getOppositePos(pos)] == true ||
            !(_checkWithinTimeframe(id))
        ) _end(id);
        else {
            requestEnd[id][pos] = true;
            emit AttemptEnd(id, msg.sender);
        }
    }
}