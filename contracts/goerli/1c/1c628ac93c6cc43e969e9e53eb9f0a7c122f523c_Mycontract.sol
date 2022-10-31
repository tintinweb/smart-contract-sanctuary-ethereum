/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

pragma solidity ^0.8.13;



contract Mycontract
{
    uint256 peopleCount = 0;
    mapping(uint=> Person) public people;
    struct Person{
        uint _id;
        string _Name;
        uint8 _age;
    }
    uint256 carCount = 0;
     mapping(uint=>Machine) public car;
    struct Machine{
        uint _id;
        string _Color;
        string _Mark;
        bool _Type;
        uint16 _Power;
    }
    enum LightBeam {GREEN, YELLOW, RED}

    LightBeam public lightbeam;
    //view - позволяет посмотреть результаты функций
     

    function setGreen() public{
        lightbeam = LightBeam.GREEN;
    }

    function setYellow() public{
        lightbeam = LightBeam.YELLOW;
    }

    function setRed() public{
        lightbeam = LightBeam.RED;
    }

    function addPerson(string memory _Name, uint8 _age) public{
        if(lightbeam==(LightBeam.GREEN))
        {
            peopleCount +=1;
            people[peopleCount]=Person(peopleCount, _Name, _age);
        }
    }
    function addCar(string memory _Color, string memory _mark,bool _type,uint16 _power) public{
        if(lightbeam==(LightBeam.RED))
        {
            carCount +=1;
            car[carCount]=Machine(carCount, _Color, _mark, _type, _power);
        }
    }
}