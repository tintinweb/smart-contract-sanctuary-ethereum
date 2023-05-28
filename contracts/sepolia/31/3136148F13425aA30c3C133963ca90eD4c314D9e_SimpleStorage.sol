/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7; 
// first import solidity by this line 
//^0.8.7 means verison grater than 0.8.7
// also the different version by using operators

contract SimpleStorage {
    
    uint256 favNumber;
    

    // struct in solidity
    struct People{
        uint256 favnum;
        string name;
    }
    People public person = People({favnum: 4, name:"Rohit"});
    
// Array in solidity
    People[] public people; // dynamic array

// Mapping -> Dictionary type ds
    mapping(string => uint) public nameandFavnum;
    function store(uint256 _favoriteNumber) public virtual {
        favNumber = _favoriteNumber;
        // retrieve();
    }

    function retrieve() public view returns(uint256){
        return favNumber;
        // view funtion does'nt allow to modify state and this type of function does'nt use any gas
    }
    function addPerson(string memory _name, uint256 _favnum) public {
        people.push(People(_favnum, _name));
        nameandFavnum[_name]=_favnum;
    }
    

    



}
// 0xd9145CCE52D386f254917e481eB44e9943F39138