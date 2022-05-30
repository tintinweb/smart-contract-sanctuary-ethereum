/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.7; //any version above 0.8.7 is okay

//starting a contract. use keyword "contract"
contract SimpleStorage{
    uint256 public favoriteNumber; //by default favoriteNumber is initialized to 0

    //create a function called "store"
    function store(uint256 favNum) public{//uses gas to trasact
        favoriteNumber=favNum;
    }

    function retrieve() public view returns(uint256){ //doesn't use any gas because view (allows modifications) and pure(doesn't allow modificatins) functions do not need any gas to trasact.
        return favoriteNumber;
    }

    //create a struct type called People to store a list of people with their favorite numbers
    struct People{
        string name;
        uint256 favnum;
    }

    //initializing People
    //People member1=People({favnum:7,name:Sindhu});
    // it is commented because it is inefficient to be used for multiple members. Therefore, we use an array to store data.

    //create an array of type People called people
    People[] public people;

    //create mapping that conveerts string to uint256 type 
    mapping (string=> uint256) public nameToFavNum;

    function addPerson(uint256 _num, string memory _name) public{ //strings,arrays and mappings in function parameters must have datalocations specified for ex: memory (For temporary,  modifiable variables) and calldata (For temporary, non-modifiable variables)
        //People memory newPerson=People({favnum:_num,name:_name}); 
        //people.push(newPerson);
        //commented because we can replace the 2 lines by the below line:
        people.push(People(_name,_num));
        nameToFavNum[_name]=_num;
    }
}