/**
 *Submitted for verification at Etherscan.io on 2022-11-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7; //0.8.12 declaring solidity version

contract SimpleStorage {
    uint256 favoriteNumber;

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
        //favoriteNumber += 200;
        //retrieve();
        //add();
    }

    //fxn keywords with no gas cost: view and pure. They don't modify the state of data
    function retrieve() public view returns (uint256) {
        return favoriteNumber;
    }

    //reading or writing (transactions) to the blockchain cost gas
    function add() public pure returns (uint256) {
        return (9 + 2);
    }

    //People public person = People({favoriteNumber:2, name:"Audrey-Ann"});
    // People public person1 = People({favoriteNumber:4, name:"Ann"});
    //People public person2 = People({favoriteNumber:20, name:"Audrey"});

    //arrays
    //uint256[] public ListFavoriteNumber;
    People[] public people;

    //mapping
    mapping(string => uint256) public mapNameToNumber;

    //struct/object

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    //fxn to add people to the people array
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        mapNameToNumber[_name] = _favoriteNumber;
    }

    /* function addAnotherPerson(string memory _name, uint256 _favoriteNumber) public {
        People memory newPerson = People({favoriteNumber: _favoriteNumber, name:_name});
        people.push(newPerson);

        
    }*/

    /* 
    There are 6 places where we can store data in solidity namely:
    1. stack
    2. memory
    3. storage
    4. calldata
    5. codes
    6. logs
    
    */
}