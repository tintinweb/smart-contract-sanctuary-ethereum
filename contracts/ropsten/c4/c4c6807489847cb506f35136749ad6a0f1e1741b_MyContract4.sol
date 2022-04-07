/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

pragma solidity >=0.4.16 <0.8.0;

contract MyContract4 {
address owner;
uint256 public peopleCount = 0;
mapping (uint=>Person) public people;
struct Person {
    uint id;
    string firstName;
    string lastName;
}

modifier onlyOwner(){
    require(msg.sender == owner);
    _;
}

constructor() public {
    owner = msg.sender;
}

function incrementCount() internal{
    peopleCount+=1;
}

function addPerson(string memory firstName, string memory lastName) public onlyOwner {

        incrementCount();
        people[peopleCount]=Person(peopleCount, firstName, lastName);
}
}