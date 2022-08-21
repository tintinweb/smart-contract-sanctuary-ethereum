// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract SimpleStorage {
    uint256 public favoriteNumber;

    // SETTING NUMBER IN [] BRACKETS = LIMITING ARRAY SIZE
    // OTHERWISE DYNAMIC
    People[] public people;
    mapping(string => uint256) public nameToFaveroriteNumber;

    struct People {
        uint256 favoriteNumber;
        string name;
    }

    function store(uint256 _favoriteNumber) public virtual {
        favoriteNumber = _favoriteNumber;
    }

    function retrieve() public view returns(uint256){
        return favoriteNumber;
    }

    // calldata, memory, storage
    //MEMORY => EXIST ONLY DURING EXECUTION
    //CALLDATA => = MEMORY BUT NOT MODIFIABLE
    //STORAGE => DEFAULT BEHAVIOUR ON VARIABLE CONTINUING EXISTING

    //STRING IS ARRAY OF BYTES = NEEDS SPECIFICATION
    function addPerson(string memory _name, uint256 _favoriteNumber) public {
        people.push(People(_favoriteNumber, _name));
        nameToFaveroriteNumber[_name] = _favoriteNumber;
    }
}