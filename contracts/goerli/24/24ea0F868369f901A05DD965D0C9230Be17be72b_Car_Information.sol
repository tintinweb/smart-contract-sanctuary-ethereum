//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract Car_Information { 

//kreiranje strukture automobila   
    struct Car {
        string Name;
        string Color;
        uint YearOfManufacturing;
        bool Registration; //false
        address Owner;   
    }

    address public _owner;
  
  constructor() {
   _owner = msg.sender;
 }

  function owner() private view returns(address) {
    return _owner;
  }

  modifier onlyOwner() { 
    require(isOwner());
    _;
  }

  function isOwner() private view returns(bool) {
   return msg.sender == _owner;
  }

    mapping (uint => Car) public OwnerOfCar; 
    mapping (address => uint) public NumberOfCar;
    mapping (uint => Car) private addressOwner;
    

//kreiranje novog automobila 
   function createCar(uint _id, string memory _Name, string memory _Color, uint _YearOfManufacturing) public {
        OwnerOfCar[_id].Name = _Name;
        OwnerOfCar[_id].Color = _Color;
        OwnerOfCar[_id].YearOfManufacturing = _YearOfManufacturing;
        OwnerOfCar[_id].Registration = false;
        addressOwner[_id].Owner = msg.sender;
        NumberOfCar[msg.sender]++;      
   }
//provera novog kreiranog automobila
   function proveriAuto(uint _id) public view returns (string memory, string memory, uint, bool) {
     return (OwnerOfCar[_id].Name, OwnerOfCar[_id].Color, OwnerOfCar[_id].YearOfManufacturing, OwnerOfCar[_id].Registration);
   }
//promena boje automobila i placanje (samo vlasnik vozila)
   function changeColorOfCar(uint _id, string memory _Color) public payable {
     require(msg.value == 0.01 ether);
       addressOwner[_id].Owner = msg.sender;
       OwnerOfCar[_id].Color = _Color;
   }
//registracija automobila i placanje (samo vlasnik vozila)
   function registrationCar(uint _id, bool _Registration) public payable {
     require(msg.value == 0.02 ether);
      addressOwner[_id].Owner = msg.sender;
      OwnerOfCar[_id].Registration = _Registration;
   }

}