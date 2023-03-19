/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

//import "hardhat/console.sol";


contract Quiz {

    address public admin;
    uint8 public currRound;

    string[] public countries = ["GERMANY", "FRANCH", "CHINA", "BRIZAL", "KOREA"];
    mapping(uint => mapping(address => Player)) players;
    mapping(uint => mapping(Country => address[])) public countryToPlayers;
    mapping(address => uint) public winnerVaults;

    enum Country {
        GERMANY,
        FRANCH,
        CHINA,
        BRAZIL,
        KOREA
    }

    struct Player {
        bool isSet;
        mapping(Country => uint) counts;
    }

    uint public deadline;

    uint public lockAtms;

    event Play(uint8 _currRound, address _player, Country _country);
    event Finialize(uint8 _currRound, uint256 _country);
    event ClaimReward(address _claimer, uint256 _amt);

    modifier onlyAdmin() {
        require(admin == msg.sender,"Only admin can handle");
        _;
    }

    constructor(uint _deadline) {
        admin = msg.sender;
        require(_deadline > block.timestamp,"invalid deadline!");
        deadline = _deadline;
    }

    function play(Country _country) external payable {
        require(msg.value == 1 gwei, "value error");
        require(block.timestamp < deadline, "it's all over!");
        countryToPlayers[currRound][_country].push(msg.sender);

        Player storage _player = players[currRound][msg.sender];
        _player.counts[_country]+=1;
        //console.log("currRound:%s,address:%s,country:%s",currRound,msg.sender,uint(_country));
        emit Play(currRound,msg.sender,_country);
    }

    function finialize(Country _country) external onlyAdmin() {
        address[] memory _winners = countryToPlayers[currRound][_country];
        uint _winnerBalance = getBalance() - lockAtms;
        uint distribution;
        for(uint i = 0; i < _winners.length; i++){
            address _winner = _winners[i];
            Player storage _winnerPlayer = players[currRound][_winner];
            if(_winnerPlayer.isSet){
                continue;
            }
            _winnerPlayer.isSet = true;
            winnerVaults[_winner] += (_winnerBalance / _winners.length) * _winnerPlayer.counts[_country];
            distribution+=winnerVaults[_winner];
            lockAtms+=winnerVaults[_winner];
        }
        uint gift = _winnerBalance - distribution;
        if( gift > 0){
            winnerVaults[admin] += gift;
        }

        emit Finialize(currRound++,uint256(_country));

    }

    function claimReward() external {
        uint gift = winnerVaults[msg.sender];

        require(gift > 0, "No vault");
        winnerVaults[msg.sender] = 0;
        lockAtms-=gift;
        (bool success,) = msg.sender.call{value:gift}("");
        require(success, "claim reward failed!");

        emit ClaimReward(msg.sender,winnerVaults[msg.sender]);
    }

    function getCountryPlayters(uint8 _round, Country _country) external view returns (uint256) {
        return countryToPlayers[_round][_country].length;
    }

    function getPlayerInfo(uint8 _round, address _player, Country _country) external  view returns (uint256 _counts) {
        return players[_round][_player].counts[_country];
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

}