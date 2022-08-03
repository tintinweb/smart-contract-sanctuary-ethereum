// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ScoreID {
    uint256 public contPersons;
    uint256 public contScores;

    struct Person {
        string name;
        bool isActive;
    }

    struct Score {
        string title;
        address personScore;
        int8 scoreNumber;
        bool exists;
    }

    mapping(address => Person) persons;
    mapping(address => Score) scores;

    modifier onlyRealPersons(address _addrPerson) {
        require(persons[_addrPerson].isActive, "Person not found");
        _;
    }

    constructor() {
        contPersons = 0;
        contScores = 0;
    }

    function createPerson(address _addr, string memory _name)
        public
        returns (bool)
    {
        persons[_addr] = Person({name: _name, isActive: true});
        contPersons++;
        return true;
    }

    function createScore(
        address _addrToken,
        string memory _title,
        address _addrPerson,
        int8 _score
    ) public onlyRealPersons(_addrPerson) returns (bool) {
        scores[_addrToken] = Score({
            title: _title,
            personScore: _addrPerson,
            scoreNumber: _score,
            exists: true
        });
        contScores++;
        return true;
    }

    function getPerson(address _addrPerson) public view onlyRealPersons(_addrPerson) returns(Person memory) {
        return persons[_addrPerson];
    }

    function getScore(address _addrToken) public view returns(Score memory) {
        require(scores[_addrToken].exists, 'Score not found');
        return scores[_addrToken];
    }
}