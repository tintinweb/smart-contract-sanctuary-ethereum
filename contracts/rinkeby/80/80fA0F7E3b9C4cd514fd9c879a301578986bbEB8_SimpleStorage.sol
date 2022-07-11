//SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

contract SimpleStorage {
    //boolean, uint, int, address, bytes
    uint256 public favNumber;
    struct People {
        uint256 num;
        string name;
    }

    People public person = People(
        {
            num: 2,
            name: "Bolbona"
        }
    );

    People[] public people;

    mapping(string => uint256) public nameToNum;

    function store(uint256 _favNumber) public virtual {
        favNumber = _favNumber;
        favNumber++;
    }
    
    function retrieve() public view returns(uint256){
        return favNumber;
    }

    //call-data(temp, noMod), memory(temp, mod), storage(permanent, modifiable) -> temp mem;
    function addPeople(uint256 favNum, string memory name) public {
        People memory newPerson = People(favNumber, name);
        people.push(newPerson);
        nameToNum[name] = favNum;
    }

    //view-read from contact, no cost
    //pure-no update, no reading, no cost(gas)
    function add() public pure returns(uint256) {
        return (1+1);
    }
}