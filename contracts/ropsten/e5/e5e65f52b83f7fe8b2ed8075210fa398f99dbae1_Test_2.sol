/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

pragma solidity >=0.4.16 <0.8.0;

contract Test_2 {

    uint public peopleCount;
    
    struct Person {
        string firstName;
        string lastName;
    }

    Person[] public people;

    function addPerson(string memory firstName, string memory lastName) public {
        people.push(Person(firstName, lastName));
        peopleCount++;
    }
  
}