/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Semaphore {
    struct Person {
        string name;
        uint8 age;
    }

    struct Car {
        string color;
        string brand;
        bool fuelType;
        uint16 hnum;
    }

    enum State {
        GREEN,
        YELLOW,
        RED
    }

    event SemaphoreToggled(string _newState);

    State private _state;
    State private _prev;
    mapping(uint => Car) public cars;
    Person[] public people;
    uint private lastCarID = 0;

    function state() public view returns (string memory current_state) {
        if (_state == State.GREEN) return "green";
        if (_state == State.YELLOW) return "yellow";
        if (_state == State.RED) return "red";
    }

    function carPassage(
        string calldata _color,
        string calldata _brand,
        bool _fuelType,
        uint16 _hnum
    ) external {
        require(_state == State.RED, "Wrong semaphore signal: car can pass throw only on red");
        cars[lastCarID++] = Car(_color, _brand, _fuelType, _hnum);
    }

    function personPassage(
        string calldata _name,
        uint8 _age
    ) external {
        require(_state == State.GREEN, "Wrong semaphore signal: person can pass throw only on green");
        people.push(Person(_name, _age));
    }

    function toggle() external {
        if (_state == State.YELLOW && _prev == State.GREEN) {
            _prev = _state;
            _state = State.RED;
        } else if (_state == State.YELLOW && _prev == State.RED) {
            _prev = _state;
            _state = State.GREEN;
        } else {
            _prev = _state;
            _state = State.YELLOW;
        }

        emit SemaphoreToggled(state());
    }
}