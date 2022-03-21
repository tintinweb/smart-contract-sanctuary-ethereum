/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity ^0.4.24;

contract cowyaoconract {
    uint256 public peoplecount = 0;
    mapping(uint => person) public people;

    struct person {
        uint _id;
        string _firstname;
        string _lastname;
    }

    function addPerson(string memory _firstname, string memory _lastname)public {
        incrementCount();
        people[peoplecount] = person(peoplecount, _firstname, _lastname);
    }

    function incrementCount() internal {
        peoplecount += 1;
    }
}