/**
 *Submitted for verification at Etherscan.io on 2022-10-30
*/

pragma solidity ^0.8.13;


contract Traffic_Lights{

    enum TraficLights {GREEN, YELLOW, RED}

    TraficLights currentState = TraficLights.GREEN;
    
    struct Car{
        string color;
        string label;
        bool source;
        int horsepower;
    }

    struct Person{
        int age;
        string name;
    }

    Person[] public crossedPeople;
    uint8 peopleCount = 0;

    mapping(uint => Car) public cars;
    uint8 carsCount = 0;


    function addCrossedPerson(Person memory crossedPerson) public {
        if(currentState == TraficLights.GREEN){
        crossedPeople[peopleCount] = crossedPerson;
        peopleCount += 1;
        }
    }

    function setState(TraficLights state) public {
        currentState = state;
    }

    function addStoppedCar(Car memory car) public{
        cars[carsCount] = car;
        carsCount += 1;
    }
}