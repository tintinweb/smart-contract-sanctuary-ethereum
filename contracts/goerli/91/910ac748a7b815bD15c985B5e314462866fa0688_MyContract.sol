//  SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract MyContract {
    enum State {
        waiting,
        ready,
        active
    }
    State state;

    string public name = "Michael Nandi";

    // Person[] public people;
    uint256 public peopleCount;
    mapping(uint256 => Person) public people;

    struct Person {
        uint256 id;
        string firstName;
        string lastName;
    }

    constructor() {
        state = State.waiting;
    }

    function get() public view returns (string memory) {
        return name;
    }

    function set(string memory _name) public {
        name = _name;
    }

    function activate() public {
        state = State.active;
    }

    function isActive() public view returns (bool) {
        return state == State.active;
    }

    function ready() public {
        state = State.ready;
    }

    function addPerson(
        string memory _firstName,
        string memory _lastName
    ) public {
        peopleCount += 1;
        people[peopleCount] = Person(peopleCount, _firstName, _lastName);
        // people.push(Person(_firstName, _lastName));
    }

    function getPeople(uint256 index) public view returns (Person memory) {
        return people[index];
    }
}