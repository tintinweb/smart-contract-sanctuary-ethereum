/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Betting {
    enum BettingType {
        Tie,
        TeamA,
        TeamB
    }

    struct BettingPerson {
        address payable betting_person;
        BettingType betting_type;
        uint256 initialAmount;
    }

    struct MatchDetails {
        string competition;
        string teamA;
        string teamB;
        uint256 tie;
        uint256 team_A_win;
        uint256 team_B_win;
        uint256 gameDay;
        uint256 bettingPersonCount;
    }

    event PlaceBet(
        uint256 match_id,
        uint256 odd_for_winning,
        BettingType betting_type
    );

    event Bet(
        address betting_person,
        uint256 match_id,
        uint256 initial_amount,
        BettingType betting_type
    );
    event Winner(uint256 _matchId, BettingType _winningType);
    event Pay(address indexed _from, address indexed _to, uint256 _amount);
    uint256 private bettingDeadline;
    uint256 public matchCount;
    address payable private owner;
    mapping(uint256 => MatchDetails) public matchDetails;
    mapping(uint256 => mapping(uint256 => BettingPerson))
        public bettingPersonList;

    constructor(uint256 _bettingDeadline) payable {
        bettingDeadline = _bettingDeadline;
        owner = payable(msg.sender);
    }

    function setBettingDeadline(
        uint256 _bettingDeadline
    ) public {
        bettingDeadline = _bettingDeadline;
    }

    modifier BettingAdministrator() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function getMatches() public view returns (MatchDetails[] memory) {
        MatchDetails[] memory details = new MatchDetails[](matchCount);
        for (uint256 index; index < matchCount; index++) {
            details[index] = matchDetails[index];
        }
        return details;
    }

    function setMatchDetails(
        string memory _competition,
        string memory _teamA,
        string memory _teamB,
        uint256 _tie,
        uint256 _team_A_win,
        uint256 _team_B_win,
        uint256 _gameDay
    ) public {
        MatchDetails memory match_details = MatchDetails(
            _competition,
            _teamA,
            _teamB,
            _tie,
            _team_A_win,
            _team_B_win,
            _gameDay,
            0
        );
        matchDetails[matchCount++] = match_details;
    }

    function placeBet(
        uint256 _matchId,
        uint256 _oddForWinning,
        BettingType _bettingType
    ) public {
        require(_matchId >= 0 && _matchId < matchCount, "Match not exists!");
        require(_oddForWinning > 0, "Odd has to be positive number!");
        if (_bettingType == BettingType.Tie) {
            matchDetails[_matchId].tie = _oddForWinning;
        } else {
            if (_bettingType == BettingType.TeamA) {
                matchDetails[_matchId].team_A_win = _oddForWinning;
            } else {
                matchDetails[_matchId].team_B_win = _oddForWinning;
            }
        }
        emit PlaceBet(_matchId, _oddForWinning, _bettingType);
    }

    receive() external payable {}

    function executeBet(uint256 _matchId, BettingType _bettingType)
        public
        payable
    {
        require(_matchId >= 0 && _matchId < matchCount, "Match not exists!");
        require(block.timestamp < bettingDeadline, "Time is passed!");
        if (msg.value <= 0) revert("Wasn't provided enough ether for betting!");
        if (msg.sender.balance <= msg.value)
            revert("Provided more amount than there is on account!");
        BettingPerson memory betting_person = BettingPerson(
            payable(msg.sender),
            _bettingType,
            msg.value
        );
        uint256 count = matchDetails[_matchId].bettingPersonCount;
        bettingPersonList[_matchId][count++] = betting_person;
        matchDetails[_matchId].bettingPersonCount = count;
        (bool sent, ) = payable(address(this)).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit Bet(payable(msg.sender), _matchId, msg.value, _bettingType);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    fallback() external payable {}

    function payWinningBets(uint256 _matchId, BettingType _winningType)
        public
        BettingAdministrator
    {
        require(_matchId >= 0 && _matchId < matchCount, "Match not exists!");
        uint256 count = matchDetails[_matchId].bettingPersonCount;
        uint256 odd;
        if (_winningType == BettingType.Tie) {
            odd = matchDetails[_matchId].tie;
        } else {
            if (_winningType == BettingType.TeamA) {
                odd = matchDetails[_matchId].team_A_win;
            } else {
                odd = matchDetails[_matchId].team_B_win;
            }
        }
        for (uint256 index; index < count; index++) {
            BettingPerson memory person = bettingPersonList[_matchId][index];
            if (person.betting_type == _winningType) {
                uint256 winning_amount = (person.initialAmount * odd * 95) /
                    100;
                payable(person.betting_person).transfer(winning_amount);

                emit Pay(
                    payable(address(this)),
                    person.betting_person,
                    winning_amount
                );
            }
        }
        emit Winner(_matchId, _winningType);
    }
}