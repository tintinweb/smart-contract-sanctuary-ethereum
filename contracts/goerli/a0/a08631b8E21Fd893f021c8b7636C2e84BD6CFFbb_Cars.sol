// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;


contract Cars {
uint256 broj;

struct Car{
    string name;
    string color;
    uint year;
    bool registered;
}

mapping (uint =>address)public carowner;

Car [] public cars;
uint id=0;

function dodajnabr(uint _id) public  {
    
    broj=broj+_id;
}


function createCar(string memory _color,string memory _name,uint _year) public payable {
    require (msg.value == 0.01 ether);
    carowner[id]=msg.sender;
    cars.push(Car(_color,_name,_year,false));
    (cars[id].color, cars[id].name, cars[id].year, cars[id].registered)=(_color,_name,_year, false);
    id++;
}


function menjajBoju(uint _id,string memory _color) public payable {
    require (msg.value == 0.01 ether);
    require(carowner[_id]== msg.sender,"Nisi vlasnik");
    cars[_id].color=_color;
    
}






function registerCar(uint _id) public payable{
    require (msg.value == 0.01 ether);
    require(carowner[_id]== msg.sender,"Nisi vlasnik");
    require(cars[_id].registered==false,"Auto je vec registrovan");
    cars[_id].registered=true;   
}

function brojAuta() public view returns (uint256) {
    return cars.length;
}

function proveriAuto(uint256 _id)  public view returns ( string memory, string memory,uint,  bool) {
    return (cars[_id].color, cars[_id].name, cars[_id].year, cars[_id].registered);
}


}