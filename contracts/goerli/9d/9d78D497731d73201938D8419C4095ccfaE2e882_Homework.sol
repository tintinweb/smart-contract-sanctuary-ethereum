/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

pragma solidity ^0.8.13;
contract Homework {
    uint256 carCount = 0;


    enum TrafficLight {Red, Yellow, Green}
    TrafficLight public light;

    function getGreen() public {
        light = TrafficLight.Green;
    }
    function getYellow() public {
        light = TrafficLight.Yellow;
    }
    function getRed() public {
        light = TrafficLight.Red;
    }



    struct Person{
        string _name;
        uint8 _age;
    }
    struct Car{
        string _color;
        string _brand;
        bool _GasOrDiesel;
        uint256 _horsepower;
    }
    mapping (uint256 => Car) public cars;
    Person[] public people;

    function addPerson(
        string memory _name,
        uint8 _age       
    ) public { 
        if (light != TrafficLight.Red) {
            return ;
        }
        people.push(Person(_name, _age));
    }

    function addCar(
        string memory _color,
        string memory _brand,
        bool _GasOrDiesel,
        uint256 _horsepower
    ) public {
        if (light != TrafficLight.Green) {
            return ;
        }
        cars[carCount] = Car(_color, _brand, _GasOrDiesel, _horsepower);
        carCount += 1;
    }
}