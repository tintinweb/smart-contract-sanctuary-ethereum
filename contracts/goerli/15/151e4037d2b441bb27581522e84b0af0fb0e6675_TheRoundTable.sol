// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
A DANGER LOOMS OVER THE REALM
THE KNIGHTS OF THE ROUND TABLE ITS ONLY SHIELD
CALL THE BANNERS
CHOOSE YOUR CHAMPIONS
*/

import "./IERC721A.sol";

contract TheRoundTable {
    address public TheKing;
    address[] public Knight;
    uint256 public Seats = 50;
    uint256 public lengthOfTrials = 10 days;
    uint256 public lengthOfTournaments = 30 days;
    uint256 internal majorityRule = 2;
    uint256 internal rest = 1 days;
    bool public gatesClosed = false;

    struct SquireRecords {
        address _address;
        bool _decisionMade;
        bool _knighted;
        uint256 _beginningOfTrials;
        uint256 _endOfTrials;
        uint256 _yays;
        uint256 _majorityRule;
    }

    struct TournamentRecords {
        bool _tournamentFinished;
        string _champion;
        uint256 _startingTime;
        uint256 _endingTime;
        string[] _contestants;
        uint256[] _yays;
        uint256[] _donations;
    }

    SquireRecords[] internal squires;
    TournamentRecords[] internal tournaments;
    mapping(address => mapping(uint256 => uint256)) internal squireBlessings;
    mapping(address => mapping(uint256 => uint256)) internal contestantBlessings;
    mapping(address => mapping(uint256 => uint256)) internal contestantDonations;
    mapping(address => uint256) internal silence;
    mapping(address => uint256) internal undergoingTrials;

    constructor() {
        TheKing = msg.sender;
        //Add Blank record to starting index
        string[] memory _blankStrings = new string[](1);
        uint256[] memory _blankUints = new uint256[](1);
        SquireRecords memory blankSquire = SquireRecords(0x0000000000000000000000000000000000000000, true, false, 0, 0, 0, 0);
        squires.push(blankSquire);
        TournamentRecords memory blankTournament = TournamentRecords(true, "", 0, 0, _blankStrings, _blankUints, _blankUints);
        tournaments.push(blankTournament);
        //Add founding Knights
        Knight.push(0xE9097b50436C2C4EdB87eDA90D6824aD011D91cf);
        Knight.push(0x880C231e502e61f8be4610e23837dE4789DbE7A9);
        Knight.push(0xAE4eb8FCa96744AdCa015E82a2A4c14dfdFd7053);
        Knight.push(0x722E5095DB94FDc39cB40d576F6B071cc0a17518);

    }

    modifier isKnighted() {
        require(msg.sender == tx.origin, "I will have your head, spy.");
        if (msg.sender != TheKing) {
            require(blessingsPerKnight(msg.sender) > 0, "You must be a Knight.");
        }
        _;
    }

    modifier onlyTheKing() {
        require(msg.sender == TheKing, "TREASON?!?!");
        _;
    }

    function isKnight(address _address) public view returns (bool) {
        bool Knighted = false;
        for(uint i = 0; i<Knight.length;i++) {
            if(_address == Knight[i]) {
                Knighted = true;
            }
        }
        return Knighted;
    }

    function isSquire(address _address) public view returns (bool) {
        IERC721A collection = IERC721A(_address);
        if (collection.totalSupply() > 0) {
            uint balanceCheck = collection.balanceOf(address(this));
            return true;
        } else {
            revert("This is no squire, M'Lord.");
        }
    }

    function isResting(address _knight) public view returns (bool) {
        if(block.timestamp > silence[_knight]+rest) {
            return false;
        } else {
            return true;
        }
    }

    function Knights() public view returns (uint256) {
        return Knight.length;
    }

    function TournamentsHeld() public view returns (uint256) {
        return tournaments.length-1;
    }

    function TrialsUndergone() public view returns (uint256) {
        return squires.length-1;
    }

    function blessingsPerKnight(address _knight) public view returns (uint256) {
        uint256 blessings = 0;
        for(uint i = 0; i<Knight.length;i++) {
            IERC721A collection = IERC721A(Knight[i]);
            blessings += collection.balanceOf(_knight);
        }
        return blessings;
    }

    function blessingsOfTheRealm() public view returns (uint256) {
        uint256 totalBlessings = 0;
        for(uint i = 0; i<Knight.length;i++) {
            IERC721A collection = IERC721A(Knight[i]);
            totalBlessings += collection.totalSupply();
        }
        return totalBlessings;
    }
  
    function getBlessingsRequired() internal view returns (uint256) {
        uint256 totalBlessings = blessingsOfTheRealm();
        uint256 blessingsRequired = (totalBlessings / majorityRule);
        return blessingsRequired + 1;
    }

    function electSquire(address _address) external isKnighted {
        require(Knights() < Seats, "Petition the King for a larger table to recruit more Knights.");
        require(gatesClosed == false, "The gates are closed.");
        require(isResting(msg.sender) == false, "You must wait before electing another squire.");
        require(block.timestamp > undergoingTrials[_address]+lengthOfTrials, "This squire is currently undergoing trials. Cast your blessings upon them.");
        require(isKnight(_address) == false, "This squire has already been Knighted.");
        require(isSquire(_address) == true, "This is no squire, M'Lord.");
        uint256 blessingsRequired = getBlessingsRequired();
        SquireRecords memory newSquire = SquireRecords(_address, false, false, block.timestamp, (block.timestamp + lengthOfTrials), 0, blessingsRequired);
        squires.push(newSquire);
        silence[msg.sender] = block.timestamp;
        undergoingTrials[_address] = block.timestamp;
    }

    function blessContestant(uint256 _tournamentID, uint256 _contestant) external payable isKnighted {
        require(gatesClosed == false, "The gates are closed.");
        require(tournaments[_tournamentID]._tournamentFinished == false, "The Tournament Is Over");
        if(block.timestamp < tournaments[_tournamentID]._endingTime) {
            uint256 blessings = blessingsPerKnight(msg.sender);
            uint256 blessingsUsed = contestantBlessings[msg.sender][_tournamentID];
            uint256 unusedBlessings = blessings - blessingsUsed;
            tournaments[_tournamentID]._yays[_contestant] += unusedBlessings;
            contestantBlessings[msg.sender][_tournamentID] += unusedBlessings;
            uint256 donations = msg.value;
            tournaments[_tournamentID]._donations[_contestant] += donations;
            contestantDonations[msg.sender][_tournamentID] += donations;
        } else {
            uint256 largest = 0; 
            uint256 i;
            for(i=0;i<tournaments[_tournamentID]._contestants.length;i++) {
                if(tournaments[_tournamentID]._yays[i] > largest) {
                    largest = tournaments[_tournamentID]._yays[i]; 
                    tournaments[_tournamentID]._champion = tournaments[_tournamentID]._contestants[i];  
                } 
            }
            concludeTournament(_tournamentID);
        }   
    }

    function blessSquire(uint256 _squireID) external isKnighted {
        require(gatesClosed == false, "The gates are closed.");
        require(squires[_squireID]._decisionMade == false, "You forget yourself, Sire. A decision has already been made.");
        if(block.timestamp < squires[_squireID]._endOfTrials) {
            uint256 blessings = blessingsPerKnight(msg.sender);
            uint256 blessingsUsed = squireBlessings[msg.sender][_squireID];
            uint256 unusedBlessings = blessings - blessingsUsed;
            squires[_squireID]._yays += unusedBlessings;
            squireBlessings[msg.sender][_squireID] += unusedBlessings;
            if(squires[_squireID]._yays >= squires[_squireID]._majorityRule) {
                knightSquire(_squireID);
            }
        } else {
            squires[_squireID]._decisionMade = true;
        }
        

    }

    function knightSquire(uint256 _squireID) internal {
        squires[_squireID]._decisionMade = true;
        squires[_squireID]._knighted = true;
        Knight.push(squires[_squireID]._address);
    }

    function concludeTournament(uint256 _tournamentID) internal {
        tournaments[_tournamentID]._tournamentFinished = true;
    }

    function squireRecords(uint256 _squireID) external view returns (
        address _address,
        bool _decisionMade,
        bool _votePassed,
        uint256 _beginningOfTrials,
        uint256 _endOfTrials,
        uint256 _yays,
        uint256 _majorityRule
    ) {
        return (
            squires[_squireID]._address,
            squires[_squireID]._decisionMade,
            squires[_squireID]._knighted,
            squires[_squireID]._beginningOfTrials,
            squires[_squireID]._endOfTrials,
            squires[_squireID]._yays,
            squires[_squireID]._majorityRule
        );
    }

    function tournamentRecords(uint256 _tournamentID) external view returns (
        bool _tournamentFinished,
        string memory _champion,
        uint256 _startingTime,
        uint256 _endingTime,
        string[] memory _contestants,
        uint256[] memory _yays
    ) {
        return (
            tournaments[_tournamentID]._tournamentFinished,
            tournaments[_tournamentID]._champion,
            tournaments[_tournamentID]._startingTime,
            tournaments[_tournamentID]._endingTime,
            tournaments[_tournamentID]._contestants,
            tournaments[_tournamentID]._yays
        );
    }

    function xTheKingIsDead(address _longLiveTheKing) external onlyTheKing {
        TheKing = _longLiveTheKing;
    }

    function xAppointKnight(address _toBeKnighted) external onlyTheKing {
        require(Knights() < Seats, "You need a bigger table, M'Lord.");
        require(block.timestamp > undergoingTrials[_toBeKnighted]+lengthOfTrials, "This squire is currently undergoing trials, M'Lord.");
        require(isKnight(_toBeKnighted) == false, "This squire has already been Knighted, M'Lord.");
        require(isSquire(_toBeKnighted) == true, "This is no squire, M'Lord.");
        Knight.push(_toBeKnighted);
    }

    function xBeginTournament(string[] memory _contestants) external onlyTheKing {
        uint256 length = _contestants.length;
        uint256[] memory _blessings = new uint256[](length);
        uint256[] memory _donations = new uint256[](length);
        TournamentRecords memory newTournament = TournamentRecords(false, "", block.timestamp, (block.timestamp + lengthOfTournaments), _contestants, _blessings, _donations);
        tournaments.push(newTournament);
    }

    function xChangeMajorityRule(uint256 _newMajorityRule) external onlyTheKing {
        majorityRule = _newMajorityRule;
    }

    function xChangeLengthOfTrials(uint256 _newLengthOfTrials) external onlyTheKing {
        lengthOfTrials = _newLengthOfTrials;
    }

    function xChangeLengthOfTournaments(uint256 _newLengthOfTournaments) external onlyTheKing {
        lengthOfTrials = _newLengthOfTournaments;
    }

    function xUpdateRest(uint256 _newRest) external onlyTheKing {
        rest = _newRest;
    }

    function xAddSeats(uint256 _seats) external onlyTheKing {
        Seats += _seats;
    }

    function xCloseTheGates() external onlyTheKing {
        gatesClosed = true;
    }

    function xOpenTheGates() external onlyTheKing {
        gatesClosed = false;
    }

    function xTreasury() external onlyTheKing {
        (bool success, ) = TheKing.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}