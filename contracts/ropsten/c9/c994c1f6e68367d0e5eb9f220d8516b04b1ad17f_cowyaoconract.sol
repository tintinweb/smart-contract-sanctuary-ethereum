/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

pragma solidity ^0.4.24;

contract cowyaoconract {
    person[] public people ;

    uint256 public peoplecount;

    struct person {
        string _firstname;
        string _lastname;
    }

    function addPerson(string memory _firstname, string memory _lastname)public {
        people.push(person( _firstname, _lastname));
        peoplecount += 1;
    }

}