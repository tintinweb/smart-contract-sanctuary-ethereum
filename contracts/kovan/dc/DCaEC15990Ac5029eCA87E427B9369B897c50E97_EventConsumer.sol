// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventConsumer {

    struct MatchEvent {
        uint eventId;
        uint homeId;
        string homeName;
        uint awayId;
        string awayName;
        uint homeScore;
        uint awayScore;
        string gameStatus;
    }

    address owner;

    mapping (uint => MatchEvent) public matchevents;

    event MatchEventAdded(uint indexed event_id, MatchEvent matchevent);

    constructor() {
        owner = msg.sender;
    }

    function setMatchEvent(
        uint event_id,
        uint home_id,
        string memory home_name,
        uint away_id,
        string memory away_name,
        uint home_score,
        uint away_score,
        string memory game_status
        ) public returns(bool) {
        require(msg.sender == owner);
        matchevents[event_id] = MatchEvent(event_id, home_id, home_name, away_id, away_name, home_score, away_score, game_status);
        return true;
    }

    // function addMatchEvent(
    //     uint event_id,
    //     uint home_id,
    //     string memory home_name,
    //     uint away_id,
    //     string memory away_name,
    //     uint home_score,
    //     uint away_score,
    //     string memory game_status
    //     ) public returns(bool) {
    //     require(msg.sender == owner);
    //     matchevents[event_id].event_id = event_id;
    //     matchevents[event_id].home_id = home_id;
    //     matchevents[event_id].home_name = home_name;
    //     matchevents[event_id].away_id = away_id;
    //     matchevents[event_id].away_name = away_name;
    //     matchevents[event_id].home_score = home_score;
    //     matchevents[event_id].away_score = away_score;
    //     matchevents[event_id].game_status = game_status;
    //     emit MatchEventAdded(event_id, matchevents[event_id]);
    //     return true;
    // }

    function getMatchEvent(uint event_id) public view returns(MatchEvent memory) {
        return matchevents[event_id];
    }

    // function getAllMatchEvent() public view returns (mapping _matchevents) {
    //     return _matchevents;
    // }
}