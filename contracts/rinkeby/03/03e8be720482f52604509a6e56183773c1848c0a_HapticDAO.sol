/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract HapticDAO {

    struct DaoCard {
        uint score;
        string title;
        string description;
    }

    DaoCard[] public daoCards; //scores 0 in array
    mapping(string => DaoCard) public titleToCardMap; //lookup actual score from mapping
    address public owner;

    event AddedCard(address user, string title);
    event DeletedCard(string title);
    event ScoreChange(string status, string title);

    constructor() {
        owner = msg.sender;
    }

    //prevent overwriting of map
    modifier uniqueTitle(string memory _title) {
        require(keccak256(abi.encodePacked(titleToCardMap[_title].title)) != keccak256(abi.encodePacked(_title)));
        _;
    }

    function addDaoCard(string memory _title, string memory _description) uniqueTitle(_title) external returns(uint) {
        require(daoCards.length < 20, "There cannot be more than 20 requests at a time"); //helps dev catchup + reduce gas fees
        DaoCard memory daoCard = DaoCard({score: 0, title: _title, description: _description});
        titleToCardMap[_title] = daoCard;
        daoCards.push(daoCard);
        emit AddedCard(msg.sender, _title);
        return daoCards.length;
    }

    function increaseScore(string memory _title) external {
        titleToCardMap[_title].score+=1;
        emit ScoreChange("score increased", _title);
    }

    function decreaseScore(string memory _title) external {
        titleToCardMap[_title].score-=1;
        emit ScoreChange("score decreased", _title);
    }

    function removeCardRequest(string memory _title) external returns(uint) {
        require(owner == msg.sender, "Only admin may delete cards");
        for(uint i =0; i<daoCards.length; i++) {
            if(keccak256(abi.encodePacked(daoCards[i].title)) == keccak256(abi.encodePacked (_title))){
                daoCards[i] = daoCards[daoCards.length-1];
                delete daoCards[daoCards.length-1];
                delete titleToCardMap[_title];
                emit DeletedCard(_title);
            }
        }
        daoCards.pop();
        return daoCards.length;
    }

    
}