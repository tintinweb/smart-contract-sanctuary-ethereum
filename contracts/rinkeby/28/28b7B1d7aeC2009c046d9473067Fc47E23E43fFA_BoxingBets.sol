/**
 *Submitted for verification at Etherscan.io on 2022-03-15
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.4.26;



// Part: OracleInterface

contract OracleInterface {
    mapping(bytes32 => uint) matchIdToIndex; 
    Match[] matches; 

    //defines a match along with its outcome
    struct Match {
        bytes32 id;
        string name;
        string participants;
        uint8 participantCount;
        uint date; 
        MatchOutcome outcome;
        int8 winner;
    }

    enum MatchOutcome {
        Pending,    //match has not been fought to decision
        Underway,   //match has started & is underway
        Draw,       //anything other than a clear winner (e.g. cancelled)
        Decided     //index of participant who is the winner 
    }

    /// @notice returns the array index of the match with the given id 
    /// @dev if the match id is invalid, then the return value will be incorrect and may cause error; you must call matchExists(_matchId) first!
    /// @param _matchId the match id to get
    /// @return an array index 
    function _getMatchIndex(bytes32 _matchId) private view returns (uint) {
        return matchIdToIndex[_matchId]-1; 
    }


    /// @notice gets the unique ids of all pending matches, in reverse chronological order
    /// @return an array of unique match ids
    function getPendingMatches() public view returns (bytes32[]) {
        uint count = 0; 

        //get count of pending matches 
        for (uint i = 0; i < matches.length; i++) {
            if (matches[i].outcome == MatchOutcome.Pending) 
                count++; 
        }

        //collect up all the pending matches
        bytes32[] memory output = new bytes32[](count); 

        if (count > 0) {
            uint index = 0;
            for (uint n = matches.length; n > 0; n--) {
                if (matches[n-1].outcome == MatchOutcome.Pending) 
                    output[index++] = matches[n-1].id;
            }
        } 

        return output; 
    }

    /// @notice gets the unique ids of matches, pending and decided, in reverse chronological order
    /// @return an array of unique match ids
    function getAllMatches() public view returns (bytes32[]) {
        bytes32[] memory output = new bytes32[](matches.length); 

        //get all ids 
        if (matches.length > 0) {
            uint index = 0;
            for (uint n = matches.length; n > 0; n--) {
                output[index++] = matches[n-1].id;
            }
        }
        
        return output; 
    }

    /// @notice determines whether a match exists with the given id 
    /// @param _matchId the match id to test
    /// @return true if match exists and id is valid
    function matchExists(bytes32 _matchId) public view returns (bool) {
        if (matches.length == 0)
            return false;
        uint index = matchIdToIndex[_matchId]; 
        return (index > 0); 
    }

    /// @notice gets the specified match 
    /// @param _matchId the unique id of the desired match 
    /// @return match data of the specified match 
    function getMatch(bytes32 _matchId) public view returns (
        bytes32 id,
        string name, 
        string participants,
        uint8 participantCount,
        uint date, 
        MatchOutcome outcome, 
        int8 winner) {
        
        //get the match 
        if (matchExists(_matchId)) {
            Match storage theMatch = matches[_getMatchIndex(_matchId)];
            return (theMatch.id, theMatch.name, theMatch.participants, theMatch.participantCount, theMatch.date, theMatch.outcome, theMatch.winner); 
        }
        else {
            return (_matchId, "", "", 0, 0, MatchOutcome.Pending, -1); 
        }
    }

    /// @notice gets the most recent match or pending match 
    /// @param _pending if true, will return only the most recent pending match; otherwise, returns the most recent match either pending or completed
    /// @return match data 
    function getMostRecentMatch(bool _pending) public view returns (
        bytes32 id,
        string name, 
        string participants,
        uint8 participantCount,
        uint date, 
        MatchOutcome outcome, 
        int8 winner) {

        bytes32 matchId = 0; 
        bytes32[] memory ids;

        if (_pending) {
            ids = getPendingMatches(); 
        } else {
            ids = getAllMatches();
        }
        if (ids.length > 0) {
            matchId = ids[0]; 
        }
        
        //by default, return a null match
        return getMatch(matchId); 
    }
}

// File: BoxingBets.sol

/// @title BoxingBets
/// @author John R. Kosinski
/// @notice Takes bets and handles payouts for boxing matches 
contract BoxingBets {
    
    //mappings 
    mapping(address => bytes32[]) private userToBets;
    mapping(bytes32 => Bet[]) private matchToBets;

    //boxing results oracle 
    OracleInterface internal boxingOracle = new OracleInterface(); 

    //constants
    uint internal minimumBet = 1000000000000;

    struct Bet {
        address user;
        bytes32 matchId;
        uint amount; 
        uint8 chosenWinner; 
    }

    enum BettableOutcome {
        Fighter1,
        Fighter2
    }

    /// @notice determines whether or not the user has already bet on the given match
    /// @param _user address of a user
    /// @param _matchId id of a match 
    /// @param _chosenWinner the index of the participant to bet on (to win)
    /// @return true if the given user has already placed a bet on the given match 
    function _betIsValid(address _user, bytes32 _matchId, uint8 _chosenWinner) private view returns (bool) {

        return true;
    }

    /// @notice determines whether or not bets may still be accepted for the given match
    /// @param _matchId id of a match 
    /// @return true if the match is bettable 
    function _matchOpenForBetting(bytes32 _matchId) private view returns (bool) {
        
        return true;
    }

 
    /// @notice gets a list ids of all currently bettable matches
    /// @return array of match ids 
    function getBettableMatches() public view returns (bytes32[]) {
        return boxingOracle.getPendingMatches(); 
    }

    /// @notice returns the full data of the specified match 
    /// @param _matchId the id of the desired match
    /// @return match data 
    function getMatch(bytes32 _matchId) public view returns (
        bytes32 id,
        string name, 
        string participants,
        uint8 participantCount,
        uint date, 
        OracleInterface.MatchOutcome outcome, 
        int8 winner) { 

        return boxingOracle.getMatch(_matchId); 
    }

    /// @notice returns the full data of the most recent bettable match 
    /// @return match data 
    function getMostRecentMatch() public view returns (
        bytes32 id,
        string name, 
        string participants,
        uint participantCount, 
        uint date, 
        OracleInterface.MatchOutcome outcome, 
        int8 winner) { 

        return boxingOracle.getMostRecentMatch(true); 
    }

    /// @notice places a non-rescindable bet on the given match 
    /// @param _matchId the id of the match on which to bet 
    /// @param _chosenWinner the index of the participant chosen as winner
    function placeBet(bytes32 _matchId, uint8 _chosenWinner) public payable {

        //bet must be above a certain minimum 
        require(msg.value >= minimumBet, "Bet amount must be >= minimum bet");

        //make sure that match exists 
        require(boxingOracle.matchExists(_matchId), "Specified match not found"); 

        //require that chosen winner falls within the defined number of participants for match
        require(_betIsValid(msg.sender, _matchId, _chosenWinner), "Bet is not valid");

        //match must still be open for betting
        require(_matchOpenForBetting(_matchId), "Match not open for betting"); 

        //transfer the money into the account 
        //address(this).transfer(msg.value);

        //add the new bet 
        Bet[] storage bets = matchToBets[_matchId]; 
        bets.push(Bet(msg.sender, _matchId, msg.value, _chosenWinner))-1; 

        //add the mapping
        bytes32[] storage userBets = userToBets[msg.sender]; 
        userBets.push(_matchId); 
    }

    /// @notice for testing only; adds two numbers and returns result 
    /// @return uint sum of two uints  
    function test(uint a, uint b) public pure returns (uint) {
        return (a + b); 
    }
}