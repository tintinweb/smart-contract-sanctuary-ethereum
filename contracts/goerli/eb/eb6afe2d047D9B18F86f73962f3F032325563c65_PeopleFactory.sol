// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

contract PeopleFactory {
  uint256 favNo;
  struct Person {
    string name;
    uint256 favNo;
  }

  Person[] people;

  function addPerson(string memory _name, uint256 _favNo)
    public
    returns (Person memory person)
  {
    Person memory _newPerson = Person(_name, _favNo);
    people.push(_newPerson);

    return _newPerson;
  }

  function getPerson(uint256 index) public view returns (Person memory) {
    require(index < people.length, "No Person Exists at that index");
    return people[index];
  }
}