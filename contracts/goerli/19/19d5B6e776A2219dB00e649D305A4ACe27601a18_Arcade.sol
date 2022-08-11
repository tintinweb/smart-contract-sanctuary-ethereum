//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";

//this contract should be named leaderboard, not arcade, probably.
contract Arcade is Ownable {
    string leaderboardName;
    uint256 nowToDay = 86400;
    uint256 firstPlaceCut = 50;
    uint256 secondPlaceCut = 25;
    uint256 thirdPlaceCut = 10;
    uint256 gameDevTakeRate = (100 - firstPlaceCut - thirdPlaceCut) / 2;
    uint256 protocolTakeRate = (100 - firstPlaceCut - thirdPlaceCut) / 2;
    uint256 costOfPlaying = 1e15; //1e15 = 0.001 eth
    address protocolPayoutWallet = 0x3f2ff81DA0B5E957ba78A0C4Ad3272cB7d214e71; //this is my arcade payout wallet on metamask
    address gameDevPayoutWallet = 0x3f2ff81DA0B5E957ba78A0C4Ad3272cB7d214e71; //this is my arcade payout wallet on metamask
    bool hasWhitelist = false;

    mapping(address => uint256) public arcadeTokensAvailable;
    mapping(address => bool) whitelistedAddresses;
    mapping(address => bool) gameSubmittooorList;

    mapping(uint256 => GameResult[]) public leaderboard;
    mapping(uint256 => bool) public dayHasBeenPaidOutList;

    struct GameResult {
        string game;
        address player;
        uint256 dayPlayed;
        uint256 score;
    }

    event gameResultSubmitted(
        string _game,
        address _player,
        uint256 _dayPlayed,
        uint256 _score
    );
    event arcadeTokenBought(address _address);
    event addressAddedToWhitelist(address _address);
    event addressRemovedFromWhitelist(address _address);
    event dayHasBeenPaidOutEvent(uint256 _day);

    //I should probably emit an event when game result is submitted... that will allow for front-end to wait for the event, and update data (like total pool value, leaderboard) when this happens
    function submitGameResult(
        string memory _game,
        address _userAddress,
        uint256 _score
    ) public isWhitelisted(_userAddress) {
        require(
            arcadeTokensAvailable[_userAddress] > 0,
            "Sorry, you need to pay to play!"
        );
        leaderboard[block.timestamp / nowToDay].push(
            GameResult(_game, _userAddress, block.timestamp / nowToDay, _score)
        );
        arcadeTokensAvailable[_userAddress]--;
        emit gameResultSubmitted(
            _game,
            _userAddress,
            block.timestamp / nowToDay,
            _score
        );
    }

    //Returns the current day
    function getCurrentDay() public view returns (uint256) {
        return block.timestamp / nowToDay;
    }

    //User deposits the game's cost to play, and then is able to play one game
    function buyArcadeToken() public payable isWhitelisted(msg.sender) {
        require(msg.value == costOfPlaying);
        arcadeTokensAvailable[msg.sender]++;
        emit arcadeTokenBought(msg.sender);
    }

    //I think I can get rid of this
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //Updates the cost of playing
    function updateCostOfPlaying(uint256 _newCost) public onlyOwner {
        costOfPlaying = _newCost;
    }

    //Returns the message sender's arcade token balance
    function getMyArcadeTokenBalance() public view returns (uint256) {
        return arcadeTokensAvailable[msg.sender];
    }

    //Initiates the daily payout, and sets that day to paid (so it can't be done twice)
    function dailyPayOut(uint256 _day) public payable {
        require(
            dayHasBeenPaidOutList[_day] != true,
            "Sorry, this day's payout has already been distributed!"
        );
        require(
            block.timestamp / nowToDay > _day,
            "Sorry, this day has not yet ended!"
        );

        address firstPlace;
        uint256 firstPlaceScore = 0;
        address secondPlace;
        uint256 secondPlaceScore = 0;
        address thirdPlace;
        uint256 thirdPlaceScore = 0;
        uint256 totalPool;

        //Looping through the leaderboard to determine top 3 scores
        for (uint256 i = 0; i < leaderboard[_day].length; i++) {
            totalPool += costOfPlaying;
            if (leaderboard[_day][i].score > firstPlaceScore) {
                thirdPlace = secondPlace;
                thirdPlaceScore = secondPlaceScore;
                secondPlace = firstPlace;
                secondPlaceScore = firstPlaceScore;
                firstPlace = leaderboard[_day][i].player;
                firstPlaceScore = leaderboard[_day][i].score;
            } else if (leaderboard[_day][i].score > secondPlaceScore) {
                thirdPlace = secondPlace;
                thirdPlaceScore = secondPlaceScore;
                secondPlace = leaderboard[_day][i].player;
                secondPlaceScore = leaderboard[_day][i].score;
            } else if (leaderboard[_day][i].score > thirdPlaceScore) {
                thirdPlace = leaderboard[_day][i].player;
                thirdPlaceScore = leaderboard[_day][i].score;
            }
        }

        uint256 firstPlacePrize = (totalPool * firstPlaceCut) / 100;
        uint256 secondPlacePrize = (totalPool * secondPlaceCut) / 100;
        uint256 thirdPlacePrize = (totalPool * thirdPlaceCut) / 100;
        uint256 protocolTake = (totalPool * protocolTakeRate) / 100;
        uint256 gameDevTake = (totalPool * gameDevTakeRate) / 100;

        payable(firstPlace).transfer(firstPlacePrize);
        payable(secondPlace).transfer(secondPlacePrize);
        payable(thirdPlace).transfer(thirdPlacePrize);
        payable(protocolPayoutWallet).transfer(protocolTake);
        payable(gameDevPayoutWallet).transfer(gameDevTake);
        dayHasBeenPaidOutList[_day] = true;
        emit dayHasBeenPaidOutEvent(_day);
    }

    //Returns the total $ pool from the day's leaderboard
    function getDailyPoolValue(uint256 _day) public view returns (uint256) {
        return leaderboard[_day].length * costOfPlaying;
    }

    //Function to update the wallet where payout is sent.  Can only be called by contract owner.
    function updateProtocolPayoutWallet(address _newAddress) public onlyOwner {
        protocolPayoutWallet = _newAddress;
    }

    //Function to update the wallet where payout is sent.  Can only be called by contract owner.
    function updateGameDevPayoutWallet(address _newAddress) public onlyOwner {
        gameDevPayoutWallet = _newAddress;
    }

    //Returns the length of the leaderboard
    function getLeaderboardLength(uint256 _day) public view returns (uint256) {
        return leaderboard[_day].length;
    }

    function updatePayoutStructure(
        uint256 _firstPlacePayout,
        uint256 _secondPlacePayout,
        uint256 _thirdPlacePayout,
        uint256 _gameDevPayout,
        uint256 _protocolPayout
    ) public onlyOwner {
        require(
            _firstPlacePayout +
                _secondPlacePayout +
                _thirdPlacePayout +
                _gameDevPayout +
                _protocolPayout ==
                100,
            "Sorry, sum must equal 100"
        );
        firstPlaceCut = _firstPlacePayout;
        secondPlaceCut = _secondPlacePayout;
        thirdPlaceCut = _thirdPlacePayout;
        gameDevTakeRate = _gameDevPayout;
        protocolTakeRate = _protocolPayout;
    }

    function turnOnWhitelist() public onlyOwner {
        hasWhitelist = true;
    }

    function turnOffWhitelist() public onlyOwner {
        hasWhitelist = false;
    }

    function addUserToWhitelist(address _address) public onlyOwner {
        whitelistedAddresses[_address] = true;
        emit addressAddedToWhitelist(_address);
    }

    function removeUserFromWhitelist(address _address) public onlyOwner {
        whitelistedAddresses[_address] = false;
        emit addressRemovedFromWhitelist(_address);
    }

    modifier isWhitelisted(address _address) {
        if (hasWhitelist) {
            require(
                whitelistedAddresses[_address],
                "Sorry, you need to be whitelisted to play in this lobby"
            );
        }
        _;
    }

    function addGameSubmittooorAddress(address _address) public onlyOwner {
        gameSubmittooorList[_address] = true;
    }

    function removeGameSubmittooorAddress(address _address) public onlyOwner {
        gameSubmittooorList[_address] = false;
    }

    function changeLeaderboardName(string memory _name) public {
        leaderboardName = _name;
    }

    modifier isGameSubmittooor(address _address) {
        require(
            gameSubmittooorList[_address],
            "Sorry, you can't submit game results"
        );
        _;
    }
}