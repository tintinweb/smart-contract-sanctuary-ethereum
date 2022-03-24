// SPDX-License-Identifier: UNLICENSED

//TODO only for t20 and odi
//TODO remove admin fee perc

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./interfaces/Icricket.sol";
import "./interfaces/IcricketAPI.sol";
import "./interfaces/IsortedPoints.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// import "hardhat/console.sol";

// interface Icalculations{
//     struct OtherPoints{
//         uint captain;
//         uint viceCaptain;
//     }

//     struct Runs {
//         uint runs;
//         uint balls;
//         uint fours;
//         uint sixes;
//         bool isOut;
//     }

//     struct Bowl {
//         uint wickets;
//         uint maidenOver;
//         uint economy;
//     }

//     struct Field {
//         uint catches;
//         uint runout;
//     }

//     struct Score {
//         Runs runs;
//         Bowl bowl;
//         Field field;
//     }

//     function calcPoints(Score memory score) external view returns (int);
//     function otherPoints() external view returns (OtherPoints memory);
// }

contract cricket is Icricket {

    using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    IcricketAPI public cricketapi;
    IsortedPoints public sortedPoints;
    // Icalculations public calculations;
    IERC20 public fanToken;
    address public admin;
    // address private potentialAdmin;
    // uint public maxRating;
    // uint public minBatsmen;
    // uint public maxBatsmen;
    // uint public minBowler;
    // uint public maxBowler;
    // uint public minAllRounder;
    // uint public maxAllRounder;
    // uint public minWicketKeeper;
    // uint public maxWicketKeeper;
    // uint public maxFromTeam;
    // uint public adminFee;
    // uint private calcPointsIndex;
    // uint private calcRankingIndex;
    GlobalVar public globalVar;

    mapping(uint => Match) public matchDetails;
    mapping(uint => mapping(uint => Player)) public playerDetails;
    mapping(uint => mapping(uint => UserTeam[])) public userTeamDetails;
    mapping(uint => mapping(uint => Score)) public matchScore;
    mapping(uint => mapping(uint => int)) public matchPoints;
    mapping(uint => mapping(uint => mapping(int => uint[]))) public userPoints;
    mapping(uint => mapping(uint => int[])) public pointsArray;
    // mapping(uint => mapping(uint => uint[])) public matchRanking;
    mapping(address => uint) public userWallet;
    mapping(uint => mapping(uint => uint)) private calcPointsIndexMap;
    mapping(uint => mapping(uint => RankingIndex)) private calcRankingIndexMap;
    // mapping(uint => mapping(uint => uint)) private rankCounter;
    mapping(uint => mapping(uint => uint)) public override totalUniquePoints;

    BattingPoints public battingPoints;
    BowlingPoints public bowlingPoints;
    FieldingPoints public fieldingPoints;
    OtherPoints public otherPoints;
    EconomyRatePoints public economyRatePoints;
    StrikeRatePoints public strikeRatePoints;

    event MatchAddition(uint _matchID);
    event ContestAddition(uint _matchID);
    event PlayerUpdation(uint[] _playerIDs);
    event TeamCreation(uint _matchID, uint _contestID, uint index);
    event UserPointsCalculated(uint _matchID, uint _contestID);
    event UserRankingCalculated(uint _matchID, uint _contestID);
    event PlayerScoreCalculated(uint _matchID);
    event PlayerPointsCalculated(uint _matchID);
    event GlobalVarUpdated();
    event FantasyPointsUpdated();
    event MatchEnded(uint _matchID);
    event EmergencyStopped(uint _matchID, uint _contestID);

    struct GlobalVar {
        uint maxRating;
        uint minBatsmen;
        uint maxBatsmen;
        uint minBowler;
        uint maxBowler;
        uint minAllRounder;
        uint maxAllRounder;
        uint minWicketKeeper;
        uint maxWicketKeeper;
        uint maxFromTeam;
        uint calcPointsIndex;
        uint calcRankingIndex;
    }

    struct RankingIndex {
        uint pointsStart; 
        uint userStart;
        int currPoints; 
        uint rankCounter;
    }

    struct Match{
        Contest[] contest;
        uint seriesID;
        uint matchID;
        uint startTime;
        uint teamID0;
        uint teamID1;
        uint[] playerID0;
        uint[] playerID1;
        bool exists;
        bool end;
        uint winningTeamID;
        bool isTie;
        bool scoreUpdated;
        bool pointsCalculated;
    }

    struct Contest{
        uint minUsers;
        uint maxUsers;
        uint participationFee;
        uint amountCollected;
        uint expenses;
        bool isReverse;
        bool userPointsCalculated;
        bool arrayUpdated;
        bool rankingCalculated;
        bool emergencyStop;
        bool adminClaimed;
        string name;
        Reward reward;
    }

    struct Reward {
        uint[] rewardMultiplier;
        uint[] rankRange;
        uint[] newRanks;
    }

    struct Player{
        // uint currMatchID;
        uint teamID;
        uint rating;
        bool playing;
        PlayerType playerType;
    }

    struct UserTeam{
        uint[] playerIDs;
        uint captainID;
        uint viceCaptainID;
        address user;
        int points;
        uint rank;
        bool claimed;
    }

    struct Runs {
        uint runs;
        uint balls;
        uint fours;
        uint sixes;
        bool isOut;
    }

    struct Bowl {
        uint wickets;
        uint maidenOver;
        uint economy;
    }

    struct Field {
        uint catches;
        uint runout;
    }

    struct Score {
        Runs runs;
        Bowl bowl;
        Field field;
    }

    struct BattingPoints{
        uint run;
        uint four;
        uint six;
        uint run30;
        uint run50;
        uint duck;
    }

    struct BowlingPoints{
        uint wicket;
        // uint bonus;
        uint wicket3;
        uint wicket4;
        uint wicket5;
        uint maiden;
    }

    struct FieldingPoints{
        uint catches;
        uint catches3;
        uint runout;
    }

    struct OtherPoints{
        uint captain;
        uint viceCaptain;
    }

    struct EconomyRatePoints {
        uint l5;
        uint f5t6;
        uint f6t7;
        uint f10t11;
        uint f11t12;
        uint m12;
    }

    struct StrikeRatePoints {
        uint m170;
        uint f150t170;
        uint f130t150;
        uint f60t70;
        uint f50t60;
        uint l50;
    }

    enum PlayerType {
        Batsman,
        Bowler,
        AllRounder,
        WicketKeeper
    }

    modifier _adminOnly {
        require (admin == msg.sender, "NA");
        _;
    }

    constructor() public {
        admin = msg.sender;
    }

    function changeAdmin(address _admin) external _adminOnly {
        admin = _admin;
    }

    // function becomeAdmin() external {
    //     require(potentialAdmin == msg.sender, "NA");
    //     admin = msg.sender;
    // }

    function setAddresses(address _sortedPoints, address _cricketAPI, address _fanToken) external _adminOnly {
        sortedPoints = IsortedPoints(_sortedPoints);
        cricketapi = IcricketAPI(_cricketAPI);
        fanToken = IERC20(_fanToken);
        // calculations = Icalculations(_calculations);
    }

    function updateGlobalVar(GlobalVar memory _globalVar) public _adminOnly {
        globalVar = _globalVar;
        emit GlobalVarUpdated();
    }

    // function updateGlobalVar(uint _maxRating, uint _minBatsmen, uint _maxBatsmen, uint _minBowler, uint _maxBowler, uint _minAllRounder, uint _maxAllRounder, uint _minWicketKeeper, uint _maxWicketKeeper, uint _maxFromTeam, uint _adminFee, uint _calcPointsIndex, uint _calcRankingIndex) external _adminOnly {
    //     maxRating = _maxRating;
    //     minBatsmen = _minBatsmen;
    //     maxBatsmen = _maxBatsmen;
    //     minBowler = _minBowler;
    //     maxBowler = _maxBowler;
    //     minAllRounder = _minAllRounder;
    //     maxAllRounder = _maxAllRounder;
    //     minWicketKeeper = _minWicketKeeper;
    //     maxWicketKeeper = _maxWicketKeeper;
    //     maxFromTeam = _maxFromTeam;
    //     adminFee = _adminFee;
    //     calcPointsIndex = _calcPointsIndex;
    //     calcRankingIndex = _calcRankingIndex;

    //     emit GlobalVarUpdated();
    // }

    function updateFantasyPoints(BattingPoints memory _battingPoints, BowlingPoints memory _bowlingPoints, FieldingPoints memory _fieldingPoints, OtherPoints memory _otherPoints, EconomyRatePoints memory _economyRatePoints, StrikeRatePoints memory _strikeRatePoints) public _adminOnly{
        battingPoints = _battingPoints;
        bowlingPoints = _bowlingPoints;
        fieldingPoints = _fieldingPoints;
        otherPoints = _otherPoints;
        economyRatePoints = _economyRatePoints;
        strikeRatePoints = _strikeRatePoints;

        emit FantasyPointsUpdated();
    }
    // playerIDs should be added in sorted manner
    function addMatch(uint _seriesID, uint _matchID, uint _startTime, uint team0, uint team1, uint[] calldata playerID0, uint[] calldata playerID1) external _adminOnly{
        require(matchDetails[_matchID].exists == false, "ME"); // match exists
        // require(playerID0.length == playerID1.length, "addMatch: team length doesnt match");

        bytes32 tempPlayerHash = keccak256(
            abi.encodePacked(
                _seriesID,
                _matchID,
                team0,
                team1,
                playerID0,
                playerID1
            )
        );
        require (cricketapi.playerHash(_seriesID, _matchID) == tempPlayerHash, "HNE"); // hash not equal
        
        Match storage _matchDetails = matchDetails[_matchID];
    
        _matchDetails.seriesID = _seriesID;
        _matchDetails.matchID = _matchID;
        _matchDetails.startTime = _startTime;
        _matchDetails.teamID0 = team0;
        _matchDetails.teamID1 = team1;
        _matchDetails.playerID0 = playerID0;
        _matchDetails.playerID1 = playerID1;
        _matchDetails.exists = true;

        for(uint i=0; i<playerID0.length; i++){
            require(playerDetails[0][playerID0[i]].teamID == team0, "PTMM"); // player id team id mismatch
            // playerDetails[playerID0[i]].currMatchID = _matchID;
            playerDetails[_matchID][playerID0[i]].teamID = playerDetails[0][playerID0[i]].teamID; 
            playerDetails[_matchID][playerID0[i]].rating = playerDetails[0][playerID0[i]].rating;
            playerDetails[_matchID][playerID0[i]].playerType = playerDetails[0][playerID0[i]].playerType;
        }
        for(uint i=0; i<playerID1.length; i++){
            require(playerDetails[0][playerID1[i]].teamID == team1, "PTMM"); // player id team id mismatch
            // playerDetails[playerID1[i]].currMatchID = _matchID;
            playerDetails[_matchID][playerID1[i]].teamID = playerDetails[0][playerID1[i]].teamID; 
            playerDetails[_matchID][playerID1[i]].rating = playerDetails[0][playerID1[i]].rating;
            playerDetails[_matchID][playerID1[i]].playerType = playerDetails[0][playerID1[i]].playerType;
        }
        emit MatchAddition(_matchID);
    }

    function addContest(uint _matchID, Contest[] memory _contest) public _adminOnly {
        Match storage _matchDetails = matchDetails[_matchID];
        require(_matchDetails.exists == true, "MDE"); // match does not exists
        for(uint i=0; i<_contest.length; i++){
            // require(_contest[i].reward.rewardMultiplier.length == _contest[i].reward.rankRange.length, "LM"); //length mismatch
            // require(_contest[i].reward.newRanks.length == 0, "LZ"); // length should be zero
            
            uint expenses;
            uint investment;
            uint minUsers;
            uint[] memory newRanks = new uint[](_contest[i].reward.rewardMultiplier.length);
 
            for(uint j=0; j<_contest[i].reward.rewardMultiplier.length; j++){
                expenses = expenses.add(_contest[i].reward.rewardMultiplier[j].mul(_contest[i].participationFee).mul(_contest[i].reward.rankRange[j]).div(100));
                investment = investment.add(_contest[i].participationFee.mul(_contest[i].reward.rankRange[j]));
                minUsers = minUsers.add(_contest[i].reward.rankRange[j]);
                newRanks[j] = minUsers;
            }
            require (investment >= expenses , "ELI"); //expenses should be less than investment
            require (_contest[i].maxUsers >= minUsers, "UM"); // num users mismatch

            _matchDetails.contest.push(Contest(minUsers, _contest[i].maxUsers, _contest[i].participationFee, 0, expenses, _contest[i].isReverse, false, false, false, false, false, _contest[i].name, Reward(_contest[i].reward.rewardMultiplier, _contest[i].reward.rankRange, newRanks)));
        }
        emit ContestAddition(_matchID);
    }

    //same player can be in multiple teams like ipl and international
    function updatePlayerDetails(uint[] calldata playerIDs, uint[] calldata playerRatings, uint[] calldata _playerTypes, uint[] calldata teamIDs) external _adminOnly {
        require(playerIDs.length == playerRatings.length && playerIDs.length == teamIDs.length && playerIDs.length == _playerTypes.length, "LM"); //length mismatch
        for(uint i=0; i<playerIDs.length; i++){
            playerDetails[0][playerIDs[i]].teamID = teamIDs[i]; 
            playerDetails[0][playerIDs[i]].rating = playerRatings[i];
            playerDetails[0][playerIDs[i]].playerType = PlayerType(_playerTypes[i]);
        }
        emit PlayerUpdation(playerIDs);
    }

    // add playerIDs in sorted order(for repeat player check)
    function createTeam(uint _matchID, uint _contestID, uint[] memory _playerIDs, uint captainID, uint viceCaptainID, uint paymentMode) public {
        require(_playerIDs.length == 11, "N11"); //not 11 players
        require(captainID != viceCaptainID, "DIF"); //should be different
        require(matchDetails[_matchID].exists == true, "MDE"); // match does not exists
        require(matchDetails[_matchID].startTime >= block.timestamp, "MS"); // match already started
        require(matchDetails[_matchID].end == false, "ME"); // match ended
        require(matchDetails[_matchID].contest.length > _contestID, "CDE"); // contest doesnt exist
        Contest storage contestDetails = matchDetails[_matchID].contest[_contestID];
        require(userTeamDetails[_matchID][_contestID].length < contestDetails.maxUsers, "MLR"); // max limit reached
        if(paymentMode == 0){
            // require(contestDetails.participationFee <= msg.value, "FI"); // fee issue
            require(fanToken.transferFrom(msg.sender, address(this), contestDetails.participationFee), "FTI");
        } else {
            //TODO need to test
            userWallet[msg.sender] = userWallet[msg.sender].sub(contestDetails.participationFee);
        }
        contestDetails.amountCollected = contestDetails.amountCollected.add(contestDetails.participationFee);

        uint[] memory numPlayers = new uint[](4);
        uint[] memory sums = new uint[](3);

        for(uint i=0; i<_playerIDs.length; i++){
            if(i != _playerIDs.length - 1){
                require(_playerIDs[i] < _playerIDs[i+1], "SO"); // not in sorted order
            }
            // TODO captain id and vice captain id same
            if(captainID == _playerIDs[i] || viceCaptainID == _playerIDs[i]) {
                sums[2]++;
            }
            Player storage player = playerDetails[_matchID][_playerIDs[i]];
            // require(player.currMatchID == _matchID, "NP"); // players not playing
            numPlayers[uint(player.playerType)]++;
            if(matchDetails[_matchID].teamID0 == player.teamID){
                sums[1]++;
            }
            sums[0] = sums[0].add(player.rating);
        }
        require(sums[2] == 2, "CE"); // captain/vice captain error
        require(sums[0] <= globalVar.maxRating, "MRE"); // max rating exceeded
        require(numPlayers[0] <= globalVar.maxBatsmen && numPlayers[0] >= globalVar.minBatsmen, "MBE"); // max batsmen error
        require(numPlayers[1] <= globalVar.maxBowler && numPlayers[1] >= globalVar.minBowler, "MBOE"); // max bowler error
        require(numPlayers[2] <= globalVar.maxAllRounder && numPlayers[2] >= globalVar.minAllRounder, "ARE"); //all rounder error
        require(numPlayers[3] <= globalVar.maxWicketKeeper && numPlayers[3] >= globalVar.minWicketKeeper, "WKE"); //wicket keeper error
        require(sums[1] <= globalVar.maxFromTeam && (11 - sums[1]) <= globalVar.maxFromTeam, "NPE"); // number of players exceeded

        userTeamDetails[_matchID][_contestID].push(UserTeam(_playerIDs, captainID, viceCaptainID, msg.sender, 0, 0, false));

        emit TeamCreation(_matchID, _contestID, userTeamDetails[_matchID][_contestID].length - 1);
    }

    function updateMatchStart(uint _matchID, uint _timestamp) external _adminOnly{
        matchDetails[_matchID].startTime = _timestamp;
    }

    function updateMatchEnd(uint _matchID) external {
        if(cricketapi.matchEnded(matchDetails[_matchID].seriesID, _matchID) == true) {
            matchDetails[_matchID].end = true;
            emit MatchEnded(_matchID);
        }
    }

    // different for ipl, test (ipl -> 22, test ->44(as 4 innings))
    function updateMatchScore(uint _matchID, uint _winningTeamID, uint[] memory playerIDs, Runs[] memory runs, Bowl[] memory bowling, Field[] memory fielding) public{
        // TODO remove? require(playerIDs.length == 22, "N22"); // not 22 players
        require(playerIDs.length == runs.length && playerIDs.length == bowling.length && playerIDs.length == fielding.length, "LM"); //length mismatch
        require(matchDetails[_matchID].exists == true, "MDE");
        require(matchDetails[_matchID].end == true, "MNE"); // match not ended

        bytes32 tempHash;
        for(uint index=0;index<runs.length;index++){
            tempHash = keccak256(
                abi.encodePacked(
                    runs[index].runs,
                    runs[index].balls, 
                    runs[index].fours, 
                    runs[index].sixes,
                    runs[index].isOut,
                    tempHash
                )
            );
        }

        for(uint index=0;index<bowling.length;index++){
            tempHash = keccak256(
                abi.encodePacked(
                    bowling[index].wickets, 
                    bowling[index].maidenOver, 
                    bowling[index].economy, 
                    tempHash
                )
            );
        }

        for(uint index=0;index<fielding.length;index++){
            tempHash = keccak256(
                abi.encodePacked(
                    fielding[index].catches,
                    fielding[index].runout,
                    tempHash
                )
            );
        }

        tempHash = keccak256(
            abi.encodePacked(
                playerIDs,
                _winningTeamID,
                tempHash
            )
        );

        require (cricketapi.scoreHash(matchDetails[_matchID].seriesID, _matchID) == tempHash, "HNE"); // hash not equal
        for(uint index=0;index<runs.length;index++){
            Score storage score = matchScore[_matchID][playerIDs[index]];
            score.runs = runs[index];
            score.bowl = bowling[index];
            score.field = fielding[index];
            playerDetails[_matchID][playerIDs[index]].playing = true;
        }
        matchDetails[_matchID].scoreUpdated = true;
        if (_winningTeamID == 0) {
            matchDetails[_matchID].isTie = true;
        }
        matchDetails[_matchID].winningTeamID = _winningTeamID;
        emit PlayerScoreCalculated(_matchID);
    }

    function calculatePlayerPoints(uint _matchID) external {
        Match storage matchData = matchDetails[_matchID];
        require(matchData.scoreUpdated == true, "SNU"); // score not updated

        for(uint i=0; i<matchData.playerID0.length; i++){
            if (playerDetails[_matchID][matchData.playerID0[i]].playing == true){
                Score storage score = matchScore[_matchID][matchData.playerID0[i]];
                int points = _calcPoints(score);
                matchPoints[_matchID][matchData.playerID0[i]] = points;
            } else {
                matchPoints[_matchID][matchData.playerID0[i]] = 0;
            }
        }
        for(uint i=0; i<matchData.playerID1.length; i++){
            if (playerDetails[_matchID][matchData.playerID1[i]].playing == true){
                Score storage score = matchScore[_matchID][matchData.playerID1[i]];
                int points = _calcPoints(score);
                matchPoints[_matchID][matchData.playerID1[i]] = points;
            } else {
                matchPoints[_matchID][matchData.playerID1[i]] = 0;
            }
        }
        matchData.pointsCalculated = true;
        emit PlayerPointsCalculated(_matchID);
    }

    // offchain
    // people can call this function within certain timeperiod
    // max score tk loop
    // predecided number of winners, maintain sorted array for that number only (equal amoun to all) or sorted
    // TODO introduce status enum rather than flag for everything
    function calculateUserPoints(uint _matchID, uint _contestID) external {
        require(matchDetails[_matchID].pointsCalculated == true, "MPNC"); // match points not calculated
        require(matchDetails[_matchID].contest[_contestID].userPointsCalculated != true, "UPC"); // user points already calculated
        UserTeam[] storage userTeam = userTeamDetails[_matchID][_contestID];
        if (matchDetails[_matchID].contest[_contestID].minUsers > userTeam.length) {
            _stopMatch(_matchID, _contestID);
        }

        if(calcPointsIndexMap[_matchID][_contestID] >= userTeam.length){
            matchDetails[_matchID].contest[_contestID].userPointsCalculated = true;
            emit UserPointsCalculated(_matchID, _contestID);
            return;
        }
        uint toIndex = userTeam.length - calcPointsIndexMap[_matchID][_contestID] > globalVar.calcPointsIndex ? globalVar.calcPointsIndex :  userTeam.length - calcPointsIndexMap[_matchID][_contestID];
        uint i;
        for(i=calcPointsIndexMap[_matchID][_contestID]; i<calcPointsIndexMap[_matchID][_contestID] + toIndex; i++){

            int points = _calcUserPoints(_matchID, userTeam[i].playerIDs, userTeam[i].captainID, userTeam[i].viceCaptainID);
            userTeam[i].points = points;
            if(userPoints[_matchID][_contestID][points].length == 0){
                pointsArray[_matchID][_contestID].push(points);
                totalUniquePoints[_matchID][_contestID]++;
            }
            userPoints[_matchID][_contestID][points].push(i);
        }
        calcPointsIndexMap[_matchID][_contestID] = i;
    }

    // TODO what happens if points array length is huge (worked till 3000)
    // function updatePointsArray(uint _matchID, uint _contestID, int[] calldata _pointsArray) external {
    //     require(matchDetails[_matchID].contest[_contestID].userPointsCalculated == true, "updatePointsArray: user points not calculated");
    //     require(pointsArray[_matchID][_contestID].length == _pointsArray.length, "updatePointsArray: array length should be same");
    //     for(uint i=0; i<_pointsArray.length; i++){
    //         if(i != _pointsArray.length - 1) { require(_pointsArray[i]>_pointsArray[i+1], "updatePointsArray: not in sorted order"); }
    //         require(userPoints[_matchID][_contestID][_pointsArray[i]].length > 0, "updatePointsArray: points does not exist");
    //     }
    //     pointsArray[_matchID][_contestID] = _pointsArray;
    //     matchDetails[_matchID].contest[_contestID].arrayUpdated = true;
    // }


    function updatePointsArray(uint _matchID, uint _contestID, int[] calldata _pointsArray, int[] calldata _prevPoints, int[] calldata _nextPoints) external {
        require(matchDetails[_matchID].contest[_contestID].userPointsCalculated == true, "UPNC"); //user points not calculated
        for(uint i=0; i<_pointsArray.length; i++){
            require(userPoints[_matchID][_contestID][_pointsArray[i]].length > 0, "PDE"); //points does not exist
            sortedPoints.insert(_matchID, _contestID, _pointsArray[i], _prevPoints[i], _nextPoints[i]);
        }
        if (sortedPoints.isFull(_matchID, _contestID)) {
            matchDetails[_matchID].contest[_contestID].arrayUpdated = true;
        }
    }

    function calculateUserRanking(uint _matchID, uint _contestID) external{
        Contest storage contestDetails = matchDetails[_matchID].contest[_contestID];
        require(contestDetails.rankingCalculated != true, "RC"); // ranking already calculated
        require(contestDetails.arrayUpdated == true, "UANU"); // user array not updated
        bool isReverse = contestDetails.isReverse;
        // Reward storage reward = contestDetails.reward;
        // uint rankPercentile;
        // uint ranks;
        // for(uint i=0; i<reward.rankPercentile.length; i++){
        //     rankPercentile = rankPercentile.add(reward.rankPercentile[i]);
        // }
        // uint lastRank = rankPercentile.mul(userTeamDetails[_matchID][_contestID].length).div(10000);
        uint counter;
        // uint i;
        uint pointsStart = calcRankingIndexMap[_matchID][_contestID].pointsStart;
        uint userStart = calcRankingIndexMap[_matchID][_contestID].userStart;
        int currPoints = calcRankingIndexMap[_matchID][_contestID].currPoints;
        uint rankCounter = calcRankingIndexMap[_matchID][_contestID].rankCounter;

        if (pointsStart == 0 && userStart == 0 && currPoints == 0) {
            currPoints = isReverse ? sortedPoints.getLast(_matchID, _contestID) : sortedPoints.getFirst(_matchID, _contestID);
        }

        for(uint i=pointsStart; i<sortedPoints.getSize(_matchID, _contestID); i++){
            for(uint j=userStart; j<userPoints[_matchID][_contestID][currPoints].length; j++){
                // matchRanking[_matchID][_contestID].push(userPoints[_matchID][_contestID][currPoints][j]);
                // userTeamDetails[_matchID][_contestID][userPoints[_matchID][_contestID][currPoints][j]].rank = matchRanking[_matchID][_contestID].length - 1;
                userTeamDetails[_matchID][_contestID][userPoints[_matchID][_contestID][currPoints][j]].rank = rankCounter;
                counter++;
                rankCounter++;
                if(counter >= globalVar.calcRankingIndex) {
                    calcRankingIndexMap[_matchID][_contestID].pointsStart = i;
                    calcRankingIndexMap[_matchID][_contestID].userStart = j + 1;
                    calcRankingIndexMap[_matchID][_contestID].currPoints = currPoints;
                    calcRankingIndexMap[_matchID][_contestID].rankCounter = rankCounter;
                    return;
                }
            }
            currPoints = isReverse ? sortedPoints.getPrev(_matchID, _contestID, currPoints) : sortedPoints.getNext(_matchID, _contestID, currPoints);
            userStart = 0;
        }
        contestDetails.rankingCalculated = true;
        emit UserRankingCalculated(_matchID, _contestID);
    }

    //TODO all mapping with matchID can be combined to single struct
    //TODO fund loss chance if no people in that range to claim
    // function claimReward(uint _matchID, uint _contestID, uint _teamID) external{
    //     Contest storage contest = matchDetails[_matchID].contest[_contestID];
    //     require(contest.emergencyStop == false, "claimReward: match stopped");
    //     UserTeam[] storage userTeam = userTeamDetails[_matchID][_contestID];
    //     require (userTeam[_teamID].claimed == false, "claimReward: reward already claimed");
    //     require (contest.rankingCalculated == true, "claimReward: user ranks not calculated");
    //     uint rank = userTeam[_teamID].rank;
    //     Reward storage reward = contest.reward;
    //     _updateContestNewRanks(reward, userTeam.length);
    //     for(uint i = 0; i < reward.newRanks.length - 1; i++){
    //         if((reward.newRanks[i] <= rank && reward.newRanks[i+1] > rank) || rank == 0 && reward.newRanks[i] == 0 && reward.newRanks[i+1] == 0 ){
    //             uint rewardAmount;
    //             if (rank == 0 && reward.newRanks[i] == 0 && reward.newRanks[i+1] == 0) {
    //                 rewardAmount = contest.amountCollected.mul(reward.newRewards[i]).div(10000);
    //             } else {
    //                 rewardAmount = contest.amountCollected.mul(reward.newRewards[i]).div(10000).div(reward.newRanks[i+1].sub(reward.newRanks[i]));
    //             }
    //             uint adminRewardAmount = rewardAmount.mul(adminFee).div(10000);
    //             rewardAmount = rewardAmount.sub(adminRewardAmount);
    //             address user = userTeam[_teamID].user;
    //             userWallet[user] = userWallet[user].add(rewardAmount);
    //             userWallet[admin] = userWallet[admin].add(adminRewardAmount);
    //             break;
    //         }
    //     }
    //     userTeam[_teamID].claimed == true;
    // }

    function claimReward(uint _matchID, uint _contestID, uint _teamID) external {
        Contest storage contest = matchDetails[_matchID].contest[_contestID];
        require(contest.emergencyStop == false, "MS"); // match stopped
        UserTeam[] storage userTeam = userTeamDetails[_matchID][_contestID];
        require (userTeam[_teamID].claimed == false, "RC"); // reward claimed
        require (contest.rankingCalculated == true, "URNC"); // user ranks not calculated
        uint rank = userTeam[_teamID].rank;
        Reward storage reward = contest.reward;
        for (uint i = 0; i < reward.newRanks.length; i++) {
            if (rank < reward.newRanks[i]) {
                uint rewardAmount = contest.reward.rewardMultiplier[i].mul(contest.participationFee).div(100);
                address user = userTeam[_teamID].user;
                userWallet[user] = userWallet[user].add(rewardAmount);
                break;
            }
        }
        userTeam[_teamID].claimed = true;
    }

    function getRewardAmount(uint _matchID, uint _contestID, uint _teamID) external view returns(uint){
        Contest storage contest = matchDetails[_matchID].contest[_contestID];
        UserTeam[] storage userTeam = userTeamDetails[_matchID][_contestID];
        if (contest.emergencyStop == true || userTeam[_teamID].claimed == true || contest.rankingCalculated == false) {
            return 0;
        }
        uint rank = userTeam[_teamID].rank;
        Reward storage reward = contest.reward;
        for (uint i = 0; i < reward.newRanks.length; i++) {
            if (rank < reward.newRanks[i]) {
                uint rewardAmount = contest.reward.rewardMultiplier[i].mul(contest.participationFee).div(100);
                return rewardAmount;
            }
        }
        return 0;
    }

    function claimAdminFunds(uint _matchID, uint _contestID) external {
        Contest storage contest = matchDetails[_matchID].contest[_contestID];
        require(contest.emergencyStop == false, "MS");
        require(contest.adminClaimed == false, "AC"); // admin already claimed
        contest.adminClaimed = true;
        uint adminRewardAmount = contest.amountCollected.sub(contest.expenses);
        userWallet[admin] = userWallet[admin].add(adminRewardAmount);
    }

    function withdrawFunds() external {
        uint amount = userWallet[msg.sender];
        delete userWallet[msg.sender];
        // payable(msg.sender).transfer(amount);
        require(fanToken.transfer(msg.sender, amount), "FTI");
    }

    function emergencyWithdrawFunds(uint _matchID, uint _contestID, uint _teamID) external {
        require(matchDetails[_matchID].contest[_contestID].emergencyStop == true, "MNS"); // match not stopped
        UserTeam storage userTeam = userTeamDetails[_matchID][_contestID][_teamID];
        require (userTeam.claimed == false, "FC"); // funds already claimed
        address user = userTeam.user;
        userWallet[user] = userWallet[user].add(matchDetails[_matchID].contest[_contestID].participationFee);
        userTeam.claimed = true;
    }

    function emergencyStopMatch(uint _matchID, uint _contestID) external _adminOnly {
        require(matchDetails[_matchID].scoreUpdated == false, "MSC"); // match score already calculated
        _stopMatch(_matchID, _contestID);
    }

    // function _updateContestNewRanks(Reward storage reward, uint teamLength) internal {
    //     if(reward.newRanks.length == 0) {
    //         uint rankPercentile;
    //         uint startRank;
    //         uint endRank;
    //         reward.newRanks.push(endRank);
    //         for(uint i=0; i<reward.rankPercentile.length; i++){
    //             startRank = endRank;
    //             rankPercentile = rankPercentile.add(reward.rankPercentile[i]);
    //             endRank = rankPercentile.mul(teamLength).div(10000);
    //             if(startRank == endRank){
    //                 if (reward.newRewards.length == 0) {
    //                     reward.newRanks.push(0);
    //                     reward.newRewards.push(0);
    //                 }
    //                 reward.newRewards[reward.newRewards.length - 1] = reward.newRewards[reward.newRewards.length - 1].add(reward.rewardPercentage[i]);
    //                 continue;
    //             }
    //             reward.newRanks.push(endRank);
    //             reward.newRewards.push(reward.rewardPercentage[i]);
    //         }
    //     }
    // }

    function _stopMatch(uint _matchID, uint _contestID) internal {
        matchDetails[_matchID].contest[_contestID].emergencyStop = true;
        emit EmergencyStopped(_matchID, _contestID);
    }

    function _calcPoints(Score memory score) internal view returns (int) {
        // because player might have negative points only
        int points;

        // BATTING POINTS
        points = points+int((score.runs.runs)*(battingPoints.run));
        points = points+int((score.runs.fours)*(battingPoints.four));
        points = points+int((score.runs.sixes)*(battingPoints.six));
        if(score.runs.runs >= 50){
            points = points+int(battingPoints.run50);
        } else if (score.runs.runs >= 30){
            points = points+int(battingPoints.run30);
        } else if (score.runs.runs == 0 && score.runs.isOut == true){ // score 0 doesnt mean duck, might not have played
            points = points-int(battingPoints.duck);
        }

        // BOWLING POINTS
        points = points+int((score.bowl.wickets)*(bowlingPoints.wicket));
        if(score.bowl.wickets >= 5){
            points = points+int(bowlingPoints.wicket5);
        } else if(score.bowl.wickets >= 4){
            points = points+int(bowlingPoints.wicket4);
        } else if(score.bowl.wickets >= 3){
            points = points+int(bowlingPoints.wicket3);
        }
        points = points+int((score.bowl.maidenOver)*(bowlingPoints.maiden));

        // FIELDING POINTS
        points = points+int((score.field.catches)*(fieldingPoints.catches));
        if(score.field.catches >= 3){
            points = points+int(fieldingPoints.catches3);
        }
        points = points+int((score.field.runout)*(fieldingPoints.runout));

        // ECONOMY POINTS
        if(score.bowl.economy == 0 && score.bowl.maidenOver > 0){
            points = points+int(economyRatePoints.l5);
        }
        else if(score.bowl.economy > 0 && score.bowl.economy <= 500){
            points = points+int(economyRatePoints.l5);
        } else if(score.bowl.economy > 500 && score.bowl.economy <= 600){
            points = points+int(economyRatePoints.f5t6);
        } else if(score.bowl.economy > 600 && score.bowl.economy <= 700){
            points = points+int(economyRatePoints.f6t7);
        } else if(score.bowl.economy > 1000 && score.bowl.economy <= 1100){
            points = points-int(economyRatePoints.f10t11);
        } else if(score.bowl.economy > 1100 && score.bowl.economy <= 1200){
            points = points-int(economyRatePoints.f11t12);
        } else if(score.bowl.economy > 1200){
            points = points-int(economyRatePoints.m12);
        }

        // STRIKE RATE POINTS
        if(score.runs.balls > 0){
            uint strikerate = score.runs.runs.mul(1e4).div(score.runs.balls);
            if(strikerate >= 17000){
                points = points+int(strikeRatePoints.m170);
            } else if(strikerate >= 15000 && strikerate < 17000){
                points = points+int(strikeRatePoints.f150t170);
            } else if(strikerate >= 13000 && strikerate < 15000){
                points = points+int(strikeRatePoints.f130t150);
            } else if(strikerate >= 6000 && strikerate < 7000){
                points = points-int(strikeRatePoints.f60t70);
            } else if(strikerate >= 5000 && strikerate < 6000){
                points = points-int(strikeRatePoints.f50t60);
            } else if(strikerate < 5000){
                points = points-int(strikeRatePoints.l50);
            }
        }
        return points;
    }

    function _calcUserPoints(uint _matchID, uint[] memory playerIDs, uint captainID, uint viceCaptainID) internal view returns(int){
        int points;
        for(uint i=0; i<playerIDs.length; i++){
            int playerPoint = matchPoints[_matchID][playerIDs[i]];
            if(playerIDs[i] == captainID){
                playerPoint = (playerPoint * int(otherPoints.captain)) / 10;
            } else if (playerIDs[i] == viceCaptainID){
                playerPoint = (playerPoint * int(otherPoints.viceCaptain)) / 10;
            }
            points = points + playerPoint;
        }
        // points = points+(matchPoints[_matchID][captainID]*int(otherPoints.captain));
        // points = points+(matchPoints[_matchID][viceCaptainID]*int(otherPoints.viceCaptain));
        return points;
    }

    function getMatchPointsArray(uint _matchID, uint _contestID) external view returns(int[] memory){
        return pointsArray[_matchID][_contestID];
    }

    // function getUserPointsArray(uint _matchID, uint _contestID, int _point) external view returns(uint[] memory) {
    //     return userPoints[_matchID][_contestID][_point];
    // }

    // function getUserTeams(uint _matchID, uint _contestID) external view returns (UserTeam[] memory){
    //     return userTeamDetails[_matchID][_contestID];
    // }

    function getUserTeamsWithIndex(uint _matchID, uint _contestID, uint index) external view returns (UserTeam memory){
        return userTeamDetails[_matchID][_contestID][index];
    }

    function getMatchContestDetails(uint _matchID) external view returns (Contest[] memory){
        return matchDetails[_matchID].contest;
    }

    function getMatchPlayerDetails(uint _matchID) external view returns (uint[] memory, uint[] memory){
        return (matchDetails[_matchID].playerID0, matchDetails[_matchID].playerID1);
    }

    // function getMatchRank(uint _matchID, uint _contestID) external view returns (uint[] memory){
    //     return matchRanking[_matchID][_contestID];
    // }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

interface Icricket {
    function totalUniquePoints(uint _matchID, uint _contetID) external view returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

interface IcricketAPI {
    function playerHash(uint _seriesID, uint _matchID) external returns (bytes32);
    function matchEnded(uint _seriesID, uint _matchID) external returns (bool);
    function scoreHash(uint _seriesID, uint _matchID) external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

interface IsortedPoints {
    function insert (uint _matchID, uint _contestID, int _score, int _prevScore, int _nextScore) external;
    function isFull(uint _matchID, uint _contestID) external view returns (bool);
    function getSize(uint _matchID, uint _contestID) external view returns (uint);
    function getNext(uint _matchID, uint _contestID, int _score) external view returns (int);
    function getFirst(uint matchID, uint contestID) external view returns (int);
    function getPrev(uint _matchID, uint _contestID, int _score) external view returns (int);
    function getLast(uint matchID, uint contestID) external view returns (int);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}