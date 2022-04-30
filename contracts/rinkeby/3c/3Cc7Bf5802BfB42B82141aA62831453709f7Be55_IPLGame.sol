// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./Mortal.sol";
import "./SafeMath.sol";

contract IPLGame is Mortal {

    // State variables
    // assert(1 gwei == 1e9);
    uint internal currentGame = 1;
    uint public minimumAmount = 10000000 gwei ;

    // Mappings
    mapping(uint=>mapping(string=>address[])) predictions;
    mapping(uint=>mapping(address=>uint)) private betAmount;
    mapping(uint=>string) private result;

    // Events
    event Winner(address indexed winner, uint amount);
    event BetPlaced(address indexed bettor, uint indexed matchId, string team, uint amount);
    event ResultSet(uint indexed matchId, string winningTeamId, string losingTeamId);
    event Winners(uint indexed matchId, address[] winners);
    event Losers(uint indexed matchId, address[] losers);

    // Functions
    function makeBet(uint _matchId, string memory _team, uint _timestamp) public payable {
        // require((_timestamp < block.timestamp+5 ), "Can't place bet after allowed time.");
        require((msg.value >= minimumAmount), "Minimum bet of 1 Gwei can be placed.");
        require(betAmount[_matchId][msg.sender] == 0, "Already placed a bet before");
        predictions[_matchId][_team].push(msg.sender);
        betAmount[_matchId][msg.sender] = msg.value;
        emit BetPlaced(msg.sender, _matchId, _team, msg.value);
    }

    function getPredictions(uint _matchId, string memory _team) public view returns (address[] memory) {
        return predictions[_matchId][_team];
    }

    function getPredictionNumber(uint _matchId, string memory _team) public view returns (uint) {
        return predictions[_matchId][_team].length;
    }

    function setResult(uint _matchId, string memory _winningTeamId, string memory _losingTeamId) onlyOwner() payable public {
        require((_matchId >= currentGame), "Only set the results for current and future game");
        emit ResultSet(_matchId, _winningTeamId, _losingTeamId);
        result[_matchId] = _winningTeamId;
        address[] memory losers = predictions[_matchId][_losingTeamId];
        emit Losers(_matchId, losers);
        uint toDistribute;
        uint total;
        for(uint i = 0; i < losers.length; i++){
            toDistribute += betAmount[_matchId][losers[i]];
        }
        toDistribute = (toDistribute/10)*9;

        address[] memory winners = predictions[_matchId][_winningTeamId];
        emit Winners(_matchId, winners);
        for (uint i = 0; i < winners.length; i++) {
            total += betAmount[_matchId][winners[i]];
        }
        for (uint i = 0; i < winners.length; i++) {
            uint transferAmount = ((toDistribute/total)+1)*betAmount[_matchId][winners[i]];
            address payable win = payable(winners[i]);
            win.transfer(transferAmount);
            emit Winner(winners[i], transferAmount-betAmount[_matchId][winners[i]]);
        }
        currentGame++;
    }

    function getResult(uint _matchId) public view returns (string memory ) {
        return result[_matchId];
    }

    function playerBalance() public view returns (uint) {
        return msg.sender.balance;
    }

    function getCurrentGame() public view returns (uint) {
        return currentGame;
    }

}