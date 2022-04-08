/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: WorldCup.sol

contract WorldCup {

    address public owner;
    uint256 public participantCounter;
    uint256 public countryCounter;

    struct Participant {
        address payable wallet;
        uint256 amount;
        uint256 id;
        uint256 country;
    }

    struct Country {
        bytes12 name;
        uint256 id;
        uint256 valueLocked;
    }

    Participant[] public funders;
    mapping(uint256 => Country) public countryIdToCountry;
    mapping(uint256 => uint256) public countryIdtoReward;
    mapping(address => uint256) public walletToId;

    event participantAdded(Participant x);
    event countryWin(uint256 countryId, bytes32 countryName, uint256 countryReward);

    constructor (bytes12[] memory _countries, uint256[] memory _rewards){
        owner = msg.sender;
        for (uint i = 0; i < _countries.length; i++){
            countryIdToCountry[countryCounter] = Country(_countries[i], countryCounter, 0);
            countryIdtoReward[countryCounter] = _rewards[i];
            countryCounter++;
        }
    }


    function addParticipant(uint256 countryId) public payable returns(uint256){
        require(msg.value > 3000000000000000, "Minimum amount is 0.003 ETH");
        require(countryId < countryCounter, "No country founded");
        require(walletToId[msg.sender] == 0, "Participant already exists");

        countryIdToCountry[countryId].valueLocked += msg.value;
        participantCounter++;
        Participant memory newParticipant = Participant(payable(msg.sender), msg.value, participantCounter, countryId);
        walletToId[msg.sender] = newParticipant.id;
        funders.push(newParticipant);
        emit participantAdded(newParticipant);

        return newParticipant.id;
    }

    function addMoreFundsParticipant(uint256 participantId) public payable {
        require(msg.value > 3000000000000000, "Minimum amount is 0.003 ETH");
        require(participantId < participantCounter, "Id is incorrect");
        Participant memory updatingParticipant = funders [participantId];
        require(updatingParticipant.wallet == msg.sender, "This is an id from a different wallet");

        updatingParticipant.amount += msg.value;
        countryIdToCountry[updatingParticipant.country].valueLocked += msg.value;
    }

    function changeCountryParticipant(uint256 participantId, uint256 countryId) public view {
        require(participantId < participantCounter, "Id is incorrect");
        Participant memory updatingParticipant = funders [participantId];
        require(updatingParticipant.wallet == msg.sender, "This is an id from a different wallet");

        updatingParticipant.country = countryId;
    }

    function removeParticipant(uint256 participantId) public payable returns(uint256) {
        Participant memory x = funders[participantId];
        uint256 value = x.amount;
        require(x.wallet == msg.sender);
        require(value > 0, "You have nothing to withdraw");

        payable(msg.sender).transfer(value); 
        countryIdToCountry[x.country].valueLocked -= value;
        participantCounter--;
        
        uint256 index = participantId;
        if (index >= funders.length) return value;
        for (uint i = index; i<funders.length-1; i++){
            funders[i] = funders[i+1];
        }
        funders.pop();
        delete walletToId[msg.sender];

        return value;
    }

    function winner(uint256 countryId) public onlyOwner{
        Country memory champion = countryIdToCountry[countryId];
        uint256 reward = countryIdtoReward[countryId];
        emit countryWin(champion.id, champion.name, reward);

        for (uint i = 0; i < participantCounter; i++) {
            Participant memory x = funders[i];
            if (x.country == countryId){
                payable(x.wallet).transfer(x.amount*reward);
            }
        }
        selfdestruct(payable(owner));
    }

    function totalValueLocked() public view returns(uint256) {
        return address(this).balance;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner");
        _;
    }

}