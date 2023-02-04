// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract petAdoption {

uint256 public totalAdopted;


struct Pets{
    uint256 createdAt;
    address createdBy;
    uint256 adoptedAt;
    address currentOwner;
    string name;
    string species;
    uint256 age;
    bool vaccinated;
    bool adopted;
}

struct Stats {
    uint256 hasAdopted;
    uint256 petsAdded;
}

mapping (address=>Stats) public userStats;

Pets [] public pets;

function putForAdoption(string memory _name, string memory _species,uint256 _age,bool _vaccinated) public {
    require(userStats[msg.sender].petsAdded<5,"You can't put more than 5 pets for adoption");
    pets.push(Pets(block.timestamp,msg.sender,0,msg.sender,_name,_species,_age,_vaccinated,false));
    userStats[msg.sender].petsAdded++;
}  


function adoptPet(uint256 _id) public {
    require(pets[_id].currentOwner!=msg.sender,"You can't adopt your own pet!");//nije dobro
    require(pets[_id].adopted==false,"That pet is already adopted");
    pets[_id].adoptedAt=block.timestamp;
    pets[_id].currentOwner=msg.sender;
    pets[_id].adopted=true;
    userStats[msg.sender].hasAdopted++;
    totalAdopted++;
}

function getPetsOwner(uint256 _id) public view returns (address){
    return pets[_id].currentOwner;
}

function totalPets() public view returns(uint256){
return pets.length;
}


function availablePets() public view returns (uint256) {
    return totalPets()-totalAdopted;
}

}